LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.all;
USE ieee.numeric_std.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

ENTITY aa_tb_dummy IS
END aa_tb_dummy;

ARCHITECTURE behavior OF aa_tb_dummy IS
	component random_size is
    port (
        Clk: in  std_logic; 
        Enb: in  std_logic; 
        Rst: in  std_logic; 
        Dout: out  std_logic_vector(31 downto 0));
	end component;
	
	signal reset, clk : std_logic;

begin
	
	size_rand_inst : random_size
		port map(Clk  => clk,
		     Enb  => '1',
		     Rst  => reset,
		     Dout => open);

-- 100 MHz system clock
CLOCK_GEN_PROC: process
begin
	CLK <= '1'; wait for 5.0 ns;
	CLK <= '0'; wait for 5.0 ns;
end process CLOCK_GEN_PROC;


testbench_proc : process
begin
	reset <= '1'; 

	wait for 100 ns;
	reset <= '0';
	
	wait for 100 ns;


	wait;

end process testbench_proc;

end; 