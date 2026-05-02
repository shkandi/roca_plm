--! полнодуплексная реализация сопряжения uart и avalon-mm
--! в основе лежит предположение, что латентность uart минимум в 10 раз выше чем у avalon-mm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity AvUartFD is
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
end AvUartFD;

architecture beh1 of AvUartFD is
    type GProcStType is (Idle, GetCmd);
    signal GProcSt: GProcStType;
    type WrProcStType is (Idle, OpSt, WrSt);
    signal WrProcSt: WrProcStType;
    type RdProcStType is (Idle, HdrSt, RdSt);
    signal RdProcSt: RdProcStType;

    signal EnWrProc: std_logic;
    signal EnRdProc: std_logic;
    signal WrOp: std_logic_vector(1 downto 0);
    signal CntMaxRg: std_logic_vector(3 downto 0);
    signal WrCntMax: std_logic_vector(3 downto 0);
    signal RdCntMax: std_logic_vector(3 downto 0);
    signal IncAddrW: std_logic;
    signal IncAddrR: std_logic;
    signal WrDataBuf: std_logic_vector(7 downto 0);
    signal AvAddrRg: std_logic_vector(5 downto 0);
    signal AvAddrW: std_logic_vector(5 downto 0);
    signal AvAddrR: std_logic_vector(5 downto 0);
    signal AvWrRqW: std_logic;
    signal AvRdRqW: std_logic;
    signal AvRdRqR: std_logic;
    signal WrCnt: std_logic_vector(3 downto 0);
    signal RdCnt: std_logic_vector(3 downto 0);
    signal Sel: std_logic;      -- wr/rd access to avalon bus; 1 - wr; 0 - rd;
    signal BufWr: std_logic_vector(9 downto 0);     -- wrrq,rdrq,addr
    signal BufRd: std_logic_vector(9 downto 0);     -- wrrq,rdrq,addr; wrrq always 0;
    signal CommState: std_logic;
begin
    
    cmd_rx_proc:
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                GProcSt <= '1';
                EnWrProc <= '0';
                EnRdProc <= '0';
            else
                case GProcSt is
                    when Idle =>
                        if DataRx(7 downto 4) = x"A" and EnRx = '1' then
                            GProcSt <= GetCmd;
                            CntMaxRg<= DataRx(3 downto 0);
                        end if;

                        EnWrProc <= '0';
                        EnRdProc <= '0';
                    when GetCmd =>
                        if EnRx = '1' then
                            GProcSt <= Idle;

                            EnWrProc <= DataRx(7) or DataRx(6);
                            EnRdProc <= not (DataRx(7) or DataRx(6));
                            AvAddrRg <= DataRx(5 downto 0);

                            if (DataRx(7) or DataRx(6)) = '1' then
                                WrOp <= DataRx(7 downto 6);
                            end if;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    wr_proc:
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                WrProcSt <= Idle;
                AvWrRqW <= '0';
                AvRdRqW <= '0';
            else
                case WrProcSt is
                    when Idle =>
                        AvWrRqW <= '0';
                        AvRdRqW <= EnWrProc and WrOp(1);
                        WrCnt <= x"0";
                        WrDataBuf <= (others => '1');

                        if EnWrProc = '1' then
                            WrCntMax <= CntMaxRg;
                            WrProcSt <= OpSt;
                            AvAddrW <= AvAddrRg;
                        end if;     
                    when OpSt =>
                        AvRdRqW <= '0';

                        if (WrOp(1) and AvRdDv and Sel) = '1' then
                            WrDataBuf <= AvRdData;
                        end if;

                        if WrOp(1) = '0' or (WrOp(1) and AvRdDv and Sel) = '1' then
                            WrProcSt <= WrSt;
                        end if;
                    when WrSt =>
                        if EnRx = '1' then
                            if WrOp(0) = '1' then
                                AvWrData <= DataRx and WrDataBuf;
                            else
                                AvWrData <= DataRx or WrDataBuf;
                            end if;
                        end if;

                        if IncAddrW = '1' then
                            AvAddrW <= AvAddrW + '1';
                            WrCnt <= WrCnt + '1';

                            if WrCnt = WrCntMax then
                                WrProcSt <= Idle;
                            else
                                WrProcSt <= OpSt;
                                AvRdRqW <= WrOp(1);
                            end if;
                        end if;

                        AvWrRqW <= EnRx;
                        IncAddrW <= EnRx;
                    when others =>
                        null;
                end case;
            end if;
        end if;                  
    end process;

    rd_proc:
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                RdProcSt <= Idle;
                EnTx <= '0';
                AvAddrR <= '0';
            else
                case RdProcSt is
                    when Idle =>
                        RdCnt <= x"0";

                        if EnRdProc = '1' then
                            AvAddrR <= AvAddrRg;
                            RdCntMax <= CntMaxRg;
                            RdProcSt <= HdrSt;
                            DataTx <= x"A" & RdCntMax;
                            EnTx <= '1';
                        end if;
                    when HdrSt =>
                        DataTx <= "00" & AvAddrR;
                        EnTx <= not UartBusy;

                        if UartBusy = '0' then
                            RdProcSt <= RdSt;
                        end if;
                    when RdSt =>
                        if (not Sel and AvRdDv) = '1' then
                            DataTx <= AvRdData;
                            DataVal <= '1';
                        end if;
                        
                        

                        EnTx <= not Sel and AvRdDv;     -- what about uart busy?
                        IncAddrR <= not Sel and AvRdDv;

                        if IncAddrR = '1' then
                            AvAddrR <= AvAddrR + '1';
                            RdCnt <= RdCnt + '1';
                        end if;

                        if RdCnt = RdCntMax and IncAddrR = '1' then
                             RdProcSt <= Idle;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    avmm_access_proc:
    process(Clk)
        variable vOp: std_logic_vector(3 downto 0);
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                Sel <= '0';
                CommState <= '0';
                AvWrRq <= '0';
                AvRdRq <= '0';
            else
                if CommState = '0' then
                    vOp := BufRd(8) & (BufWr(9) or BufWr(8)) & AvRdRqR & (AvRdRqW or AvWrRqW);
                    
                    if (AvRdRqW or AvWrRqW) = '1' then
                        AvAddr <= AvAddrW;
                        AvWrRq <= AvWrRqW;
                        AvRdRq <= AvRdRqW;
                        CommState <= '1';
                        Sel <= '1';
                        BufRd <= "0" & AvRdRqR & AvAddrR;
                    elsif AvRdRqR = '1' then
                        AvAddr <= AvAddrR;
                        AvRdRq <= AvRdRqR;
                        CommState <= '1';
                        Sel <= '0';
                    end if;
                else
                    if Sel = '1' and ()
                    AvWrRqInt <= '0';
                    AvRdRq <= '0';

                    if Sel = '1' then
                        BufWr(9 downto 8) <= "00";
                    else
                        BufRd(9 downto 8) <= "00";
                    end if;
                end if;
            end if;
        end if;
    end process;

end beh1;
