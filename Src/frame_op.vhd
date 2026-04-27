-- frame_op.vhd
-- Примем и пересылка пакетов от UART

LIBRARY ieee;

USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

library work;
use work.roca_src.all;

entity frame_op is
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
end frame_op;

architecture Behavioral of frame_op is

	type state_type is (wait_id, wait_code, read_mem, write_mem, write_logic);
	signal state: state_type;

	signal count_sb: natural range 0 to 20; 
	signal count_max: natural range 0 to 20; 
	signal ur_adr: natural range 0 to 63; 
	
	signal com_sav: std_logic_vector(1 downto 0); 
	signal count_sav: std_logic_vector(3 downto 0); 
	signal addr_sav: std_logic_vector(5 downto 0); 
	signal wstr: std_logic_vector(2 downto 0):= "001";
	signal rstr: std_logic_vector(1 downto 0):= "01";
	
	signal unac_flag: std_logic:= '0';
	constant unac_max: integer:= noact_cn; 

Begin

	we_a <= wstr(1); -- Выход на запись

	-- Оператор кадра UART
	process (clk)
	begin
		if rising_edge(clk) then
			case state is
				when wait_id => -- Состояние. Ожидание байта с заголовком
				
					wstr <= "001";
					rstr <= "01";
					count_sb <= 0;
					if rec_front = '1' and uart_rec(7 downto 4) = x"A" then
						count_max <= conv_integer(unsigned(uart_rec(3 downto 0))) + 1;
						count_sav <= uart_rec(3 downto 0);
						state <= wait_code;
					end if;
					
				when wait_code => -- Сщстояние. Ожидание байта c кодом и адресом
				
					if rec_front = '1' then
						ur_adr <= conv_integer(unsigned(uart_rec(5 downto 0)));
						addr_sav <= uart_rec(5 downto 0);
						if uart_rec(7 downto 6) = "00" then
							state <= read_mem;
							count_max <= count_max + 2;
							addr_a <= conv_integer(unsigned(uart_rec(5 downto 0)));
						elsif uart_rec(7 downto 6) = "01" then
							state <= write_mem;
						else
							com_sav <= uart_rec(7 downto 6);
							state <= write_logic;
						end if;
					else
						if unac_flag = '1' then
							state <= wait_id;
						end if;
					end if;
					
				when read_mem => -- Состояние. Чтение из памяти и отправка
				
					if snd_front = '0' then
						if count_sb < count_max then
							if sw_flag = '0' then
								if count_sb = 0 then
									uart_snd(7 downto 4) <= x"B";
									uart_snd(3 downto 0) <= count_sav;
									snd_front <= '1';
								elsif count_sb = 1 then
									uart_snd(7 downto 6) <= "00";
									uart_snd(5 downto 0) <= addr_sav;
									snd_front <= '1';
								else
									ur_adr <= ur_adr + 1;
									uart_snd <= q_a;
									snd_front <= '1';
								end if;
							end if;
						else
							state <= wait_id;
						end if;
					else
						addr_a <= ur_adr;
						snd_front <= '0';
						count_sb <= count_sb + 1;	
					end if;
					
				when write_mem => -- Состояние. Запись в память
				
					if wstr(0) = '1' then
						if rec_front = '1' then
							addr_a <= ur_adr;
							data_a <= uart_rec;
							wstr <= wstr(wstr'left - 1 downto 0) & "0";
						else
							if unac_flag = '1' then
								state <= wait_id;
							end if;
						end if;
					else
						wstr <= wstr(wstr'left - 1 downto 0) & "0";
					end if;
					
					if wstr(wstr'left) = '1' then
						wstr <= "001";
						if count_sb < count_max then
							count_sb <= count_sb + 1;
							ur_adr <= ur_adr + 1;
						else
							state <= wait_id;
						end if;
					end if;
				
				when write_logic => -- Состояние. Логическая запись в память

					if rstr(0) = '1' then
						addr_a <= ur_adr;
						rstr <= rstr(rstr'left - 1 downto 0) & "0";
					end if;
					
					if rstr(rstr'left) = '1' then
						if wstr(0) = '1' then
							if rec_front = '1' then
								if com_sav = "10" then
									data_a <= uart_rec and q_a;
									wstr <= wstr(wstr'left - 1 downto 0) & "0";
								elsif com_sav = "11" then
									data_a <= uart_rec or q_a;
									wstr <= wstr(wstr'left - 1 downto 0) & "0";
								end if;
							else
								if unac_flag = '1' then
									state <= wait_id;
								end if;
							end if;
						else
							wstr <= wstr(wstr'left - 1 downto 0) & "0";
						end if;
					
						if wstr(wstr'left) = '1' then
							wstr <= "001";
							rstr <= "01";
							if count_sb < count_max then
								count_sb <= count_sb + 1;
								ur_adr <= ur_adr + 1;
							else
								state <= wait_id;
							end if;
						end if;
					end if;
			end case;
		end if;
	end process;


	-- Counter no UART activity
	process (clk)
	variable count: integer range 0 to unac_max + 1;
	begin
		if rising_edge(clk) then
			if rec_front = '0' then	
				if count < unac_max then
					count:= count + 1; 
				else 
					count:= 0;
					unac_flag <= '1';
				end if;
			else
				count:= 0;
				unac_flag <= '0';
			end if;
		end if;
	end process;

	
End;