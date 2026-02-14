library ieee;
use ieee.std_logic_1164.all;


entity AvUart is
    generic(
        pFreq           : integer := 50000000;
        pBaudRate       : integer := 9600
    );
    port(
        AvAddr              : out std_logic_vector(7 downto 0);
        AvWrData            : out std_logic_vector(7 downto 0);
        AvRdData            : in std_logic_vector(7 downto 0);
        AvWrRq              : out std_logic;
        AvRdRq              : out std_logic;
        AvWaitRq            : in std_logic;
        AvRdDv              : in std_logic;
        Clk                 : in std_logic;
        UartRx              : in std_logic;
        UartTx              : out std_logic
    );
end AvUart;

architecture beh1 of AvUart is
    component uart is
    generic(
        pFreq           : integer := 50000000;
        pBaudRate       : integer := 9600
    );
    port(
        DataIn          : in std_logic_vector(7 downto 0);
        EnIn            : in std_logic;
        Clk             : in std_logic;
        Rx              : in std_logic;
        Tx              : out std_logic;
        TxBusy          : out std_logic;
        DataOut         : out std_logic_vector(7 downto 0);
        EnOut           : out std_logic
    );
    end component uart;

    signal DataRx: std_logic_vector(7 downto 0);
    signal EnRx: std_logic;
    signal DataRxSr: std_logic_vector(15 downto 0);
    signal DataTx: std_logic_vector(7 downto 0);
    signal EnTx: std_logic;

    type StateType is (Idle, GetCmd, GetAddr, GetWrData, WrSt, RdSt);
    signal State: StateType;
    signal CmdRg: std_logic;
begin

    uart_ent:
    uart
    generic map(
        pFreq           => pFreq,            -- : integer := 50000000;
        pBaudRate       => pBaudRate            -- : integer := 9600
    )
    port map(
        DataIn          => DataTx,                -- : in std_logic_vector(7 downto 0);
        EnIn            => EnTx,                -- : in std_logic;
        Clk             => Clk,                -- : in std_logic;
        Rx              => UartRx,                -- : in std_logic;
        Tx              => UartTx,                -- : out std_logic;
        TxBusy          => open,                -- : out std_logic;
        DataOut         => DataRx,                -- : out std_logic_vector(7 downto 0);
        EnOut           => EnRx                -- : out std_logic
    );

    process(Clk)
    begin
        if rising_edge(Clk) then
            case State is
                when Idle =>
                    if DataRx = x"55" and EnRx = '1' then
                        State <= GetCmd;
                    end if;

                    AvWrRq <= '0';
                    AvRdRq <= '0';
                    EnTx <= '0';
                when GetCmd =>
                    if EnRx = '1' then
                        State <= GetAddr;
                        CmdRg <= DataRx(0);
                    end if;
                when GetAddr =>
                    if EnRx = '1' then
                        AvAddr <= DataRx;
                        AvRdRq <= not CmdRg;

                        if CmdRg = '1' then
                            State <= GetWrData;
                        else
                            State <= RdSt;
                        end if;
                    end if;
                when GetWrData =>
                    if EnRx = '1' then
                        AvWrData <= DataRx;
                        State <= WrSt;
                        AvWrRq <= '1';
                    end if;
                when WrSt =>
                    State <= Idle;
                    AvWrRq <= '0';
                when RdSt =>
                    if AvRdDv = '1' then
                        State <= Idle;
                        DataTx <= AvRdData;
                        EnTx <= '1';
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    
end beh1;
