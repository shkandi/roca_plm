library ieee;
use ieee.std_logic_1164.all;


entity uart is
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
end uart;

architecture beh1 of uart is
    constant CntRxMax: integer := pFreq/(pBaudRate*9);
    constant CntTxMax: integer := pFreq/pBaudRate;

    type StateType is (S0,S1);
    signal RxState: StateType;

    signal SmplEnSr: std_logic_vector(7 downto 0);
    signal SmplCntSr: std_logic_vector(8 downto 0);
    signal SmplSr: std_logic_vector(4 downto 0);
    signal RxDataSr: std_logic_vector(9 downto 0);
    signal RxBusySr: std_logic_vector(9 downto 0);
    signal CntRx: integer range 0 to pFreq/(pBaudRate*9); 

    signal TxBusySr : std_logic_vector (9 downto 0);
    signal TxDaraSr : std_logic_vector (9 downto 0) := "1111111111";
    signal CntTx : integer range 0 to pFreq/pBaudRate;

begin

    -----------------------------------------------------------------------
    -- UART RX
    -----------------------------------------------------------------------

    process(Clk)
    begin
        if rising_edge(Clk) then
            case RxState is
                when S0 =>
                    if Rx = '0' then
                        RxState <= S1;
                    end if;
                    
                    RxBusySr <= (others => '0');
                    EnOut <= '0';
                    CntRx <= 0;
                    SmplEnSr <= (others => '0');
                    SmplCntSr <= (others => '0');
                    SmplSr <= (others => '0');
                when S1 =>
                    if CntRx = CntRxMax then                      
                        if SmplEnSr(SmplEnSr'left) = '1' then
                            SmplEnSr <= (others => '0');
                        else
                            SmplEnSr <= SmplEnSr(SmplEnSr'left - 1 downto 0) & "1";
                        end if;
                    end if;
                    
                    if SmplEnSr(2) = '1' then
                        SmplCntSr <= SmplCntSr(SmplCntSr'left - 1 downto 0) & "1";

                        if Rx = '1' then
                            SmplSr <= SmplSr(SmplSr'left - 1 downto 0) & "1";
                        end if;
                    else
                        SmplCntSr <= (others => '0');
                        SmplSr <= (others => '0');
                    end if;

                    if SmplCntSr(8 downto 7) = "01" then
                        RxDataSr <= SmplSr(SmplSr'left) & RxDataSr(RxDataSr'left downto 1);
                        RxBusySr <= RxBusySr(RxBusySr'left - 1 downto 0) & "1";
                    end if;

                    if RxBusySr(RxBusySr'left) = '1' or (RxBusySr(1 downto 0) = "01" and RxDataSr(9) = '1') then
                        RxState <= S0;
                    end if;

                    EnOut <= not RxDataSr(0) and RxDataSr(9) and RxBusySr(RxBusySr'left);
                    DataOut <= RxDataSr(8 downto 1);
                    
                    if CntRx = CntRxMax then
                        CntRx <= 0;
                    else
                        CntRx <= CntRx + 1;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    -----------------------------------------------------------------------
    -- UART TX
    -----------------------------------------------------------------------

    Tx <= TxDaraSr(0);
    TxBusy <= TxBusySr(0);

    process(Clk)
    begin
       if rising_edge(Clk) then
            if TxBusySr(0) = '0' then
                TxDaraSr(9 downto 1) <= '1' & DataIn;
                TxDaraSr(0) <= not EnIn;

                if EnIn = '1' then
                    TxBusySr <= (others => '1');
                end if;

                CntTx <= 0;
            else
                if (CntTx = CntTxMax) then
                    TxDaraSr <= '1' & TxDaraSr(TxDaraSr'left downto 1);
                    TxBusySr <= '0' & TxBusySr(TxBusySr'left downto 1);
                    CntTx <= 0;
                else
                    CntTx <= CntTx + 1;
                end if;
            end if;
        end if;
    end process;


end beh1;
