library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity i2c_slave is
	generic(
		pDevId			: std_logic_vector(7 downto 0) := x"B0"
	);
	port(
		DataIn			: in std_logic_vector(7 downto 0);
		Rst				: in std_logic;
		Clk				: in  std_logic;
		DataOut			: out std_logic_vector(7 downto 0);
		AddrVal			: out std_logic;
		RdAck			: out std_logic;
		WrRq			: out std_logic;
		SDA				: inout std_logic;
		SCL				: in std_logic
	);
end i2c_slave;

architecture beh1 of i2c_slave is
	signal SDAOut: std_logic;
	signal SCLSr: std_logic_vector(2 downto 0);
	signal SDASr: std_logic_vector(2 downto 0);
	signal SCLVal: std_logic;
	signal dSCLVal: std_logic;
	signal SDAVal: std_logic;
	signal dSDAVal: std_logic;
	signal I2CAckIn: std_logic;
    
    signal RstInt: std_logic;
    signal RstBus: std_logic;
	signal nIdCmp: std_logic;

    signal SCntSr: std_logic_vector(1 downto 0);
	signal DCntSr: std_logic_vector(7 downto 0);
	signal InputSr: std_logic_vector(7 downto 0);
	signal OutputSr: std_logic_vector(7 downto 0);
	signal nEnWrSl: std_logic;
    signal nEnRdSl: std_logic;
begin
	
	SDA <= '0' when SDAOut = '0' else 'Z';
	
	RstInt <= Rst or RstBus;

	process(Clk)
		variable vEnBus: std_logic;
	begin
		if rising_edge(Clk) then
			SCLSr <= SCLSr(SCLSr'left - 1 downto 0) & SCL;
			SDASr <= SDASr(SCLSr'left - 1 downto 0) & SDA;
			
			case SCLSr is
				when "000"|"001"|"010"|"100" =>
					SCLVal <= '0';
				when others =>
					SCLVal <= '1';
			end case;
			
			case SDASr is
				when "000"|"001"|"010"|"100" =>
					SDAVal <= '0';
				when others =>
					SDAVal <= '1';
			end case;
			
			dSCLVal <= SCLVal;
			dSDAVal <= SDAVal;

            if SCLVal = '1' and ((dSDAVal xor SDAVal) = '1') then
                RstBus <= '1';
            else
                RstBus <= '0';
            end if;

            if dSCLVal = '0' and SCLVal = '1' then
			    InputSr <= InputSr(InputSr'left - 1 downto 0) & SDAVal;
            end if;
			
            if RstInt = '1' then
                DCntSr <= (others => '0');
                SCntSr <= (others => '0');
				RdAck <= '0';
				OutputSr <= pDevId;
				nIdCmp <= '0';
				I2CAckIn <= '0';
            elsif dSCLVal = '0' and SCLVal = '1' then
                if DCntSr(DCntSr'left) = '1' then
                    DCntSr <= (others => '0');
                    SCntSr <= SCntSr(0) & "1";
                else
                    DCntSr <= DCntSr(DCntSr'left - 1 downto 0) & "1";
                end if;    
				
				nIdCmp <= nIdCmp or (not DCntSr(6) and (OutputSr(7) xor SDAVal));
				
				if DCntSr(7) = '1' then
					OutputSr <= DataIn;
					RdAck <= not (nEnRdSl or SDAVal);
					I2CAckIn <= SDAVal;
                else
                    OutputSr <= OutputSr(6 downto 0) & "1";
                end if;
			else
				RdAck <= '0';
            end if;
			
			if RstInt = '1' then
				AddrVal <= '0';
				WrRq <= '0';
				SDAOut <= '1';
				nEnRdSl <= '1';
				nEnWrSl <= '1';
            elsif dSCLVal = '1' and SCLVal = '0' then
				if DCntSr(7) = '1' and SCntSr(0) = '0' then
					nEnWrSl <= nIdCmp or InputSr(0);
					nEnRdSl <= not InputSr(0) or nIdCmp;
				end if;
				
				if DCntSr(7) = '1' then
					SDAOut <= nEnWrSl and (SCntSr(0) or nIdCmp);
				else
					SDAOut <= nEnRdSl or OutputSr(7) or I2CAckIn;
				end if;
				
				WrRq <= not nEnWrSl and DCntSr(7) and SCntSr(1);
				
				if DCntSr(7) = '1' and SCntSr(1) = '0' and nEnWrSl = '0' then
					AddrVal <= '1';
				end if;
			else
				WrRq <= '0';
				AddrVal <= '0';
            end if;
		end if;
	end process;
	
	DataOut <= InputSr;

end beh1;
