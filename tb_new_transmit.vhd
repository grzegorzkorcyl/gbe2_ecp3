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

ENTITY testbench_new_transmit IS
END testbench_new_transmit;

ARCHITECTURE behavior OF testbench_new_transmit IS

signal clk, reset,RX_MAC_CLK : std_logic;
signal fc_data                   : std_logic_vector(7 downto 0);
signal fc_wr_en                  : std_logic;
signal fc_sod                    : std_logic;
signal fc_eod                    : std_logic;
signal fc_h_ready                : std_logic;
signal fc_ip_size                : std_logic_vector(15 downto 0);
signal fc_udp_size               : std_logic_vector(15 downto 0);
signal fc_ready                  : std_logic;
signal fc_dest_mac               : std_logic_vector(47 downto 0);
signal fc_dest_ip                : std_logic_vector(31 downto 0);
signal fc_dest_udp               : std_logic_vector(15 downto 0);
signal fc_src_mac                : std_logic_vector(47 downto 0);
signal fc_src_ip                 : std_logic_vector(31 downto 0);
signal fc_src_udp                : std_logic_vector(15 downto 0);
signal fc_type                   : std_logic_vector(15 downto 0);
signal fc_ihl                    : std_logic_vector(7 downto 0);
signal fc_tos                    : std_logic_vector(7 downto 0);
signal fc_ident                  : std_logic_vector(15 downto 0);
signal fc_flags                  : std_logic_vector(15 downto 0);
signal fc_ttl                    : std_logic_vector(7 downto 0);
signal fc_proto                  : std_logic_vector(7 downto 0);
signal tc_src_mac                : std_logic_vector(47 downto 0);
signal tc_dest_mac               : std_logic_vector(47 downto 0);
signal tc_src_ip                 : std_logic_vector(31 downto 0);
signal tc_dest_ip                : std_logic_vector(31 downto 0);
signal tc_src_udp                : std_logic_vector(15 downto 0);
signal tc_dest_udp               : std_logic_vector(15 downto 0);
signal tc_dataready, tc_rd_en, tc_done : std_logic;
signal tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_data : std_logic_vector(8 downto 0);
signal tc_frame_size, tc_size_left, tc_frame_type, tc_flags, tc_ident : std_logic_vector(15 downto 0);
signal response_ready, selected, dhcp_start, mc_busy : std_logic;

signal ps_data : std_logic_vector(8 downto 0);
signal ps_wr_en, ps_rd_en, ps_frame_ready : std_logic;
signal ps_proto, ps_busy : std_logic_vector(5 downto 0);
signal ps_frame_size : std_logic_vector(15 downto 0);

signal gsc_reply_dataready, gsc_busy : std_logic;
signal gsc_reply_data : std_logic_vector(15 downto 0);

begin

MAIN_CONTROL : trb_net16_gbe_main_control
  port map(
	  CLK			=> CLK,
	  CLK_125		=> RX_MAC_CLK,
	  RESET			=> RESET,

	  MC_LINK_OK_OUT	=> open,
	  MC_RESET_LINK_IN	=> '0',
	  MC_IDLE_TOO_LONG_OUT => open,

  -- signals to/from receive controller
	  RC_FRAME_WAITING_IN	=> ps_frame_ready,
	  RC_LOADING_DONE_OUT	=> open,
	  RC_DATA_IN		=> ps_data,
	  RC_RD_EN_OUT		=> ps_rd_en,
	  RC_FRAME_SIZE_IN	=> ps_frame_size,
	  RC_FRAME_PROTO_IN	=> ps_proto,

	RC_SRC_MAC_ADDRESS_IN	=> x"001122334455",
	RC_DEST_MAC_ADDRESS_IN  => x"001122334455",
	RC_SRC_IP_ADDRESS_IN	=> x"c0a80001",
	RC_DEST_IP_ADDRESS_IN	=> x"c0a80003",
	RC_SRC_UDP_PORT_IN	    => x"c350",
	RC_DEST_UDP_PORT_IN	    => x"c350",

	  -- signals to/from transmit controller
	  TC_TRANSMIT_CTRL_OUT	=> tc_dataready,
	  
	TC_DATA_OUT				=> tc_data,
	TC_RD_EN_IN				=> tc_rd_en,
	TC_FRAME_SIZE_OUT	    => tc_frame_size,
	TC_FRAME_TYPE_OUT	    => tc_frame_type,
	TC_IP_PROTOCOL_OUT	    => tc_ip_proto,
	TC_IDENT_OUT            => tc_ident,
	
	TC_DEST_MAC_OUT		    => tc_dest_mac,
	TC_DEST_IP_OUT		    => tc_dest_ip,
	TC_DEST_UDP_OUT		    => tc_dest_udp,
	TC_SRC_MAC_OUT		    => tc_src_mac,
	TC_SRC_IP_OUT		    => tc_src_ip,
	TC_SRC_UDP_OUT		    => tc_src_udp,
  	TC_TRANSMIT_DONE_IN		=> tc_done,

  -- signals to/from sgmii/gbe pcs_an_complete
	  PCS_AN_COMPLETE_IN	=> '1',

  -- signals to/from hub
	GSC_CLK_IN               => '0',
	GSC_INIT_DATAREADY_OUT   => open,
	GSC_INIT_DATA_OUT        => open,
	GSC_INIT_PACKET_NUM_OUT  => open,
	GSC_INIT_READ_IN         => '0',
	GSC_REPLY_DATAREADY_IN   => gsc_reply_dataready,
	GSC_REPLY_DATA_IN        => gsc_reply_data,
	GSC_REPLY_PACKET_NUM_IN  => (others => '0'),
	GSC_REPLY_READ_OUT       => open,
	GSC_BUSY_IN              => gsc_busy,

	MAKE_RESET_OUT           => open, --MAKE_RESET_OUT,
	
	CTS_NUMBER_IN				=> (others => '0'),
	CTS_CODE_IN					=> (others => '0'),
	CTS_INFORMATION_IN			=> (others => '0'),
	CTS_READOUT_TYPE_IN			=> (others => '0'),
	CTS_START_READOUT_IN		=> '0',
	CTS_DATA_OUT				=> open,
	CTS_DATAREADY_OUT			=> open,
	CTS_READOUT_FINISHED_OUT	=> open,
	CTS_READ_IN					=> '0',
	CTS_LENGTH_OUT				=> open,
	CTS_ERROR_PATTERN_OUT		=> open,
	-- Data payload interface
	FEE_DATA_IN					=> (others => '0'),
	FEE_DATAREADY_IN			=> '0',
	FEE_READ_OUT				=> open,
	FEE_STATUS_BITS_IN			=> (others => '0'),
	FEE_BUSY_IN					=> '0',
	-- ip configurator
	SLV_ADDR_IN                  => (others => '0'),
	SLV_READ_IN                  => '0',
	SLV_WRITE_IN                 => '0',
	SLV_BUSY_OUT                 => open,
	SLV_ACK_OUT                  => open,
	SLV_DATA_IN                  => (others => '0'),
	SLV_DATA_OUT                 => open,
	
	CFG_GBE_ENABLE_IN           => '0',
	CFG_IPU_ENABLE_IN           => '0',
	CFG_MULT_ENABLE_IN          => '0',
	
	MC_UNIQUE_ID_IN => (others => '0'),

  -- signal to/from Host interface of TriSpeed MAC
	  TSM_HADDR_OUT		=> open,
	  TSM_HDATA_OUT		=> open,
	  TSM_HCS_N_OUT		=> open,
	  TSM_HWRITE_N_OUT	=> open,
	  TSM_HREAD_N_OUT	=> open,
	  TSM_HREADY_N_IN	=> '0',
	  TSM_HDATA_EN_N_IN	=> '0',
	  TSM_RX_STAT_VEC_IN  => (others => '0'),
	  TSM_RX_STAT_EN_IN   => '0',
	  
	  SELECT_REC_FRAMES_OUT		=> open,
	  SELECT_SENT_FRAMES_OUT	=> open,
	  SELECT_PROTOS_DEBUG_OUT	=> open,

	  DEBUG_OUT		=> open
  );

transmit_controller : trb_net16_gbe_transmit_control2
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	TC_DATAREADY_IN        => tc_dataready,
	TC_RD_EN_OUT		        => tc_rd_en,
	TC_DATA_IN		        => tc_data(7 downto 0),
	TC_FRAME_SIZE_IN	    => tc_frame_size,
	TC_FRAME_TYPE_IN	    => tc_frame_type,
	TC_IP_PROTOCOL_IN	    => tc_ip_proto,	
	TC_DEST_MAC_IN		    => tc_dest_mac,
	TC_DEST_IP_IN		    => tc_dest_ip,
	TC_DEST_UDP_IN		    => tc_dest_udp,
	TC_SRC_MAC_IN		    => tc_src_mac,
	TC_SRC_IP_IN		    => tc_src_ip,
	TC_SRC_UDP_IN		    => tc_src_udp,
	TC_TRANSMISSION_DONE_OUT => tc_done,
	TC_IDENT_IN            => tc_ident,
	
-- signal to/from frame constructor
	FC_DATA_OUT		=> fc_data,
	FC_WR_EN_OUT		=> fc_wr_en,
	FC_READY_IN		=> fc_ready,
	FC_H_READY_IN		=> fc_h_ready,
	FC_FRAME_TYPE_OUT	=> fc_type,
	FC_IP_SIZE_OUT		=> fc_ip_size,
	FC_UDP_SIZE_OUT		=> fc_udp_size,
	FC_IDENT_OUT		=> fc_ident,
	FC_FLAGS_OFFSET_OUT	=> fc_flags,
	FC_SOD_OUT		=> fc_sod,
	FC_EOD_OUT		=> fc_eod,
	FC_IP_PROTOCOL_OUT	=> fc_proto,

	DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
	DEST_IP_ADDRESS_OUT     => fc_dest_ip,
	DEST_UDP_PORT_OUT       => fc_dest_udp,
	SRC_MAC_ADDRESS_OUT     => fc_src_mac,
	SRC_IP_ADDRESS_OUT      => fc_src_ip,
	SRC_UDP_PORT_OUT        => fc_src_udp,

	DEBUG_OUT		=> open
);

frame_constructor : trb_net16_gbe_frame_constr
port map( 
	-- ports for user logic
	RESET                   => RESET,
	CLK                     => CLK,
	LINK_OK_IN              => '1',
	--
	WR_EN_IN                => fc_wr_en,
	DATA_IN                 => fc_data,
	START_OF_DATA_IN        => fc_sod,
	END_OF_DATA_IN          => fc_eod,
	IP_F_SIZE_IN            => fc_ip_size,
	UDP_P_SIZE_IN           => fc_udp_size,
	HEADERS_READY_OUT       => fc_h_ready,
	READY_OUT               => fc_ready,
	DEST_MAC_ADDRESS_IN     => fc_dest_mac,
	DEST_IP_ADDRESS_IN      => fc_dest_ip,
	DEST_UDP_PORT_IN        => fc_dest_udp,
	SRC_MAC_ADDRESS_IN      => fc_src_mac,
	SRC_IP_ADDRESS_IN       => fc_src_ip,
	SRC_UDP_PORT_IN         => fc_src_udp,
	FRAME_TYPE_IN           => fc_type,
	IHL_VERSION_IN          => fc_ihl,
	TOS_IN                  => fc_tos,
	IDENTIFICATION_IN       => fc_ident,
	FLAGS_OFFSET_IN         => fc_flags,
	TTL_IN                  => fc_ttl,
	PROTOCOL_IN             => fc_proto,
	FRAME_DELAY_IN          => x"0000_0000",
	-- ports for packetTransmitter
	RD_CLK                  => RX_MAC_CLK,
	FT_DATA_OUT             => open,
	FT_TX_EMPTY_OUT         => open,
	FT_TX_RD_EN_IN          => '1',
	FT_START_OF_PACKET_OUT  => open,
	FT_TX_DONE_IN           => '1',
	FT_TX_DISCFRM_IN	=> '0',
	-- debug ports
	BSM_CONSTR_OUT          => open,
	BSM_TRANS_OUT           => open,
	DEBUG_OUT               => open
);


g_MAX_FRAME_SIZE <= x"0fd0";


-- 125 MHz MAC clock
CLOCK2_GEN_PROC: process
begin
	RX_MAC_CLK <= '1'; wait for 3.0 ns;
	RX_MAC_CLK <= '0'; wait for 4.0 ns;
end process CLOCK2_GEN_PROC;

-- 100 MHz system clock
CLOCK_GEN_PROC: process
begin
	CLK <= '1'; wait for 5.0 ns;
	CLK <= '0'; wait for 5.0 ns;
end process CLOCK_GEN_PROC;

testbench_proc : process
begin
	reset <= '1';
	ps_frame_ready <= '0';
	ps_data <= (others => '0');
	ps_frame_size <= x"0000"; 
	dhcp_start <= '0';
	mc_busy <= '0';
	ps_wr_en <= '0';
	ps_data <= '0' & x"00";
	ps_proto <= "00000";
	gsc_reply_data <= (others => '0');
	gsc_reply_dataready <= '0';
	gsc_busy <= '0'; 
	wait for 100 ns;
	reset <= '0';
	
	wait for 1 us;
	
	wait until rising_edge(CLK);
	gsc_reply_dataready <= '1';
	gsc_busy <= '1';
	gsc_reply_data <= x"0039";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"f3c0";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5555";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ffff";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"001f";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"fb28";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"e2cc";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"9600";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0005";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"2222";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1111";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0039";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"f305";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5555";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ffff";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"002f";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"9c28";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"e303";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1200";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"2222";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1111";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0039";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"f305";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5555";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ffff";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"002f";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5128";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"e2eb";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ac00";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0001";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"2222";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1111";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0039";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"f305";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5555";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ffff";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"001f";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"e2cc";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"fc00";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"2222";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1111";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0039";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"f305";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"5555";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"ffff";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"002f";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"a528";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"e303";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0002";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"6900";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0038";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0003";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"2222";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"1111";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0003";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0000";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"0001";
	wait until rising_edge(CLK);
	gsc_reply_data <= x"003f";
	wait until rising_edge(clk);
	gsc_busy <= '0';
	gsc_reply_dataready <= '0';	
	
--	for i in 0 to 100 loop
--	
--		wait until rising_edge(clk);
--		gsc_reply_dataready <= '1';
--		gsc_busy <= '1';
--		gsc_reply_data <= std_logic_vector(to_unsigned(i, 16));
--			
--	end loop;
--	wait until rising_edge(clk);
--	gsc_busy <= '0';
--	gsc_reply_dataready <= '0';
	
--	wait until rising_edge(clk);
--	ps_frame_ready <= '1';
--	ps_proto <= "100";
--	ps_frame_size <= x"0005";
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	ps_data <= '1' & x"aa";
--	ps_frame_ready <= '0';
--	ps_proto <= "000";

--	
--	
--	
--	wait for 5 us;
--	
--	wait until rising_edge(clk);
--	ps_data <= '0' & x"ff";
--	ps_wr_en <= '1';
--	ps_proto <= "100";
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	ps_data <= '1' & x"aa";
--	wait until rising_edge(clk);
--	ps_data <= '0' & x"00";
--	ps_wr_en <= '0';
--	ps_proto <= "000";
--
--	wait until rising_edge(tc_dataready);
--	mc_busy <= '1';
--	wait until ps_busy = "000";
--	mc_busy <= '0';	
	
--	dhcp_start <= '1';
--	wait for 100 ns;
--	dhcp_start <= '0';
--	
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	mc_busy <= '1';
--	
--	wait until rising_edge(tc_done);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	wait until rising_edge(clk);
--	mc_busy <= '0';
	
	wait;

end process testbench_proc;

end; 