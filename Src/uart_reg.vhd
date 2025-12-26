-- uart_reg.vhd
-- Атоматы интерфейса UART

LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

library work;
use work.roca_src.all;

entity uart_reg is
port (
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
end uart_reg;

architecture Behavioral of uart_reg is
	
constant per: integer:= 2604;  -- Скорость UART, 2600 это 19200 бод ???
constant per14: integer:= 650; -- 1/4 интервала при 19200 ???

signal rec_bs: std_logic_vector(7 downto 0);
signal snd_bs: std_logic_vector(7 downto 0);

Begin

-- UART receive 
process (clk)
variable state: integer range 0 to 63; -- Состояние
variable count_tp: integer range 0 to per + 1; -- Счетчик периода и выборки бита
variable sum_tp: integer range 0 to 4; -- Сумма выборок бита
variable num_tp: integer range 0 to 4; -- Номер выборки бита 
variable count_bit: integer range 0 to 8; -- Счетчик битов
variable ur_bcount: integer range 0 to 256; -- Счетчик принятых байтов
variable mp_count: integer range 0 to 8; -- Счетчик между пакетов

variable header_flag: std_logic; -- Флаг заголовка пакета
begin
if (reset = '0') then -- Сброс
	count_tp:= 0;
	sum_tp:= 0;
	num_tp:= 0;
	count_bit:= 0;
	ur_bcount:= 0;
	mp_count:= 0;
	state:= 0;
elsif (rising_edge(clk) and reset = '1') then
	if (state = 0) then -- Состояние 0. Ожидание старт-бита
		if (uart_rx = '0') then -- Если есть признак старт бита
			state:= 1;
			count_tp:= 0;
		else -- Если нет признака старт бита
			if (ur_bcount > 0) then -- Если счетчик байт больше 0 
					if (count_tp < per) then -- Таймер периода  	
						count_tp:= count_tp + 1; 
					else -- Если не было старт-бита за 3 периода, то триггер
						if (mp_count < 3) then
							mp_count:= mp_count + 1;
						else 
							ur_trig <= not ur_trig; -- Триггер принятых данных
							ur_bcount:= 0; -- Счетчик принятых байт = 0
							mp_count:= 0; -- Счетчик между пакетами = 0
							count_tp:= 0;
						end if;
					end if;	
			end if;
		end if;
	elsif (state = 1) then -- Состояние 1. Проверка старт бита
		if (count_tp < per14) then -- Таймер 1/4 периода
			count_tp:= count_tp + 1; 
		else
			count_tp:= 0;
			if (num_tp < 3) then -- Счетчик выборки
				if (uart_rx = '1') then -- Выборка старт бита
					sum_tp:= sum_tp + 1; -- Сумма результатов выборки
				end if;
				num_tp:= num_tp + 1; -- Счетчик выборки +1
			else -- Если сделали 3 выборки старт бита
				num_tp:= 0; -- Обнуляем счетчик выборки
				if (sum_tp < 2) then -- Если выборка в пользу старт бита,
					state:= 2; -- то переходим на состояние 2
				else -- Если выборка не в пользу старт бита, 
					state:= 0; -- то уходим на состояние 1
				end if;
				sum_tp:= 0; -- Обнуляем сумму выборки
			end if;
		end if;
	elsif (state = 2) then -- Состояние 2. Прием битов
		if (count_bit < 8) then -- Счетчик принятых битов
			if (count_tp < per14) then -- Таймер 1/4 периода
				count_tp:= count_tp + 1; 
			else 
				count_tp:= 0;	
				if (num_tp < 3) then -- Счетчик выборки
					if (uart_rx = '1') then -- Выборка
							sum_tp:= sum_tp + 1; -- Сумма результатов выборки
					end if; 
					num_tp:= num_tp + 1; -- Счетчик выборки +1	
				else -- Если сделали 3 выборки бита данных
					num_tp:= 0; -- Обнуляем счетчик выборки	
					rec_bs <= to_stdlogicvector(to_bitvector(rec_bs) ror 1); -- Сдвигаем буфер на 1 вправо
					if (sum_tp > 2) then -- Если выборка в пользу 1,
						rec_bs(7)<= '1'; -- то записываем 1 
					else -- Если нет,
						rec_bs(7)<= '0'; -- то записываем 0 
					end if;
					count_bit:= count_bit + 1; -- Сетчик битов +1
					sum_tp:= 0; -- Обнуляем сумму выборки
				end if;
			end if;
		else -- Если 8 бит принято
			count_bit:= 0; -- Сбрысываем счетчик битов
			state:= 3; -- Переходим на состояние 4 проверки стоп бита
		end if;
	elsif (state = 3) then -- Состояние 3. Проверка стоп бита
		if (count_tp < per14) then -- Таймер 1/4 периода	
			count_tp:= count_tp + 1; 
		else	
			count_tp:= 0;
			if (num_tp < 2) then -- Счетчик выборки
				if (uart_rx = '1') then -- Выборка стоп бита
					sum_tp:= sum_tp + 1; -- Сумма результатов выборки 
				end if;
				num_tp:= num_tp + 1; -- Счетчик выборки +1
			else -- Если сделали 2 выборки стоп бита
				num_tp:= 0; -- Обнуляем счетчик выборки
				if (sum_tp > 1) then -- Если выборка в пользу стоп бита,
					state:= 4; -- то переходим на состояние 4
				else -- Если выборка не в пользу стоп бита,												
					state:= 0;  -- то переходим на состояние 0
				end if;				
				sum_tp:= 0; -- Обнуляем сумму выборки
			end if;
		end if;
	elsif (state = 4) then -- Состояние 4. Счетчик байт
		if (ur_bcount < 26) then -- Если количество байт меньше допустимого
			ur_bcount:= ur_bcount + 1; -- Увеличиваем счетчик байтов
		end if;
		state:= 5;
	elsif (state = 5) then -- Состояние 5. Заносим байт в буфер
		rec_buf(ur_bcount) <= rec_bs;
		state:= 0;
	end if;
end if;
end process;



-- UART send
process (clk)
variable state: integer range 0 to 63; -- Состояние
variable count_p: integer range 0 to per + 1; -- Счетчик периода бита
variable count_bit: integer range 0 to 8; -- Счетчик битов
variable count_bte: integer range 0 to 8; -- Счетчик байтов
variable us_ctg: std_logic:= '0'; -- Контрольный триггер отправки
begin
if (reset = '0') then
	us_ctg:= us_trig;
	count_p:= 0;
	count_bit:= 0;
	count_bte:= 0;
	state:= 0;
elsif (rising_edge(clk) and reset = '1') then
	if (state = 0) then -- Состояние 0. Установка переменных. Инициализация
		uart_tx <= '1'; -- Задаем 1 на линии
		sw_flag <= '0'; -- Флаг работы = 0
		state:= 1;
	elsif (state = 1) then -- Состояние 1. Первичное ожидание триггеров
		if (us_trig /= us_ctg) then -- Проверяем триггер от REG
			us_ctg:= us_trig;
			sw_flag <= '1'; -- Устанавливаем флаг работы
			state:= 2;
		end if; 
	elsif (state = 2) then -- Состояние 2. Старт бит
		if (count_p < per) then -- Таймер периода
			uart_tx <= '0'; -- Устанавливаем 0
			count_p:= count_p + 1;
		else
			snd_bs <= snd_buf(count_bte); -- Загружаем данные
			count_p:= 0;
			state:= 3;
		end if;
	elsif (state = 3) then -- Состояние 3. Отправка битов
		if (count_bit < 8) then -- Счетчик отправленных битов
			if (count_p < per) then -- Таймер периода
				count_p:= count_p + 1;
				uart_tx <= snd_bs(0); -- Выставляем значение из буфера
			else
				count_p:= 0;
				count_bit:= count_bit + 1;
				snd_bs <= to_stdlogicvector(to_bitvector(snd_bs) ror 1); -- Сдвигаем буфер на 1 вправо
			end if;
		else
			count_bit:= 0; -- Обнуляем счетчик битов
			state:= 4; -- Переходим на стоп бит	
		end if;
	elsif (state = 4) then -- Состояние 4. Стоп бит
		if (count_p < per) then -- Таймер периода
			uart_tx <= '1'; -- Устанавливаем 1
			count_p:= count_p + 1; 
		else
			count_p:= 0;
			state:= 5;
		end if;
	elsif (state = 5) then -- Состояние 5. Проверка количества байт
		if (count_bte < snd_buf(2) + 4) then
			count_bte:= count_bte + 1; 
			state:= 2;
		else
			count_bte:= 0;
			state:= 6;
		end if;
	elsif (state = 6) then -- Состояние 6. Выдержка 
		if (count_bte < 3) then
			if (count_p < per) then -- Таймер периода
				count_p:= count_p + 1;
			else
				count_p:= 0;
				count_bte:= count_bte + 1;
			end if;
		else
			count_bte:= 0;
			state:= 0;
		end if;
	end if;
end if;
end process;

End;