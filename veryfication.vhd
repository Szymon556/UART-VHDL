library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity veryfication is
	port(
		clk: in std_logic;
		reset: in std_logic;
		btn : in std_logic;
		--rx: in std_logic;
		conf : in std_logic_vector(1 downto 0);
		d_num : in std_logic;
		s_num : in std_logic;
		par : in std_logic_vector(1 downto 0);
		rx_test : in std_logic;
		--tx : out std_logic;
		led : out std_logic_vector(7 downto 0);
		sseg: out std_logic_vector(7 downto 0);
		an: out std_logic_vector(2 downto 0);
		tx_test : out std_logic;
		test: out std_logic;
		btn_tick_test : out std_logic;
		parity_error : out std_logic
	);
end veryfication;

architecture Behavioral of veryfication is
	signal tx_full, rx_empty: std_logic;
	signal rec_data, rec_data1: std_logic_vector(7 downto 0);
	signal btn_tick, prev_tick: std_logic;
	signal conf_buff: std_logic_vector(1 downto 0);
	signal tick : std_logic;
begin
	
	-- rising edge detector
	tick <= '1' when btn_tick = '1' and prev_tick = '0' else '0';
	
	process(reset,clk)
	begin
		if reset = '0' then
			prev_tick <= '0';
		else
			if clk'event and clk = '1' then
				prev_tick <= btn_tick;
			end if;
		end if;
	end process;
	
	uart_unit: entity work.top(Behavioral)
				port map(
					clk=>clk, reset=>reset, rd_uart=>tick,
					wr_uart=>tick, rx=>rx_test, w_data=>rec_data1,
					tx_full=>tx_full, rx_empty=> rx_empty,
					r_data=>rec_data, tx=>tx_test,
					conf_buff => conf_buff,d_num=>d_num,s_num=>s_num,
					par=>par, parity_error=>parity_error
				);
	btn_db_unit: entity work.debouncer(Behavioral)
					port map(clk=>clk, reset=>reset, sw=>btn,
					db=>btn_tick
					);
	rec_data1 <= std_logic_vector(unsigned(rec_data) + 1);
	conf_buff <= conf;
	led <= rec_data;
	an <= "110";
	sseg <= '1' & (not tx_full) & "11" &  (not rx_empty) & "111";
	btn_tick_test <= tick;
end Behavioral;

