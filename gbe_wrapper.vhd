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
		DO_SIMULATION : integer range 0 to 1;
		INCLUDE_DEBUG : integer range 0 to 1;
		
		USE_INTERNAL_TRBNET_DUMMY : integer range 0 to 1;
		RX_PATH_ENABLE : integer range 0 to 1;
		
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		INCREMENTAL_MODE : integer range 0 to 1 := 0;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		UP_DOWN_MODE : integer range 0 to 1 := 0;
		UP_DOWN_LIMIT : integer range 0 to 16777215 := 0;
		FIXED_DELAY : integer range 0 to 16777215 := 16777215;
		
		NUMBER_OF_GBE_LINKS : integer range 1 to 4;
		LINKS_ACTIVE : std_logic_vector(3 downto 0)
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
			
		MAKE_RESET_OUT					: out std_logic
	);
end entity gbe_wrapper;

architecture RTL of gbe_wrapper is
	
	signal mac_ready_conf		: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mac_reconf			: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
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
	
begin
	
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
		     
	gbe_inst1 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => DO_SIMULATION,
		        INCLUDE_DEBUG             => INCLUDE_DEBUG,
		        USE_INTERNAL_TRBNET_DUMMY => USE_INTERNAL_TRBNET_DUMMY,
		        RX_PATH_ENABLE            => RX_PATH_ENABLE,
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
		     
		     MAC_READY_CONF_IN        => mac_ready_conf(3),
		     MAC_RECONF_OUT           => mac_reconf(3),
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
		     
		     CTS_NUMBER_IN            => CTS_NUMBER_IN,
		     CTS_CODE_IN              => CTS_CODE_IN,
		     CTS_INFORMATION_IN       => CTS_INFORMATION_IN,
		     CTS_READOUT_TYPE_IN      => CTS_READOUT_TYPE_IN,
		     CTS_START_READOUT_IN     => CTS_START_READOUT_IN,
		     CTS_DATA_OUT             => CTS_DATA_OUT,
		     CTS_DATAREADY_OUT        => CTS_DATAREADY_OUT,
		     CTS_READOUT_FINISHED_OUT => CTS_READOUT_FINISHED_OUT,
		     CTS_READ_IN              => CTS_READ_IN,
		     CTS_LENGTH_OUT           => CTS_LENGTH_OUT,
		     CTS_ERROR_PATTERN_OUT    => CTS_ERROR_PATTERN_OUT,
		     
		     FEE_DATA_IN              => FEE_DATA_IN,
		     FEE_DATAREADY_IN         => FEE_DATAREADY_IN,
		     FEE_READ_OUT             => FEE_READ_OUT,
		     FEE_STATUS_BITS_IN       => FEE_STATUS_BITS_IN,
		     FEE_BUSY_IN              => FEE_BUSY_IN,
		     
		     MC_UNIQUE_ID_IN          => MC_UNIQUE_ID_IN,
		     
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
		     
		     MAKE_RESET_OUT           => MAKE_RESET_OUT
		);
		     
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
			
			GBE_MAX_SUB_OUT             => cfg_max_sub,
			GBE_MAX_QUEUE_OUT           => cfg_max_queue,
			GBE_MAX_SUBS_IN_QUEUE_OUT   => cfg_max_subs_in_queue,
			GBE_MAX_SINGLE_SUB_OUT      => cfg_max_single_sub,
			
			MONITOR_RX_BYTES_IN         => (others => '0'), --monitor_rx_bytes,
			MONITOR_RX_FRAMES_IN        => (others => '0'), --monitor_rx_frames,
			MONITOR_TX_BYTES_IN         => (others => '0'), --monitor_tx_bytes,
			MONITOR_TX_FRAMES_IN        => (others => '0'), --monitor_tx_frames,
			MONITOR_TX_PACKETS_IN       => (others => '0'), --monitor_tx_packets,
			MONITOR_DROPPED_IN          => (others => '0'), --monitor_dropped,
			
			MONITOR_SELECT_REC_IN	      => (others => '0'), --dbg_select_rec,
			MONITOR_SELECT_REC_BYTES_IN   => (others => '0'), --dbg_select_rec_bytes,
			MONITOR_SELECT_SENT_BYTES_IN  => (others => '0'), --dbg_select_sent_bytes,
			MONITOR_SELECT_SENT_IN	      => (others => '0'), --dbg_select_sent,
			MONITOR_SELECT_DROP_IN_IN     => (others => '0'), --dbg_select_drop_in,
			MONITOR_SELECT_DROP_OUT_IN    => (others => '0'), --dbg_select_drop_out,
			MONITOR_SELECT_GEN_DBG_IN     => (others => '0'), --dbg_select_gen,
			
			DATA_HIST_IN => dbg_hist,
			SCTRL_HIST_IN => dbg_hist2
		);
		end generate;
		
		setup_sim_gen : if (DO_SIMULATION = 1) generate
			cfg_gbe_enable <= '1';
			cfg_allow_rx <= '1';
		end generate;

end architecture RTL;
