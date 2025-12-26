-- roca_plm.vhd

LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;
-- USE ieee.numeric_std.all; -- билииотека отключена т.к. конфликт

library work;
use work.roca_src.all;

entity roca_plm is

Port 
	(
	-- Comon
	hw_reset:in std_logic; -- Аппаратный сброс
	clk_in:in std_logic; -- Внешний такт
	
	-- Indication
	led_activ: out std_logic;
	led_error: out std_logic;

	-- Motor operator
	mfr_pwm: out std_logic; -- Мотор ПП 
	mfr_polar: out std_logic; -- Мотор ПП полярность
	mbr_pwm: out std_logic; -- Мотор ЗП  
	mbr_polar: out std_logic; -- Мотор ЗП полярность
	mfl_pwm: out std_logic; -- Мотор ПЛ 
	mfl_polar: out std_logic; -- Мотор ПЛ полярность
	mbl_pwm: out std_logic; -- Мотор ЗЛ 
	mbl_polar: out std_logic; -- Мотор ЗЛ полярность
	
	-- Trim operator
	trim_1: out std_logic; -- Триммер 1
	trim_2: out std_logic; -- Триммер 2
	trim_3: out std_logic; -- Триммер 3
	trim_4: out std_logic; -- Триммер 4

	-- UART команды и данные
	uart_rx:in std_logic;
	uart_tx:out std_logic
	);

end roca_plm;



architecture Behavioral of roca_plm is

-- PLL для общего тактирования
component clock_pll 
port 
	(
		inclk0: in std_logic;
		c0: out std_logic
	);
end component;
-- Сигналы clock
signal clk: std_logic; -- Общий сигнал тактирования 50 МГц



-- UART обмена данными с MCU
component uart_reg 
port 
	(
	reset: in std_logic; -- Сброс
	clk: in std_logic; -- Такт
	uart_rx: in std_logic; -- Прием Rx
	uart_tx: out std_logic; -- Передача Tx
	rec_buf: out arr_26; -- Буфер приема
	snd_buf: in arr_26; -- Буфер отправки
	sw_flag: out std_logic; -- Флаг работы UART send 
	ur_trig: buffer std_logic; -- Триггер принятых данных
	us_trig: in std_logic -- Триггер на отправку
	);
end component;
-- Исходящие сигналы ea_uart
signal sig_rec_buf: arr_26;
signal sig_sw_flag: std_logic; -- Флаг работы UART send 
signal sig_ur_trig: std_logic; -- Триггер принятых данных



-- Оператор работы с регистрами
component reg_op 
port 
	(
	reset: in std_logic; -- Сброс
	clk: in std_logic; -- Такт
	p_reset: out std_logic; -- Программный сброс
	rec_buf: in arr_26; -- Буфер приема
	snd_buf: out arr_26; -- Буфер отправки
	sw_flag: in std_logic; -- Флаг работы UART send 
	ur_trig: in std_logic; -- Триггер принятых данных
	us_trig: buffer std_logic -- Триггер на отправку
	);
end component;
-- Исходящие сигналы ea_uart
signal sig_p_reset: std_logic; -- Программный сброс
signal sig_snd_buf: arr_26;
signal sig_us_trig: std_logic; -- Триггер на отправку


signal sig_reset: std_logic;

begin

sig_reset <= hw_reset;

-- Назначение компонента PLL
clock: clock_pll  
    port map ( 
      inclk0 => clk_in,
		c0 => clk
	);
	
	
	
-- Назначение компонента UART
uart: uart_reg
	port map (
	reset => sig_reset,
	clk => clk,
	uart_rx => uart_rx,
	uart_tx => uart_tx,
	rec_buf => sig_rec_buf,
	snd_buf => sig_snd_buf,
	sw_flag => sig_sw_flag,
	ur_trig => sig_ur_trig,
	us_trig => sig_us_trig
	);


	
-- Назначение компонента REG
regop: reg_op
	port map (
	reset => sig_reset,
	clk => clk,
	p_reset => sig_p_reset,
	rec_buf => sig_rec_buf,
	snd_buf => sig_snd_buf,
	sw_flag => sig_sw_flag,
	ur_trig => sig_ur_trig,
	us_trig => sig_us_trig
	);


	
end Behavioral;
