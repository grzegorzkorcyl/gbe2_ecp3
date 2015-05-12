LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;


use work.trb_net_gbe_components.all;

entity gbe_wrapper is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		INCLUDE_DEBUG : integer range 0 to 1 := 0;
		
		USE_INTERNAL_TRBNET_DUMMY : integer range 0 to 1 := 0;
		USE_EXTERNAL_TRBNET_DUMMY : integer range 0 to 1 := 0;
		RX_PATH_ENABLE : integer range 0 to 1 := 1;
		
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		INCREMENTAL_MODE : integer range 0 to 1 := 0;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		UP_DOWN_MODE : integer range 0 to 1 := 0;
		UP_DOWN_LIMIT : integer range 0 to 16777215 := 0;
		FIXED_DELAY : integer range 0 to 16777215 := 16777215;
		
		NUMBER_OF_GBE_LINKS : integer range 1 to 4 := 4;
		LINKS_ACTIVE      : std_logic_vector(3 downto 0) := "1111";
		LINK_HAS_PING     : std_logic_vector(3 downto 0) := "1111";
		LINK_HAS_ARP      : std_logic_vector(3 downto 0) := "1111";
		LINK_HAS_DHCP     : std_logic_vector(3 downto 0) := "1111";
		LINK_HAS_READOUT  : std_logic_vector(3 downto 0) := "1111";
		LINK_HAS_SLOWCTRL : std_logic_vector(3 downto 0) := "1111"; 
		
		NUMBER_OF_OUTPUT_LINKS : integer range 0 to 4 := 0
	);
	port (
		CLK_SYS_IN		: in std_logic;
		CLK_125_IN		: in std_logic;
		RESET			: in std_logic;
		GSR_N			: in std_logic;
		
		SD_RXD_P_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_RXD_N_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_TXD_P_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_TXD_N_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_PRSNT_N_IN			: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_LOS_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0); -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
		SD_TXDIS_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0); -- SFP disable
		
		TRIGGER_IN              : in std_logic; -- for debug purpose only
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
			-- Registers config
		BUS_ADDR_IN               : in std_logic_vector(7 downto 0);
		BUS_DATA_IN               : in std_logic_vector(31 downto 0);
		BUS_DATA_OUT              : out std_logic_vector(31 downto 0);
		BUS_WRITE_EN_IN           : in std_logic;
		BUS_READ_EN_IN            : in std_logic;
		BUS_ACK_OUT               : out std_logic;
			
		MAKE_RESET_OUT					: out std_logic;
		
		DEBUG_OUT				  : out std_logic_vector(127 downto 0)
	);
end entity gbe_wrapper;

architecture RTL of gbe_wrapper is
	
	signal mac_ready_conf		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_reconf			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_an_ready			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_fifoavail		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_fifoeof			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_fifoempty		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_fifofull		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_tx_data			: std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal mac_tx_read			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_tx_discrfrm		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_tx_stat_en		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_tx_stats			: std_logic_vector(NUMBER_OF_GBE_LINKS * 31 - 1 downto 0);
	signal mac_tx_done			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_fifo_err		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_stats			: std_logic_vector(NUMBER_OF_GBE_LINKS * 32 - 1 downto 0);
	signal mac_rx_data			: std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal mac_rx_write			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_stat_en		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_eof			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_rx_err			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	
	signal clk_125_from_pcs		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal clk_125_rx_from_pcs	: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);

	signal cfg_gbe_enable            : std_logic;                    
	signal cfg_ipu_enable            : std_logic;                    
	signal cfg_mult_enable           : std_logic;                    
	signal cfg_subevent_id			 : std_logic_vector(31 downto 0);
	signal cfg_subevent_dec          : std_logic_vector(31 downto 0);
	signal cfg_queue_dec             : std_logic_vector(31 downto 0);
	signal cfg_readout_ctr           : std_logic_vector(23 downto 0);
	signal cfg_readout_ctr_valid     : std_logic;
	signal cfg_insert_ttype          : std_logic;
	signal cfg_max_sub               : std_logic_vector(15 downto 0);
	signal cfg_max_queue             : std_logic_vector(15 downto 0);
	signal cfg_max_subs_in_queue     : std_logic_vector(15 downto 0);
	signal cfg_max_single_sub        : std_logic_vector(15 downto 0);
	signal cfg_additional_hdr        : std_logic;   
	signal cfg_soft_rst				 : std_logic;
	signal cfg_allow_rx				 : std_logic;
	signal cfg_max_frame			 : std_logic_vector(15 downto 0);
	
	signal dbg_hist, dbg_hist2 : hist_array;
	
	signal master_mac, mac_0, mac_1, mac_2, mac_3 : std_logic_vector(47 downto 0);
	signal cfg_max_reply : std_logic_vector(31 downto 0);
	
	signal mlt_cts_number		    : std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
	signal mlt_cts_code		        : std_logic_vector (8 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
	signal mlt_cts_information	    : std_logic_vector (8 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
	signal mlt_cts_readout_type     : std_logic_vector (4 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
	signal mlt_cts_start_readout    : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_data			    : std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_dataready	    : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_readout_finished : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_read		        : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_length		    : std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_cts_error_pattern    : std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_fee_data		        : std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_fee_dataready	    : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_fee_read			    : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_fee_status	        : std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal mlt_fee_busy		        : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
	signal local_cts_number : std_logic_vector (15 downto 0);
	signal local_cts_code : std_logic_vector (7 downto 0);
	signal local_cts_information : std_logic_vector (7 downto 0);
	signal local_cts_readout_type : std_logic_vector (3 downto 0);
	signal local_cts_start_readout : std_logic;
	signal local_cts_readout_finished : std_logic;
	signal local_cts_status_bits : std_logic_vector (31 downto 0);
	signal local_fee_data : std_logic_vector (15 downto 0);
	signal local_fee_dataready : std_logic;
	signal local_fee_read : std_logic;
	signal local_fee_status_bits : std_logic_vector (31 downto 0);
	signal local_fee_busy : std_logic;
	signal dhcp_done : std_logic_vector(3 downto 0);
	signal all_links_ready : std_logic;
	signal monitor_rx_frames, monitor_rx_bytes, monitor_tx_frames, monitor_tx_bytes, monitor_tx_packets, monitor_dropped : std_logic_vector(4 * 32 - 1 downto 0);
	signal sum_rx_frames, sum_rx_bytes, sum_tx_frames, sum_tx_bytes, sum_tx_packets, sum_dropped : std_logic_vector(31 downto 0);
	
	signal dummy_event : std_logic_vector(15 downto 0);
	signal dummy_mode : std_logic;
	
begin
	
	mac_0 <= master_mac(31 downto 8) & x"f50002";
	mac_1 <= master_mac(31 downto 8) & x"f60002";
	mac_2 <= master_mac(31 downto 8) & x"f70002";
	mac_3 <= master_mac(31 downto 8) & x"f80002";
	
	all_links_ready <= '1' when dhcp_done = x"f" else '0';	
	
	physical : entity work.gbe_med_interface
	generic map(DO_SIMULATION       => DO_SIMULATION,
		        NUMBER_OF_GBE_LINKS => NUMBER_OF_GBE_LINKS,
		        LINKS_ACTIVE        => LINKS_ACTIVE)
	port map(
			 RESET               => RESET,
		     GSR_N               => GSR_N,
		     CLK_SYS_IN          => CLK_SYS_IN,
		     CLK_125_OUT         => clk_125_from_pcs,
		     CLK_125_IN          => CLK_125_IN,
		     CLK_125_RX_OUT      => clk_125_rx_from_pcs,
		     
		     MAC_READY_CONF_OUT  => mac_ready_conf,
		     MAC_RECONF_IN       => mac_reconf,
		     MAC_AN_READY_OUT	 => mac_an_ready,
		     MAC_FIFOAVAIL_IN    => mac_fifoavail,
		     MAC_FIFOEOF_IN      => mac_fifoeof,
		     MAC_FIFOEMPTY_IN    => mac_fifoempty,
		     MAC_RX_FIFOFULL_IN  => mac_rx_fifofull,
		     MAC_TX_DATA_IN      => mac_tx_data,
		     MAC_TX_READ_OUT     => mac_tx_read,
		     MAC_TX_DISCRFRM_OUT => mac_tx_discrfrm,
		     MAC_TX_STAT_EN_OUT  => mac_tx_stat_en,
		     MAC_TX_STATS_OUT    => mac_tx_stats,
		     MAC_TX_DONE_OUT     => mac_tx_done,
		     MAC_RX_FIFO_ERR_OUT => mac_rx_fifo_err,
		     MAC_RX_STATS_OUT    => mac_rx_stats,
		     MAC_RX_DATA_OUT     => mac_rx_data,
		     MAC_RX_WRITE_OUT    => mac_rx_write,
		     MAC_RX_STAT_EN_OUT  => mac_rx_stat_en,
		     MAC_RX_EOF_OUT      => mac_rx_eof,
		     MAC_RX_ERROR_OUT    => mac_rx_err,
		     
		     SD_RXD_P_IN         => SD_RXD_P_IN,
		     SD_RXD_N_IN         => SD_RXD_N_IN,
		     SD_TXD_P_OUT        => SD_TXD_P_OUT,
		     SD_TXD_N_OUT        => SD_TXD_N_OUT,
		     SD_PRSNT_N_IN       => SD_PRSNT_N_IN,
		     SD_LOS_IN           => SD_LOS_IN,
		     SD_TXDIS_OUT        => SD_TXDIS_OUT,
		     
		     DEBUG_OUT           => open
     );

	-- sfp8
	GEN_LINK_3 : if (LINKS_ACTIVE(3) = '1') generate		     
	gbe_inst3 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => DO_SIMULATION,
		        INCLUDE_DEBUG             => INCLUDE_DEBUG,
		        USE_INTERNAL_TRBNET_DUMMY => USE_INTERNAL_TRBNET_DUMMY,
		        RX_PATH_ENABLE            => RX_PATH_ENABLE,
		        
		        INCLUDE_READOUT		=> LINK_HAS_READOUT(3),
				INCLUDE_SLOWCTRL	=> LINK_HAS_SLOWCTRL(3),
				INCLUDE_DHCP		=> LINK_HAS_DHCP(3),
				INCLUDE_ARP			=> LINK_HAS_ARP(3),
				INCLUDE_PING		=> LINK_HAS_PING(3),
				
		        FRAME_BUFFER_SIZE	 => 1,
				READOUT_BUFFER_SIZE  => 4,
				SLOWCTRL_BUFFER_SIZE => 2,
				
		        FIXED_SIZE_MODE           => FIXED_SIZE_MODE,
		        INCREMENTAL_MODE          => INCREMENTAL_MODE,
		        FIXED_SIZE                => FIXED_SIZE,
		        FIXED_DELAY_MODE          => FIXED_DELAY_MODE,
		        UP_DOWN_MODE              => UP_DOWN_MODE,
		        UP_DOWN_LIMIT             => UP_DOWN_LIMIT,
		        FIXED_DELAY               => FIXED_DELAY)
	port map(
			 CLK_SYS_IN               => CLK_SYS_IN,
		     CLK_125_IN               => CLK_125_IN,
		     CLK_RX_125_IN            => clk_125_rx_from_pcs(3),
		     RESET                    => RESET,
		     GSR_N                    => GSR_N,
		     
		     MY_MAC_OUT => master_mac,
			 MY_MAC_IN  => mac_3,
			 DHCP_DONE_OUT => dhcp_done(3),
		     
		     MAC_READY_CONF_IN        => mac_ready_conf(3),
		     MAC_RECONF_OUT           => mac_reconf(3),
		     MAC_AN_READY_IN		  => mac_an_ready(3),
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(3),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(3),
		     MAC_FIFOEMPTY_OUT        => mac_fifoempty(3),
		     MAC_RX_FIFOFULL_OUT      => mac_rx_fifofull(3),
		     MAC_TX_DATA_OUT          => mac_tx_data(4 * 8 - 1 downto 3 * 8),
		     MAC_TX_READ_IN           => mac_tx_read(3),
		     MAC_TX_DISCRFRM_IN       => mac_tx_discrfrm(3),
		     MAC_TX_STAT_EN_IN        => mac_tx_stat_en(3),
		     MAC_TX_STATS_IN          => mac_tx_stats(4 * 31 - 1 downto 3 * 31),
		     MAC_TX_DONE_IN           => mac_tx_done(3),
		     MAC_RX_FIFO_ERR_IN       => mac_rx_fifo_err(3),
		     MAC_RX_STATS_IN          => mac_rx_stats(4 * 32 - 1 downto 3 * 32),
		     MAC_RX_DATA_IN           => mac_rx_data(4 * 8 - 1 downto 3 * 8),
		     MAC_RX_WRITE_IN          => mac_rx_write(3),
		     MAC_RX_STAT_EN_IN        => mac_rx_stat_en(3),
		     MAC_RX_EOF_IN            => mac_rx_eof(3),
		     MAC_RX_ERROR_IN          => mac_rx_err(3),
		     
--		     CTS_NUMBER_IN            => (others => '0'), --CTS_NUMBER_IN,
--		     CTS_CODE_IN              => (others => '0'), --CTS_CODE_IN,
--		     CTS_INFORMATION_IN       => (others => '0'), --CTS_INFORMATION_IN,
--		     CTS_READOUT_TYPE_IN      => (others => '0'), --CTS_READOUT_TYPE_IN,
--		     CTS_START_READOUT_IN     => '0', --CTS_START_READOUT_IN,
--		     CTS_DATA_OUT             => open, --CTS_DATA_OUT,
--		     CTS_DATAREADY_OUT        => open, --CTS_DATAREADY_OUT,
--		     CTS_READOUT_FINISHED_OUT => open, --CTS_READOUT_FINISHED_OUT,
--		     CTS_READ_IN              => '0', --CTS_READ_IN,
--		     CTS_LENGTH_OUT           => open, --CTS_LENGTH_OUT,
--		     CTS_ERROR_PATTERN_OUT    => open, --CTS_ERROR_PATTERN_OUT,
--		     FEE_DATA_IN              => (others => '0'), --FEE_DATA_IN,
--		     FEE_DATAREADY_IN         => '0', --FEE_DATAREADY_IN,
--		     FEE_READ_OUT             => open, --FEE_READ_OUT,
--		     FEE_STATUS_BITS_IN       => (others => '0'), --FEE_STATUS_BITS_IN,
--		     FEE_BUSY_IN              => '0', --FEE_BUSY_IN,
		     
		     CTS_NUMBER_IN            => mlt_cts_number(1 * 16 - 1 downto 0 * 16),		    
		     CTS_CODE_IN              => mlt_cts_code(1 * 8 - 1 downto 0 * 8),	        
		     CTS_INFORMATION_IN       => mlt_cts_information(1 * 8 - 1 downto 0 * 8),	    
		     CTS_READOUT_TYPE_IN      => mlt_cts_readout_type(1 * 4 - 1 downto 0 * 4),     
		     CTS_START_READOUT_IN     => mlt_cts_start_readout(0),    
		     CTS_DATA_OUT             => mlt_cts_data(1 * 32 - 1 downto 0 * 32),			    
		     CTS_DATAREADY_OUT        => mlt_cts_dataready(0),	    
		     CTS_READOUT_FINISHED_OUT => mlt_cts_readout_finished(0), 
		     CTS_READ_IN              => mlt_cts_read(0),		        
		     CTS_LENGTH_OUT           => mlt_cts_length(1 * 16 - 1 downto 0 * 16),		    
		     CTS_ERROR_PATTERN_OUT    => mlt_cts_error_pattern(1 * 32 - 1 downto 0 * 32),    
		     FEE_DATA_IN              => mlt_fee_data(1 * 16 - 1 downto 0 * 16),		        
		     FEE_DATAREADY_IN         => mlt_fee_dataready(0),	    
		     FEE_READ_OUT             => mlt_fee_read(0),			    
		     FEE_STATUS_BITS_IN       => mlt_fee_status(1 * 32 - 1 downto 0 * 32),	        
		     FEE_BUSY_IN              => mlt_fee_busy(0),		        
		     
		     MC_UNIQUE_ID_IN          => MC_UNIQUE_ID_IN,
		    
--			 GSC_CLK_IN               => GSC_CLK_IN,                                
--			 GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,            
--			 GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,                 
--			 GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,           
--			 GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,                   
--			 GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,             
--			 GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,      
--			 GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
--			 GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,                
--			 GSC_BUSY_IN              => '0', --GSC_BUSY_IN,                        
		     
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
		     
		     SLV_ADDR_IN              => SLV_ADDR_IN,
		     SLV_READ_IN              => SLV_READ_IN,
		     SLV_WRITE_IN             => SLV_WRITE_IN,
		     SLV_BUSY_OUT             => SLV_BUSY_OUT,
		     SLV_ACK_OUT              => SLV_ACK_OUT,
		     SLV_DATA_IN              => SLV_DATA_IN,
		     SLV_DATA_OUT             => SLV_DATA_OUT,
		     
		     CFG_GBE_ENABLE_IN        => cfg_gbe_enable,
		     CFG_IPU_ENABLE_IN        => cfg_ipu_enable,
		     CFG_MULT_ENABLE_IN       => cfg_mult_enable,
		     CFG_MAX_FRAME_IN         => cfg_max_frame,
		     CFG_ALLOW_RX_IN		  => cfg_allow_rx,
		     CFG_SOFT_RESET_IN		  => cfg_soft_rst,
		     CFG_SUBEVENT_ID_IN       => cfg_subevent_id,
		     CFG_SUBEVENT_DEC_IN      => cfg_subevent_dec,
		     CFG_QUEUE_DEC_IN         => cfg_queue_dec,
		     CFG_READOUT_CTR_IN       => cfg_readout_ctr,
		     CFG_READOUT_CTR_VALID_IN => cfg_readout_ctr_valid,
		     CFG_INSERT_TTYPE_IN      => cfg_insert_ttype,
		     CFG_MAX_SUB_IN           => cfg_max_sub,
		     CFG_MAX_QUEUE_IN         => cfg_max_queue,
		     CFG_MAX_SUBS_IN_QUEUE_IN => cfg_max_subs_in_queue,
		     CFG_MAX_SINGLE_SUB_IN    => cfg_max_single_sub,
		     CFG_ADDITIONAL_HDR_IN    => cfg_additional_hdr,
		     CFG_MAX_REPLY_SIZE_IN    => cfg_max_reply,
		     			 
			 MONITOR_RX_FRAMES_OUT    => monitor_rx_frames(4 * 32 - 1 downto 3 * 32),
			 MONITOR_RX_BYTES_OUT     => monitor_rx_bytes(4 * 32 - 1 downto 3 * 32),
			 MONITOR_TX_FRAMES_OUT    => monitor_tx_frames(4 * 32 - 1 downto 3 * 32),
			 MONITOR_TX_BYTES_OUT     => monitor_tx_bytes(4 * 32 - 1 downto 3 * 32),
			 MONITOR_TX_PACKETS_OUT   => monitor_tx_packets(4 * 32 - 1 downto 3 * 32),
			 MONITOR_DROPPED_OUT      => monitor_dropped(4 * 32 - 1 downto 3 * 32),
		     
		     MAKE_RESET_OUT           => MAKE_RESET_OUT
		);
	end generate GEN_LINK_3;
	
	-- sfp7
	GEN_LINK_2 : if (LINKS_ACTIVE(2) = '1') generate	
	gbe_inst2 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => DO_SIMULATION,
		        INCLUDE_DEBUG             => INCLUDE_DEBUG,
		        USE_INTERNAL_TRBNET_DUMMY => USE_INTERNAL_TRBNET_DUMMY,
		        RX_PATH_ENABLE            => 1,

		        INCLUDE_READOUT		=> LINK_HAS_READOUT(2),
				INCLUDE_SLOWCTRL	=> LINK_HAS_SLOWCTRL(2),
				INCLUDE_DHCP		=> LINK_HAS_DHCP(2),
				INCLUDE_ARP			=> LINK_HAS_ARP(2),
				INCLUDE_PING		=> LINK_HAS_PING(2),
				
				FRAME_BUFFER_SIZE	 => 1,
				READOUT_BUFFER_SIZE  => 4,
				SLOWCTRL_BUFFER_SIZE => 2,

		        FIXED_SIZE_MODE           => FIXED_SIZE_MODE,
		        INCREMENTAL_MODE          => INCREMENTAL_MODE,
		        FIXED_SIZE                => FIXED_SIZE,
		        FIXED_DELAY_MODE          => FIXED_DELAY_MODE,
		        UP_DOWN_MODE              => UP_DOWN_MODE,
		        UP_DOWN_LIMIT             => UP_DOWN_LIMIT,
		        FIXED_DELAY               => FIXED_DELAY)
	port map(
			 CLK_SYS_IN               => CLK_SYS_IN,
		     CLK_125_IN               => CLK_125_IN,
		     CLK_RX_125_IN            => clk_125_rx_from_pcs(2),
		     RESET                    => RESET,
		     GSR_N                    => GSR_N,
		     
		     MY_MAC_OUT => open,
		     MY_MAC_IN  => mac_2,
			 DHCP_DONE_OUT => dhcp_done(2),
		     
		     MAC_READY_CONF_IN        => mac_ready_conf(2),
		     MAC_RECONF_OUT           => mac_reconf(2),
		     MAC_AN_READY_IN		  => mac_an_ready(2),
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(2),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(2),
		     MAC_FIFOEMPTY_OUT        => mac_fifoempty(2),
		     MAC_RX_FIFOFULL_OUT      => mac_rx_fifofull(2),
		     MAC_TX_DATA_OUT          => mac_tx_data(3 * 8 - 1 downto 2 * 8),
		     MAC_TX_READ_IN           => mac_tx_read(2),
		     MAC_TX_DISCRFRM_IN       => mac_tx_discrfrm(2),
		     MAC_TX_STAT_EN_IN        => mac_tx_stat_en(2),
		     MAC_TX_STATS_IN          => mac_tx_stats(3 * 31 - 1 downto 2 * 31),
		     MAC_TX_DONE_IN           => mac_tx_done(2),
		     MAC_RX_FIFO_ERR_IN       => mac_rx_fifo_err(2),
		     MAC_RX_STATS_IN          => mac_rx_stats(3 * 32 - 1 downto 2 * 32),
		     MAC_RX_DATA_IN           => mac_rx_data(3 * 8 - 1 downto 2 * 8),
		     MAC_RX_WRITE_IN          => mac_rx_write(2),
		     MAC_RX_STAT_EN_IN        => mac_rx_stat_en(2),
		     MAC_RX_EOF_IN            => mac_rx_eof(2),
		     MAC_RX_ERROR_IN          => mac_rx_err(2),
		     
		     CTS_NUMBER_IN            => (others => '0'), --CTS_NUMBER_IN,
		     CTS_CODE_IN              => (others => '0'), --CTS_CODE_IN,
		     CTS_INFORMATION_IN       => (others => '0'), --CTS_INFORMATION_IN,
		     CTS_READOUT_TYPE_IN      => (others => '0'), --CTS_READOUT_TYPE_IN,
		     CTS_START_READOUT_IN     => '0', --CTS_START_READOUT_IN,
		     CTS_DATA_OUT             => open, --CTS_DATA_OUT,
		     CTS_DATAREADY_OUT        => open, --CTS_DATAREADY_OUT,
		     CTS_READOUT_FINISHED_OUT => open, --CTS_READOUT_FINISHED_OUT,
		     CTS_READ_IN              => '0', --CTS_READ_IN,
		     CTS_LENGTH_OUT           => open, --CTS_LENGTH_OUT,
		     CTS_ERROR_PATTERN_OUT    => open, --CTS_ERROR_PATTERN_OUT,
		     FEE_DATA_IN              => (others => '0'), --FEE_DATA_IN,
		     FEE_DATAREADY_IN         => '0', --FEE_DATAREADY_IN,
		     FEE_READ_OUT             => open, --FEE_READ_OUT,
		     FEE_STATUS_BITS_IN       => (others => '0'), --FEE_STATUS_BITS_IN,
		     FEE_BUSY_IN              => '0', --FEE_BUSY_IN,

-- 		     CTS_NUMBER_IN            => mlt_cts_number(2 * 16 - 1 downto 1 * 16),		    
-- 		     CTS_CODE_IN              => mlt_cts_code(2 * 8 - 1 downto 1 * 8),	        
-- 		     CTS_INFORMATION_IN       => mlt_cts_information(2 * 8 - 1 downto 1 * 8),	    
-- 		     CTS_READOUT_TYPE_IN      => mlt_cts_readout_type(2 * 4 - 1 downto 1 * 4),     
-- 		     CTS_START_READOUT_IN     => mlt_cts_start_readout(1),    
-- 		     CTS_DATA_OUT             => mlt_cts_data(2 * 32 - 1 downto 1 * 32),			    
-- 		     CTS_DATAREADY_OUT        => mlt_cts_dataready(1),	    
-- 		     CTS_READOUT_FINISHED_OUT => mlt_cts_readout_finished(1), 
-- 		     CTS_READ_IN              => mlt_cts_read(1),		        
-- 		     CTS_LENGTH_OUT           => mlt_cts_length(2 * 16 - 1 downto 1 * 16),		    
-- 		     CTS_ERROR_PATTERN_OUT    => mlt_cts_error_pattern(2 * 32 - 1 downto 1 * 32),    
-- 		     FEE_DATA_IN              => mlt_fee_data(2 * 16 - 1 downto 1 * 16),		        
-- 		     FEE_DATAREADY_IN         => mlt_fee_dataready(1),	    
-- 		     FEE_READ_OUT             => mlt_fee_read(1),			    
-- 		     FEE_STATUS_BITS_IN       => mlt_fee_status(2 * 32 - 1 downto 1 * 32),	        
-- 		     FEE_BUSY_IN              => mlt_fee_busy(1),	
		     
		     MC_UNIQUE_ID_IN          => MC_UNIQUE_ID_IN,
		     
		     GSC_CLK_IN               => GSC_CLK_IN,
		     GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,
		     GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,
		     GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,
		     GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,
		     GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,
		     GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,
		     GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
		     GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,
		     GSC_BUSY_IN              => '0', --GSC_BUSY_IN,
		     
--		     GSC_CLK_IN               => GSC_CLK_IN,
--		     GSC_INIT_DATAREADY_OUT   => GSC_INIT_DATAREADY_OUT,
--		     GSC_INIT_DATA_OUT        => GSC_INIT_DATA_OUT,
--		     GSC_INIT_PACKET_NUM_OUT  => GSC_INIT_PACKET_NUM_OUT,
--		     GSC_INIT_READ_IN         => GSC_INIT_READ_IN,
--		     GSC_REPLY_DATAREADY_IN   => GSC_REPLY_DATAREADY_IN,
--		     GSC_REPLY_DATA_IN        => GSC_REPLY_DATA_IN,
--		     GSC_REPLY_PACKET_NUM_IN  => GSC_REPLY_PACKET_NUM_IN,
--		     GSC_REPLY_READ_OUT       => GSC_REPLY_READ_OUT,
--		     GSC_BUSY_IN              => GSC_BUSY_IN,
		     
--		     SLV_ADDR_IN              => (others => '0'), --SLV_ADDR_IN,
--		     SLV_READ_IN              => '0', --SLV_READ_IN,
--		     SLV_WRITE_IN             => '0', --SLV_WRITE_IN,
--		     SLV_BUSY_OUT             => open, --SLV_BUSY_OUT,
--		     SLV_ACK_OUT              => open, --SLV_ACK_OUT,
--		     SLV_DATA_IN              => (others => '0'), --SLV_DATA_IN,
--		     SLV_DATA_OUT             => open, --SLV_DATA_OUT,
			 SLV_ADDR_IN              => SLV_ADDR_IN,
		     SLV_READ_IN              => SLV_READ_IN,
		     SLV_WRITE_IN             => SLV_WRITE_IN,
		     SLV_BUSY_OUT             => open,
		     SLV_ACK_OUT              => open,
		     SLV_DATA_IN              => SLV_DATA_IN,
		     SLV_DATA_OUT             => open,
		     
		     CFG_GBE_ENABLE_IN        => cfg_gbe_enable,
		     CFG_IPU_ENABLE_IN        => cfg_ipu_enable,
		     CFG_MULT_ENABLE_IN       => cfg_mult_enable,
		     CFG_MAX_FRAME_IN         => cfg_max_frame,
		     CFG_ALLOW_RX_IN		  => cfg_allow_rx,
		     CFG_SOFT_RESET_IN		  => cfg_soft_rst,
		     CFG_SUBEVENT_ID_IN       => cfg_subevent_id,
		     CFG_SUBEVENT_DEC_IN      => cfg_subevent_dec,
		     CFG_QUEUE_DEC_IN         => cfg_queue_dec,
		     CFG_READOUT_CTR_IN       => cfg_readout_ctr,
		     CFG_READOUT_CTR_VALID_IN => cfg_readout_ctr_valid,
		     CFG_INSERT_TTYPE_IN      => cfg_insert_ttype,
		     CFG_MAX_SUB_IN           => cfg_max_sub,
		     CFG_MAX_QUEUE_IN         => cfg_max_queue,
		     CFG_MAX_SUBS_IN_QUEUE_IN => cfg_max_subs_in_queue,
		     CFG_MAX_SINGLE_SUB_IN    => cfg_max_single_sub,
		     CFG_ADDITIONAL_HDR_IN    => cfg_additional_hdr,
		     CFG_MAX_REPLY_SIZE_IN    => cfg_max_reply,
		     			 
			 MONITOR_RX_FRAMES_OUT    => monitor_rx_frames(3 * 32 - 1 downto 2 * 32),
			 MONITOR_RX_BYTES_OUT     => monitor_rx_bytes(3 * 32 - 1 downto 2 * 32),
			 MONITOR_TX_FRAMES_OUT    => monitor_tx_frames(3 * 32 - 1 downto 2 * 32),
			 MONITOR_TX_BYTES_OUT     => monitor_tx_bytes(3 * 32 - 1 downto 2 * 32),
			 MONITOR_TX_PACKETS_OUT   => monitor_tx_packets(3 * 32 - 1 downto 2 * 32),
			 MONITOR_DROPPED_OUT      => monitor_dropped(3 * 32 - 1 downto 2 * 32),
		     
		     MAKE_RESET_OUT           => open --MAKE_RESET_OUT
		);
	end generate GEN_LINK_2;
	
	-- sfp6
	GEN_LINK_1 : if (LINKS_ACTIVE(1) = '1') generate	
	gbe_inst1 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => DO_SIMULATION,
		        INCLUDE_DEBUG             => INCLUDE_DEBUG,
		        USE_INTERNAL_TRBNET_DUMMY => USE_INTERNAL_TRBNET_DUMMY,
		        RX_PATH_ENABLE            => 1,
		        
		        INCLUDE_READOUT		=> LINK_HAS_READOUT(1),
				INCLUDE_SLOWCTRL	=> LINK_HAS_SLOWCTRL(1),
				INCLUDE_DHCP		=> LINK_HAS_DHCP(1),
				INCLUDE_ARP			=> LINK_HAS_ARP(1),
				INCLUDE_PING		=> LINK_HAS_PING(1),
						        
				FRAME_BUFFER_SIZE	 => 1,
				READOUT_BUFFER_SIZE  => 4,
				SLOWCTRL_BUFFER_SIZE => 2,
				
		        FIXED_SIZE_MODE           => FIXED_SIZE_MODE,
		        INCREMENTAL_MODE          => INCREMENTAL_MODE,
		        FIXED_SIZE                => FIXED_SIZE,
		        FIXED_DELAY_MODE          => FIXED_DELAY_MODE,
		        UP_DOWN_MODE              => UP_DOWN_MODE,
		        UP_DOWN_LIMIT             => UP_DOWN_LIMIT,
		        FIXED_DELAY               => FIXED_DELAY)
	port map(
			 CLK_SYS_IN               => CLK_SYS_IN,
		     CLK_125_IN               => CLK_125_IN,
		     CLK_RX_125_IN            => clk_125_rx_from_pcs(1),
		     RESET                    => RESET,
		     GSR_N                    => GSR_N,
		     
		     MY_MAC_OUT => open,
		     MY_MAC_IN  => mac_1,
			 DHCP_DONE_OUT => dhcp_done(1),
		     
		     MAC_READY_CONF_IN        => mac_ready_conf(1),
		     MAC_RECONF_OUT           => mac_reconf(1),
		     MAC_AN_READY_IN		  => mac_an_ready(1),
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(1),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(1),
		     MAC_FIFOEMPTY_OUT        => mac_fifoempty(1),
		     MAC_RX_FIFOFULL_OUT      => mac_rx_fifofull(1),
		     MAC_TX_DATA_OUT          => mac_tx_data(2 * 8 - 1 downto 1 * 8),
		     MAC_TX_READ_IN           => mac_tx_read(1),
		     MAC_TX_DISCRFRM_IN       => mac_tx_discrfrm(1),
		     MAC_TX_STAT_EN_IN        => mac_tx_stat_en(1),
		     MAC_TX_STATS_IN          => mac_tx_stats(2 * 31 - 1 downto 1 * 31),
		     MAC_TX_DONE_IN           => mac_tx_done(1),
		     MAC_RX_FIFO_ERR_IN       => mac_rx_fifo_err(1),
		     MAC_RX_STATS_IN          => mac_rx_stats(2 * 32 - 1 downto 1 * 32),
		     MAC_RX_DATA_IN           => mac_rx_data(2 * 8 - 1 downto 1 * 8),
		     MAC_RX_WRITE_IN          => mac_rx_write(1),
		     MAC_RX_STAT_EN_IN        => mac_rx_stat_en(1),
		     MAC_RX_EOF_IN            => mac_rx_eof(1),
		     MAC_RX_ERROR_IN          => mac_rx_err(1),
		     
		     CTS_NUMBER_IN            => (others => '0'), --CTS_NUMBER_IN,
		     CTS_CODE_IN              => (others => '0'), --CTS_CODE_IN,
		     CTS_INFORMATION_IN       => (others => '0'), --CTS_INFORMATION_IN,
		     CTS_READOUT_TYPE_IN      => (others => '0'), --CTS_READOUT_TYPE_IN,
		     CTS_START_READOUT_IN     => '0', --CTS_START_READOUT_IN,
		     CTS_DATA_OUT             => open, --CTS_DATA_OUT,
		     CTS_DATAREADY_OUT        => open, --CTS_DATAREADY_OUT,
		     CTS_READOUT_FINISHED_OUT => open, --CTS_READOUT_FINISHED_OUT,
		     CTS_READ_IN              => '0', --CTS_READ_IN,
		     CTS_LENGTH_OUT           => open, --CTS_LENGTH_OUT,
		     CTS_ERROR_PATTERN_OUT    => open, --CTS_ERROR_PATTERN_OUT,
		     FEE_DATA_IN              => (others => '0'), --FEE_DATA_IN,
		     FEE_DATAREADY_IN         => '0', --FEE_DATAREADY_IN,
		     FEE_READ_OUT             => open, --FEE_READ_OUT,
		     FEE_STATUS_BITS_IN       => (others => '0'), --FEE_STATUS_BITS_IN,
		     FEE_BUSY_IN              => '0', --FEE_BUSY_IN,

-- 		     CTS_NUMBER_IN            => mlt_cts_number(2 * 16 - 1 downto 1 * 16),		    
-- 		     CTS_CODE_IN              => mlt_cts_code(2 * 8 - 1 downto 1 * 8),	        
-- 		     CTS_INFORMATION_IN       => mlt_cts_information(2 * 8 - 1 downto 1 * 8),	    
-- 		     CTS_READOUT_TYPE_IN      => mlt_cts_readout_type(2 * 4 - 1 downto 1 * 4),     
-- 		     CTS_START_READOUT_IN     => mlt_cts_start_readout(1),    
-- 		     CTS_DATA_OUT             => mlt_cts_data(2 * 32 - 1 downto 1 * 32),			    
-- 		     CTS_DATAREADY_OUT        => mlt_cts_dataready(1),	    
-- 		     CTS_READOUT_FINISHED_OUT => mlt_cts_readout_finished(1), 
-- 		     CTS_READ_IN              => mlt_cts_read(1),		        
-- 		     CTS_LENGTH_OUT           => mlt_cts_length(2 * 16 - 1 downto 1 * 16),		    
-- 		     CTS_ERROR_PATTERN_OUT    => mlt_cts_error_pattern(2 * 32 - 1 downto 1 * 32),    
-- 		     FEE_DATA_IN              => mlt_fee_data(2 * 16 - 1 downto 1 * 16),		        
-- 		     FEE_DATAREADY_IN         => mlt_fee_dataready(1),	    
-- 		     FEE_READ_OUT             => mlt_fee_read(1),			    
-- 		     FEE_STATUS_BITS_IN       => mlt_fee_status(2 * 32 - 1 downto 1 * 32),	        
-- 		     FEE_BUSY_IN              => mlt_fee_busy(1),
		     
		     MC_UNIQUE_ID_IN          => MC_UNIQUE_ID_IN,
		     
		     GSC_CLK_IN               => GSC_CLK_IN,
		     GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,
		     GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,
		     GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,
		     GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,
		     GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,
		     GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,
		     GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
		     GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,
		     GSC_BUSY_IN              => '0', --GSC_BUSY_IN,
		     
--		     SLV_ADDR_IN              => (others => '0'), --SLV_ADDR_IN,
--		     SLV_READ_IN              => '0', --SLV_READ_IN,
--		     SLV_WRITE_IN             => '0', --SLV_WRITE_IN,
--		     SLV_BUSY_OUT             => open, --SLV_BUSY_OUT,
--		     SLV_ACK_OUT              => open, --SLV_ACK_OUT,
--		     SLV_DATA_IN              => (others => '0'), --SLV_DATA_IN,
--		     SLV_DATA_OUT             => open, --SLV_DATA_OUT,
			 SLV_ADDR_IN              => SLV_ADDR_IN,
		     SLV_READ_IN              => SLV_READ_IN,
		     SLV_WRITE_IN             => SLV_WRITE_IN,
		     SLV_BUSY_OUT             => open,
		     SLV_ACK_OUT              => open,
		     SLV_DATA_IN              => SLV_DATA_IN,
		     SLV_DATA_OUT             => open,
		     
		     CFG_GBE_ENABLE_IN        => cfg_gbe_enable,
		     CFG_IPU_ENABLE_IN        => cfg_ipu_enable,
		     CFG_MULT_ENABLE_IN       => cfg_mult_enable,
		     CFG_MAX_FRAME_IN         => cfg_max_frame,
		     CFG_ALLOW_RX_IN		  => cfg_allow_rx,
		     CFG_SOFT_RESET_IN		  => cfg_soft_rst,
		     CFG_SUBEVENT_ID_IN       => cfg_subevent_id,
		     CFG_SUBEVENT_DEC_IN      => cfg_subevent_dec,
		     CFG_QUEUE_DEC_IN         => cfg_queue_dec,
		     CFG_READOUT_CTR_IN       => cfg_readout_ctr,
		     CFG_READOUT_CTR_VALID_IN => cfg_readout_ctr_valid,
		     CFG_INSERT_TTYPE_IN      => cfg_insert_ttype,
		     CFG_MAX_SUB_IN           => cfg_max_sub,
		     CFG_MAX_QUEUE_IN         => cfg_max_queue,
		     CFG_MAX_SUBS_IN_QUEUE_IN => cfg_max_subs_in_queue,
		     CFG_MAX_SINGLE_SUB_IN    => cfg_max_single_sub,
		     CFG_ADDITIONAL_HDR_IN    => cfg_additional_hdr,
			 CFG_MAX_REPLY_SIZE_IN    => cfg_max_reply,	
			 		 
			 MONITOR_RX_FRAMES_OUT    => monitor_rx_frames(2 * 32 - 1 downto 1 * 32),
			 MONITOR_RX_BYTES_OUT     => monitor_rx_bytes(2 * 32 - 1 downto 1 * 32),
			 MONITOR_TX_FRAMES_OUT    => monitor_tx_frames(2 * 32 - 1 downto 1 * 32),
			 MONITOR_TX_BYTES_OUT     => monitor_tx_bytes(2 * 32 - 1 downto 1 * 32),
			 MONITOR_TX_PACKETS_OUT   => monitor_tx_packets(2 * 32 - 1 downto 1 * 32),
			 MONITOR_DROPPED_OUT      => monitor_dropped(2 * 32 - 1 downto 1 * 32),
		     
		     MAKE_RESET_OUT           => open --MAKE_RESET_OUT
		);
	end generate GEN_LINK_1;
	
	-- sfp5
	GEN_LINK_0 : if (LINKS_ACTIVE(0) = '1') generate
	gbe_inst0 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => DO_SIMULATION,
		        INCLUDE_DEBUG             => INCLUDE_DEBUG,
		        USE_INTERNAL_TRBNET_DUMMY => USE_INTERNAL_TRBNET_DUMMY,
		        RX_PATH_ENABLE            => 1,
		        
		        INCLUDE_READOUT		=> LINK_HAS_READOUT(0),
				INCLUDE_SLOWCTRL	=> LINK_HAS_SLOWCTRL(0),
				INCLUDE_DHCP		=> LINK_HAS_DHCP(0),
				INCLUDE_ARP			=> LINK_HAS_ARP(0),
				INCLUDE_PING		=> LINK_HAS_PING(0),
				
		        FRAME_BUFFER_SIZE	 => 1,
				READOUT_BUFFER_SIZE  => 4,
				SLOWCTRL_BUFFER_SIZE => 2,
				
		        FIXED_SIZE_MODE           => FIXED_SIZE_MODE,
		        INCREMENTAL_MODE          => INCREMENTAL_MODE,
		        FIXED_SIZE                => FIXED_SIZE,
		        FIXED_DELAY_MODE          => FIXED_DELAY_MODE,
		        UP_DOWN_MODE              => UP_DOWN_MODE,
		        UP_DOWN_LIMIT             => UP_DOWN_LIMIT,
		        FIXED_DELAY               => FIXED_DELAY)
	port map(
			 CLK_SYS_IN               => CLK_SYS_IN,
		     CLK_125_IN               => CLK_125_IN,
		     CLK_RX_125_IN            => clk_125_rx_from_pcs(0),
		     RESET                    => RESET,
		     GSR_N                    => GSR_N,
		     
		     MY_MAC_OUT => open,
		     MY_MAC_IN  => mac_0,
			 DHCP_DONE_OUT => dhcp_done(0),
		     
		     MAC_READY_CONF_IN        => mac_ready_conf(0),
		     MAC_RECONF_OUT           => mac_reconf(0),
		     MAC_AN_READY_IN		  => mac_an_ready(0),
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(0),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(0),
		     MAC_FIFOEMPTY_OUT        => mac_fifoempty(0),
		     MAC_RX_FIFOFULL_OUT      => mac_rx_fifofull(0),
		     MAC_TX_DATA_OUT          => mac_tx_data(1 * 8 - 1 downto 0 * 8),
		     MAC_TX_READ_IN           => mac_tx_read(0),
		     MAC_TX_DISCRFRM_IN       => mac_tx_discrfrm(0),
		     MAC_TX_STAT_EN_IN        => mac_tx_stat_en(0),
		     MAC_TX_STATS_IN          => mac_tx_stats(1 * 31 - 1 downto 0 * 31),
		     MAC_TX_DONE_IN           => mac_tx_done(0),
		     MAC_RX_FIFO_ERR_IN       => mac_rx_fifo_err(0),
		     MAC_RX_STATS_IN          => mac_rx_stats(1 * 32 - 1 downto 0 * 32),
		     MAC_RX_DATA_IN           => mac_rx_data(1 * 8 - 1 downto 0 * 8),
		     MAC_RX_WRITE_IN          => mac_rx_write(0),
		     MAC_RX_STAT_EN_IN        => mac_rx_stat_en(0),
		     MAC_RX_EOF_IN            => mac_rx_eof(0),
		     MAC_RX_ERROR_IN          => mac_rx_err(0),
		     
		     CTS_NUMBER_IN            => (others => '0'), --CTS_NUMBER_IN,
		     CTS_CODE_IN              => (others => '0'), --CTS_CODE_IN,
		     CTS_INFORMATION_IN       => (others => '0'), --CTS_INFORMATION_IN,
		     CTS_READOUT_TYPE_IN      => (others => '0'), --CTS_READOUT_TYPE_IN,
		     CTS_START_READOUT_IN     => '0', --CTS_START_READOUT_IN,
		     CTS_DATA_OUT             => open, --CTS_DATA_OUT,
		     CTS_DATAREADY_OUT        => open, --CTS_DATAREADY_OUT,
		     CTS_READOUT_FINISHED_OUT => open, --CTS_READOUT_FINISHED_OUT,
		     CTS_READ_IN              => '0', --CTS_READ_IN,
		     CTS_LENGTH_OUT           => open, --CTS_LENGTH_OUT,
		     CTS_ERROR_PATTERN_OUT    => open, --CTS_ERROR_PATTERN_OUT,
		     FEE_DATA_IN              => (others => '0'), --FEE_DATA_IN,
		     FEE_DATAREADY_IN         => '0', --FEE_DATAREADY_IN,
		     FEE_READ_OUT             => open, --FEE_READ_OUT,
		     FEE_STATUS_BITS_IN       => (others => '0'), --FEE_STATUS_BITS_IN,
		     FEE_BUSY_IN              => '0', --FEE_BUSY_IN,

-- 		     CTS_NUMBER_IN            => mlt_cts_number(3 * 16 - 1 downto 2 * 16),		    
-- 		     CTS_CODE_IN              => mlt_cts_code(3 * 8 - 1 downto 2 * 8),	        
-- 		     CTS_INFORMATION_IN       => mlt_cts_information(3 * 8 - 1 downto 2 * 8),	    
-- 		     CTS_READOUT_TYPE_IN      => mlt_cts_readout_type(3 * 4 - 1 downto 2 * 4),     
-- 		     CTS_START_READOUT_IN     => mlt_cts_start_readout(2),    
-- 		     CTS_DATA_OUT             => mlt_cts_data(3 * 32 - 1 downto 2 * 32),			    
-- 		     CTS_DATAREADY_OUT        => mlt_cts_dataready(2),	    
-- 		     CTS_READOUT_FINISHED_OUT => mlt_cts_readout_finished(2), 
-- 		     CTS_READ_IN              => mlt_cts_read(2),		        
-- 		     CTS_LENGTH_OUT           => mlt_cts_length(3 * 16 - 1 downto 2 * 16),		    
-- 		     CTS_ERROR_PATTERN_OUT    => mlt_cts_error_pattern(3 * 32 - 1 downto 2 * 32),    
-- 		     FEE_DATA_IN              => mlt_fee_data(3 * 16 - 1 downto 2 * 16),		        
-- 		     FEE_DATAREADY_IN         => mlt_fee_dataready(2),	    
-- 		     FEE_READ_OUT             => mlt_fee_read(2),			    
-- 		     FEE_STATUS_BITS_IN       => mlt_fee_status(3 * 32 - 1 downto 2 * 32),	        
-- 		     FEE_BUSY_IN              => mlt_fee_busy(2),	
		     
		     MC_UNIQUE_ID_IN          => MC_UNIQUE_ID_IN,
		     
		     GSC_CLK_IN               => GSC_CLK_IN,
		     GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,
		     GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,
		     GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,
		     GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,
		     GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,
		     GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,
		     GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
		     GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,
		     GSC_BUSY_IN              => '0', --GSC_BUSY_IN,
		     
--		     SLV_ADDR_IN              => (others => '0'), --SLV_ADDR_IN,
--		     SLV_READ_IN              => '0', --SLV_READ_IN,
--		     SLV_WRITE_IN             => '0', --SLV_WRITE_IN,
--		     SLV_BUSY_OUT             => open, --SLV_BUSY_OUT,
--		     SLV_ACK_OUT              => open, --SLV_ACK_OUT,
--		     SLV_DATA_IN              => (others => '0'), --SLV_DATA_IN,
--		     SLV_DATA_OUT             => open, --SLV_DATA_OUT,
			 SLV_ADDR_IN              => SLV_ADDR_IN,
		     SLV_READ_IN              => SLV_READ_IN,
		     SLV_WRITE_IN             => SLV_WRITE_IN,
		     SLV_BUSY_OUT             => open,
		     SLV_ACK_OUT              => open,
		     SLV_DATA_IN              => SLV_DATA_IN,
		     SLV_DATA_OUT             => open,
		     
		     CFG_GBE_ENABLE_IN        => cfg_gbe_enable,
		     CFG_IPU_ENABLE_IN        => cfg_ipu_enable,
		     CFG_MULT_ENABLE_IN       => cfg_mult_enable,
		     CFG_MAX_FRAME_IN         => cfg_max_frame,
		     CFG_ALLOW_RX_IN		  => cfg_allow_rx,
		     CFG_SOFT_RESET_IN		  => cfg_soft_rst,
		     CFG_SUBEVENT_ID_IN       => cfg_subevent_id,
		     CFG_SUBEVENT_DEC_IN      => cfg_subevent_dec,
		     CFG_QUEUE_DEC_IN         => cfg_queue_dec,
		     CFG_READOUT_CTR_IN       => cfg_readout_ctr,
		     CFG_READOUT_CTR_VALID_IN => cfg_readout_ctr_valid,
		     CFG_INSERT_TTYPE_IN      => cfg_insert_ttype,
		     CFG_MAX_SUB_IN           => cfg_max_sub,
		     CFG_MAX_QUEUE_IN         => cfg_max_queue,
		     CFG_MAX_SUBS_IN_QUEUE_IN => cfg_max_subs_in_queue,
		     CFG_MAX_SINGLE_SUB_IN    => cfg_max_single_sub,
		     CFG_ADDITIONAL_HDR_IN    => cfg_additional_hdr,
			 CFG_MAX_REPLY_SIZE_IN    => cfg_max_reply,
			 
			 MONITOR_RX_FRAMES_OUT    => monitor_rx_frames(1 * 32 - 1 downto 0 * 32),
			 MONITOR_RX_BYTES_OUT     => monitor_rx_bytes(1 * 32 - 1 downto 0 * 32),
			 MONITOR_TX_FRAMES_OUT    => monitor_tx_frames(1 * 32 - 1 downto 0 * 32),
			 MONITOR_TX_BYTES_OUT     => monitor_tx_bytes(1 * 32 - 1 downto 0 * 32),
			 MONITOR_TX_PACKETS_OUT   => monitor_tx_packets(1 * 32 - 1 downto 0 * 32),
			 MONITOR_DROPPED_OUT      => monitor_dropped(1 * 32 - 1 downto 0 * 32),
		     
		     MAKE_RESET_OUT           => open --MAKE_RESET_OUT
		);
	end generate GEN_LINK_0;
	
	real_ipu_gen : if USE_EXTERNAL_TRBNET_DUMMY = 0 generate
		ipu_mult : entity work.gbe_ipu_multiplexer
		generic map(
			DO_SIMULATION          => DO_SIMULATION,
			INCLUDE_DEBUG          => INCLUDE_DEBUG,
			NUMBER_OF_OUTPUT_LINKS => NUMBER_OF_OUTPUT_LINKS
		)
		port map(
			CLK_SYS_IN                  => CLK_SYS_IN,
			RESET                       => RESET,
			CTS_NUMBER_IN               => CTS_NUMBER_IN,
			CTS_CODE_IN                 => CTS_CODE_IN,
			CTS_INFORMATION_IN          => CTS_INFORMATION_IN,
			CTS_READOUT_TYPE_IN         => CTS_READOUT_TYPE_IN,
			CTS_START_READOUT_IN        => CTS_START_READOUT_IN,
			CTS_DATA_OUT                => CTS_DATA_OUT,
			CTS_DATAREADY_OUT           => CTS_DATAREADY_OUT,
			CTS_READOUT_FINISHED_OUT    => CTS_READOUT_FINISHED_OUT,
			CTS_READ_IN                 => CTS_READ_IN,
			CTS_LENGTH_OUT              => CTS_LENGTH_OUT,
			CTS_ERROR_PATTERN_OUT       => CTS_ERROR_PATTERN_OUT,
			FEE_DATA_IN                 => FEE_DATA_IN,
			FEE_DATAREADY_IN            => FEE_DATAREADY_IN,
			FEE_READ_OUT                => FEE_READ_OUT,
			FEE_STATUS_BITS_IN          => FEE_STATUS_BITS_IN,
			FEE_BUSY_IN                 => FEE_BUSY_IN,
			 
			MLT_CTS_NUMBER_OUT          => mlt_cts_number,
			MLT_CTS_CODE_OUT            => mlt_cts_code,
			MLT_CTS_INFORMATION_OUT     => mlt_cts_information,
			MLT_CTS_READOUT_TYPE_OUT    => mlt_cts_readout_type,
			MLT_CTS_START_READOUT_OUT   => mlt_cts_start_readout,
			MLT_CTS_DATA_IN             => mlt_cts_data,
			MLT_CTS_DATAREADY_IN        => mlt_cts_dataready,
			MLT_CTS_READOUT_FINISHED_IN => mlt_cts_readout_finished,
			MLT_CTS_READ_OUT            => mlt_cts_read,
			MLT_CTS_LENGTH_IN           => mlt_cts_length,
			MLT_CTS_ERROR_PATTERN_IN    => mlt_cts_error_pattern,
			MLT_FEE_DATA_OUT            => mlt_fee_data,		        
			MLT_FEE_DATAREADY_OUT       => mlt_fee_dataready,	    
			MLT_FEE_READ_IN             => mlt_fee_read,			    
			MLT_FEE_STATUS_BITS_OUT     => mlt_fee_status,	        
			MLT_FEE_BUSY_OUT            => mlt_fee_busy,		        
			 
			DEBUG_OUT                   => open
		);
	end generate real_ipu_gen;
	
	dummy_ipu_gen : if (USE_EXTERNAL_TRBNET_DUMMY = 1) generate 	
		ipu_mult : entity work.gbe_ipu_multiplexer
		generic map(
			DO_SIMULATION          => DO_SIMULATION,
			INCLUDE_DEBUG          => INCLUDE_DEBUG,
			NUMBER_OF_OUTPUT_LINKS => NUMBER_OF_OUTPUT_LINKS
		)
		port map(
			CLK_SYS_IN                  => CLK_SYS_IN,
			RESET                       => RESET,
			CTS_NUMBER_IN               => local_cts_number,           
			CTS_CODE_IN                 => local_cts_code,             
			CTS_INFORMATION_IN          => local_cts_information,      
			CTS_READOUT_TYPE_IN         => local_cts_readout_type,     
			CTS_START_READOUT_IN        => local_cts_start_readout,    
			CTS_DATA_OUT                => open,            
			CTS_DATAREADY_OUT           => open,                        
			CTS_READOUT_FINISHED_OUT    => local_cts_readout_finished, 
			CTS_READ_IN                 => '1',                       
			CTS_LENGTH_OUT              => open,            
			CTS_ERROR_PATTERN_OUT       => local_cts_status_bits,      
			FEE_DATA_IN                 => local_fee_data,              
			FEE_DATAREADY_IN            => local_fee_dataready,  
			FEE_READ_OUT                => local_fee_read,       
			FEE_STATUS_BITS_IN          => local_fee_status_bits,
			FEE_BUSY_IN                 => local_fee_busy,
			 
			MLT_CTS_NUMBER_OUT          => mlt_cts_number,
			MLT_CTS_CODE_OUT            => mlt_cts_code,
			MLT_CTS_INFORMATION_OUT     => mlt_cts_information,
			MLT_CTS_READOUT_TYPE_OUT    => mlt_cts_readout_type,
			MLT_CTS_START_READOUT_OUT   => mlt_cts_start_readout,
			MLT_CTS_DATA_IN             => mlt_cts_data,
			MLT_CTS_DATAREADY_IN        => mlt_cts_dataready,
			MLT_CTS_READOUT_FINISHED_IN => mlt_cts_readout_finished,
			MLT_CTS_READ_OUT            => mlt_cts_read,
			MLT_CTS_LENGTH_IN           => mlt_cts_length,
			MLT_CTS_ERROR_PATTERN_IN    => mlt_cts_error_pattern,
			MLT_FEE_DATA_OUT            => mlt_fee_data,		        
			MLT_FEE_DATAREADY_OUT       => mlt_fee_dataready,	    
			MLT_FEE_READ_IN             => mlt_fee_read,			    
			MLT_FEE_STATUS_BITS_OUT     => mlt_fee_status,	        
			MLT_FEE_BUSY_OUT            => mlt_fee_busy,		        
			 
			DEBUG_OUT                   => open
		);
		
		dummy : entity work.gbe_ipu_dummy
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
			GBE_READY_IN => '1', --all_links_ready,

			CFG_EVENT_SIZE_IN      => dummy_event,
			CFG_TRIGGERED_MODE_IN  => dummy_mode,
			TRIGGER_IN => TRIGGER_IN,
			                    
			CTS_NUMBER_OUT		     => local_cts_number,
			CTS_CODE_OUT		     => local_cts_code,
			CTS_INFORMATION_OUT	     => local_cts_information,
			CTS_READOUT_TYPE_OUT     => local_cts_readout_type,
			CTS_START_READOUT_OUT    => local_cts_start_readout,
			CTS_DATA_IN				 => (others => '0'),
			CTS_DATAREADY_IN	     => '0',
			CTS_READOUT_FINISHED_IN	 => local_cts_readout_finished,
			CTS_READ_OUT		     => open,
			CTS_LENGTH_IN		     => (others => '0'),
			CTS_ERROR_PATTERN_IN     => local_cts_status_bits,
			-- Data payload interface
			FEE_DATA_OUT		     => local_fee_data,
			FEE_DATAREADY_OUT	     => local_fee_dataready,
			FEE_READ_IN				 => local_fee_read,
			FEE_STATUS_BITS_OUT	     => local_fee_status_bits,
			FEE_BUSY_OUT		     => local_fee_busy
		);
		
		-- handler for triggers
		DUMMY_HANDLER: trb_net16_gbe_ipu_interface
		port map( 
			CLK_IPU 			     => CLK_SYS_IN,
			CLK_GBE					 => CLK_125_IN,
			RESET					 => RESET,
			--Event information coming from CTS
			CTS_NUMBER_IN			 => CTS_NUMBER_IN,
			CTS_CODE_IN				 => CTS_CODE_IN,
			CTS_INFORMATION_IN		 => CTS_INFORMATION_IN,
			CTS_READOUT_TYPE_IN		 => CTS_READOUT_TYPE_IN,
			CTS_START_READOUT_IN	 => CTS_START_READOUT_IN,
			--Information sent to CTS
			--status data, equipped with DHDR
			CTS_DATA_OUT			 => CTS_DATA_OUT,
			CTS_DATAREADY_OUT		 => CTS_DATAREADY_OUT,
			CTS_READOUT_FINISHED_OUT => CTS_READOUT_FINISHED_OUT,
			CTS_READ_IN				 => CTS_READ_IN,
			CTS_LENGTH_OUT			 => CTS_LENGTH_OUT,
			CTS_ERROR_PATTERN_OUT	 => CTS_ERROR_PATTERN_OUT,
			-- Data from Frontends
			FEE_DATA_IN				 => FEE_DATA_IN,
			FEE_DATAREADY_IN		 => FEE_DATAREADY_IN,
			FEE_READ_OUT			 => FEE_READ_OUT,
			FEE_STATUS_BITS_IN		 => FEE_STATUS_BITS_IN,
			FEE_BUSY_IN				 => FEE_BUSY_IN,
			-- slow control interface
			START_CONFIG_OUT		 => open,
			BANK_SELECT_OUT			 => open,
			CONFIG_DONE_IN			 => '1',
			DATA_GBE_ENABLE_IN		 => '1',
			DATA_IPU_ENABLE_IN		 => '1',
			MULT_EVT_ENABLE_IN		 => '1',
			MAX_SUBEVENT_SIZE_IN     => (others => '0'),
			MAX_QUEUE_SIZE_IN        => (others => '0'),
			MAX_SUBS_IN_QUEUE_IN     => (others => '0'),
			MAX_SINGLE_SUB_SIZE_IN   => (others => '0'),
			READOUT_CTR_IN			 => (others => '0'),
			READOUT_CTR_VALID_IN	 => '0',
			-- PacketConstructor interface
			PC_WR_EN_OUT			 => open,
			PC_DATA_OUT				 => open,
			PC_READY_IN				 => '1',
			PC_SOS_OUT				 => open,
			PC_EOS_OUT				 => open,
			PC_EOQ_OUT				 => open,
			PC_SUB_SIZE_OUT			 => open,
			PC_TRIG_NR_OUT			 => open,
			PC_TRIGGER_TYPE_OUT      => open,
			MONITOR_OUT              => open,
			DEBUG_OUT                => open
		);
	end generate dummy_ipu_gen;
		     
	setup_imp_gen : if (DO_SIMULATION = 0) generate
		SETUP : gbe_setup
		port map(
			CLK                         => CLK_SYS_IN,  
			RESET                       => RESET,
		
			-- interface to regio bus
			BUS_ADDR_IN                 => BUS_ADDR_IN,     
			BUS_DATA_IN                 => BUS_DATA_IN,     
			BUS_DATA_OUT                => BUS_DATA_OUT,    
			BUS_WRITE_EN_IN             => BUS_WRITE_EN_IN, 
			BUS_READ_EN_IN              => BUS_READ_EN_IN,  
			BUS_ACK_OUT                 => BUS_ACK_OUT,     
		
			-- output to gbe_buf
			GBE_SUBEVENT_ID_OUT         => cfg_subevent_id,
			GBE_SUBEVENT_DEC_OUT        => cfg_subevent_dec,
			GBE_QUEUE_DEC_OUT           => cfg_queue_dec,
			GBE_MAX_FRAME_OUT           => cfg_max_frame,
			GBE_USE_GBE_OUT             => cfg_gbe_enable,        
			GBE_USE_TRBNET_OUT          => cfg_ipu_enable,     
			GBE_USE_MULTIEVENTS_OUT     => cfg_mult_enable,
			GBE_READOUT_CTR_OUT         => cfg_readout_ctr,
			GBE_READOUT_CTR_VALID_OUT   => cfg_readout_ctr_valid,
			GBE_ALLOW_RX_OUT            => cfg_allow_rx,
			GBE_ADDITIONAL_HDR_OUT      => cfg_additional_hdr,
			GBE_INSERT_TTYPE_OUT        => cfg_insert_ttype,
			GBE_SOFT_RESET_OUT          => cfg_soft_rst,
			GBE_MAX_REPLY_OUT			=> cfg_max_reply,
			
			GBE_MAX_SUB_OUT             => cfg_max_sub,
			GBE_MAX_QUEUE_OUT           => cfg_max_queue,
			GBE_MAX_SUBS_IN_QUEUE_OUT   => cfg_max_subs_in_queue,
			GBE_MAX_SINGLE_SUB_OUT      => cfg_max_single_sub,
			
			MONITOR_RX_BYTES_IN         => sum_rx_bytes,
			MONITOR_RX_FRAMES_IN        => sum_rx_frames,
			MONITOR_TX_BYTES_IN         => sum_tx_bytes,
			MONITOR_TX_FRAMES_IN        => sum_tx_frames,
			MONITOR_TX_PACKETS_IN       => sum_tx_packets,
			MONITOR_DROPPED_IN          => sum_dropped,
			
			MONITOR_SELECT_REC_IN	      => (others => '0'), --dbg_select_rec,
			MONITOR_SELECT_REC_BYTES_IN   => (others => '0'), --dbg_select_rec_bytes,
			MONITOR_SELECT_SENT_BYTES_IN  => (others => '0'), --dbg_select_sent_bytes,
			MONITOR_SELECT_SENT_IN	      => (others => '0'), --dbg_select_sent,
			MONITOR_SELECT_DROP_IN_IN     => (others => '0'), --dbg_select_drop_in,
			MONITOR_SELECT_DROP_OUT_IN    => (others => '0'), --dbg_select_drop_out,
			MONITOR_SELECT_GEN_DBG_IN     => (others => '0'), --dbg_select_gen,
			
			DUMMY_EVENT_SIZE_OUT     => dummy_event,
			DUMMY_TRIGGERED_MODE_OUT => dummy_mode,
			
			DATA_HIST_IN => dbg_hist,
			SCTRL_HIST_IN => dbg_hist2
		);
	end generate;
	
	sum_rx_bytes   <= monitor_rx_bytes(4 * 32 - 1 downto 3 * 32) + monitor_rx_bytes(3 * 32 - 1 downto 2 * 32) + monitor_rx_bytes(2 * 32 - 1 downto 1 * 32) + monitor_rx_bytes(1 * 32 - 1 downto 0 * 32);
	sum_rx_frames  <= monitor_rx_frames(4 * 32 - 1 downto 3 * 32) + monitor_rx_frames(3 * 32 - 1 downto 2 * 32) + monitor_rx_frames(2 * 32 - 1 downto 1 * 32) + monitor_rx_frames(1 * 32 - 1 downto 0 * 32);    
	sum_tx_bytes   <= monitor_tx_bytes(4 * 32 - 1 downto 3 * 32) + monitor_tx_bytes(3 * 32 - 1 downto 2 * 32) + monitor_tx_bytes(2 * 32 - 1 downto 1 * 32) + monitor_tx_bytes(1 * 32 - 1 downto 0 * 32);        
	sum_tx_frames  <= monitor_tx_frames(4 * 32 - 1 downto 3 * 32) + monitor_tx_frames(3 * 32 - 1 downto 2 * 32) + monitor_tx_frames(2 * 32 - 1 downto 1 * 32) + monitor_tx_frames(1 * 32 - 1 downto 0 * 32);    
	sum_tx_packets <= monitor_tx_packets(4 * 32 - 1 downto 3 * 32) + monitor_tx_packets(3 * 32 - 1 downto 2 * 32) + monitor_tx_packets(2 * 32 - 1 downto 1 * 32) + monitor_tx_packets(1 * 32 - 1 downto 0 * 32);
	sum_dropped    <= monitor_dropped(4 * 32 - 1 downto 3 * 32) + monitor_dropped(3 * 32 - 1 downto 2 * 32) + monitor_dropped(2 * 32 - 1 downto 1 * 32) + monitor_dropped(1 * 32 - 1 downto 0 * 32);                                                                                                                                                                          
	
	setup_sim_gen : if (DO_SIMULATION = 1) generate
		cfg_gbe_enable <= '1';
		cfg_allow_rx <= '1';
	end generate;
	
	
	include_debug_gen : if (INCLUDE_DEBUG = 1) generate
		DEBUG_OUT(0) <= mac_an_ready(3);
		DEBUG_OUT(1) <= clk_125_rx_from_pcs(3);
		DEBUG_OUT(2) <= RESET;
		DEBUG_OUT(3) <= CLK_125_IN;
		
		DEBUG_OUT(127 downto 4) <= (others => '0');			
	end generate;

end architecture RTL;
