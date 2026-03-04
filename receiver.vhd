library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity receiver is
	generic(
		DBIT : integer := 8; -- data bits
		SB_TICK1: integer := 16; -- ticks for stop
		SB_TICK2: integer := 32 	
	);
	port(
		clk : in std_logic;
		reset : in std_logic;
		rx : in std_logic;
		s_tick : in std_logic;
		d_num : in std_logic;
		s_num : in std_logic;
		par : in std_logic_vector(1 downto 0);
		rx_done_tick : out std_logic;
		dout : out std_logic_vector(7 downto 0);
		parity_error : out std_logic
	);
end receiver;

architecture Behavioral of receiver is
	type state_type is (idle, start, data,parity, stop);
	signal state_reg, state_next : state_type;
	signal s_reg, s_next : unsigned(3 downto 0);
	signal n_reg, n_next : unsigned(2 downto 0);
	signal STOP_TICK : unsigned(4 downto 0);
	signal b_reg, b_next : std_logic_vector(7 downto 0);
	signal error_reg, error_next : std_logic;
begin
	-- FSMD state & data registes
	process(clk, reset)
	begin
		if reset = '0' then
			state_reg <= idle;
			s_reg <= (others => '0');
			n_reg <= (others => '0');
			b_reg <= (others => '0');
			error_reg <= '0';
		elsif clk'event and clk = '1' then
			state_reg <= state_next;
			s_reg <= s_next;
			n_reg <= n_next;
			b_reg <= b_next;
			error_reg <= error_next;
		end if;
	end process;
	
	-- choose stop bits
		process(s_num)
		begin
			if s_num = '0' then
				STOP_TICK <= to_unsigned(SB_TICK1 - 1, STOP_TICK'length);
			else
				STOP_TICK <= to_unsigned(SB_TICK2 - 1, STOP_TICK'length);
			end if;
		end process;
	
	-- FSMD next state logic
	process(state_reg,s_reg,n_reg,b_reg,s_tick,rx,d_num, stop_tick,par,
	error_reg)
	begin
		state_next <= state_reg;
		s_next <= s_reg;
		n_next <= n_reg;
		b_next <= b_reg;
		error_next <= error_reg;
		rx_done_tick <= '0';

		case state_reg is
			when idle =>	
				if rx = '0' then
					state_next <= start;
					s_next <= (others => '0');
				end if;
			when start =>
				if s_tick = '1' then
					if s_reg = 7 then
						state_next <= data;
						s_next <= (others => '0');
						n_next <= (others => '0');
					else
						s_next <= s_reg + 1;
					end if;
				end if;
			when data =>
				if s_tick = '1' then
					if s_reg = 15 then
						s_next <= (others => '0');
						b_next <= rx & b_reg(7 downto 1);
						if n_reg = (DBIT - 1) then
							if d_num = '0' then
							 b_next <= '0' & b_reg(7 downto 1);
							end if;
							state_next <= parity;
						else
							n_next <= n_reg + 1;
						end if;
					else
						s_next <= s_reg + 1;
					end if;
				end if;
			when parity =>
				if par = "00" or par ="11" then
					state_next <= stop;
				else 
					if s_tick = '1' then -- get parity bit
						if s_reg = 15 then
							s_next <= (others => '0');
							state_next <= stop;
							if par = "01" then -- Odd parity
								error_next <= not(b_reg(7) xor b_reg(6) xor b_reg(5)
								xor b_reg(4) xor b_reg(3) xor b_reg(2) xor b_reg(1) xor 
								b_reg(0) xor rx);
							elsif par = "10" then -- Even parity
								error_next <= b_reg(7) xor b_reg(6) xor b_reg(5)
								xor b_reg(4) xor b_reg(3) xor b_reg(2) xor b_reg(1) xor 
								b_reg(0) xor rx;
							end if;
						else
							s_next <= s_reg + 1; 
						end if;
					end if;
				end if;
			when stop =>
				if s_tick = '1' then
					if s_reg = STOP_TICK then
						state_next <= idle;
						rx_done_tick <= '1';
					else
						s_next <= s_reg + 1;
					end if;
				end if;
		end case;
	end process;
	dout <= b_reg;
	parity_error <= error_reg;
end Behavioral;
