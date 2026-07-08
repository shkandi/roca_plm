library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity tb_i2c is
end tb_i2c;

architecture sim1 of tb_i2c is
    signal clk_m: std_logic := '0';
    signal clk_s: std_logic := '0';
    signal rst: std_logic := '0';
    
    signal scl: std_logic;
    signal scl_oe: std_logic;
    signal sda: std_logic;
    signal sda_oe: std_logic;
    
    signal AvAddr: std_logic_vector(3 downto 0);
    signal AvWrData: std_logic_vector(7 downto 0);
    signal AvRdData: std_logic_vector(7 downto 0);
    signal AvWrRq: std_logic;
    signal AvRdRq: std_logic;
    signal AvRdVal: std_logic;
    
    signal DataM2S: std_logic_vector(7 downto 0);
    signal DataS2M: std_logic_vector(7 downto 0);
    signal nWr: std_logic;
    signal CS: std_logic;
    signal AckD: std_logic;
    signal BusBusy: std_logic;
    signal AckErr: std_logic;

    type MemArrType is array(15 downto 0) of std_logic_vector(7 downto 0);
    signal MemArr: MemArrType;

    signal MemD: std_logic_vector(7 downto 0);
    signal MemQ: std_logic_vector(7 downto 0);
    signal AVal: std_logic;
    signal RdAck: std_logic;
    signal MemWrRq: std_logic;
    signal AddrCnt: std_logic_vector(3 downto 0);
begin

	scl <= 'H';
	sda <= 'H';

    test_proc:
    process(clk_m)
        variable vState: integer := 0;
    begin
        if rising_edge(clk_m) then
            if rst = '0' then
                case vState is
                    when 0 =>
                        null;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;


    AvI2C_uut:
    entity work.AvI2C
    port map(
        AvAddr          => AvAddr,            -- : in std_logic_vector(3 downto 0);
        AvWrData        => AvWrData,            -- : in std_logic_vector(7 downto 0);
        AvRdData        => AvRdData,            -- : out std_logic_vector(7 downto 0);
        AvWrRq          => AvWrRq,            -- : in std_logic;
        AvRdRq          => AvRdRq,            -- : in std_logic;
        AvRdVal         => AvRdVal,            -- : out std_logic;
        Clk             => clk_m,            -- : in std_logic;
        DataM2S         => DataM2S,            -- : out std_logic_vector(7 downto 0);
        DataS2M         => DataS2M,            -- : in std_logic_vector(7 downto 0);
        AckD            => AckD,            -- : in std_logic;
        nWr             => nWr,            -- : out std_logic;
        Cs              => CS,            -- : out std_logic;
        BusBusy         => BusBusy,            -- : in std_logic;
        AckErr          => AckErr            -- : in std_logic
    );

    i2c_master_uut:
    entity work.i2c_master
    port map(
            clk         => clk_m,            --                                    : in std_logic;
            data_wr     => DataM2S,            --                            : in std_logic_vector(7 downto 0);
            data_rd     => DataS2M,            --                            : out std_logic_vector(7 downto 0);
            wr_n        => nWr,            --                            : in std_logic;
            cs          => CS,            --                                    : in std_logic;
            ackd        => AckD,            --                            : out std_logic;
            busy        => BusBusy,            --                            : out std_logic;
            ack_err     => AckErr,            --                            : out std_logic;
            sda         => sda,            --                                    : inout std_logic;
            sda_oe      => sda_oe,            --                                    : inout std_logic;
            scl         => scl,            --                                    : inout std_logic
            scl_oe      => scl_oe            --                                    : inout std_logic
    );

    sda <= '0' when sda_oe = '1' else 'H';
    scl <= '0' when scl_oe = '1' else 'H';
    ------------------------------------------

	i2c_mem_uut:
	entity work.i2c_slave
	generic map(
		pDevId			=> x"A2"			-- : std_logic_vector(7 downto 0) := x"B0"
	)
	port map(
		DataIn			=> MemQ,				-- : in std_logic_vector(7 downto 0);
		Rst				=> rst,				-- : in std_logic;
		Clk				=> clk_s,				-- : in  std_logic;
		DataOut			=> MemD,				-- : out std_logic_vector(7 downto 0);
		AddrVal			=> AVal,				-- : out std_logic;
		RdAck			=> RdAck,				-- : out std_logic;
		WrRq			=> MemWrRq,				-- : out std_logic;
		SDA				=> sda,				-- : inout std_logic;
		SCL				=> scl				-- : in std_logic
	);

	mem_proc:
	process(clk_s)
	begin
		if rising_edge(clk_s) then
			if AVal = '1' then
				AddrCnt <= MemD(3 downto 0);
			elsif MemWrRq = '1' or RdAck = '1' then
				AddrCnt <= AddrCnt + '1';
			end if;

			if MemWrRq = '1' then
				MemArr(conv_integer(AddrCnt)) <= MemD;
			end if;
		end if;
	end process;

	MemQ <= MemArr(conv_integer(AddrCnt));

end sim1;
