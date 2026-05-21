LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity i2c_master is
	port(
		clk						: in std_logic;
		data_wr					: in std_logic_vector(7 downto 0);
		data_rd					: out std_logic_vector(7 downto 0);
		wr_n					: in std_logic;
		cs						: in std_logic;
		ackd					: out std_logic;
		busy					: out std_logic;
		ack_err					: out std_logic;
		SDA						: inout std_logic;
		SCL						: inout std_logic
	);
end i2c_master;

architecture beh1 of i2c_master is 
	constant divider: integer := 32;
	type StateType is (StandBy, Start, WriteByte, ReadAck, WaitRestart, ReadByte, WriteAck, Stop);
	signal State: StateType;
	signal DCntSR: std_logic_vector(7 downto 0);
	signal I2CRxData: std_logic_vector(7 downto 0);
	signal I2CTxData: std_logic_vector(7 downto 0);
	signal SCL_clk: std_logic;
	signal SCL_en: std_logic;
	signal SCL_state: std_logic_vector(1 downto 0);
	signal SCL_hh: std_logic;
	signal SCL_hl: std_logic;
	signal strech: std_logic;
	signal SDA_out: std_logic;
	signal nWrCmd: std_logic;
	signal busy_int: std_logic;
	
--	           	attribute MARK_DEBUG: string;
--				attribute MARK_DEBUG of State : signal is "TRUE";
	
begin
	
	SCL <= '0' when (SCL_clk = '0' and SCL_en = '1') else 'Z';
	SDA <= '0' when SDA_Out = '0' else 'Z';
	
	process(clk)
		variable count : integer range 0 to 4*divider;
	begin
		if rising_edge(clk) then
			if count = 4*divider then
				count := 0;
			elsif strech /= '1' then	
				count := count + 1;
			end if;

			if SCL_state(1) = '1' and SCL = '0' then
				strech <= '1';
			else
				strech <= '0';
			end if;
			
			SCL_hl <= '0';
			SCL_hh <= '0';
			case count is
				when 0  =>
					SCL_state <= "00";
				when 32 =>
					SCL_hl <= '1';
					SCL_state <= "01";
				when 64 =>
					SCL_state <= "10";
				when 96 =>
					SCL_hh <= '1';
					SCL_state <= "11";
				when others =>
					null;
			end case;
		end if;
	end process;
	
	SCL_clk <= SCL_state(1);
	
	process(clk)
	begin
		if rising_edge(clk) then
			case State is
				when StandBy =>
					SDA_Out <= '1';
					SCL_en <= '0';
					ackd <= cs;
					busy <= '0';
					
					if cs = '1' then
						I2CTxData <= data_wr;
						State <= Start;
						nWrCmd <= wr_n;
						ack_err <= '0';
					end if;
				when Start =>
					ackd <= '0';
					busy <= '1';
					
					DCntSR <= (others => '0');
					
					if SCL_hh = '1' then
						SDA_out <= '0';
						SCL_en <= '1';
						State <= WriteByte;
					end if;
				when WriteByte =>
					ackd <= '0';
					busy <= '1';
					
					if SCL_hl = '1' then
						SDA_out <= I2CTxData(7);
					end if;
					
					if SCL_hh = '1' then
						DCntSR <= DCntSR(6 downto 0) & "1";
						I2CTxData <= I2CTxData(6 downto 0) & "1";
					end if;
					
					if DCntSR(DCntSR'left) = '1' and SCL_hl = '1' then
						State <= ReadAck;
					end if;
				when ReadAck =>
					busy <= '1';
					
					DCntSR <= (others => '0');
					
					if SCL_hh = '1' then
						ack_err <= SDA;
						ackd <= not (SDA or nWrCmd);

						if SDA = '0' and cs = '1' then
							nWrCmd <= wr_n;
							if wr_n = '1' then
								if nWrCmd = '0' then
									State <= Start;
								else
									State <= ReadByte;
								end if;
							else
								State <= WriteByte;
							end if;
							I2CTxData <= data_wr;
						else
							State <= Stop;
						end if;
					end if;
				when ReadByte =>	
					ackd <= '0';
					busy <= '1';
					
					if SCL_hl = '1' then
						SDA_Out <= '1';
					end if;
					
					if SCL_hh = '1' then
						I2CRxData <= I2CRxData(6 downto 0) & (SDA and '1');
						DCntSR <= DCntSR(6 downto 0) & "1";
					end if;
					
					if DCntSR(7) = '1' then
						State <= WriteAck;
						data_rd <= I2CRxData;
					end if;
				when WriteAck =>
					DCntSR <= (others => '0');
					ackd <= SCL_hh;
					busy <= '1';
					
					if SCL_hl = '1' then
						SDA_out <= not cs;
					end if;
					
					if SCL_hh = '1' then
						if cs = '1' then
							State <= ReadByte;
						else
							State <= Stop;
						end if;
					end if;
				when Stop =>
					ackd <= '0';
					busy <= '1';
					
					if SCL_hl = '1' then
						SDA_out <= '0';
					elsif SCL_hh = '1' then
						SCL_en <= '0';
						SDA_out <= '1';
						State <= StandBy;
					end if;
				when others =>
					null;
			end case;
		end if;
	end process;
	
end beh1;
