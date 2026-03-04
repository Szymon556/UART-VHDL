library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity baud_rate_generator is
	generic(
	--============================--
	-- For MIMAS V2 only 9600     --
	-- and 19200                  --
	--============================--
	--============================--
	--     1200 baud options      --
	--============================--
		N_0: integer := 12;  -- number of bits
		M_0: integer := 5208; -- mod-M
	--============================--
	--      2400 baud options     --
	--============================--
		N_1: integer := 11; 
		M_1: integer := 2604; 
   --============================--
	--      9600 baud options     --
	--============================--
		N_2: integer := 9; 
		M_2: integer := 651; 
   --============================--
	--     19200 baud options     --
	--============================--
		N_3: integer := 8;
		M_3: integer := 325 
	);
	port(
		clk : in std_logic;
		reset : in std_logic;
		baud_conf : in std_logic_vector(1 downto 0);
		max_tick : out std_logic
	);
end baud_rate_generator;

architecture Behavioral of baud_rate_generator is
	signal r_reg, r_next : unsigned(11 downto 0);
	signal M_sel : unsigned(11 downto 0);
begin
	process(clk,reset)
	begin
		if (reset = '0') then
			r_reg <= (others => '0');
		elsif clk'event and clk = '1' then
			r_reg <= r_next;	
		end if;
	end process;
	
	process(baud_conf)
	begin	
		case baud_conf is
			when "00" =>	
				M_sel <= to_unsigned((M_0-1),M_sel'length);
			when "01" =>
				M_sel <= to_unsigned((M_1-1),M_sel'length);
			when "10" =>
				M_sel <= to_unsigned((M_2-1),M_sel'length);
			when others =>
				M_sel <= to_unsigned((M_3-1),M_sel'length);			
		end case;
	end process;
	
	max_tick <= '1' when r_reg = M_sel else '0';
	
	r_next <= (others => '0') when r_reg = M_sel else r_reg + 1;
	
	
end Behavioral;
