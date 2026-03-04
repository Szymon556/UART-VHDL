library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity top is
generic(
	-- Default Settings
	DBIT: integer:= 8; -- data bits
   SB_TICK1: integer := 16; -- ticks for stop
	SB_TICK2: integer := 32; -- ticks for stop	
	
	DVSR: integer:=325; -- baud rate DVSR (Oversampling)
	
	DVSR_BIT: integer:=9; -- bits od DVSR
	FIFO_W: integer:=4 -- addr bits of fifo
	
);
port(
	clk : in std_logic;
	reset : in std_logic;
	rd_uart : in std_logic;
	wr_uart : in std_logic;
	rx: in std_logic;
	w_data : in std_logic_vector(7 downto 0);
	conf_buff : in std_logic_vector(1 downto 0);
	d_num : in std_logic;
	s_num : in std_logic;
	par : in std_logic_vector(1 downto 0);
	tx_full : out std_logic;
	rx_empty: out std_logic;
	r_data: out std_logic_vector(7 downto 0);
	tx: out std_logic;
	parity_error : out std_logic

);
end top;

architecture Behavioral of top is
	signal tick : std_logic;
	signal rx_done_tick : std_logic;
	signal tx_fifo_out : std_logic_vector(7 downto 0);
	signal rx_data_out : std_logic_vector(7 downto 0);
	signal tx_empty, tx_fifo_not_empty: std_logic;
	signal tx_done_tick: std_logic;
begin
	baud_gen_unit: entity work.baud_rate_generator(Behavioral)
					  port map(clk=>clk, reset=>reset,max_tick=>tick,baud_conf=>conf_buff);

	uart_rx_unit: entity work.receiver(Behavioral)
					  generic map(DBIT => DBIT, SB_TICK1=>SB_TICK1, SB_TICK2=>SB_TICK2)
					  port map(clk=>clk, reset=> reset, rx=>rx, s_tick=>tick,
					  rx_done_tick=>rx_done_tick, dout=>rx_data_out, d_num=>d_num,s_num=>s_num,
					  par=>par,parity_error => parity_error);
					  
	fifo_rx_unit: entity work.fifo(Behavioral)
					  generic map(B=>DBIT, W=>FIFO_W)
					  port map(clk=>clk, reset=>reset, rd=>rd_uart,
					  wr=>rx_done_tick, w_data=>rx_data_out,empty=>rx_empty,
					  full=>open, r_data=>r_data);
					  
	fifo_tx_unit: entity work.fifo(Behavioral)
					  generic map(B=>DBIT, W=>FIFO_W)
					  port map(clk=>clk, reset=>reset, rd=>tx_done_tick,
					  wr=>wr_uart, w_data=>w_data,empty=>tx_empty,
					  full=>tx_full, r_data=>tx_fifo_out);
	
	uart_tx_unit: entity work.transmitter(Behavioral)
					  generic map(DBIT_L=>DBIT, SB_TICK1=>SB_TICK1,SB_TICK2=>SB_TICK2)
					  port map(clk=>clk, reset=>reset, tx_start=> tx_fifo_not_empty,
					  s_tick=>tick, din=>tx_fifo_out,tx_done_tick=>tx_done_tick,tx=>tx,d_num=>d_num,s_num=>s_num,par=>par);
tx_fifo_not_empty <= not tx_empty;	
			  	
end Behavioral;
