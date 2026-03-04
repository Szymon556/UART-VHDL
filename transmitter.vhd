	library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

	entity transmitter is
		generic(
			DBIT_L: integer := 8; -- data bits
			DBIT_S : integer := 7;
			SB_TICK1: integer := 16; -- ticks for stop
			SB_TICK2: integer := 32 -- ticks for stop			
		);
		port(
			clk: in std_logic;
			reset: in std_logic;
			tx_start: in std_logic;
			s_tick: in std_logic;
			din: in std_logic_vector(7 downto 0);
			d_num : in std_logic;
			s_num : in std_logic;
			par : in std_logic_vector(1 downto 0);
			tx_done_tick: out std_logic;
			tx: out std_logic
			
		);
	end transmitter;

	architecture Behavioral of transmitter is
		type state_type is (idle, start, data, parity, stop);
		signal state_reg, state_next : state_type;
		signal s_reg, s_next : unsigned(4 downto 0);
		signal n_reg, n_next : unsigned(2 downto 0);
		signal STOP_TICK : unsigned(4 downto 0);
		signal b_reg, b_next : std_logic_vector(7 downto 0);
		signal tx_reg, tx_next: std_logic;
	begin
		--FSMD registers 
		process(clk,reset)
		begin
			if reset = '0' then
				state_reg <= idle;
				s_reg <= (others => '0');
				n_reg <= (others => '0');
				b_reg <= (others => '0');
				tx_reg <= '1';
			elsif clk'event and clk = '1' then
				state_reg <= state_next;
				s_reg <= s_next;
				n_reg <= n_next;
				b_reg <= b_next;
				tx_reg <= tx_next;
			end if;
		end process;
		
		-- choose stop bits
		process(s_num)
		begin
			if s_num = '0' then
				STOP_TICK <= to_unsigned(SB_TICK1, STOP_TICK'length);
			else
				STOP_TICK <= to_unsigned(SB_TICK2, STOP_TICK'length);
			end if;
		end process;
		
		--next-state logic
		process(state_reg, s_reg, n_reg, b_reg, s_tick,
		tx_reg, tx_start, din,d_num,stop_tick,par)
		begin
			state_next <= state_reg;
			s_next <= s_reg;
			n_next <= n_reg;
			b_next <= b_reg;
			tx_next <= tx_reg;
			tx_done_tick <= '0';
			case state_reg is
				when idle =>
					tx_next <= '1';
					if tx_start = '1' then
						state_next <= start;
						s_next <= (others => '0');
						b_next <= din;
					end if;
				when start =>
					tx_next <= '0';
					if s_tick = '1' then
						if s_reg = 15 then
							state_next <= data;
							s_next <= (others => '0');
							n_next <= (others => '0');
						else
							s_next <= s_reg + 1;
						end if;
					end if;
				when data =>
					tx_next <= b_reg(0);
					if s_tick = '1' then
						if s_reg = 15 then
							s_next <= (others => '0');
							b_next <= '0' & b_reg(7 downto 1);
							if d_num = '1' and n_reg = (DBIT_L - 1) then
								state_next <= parity;
							elsif d_num = '0' and n_reg = (DBIT_S - 1) then
								state_next <= parity;
							else
								n_next <= n_reg + 1;
							end if;
						else
							s_next <= s_reg + 1;
						end if;			
					end if;
				when parity =>
					if par = "00" or par = "11" then
						state_next <= stop;
					else
						if s_tick = '1' then
							if s_reg = 15 then
								s_next <= (others => '0');
								state_next <= stop;
							else
								if par = "01" then --odd parity
									tx_next <= not(b_reg(7) xor b_reg(6) xor b_reg(5)
									xor b_reg(4) xor b_reg(3) xor b_reg(2) xor b_reg(1) xor 
									b_reg(0) xor '1');
								elsif par = "10" then -- Even parity
									tx_next <= b_reg(7) xor b_reg(6) xor b_reg(5)
									xor b_reg(4) xor b_reg(3) xor b_reg(2) xor b_reg(1) xor 
									b_reg(0) xor '1';
								end if;
								s_next <= s_reg + 1;
							end if;
						end if;
					end if;
					
				when stop =>
					tx_next <= '1';
					if s_tick = '1' then
						if s_reg = STOP_TICK then
							state_next <= idle;
							tx_done_tick <= '1';
						else
							s_next <= s_reg + 1;
						end if;
					end if;
			end case;
		end process;
		tx <= tx_reg;
	end Behavioral;
