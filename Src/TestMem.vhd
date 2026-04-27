library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TestMem is
    port(
        AvWrData        : in std_logic_vector(7 downto 0);
        AvAddr          : in std_logic_vector(3 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdDv          : out std_logic;
        Clk             : in std_logic
    );
end TestMem;

architecture beh1 of TestMem is
    type RamType is array(15 downto 0) of std_logic_vector(7 downto 0);
    signal Ram: RamType;
begin

    AvRdDv <= AvRdRq when rising_edge(Clk);

    process(Clk)
    begin
        if rising_edge(Clk) then
            if AvWrRq = '1' then
                Ram(to_integer(unsigned(AvAddr))) <= AvWrData; 
            end if;

            AvRdData <= Ram(to_integer(unsigned(AvAddr)));
        end if;
    end process;

end beh1;
