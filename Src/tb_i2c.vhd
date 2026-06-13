 
	scl <= 'H';
	sda <= 'H';

	i2c_mem_uut:
	entity work.i2c_slave
	generic map(
		pDevId			=> x"A2"			-- : std_logic_vector(7 downto 0) := x"B0"
	)
	port map(
		DataIn			=> MemQ,				-- : in std_logic_vector(7 downto 0);
		Rst				=> rst_mgmt,				-- : in std_logic;
		Clk				=> clk_mgmt,				-- : in  std_logic;
		DataOut			=> MemD,				-- : out std_logic_vector(7 downto 0);
		AddrVal			=> AVal,				-- : out std_logic;
		RdAck			=> RdAck,				-- : out std_logic;
		WrRq			=> MemWrRq,				-- : out std_logic;
		SDA				=> sda,				-- : inout std_logic;
		SCL				=> scl				-- : in std_logic
	);

	mem_proc:
	process(clk_mgmt)
	begin
		if rising_edge(clk_mgmt) then
			if AVal = '1' then
				AddrCnt <= MemD;
			elsif MemWrRq = '1' or RdAck = '1' then
				AddrCnt <= AddrCnt + '1';
			end if;

			if MemWrRq = '1' then
				MemArr(conv_integer(AddrCnt)) <= MemD;
			end if;
		end if;
	end process;

	MemQ <= MemArr(conv_integer(AddrCnt));
