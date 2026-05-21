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
    signal DataBufIn: std_logic_vector(7 downto 0);
    signal DataBufOut: std_logic_vector(7 downto 0);

    signal Status: std_logic_vector(7 downto 0);
    signal DevAddr: std_logic_vector(7 downto 0);
    signal RegAddr: std_logic_vector(7 downto 0);

    signal dAvRdRq: std_logic;
begin

    process(Clk)
    begin
        if rising_edge(Clk) then
            dAvRdRq <= AvRdRq;

            case AvAddr is
                when x"8" =>
                    AvRdData <= DevAddr;
                    AvRdVal <= AvRdRq;
                when x"9" =>
                    AvRdData <= RegAddr;
                    AvRdVal <= AvRdRq;
                when x"A" =>
                    AvRdData <= StatusReg;
                    AvRdVal <= AvRdRq;
                when others =>
                    AvRdData <= DataBufOut;
                    AvRdVal <= dAvRdRq;
            end case;

        end if;
    end process;

    process(Clk)
    begin
        if rising_edge(Clk) then
            if WrBuf = '1' then
                DataBuf(conv_integer(AddrBuf)) <= DataBufIn;
            end if;

            DataBufOut <= DataBuf(conv_integer(AddrBuf));
        end if;
    end process;

end beh1;
