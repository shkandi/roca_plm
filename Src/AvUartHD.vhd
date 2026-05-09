--! полуплексная реализация сопряжения uart и avalon-mm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity AvUartHD is
    port(
        AvAddr              : out std_logic_vector(5 downto 0);
        AvWrData            : out std_logic_vector(7 downto 0);
        AvRdData            : in std_logic_vector(7 downto 0);
        AvWrRq              : out std_logic;
        AvRdRq              : out std_logic;
        AvWaitRq            : in std_logic;
        AvRdDv              : in std_logic;
        Rst                 : in std_logic;
        Clk                 : in std_logic;
        UartBusy            : in std_logic;
        DataRx              : in std_logic_vector(7 downto 0);
        EnRx                : in std_logic;
        DataTx              : out std_logic_vector(7 downto 0);
        EnTx                : out std_logic
    );
end AvUartHD;

architecture beh1 of AvUartHD is
    type StateType is (Idle, GetCmd, OpSt, WrSt, HdrSt, RdSt);
    signal State: StateType;

    signal WrOp: std_logic_vector(1 downto 0);
    signal CntMaxRg: std_logic_vector(3 downto 0);
    signal IncAddr: std_logic;
    signal WrDataBuf: std_logic_vector(7 downto 0);
    signal AvAddrRg: std_logic_vector(5 downto 0);
    signal Cnt16: std_logic_vector(3 downto 0);
    signal RdVal: std_logic;
begin
    
    cmd_rx_proc:
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                State <= Idle;
                AvWrRq <= '0';
                AvRdRq <= '0';
                EnTx <= '0';
            else
                case State is
                    when Idle =>
                        if DataRx(7 downto 4) = x"A" and EnRx = '1' then
                            State <= GetCmd;
                            CntMaxRg <= DataRx(3 downto 0);
                        end if;

                        WrDataBuf <= (others => '1');
                        AvWrRq <= '0';
                        AvRdRq <= '0';
                        EnTx <= '0';
                        RdVal <= '0';
                        IncAddr <= '0';
                        Cnt16 <= x"0";
                    when GetCmd =>
                        if EnRx = '1' then
                            if DataRx(7 downto 6) = "00" then
                                State <= HdrSt;
                                EnTx <= '1';
                            else
                                State <= OpSt;
                            end if;
                            
                            AvAddrRg <= DataRx(5 downto 0);
                            AvRdRq <= DataRx(7);
                            WrOp <= DataRx(7 downto 6);
                        end if;

                        DataTx <= x"B" & CntMaxRg;
                    when OpSt =>
                        AvRdRq <= '0';

                        if (WrOp(1) and AvRdDv) = '1' then
                            WrDataBuf <= AvRdData;
                        end if;

                        if WrOp(1) = '0' or (WrOp(1) and AvRdDv) = '1' then
                            State <= WrSt;
                        end if;
                    when WrSt =>
                        if EnRx = '1' then
                            if WrOp(0) = '1' then
                                AvWrData <= DataRx and WrDataBuf;
                            else
                                AvWrData <= DataRx or WrDataBuf;
                            end if;
                        end if;

                        if IncAddr = '1' then
                            AvAddrRg <= AvAddrRg + '1';
                            Cnt16 <= Cnt16 + '1';

                            if Cnt16 = CntMaxRg then
                                State <= Idle;
                            else
                                State <= OpSt;
                                AvRdRq <= WrOp(1);
                            end if;
                        end if;

                        AvWrRq <= EnRx;
                        IncAddr <= EnRx;
                    when HdrSt =>
                        DataTx <= "00" & AvAddrRg;
                        EnTx <= not UartBusy;

                        if UartBusy = '0' then
                            State <= RdSt;
                            AvRdRq <= '1';
                        end if;
                    when RdSt =>
                        if AvRdDv = '1' then
                            DataTx <= AvRdData;
                            RdVal <= '1';
                        end if;

                        if RdVal = '1' and UartBusy = '0' then
                            RdVal <= '0';
                        end if;
                        
                        EnTx <= not UartBusy and RdVal;
                        IncAddr <= not UartBusy and RdVal;
                        AvRdRq <= IncAddr;

                        if IncAddr = '1' then
                            AvAddrRg <= AvAddrRg + '1';
                            Cnt16 <= Cnt16 + '1';
                        end if;

                        if Cnt16 = CntMaxRg and IncAddr = '1' then
                             State <= Idle;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    AvAddr <= AvAddrRg;

end beh1;
