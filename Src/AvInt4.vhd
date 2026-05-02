library ieee;
use ieee.std_logic_1164.all;


entity AvInt4 is
    port(
        AddrM       : in std_logic_vector(5 downto 0);
        WrDataM     : in std_logic_vector(7 downto 0);
        RdDataM     : out std_logic_vector(7 downto 0);
        WrRqM       : in std_logic;
        RdRqM       : in std_logic;
        RdVM        : out std_logic;
        AddrS       : out std_logic_vector(3 downto 0);
        WrDataS     : out std_logic_vector(7 downto 0);
        RdDataS     : in std_logic_vector(31 downto 0);
        WrRqS       : out std_logic_vector(3 downto 0);
        RdRqS       : out std_logic_vector(3 downto 0);
        RdVS        : in std_logic_vector(3 downto 0);
        Clk         : in std_logic
    );
end AvInt4;

architecture beh1 of AvInt4 is
    type RdDataType is array(3 downto 0) of std_logic_vector(7 downto 0);
    signal RdDataInt: RdDataType;
    signal RdVMask: std_logic_vector(3 downto 0);
begin
    
    rddata_gen:
    for i in 0 to 3 generate
    begin
        RdDataInt(i) <= RdDataS(8*i + 7 downto 8*i);
    end generate;


    process(Clk)
        variable vRdVal: std_logic;
        variable vRdDataAnd: RdDataType;
        variable vRdData: std_logic_vector(7 downto 0);
    begin
        if rising_edge(Clk) then
            AddrS <= AddrM(3 downto 0);
            WrDataS <= WrDataM;

            case AddrM(5 downto 4) is
                when "00" =>
                    WrRqS <= "000" & WrRqM;
                    RdRqS <= "000" & RdRqM;
                    RdVMask <= x"1";
                when "01" =>
                    WrRqS <= "00" & WrRqM & "0";
                    RdRqS <= "00" & RdRqM & "0";
                    RdVMask <= x"2";
                when "10" =>
                    WrRqS <= "0" & WrRqM & "00";
                    RdRqS <= "0" & RdRqM & "00";
                    RdVMask <= x"4";
                when "11" =>
                    WrRqS <= WrRqM & "000";
                    RdRqS <= RdRqM & "000";
                    RdVMask <= x"8";
                when others =>
                    null;
            end case;

            vRdVal := '0';
            for i in 0 to 3 loop
                vRdVal := vRdVal or (RdVMask(i) and RdVS(i));

                if RdVMask(i) = '1' then
                    vRdData := x"FF";
                else
                    vRdData := x"00";
                end if;

                vRdDataAnd(i) := RdDataInt(i) and vRdData;
            end loop;
            RdVM <= vRdVal;
            
            vRdData := x"00";
            for i in 0 to 3 loop
                vRdData := vRdData or vRdDataAnd(i);
            end loop;
            RdDataM <= vRdData;
        end if;
    end process;
end beh1;
