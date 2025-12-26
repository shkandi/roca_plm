-- reg_op.vhd
-- Взаимодействие с регистрами

LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

library work;
use work.roca_src.all;

entity reg_op is
port (
	reset: in std_logic; -- Сброс
	clk: in std_logic; -- Такт
	p_reset: out std_logic; -- Программный сброс
	rec_buf: in arr_26; -- Буфер приема
	snd_buf: out arr_26; -- Буфер отправки
	sw_flag: in std_logic; -- Флаг работы UART send 
	ur_trig: in std_logic; -- Триггер принятых данных
	us_trig: buffer std_logic -- Триггер на отправку
);		
end reg_op;

architecture Behavioral of reg_op is

constant rcom_timer: integer:= 50; -- Таймер выдержки активации команды

signal conv_adr: std_logic_vector (15 downto 0); -- Для конвртации адреса
signal mb_count: natural range 0 to 15; -- Счетчик байт в пакете
signal reg_adr: natural range 0 to 15; -- Адреса регистров для приведения
signal m_trig: std_logic; -- Триггер параметров хода

signal pro_reg: arr_256;
	
Begin

-- Register operator
-- Автомат работы с регистрами		
process (clk)
variable state: integer range 0 to 31; -- Состояние
variable count: integer range 0 to 510; -- Счетчик
variable ur_ctg: std_logic; -- Проверочный триггер UART прием
variable us_ctg: std_logic; -- Проверочный триггер UART отправка
begin	
if (reset = '0') then -- Сброс
	ur_ctg:= ur_trig; -- Ставим проверочный триггер
	us_ctg:= us_trig; -- Ставим проверочный триггер
	p_reset <= '1';
	state:= 0;
	count:= 0;
elsif (rising_edge(clk) and reset = '1') then
	if (state = 0) then -- Состояние 0. Установка стандартных значний регистров
		pro_reg(0) <= x"cf"; 
		pro_reg(1) <= x"01"; 
		pro_reg(2) <= x"00"; 
		pro_reg(16) <= x"00"; 
		pro_reg(17) <= x"aa"; 
		state:= 1;
	elsif (state = 1) then -- Состояние 1. Установка знчений регистров по признакам
		
			
		state:= 2;
	elsif (state = 2) then -- Состояние 2. Просмотр знчаений регистров на признаки действий
		
		-- Просмотр признака сброса
		if (pro_reg(16) = x"ff") then
			p_reset <= '0';
		end if;
		
		-- Просмотр признака параметров хода
		if (pro_reg(21) = x"01") then
			m_trig <= not m_trig;
			pro_reg(21) <= x"00";
		end if;
		
			
		state:= 3; -- Переход на просмотр таймеров
		
	elsif (state = 3) then -- Состояние 3. Просмотр таймеров
		
		
		state:= 10; -- Переход на просмотр триггеров UART
		
	-- UART чтение
	elsif (state = 10) then -- Состояние 10. Просмотр триггера от UART
		if (ur_trig /= ur_ctg) then -- Если есть триггер
			ur_ctg:= ur_trig; -- Сбрасываем проверочный триггер
			if (rec_buf(0) = x"f1" and rec_buf(1) = x"00") then -- Проверям заголовок
				mb_count <= conv_integer(unsigned(rec_buf(2))); -- Конверт std_logic_vector в natural
				conv_adr(15 downto 8) <= rec_buf(7); -- Конвертируем адрес
				conv_adr(7 downto 0) <= rec_buf(6);
				state:= 11;
			else
				state:= 20;
			end if;
		else
			state:= 20;
		end if;
	elsif (state = 11) then -- Состояние 11. Проверка CRC
		if (rec_buf(mb_count + 2) = x"c0" and rec_buf(mb_count + 3) = x"c1") then
			state:= 12;
		else
			state:= 20;
		end if;
	elsif (state = 12) then -- Состояние 12. Конертируем и смотрим команду
		reg_adr <= conv_integer(unsigned(conv_adr)); -- Конверт std_logic_vector в natural
		if (rec_buf(4) = x"00") then
			
			snd_buf(0) <= x"b1";
			snd_buf(1) <= x"00";
			snd_buf(2) <= rec_buf(5) + 6;
			snd_buf(3) <= x"00";
			snd_buf(4) <= x"a0";
			snd_buf(5) <= rec_buf(5);
			snd_buf(6) <= rec_buf(6);
			snd_buf(7) <= rec_buf(7);
			
			count:= 0;
			state:= 13; -- Идем на чтение
		elsif (rec_buf(4) = x"01" or rec_buf(4) = x"02" or rec_buf(4) = x"03") then
			state:= 17; -- Идем на запись
		else
			state:= 20;
		end if;
	
	-- UART чтение
	elsif (state = 13) then -- Состояние 13. Читаем в буфер
		if (count < mb_count) then
			if (reg_adr < 256) then
				snd_buf(8 + count) <= pro_reg(reg_adr);
			else	
				snd_buf(8 + count) <= x"ff";
			end if;
			count:= count + 1;	
			reg_adr <= reg_adr + 1;
		else
			count:= 0;
			state:= 14;
		end if;
	elsif (state = 14) then -- Состояние 14. Подсчет и запись CRC
		snd_buf(mb_count + 2) <= x"c0";
		snd_buf(mb_count + 3) <= x"c1";
		state:= 15;
	elsif (state = 15) then -- Состояние 14. Отправка по UART
		if (sw_flag = '0') then
			us_trig <= not us_trig;
			state:= 20;
		end if;
	
	-- UART запись
	elsif (state = 17) then -- Состояние 17. Записи в регистр
		if (count < mb_count) then
			if (reg_adr < 256 and reg_adr > 15) then
				if (rec_buf(4) = x"01") then
					pro_reg(8 + count) <= pro_reg(reg_adr);
				elsif (rec_buf(4) = x"02") then
					pro_reg(8 + count) <= pro_reg(8 + count) and pro_reg(reg_adr);
				elsif (rec_buf(4) = x"03") then
					pro_reg(8 + count) <= pro_reg(8 + count) or pro_reg(reg_adr);
				end if;
			end if;
			count:= count + 1;	
			reg_adr <= reg_adr + 1;
		else
			count:= 0;
			state:= 20;
		end if;

	elsif (state = 20) then -- Состояние 20.
		
		state:= 30;
	elsif (state = 30) then -- Стостояние 30. Таймер выдержки для акттвации команды
		if (count < rcom_timer) then -- Таймер выдержки команды
			count:= count + 1;
		else
			count:= 0;
			state:= 1;
		end if;
	end if;
end if;
end process;



-- Управление мотором.
process (clk)
variable state: integer range 0 to 7;
variable m_ctg: std_logic; -- Проверочный триггер моторов
begin
if (reset = '0') then -- Сброс
	m_ctg:= m_trig; -- Сбрасываем проверочный триггер
	state:= 0;
elsif (rising_edge(clk) and reset = '1') then
	if (state = 0) then -- Состояние 0. Уставновка переменных 
		if (m_trig /= m_ctg) then
			m_ctg:= m_trig; -- Сбрасываем проверочный триггер
			state:= 1;
		end if;
	elsif (state = 1) then -- Состояние 1. Считывание регистров мотора
		state:= 2;
	elsif (state = 2) then -- Состояние 2. ШИМ и поляность
		state:= 0;
	end if;	
end if;	
end process;



-- Таймер watchdog.
process (clk)
variable s_time: std_logic_vector(15 downto 0);
variable count: integer range 0 to 51000;
variable state: integer range 0 to 7;
begin
if (reset = '0') then -- Сброс
	count:= 0;
	state:= 0;
elsif (rising_edge(clk) and reset = '1') then
	if (state = 0) then -- Состояние 0. Установка переменных.
		state:= 1;
	elsif (state = 1) then -- Состояние 1.
		state:= 2;
	elsif (state = 2) then -- Состояние 2.
		state:= 0;
	end if;	
end if;	
end process;


End;		
