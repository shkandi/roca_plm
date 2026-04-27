-- roca_plm.vhd
LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;
-- USE ieee.numeric_std.all; -- билииотека отключена т.к. конфликт

library work;
use work.roca_src.all;

entity roca_plm is
	port(
		-- Common
		hw_reset				: in std_logic; -- Аппаратный сброс
		clk_in				: in std_logic; -- Внешний такт
	
		-- Indication
		led_1					: out std_logic;
		led_2					: out std_logic;

		-- Motor operator
		mfr_pwm				: out std_logic; -- Мот ПП 
		mfr_polar			: out std_logic; -- Мот ПП полярность
		mbr_pwm				: out std_logic; -- Мот ЗП  
		mbr_polar			: out std_logic; -- Мот ЗП полярность
		mfl_pwm				: out std_logic; -- Мот ПЛ 
		mfl_polar			: out std_logic; -- Мот ПЛ полярность
		mbl_pwm				: out std_logic; -- Мот ЗЛ 
		mbl_polar			: out std_logic; -- Мот ЗЛ полярность
	
		-- Trim operator
		trim_1				: out std_logic; -- Трим 1
		trim_2				: out std_logic; -- Трим 2
		trim_3				: out std_logic; -- Трим 3
		trim_4				: out std_logic; -- Трим 4
	
		
		-- Debug pin
		pin_d					: out std_logic_vector (7 downto 0); -- DEBUG
		
		-- Markers
		mark_in				: in std_logic_vector(20 downto 0);
		mark_out				: out std_logic_vector(20 downto 0);


		-- UART команды и данные
		uart_rx				:in std_logic;
		uart_tx				:out std_logic
	);
end roca_plm;



architecture Behavioral of roca_plm is

	-- PLL для общего тактирования
	component clock_pll 
	port(
		inclk0		:in std_logic;
		c0				:out std_logic
	);
	end component clock_pll;
	
	
	-- SRAM для проектных регистров
	component pro_ram 
	port(
		clk			: in std_logic;
		addr_a		: in natural range 0 to 63;
		addr_b		: in natural range 0 to 63;
		data_a		: in std_logic_vector(7 downto 0);
		data_b		: in std_logic_vector(7 downto 0);
		we_a			: in std_logic;
		we_b			: in std_logic;
		q_a			: out std_logic_vector(7 downto 0);
		q_b			: out std_logic_vector(7 downto 0)
	);
	end component pro_ram;


	-- UART Tima
	component uart_tima is
	generic(
        pFreq           : integer := 50000000;
        pBaudRate       : integer := 19200
	);
	port (
    DataIn          : in std_logic_vector(7 downto 0);
    EnIn            : in std_logic;
    Clk             : in std_logic;
    Rx              : in std_logic;
    Tx              : out std_logic;
    TxBusy          : out std_logic;
    DataOut         : out std_logic_vector(7 downto 0);
    EnOut           : out std_logic
    );
	end component uart_tima;


	-- Блок работы с кадром UART 
	component frame_op
	generic(
		noact_cn			: integer := 64000
	);
	port (
		clk				: in std_logic; -- Такт
		uart_rec			: in std_logic_vector (7 downto 0); -- Байт на прием
		uart_snd			: out std_logic_vector (7 downto 0); -- Байт на отправку
		rec_front		: in std_logic; -- Сигнал байт принят
		snd_front		: buffer std_logic; -- Сигнал на отправку байта		
		sw_flag			: in std_logic; -- Флаг работы передатчика
		addr_a			: out natural range 0 to 63;
		data_a			: out std_logic_vector(7 downto 0);
		we_a				: out std_logic;
		q_a				: in std_logic_vector(7 downto 0)
	);
	end component frame_op;


	-- Блок работы с проектными регистрами
	component routine_op is
	port (
		led1				: out std_logic; -- DEBUG 
		led2				: out std_logic; -- DEBUG
		clk				: in std_logic; -- Такт
		p_reset			: out std_logic; -- Программный сброс
		addr_b			: out natural range 0 to 63;
		data_b			: out std_logic_vector(7 downto 0);
		we_b				: out std_logic;
		q_b				: in std_logic_vector(7 downto 0);
		mark_in			: in std_logic_vector(20 downto 0);
		mark_out			: out std_logic_vector(20 downto 0)
		);
	end component routine_op;


	-- Cигналы общие
	signal sig_reset: std_logic;
	signal clk: std_logic; -- Общий сигнал тактирования 50 МГц
	
	-- Сигналы SRAM проекнтых регистров
	signal sig_pram_adr_a: natural range 0 to 63;
	signal sig_pram_adr_b: natural range 0 to 63;
	signal sig_pram_data_a: std_logic_vector(7 downto 0);
	signal sig_pram_data_b: std_logic_vector(7 downto 0);
	signal sig_pram_we_a: std_logic;
	signal sig_pram_we_b: std_logic;
	signal sig_pram_q_a: std_logic_vector(7 downto 0);
	signal sig_pram_q_b: std_logic_vector(7 downto 0);
	
	-- Сигналы для UART
	signal sig_uart_rec: std_logic_vector (7 downto 0);
	signal sig_uart_snd: std_logic_vector (7 downto 0);
	signal sig_rec_front: std_logic;
	signal sig_snd_front: std_logic;
	signal sig_sw_flag: std_logic;


begin

	sig_reset <= '1';

	-- Назначение компонента PLL
	clock_ent: clock_pll  
   port map( 
      inclk0		=> clk_in,
		c0				=> clk
	);


	-- Назначение компонента проектных регистров
	prore_ent: pro_ram  
	port map( 
		clk			=> clk,
		addr_a		=> sig_pram_adr_a,
		addr_b		=> sig_pram_adr_b,
		data_a		=> sig_pram_data_a,
		data_b		=> sig_pram_data_b,
		we_a			=> sig_pram_we_a,
		we_b			=> sig_pram_we_b,
		q_a			=> sig_pram_q_a,
		q_b			=> sig_pram_q_b
	);
	
	
	-- Назначение компонента UART
	uart_ent: uart_tima  
	generic map(
		pFreq               => 50000000,
		pBaudRate           => 19200
   )
	port map( 
		DataIn		=> sig_uart_snd,
		EnIn			=> sig_snd_front,
		Clk			=> clk,
		Rx				=> uart_rx,
		Tx				=> uart_tx,
		TxBusy		=> sig_sw_flag,
		DataOut		=> sig_uart_rec,
		EnOut			=> sig_rec_front
	);

	
	-- Назначение компонента работы с UART
	frame: frame_op  
	generic map(
		noact_cn       => 64000
	)
	port map( 
		clk				=> clk,
		uart_rec			=> sig_uart_rec,
		uart_snd			=> sig_uart_snd,
		rec_front		=> sig_rec_front,
		snd_front		=> sig_snd_front,
		sw_flag			=> sig_sw_flag,
		addr_a			=> sig_pram_adr_a,
		data_a			=> sig_pram_data_a,
		we_a				=> sig_pram_we_a,
		q_a				=> sig_pram_q_a
	);


	-- Назначение компонента routine_op
	routine: routine_op  
	port map( 
		led1			=> led_1, -- DEBUG !!!
		led2			=> led_2, -- DEBUG !!!
		clk			=> clk,
		addr_b		=> sig_pram_adr_b,
		data_b		=> sig_pram_data_b,
		we_b			=> sig_pram_we_b,
		q_b			=> sig_pram_q_b,
		mark_in		=> mark_in,
		mark_out		=> mark_out
	);
	

end Behavioral;
