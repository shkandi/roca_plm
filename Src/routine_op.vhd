-- routine_op.vhd
-- Работа с регистрами
LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

library work;
use work.roca_src.all;

entity routine_op is
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
	mark_out			: out std_logic_vector(20 downto 0):= "000000000000000000000"
);		
end routine_op;

architecture Behavioral of routine_op is

type state_type is (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15);
type wr_state_type is (s0, s1);
type mot_state_type is (s0, s1, s2, s3, s4);
type wd_state_type is (s0, s1, s2);


signal state: state_type;
signal w_state: wr_state_type;
signal r_state: wr_state_type;
signal mot_state: mot_state_type;
signal wd_state: wd_state_type;

signal r_front: std_logic_vector(1 downto 0);
signal w_front: std_logic_vector(1 downto 0);

signal fil_str: std_logic_vector(2 downto 0):= "001";
signal mot_str: std_logic_vector(3 downto 0):= "0001";
signal wstr: std_logic_vector(2 downto 0):= "001";
signal rstr: std_logic_vector(2 downto 0):= "001";

signal mot_front: std_logic:= '0'; -- Фронт параметров хода
signal mot_r: std_logic_vector(7 downto 0);
signal mot_l: std_logic_vector(7 downto 0);
signal mot_m: std_logic_vector(7 downto 0);

signal w_count: integer range 0 to 50000;

signal flip: std_logic; -- DEBUG !!!

-- //// MARKER SIGNALS /////
type marr_state is array (0 to 20) of wd_state_type;
signal m_state: marr_state;

signal m_timer: arr_mark;
signal arr_pos: integer range 0 to 20;
signal sm_timer: std_logic_vector(15 downto 0);

signal mw_flag: std_logic;
signal m_clk: std_logic;
signal mp_clk: std_logic;

signal adr: natural range 0 to 63;

signal wod_str: std_logic_vector(2 downto 0):= "001";
signal cout_str: std_logic_vector(5 downto 0):= "000001";
signal word_str: std_logic_vector(1 downto 0):= "01";

signal opr_vect: std_logic_vector(20 downto 0);
signal drf_vect: std_logic_vector(20 downto 0):= "000000000000000000000";
signal sta_vect: std_logic_vector(20 downto 0):= "000000000000000000000";
signal cla_vect: std_logic_vector(20 downto 0):= "000000000000000000000";
signal rot_vect: std_logic_vector(20 downto 0);
signal not_vect: std_logic_vector(20 downto 0);

signal mark_cmp: std_logic_vector(20 downto 0);

Begin

	we_b <= wstr(1); -- Выход на запись
	
	led1 <= flip; -- DEBUG !!!
	
	-- Работа с регистрами
	process (clk)
	begin	
		if rising_edge(clk) then
			case state is
				when s0 => -- Состояние 0. Свободное
					state <= s1;
				when s1 => -- Состояние 1. Запись изначальных значений
					-- Ход записи
					if wstr(wstr'left) = '1' then
						wstr <= "001";
						if fil_str(fil_str'left) = '1' then
							state <= s2;
							fil_str <= "001";
						else
							fil_str <= fil_str(fil_str'left - 1 downto 0) & "0";
						end if;
					else
						wstr <= wstr(wstr'left - 1 downto 0) & "0";
					end if;
					-- Адреса и данные
					if fil_str(0) = '1' then
							addr_b <= 0;
							data_b <= x"cf"; -- Идентификатор
					elsif fil_str(1) = '1' then
						addr_b <= 1;
						data_b <= x"01"; -- Версия ПО
					elsif fil_str(2) = '1' then
						addr_b <= 16;
						data_b <= x"00"; -- Обнуляем регистр сброса
					end if;
				when s2 => -- Состояние 2. Свободное
					state <= s3;
				when s3 => -- Состояние 3. Просмотр регистра сброса
					-- Ход чтения
					if rstr(rstr'left) = '1' then
						rstr <= "001";
						state <= s4; -- Переход на состояние 4
					else
						rstr <= rstr(rstr'left - 1 downto 0) & "0";
					end if;
					-- Адрес и данные
					if rstr(0) = '1' then
						addr_b <= 16;
					elsif rstr(2) = '1' then
						if q_b = x"ff" then -- Если признак сброса
							p_reset <= '0';
						end if;
					end if;
				when s4 => -- Состояние 4.	Свободное
					state <= s7; -- ПЕРЕХОД НА ТАЙМЕРЫ !!!
				when s5 => -- Состояние 5. Просмотр регистров М
					-- Ход чтения
					if rstr(rstr'left) = '1' then
						rstr <= "001";
						if mot_str(mot_str'left) = '1' then
							mot_str <= "0001";
						else
							mot_str <= mot_str(mot_str'left - 1 downto 0) & "0";
						end if;
					else
						rstr <= rstr(rstr'left - 1 downto 0) & "0";
					end if;
					-- Адреса и данные
					if rstr(0) = '1' then
						if mot_str(0) = '1' then
							addr_b <= 18;
						elsif mot_str(1) = '1' then
							addr_b <= 19;
						elsif mot_str(2) = '1' then
							addr_b <= 21;
						elsif mot_str(3) = '1' then
							addr_b <= 21;
						end if;
					elsif rstr(2) = '1' then
						if mot_str(0) = '1' then
							mot_r <= q_b;
						elsif mot_str(1) = '1' then
							mot_l <= q_b;
						elsif mot_str(2) = '1' then
							mot_m <= q_b;
						elsif mot_str(3) = '1' then
							if q_b = x"01" then
								mot_front <= '1';
							end if;
							if q_b /= x"00" then
								state <= s6;
							else
								state <= s15;
							end if;
						end if;
					end if;
				when s6 => -- Состояние 6. Очистка регистра запуска М
					mot_front <= '0';
					-- Ход записи
					if wstr(wstr'left) = '1' then
						wstr <= "001";
						state <= s15; -- Переход на состояние 15
					else
						wstr <= wstr(wstr'left - 1 downto 0) & "0";
					end if;
					-- Сброс данных и фронт блоку М
					if wstr(0) = '1' then
						addr_b <= 21;
						data_b <= x"00";
					end if;

				--- //// РАБОТА С РЕГИСТРАМИ МАРКЕРОВ  ////
				
				when s7 => -- Состояние 7. Просмотр флага старта счетчиков
					-- Ход чтения
					if rstr(rstr'left) = '1' then
						rstr <= "001";
					else
						rstr <= rstr(rstr'left - 1 downto 0) & "0";
					end if;
					-- Адреса и данные
					if rstr(0) = '1' then
						addr_b <= 63;
					elsif rstr(2) = '1' then
						if q_b = x"01" then -- Если признак работы счетчиков
							if mw_flag = '1' then
								state <= s10;
							else
								mw_flag <= '1';
								state <= s8;
							end if;
						else
							mw_flag <= '0';
							state <= s2;
						end if;
					end if;
				when s8 => -- Состояние 8. Подготовка к обнулению
					adr <= 16;
					addr_b <= 16;
					cla_vect <= "000000000000000000000";
					sta_vect <= "000000000000000000000";
					rot_vect <= "000000000000000000001";
					state <= s9;
				when s9 => -- Состояние 9. Обнуление ячеек
					-- Ход записи
					if wstr(wstr'left) = '1' then
						wstr <= "001";
						if word_str(word_str'left) = '1' then
							word_str <= "01";
							if rot_vect(rot_vect'left) = '1' then
								state <= s10; -- Переход на состояние 10
							else
								rot_vect <= rot_vect(rot_vect'left - 1 downto 0) & "0";
							end if;
						else
							word_str <= word_str(word_str'left - 1 downto 0) & "0";
						end if;
					else
						wstr <= wstr(wstr'left - 1 downto 0) & "0";
					end if;
					-- Адреса и данные
					if wstr(0) = '1' then
						data_b <= x"00";
					elsif wstr(1) = '1' then	
						adr <= adr + 1;
					elsif wstr(2) = '1' then
						addr_b <= adr;
					end if;
				when s10 => -- Состояние 10. Загружаем адрес и сдвиги
					adr <= 16;
					addr_b <= 16;
					rot_vect <= "000000000000000000001";
					not_vect <= "111111111111111111110";
					state <= s11;
				when s11 => -- Состояние 11. Контроль ячеек памяти на "0x0000"
					-- Ход чтения
					if rstr(rstr'left) = '1' then
						rstr <= "001";
						if wod_str(wod_str'left) = '1' then
							wod_str <= "001";
							if rot_vect(rot_vect'left) = '1' then
								state <= s12; -- Переход на состояние 12
							else
								rot_vect <= rot_vect(rot_vect'left - 1 downto 0) & "0";
								not_vect <= not_vect(not_vect'left - 1 downto 0) & "1";
							end if;
						else
							wod_str <= wod_str(wod_str'left - 1 downto 0) & "0";
						end if;
					else
						rstr <= rstr(rstr'left - 1 downto 0) & "0";
					end if;
					-- Адреса и данные
					if wod_str(0) = '1' then
						if rstr(1) = '1' then
							adr <= adr + 1;
						elsif rstr(2) = '1' then
							sm_timer(15 downto 8) <= q_b;
							addr_b <= adr;
						end if;
					elsif wod_str(1) = '1' then
						if rstr(1) = '1' then
							adr <= adr + 1;
						elsif rstr(2) = '1' then
							sm_timer(7 downto 0) <= q_b;
							addr_b <= adr;
						end if;
					elsif wod_str(2) = '1' then
						if sm_timer = x"0000" then
							sta_vect <= sta_vect or rot_vect;
							cla_vect <= cla_vect and not_vect;
						end if;
					end if;
				when s12 => -- Состояние 12. Свободное
					state <= s13;
				when s13 => -- Состояние 13. Загружаем адрес и сдвиги
					adr <= 16;
					addr_b <= 16;
					arr_pos <= 0;
					wstr <= "000";
					rot_vect <= "000000000000000000001";
					not_vect <= "111111111111111111110";
					state <= s14;
				when s14 => -- Состояние 14. Проверка готовности таймеров для копии
					-- Ход записи
					if wstr(wstr'left) = '1' then
						wstr <= "000";
						cout_str <= cout_str(cout_str'left - 1 downto 0) & "0";
					else
						wstr <= wstr(wstr'left - 1 downto 0) & "0";
					end if;	
					
					if cout_str(0) = '1' then
						opr_vect <= rot_vect and drf_vect;
						cout_str <= cout_str(cout_str'left - 1 downto 0) & "0";
					elsif cout_str(1) = '1' then
						if opr_vect > 0 then
							data_b <= m_timer(arr_pos)(7 downto 0);
							addr_b <= adr;
							wstr <= "001";
							cout_str <= cout_str(cout_str'left - 1 downto 0) & "0";	
						else
							cout_str <= "100000";
						end if;
					elsif cout_str(3) = '1' then
						data_b <= m_timer(arr_pos)(15 downto 8);
						addr_b <= adr + 1;
						wstr <= "001";
						cla_vect <= cla_vect or rot_vect;
						sta_vect <= sta_vect and not_vect;
						cout_str <= cout_str(cout_str'left - 1 downto 0) & "0";
					elsif cout_str(5) = '1' then
						adr <= adr + 2;
						arr_pos <= arr_pos + 1;
						cout_str <= "000001";
						if rot_vect(rot_vect'left) = '1' then
							wstr <= "001";
							state <= s15; -- Переход на состояние 15
						else
							rot_vect <= rot_vect(rot_vect'left - 1 downto 0) & "0";
							not_vect <= not_vect(not_vect'left - 1 downto 0) & "1";
						end if;
					end if;
				when s15 => -- Состояние 15. Таймер
					if (w_count < 50000) then
						w_count <= w_count + 1;
					else
						w_count <= 0;
						state <= s2;
					end if;
			end case;
		end if;
	end process;
	

	
	-- Управление мот.
	process (clk)
	begin
		if rising_edge(clk) then
			case mot_state is
				when s0 => -- Состояние 0.
					mot_state <= s1;
				when s1 => -- Состояние 1.
					mot_state <= s2;
				when s2 => -- Состояние 2.
					mot_state <= s3;
				when s3 => -- Состояние 3.
					mot_state <= s4;
				when s4 => -- Состояние 4.
					mot_state <= s0;
			end case;
		end if;	
	end process;



	-- Таймер watchdog.
	process (clk)
	begin
		if rising_edge(clk) then
			case wd_state is
				when s0 => -- Состояние 0.
					wd_state <= s1;
				when s1 => -- Состояние 1.
					wd_state <= s2;
				when s2=> -- Состояние 2.
					wd_state <= s0;
			end case;
		end if;	
	end process;
	
	
	
	-- Таймер led
	process (clk)
	variable count: integer range 0 to 25000000;
	begin
		if rising_edge(clk) then
			if mw_flag = '1' then
				if count < 25000000 then
					count:= count + 1;
				else
					count:= 0;
					flip <= not flip;
				end if;
			else
				flip <= '1';
				count:= 0;
			end if;
		end if;	
	end process;
	
	

--	-- Таймер marker clock
--	process (clk)
--	variable count: integer range 0 to 500;
--	begin
--		if rising_edge(clk) then
--			mp_clk <= m_clk;
--			if count < 250 then
--				count:= count + 1;
--			else
--				count:= 0;
--				m_clk <= not m_clk;
--			end if;
--		end if;	
--	end process;
		
	
	-- Таймер маркера 0
	process (clk)
	variable count: integer range 0 to 5000000;
	begin
		if rising_edge(clk) then
			case m_state(0) is
				when s0 => -- Выставление 0 и ожидание 200 мс. 
					mark_out(0) <= '0';
					m_timer(0) <= x"0000";
					drf_vect(0) <= '0';
					if sta_vect(0) = '1' then 
						if mark_in(0) = '0' then
							if count < 5000000 then
								count:= count + 1;
							else
								count:= 0;
								mark_out(0) <= '1';
								m_state(0) <= s1;
							end if;
						else
							count:= 0;
						end if;
					else
						count:= 0;
					end if;
				when s1 => -- Таймер, сигнал или переполнение
					if mark_in(0) = '1' or m_timer(0) = x"ffff" then
						mark_out(0) <= '0';
						count:= 0;
						drf_vect(0) <= '1'; -- Вектор готовности
						m_state(0) <= s2;
					else
						if count < 500 then
							count:= count + 1;
						else
							count:= 0;
							m_timer(0) <= m_timer(0) + 1;
						end if;
					end if;
				when s2 => -- Ожидание чтения значения таймера
					if cla_vect(0) = '1' or mw_flag = '0' then
						m_state(0) <= s0;
					end if;
			end case;		
		end if;
	end process;
	
	
	
	-- Таймер маркера 1
	process (clk)
	variable count: integer range 0 to 5000000;
	begin
		if rising_edge(clk) then
			case m_state(1) is
				when s0 => -- Выставление 0 и ожидание 200 мс. 
					mark_out(1) <= '0';
					m_timer(1) <= x"0000";
					drf_vect(1) <= '0';
					if sta_vect(1) = '1' then 
						if mark_in(1) = '0' then
							if count < 5000000 then
								count:= count + 1;
							else
								count:= 0;
								mark_out(1) <= '1';
								m_state(1) <= s1;
							end if;
						else
							count:= 0;
						end if;
					else
						count:= 0;
					end if;
				when s1 => -- Таймер, сигнал или переполнение
					if mark_in(1) = '1' or m_timer(1) = x"ffff" then
						mark_out(1) <= '0';
						count:= 0;
						drf_vect(1) <= '1'; -- Вектор готовности
						m_state(1) <= s2;
					else
						if count < 500 then
							count:= count + 1;
						else
							count:= 0;
							m_timer(1) <= m_timer(1) + 1;
						end if;
					end if;
				when s2 => -- Ожидание чтения значения таймера
					if cla_vect(1) = '1' or mw_flag = '0' then
						m_state(1) <= s0;
					end if;
			end case;		
		end if;
	end process;
	
	
	
	-- Таймер маркера 2
	process (clk)
	variable count: integer range 0 to 5000000;
	begin
		if rising_edge(clk) then
			case m_state(2) is
				when s0 => -- Выставление 0 и ожидание 200 мс. 
					mark_out(2) <= '0';
					m_timer(2) <= x"0000";
					drf_vect(2) <= '0';
					if sta_vect(2) = '1' then 
						if mark_in(2) = '0' then
							if count < 5000000 then
								count:= count + 1;
							else
								count:= 0;
								mark_out(2) <= '1';
								m_state(2) <= s1;
							end if;
						else
							count:= 0;
						end if;
					else
						count:= 0;
					end if;
				when s1 => -- Таймер, сигнал или переполнение
					if mark_in(2) = '1' or m_timer(2) = x"ffff" then
						mark_out(2) <= '0';
						count:= 0;
						drf_vect(2) <= '1'; -- Вектор готовности
						m_state(2) <= s2;
					else
						if count < 500 then
							count:= count + 1;
						else
							count:= 0;
							m_timer(2) <= m_timer(2) + 1;
						end if;
					end if;
				when s2 => -- Ожидание чтения значения таймера
					if cla_vect(2) = '1' or mw_flag = '0' then
						m_state(2) <= s0;
					end if;
			end case;		
		end if;
	end process;
	

End;		
