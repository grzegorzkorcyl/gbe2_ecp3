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

ENTITY testbench_sctrl IS
END testbench_sctrl;

ARCHITECTURE behavior OF testbench_sctrl IS

signal clk, reset, wr_en, activate, read, dataready : std_logic;
signal data : std_logic_vector(8 downto 0);

signal reply_dataready, reply_busy  :std_logic;
signal reply_data : std_logic_vector(15 downto 0);
signal reply_packet_num : std_logic_vector(2 downto 0);
signal selected : std_logic;

begin

SCTRL : trb_net16_gbe_response_constructor_SCTRL
generic map( STAT_ADDRESS_BASE => 8
)
port map (
	CLK			            => CLK,
	RESET			        => RESET,
	
-- INTERFACE	
	PS_DATA_IN		        => data,
	PS_WR_EN_IN		        => wr_en,
	PS_ACTIVATE_IN		    => activate,
	PS_RESPONSE_READY_OUT	=> open,
	PS_BUSY_OUT		        => open,
	PS_SELECTED_IN		    => selected,
	
	PS_SRC_MAC_ADDRESS_IN	=> (others => '0'),
	PS_DEST_MAC_ADDRESS_IN  => (others => '0'),
	PS_SRC_IP_ADDRESS_IN	=> (others => '0'),
	PS_DEST_IP_ADDRESS_IN	=> (others => '0'),
	PS_SRC_UDP_PORT_IN	    => (others => '0'),
	PS_DEST_UDP_PORT_IN	    => (others => '0'),
	
	TC_RD_EN_IN             => '1',
	TC_DATA_OUT		        => open,
	TC_FRAME_SIZE_OUT	    => open,
	TC_FRAME_TYPE_OUT	    => open,
	TC_IP_PROTOCOL_OUT	    => open,
	TC_IDENT_OUT            => open,
	
	TC_DEST_MAC_OUT		    => open,
	TC_DEST_IP_OUT		    => open,
	TC_DEST_UDP_OUT		    => open,
	TC_SRC_MAC_OUT		    => open,
	TC_SRC_IP_OUT		    => open,
	TC_SRC_UDP_OUT		    => open,
	
	STAT_DATA_OUT           => open,
	STAT_ADDR_OUT           => open,
	STAT_DATA_RDY_OUT       => open,
	STAT_DATA_ACK_IN        => '0',
	RECEIVED_FRAMES_OUT	    => open,
	SENT_FRAMES_OUT		    => open,
	-- END OF INTERFACE
	
	GSC_CLK_IN              => clk,
	GSC_INIT_DATAREADY_OUT  => dataready,
	GSC_INIT_DATA_OUT       => open,
	GSC_INIT_PACKET_NUM_OUT => open,
	GSC_INIT_READ_IN        => read,
	GSC_REPLY_DATAREADY_IN  => reply_dataready,
	GSC_REPLY_DATA_IN       => reply_data,
	GSC_REPLY_PACKET_NUM_IN => reply_packet_num,
	GSC_REPLY_READ_OUT      => open,
	GSC_BUSY_IN             => reply_busy,
	
	MAKE_RESET_OUT          => open,
	
	
	DEBUG_OUT		        => open
);

-- 100 MHz system clock
CLOCK_GEN_PROC: process
begin
	CLK <= '1'; wait for 5.0 ns;
	CLK <= '0'; wait for 5.0 ns;
end process CLOCK_GEN_PROC;



testbench_proc : process
begin
	
	wait for 100 ns;
	reset <= '1';
	read <= '0';
	data <= (others => '0');
	wr_en <= '0';
	activate <= '0';
	selected <= '0';
	reply_dataready <= '0';
	reply_busy <= '0';
	reply_data <= (others => '0');
	wait for 100 ns;
	reset <= '0';
	
	wait for 100 ns;

---- REPLY TESTBENCH
----	
	for i in 0 to 100 loop
	
		wait until rising_edge(clk);
		reply_dataready <= '1';
		reply_busy <= '1';
		reply_data <= std_logic_vector(to_unsigned(i, 16));
			
	end loop;
	wait until rising_edge(clk);
	reply_dataready <= '0';
	reply_busy <= '0';
	
	wait for 100 ns;
	selected <= '1';
	
	wait;
	
-- REQUEST TESTBENCH
--	activate <= '1';
--	
--	
--	wait until rising_edge(clk);
--	data <= '0' & x"ab";
--	wr_en <= '1';
--	wait until rising_edge(clk);
--	data <= '0' & x"cd";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"31";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"ff";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"08";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"30";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"50";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"33";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '0' & x"00";
--	wait until rising_edge(clk);
--	data <= '1' & x"08";
--	wait until rising_edge(clk);
--	wr_en <= '0';
--	activate <= '0';
--	
--	wait until rising_edge(dataready);
------	wait until rising_edge(clk);
------	read <= '1';
----	wait until rising_edge(clk);
----	read <= '0';
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	read <= '1';
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	read <= '0';
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	read <= '1';
	
	wait;

end process testbench_proc;

end; 