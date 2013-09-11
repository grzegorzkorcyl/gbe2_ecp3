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

ENTITY aa_tb_mac_control IS
END aa_tb_mac_control;

ARCHITECTURE behavior OF aa_tb_mac_control IS

signal clk, reset,RX_MAC_CLK : std_logic;
signal tsm_ready, tsm_reconf, tsm_hcs_n, tsm_hwrite_n, tsm_hread_n : std_logic;
signal tsm_haddr, tsm_hdata : std_logic_vector(7 downto 0);
begin

TSMAC_CONTROLLER : trb_net16_gbe_mac_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signals to/from main controller
	MC_TSMAC_READY_OUT	=> tsm_ready,
	MC_RECONF_IN		=> tsm_reconf,
	MC_GBE_EN_IN		=> '1',
	MC_RX_DISCARD_FCS	=> '0',
	MC_PROMISC_IN		=> '1',
	MC_MAC_ADDR_IN		=> g_MY_MAC, --x"001122334455",

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		=> tsm_haddr,
	TSM_HDATA_OUT		=> tsm_hdata,
	TSM_HCS_N_OUT		=> tsm_hcs_n,
	TSM_HWRITE_N_OUT	=> tsm_hwrite_n,
	TSM_HREAD_N_OUT		=> tsm_hread_n,
	TSM_HREADY_N_IN		=> '1',
	TSM_HDATA_EN_N_IN	=> '1',

	DEBUG_OUT		=> open
);

process
begin
	clk <= '0';
	wait for 5 ns;
	clk <= '1';
	wait for 5 ns;
end process;

testbench_proc : process
begin
	reset <= '1';
	wait for 100 ns;
	reset <= '0';
	wait;
end process testbench_proc;



end; 