library ieee;
use ieee.std_logic_1164.all;


entity AvI2C is
    port(
        AvAddr          : in std_logic_vector(3 downto 0);
        AvWrData        : in std_logic_vector(7 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdVal         : out std_logic;
        Clk             : in std_logic;
        DataM2S         : out std_logic_vector(7 downto 0);
        DataS2M         : in std_logic_vector(7 downto 0);
        AckD            : in std_logic;
        nWr             : out std_logic;
        Cs              : out std_logic;
        BusBusy         : in std_logic;
        AckErr          : in std_logic
    );
end AvI2C;

architecture beh1 of AvI2C is
    type DataBufType is array(7 downto 0) of std_logic_vector(7 downto 0);
    signal DataBuf: DataBufType;
    signal A_Buf: std_logic_vector(2 downto 0);
    signal D_Buf: std_logic_vector(7 downto 0);
    signal W_Buf: std_logic;
    signal Q_Buf: std_logic_vector(7 downto 0);
    signal Sel_Buf: std_logic; 
    signal std_logic_vector(2 downto 0); 

    signal Status: std_logic_vector(7 downto 0);
    signal DevAddr: std_logic_vector(7 downto 0);
    signal RegAddr: std_logic_vector(7 downto 0);
begin

    process(Clk)
    begin
        if rising_edge(Clk) then
            AvRdVal <= AvRdRq;
            CmdVal <= '0';
            CmdReg <= AvWrData;

            case AvAddr is
                when x"8" =>
                    if AvWrRq = '1' then
                        DevAddr <= AvWrData;
                    end if;

                    AvRdData <= DevAddr;
                when x"9" =>
                    if AvWrRq = '1' then
                        RegAddr <= AvWrData;
                    end if;

                    AvRdData <= RegAddr;
                when x"A" =>
                    CmdVal <= AvWrRq;
                    AvRdData <= Status;
                when others =>
                    if AvWrRq = '1' then
                        TdDataBuf(conv_integer(AvAddr(3 downto 0))) <= AvWrData;
                    end if;

                    AvRdData <= Q_Buf;
            end case;
            
            case State is
                when Idle =>
                    Sel_Buf <= '0';
                    if CmdVal = '1' then
                        State <= WrDev;
                    end if;
                when WrDev =>
                    Sel_Buf <= '0';
                when others =>
                    null;
            end case;
        end if;
    end process;

    A_Buf <= when Sel_Buf = '1' else AvAddr(2 downto 0);
    D_Buf <= when Sel_Buf = '1' else AvWrData;
    W_Buf <= when Sel_Buf = '1' else (not (vAddr(3) and AvWrRq);
    
    process(Clk)
    begin
        if rising_edge(Clk) then
            if W_Buf = '1' then
                DataBuf(conv_integer(A_Buf)) <= D_Buf;
            end if;

            Q_Buf <= DataBuf(conv_integer(A_Buf));
        end if;
    end process;


end beh1;
