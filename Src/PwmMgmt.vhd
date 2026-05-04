library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity PwmMgmt is
    generic(
        pOutputs        : integer range 1 to 8:= 1
    );
    port(
        AvAddr          : in std_logic_vector(3 downto 0);
        AvWrData        : in std_logic_vector(7 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdVal         : out std_logic;
        CmpEn           : in std_logic;
        Clk             : in std_logic;
        PwmOut          : out std_logic_vector(pOutputs - 1 downto 0)
    );
end PwmMgmt;

architecture beh1 of PwmMgmt is
    signal PwmCnt: std_logic_vector(7 downto 0);
    signal DivCnt: std_logic_vector(7 downto 0);
    signal DivCntMax: std_logic_vector(7 downto 0);
    signal SwReg: std_logic_vector(7 downto 0);
    signal dSwReg: std_logic_vector(7 downto 0);
    signal EnReg: std_logic_vector(7 downto 0);
    signal PolarityReg: std_logic_vector(7 downto 0);
    signal nForceStop: std_logic;
    
    type PwmMaskType is array(pOutputs - 1 downto 0) of std_logic_vector(7 downto 0);
    signal PwmMask: PwmMaskType;
begin
    
    process(Clk)
        variable vTmp: std_logic;
    begin
        if rising_edge(Clk) then
            
            case AvAddr is
                when x"0" =>
                    if AvWrRq = '1' then
                        SwReg <= AvWrData;
                    end if;

                    AvRdData <= SwReg;
                when x"1" =>
                    if AvWrRq = '1' then
                        DivCntMax <= AvWrData;
                    end if;

                    AvRdData <= DivCntMax;
                when x"2" =>
                    if AvWrRq = '1' then
                        EnReg <= AvWrData;
                    end if;

                    AvRdData <= EnReg;
                when x"3" =>
                    if AvWrRq = '1' then
                        PolarityReg <= AvWrData;
                    end if;

                    AvRdData <= PolarityReg;
                when others =>
                    if AvWrRq = '1' and AvAddr(3) = '1' then
                        PwmMask(conv_integer(AvAddr(2 downto 0))) <= AvWrData;
                    end if;

                    AvRdData <= PwmMask(conv_integer(AvAddr(2 downto 0)));
            end case;

            if CmpEn = '1' then
                dSwReg <= SwReg;

                if dSwReg = SwReg then
                    nForceStop <= '0';
                else
                    nForceStop <= '1';
                end if;
            end if;

            if DivCnt = DivCntMax then
                DivCnt <= (others => '0');

                if PwmCnt(PwmCnt'left) = '1' then
                    PwmCnt <= x"01";
                else
                    PwmCnt <= PwmCnt(PwmCnt'left - 1 downto 0) & "1";
                end if;
            elsif nForceStop = '1' then
                DivCnt <= DivCnt + '1';
            end if;

            for i in 0 to (pOutputs - 1) loop
                vTmp := '1';
                for j in PwmCnt'range loop
                    vTmp := (not PwmCnt(j) or PwmMask(i)(j)) and vTmp;
                end loop;

                PwmOut(i) <= vTmp and EnReg(i) and nForceStop;
            end loop;
        end if;
    end process;

end beh1;
