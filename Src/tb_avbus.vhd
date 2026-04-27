library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_TEXTIO.ALL; 
use STD.TEXTIO.all;

use std.env.all;

entity tb_avbus is
end tb_avbus;

architecture sim1 of tb_avbus is
    signal Clk: std_logic := '0';

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
   
    Clk <= not Clk after 10 ns;

    -- to speedup tests delay between bytes is 100 ns;
    -- uart rx
    process
        file tv: text;
        variable L: line;
        variable vFrame: std_logic_vector(143 downto 0);
        variable vCntF: integer := 0;
    begin
        FILE_OPEN(tv, "frames.tv", READ_MODE);

        while not endfile(tv) loop
            readline(tv, L);
            hread(L, vFrame);
            vCntF := 2 + conv_integer(vFrame(139 downto 136));
            UartRxE <= '0';

            for i in 0 to vCntF loop
                wait until rising_edge(Clk);
                UartRxD <= vFrame(143 downto 136);
                UartRxE <= '1';
                vFrame := vFrame(135 downto 0) & x"00";
                wait until rising_edge(Clk);
                UartRxE <= '0';
                wait until rising_edge(Clk);
                wait until rising_edge(Clk);
                wait until rising_edge(Clk);
                wait until rising_edge(Clk);
            end loop;

       end loop;

       -- stop;
       wait;
    end process;

    process(Clk)
        variable vState: integer := 0;
        variable vCnt: integer := 0;
    begin
        if rising_edge(Clk) then
            case vState is
                when 0 =>
                    if UartTxE = '1' then
                        vState := 1;
                    end if;
                    
                    UartBusy <= UartTxE;
                    vCnt := 0;
                when 1 =>
                    if vCnt = 4 then
                        vState := 0;
                        UartTxE <= '0';
                    end if;

                    vCnt := vCnt + 1;
                when others =>
                    null;
            end case;    
        end if;
    end process;

    AvUart_uut:
    entity work.AvUart
    port map(
        AvAddr              => AvAddrM,            -- : out std_logic_vector(7 downto 0);
        AvWrData            => AvWrDataM,            -- : out std_logic_vector(7 downto 0);
        AvRdData            => AvRdDataM,            -- : in std_logic_vector(7 downto 0);
        AvWrRq              => AvWrRqM,            -- : out std_logic;
        AvRdRq              => AvRdRqM,            -- : out std_logic;
        AvWaitRq            => '0',            -- : in std_logic;
        AvRdDv              => AvRdDvM,            -- : in std_logic;
        Clk                 => Clk,            -- : in std_logic;
        UartBusy            => UartBusy,
        DataRx              => UartRxD,            -- : in std_logic_vector(7 downto 0);
        EnRx                => UartRxE,            -- : in std_logic;
        DataTx              => UartTxD,            -- : out std_logic_vector(7 downto 0);
        EnTx                => UartTxE            -- : out std_logic
    );


    AvInt4_uut:
    entity work.AvInt4
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
        Clk         => Clk            -- : in std_logic
    );

    test_mem_gen:
    for i in 0 to 3 generate
    begin
        TestMem_ent:
        entity work.TestMem
        port map(
            AvWrData        => AvWrDataS,                       -- : in std_logic_vector(7 downto 0);
            AvAddr          => AvAddrS,                         -- : in std_logic_vector(7 downto 0);
            AvRdData        => AvRdDataS(8*i + 7 downto 8*i),                -- : out std_logic_vector(7 downto 0);
            AvWrRq          => AvWrRqS(i),                -- : in std_logic;
            AvRdRq          => AvRdRqS(i),                -- : in std_logic;
            AvRdDv          => AvRdDvS(i),                -- : out std_logic;
            Clk             => Clk                -- : in std_logic
        );
    end generate;

end sim1;
