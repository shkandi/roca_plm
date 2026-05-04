library ieee;
use ieee.std_logic_1164.all;

-- need to add package with version iterable by tcl script

entity MainInfo is
    port(
        AvAddr          : in std_logic_vector(3 downto 0);
        AvWrData        : in std_logic_vector(7 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdVal         : out std_logic;
        Clk             : in std_logic;
        RstOut          : out std_logic
    );
end MainInfo;

architecture beh1 of MainInfo is
    constant cDevId: std_logic_vector(7 downto 0) := x"CF";
    constant cVerMaj: std_logic_vector(7 downto 0) := x"01";
    constant cVerMin: std_logic_vector(7 downto 0) := x"02";

    signal RstRg: std_logic_vector(7 downto 0);
begin
    process(Clk)
    begin
        if rising_edge(Clk) then
            case AvAddr is
                when x"0" =>
                    AvRdData <= cDevId;
                when x"1" =>
                    AvRdData <= cVerMaj;
                when x"2" =>
                    AvRdData <= cVerMin;
                when x"F" =>
                    if AvWrRq = '1' then
                        RstRg <= AvWrData;
                    end if;
                    
                    AvRdData <= RstRg;
                when others => 
                    AvRdData <= x"00";
            end case;

            AvRdVal <= AvRdRq;

            if RstRg = x"FF" then
                RstOut <= '1';
            else
                RstOut <= '0';
            end if;
        end if;
    end process;
end beh1;
