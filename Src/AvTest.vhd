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
	
    component clock_pll 
    port (
        inclk0: in std_logic;
        c0: out std_logic;
        locked: out std_logic
    );
    end component clock_pll;
    
    component AvUartHD is
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
    end component AvUartHD;
    
    component AvInt4 is
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
    end component AvInt4;
    
	component uart is
    generic(
        pFreq           : integer := 50000000;
        pBaudRate       : integer := 14400
    );
    port(
        DataIn          : in std_logic_vector(7 downto 0);
        EnIn            : in std_logic;
        Clk             : in std_logic;
        Rx              : in std_logic;
        Tx              : out std_logic;
        TxBusy          : out std_logic;
        DataOut         : out std_logic_vector(7 downto 0);
        EnOut           : out std_logic
    );
	end component uart;
    
    component TestMem is
    port(
        AvWrData        : in std_logic_vector(7 downto 0);
        AvAddr          : in std_logic_vector(3 downto 0);
        AvRdData        : out std_logic_vector(7 downto 0);
        AvWrRq          : in std_logic;
        AvRdRq          : in std_logic;
        AvRdDv          : out std_logic;
        Clk             : in std_logic
    );
    end component TestMem;

	signal Cnt50: std_logic_vector(25 downto 0);
    signal PllLocked: std_logic;
    signal Clk50: std_logic;
    signal Rst: std_logic;
	
	signal UartRxD: std_logic_vector(7 downto 0);
    signal UartRxE: std_logic;
    signal UartTxD: std_logic_vector(7 downto 0);
    signal UartTxE: std_logic;
    signal UartBusy: std_logic;

    signal AvAddrM: std_logic_vector(5 downto 0);  
    signal AvWrDataM: std_logic_vector(7 downto 0);
    signal AvRdDataM: std_logic_vector(7 downto 0);
    signal AvWrRqM: std_logic;  
    signal AvRdRqM: std_logic;  
    signal AvRdDvM: std_logic;  

    signal AvAddrS: std_logic_vector(3 downto 0);  
    signal AvWrDataS: std_logic_vector(7 downto 0);
    signal AvRdDataS: std_logic_vector(31 downto 0);
    signal AvWrRqS: std_logic_vector(3 downto 0);  
    signal AvRdRqS: std_logic_vector(3 downto 0);  
    signal AvRdDvS: std_logic_vector(3 downto 0);
    
begin
	
--	process(Clk)
--	begin
--		if rising_edge(Clk) then
--			Led <= Cnt(Cnt'left);
--			Cnt <= Cnt + '1';
--		end if;
--	end process;
	
    clock_main: 
    clock_pll  
    port map ( 
        inclk0  => Clk,
        c0      => Clk50,
        locked  => PllLocked
	);
    
    Rst <= not PllLocked;
    
	uart_ent:
	uart
    generic map(
        pFreq           => 50000000,			-- : integer := 50000000;
        pBaudRate       => 115200			-- : integer := 9600
    )
    port map(
        DataIn          => UartTxD,				-- : in std_logic_vector(7 downto 0);
        EnIn            => UartTxE,				-- : in std_logic;
        Clk             => Clk50,				-- : in std_logic;
        Rx              => UartRx,				-- : in std_logic;
        Tx              => UartTx,				-- : out std_logic;
        TxBusy          => UartBusy,				-- : out std_logic;
        DataOut         => UartRxD,				-- : out std_logic_vector(7 downto 0);
        EnOut           => UartRxE				-- : out std_logic
    );
	
    AvUart_ent:
    AvUartHD
    port map(
        AvAddr              => AvAddrM,            -- : out std_logic_vector(7 downto 0);
        AvWrData            => AvWrDataM,            -- : out std_logic_vector(7 downto 0);
        AvRdData            => AvRdDataM,            -- : in std_logic_vector(7 downto 0);
        AvWrRq              => AvWrRqM,            -- : out std_logic;
        AvRdRq              => AvRdRqM,            -- : out std_logic;
        AvWaitRq            => Rst,            -- : in std_logic;
        AvRdDv              => AvRdDvM,            -- : in std_logic;
        Rst                 => Rst,
        Clk                 => Clk50,            -- : in std_logic;
        UartBusy            => UartBusy,
        DataRx              => UartRxD,            -- : in std_logic_vector(7 downto 0);
        EnRx                => UartRxE,            -- : in std_logic;
        DataTx              => UartTxD,            -- : out std_logic_vector(7 downto 0);
        EnTx                => UartTxE            -- : out std_logic
    );

    AvInt4_ent:
    AvInt4
    port map(
        AddrM       => AvAddrM,            -- : in std_logic_vector(5 downto 0);
        WrDataM     => AvWrDataM,            -- : in std_logic_vector(7 downto 0);
        RdDataM     => AvRdDataM,            -- : out std_logic_vector(7 downto 0);
        WrRqM       => AvWrRqM,            -- : in std_logic;
        RdRqM       => AvRdRqM,            -- : in std_logic;
        RdVM        => AvRdDvM,            -- : out std_logic;
        AddrS       => AvAddrS,            -- : out std_logic_vector(3 downto 0);
        WrDataS     => AvWrDataS,            -- : out std_logic_vector(7 downto 0);
        RdDataS     => AvRdDataS,            -- : in std_logic_vector(31 downto 0);
        WrRqS       => AvWrRqS,            -- : out std_logic_vector(3 downto 0;
        RdRqS       => AvRdRqS,            -- : out std_logic_vector(3 downto 0;
        RdVS        => AvRdDvS,            -- : in std_logic_vector(3 downto 0;
        Clk         => Clk50            -- : in std_logic
    );
    
    test_mem_gen:
    for i in 0 to 3 generate
    begin
        TestMem_ent:
        TestMem
        port map(
            AvWrData        => AvWrDataS,                -- : in std_logic_vector(7 downto 0);
            AvAddr          => AvAddrS,                -- : in std_logic_vector(7 downto 0);
            AvRdData        => AvRdDataS(8*i + 7 downto 8*i),                -- : out std_logic_vector(7 downto 0);
            AvWrRq          => AvWrRqS(i),                -- : in std_logic;
            AvRdRq          => AvRdRqS(i),                -- : in std_logic;
            AvRdDv          => AvRdDvS(i),                -- : out std_logic;
            Clk             => Clk50                -- : in std_logic
        );
    end generate;
    
end beh1;
