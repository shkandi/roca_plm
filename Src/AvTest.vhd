library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity AvTest is
	port(
		UartRx	: in std_logic;
		UartTx	: out std_logic;
		Clk		: in std_logic;
		Led		: out std_logic
	);
end AvTest;

architecture beh1 of AvTest is
	
    component AvUart is
    generic(
        pFreq           : integer := 50000000;
        pBaudRate       : integer := 9600
    );
    port(
        AvAddr              : out std_logic_vector(7 downto 0);
        AvWrData            : out std_logic_vector(7 downto 0);
        AvRdData            : in std_logic_vector(7 downto 0);
        AvWrRq              : out std_logic;
        AvRdRq              : out std_logic;
        AvWaitRq            : in std_logic;
        AvRdDv              : in std_logic;
        Clk                 : in std_logic;
        UartRx              : in std_logic;
        UartTx              : out std_logic
    );
    end component AvUart;
    
    component TestMem is
    port(
        AvWrData        : in std_logic_vector(7 downto 0);
        AvAddr          : in std_logic_vector(7 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdDv          : out std_logic;
        Clk             : in std_logic
    );
    end component TestMem;
    
--	component uart is
--    generic(
--        pFreq           : integer := 50000000;
--        pBaudRate       : integer := 14400
--    );
--    port(
--        DataIn          : in std_logic_vector(7 downto 0);
--        EnIn            : in std_logic;
--        Clk             : in std_logic;
--        Rx              : in std_logic;
--        Tx              : out std_logic;
--        TxBusy          : out std_logic;
--        DataOut         : out std_logic_vector(7 downto 0);
--        EnOut           : out std_logic
--    );
--	end component uart;

	signal Cnt: std_logic_vector(25 downto 0);
	
	signal DataLb: std_logic_vector(7 downto 0);
	signal EnLb: std_logic;
    
    signal AvWrData: std_logic_vector(7 downto 0);
    signal AvAddr: std_logic_vector(7 downto 0);   
    signal AvRdData: std_logic_vector(7 downto 0);
    signal AvWrRq: std_logic;  
    signal AvRdRq: std_logic;  
    signal AvRdDv: std_logic;  
    
begin
	
--	process(Clk)
--	begin
--		if rising_edge(Clk) then
--			Led <= Cnt(Cnt'left);
--			Cnt <= Cnt + '1';
--		end if;
--	end process;
	
--	uart_ent:
--	uart
--    generic map(
--        pFreq           => 50000000,			-- : integer := 50000000;
--        pBaudRate       => 9600			-- : integer := 9600
--    )
--    port map(
--        DataIn          => DataLb,				-- : in std_logic_vector(7 downto 0);
--        EnIn            => EnLb,				-- : in std_logic;
--        Clk             => Clk,				-- : in std_logic;
--        Rx              => UartRx,				-- : in std_logic;
--        Tx              => UartTx,				-- : out std_logic;
--        TxBusy          => open,				-- : out std_logic;
--        DataOut         => DataLb,				-- : out std_logic_vector(7 downto 0);
--        EnOut           => EnLb				-- : out std_logic
--    );
	
    AvUart_ent:
	AvUart
    generic map(
        pFreq               => 50000000,            -- : integer := 50000000;
        pBaudRate           => 9600            -- : integer := 9600
    )
    port map(
        AvAddr              => AvAddr,                -- : out std_logic_vector(15 downto 0);
        AvWrData            => AvWrData,                -- : out std_logic_vector(15 downto 0);
        AvRdData            => AvRdData,                -- : in std_logic_vector(15 downto 0);
        AvWrRq              => AvWrRq,                -- : out std_logic;
        AvRdRq              => AvRdRq,                -- : out std_logic;
        AvWaitRq            => '0',                -- : in std_logic;
        AvRdDv              => AvRdDv,                -- : in std_logic;
        Clk                 => Clk,                -- : in std_logic;
        UartRx              => UartRx,                -- : in std_logic;
        UartTx              => UartTx                -- : out std_logic
    );
    
    TestMem_ent:
    TestMem
    port map(
        AvWrData        => AvWrData,                -- : in std_logic_vector(7 downto 0);
        AvAddr          => AvAddr,                -- : in std_logic_vector(7 downto 0);
        AvRdData        => AvRdData,                -- : out std_logic_vector(7 downto 0);
        AvWrRq          => AvWrRq,                -- : in std_logic;
        AvRdRq          => AvRdRq,                -- : in std_logic;
        AvRdDv          => AvRdDv,                -- : out std_logic;
        Clk             => Clk                -- : in std_logic
    );
    
end beh1;
