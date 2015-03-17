LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity gbe_logic_wrapper is
	generic (
		DO_SIMULATION : integer range 0 to 1;
		INCLUDE_DEBUG : integer range 0 to 1;
		USE_INTERNAL_TRBNET_DUMMY : integer range 0 to 1;
		RX_PATH_ENABLE : integer range 0 to 1;
				
		INCLUDE_READOUT  : std_logic := '0';
		INCLUDE_SLOWCTRL : std_logic := '0';
		INCLUDE_DHCP     : std_logic := '0';
		INCLUDE_ARP      : std_logic := '0';
		INCLUDE_PING     : std_logic := '0';
		
		FRAME_BUFFER_SIZE : integer range 1 to 4 := 1;
		READOUT_BUFFER_SIZE : integer range 1 to 4 := 1;
		SLOWCTRL_BUFFER_SIZE : integer range 1 to 4 := 1; 
		
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		INCREMENTAL_MODE : integer range 0 to 1 := 0;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		UP_DOWN_MODE : integer range 0 to 1 := 0;
		UP_DOWN_LIMIT : integer range 0 to 16777215 := 0;
		FIXED_DELAY : integer range 0 to 16777215 := 16777215
	);
	port (
		CLK_SYS_IN : in std_logic;
		CLK_125_IN : in std_logic;
		CLK_RX_125_IN : in std_logic;
		RESET : in std_logic;
		GSR_N : in std_logic;
		
		MY_MAC_OUT : out std_logic_vector(47 downto 0);
		MY_MAC_IN  : in std_logic_vector(47 downto 0);
		DHCP_DONE_OUT : out std_logic;
		
			-- connection to MAC
		MAC_READY_CONF_IN		: in	std_logic;
		MAC_RECONF_OUT			: out	std_logic;
		MAC_AN_READY_IN			: in	std_logic;

		MAC_FIFOAVAIL_OUT		: out	std_logic;
		MAC_FIFOEOF_OUT			: out	std_logic;
		MAC_FIFOEMPTY_OUT		: out	std_logic;
		MAC_RX_FIFOFULL_OUT		: out	std_logic;
		
		MAC_TX_DATA_OUT			: out	std_logic_vector(7 downto 0);
		MAC_TX_READ_IN			: in	std_logic;
		MAC_TX_DISCRFRM_IN		: in	std_logic;
		MAC_TX_STAT_EN_IN		: in	std_logic;
		MAC_TX_STATS_IN			: in	std_logic_vector(30 downto 0);
		MAC_TX_DONE_IN			: in	std_logic;

		MAC_RX_FIFO_ERR_IN		: in	std_logic;
		MAC_RX_STATS_IN			: in	std_logic_vector(31 downto 0);
		MAC_RX_DATA_IN			: in	std_logic_vector(7 downto 0);
		MAC_RX_WRITE_IN			: in	std_logic;
		MAC_RX_STAT_EN_IN		: in	std_logic;
		MAC_RX_EOF_IN			: in	std_logic;
		MAC_RX_ERROR_IN			: in	std_logic;
		
			-- CTS interface
		CTS_NUMBER_IN				: in	std_logic_vector (15 downto 0);
		CTS_CODE_IN					: in	std_logic_vector (7  downto 0);
		CTS_INFORMATION_IN			: in	std_logic_vector (7  downto 0);
		CTS_READOUT_TYPE_IN			: in	std_logic_vector (3  downto 0);
		CTS_START_READOUT_IN		: in	std_logic;
		CTS_DATA_OUT				: out	std_logic_vector (31 downto 0);
		CTS_DATAREADY_OUT			: out	std_logic;
		CTS_READOUT_FINISHED_OUT	: out	std_logic;
		CTS_READ_IN					: in	std_logic;
		CTS_LENGTH_OUT				: out	std_logic_vector (15 downto 0);
		CTS_ERROR_PATTERN_OUT		: out	std_logic_vector (31 downto 0);
			-- Data payload interface
		FEE_DATA_IN					: in	std_logic_vector (15 downto 0);
		FEE_DATAREADY_IN			: in	std_logic;
		FEE_READ_OUT				: out	std_logic;
		FEE_STATUS_BITS_IN			: in	std_logic_vector (31 downto 0);
		FEE_BUSY_IN					: in	std_logic;
			-- SlowControl
		MC_UNIQUE_ID_IN          : in std_logic_vector(63 downto 0);		
		GSC_CLK_IN               : in std_logic;
		GSC_INIT_DATAREADY_OUT   : out std_logic;
		GSC_INIT_DATA_OUT        : out std_logic_vector(15 downto 0);
		GSC_INIT_PACKET_NUM_OUT  : out std_logic_vector(2 downto 0);
		GSC_INIT_READ_IN         : in std_logic;
		GSC_REPLY_DATAREADY_IN   : in std_logic;
		GSC_REPLY_DATA_IN        : in std_logic_vector(15 downto 0);
		GSC_REPLY_PACKET_NUM_IN  : in std_logic_vector(2 downto 0);
		GSC_REPLY_READ_OUT       : out std_logic;
		GSC_BUSY_IN              : in std_logic;
			-- IP configuration
		SLV_ADDR_IN                  : in std_logic_vector(7 downto 0);
		SLV_READ_IN                  : in std_logic;
		SLV_WRITE_IN                 : in std_logic;
		SLV_BUSY_OUT                 : out std_logic;
		SLV_ACK_OUT                  : out std_logic;
		SLV_DATA_IN                  : in std_logic_vector(31 downto 0);
		SLV_DATA_OUT                 : out std_logic_vector(31 downto 0);
			-- configuration of gbe core
		CFG_GBE_ENABLE_IN            : in std_logic;                    
		CFG_IPU_ENABLE_IN            : in std_logic;                    
		CFG_MULT_ENABLE_IN           : in std_logic;                    
		CFG_MAX_FRAME_IN			 : in std_logic_vector(15 downto 0);
		CFG_ALLOW_RX_IN				 : in std_logic;
		CFG_SOFT_RESET_IN			 : in std_logic;
		CFG_SUBEVENT_ID_IN			 : in std_logic_vector(31 downto 0);
		CFG_SUBEVENT_DEC_IN          : in std_logic_vector(31 downto 0);
		CFG_QUEUE_DEC_IN             : in std_logic_vector(31 downto 0);
		CFG_READOUT_CTR_IN           : in std_logic_vector(23 downto 0);
		CFG_READOUT_CTR_VALID_IN     : in std_logic;
		CFG_INSERT_TTYPE_IN          : in std_logic;
		CFG_MAX_SUB_IN               : in std_logic_vector(15 downto 0);
		CFG_MAX_QUEUE_IN             : in std_logic_vector(15 downto 0);
		CFG_MAX_SUBS_IN_QUEUE_IN     : in std_logic_vector(15 downto 0);
		CFG_MAX_SINGLE_SUB_IN        : in std_logic_vector(15 downto 0);
		CFG_ADDITIONAL_HDR_IN        : in std_logic;   
		CFG_MAX_REPLY_SIZE_IN        : in std_logic_vector(31 downto 0);
		
		MONITOR_RX_BYTES_OUT       : out std_logic_vector(31 downto 0);
		MONITOR_RX_FRAMES_OUT      : out std_logic_vector(31 downto 0);
		MONITOR_TX_BYTES_OUT       : out std_logic_vector(31 downto 0);
		MONITOR_TX_FRAMES_OUT      : out std_logic_vector(31 downto 0);
		MONITOR_TX_PACKETS_OUT     : out std_logic_vector(31 downto 0);
		MONITOR_DROPPED_OUT        : out std_logic_vector(31 downto 0);
	
		MAKE_RESET_OUT					: out std_logic		
	);
end entity gbe_logic_wrapper;

architecture RTL of gbe_logic_wrapper is
	
	signal fr_q                          : std_logic_vector(8 downto 0);
	signal fr_rd_en                      : std_logic;
	signal fr_frame_valid                : std_logic;
	signal rc_rd_en                      : std_logic;
	signal rc_q                          : std_logic_vector(8 downto 0);
	signal rc_frames_rec_ctr             : std_logic_vector(31 downto 0);
	signal mc_data                       : std_logic_vector(8 downto 0);
	signal mc_wr_en                      : std_logic;
	signal fc_wr_en                      : std_logic;
	signal fc_data                       : std_logic_vector(7 downto 0);
	signal fc_ip_size                    : std_logic_vector(15 downto 0);
	signal fc_udp_size                   : std_logic_vector(15 downto 0);
	signal fc_ident                      : std_logic_vector(15 downto 0);
	signal fc_flags_offset               : std_logic_vector(15 downto 0);
	signal fc_sod                        : std_logic;
	signal fc_eod                        : std_logic;
	signal fc_h_ready                    : std_logic;
	signal fc_ready                      : std_logic;
	signal rc_frame_ready                : std_logic;
	signal fr_frame_size                 : std_logic_vector(15 downto 0);
	signal rc_frame_size                 : std_logic_vector(15 downto 0);
	signal mc_frame_size                 : std_logic_vector(15 downto 0);
	signal rc_bytes_rec                  : std_logic_vector(31 downto 0);
	signal rc_debug                      : std_logic_vector(63 downto 0);
	signal mc_transmit_ctrl              : std_logic;
	signal rc_loading_done               : std_logic;
	signal fr_get_frame                  : std_logic;
	signal mc_transmit_done              : std_logic;
	
	signal fr_frame_proto                : std_logic_vector(15 downto 0);
	signal rc_frame_proto                : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	
	signal mc_type                       : std_logic_vector(15 downto 0);
	signal fr_src_mac                : std_logic_vector(47 downto 0);
	signal fr_dest_mac               : std_logic_vector(47 downto 0);
	signal fr_src_ip                 : std_logic_vector(31 downto 0);
	signal fr_dest_ip                : std_logic_vector(31 downto 0);
	signal fr_src_udp                : std_logic_vector(15 downto 0);
	signal fr_dest_udp               : std_logic_vector(15 downto 0);
	signal rc_src_mac                : std_logic_vector(47 downto 0);
	signal rc_dest_mac               : std_logic_vector(47 downto 0);
	signal rc_src_ip                 : std_logic_vector(31 downto 0);
	signal rc_dest_ip                : std_logic_vector(31 downto 0);
	signal rc_src_udp                : std_logic_vector(15 downto 0);
	signal rc_dest_udp               : std_logic_vector(15 downto 0);
	
	signal mc_dest_mac			: std_logic_vector(47 downto 0);
	signal mc_dest_ip			: std_logic_vector(31 downto 0);
	signal mc_dest_udp			: std_logic_vector(15 downto 0);
	signal mc_src_mac			: std_logic_vector(47 downto 0);
	signal mc_src_ip			: std_logic_vector(31 downto 0);
	signal mc_src_udp			: std_logic_vector(15 downto 0);
	
	signal fc_dest_mac				: std_logic_vector(47 downto 0);
	signal fc_dest_ip				: std_logic_vector(31 downto 0);
	signal fc_dest_udp				: std_logic_vector(15 downto 0);
	signal fc_src_mac				: std_logic_vector(47 downto 0);
	signal fc_src_ip				: std_logic_vector(31 downto 0);
	signal fc_src_udp				: std_logic_vector(15 downto 0);
	signal fc_type					: std_logic_vector(15 downto 0);
	signal fc_ihl_version			: std_logic_vector(7 downto 0);
	signal fc_tos					: std_logic_vector(7 downto 0);
	signal fc_ttl					: std_logic_vector(7 downto 0);
	signal fc_protocol				: std_logic_vector(7 downto 0);
	
	signal ft_data					: std_logic_vector(8 downto 0);
	signal ft_tx_empty				: std_logic;
	signal ft_start_of_packet		: std_logic;
	signal ft_bsm_init				: std_logic_vector(3 downto 0);
	signal ft_bsm_mac				: std_logic_vector(3 downto 0);
	signal ft_bsm_trans				: std_logic_vector(3 downto 0);
	
	signal gbe_cts_number                   : std_logic_vector(15 downto 0);
	signal gbe_cts_code                     : std_logic_vector(7 downto 0);
	signal gbe_cts_information              : std_logic_vector(7 downto 0);
	signal gbe_cts_start_readout            : std_logic;
	signal gbe_cts_readout_type             : std_logic_vector(3 downto 0);
	signal gbe_cts_readout_finished         : std_logic;
	signal gbe_cts_status_bits              : std_logic_vector(31 downto 0);
	signal gbe_fee_data                     : std_logic_vector(15 downto 0);
	signal gbe_fee_dataready                : std_logic;
	signal gbe_fee_read                     : std_logic;
	signal gbe_fee_status_bits              : std_logic_vector(31 downto 0);
	signal gbe_fee_busy                     : std_logic;
	
	signal fr_ip_proto						: std_logic_vector(7 downto 0);
	signal mc_ip_proto						: std_logic_vector(7 downto 0);
	signal mc_ident							: std_logic_vector(15 downto 0);
	
	signal dbg_select_rec                : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_sent               : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_rec_bytes          : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_sent_bytes         : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_drop_in            : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_drop_out           : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	signal dbg_select_gen                : std_logic_vector(2*c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	signal global_reset, rst_n, ff		: std_logic;
	signal link_ok, dhcp_done			: std_logic;
	
	signal dum_busy, dum_read, dum_dataready : std_logic;
	signal dum_data : std_logic_vector(15 downto 0);
	
	signal monitor_tx_packets : std_logic_vector(31 downto 0);
	signal monitor_rx_bytes, monitor_rx_frames, monitor_tx_bytes, monitor_tx_frames : std_logic_vector(31 downto 0);
	
	signal dbg_hist, dbg_hist2 : hist_array;
	signal monitor_dropped : std_logic_vector(31 downto 0);
	signal dbg_ft : std_logic_vector(63 downto 0);
	signal dbg_q : std_logic_vector(15 downto 0);
	signal make_reset : std_logic;
	signal my_mac : std_logic_vector(47 downto 0);
	
begin
	
	reset_sync : process(GSR_N, CLK_SYS_IN)
	begin
		if (GSR_N = '0') then
			ff <= '0';
			rst_n <= '0';
		elsif rising_edge(CLK_SYS_IN) then
			ff <= '1';
			rst_n <= ff;
		end if;
	end process reset_sync;
	
	global_reset <= not rst_n;
	
	fc_ihl_version      <= x"45";
	fc_tos              <= x"10";
	fc_ttl              <= x"ff";
	
	MY_MAC_OUT <= my_mac;
	DHCP_DONE_OUT <= dhcp_done;


	main_gen : if USE_INTERNAL_TRBNET_DUMMY = 0 generate
		MAIN_CONTROL : trb_net16_gbe_main_control
			generic map(
				RX_PATH_ENABLE => RX_PATH_ENABLE,
				DO_SIMULATION  => DO_SIMULATION,
				
				INCLUDE_READOUT  => INCLUDE_READOUT,
				INCLUDE_SLOWCTRL => INCLUDE_SLOWCTRL,
				INCLUDE_DHCP     => INCLUDE_DHCP,
				INCLUDE_ARP      => INCLUDE_ARP,
				INCLUDE_PING     => INCLUDE_PING,
			
				READOUT_BUFFER_SIZE => READOUT_BUFFER_SIZE,
				SLOWCTRL_BUFFER_SIZE => SLOWCTRL_BUFFER_SIZE
				)
		  port map(
			  CLK						=> CLK_SYS_IN,
			  CLK_125					=> CLK_125_IN,
			  RESET						=> RESET,
		
			  MC_LINK_OK_OUT			=> link_ok,
			  MC_RESET_LINK_IN			=> global_reset,
			  MC_IDLE_TOO_LONG_OUT 		=> open,
			  MC_DHCP_DONE_OUT 			=> dhcp_done,
			  MC_MY_MAC_OUT				=> my_mac,
			  MC_MY_MAC_IN				=> MY_MAC_IN,
		
		  -- signals to/from receive controller
			  RC_FRAME_WAITING_IN		=> rc_frame_ready,
			  RC_LOADING_DONE_OUT		=> rc_loading_done,
			  RC_DATA_IN				=> rc_q,
			  RC_RD_EN_OUT				=> rc_rd_en,
			  RC_FRAME_SIZE_IN			=> rc_frame_size,
			  RC_FRAME_PROTO_IN			=> rc_frame_proto,
		
			  RC_SRC_MAC_ADDRESS_IN		=> rc_src_mac,
			  RC_DEST_MAC_ADDRESS_IN  	=> rc_dest_mac,
			  RC_SRC_IP_ADDRESS_IN		=> rc_src_ip,
			  RC_DEST_IP_ADDRESS_IN		=> rc_dest_ip,
			  RC_SRC_UDP_PORT_IN		=> rc_src_udp,
			  RC_DEST_UDP_PORT_IN		=> rc_dest_udp,
		
		  -- signals to/from transmit controller
			  TC_TRANSMIT_CTRL_OUT		=> mc_transmit_ctrl,
			  TC_DATA_OUT				=> mc_data,
			  TC_RD_EN_IN				=> mc_wr_en,
			  TC_FRAME_SIZE_OUT			=> mc_frame_size,
			  TC_FRAME_TYPE_OUT			=> mc_type,
			  TC_IP_PROTOCOL_OUT		=> mc_ip_proto,
			  TC_IDENT_OUT          	=> mc_ident,
			  
			  TC_DEST_MAC_OUT			=> mc_dest_mac,
			  TC_DEST_IP_OUT			=> mc_dest_ip,
			  TC_DEST_UDP_OUT			=> mc_dest_udp,
			  TC_SRC_MAC_OUT			=> mc_src_mac,
			  TC_SRC_IP_OUT				=> mc_src_ip,
			  TC_SRC_UDP_OUT			=> mc_src_udp,
			  TC_TRANSMIT_DONE_IN		=> mc_transmit_done,
		
		  -- signals to/from sgmii/gbe pcs_an_complete
			  PCS_AN_COMPLETE_IN		=> MAC_AN_READY_IN,
		
		  -- signals to/from hub
			MC_UNIQUE_ID_IN			=> MC_UNIQUE_ID_IN,
			GSC_CLK_IN               => GSC_CLK_IN,
			GSC_INIT_DATAREADY_OUT   => GSC_INIT_DATAREADY_OUT,
			GSC_INIT_DATA_OUT        => GSC_INIT_DATA_OUT,
			GSC_INIT_PACKET_NUM_OUT  => GSC_INIT_PACKET_NUM_OUT,
			GSC_INIT_READ_IN         => GSC_INIT_READ_IN,
			GSC_REPLY_DATAREADY_IN   => GSC_REPLY_DATAREADY_IN,
			GSC_REPLY_DATA_IN        => GSC_REPLY_DATA_IN,
			GSC_REPLY_PACKET_NUM_IN  => GSC_REPLY_PACKET_NUM_IN,
			GSC_REPLY_READ_OUT       => GSC_REPLY_READ_OUT,
			GSC_BUSY_IN              => GSC_BUSY_IN,
		
			MAKE_RESET_OUT           => make_reset, --MAKE_RESET_OUT,
			
				-- CTS interface
			CTS_NUMBER_IN				=> CTS_NUMBER_IN,
			CTS_CODE_IN					=> CTS_CODE_IN,
			CTS_INFORMATION_IN			=> CTS_INFORMATION_IN,
			CTS_READOUT_TYPE_IN			=> CTS_READOUT_TYPE_IN,
			CTS_START_READOUT_IN		=> CTS_START_READOUT_IN,
			CTS_DATA_OUT				=> CTS_DATA_OUT,
			CTS_DATAREADY_OUT			=> CTS_DATAREADY_OUT,
			CTS_READOUT_FINISHED_OUT	=> CTS_READOUT_FINISHED_OUT,
			CTS_READ_IN					=> CTS_READ_IN,
			CTS_LENGTH_OUT				=> CTS_LENGTH_OUT,
			CTS_ERROR_PATTERN_OUT		=> CTS_ERROR_PATTERN_OUT,
			-- Data payload interface
			FEE_DATA_IN					=> FEE_DATA_IN,
			FEE_DATAREADY_IN			=> FEE_DATAREADY_IN,
			FEE_READ_OUT				=> FEE_READ_OUT,
			FEE_STATUS_BITS_IN			=> FEE_STATUS_BITS_IN,
			FEE_BUSY_IN					=> FEE_BUSY_IN, 
			-- ip configurator
			SLV_ADDR_IN                 => SLV_ADDR_IN,
			SLV_READ_IN                 => SLV_READ_IN,
			SLV_WRITE_IN                => SLV_WRITE_IN,
			SLV_BUSY_OUT                => SLV_BUSY_OUT,
			SLV_ACK_OUT                 => SLV_ACK_OUT,
			SLV_DATA_IN                 => SLV_DATA_IN,
			SLV_DATA_OUT                => SLV_DATA_OUT,
			
			CFG_GBE_ENABLE_IN           => CFG_GBE_ENABLE_IN,
			CFG_IPU_ENABLE_IN           => CFG_IPU_ENABLE_IN,
			CFG_MULT_ENABLE_IN          => CFG_MULT_ENABLE_IN,
			CFG_SUBEVENT_ID_IN			=> CFG_SUBEVENT_ID_IN,
			CFG_SUBEVENT_DEC_IN         => CFG_SUBEVENT_DEC_IN,
			CFG_QUEUE_DEC_IN            => CFG_QUEUE_DEC_IN,
			CFG_READOUT_CTR_IN          => CFG_READOUT_CTR_IN,
			CFG_READOUT_CTR_VALID_IN    => CFG_READOUT_CTR_VALID_IN,
			CFG_INSERT_TTYPE_IN         => CFG_INSERT_TTYPE_IN,
			CFG_MAX_SUB_IN              => CFG_MAX_SUB_IN,
			CFG_MAX_QUEUE_IN            => CFG_MAX_QUEUE_IN,
			CFG_MAX_SUBS_IN_QUEUE_IN    => CFG_MAX_SUBS_IN_QUEUE_IN,
			CFG_MAX_SINGLE_SUB_IN       => CFG_MAX_SINGLE_SUB_IN,
			CFG_ADDITIONAL_HDR_IN       => CFG_ADDITIONAL_HDR_IN,
			CFG_MAX_REPLY_SIZE_IN       => CFG_MAX_REPLY_SIZE_IN,
			
			TSM_HADDR_OUT		=> open, --mac_haddr,
		  	TSM_HDATA_OUT		=> open, --mac_hdataout,
			TSM_HCS_N_OUT		=> open, --mac_hcs,
			TSM_HWRITE_N_OUT	=> open, --mac_hwrite,
			TSM_HREAD_N_OUT	=> open, --mac_hread,
			TSM_HREADY_N_IN	=> '0', --mac_hready,
			TSM_HDATA_EN_N_IN	=> '1', --mac_hdata_en,
			TSM_RX_STAT_VEC_IN  => (others => '0'), --mac_rx_stat_vec,
			TSM_RX_STAT_EN_IN   => '0', --mac_rx_stat_en,
			
			MAC_READY_CONF_IN => MAC_READY_CONF_IN,
			MAC_RECONF_OUT => MAC_RECONF_OUT,
		  
		  	MONITOR_SELECT_REC_OUT		 => dbg_select_rec,
		  MONITOR_SELECT_REC_BYTES_OUT   => dbg_select_rec_bytes,
		  MONITOR_SELECT_SENT_BYTES_OUT  => dbg_select_sent_bytes,
		  MONITOR_SELECT_SENT_OUT	     => dbg_select_sent,
		  MONITOR_SELECT_DROP_IN_OUT     => dbg_select_drop_in,
		  MONITOR_SELECT_DROP_OUT_OUT    => dbg_select_drop_out,
		  MONITOR_SELECT_GEN_DBG_OUT     => dbg_select_gen,
			
				DATA_HIST_OUT => dbg_hist,
				SCTRL_HIST_OUT => dbg_hist2
		  );
	end generate main_gen;
	
	main_with_dummy_gen : if USE_INTERNAL_TRBNET_DUMMY = 1 generate
		MAIN_CONTROL : trb_net16_gbe_main_control
		generic map(
			RX_PATH_ENABLE => RX_PATH_ENABLE,
			DO_SIMULATION  => DO_SIMULATION,
			
			INCLUDE_READOUT  => INCLUDE_READOUT,
			INCLUDE_SLOWCTRL => INCLUDE_SLOWCTRL,
			INCLUDE_DHCP     => INCLUDE_DHCP,
			INCLUDE_ARP      => INCLUDE_ARP,
			INCLUDE_PING     => INCLUDE_PING,
			
			READOUT_BUFFER_SIZE => READOUT_BUFFER_SIZE,
			SLOWCTRL_BUFFER_SIZE => SLOWCTRL_BUFFER_SIZE
			)
	  	port map(
		  CLK			=> CLK_SYS_IN,
		  CLK_125		=> CLK_125_IN,
		  RESET			=> RESET,
	
		  MC_LINK_OK_OUT	=> link_ok,
		  MC_RESET_LINK_IN	=> global_reset,
		  MC_IDLE_TOO_LONG_OUT => open,
		  MC_DHCP_DONE_OUT => dhcp_done,
		  MC_MY_MAC_OUT				=> my_mac,
		  MC_MY_MAC_IN				=> MY_MAC_IN,
	
	  -- signals to/from receive controller
		  RC_FRAME_WAITING_IN	=> rc_frame_ready,
		  RC_LOADING_DONE_OUT	=> rc_loading_done,
		  RC_DATA_IN		=> rc_q,
		  RC_RD_EN_OUT		=> rc_rd_en,
		  RC_FRAME_SIZE_IN	=> rc_frame_size,
		  RC_FRAME_PROTO_IN	=> rc_frame_proto,
	
		  RC_SRC_MAC_ADDRESS_IN	=> rc_src_mac,
		  RC_DEST_MAC_ADDRESS_IN  => rc_dest_mac,
		  RC_SRC_IP_ADDRESS_IN	=> rc_src_ip,
		  RC_DEST_IP_ADDRESS_IN	=> rc_dest_ip,
		  RC_SRC_UDP_PORT_IN	=> rc_src_udp,
		  RC_DEST_UDP_PORT_IN	=> rc_dest_udp,
	
	  -- signals to/from transmit controller
		  TC_TRANSMIT_CTRL_OUT	=> mc_transmit_ctrl,
		  TC_DATA_OUT		=> mc_data,
		  TC_RD_EN_IN		=> mc_wr_en,
		  --TC_DATA_NOT_VALID_OUT => tc_data_not_valid,
		  TC_FRAME_SIZE_OUT	=> mc_frame_size,
		  TC_FRAME_TYPE_OUT	=> mc_type,
		  TC_IP_PROTOCOL_OUT	=> mc_ip_proto,
		  TC_IDENT_OUT          => mc_ident,
		  
		  TC_DEST_MAC_OUT	=> mc_dest_mac,
		  TC_DEST_IP_OUT	=> mc_dest_ip,
		  TC_DEST_UDP_OUT	=> mc_dest_udp,
		  TC_SRC_MAC_OUT	=> mc_src_mac,
		  TC_SRC_IP_OUT		=> mc_src_ip,
		  TC_SRC_UDP_OUT	=> mc_src_udp,
		  TC_TRANSMIT_DONE_IN   => mc_transmit_done,
	
	  -- signals to/from sgmii/gbe pcs_an_complete
		  PCS_AN_COMPLETE_IN	=> MAC_AN_READY_IN,
	
	  -- signals to/from hub
		  MC_UNIQUE_ID_IN	     => MC_UNIQUE_ID_IN,
		GSC_CLK_IN               => GSC_CLK_IN,
		GSC_INIT_DATAREADY_OUT   => GSC_INIT_DATAREADY_OUT,
		GSC_INIT_DATA_OUT        => GSC_INIT_DATA_OUT,
		GSC_INIT_PACKET_NUM_OUT  => GSC_INIT_PACKET_NUM_OUT,
		GSC_INIT_READ_IN         => '1',
		GSC_REPLY_DATAREADY_IN   => dum_dataready,
		GSC_REPLY_DATA_IN        => dum_data,
		GSC_REPLY_PACKET_NUM_IN  => GSC_REPLY_PACKET_NUM_IN,
		GSC_REPLY_READ_OUT       => dum_read,
		GSC_BUSY_IN              => dum_busy,
	
		MAKE_RESET_OUT           => make_reset,
		
			-- CTS interface
		CTS_NUMBER_IN               => gbe_cts_number,           
		CTS_CODE_IN                 => gbe_cts_code,             
		CTS_INFORMATION_IN          => gbe_cts_information,      
		CTS_READOUT_TYPE_IN         => gbe_cts_readout_type,     
		CTS_START_READOUT_IN        => gbe_cts_start_readout,    
		CTS_DATA_OUT                => open,                     
		CTS_DATAREADY_OUT           => open,                     
		CTS_READOUT_FINISHED_OUT    => gbe_cts_readout_finished, 
		CTS_READ_IN                 => '1',                      
		CTS_LENGTH_OUT              => open,                     
		CTS_ERROR_PATTERN_OUT       => gbe_cts_status_bits,      
		--Data payload interface                                 
		FEE_DATA_IN                 => gbe_fee_data,             
		FEE_DATAREADY_IN            => gbe_fee_dataready,        
		FEE_READ_OUT                => gbe_fee_read,             
		FEE_STATUS_BITS_IN          => gbe_fee_status_bits,      
		FEE_BUSY_IN                 => gbe_fee_busy,             
		-- ip configurator
		SLV_ADDR_IN                 => SLV_ADDR_IN,
		SLV_READ_IN                 => SLV_READ_IN,
		SLV_WRITE_IN                => SLV_WRITE_IN,
		SLV_BUSY_OUT                => SLV_BUSY_OUT,
		SLV_ACK_OUT                 => SLV_ACK_OUT,
		SLV_DATA_IN                 => SLV_DATA_IN,
		SLV_DATA_OUT                => SLV_DATA_OUT,
		
		CFG_GBE_ENABLE_IN           => '1',
		CFG_IPU_ENABLE_IN           => '0',
		CFG_MULT_ENABLE_IN          => '0',
		CFG_SUBEVENT_ID_IN			=> x"0000_00cf",
		CFG_SUBEVENT_DEC_IN         => x"0002_0001",
		CFG_QUEUE_DEC_IN            => x"0003_0062",
		CFG_READOUT_CTR_IN          => x"00_0000",
		CFG_READOUT_CTR_VALID_IN    => '0',
		CFG_INSERT_TTYPE_IN         => '0',
		CFG_MAX_SUB_IN              => x"e998",  -- 59800 
		CFG_MAX_QUEUE_IN            => x"ea60",  -- 60000 
		CFG_MAX_SUBS_IN_QUEUE_IN    => x"00c8",  -- 200
		CFG_MAX_SINGLE_SUB_IN       => x"e998", --x"7d00",  -- 32000
		
		CFG_ADDITIONAL_HDR_IN       => '0',
		CFG_MAX_REPLY_SIZE_IN       => x"0000_fa00",
	
	  -- signal to/from Host interface of TriSpeed MAC
		  TSM_HADDR_OUT		=> open, --mac_haddr,
		  TSM_HDATA_OUT		=> open, --mac_hdataout,
		  TSM_HCS_N_OUT		=> open, --mac_hcs,
		  TSM_HWRITE_N_OUT	=> open, --mac_hwrite,
		  TSM_HREAD_N_OUT	=> open, --mac_hread,
		  TSM_HREADY_N_IN	=> '0', --mac_hready,
		  TSM_HDATA_EN_N_IN	=> '1', --mac_hdata_en,
		  TSM_RX_STAT_VEC_IN  => (others => '0'), --mac_rx_stat_vec,
		  TSM_RX_STAT_EN_IN   => '0', --mac_rx_stat_en,
		  
		  MAC_READY_CONF_IN => MAC_READY_CONF_IN,
		  MAC_RECONF_OUT => MAC_RECONF_OUT,
		  
		  MONITOR_SELECT_REC_OUT		 => dbg_select_rec,
		  MONITOR_SELECT_REC_BYTES_OUT   => dbg_select_rec_bytes,
		  MONITOR_SELECT_SENT_BYTES_OUT  => dbg_select_sent_bytes,
		  MONITOR_SELECT_SENT_OUT	     => dbg_select_sent,
		  MONITOR_SELECT_DROP_IN_OUT     => dbg_select_drop_in,
		  MONITOR_SELECT_DROP_OUT_OUT    => dbg_select_drop_out,
		  MONITOR_SELECT_GEN_DBG_OUT     => dbg_select_gen,
		
			DATA_HIST_OUT => dbg_hist,
			SCTRL_HIST_OUT => dbg_hist2
	  );
	  
	  dummy : gbe_ipu_dummy
		generic map(
			DO_SIMULATION => DO_SIMULATION,
			FIXED_SIZE_MODE => FIXED_SIZE_MODE,
			INCREMENTAL_MODE => INCREMENTAL_MODE,
			FIXED_SIZE => FIXED_SIZE,
			UP_DOWN_MODE => UP_DOWN_MODE,
			UP_DOWN_LIMIT => UP_DOWN_LIMIT,
			FIXED_DELAY_MODE => FIXED_DELAY_MODE,
			FIXED_DELAY => FIXED_DELAY
		)
		port map(
			clk => CLK_SYS_IN,
			rst => RESET,
			GBE_READY_IN => dhcp_done,
			
			CFG_EVENT_SIZE_IN      => (others => '0'),
			CFG_TRIGGERED_MODE_IN  => '0',
			TRIGGER_IN => '0',
			                    
			CTS_NUMBER_OUT		     => gbe_cts_number,
			CTS_CODE_OUT		     => gbe_cts_code,
			CTS_INFORMATION_OUT	     => gbe_cts_information,
			CTS_READOUT_TYPE_OUT     => gbe_cts_readout_type,
			CTS_START_READOUT_OUT    => gbe_cts_start_readout,
			CTS_DATA_IN				 => (others => '0'),
			CTS_DATAREADY_IN	     => '0',
			CTS_READOUT_FINISHED_IN	 => gbe_cts_readout_finished,
			CTS_READ_OUT		     => open,
			CTS_LENGTH_IN		     => (others => '0'),
			CTS_ERROR_PATTERN_IN     => gbe_cts_status_bits,
			-- Data payload interfac =>
			FEE_DATA_OUT		     => gbe_fee_data,
			FEE_DATAREADY_OUT	     => gbe_fee_dataready,
			FEE_READ_IN				 => gbe_fee_read,
			FEE_STATUS_BITS_OUT	     => gbe_fee_status_bits,
			FEE_BUSY_OUT		     => gbe_fee_busy
		);
	end generate main_with_dummy_gen;
	
	 MAKE_RESET_OUT <= make_reset; -- or idle_too_long;

	transmit_gen : if USE_INTERNAL_TRBNET_DUMMY = 0 generate
	
		TRANSMIT_CONTROLLER : trb_net16_gbe_transmit_control2
		port map(
			CLK			=> CLK_SYS_IN,
			RESET			=> global_reset, --RESET,
		
		-- signal to/from main controller
			TC_DATAREADY_IN        => mc_transmit_ctrl,
			TC_RD_EN_OUT		   => mc_wr_en,
			TC_DATA_IN		       => mc_data(7 downto 0),
			TC_FRAME_SIZE_IN	   => mc_frame_size,
			TC_FRAME_TYPE_IN	   => mc_type,
			TC_IP_PROTOCOL_IN	   => mc_ip_proto,	
			TC_DEST_MAC_IN		   => mc_dest_mac,
			TC_DEST_IP_IN		   => mc_dest_ip,
			TC_DEST_UDP_IN		   => mc_dest_udp,
			TC_SRC_MAC_IN		   => mc_src_mac,
			TC_SRC_IP_IN		   => mc_src_ip,
			TC_SRC_UDP_IN		   => mc_src_udp,
			TC_TRANSMISSION_DONE_OUT => mc_transmit_done,
			TC_IDENT_IN            => mc_ident,
			TC_MAX_FRAME_IN        => CFG_MAX_FRAME_IN,
		
		-- signal to/from frame constructor
			FC_DATA_OUT			=> fc_data,
			FC_WR_EN_OUT		=> fc_wr_en,
			FC_READY_IN			=> fc_ready,
			FC_H_READY_IN		=> fc_h_ready,
			FC_FRAME_TYPE_OUT	=> fc_type,
			FC_IP_SIZE_OUT		=> fc_ip_size,
			FC_UDP_SIZE_OUT		=> fc_udp_size,
			FC_IDENT_OUT		=> fc_ident,
			FC_FLAGS_OFFSET_OUT	=> fc_flags_offset,
			FC_SOD_OUT			=> fc_sod,
			FC_EOD_OUT			=> fc_eod,
			FC_IP_PROTOCOL_OUT	=> fc_protocol,
		
			DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
			DEST_IP_ADDRESS_OUT     => fc_dest_ip,
			DEST_UDP_PORT_OUT       => fc_dest_udp,
			SRC_MAC_ADDRESS_OUT     => fc_src_mac,
			SRC_IP_ADDRESS_OUT      => fc_src_ip,
			SRC_UDP_PORT_OUT        => fc_src_udp,
		
			MONITOR_TX_PACKETS_OUT  => monitor_tx_packets
		);
	end generate transmit_gen;
	
	transmit_with_dummy_gen : if USE_INTERNAL_TRBNET_DUMMY = 1 generate
		TRANSMIT_CONTROLLER : trb_net16_gbe_transmit_control2
	port map(
		CLK						=> CLK_SYS_IN,
		RESET					=> global_reset, --RESET,
	
	-- signal to/from main controller
		TC_DATAREADY_IN			=> mc_transmit_ctrl,
		TC_RD_EN_OUT			=> mc_wr_en,
		TC_DATA_IN				=> mc_data(7 downto 0),
		TC_FRAME_SIZE_IN		=> mc_frame_size,
		TC_FRAME_TYPE_IN		=> mc_type,
		TC_IP_PROTOCOL_IN		=> mc_ip_proto,	
		TC_DEST_MAC_IN			=> mc_dest_mac,
		TC_DEST_IP_IN			=> mc_dest_ip,
		TC_DEST_UDP_IN			=> mc_dest_udp,
		TC_SRC_MAC_IN			=> mc_src_mac,
		TC_SRC_IP_IN			=> mc_src_ip,
		TC_SRC_UDP_IN			=> mc_src_udp,
		TC_TRANSMISSION_DONE_OUT => mc_transmit_done,
		TC_IDENT_IN				=> mc_ident,
		TC_MAX_FRAME_IN			=> CFG_MAX_FRAME_IN,
	
	-- signal to/from frame constructor
		FC_DATA_OUT				=> fc_data,
		FC_WR_EN_OUT			=> fc_wr_en,
		FC_READY_IN				=> fc_ready,
		FC_H_READY_IN			=> fc_h_ready,
		FC_FRAME_TYPE_OUT		=> fc_type,
		FC_IP_SIZE_OUT			=> fc_ip_size,
		FC_UDP_SIZE_OUT			=> fc_udp_size,
		FC_IDENT_OUT			=> fc_ident,
		FC_FLAGS_OFFSET_OUT		=> fc_flags_offset,
		FC_SOD_OUT				=> fc_sod,
		FC_EOD_OUT				=> fc_eod,
		FC_IP_PROTOCOL_OUT		=> fc_protocol,
	
		DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
		DEST_IP_ADDRESS_OUT     => fc_dest_ip,
		DEST_UDP_PORT_OUT       => fc_dest_udp,
		SRC_MAC_ADDRESS_OUT     => fc_src_mac,
		SRC_IP_ADDRESS_OUT      => fc_src_ip,
		SRC_UDP_PORT_OUT        => fc_src_udp,
	
		MONITOR_TX_PACKETS_OUT  => monitor_tx_packets
	);
	end generate transmit_with_dummy_gen;

	FRAME_CONSTRUCTOR: trb_net16_gbe_frame_constr
	generic map (
		FRAME_BUFFER_SIZE => FRAME_BUFFER_SIZE
	)
	port map( 
		-- ports for user logic
		RESET					=> global_reset,
		CLK				    	=> CLK_SYS_IN,
		LINK_OK_IN				=> '1',
		--
		WR_EN_IN				=> fc_wr_en,
		DATA_IN					=> fc_data,
		START_OF_DATA_IN		=> fc_sod,
		END_OF_DATA_IN			=> fc_eod,
		IP_F_SIZE_IN			=> fc_ip_size,
		UDP_P_SIZE_IN			=> fc_udp_size,
		HEADERS_READY_OUT		=> fc_h_ready,
		READY_OUT				=> fc_ready,
		DEST_MAC_ADDRESS_IN		=> fc_dest_mac,
		DEST_IP_ADDRESS_IN		=> fc_dest_ip,
		DEST_UDP_PORT_IN		=> fc_dest_udp,
		SRC_MAC_ADDRESS_IN		=> fc_src_mac,
		SRC_IP_ADDRESS_IN		=> fc_src_ip,
		SRC_UDP_PORT_IN			=> fc_src_udp,
		FRAME_TYPE_IN			=> fc_type,
		IHL_VERSION_IN			=> fc_ihl_version,
		TOS_IN					=> fc_tos,
		IDENTIFICATION_IN		=> fc_ident,
		FLAGS_OFFSET_IN			=> fc_flags_offset,
		TTL_IN					=> fc_ttl,
		PROTOCOL_IN				=> fc_protocol,
		FRAME_DELAY_IN			=> (others => '0'),
		
		RD_CLK					=> CLK_125_IN,
		FT_DATA_OUT 			=> ft_data,
		FT_TX_EMPTY_OUT			=> ft_tx_empty,
		FT_TX_RD_EN_IN			=> MAC_TX_READ_IN,
		FT_START_OF_PACKET_OUT	=> ft_start_of_packet,
		FT_TX_DONE_IN			=> MAC_TX_DONE_IN,
		FT_TX_DISCFRM_IN		=> MAC_TX_DISCRFRM_IN,
		
		MONITOR_TX_BYTES_OUT    => monitor_tx_bytes,
		MONITOR_TX_FRAMES_OUT   => monitor_tx_frames
	);
	
	MAC_TX_DATA_OUT <= ft_data(7 downto 0);
	
	dbg_q(15 downto 9) <= (others  => '0');
	
	FRAME_TRANSMITTER: trb_net16_gbe_frame_trans
	port map( 
		CLK					=> CLK_SYS_IN,
		RESET				=> global_reset,
		LINK_OK_IN			=> link_ok,
		TX_MAC_CLK			=> CLK_125_IN,
		TX_EMPTY_IN			=> ft_tx_empty,
		START_OF_PACKET_IN	=> ft_start_of_packet,
		DATA_ENDFLAG_IN		=> ft_data(8),
		
		TX_FIFOAVAIL_OUT	=> MAC_FIFOAVAIL_OUT,
		TX_FIFOEOF_OUT		=> MAC_FIFOEOF_OUT,
		TX_FIFOEMPTY_OUT	=> MAC_FIFOEMPTY_OUT,
		TX_DONE_IN			=> MAC_TX_DONE_IN,	
		TX_STAT_EN_IN		=> MAC_TX_STAT_EN_IN,
		TX_STATVEC_IN		=> MAC_TX_STATS_IN,
		TX_DISCFRM_IN		=> MAC_TX_DISCRFRM_IN,
		-- Debug
		BSM_INIT_OUT		=> ft_bsm_init,
		BSM_MAC_OUT			=> ft_bsm_mac,
		BSM_TRANS_OUT		=> ft_bsm_trans,
		DBG_RD_DONE_OUT		=> open,
		DBG_INIT_DONE_OUT	=> open,
		DBG_ENABLED_OUT		=> open,
		DEBUG_OUT			=> dbg_ft
	);  
	
	rx_enable_gen : if (RX_PATH_ENABLE = 1) generate
	
		RECEIVE_CONTROLLER : trb_net16_gbe_receive_control
		port map(
			CLK						=> CLK_SYS_IN,
			RESET					=> global_reset,
		
				-- signals to/from frame_receiver
			RC_DATA_IN				=> fr_q,
			FR_RD_EN_OUT			=> fr_rd_en,
			FR_FRAME_VALID_IN		=> fr_frame_valid,
			FR_GET_FRAME_OUT		=> fr_get_frame,
			FR_FRAME_SIZE_IN		=> fr_frame_size,
			FR_FRAME_PROTO_IN		=> fr_frame_proto,
			FR_IP_PROTOCOL_IN		=> fr_ip_proto,
			
			FR_SRC_MAC_ADDRESS_IN	=> fr_src_mac,
			FR_DEST_MAC_ADDRESS_IN  => fr_dest_mac,
			FR_SRC_IP_ADDRESS_IN	=> fr_src_ip,
			FR_DEST_IP_ADDRESS_IN	=> fr_dest_ip,
			FR_SRC_UDP_PORT_IN		=> fr_src_udp,
			FR_DEST_UDP_PORT_IN		=> fr_dest_udp,
		
				-- signals to/from main controller
			RC_RD_EN_IN				=> rc_rd_en,
			RC_Q_OUT				=> rc_q,
			RC_FRAME_WAITING_OUT	=> rc_frame_ready,
			RC_LOADING_DONE_IN		=> rc_loading_done,
			RC_FRAME_SIZE_OUT		=> rc_frame_size,
			RC_FRAME_PROTO_OUT		=> rc_frame_proto,
			
			RC_SRC_MAC_ADDRESS_OUT	=> rc_src_mac,
			RC_DEST_MAC_ADDRESS_OUT => rc_dest_mac,
			RC_SRC_IP_ADDRESS_OUT	=> rc_src_ip,
			RC_DEST_IP_ADDRESS_OUT	=> rc_dest_ip,
			RC_SRC_UDP_PORT_OUT		=> rc_src_udp,
			RC_DEST_UDP_PORT_OUT	=> rc_dest_udp,
		
				-- statistics
			FRAMES_RECEIVED_OUT		=> rc_frames_rec_ctr,
			BYTES_RECEIVED_OUT      => rc_bytes_rec,
		
			DEBUG_OUT				=> rc_debug
		);
	
	  FRAME_RECEIVER : trb_net16_gbe_frame_receiver
	  port map(
		CLK						=> CLK_SYS_IN,
		RESET					=> global_reset,
		LINK_OK_IN				=> link_ok,
		ALLOW_RX_IN				=> CFG_ALLOW_RX_IN,
		RX_MAC_CLK				=> CLK_RX_125_IN,
		MY_MAC_IN				=> MY_MAC_IN,
	
	  -- input signals from TS_MAC
		MAC_RX_EOF_IN			=> MAC_RX_EOF_IN,
		MAC_RX_ER_IN			=> MAC_RX_ERROR_IN,
		MAC_RXD_IN				=> MAC_RX_DATA_IN,
		MAC_RX_EN_IN			=> MAC_RX_WRITE_IN,
		MAC_RX_FIFO_ERR_IN		=> MAC_RX_FIFO_ERR_IN,
		MAC_RX_FIFO_FULL_OUT	=> MAC_RX_FIFOFULL_OUT,
		MAC_RX_STAT_EN_IN		=> MAC_RX_STAT_EN_IN,
		MAC_RX_STAT_VEC_IN		=> MAC_RX_STATS_IN,
	  -- output signal to control logic
		FR_Q_OUT				=> fr_q,
		FR_RD_EN_IN				=> fr_rd_en,
		FR_FRAME_VALID_OUT		=> fr_frame_valid,
		FR_GET_FRAME_IN			=> fr_get_frame,
		FR_FRAME_SIZE_OUT		=> fr_frame_size,
		FR_FRAME_PROTO_OUT		=> fr_frame_proto,
		FR_IP_PROTOCOL_OUT		=> fr_ip_proto,
		FR_ALLOWED_TYPES_IN   	=> (others => '1'), --fr_allowed_types,
		FR_ALLOWED_IP_IN      	=> (others => '1'), --fr_allowed_ip,
		FR_ALLOWED_UDP_IN    	=> (others => '1'), --fr_allowed_udp,
		FR_VLAN_ID_IN			=> (others => '0'), --vlan_id,
		
		FR_SRC_MAC_ADDRESS_OUT	=> fr_src_mac,
		FR_DEST_MAC_ADDRESS_OUT => fr_dest_mac,
		FR_SRC_IP_ADDRESS_OUT	=> fr_src_ip,
		FR_DEST_IP_ADDRESS_OUT	=> fr_dest_ip,
		FR_SRC_UDP_PORT_OUT		=> fr_src_udp,
		FR_DEST_UDP_PORT_OUT	=> fr_dest_udp,
	
		MONITOR_RX_BYTES_OUT  	=> monitor_rx_bytes,
		MONITOR_RX_FRAMES_OUT 	=> monitor_rx_frames,
		MONITOR_DROPPED_OUT   	=> monitor_dropped
	  );
	  
	end generate rx_enable_gen;

	rx_disable_gen : if (RX_PATH_ENABLE = 0) generate
		
			rc_q <= (others => '0');
			rc_frame_ready <= '0';
			rc_frame_size <= (others => '0');
			rc_frame_proto <= (others => '0');
			
			rc_src_mac <= (others => '0');
			rc_dest_mac <= (others => '0');
			rc_src_ip <= (others => '0');
			rc_dest_ip <= (others => '0');
			rc_src_udp <= (others => '0');
			rc_dest_udp <= (others => '0');
		
			rc_frames_rec_ctr <= (others => '0');
			rc_bytes_rec <= (others => '0');
			rc_debug <= (others => '0');
			
			monitor_rx_bytes <= (others => '0');
		    monitor_rx_frames <= (others => '0');
		    monitor_dropped <= (others => '0');
		
	end generate rx_disable_gen;
	
	
	MONITOR_RX_FRAMES_OUT  <= monitor_rx_frames;
	MONITOR_RX_BYTES_OUT   <= monitor_rx_bytes;
	MONITOR_TX_FRAMES_OUT  <= monitor_tx_frames;
	MONITOR_TX_BYTES_OUT   <= monitor_tx_bytes;
	MONITOR_TX_PACKETS_OUT <= monitor_tx_packets;
	MONITOR_DROPPED_OUT    <= monitor_dropped;
	
	
--	MONITOR_RX_BYTES_OUT    <= monitor_rx_bytes(4 * 32 - 1 downto 3 * 32) + monitor_rx_bytes(3 * 32 - 1 downto 2 * 32) + monitor_rx_bytes(2 * 32 - 1 downto 1 * 32) + monitor_rx_bytes(1 * 32 - 1 downto 0 * 32);
--	MONITOR_RX_FRAMES_OUT   <= monitor_rx_frames(4 * 32 - 1 downto 3 * 32) + monitor_rx_frames(3 * 32 - 1 downto 2 * 32) + monitor_rx_frames(2 * 32 - 1 downto 1 * 32) + monitor_rx_frames(1 * 32 - 1 downto 0 * 32); 
--	MONITOR_TX_BYTES_OUT    <= monitor_tx_bytes(4 * 32 - 1 downto 3 * 32) + monitor_tx_bytes(3 * 32 - 1 downto 2 * 32) + monitor_tx_bytes(2 * 32 - 1 downto 1 * 32) + monitor_tx_bytes(1 * 32 - 1 downto 0 * 32); 
--	MONITOR_TX_FRAMES_OUT   <= monitor_tx_frames(4 * 32 - 1 downto 3 * 32) + monitor_tx_frames(3 * 32 - 1 downto 2 * 32) + monitor_tx_frames(2 * 32 - 1 downto 1 * 32) + monitor_tx_frames(1 * 32 - 1 downto 0 * 32);
--	MONITOR_TX_PACKETS_OUT  <= monitor_tx_packets(4 * 32 - 1 downto 3 * 32) + monitor_tx_packets(3 * 32 - 1 downto 2 * 32) + monitor_tx_packets(2 * 32 - 1 downto 1 * 32) + monitor_tx_packets(1 * 32 - 1 downto 0 * 32);
--	MONITOR_DROPPED_OUT     <= (others => '0');


end architecture RTL;
