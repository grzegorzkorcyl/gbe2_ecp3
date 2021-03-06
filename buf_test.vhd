LIBRARY ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;
--use work.version.all;

entity buf_test is
generic( 
	DO_SIMULATION		: integer range 0 to 1 := 1;
	USE_125MHZ_EXTCLK       : integer range 0 to 1 := 1
);
port(
	CLK							: in	std_logic;
	TEST_CLK					: in	std_logic; -- only for simulation!
	CLK_125_IN				: in std_logic;  -- gk 28.04.01 used only in internal 125MHz clock mode
	RESET						: in	std_logic;
	GSR_N						: in	std_logic;
	-- Debug
	STAGE_STAT_REGS_OUT			: out	std_logic_vector(31 downto 0);
	STAGE_CTRL_REGS_IN			: in	std_logic_vector(31 downto 0);
	-- configuration interface
	IP_CFG_START_IN				: in 	std_logic;
	IP_CFG_BANK_SEL_IN			: in	std_logic_vector(3 downto 0);
	IP_CFG_DONE_OUT				: out	std_logic;
	IP_CFG_MEM_ADDR_OUT			: out	std_logic_vector(7 downto 0);
	IP_CFG_MEM_DATA_IN			: in	std_logic_vector(31 downto 0);
	IP_CFG_MEM_CLK_OUT			: out	std_logic;
	MR_RESET_IN					: in	std_logic;
	MR_MODE_IN					: in	std_logic;
	MR_RESTART_IN				: in	std_logic;
	-- gk 29.03.10
	SLV_ADDR_IN                  : in std_logic_vector(7 downto 0);
	SLV_READ_IN                  : in std_logic;
	SLV_WRITE_IN                 : in std_logic;
	SLV_BUSY_OUT                 : out std_logic;
	SLV_ACK_OUT                  : out std_logic;
	SLV_DATA_IN                  : in std_logic_vector(31 downto 0);
	SLV_DATA_OUT                 : out std_logic_vector(31 downto 0);
	-- gk 22.04.10
	-- registers setup interface
	BUS_ADDR_IN               : in std_logic_vector(7 downto 0);
	BUS_DATA_IN               : in std_logic_vector(31 downto 0);
	BUS_DATA_OUT              : out std_logic_vector(31 downto 0);  -- gk 26.04.10
	BUS_WRITE_EN_IN           : in std_logic;  -- gk 26.04.10
	BUS_READ_EN_IN            : in std_logic;  -- gk 26.04.10
	BUS_ACK_OUT               : out std_logic;  -- gk 26.04.10
	-- gk 23.04.10
	LED_PACKET_SENT_OUT          : out std_logic;
	LED_AN_DONE_N_OUT            : out std_logic;
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
	--SFP Connection
	SFP_RXD_P_IN				: in	std_logic;
	SFP_RXD_N_IN				: in	std_logic;
	SFP_TXD_P_OUT				: out	std_logic;
	SFP_TXD_N_OUT				: out	std_logic;
	SFP_REFCLK_P_IN				: in	std_logic;
	SFP_REFCLK_N_IN				: in	std_logic;
	SFP_PRSNT_N_IN				: in	std_logic; -- SFP Present ('0' = SFP in place, '1' = no SFP mounted)
	SFP_LOS_IN					: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	SFP_TXDIS_OUT				: out	std_logic; -- SFP disable
	
	-- interface between main_controller and hub logic
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
	
	MAKE_RESET_OUT           : out std_logic;

	-- for simulation of receiving part only
	MAC_RX_EOF_IN		: in	std_logic;
	MAC_RXD_IN		: in	std_logic_vector(7 downto 0);
	MAC_RX_EN_IN		: in	std_logic;


	-- debug ports
	ANALYZER_DEBUG_OUT			: out	std_logic_vector(63 downto 0)
);
end entity buf_test;

architecture buf_test of buf_test is

-- Placer Directives
--attribute HGROUP : string;
-- for whole architecture
--attribute HGROUP of trb_net16_gbe_buf : architecture is "GBE_BUF_group";


component tsmac36 --tsmac35
port(
	--------------- clock and reset port declarations ------------------
	hclk					: in	std_logic;
	txmac_clk				: in	std_logic;
	rxmac_clk				: in	std_logic;
	reset_n					: in	std_logic;
	txmac_clk_en			: in	std_logic;
	rxmac_clk_en			: in	std_logic;
	------------------- Input signals to the GMII ----------------
	rxd						: in	std_logic_vector(7 downto 0);
	rx_dv					: in	std_logic;
	rx_er					: in	std_logic;
	col						: in	std_logic;
	crs						: in	std_logic;
	-------------------- Input signals to the CPU I/F -------------------
	haddr					: in	std_logic_vector(7 downto 0);
	hdatain					: in	std_logic_vector(7 downto 0);
	hcs_n					: in	std_logic;
	hwrite_n				: in	std_logic;
	hread_n					: in	std_logic;
	---------------- Input signals to the Tx MAC FIFO I/F ---------------
	tx_fifodata				: in	std_logic_vector(7 downto 0);
	tx_fifoavail			: in	std_logic;
	tx_fifoeof				: in	std_logic;
	tx_fifoempty			: in	std_logic;
	tx_sndpaustim			: in	std_logic_vector(15 downto 0);
	tx_sndpausreq			: in	std_logic;
	tx_fifoctrl				: in	std_logic;
	---------------- Input signals to the Rx MAC FIFO I/F --------------- 
	rx_fifo_full			: in	std_logic;
	ignore_pkt				: in	std_logic;
	-------------------- Output signals from the GMII -----------------------
	txd						: out	std_logic_vector(7 downto 0);  
	tx_en					: out	std_logic;
	tx_er					: out	std_logic;
	-------------------- Output signals from the CPU I/F -------------------
	hdataout				: out	std_logic_vector(7 downto 0);
	hdataout_en_n			: out	std_logic;
	hready_n				: out	std_logic;
	cpu_if_gbit_en			: out	std_logic;
	---------------- Output signals from the Tx MAC FIFO I/F --------------- 
	tx_macread				: out	std_logic;
	tx_discfrm				: out	std_logic;
	tx_staten				: out	std_logic;
	tx_done					: out	std_logic;
	tx_statvec				: out	std_logic_vector(30 downto 0);
	---------------- Output signals from the Rx MAC FIFO I/F ---------------   
	rx_fifo_error			: out	std_logic;
	rx_stat_vector			: out	std_logic_vector(31 downto 0);
	rx_dbout				: out	std_logic_vector(7 downto 0);
	rx_write				: out	std_logic;
	rx_stat_en				: out	std_logic;
	rx_eof					: out	std_logic;
	rx_error				: out	std_logic
);
end component; 

component mb_mac_sim is
port (
	--------------------------------------------------------------------------
	--------------- clock, reset, clock enable -------------------------------
	HCLK				: in	std_logic;
	TX_MAC_CLK			: in	std_logic;
	RX_MAC_CLK			: in	std_logic;
	RESET_N				: in	std_logic;
	TXMAC_CLK_EN		: in	std_logic;
	RXMAC_CLK_EN		: in	std_logic;
	--------------------------------------------------------------------------
	--------------- SGMII receive interface ----------------------------------
	RXD					: in	std_logic_vector(7 downto 0);
	RX_DV				: in	std_logic;
	RX_ER				: in	std_logic;
	COL					: in	std_logic;
	CRS					: in	std_logic;
	--------------------------------------------------------------------------
	--------------- SGMII transmit interface ---------------------------------
	TXD					: out	std_logic_vector(7 downto 0);
	TX_EN				: out	std_logic;
	TX_ER				: out	std_logic;
	--------------------------------------------------------------------------
	--------------- CPU configuration interface ------------------------------
	HADDR				: in	std_logic_vector(7 downto 0);
	HDATAIN				: in	std_logic_vector(7 downto 0);
	HCS_N				: in	std_logic;
	HWRITE_N			: in	std_logic;
	HREAD_N				: in	std_logic;
	HDATAOUT			: out	std_logic_vector(7 downto 0);
	HDATAOUT_EN_N		: out	std_logic;
	HREADY_N			: out	std_logic;
	CPU_IF_GBIT_EN		: out	std_logic;
	--------------------------------------------------------------------------
	--------------- Transmit FIFO interface ----------------------------------
	TX_FIFODATA			: in	std_logic_vector(7 downto 0);
	TX_FIFOAVAIL		: in	std_logic;
	TX_FIFOEOF			: in	std_logic;
	TX_FIFOEMPTY		: in	std_logic;
	TX_MACREAD			: out	std_logic;
	TX_DONE				: out	std_logic;
	TX_SNDPAUSTIM		: in	std_logic_vector(15 downto 0);
	TX_SNDPAUSREQ		: in	std_logic;
	TX_FIFOCTRL			: in	std_logic;
	TX_DISCFRM			: out	std_logic;
	TX_STATEN			: out	std_logic;
	TX_STATVEC			: out	std_logic_vector(30 downto 0);
	--------------------------------------------------------------------------
	--------------- Receive FIFO interface -----------------------------------
	RX_DBOUT			: out	std_logic_vector(7 downto 0);
	RX_FIFO_FULL		: in	std_logic;
	IGNORE_PKT			: in	std_logic;	
	RX_FIFO_ERROR		: out	std_logic;
	RX_STAT_VECTOR		: out	std_logic_vector(31 downto 0);
	RX_STAT_EN			: out	std_logic;
	RX_WRITE			: out	std_logic;
	RX_EOF				: out	std_logic;
	RX_ERROR			: out	std_logic
);
end component;

component fifo_4096x9 is
port( 
	Data    : in    std_logic_vector(8 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(8 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

signal ig_bsm_save				: std_logic_vector(3 downto 0);
signal ig_bsm_load				: std_logic_vector(3 downto 0);
signal ig_cts_ctr				: std_logic_vector(2 downto 0);
signal ig_rem_ctr				: std_logic_vector(3 downto 0);
signal ig_debug					: std_logic_vector(31 downto 0);
signal ig_data					: std_logic_vector(15 downto 0);
signal ig_wcnt					: std_logic_vector(15 downto 0);
signal ig_rcnt					: std_logic_vector(16 downto 0);
signal ig_rd_en					: std_logic;
signal ig_wr_en					: std_logic;
signal ig_empty					: std_logic;
signal ig_aempty				: std_logic;
signal ig_full					: std_logic;
signal ig_afull					: std_logic;

signal pc_wr_en					: std_logic;
signal pc_data					: std_logic_vector(7 downto 0);
signal pc_eod					: std_logic;
signal pc_sos					: std_logic;
signal pc_ready					: std_logic;
signal pc_padding				: std_logic;
signal pc_decoding				: std_logic_vector(31 downto 0);
signal pc_event_id				: std_logic_vector(31 downto 0);
signal pc_queue_dec				: std_logic_vector(31 downto 0);
signal pc_max_frame_size        : std_logic_vector(15 downto 0);
signal pc_bsm_constr			: std_logic_vector(3 downto 0);
signal pc_bsm_load				: std_logic_vector(3 downto 0);
signal pc_bsm_save				: std_logic_vector(3 downto 0);
signal pc_shf_empty				: std_logic;
signal pc_shf_full				: std_logic;
signal pc_shf_wr_en				: std_logic;
signal pc_shf_rd_en				: std_logic;
signal pc_shf_q					: std_logic_vector(7 downto 0);
signal pc_df_empty				: std_logic;
signal pc_df_full				: std_logic;
signal pc_df_wr_en				: std_logic;
signal pc_df_rd_en				: std_logic;
signal pc_df_q					: std_logic_vector(7 downto 0);
signal pc_all_ctr				: std_logic_vector(4 downto 0);
signal pc_sub_ctr				: std_logic_vector(4 downto 0);
signal pc_bytes_loaded			: std_logic_vector(15 downto 0);
signal pc_size_left				: std_logic_vector(31 downto 0);
signal pc_sub_size_to_save		: std_logic_vector(31 downto 0);
signal pc_sub_size_loaded		: std_logic_vector(31 downto 0);
signal pc_sub_bytes_loaded		: std_logic_vector(31 downto 0);
signal pc_queue_size			: std_logic_vector(31 downto 0);
signal pc_act_queue_size		: std_logic_vector(31 downto 0);

signal fee_read					: std_logic;
signal cts_readout_finished		: std_logic;
signal cts_dataready			: std_logic;
signal cts_length				: std_logic_vector(15 downto 0);
signal cts_data					: std_logic_vector(31 downto 0); -- DHDR of rest packet
signal cts_error_pattern		: std_logic_vector(31 downto 0);

signal pc_sub_size				: std_logic_vector(31 downto 0);
signal pc_trig_nr				: std_logic_vector(31 downto 0);

signal tc_wr_en					: std_logic;
signal tc_data					: std_logic_vector(8 downto 0);
signal tc_ip_size				: std_logic_vector(15 downto 0);
signal tc_udp_size				: std_logic_vector(15 downto 0);
signal tc_ident					: std_logic_vector(15 downto 0);
signal tc_flags_offset				: std_logic_vector(15 downto 0);
signal tc_sod					: std_logic;
signal tc_eod					: std_logic;
signal tc_h_ready				: std_logic;
signal tc_ready					: std_logic;
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
signal fc_bsm_constr			: std_logic_vector(7 downto 0);
signal fc_bsm_trans				: std_logic_vector(3 downto 0);

signal ft_data					: std_logic_vector(8 downto 0);-- gk 04.05.10
signal ft_tx_empty				: std_logic;
signal ft_start_of_packet		: std_logic;
signal ft_bsm_init				: std_logic_vector(3 downto 0);
signal ft_bsm_mac				: std_logic_vector(3 downto 0);
signal ft_bsm_trans				: std_logic_vector(3 downto 0);

signal mac_haddr				: std_logic_vector(7 downto 0);
signal mac_hdataout				: std_logic_vector(7 downto 0);
signal mac_hcs					: std_logic;
signal mac_hwrite				: std_logic;
signal mac_hread				: std_logic;
signal mac_fifoavail			: std_logic;
signal mac_fifoempty			: std_logic;
signal mac_fifoeof				: std_logic;
signal mac_hready				: std_logic;
signal mac_hdata_en				: std_logic;
signal mac_tx_done				: std_logic;
signal mac_tx_read				: std_logic;

signal serdes_clk_125			: std_logic;
signal mac_tx_clk_en			: std_logic;
signal mac_rx_clk_en			: std_logic;
signal mac_col					: std_logic;
signal mac_crs					: std_logic;
signal pcs_txd					: std_logic_vector(7 downto 0);
signal pcs_tx_en				: std_logic;
signal pcs_tx_er				: std_logic;
signal pcs_an_lp_ability		: std_logic_vector(15 downto 0);
signal pcs_an_complete			: std_logic;
signal pcs_an_page_rx			: std_logic;

signal pcs_stat_debug			: std_logic_vector(63 downto 0); 

signal stage_stat_regs			: std_logic_vector(31 downto 0);
signal stage_ctrl_regs			: std_logic_vector(31 downto 0);

signal analyzer_debug			: std_logic_vector(63 downto 0);

signal ip_cfg_start			: std_logic;
signal ip_cfg_bank			: std_logic_vector(3 downto 0);
signal ip_cfg_done			: std_logic;

signal ip_cfg_mem_addr			: std_logic_vector(7 downto 0);
signal ip_cfg_mem_data			: std_logic_vector(31 downto 0);
signal ip_cfg_mem_clk			: std_logic;

-- gk 22.04.10
signal max_packet                    : std_logic_vector(31 downto 0);
signal min_packet                    : std_logic_vector(31 downto 0);
signal use_gbe                       : std_logic;
signal use_trbnet                    : std_logic;
signal use_multievents               : std_logic;
-- gk 26.04.10
signal readout_ctr                   : std_logic_vector(23 downto 0);
signal readout_ctr_valid             : std_logic;
signal gbe_trig_nr                   : std_logic_vector(31 downto 0);
-- gk 28.04.10
signal pc_delay                      : std_logic_vector(31 downto 0);
-- gk 04.05.10
signal ft_eod                        : std_logic;
-- gk 01.06.10
signal dbg_ipu2gbe1                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe2                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe3                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe4                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe5                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe6                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe7                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe8                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe9                  : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe10                 : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe11                 : std_logic_vector(31 downto 0);
signal dbg_ipu2gbe12                 : std_logic_vector(31 downto 0);
signal dbg_pc1                       : std_logic_vector(31 downto 0);
signal dbg_pc2                       : std_logic_vector(31 downto 0);
signal dbg_fc1                       : std_logic_vector(31 downto 0);
signal dbg_fc2                       : std_logic_vector(31 downto 0);
signal dbg_ft1                       : std_logic_vector(31 downto 0);
-- gk 08.06.10
signal mac_tx_staten                 : std_logic;
signal mac_tx_statevec               : std_logic_vector(30 downto 0);
signal mac_tx_discfrm                : std_logic;

signal dbg_rd_en                     : std_logic;
signal dbg_q                         : std_logic_vector(15 downto 0);

-- gk 21.07.10
signal allow_large                   : std_logic;

-- gk 28.07.10
signal bytes_sent_ctr                : std_logic_vector(31 downto 0);
signal monitor_sent                  : std_logic_vector(31 downto 0);
signal monitor_dropped               : std_logic_vector(31 downto 0);
signal monitor_sm                    : std_logic_vector(31 downto 0);
signal monitor_lr                    : std_logic_vector(31 downto 0);
signal monitor_hr                    : std_logic_vector(31 downto 0);
signal monitor_fifos                 : std_logic_vector(31 downto 0);
signal monitor_fifos_q               : std_logic_vector(31 downto 0);
signal monitor_discfrm               : std_logic_vector(31 downto 0);

-- gk 02.08.10
signal discfrm_ctr                   : std_logic_vector(31 downto 0);

-- gk 28.09.10
signal dbg_reset_fifo                : std_logic;

-- gk 30.09.10
signal fc_rd_en                      : std_logic;
signal link_ok                       : std_logic;
signal link_ok_timeout_ctr           : std_logic_vector(15 downto 0);

type linkStates     is  (ACTIVE, INACTIVE, TIMEOUT, FINALIZE);
signal link_current_state, link_next_state : linkStates;

signal link_down_ctr                 : std_logic_vector(15 downto 0);
signal link_down_ctr_lock            : std_logic;

signal link_state                    : std_logic_vector(3 downto 0);

signal monitor_empty                 : std_logic_vector(31 downto 0);

-- gk 07.10.10
signal pc_eos                        : std_logic;

-- gk 09.12.10
signal frame_delay                   : std_logic_vector(31 downto 0);

-- gk 13.02.11
signal pcs_rxd                       : std_logic_vector(7 downto 0);
signal pcs_rx_en                     : std_logic;
signal pcs_rx_er                     : std_logic;
signal mac_rx_eof                    : std_logic;
signal mac_rx_er                     : std_logic;
signal mac_rxd                       : std_logic_vector(7 downto 0);
signal mac_rx_fifo_err               : std_logic;
signal mac_rx_fifo_full              : std_logic;
signal mac_rx_en                     : std_logic;
signal mac_rx_stat_en                : std_logic;
signal mac_rx_stat_vec               : std_logic_vector(31 downto 0);
signal fr_q                          : std_logic_vector(8 downto 0);
signal fr_rd_en                      : std_logic;
signal fr_frame_valid                : std_logic;
signal rc_rd_en                      : std_logic;
signal rc_q                          : std_logic_vector(8 downto 0);
signal rc_frames_rec_ctr             : std_logic_vector(31 downto 0);
signal tc_pc_ready                   : std_logic;
signal tc_pc_h_ready                 : std_logic;
signal mc_ctrl_frame_req             : std_logic;
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
signal allow_rx                      : std_logic;
signal fr_frame_size                 : std_logic_vector(15 downto 0);
signal rc_frame_size                 : std_logic_vector(15 downto 0);
signal mc_frame_size                 : std_logic_vector(15 downto 0);
signal ic_dest_mac			: std_logic_vector(47 downto 0);
signal ic_dest_ip			: std_logic_vector(31 downto 0);
signal ic_dest_udp			: std_logic_vector(15 downto 0);
signal ic_src_mac			: std_logic_vector(47 downto 0);
signal ic_src_ip			: std_logic_vector(31 downto 0);
signal ic_src_udp			: std_logic_vector(15 downto 0);
signal pc_transmit_on			: std_logic;
signal rc_bytes_rec                  : std_logic_vector(31 downto 0);
signal rc_debug                      : std_logic_vector(63 downto 0);
signal mc_busy                       : std_logic;
signal tsmac_gbit_en                 : std_logic;
signal mc_transmit_ctrl              : std_logic;
signal mc_transmit_data              : std_logic;
signal rc_loading_done               : std_logic;
signal fr_get_frame                  : std_logic;
signal mc_transmit_done              : std_logic;

signal dbg_fr                        : std_logic_vector(95 downto 0);
signal dbg_rc                        : std_logic_vector(63 downto 0);
signal dbg_mc                        : std_logic_vector(63 downto 0);
signal dbg_tc                        : std_logic_vector(63 downto 0);

signal fr_allowed_types              : std_logic_vector(31 downto 0);
signal fr_allowed_ip                 : std_logic_vector(31 downto 0);
signal fr_allowed_udp                : std_logic_vector(31 downto 0);

signal fr_frame_proto                : std_logic_vector(15 downto 0);
signal rc_frame_proto                : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

signal dbg_select_rec                : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal dbg_select_sent               : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal dbg_select_protos             : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
signal serdes_rx_clk                 : std_logic;

signal vlan_id                       : std_logic_vector(31 downto 0);
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

signal dbg_ft                        : std_logic_vector(63 downto 0);

signal fr_ip_proto                   : std_logic_vector(7 downto 0);
signal mc_ip_proto                   : std_logic_vector(7 downto 0);

attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of pcs_rxd, pcs_txd, pcs_rx_en, pcs_tx_en, pcs_rx_er, pcs_tx_er : signal is true;
attribute syn_preserve of pcs_rxd, pcs_txd, pcs_rx_en, pcs_tx_en, pcs_rx_er, pcs_tx_er : signal is true;

signal pcs_txd_q, pcs_rxd_q : std_logic_vector(7 downto 0);
signal pcs_tx_en_q, pcs_tx_er_q, pcs_rx_en_q, pcs_rx_er_q, mac_col_q, mac_crs_q : std_logic;

signal pcs_txd_qq, pcs_rxd_qq : std_logic_vector(7 downto 0);
signal pcs_tx_en_qq, pcs_tx_er_qq, pcs_rx_en_qq, pcs_rx_er_qq, mac_col_qq, mac_crs_qq : std_logic;

signal mc_ip_size, mc_udp_size, mc_flags : std_logic_vector(15 downto 0);

signal timeout_ctr : std_logic_vector(31 downto 0);
signal timeout_noticed : std_Logic;
attribute syn_keep of timeout_noticed : signal is true;
attribute syn_preserve of timeout_noticed : signal is true;

signal dummy_size : std_logic_vector(15 downto 0);
signal dummy_pause : std_logic_vector(31 downto 0);

signal make_reset    : std_logic;
signal idle_too_long : std_logic;

signal tc_data_not_valid : std_logic;

signal mc_fc_h_ready, mc_fc_ready, mc_fc_wr_en : std_logic;
signal mc_ident : std_logic_vector(15 downto 0);

component test_data_source is
port (
	CLK			            : in	std_logic;
	RESET			        : in	std_logic;

	TC_DATAREADY_OUT        : out 	std_logic;
	TC_RD_EN_IN		        : in	std_logic;
	TC_DATA_OUT		        : out	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_OUT	    : out	std_logic_vector(15 downto 0);
	TC_SIZE_LEFT_OUT        : out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	    : out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	    : out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		    : out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		    : out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		    : out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		    : out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		    : out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		    : out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	    : out	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_IN : in	std_logic;
	TC_IDENT_OUT            : out	std_logic_vector(15 downto 0)
);
end component;

component trb_net16_gbe_transmit_control2 is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	TC_DATAREADY_IN        : in 	std_logic;
	TC_RD_EN_OUT		        : out	std_logic;
	TC_DATA_IN		        : in	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	TC_SIZE_LEFT_IN        : in	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_IN	    : in	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);

-- signal to/from frame constructor
	FC_DATA_OUT		     : out	std_logic_vector(7 downto 0);
	FC_WR_EN_OUT		 : out	std_logic;
	FC_READY_IN		     : in	std_logic;
	FC_H_READY_IN		 : in	std_logic;
	FC_FRAME_TYPE_OUT	 : out	std_logic_vector(15 downto 0);
	FC_IP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_UDP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_IDENT_OUT		 : out	std_logic_vector(15 downto 0);  -- internal packet counter
	FC_FLAGS_OFFSET_OUT	 : out	std_logic_vector(15 downto 0);
	FC_SOD_OUT		     : out	std_logic;
	FC_EOD_OUT		     : out	std_logic;
	FC_IP_PROTOCOL_OUT	 : out	std_logic_vector(7 downto 0);

	DEST_MAC_ADDRESS_OUT : out    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_OUT  : out    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_OUT    : out    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_OUT  : out    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_OUT   : out    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_OUT     : out    std_logic_vector(15 downto 0);

-- debug
	DEBUG_OUT		     : out	std_logic_vector(63 downto 0)
);
end component;
signal tc_src_mac                : std_logic_vector(47 downto 0);
signal tc_dest_mac               : std_logic_vector(47 downto 0);
signal tc_src_ip                 : std_logic_vector(31 downto 0);
signal tc_dest_ip                : std_logic_vector(31 downto 0);
signal tc_src_udp                : std_logic_vector(15 downto 0);
signal tc_dest_udp               : std_logic_vector(15 downto 0);
signal tc_dataready, tc_rd_en, tc_done : std_logic;
signal tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_frame_size, tc_size_left, tc_frame_type, tc_flags : std_logic_vector(15 downto 0);

begin

stage_ctrl_regs <= STAGE_CTRL_REGS_IN;

-- gk 23.04.10
LED_PACKET_SENT_OUT <= timeout_noticed; --pc_ready;
LED_AN_DONE_N_OUT   <= not link_ok; --not pcs_an_complete;

fc_ihl_version      <= x"45";
fc_tos              <= x"10";
fc_ttl              <= x"ff";


MAIN_CONTROL : trb_net16_gbe_main_control
  port map(
	  CLK			=> CLK,
	  CLK_125		=> serdes_clk_125,
	  RESET			=> RESET,

	  MC_LINK_OK_OUT	=> link_ok,
	  MC_RESET_LINK_IN	=> MR_RESTART_IN,
	  MC_IDLE_TOO_LONG_OUT => idle_too_long,

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
	  TC_TRANSMIT_CTRL_OUT	=> tc_dataready,
	  TC_DATA_OUT		=> tc_data,
	  TC_RD_EN_IN		=> tc_rd_en,
	  --TC_DATA_NOT_VALID_OUT => tc_data_not_valid,
	  TC_FRAME_SIZE_OUT	=> tc_frame_size,
	  TC_SIZE_LEFT_OUT  => tc_size_left,
	  TC_FRAME_TYPE_OUT	=> tc_frame_type,
	  TC_IP_PROTOCOL_OUT	=> tc_ip_proto,
	  TC_IDENT_OUT          => tc_ident,
	  
	  TC_DEST_MAC_OUT	=> tc_dest_mac,
	  TC_DEST_IP_OUT	=> tc_dest_ip,
	  TC_DEST_UDP_OUT	=> tc_dest_udp,
	  TC_SRC_MAC_OUT	=> tc_src_mac,
	  TC_SRC_IP_OUT		=> tc_src_ip,
	  TC_SRC_UDP_OUT	=> tc_src_udp,
	  
	  --TC_IP_SIZE_OUT		=> mc_ip_size,
	  --TC_UDP_SIZE_OUT		=> mc_udp_size,
	  TC_FLAGS_OFFSET_OUT	=> tc_flags,
	  
--	  TC_FC_H_READY_IN => mc_fc_h_ready,
--	  TC_FC_READY_IN  => mc_fc_ready,
--	  TC_FC_WR_EN_OUT => mc_fc_wr_en,
--	  
--	  TC_BUSY_IN		=> mc_busy,
	  TC_TRANSMIT_DONE_IN   => tc_done,

  -- signals to/from sgmii/gbe pcs_an_complete
	  PCS_AN_COMPLETE_IN	=> pcs_an_complete,

  -- signals to/from hub
	  MC_UNIQUE_ID_IN	=> MC_UNIQUE_ID_IN,
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
	
	CFG_GBE_ENABLE_IN           => use_gbe,
	CFG_IPU_ENABLE_IN           => use_trbnet,
	CFG_MULT_ENABLE_IN          => use_multievents,

  -- signal to/from Host interface of TriSpeed MAC
	  TSM_HADDR_OUT		=> mac_haddr,
	  TSM_HDATA_OUT		=> mac_hdataout,
	  TSM_HCS_N_OUT		=> mac_hcs,
	  TSM_HWRITE_N_OUT	=> mac_hwrite,
	  TSM_HREAD_N_OUT	=> mac_hread,
	  TSM_HREADY_N_IN	=> mac_hready,
	  TSM_HDATA_EN_N_IN	=> mac_hdata_en,
	  TSM_RX_STAT_VEC_IN  => mac_rx_stat_vec,
	  TSM_RX_STAT_EN_IN   => mac_rx_stat_en,
	  
	  SELECT_REC_FRAMES_OUT		=> dbg_select_rec,
	  SELECT_SENT_FRAMES_OUT	=> dbg_select_sent,
	  SELECT_PROTOS_DEBUG_OUT	=> dbg_select_protos,

	  DEBUG_OUT		=> dbg_mc
  );
  
  MAKE_RESET_OUT <= '0'; -- make_reset or idle_too_long;


--data_src : test_data_source
--port map(
--	CLK			            => clk,
--	RESET			        => reset,
--
--	TC_DATAREADY_OUT        => tc_dataready,
--	TC_RD_EN_IN		        => tc_rd_en,
--	TC_DATA_OUT		        => tc_data,
--	TC_FRAME_SIZE_OUT	    => tc_frame_size,
--	TC_SIZE_LEFT_OUT        => tc_size_left,
--	TC_FRAME_TYPE_OUT	    => tc_frame_type,
--	TC_IP_PROTOCOL_OUT	    => tc_ip_proto,	
--	TC_DEST_MAC_OUT		    => tc_dest_mac,
--	TC_DEST_IP_OUT		    => tc_dest_ip,
--	TC_DEST_UDP_OUT		    => tc_dest_udp,
--	TC_SRC_MAC_OUT		    => tc_src_mac,
--	TC_SRC_IP_OUT		    => tc_src_ip,
--	TC_SRC_UDP_OUT		    => tc_src_udp,
--	TC_FLAGS_OFFSET_OUT	    => tc_flags,
--	TC_TRANSMISSION_DONE_IN => tc_done,
--	TC_IDENT_OUT            => tc_ident
--);

transmit_controller : trb_net16_gbe_transmit_control2
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	TC_DATAREADY_IN        => tc_dataready,
	TC_RD_EN_OUT		        => tc_rd_en,
	TC_DATA_IN		        => tc_data(7 downto 0),
	TC_FRAME_SIZE_IN	    => tc_frame_size,
	TC_SIZE_LEFT_IN        => tc_size_left,
	TC_FRAME_TYPE_IN	    => tc_frame_type,
	TC_IP_PROTOCOL_IN	    => tc_ip_proto,	
	TC_DEST_MAC_IN		    => tc_dest_mac,
	TC_DEST_IP_IN		    => tc_dest_ip,
	TC_DEST_UDP_IN		    => tc_dest_udp,
	TC_SRC_MAC_IN		    => tc_src_mac,
	TC_SRC_IP_IN		    => tc_src_ip,
	TC_SRC_UDP_IN		    => tc_src_udp,
	TC_FLAGS_OFFSET_IN	    => tc_flags,
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
	FC_FLAGS_OFFSET_OUT	=> fc_flags_offset,
	FC_SOD_OUT		=> fc_sod,
	FC_EOD_OUT		=> fc_eod,
	FC_IP_PROTOCOL_OUT	=> fc_protocol,

	DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
	DEST_IP_ADDRESS_OUT     => fc_dest_ip,
	DEST_UDP_PORT_OUT       => fc_dest_udp,
	SRC_MAC_ADDRESS_OUT     => fc_src_mac,
	SRC_IP_ADDRESS_OUT      => fc_src_ip,
	SRC_UDP_PORT_OUT        => fc_src_udp,

	DEBUG_OUT		=> open
);


setup_imp_gen : if (DO_SIMULATION = 0) generate
-- gk 22.04.10 new entity to set values via slow control
SETUP : gbe_setup
port map(
	CLK                       => CLK,
	RESET                     => RESET,

	-- gk 26.04.10
	-- interface to regio bus
	BUS_ADDR_IN               => BUS_ADDR_IN,
	BUS_DATA_IN               => BUS_DATA_IN,
	BUS_DATA_OUT              => BUS_DATA_OUT,
	BUS_WRITE_EN_IN           => BUS_WRITE_EN_IN,
	BUS_READ_EN_IN            => BUS_READ_EN_IN,
	BUS_ACK_OUT               => BUS_ACK_OUT,

	GBE_TRIG_NR_IN            => pc_trig_nr, -- gk 26.04.10

	-- output to gbe_buf
	GBE_SUBEVENT_ID_OUT       => pc_event_id,
	GBE_SUBEVENT_DEC_OUT      => pc_decoding,
	GBE_QUEUE_DEC_OUT         => pc_queue_dec,
	GBE_MAX_PACKET_OUT        => max_packet,
	GBE_MIN_PACKET_OUT        => min_packet,  -- gk 20.07.10
	GBE_MAX_FRAME_OUT         => pc_max_frame_size,
	GBE_USE_GBE_OUT           => use_gbe,
	GBE_USE_TRBNET_OUT        => use_trbnet,
	GBE_USE_MULTIEVENTS_OUT   => use_multievents,
	GBE_READOUT_CTR_OUT       => readout_ctr,  -- gk 26.04.10
	GBE_READOUT_CTR_VALID_OUT => readout_ctr_valid,  -- gk 26.04.10
	GBE_DELAY_OUT             => pc_delay,
	GBE_ALLOW_LARGE_OUT       => allow_large,  -- gk 21.07.10
	GBE_ALLOW_RX_OUT          => allow_rx,
	GBE_ALLOW_BRDCST_ETH_OUT  => open,
	GBE_ALLOW_BRDCST_IP_OUT   => open,
	GBE_FRAME_DELAY_OUT       => frame_delay, -- gk 09.12.10
	GBE_ALLOWED_TYPES_OUT     => fr_allowed_types,
	GBE_ALLOWED_IP_OUT	  => fr_allowed_ip,
	GBE_ALLOWED_UDP_OUT	  => fr_allowed_udp,
	GBE_VLAN_ID_OUT	          => vlan_id,
	-- gk 28.07.10
	MONITOR_BYTES_IN          => bytes_sent_ctr,
	MONITOR_SENT_IN           => monitor_sent,
	MONITOR_DROPPED_IN        => monitor_dropped,
	MONITOR_SM_IN             => monitor_sm,
	MONITOR_LR_IN             => monitor_lr,
	MONITOR_HDR_IN            => monitor_hr,
	MONITOR_FIFOS_IN          => monitor_fifos_q,
	MONITOR_DISCFRM_IN        => monitor_discfrm,
	MONITOR_EMPTY_IN          => monitor_empty,
	MONITOR_LINK_DWN_IN(15 downto 0)  => link_down_ctr,  -- gk 30.09.10
	MONITOR_LINK_DWN_IN(19 downto 16) => link_state,
	MONITOR_LINK_DWN_IN(23 downto 20) => ft_bsm_trans,
	MONITOR_LINK_DWN_IN(27 downto 24) => fc_bsm_trans,
	MONITOR_LINK_DWN_IN(31 downto 28) => (others => '0'),
	MONITOR_RX_FRAMES_IN      => rc_frames_rec_ctr,
	MONITOR_RX_BYTES_IN       => rc_bytes_rec,
	MONITOR_RX_BYTES_R_IN     => rc_debug(31 downto 0),
	-- gk 01.06.10
	DBG_IPU2GBE1_IN           => dbg_ipu2gbe1,
	DBG_IPU2GBE2_IN           => dbg_ipu2gbe2,
	DBG_IPU2GBE3_IN           => dbg_ipu2gbe3,
	DBG_IPU2GBE4_IN           => dbg_ipu2gbe4,
	DBG_IPU2GBE5_IN           => dbg_ipu2gbe5,
	DBG_IPU2GBE6_IN           => dbg_ipu2gbe6,
	DBG_IPU2GBE7_IN           => dbg_ipu2gbe7,
	DBG_IPU2GBE8_IN           => dbg_ipu2gbe8,
	DBG_IPU2GBE9_IN           => dbg_ipu2gbe9,
	DBG_IPU2GBE10_IN          => dbg_ipu2gbe10,
	DBG_IPU2GBE11_IN          => dbg_ipu2gbe11,
	DBG_IPU2GBE12_IN          => dbg_ipu2gbe12,
	DBG_PC1_IN                => dbg_pc1,
	DBG_PC2_IN                => dbg_pc2,
	DBG_FC1_IN                => dbg_fc1,
	DBG_FC2_IN                => dbg_fc2,
	DBG_FT1_IN                => dbg_ft1,
	DBG_FT2_IN                => dbg_ft(31 downto 0),
	DBG_FR_IN                 => dbg_fr(63 downto 0),
	DBG_RC_IN                 => dbg_rc,
	DBG_MC_IN                 => dbg_mc,
	DBG_TC_IN                 => dbg_tc(31 downto 0),
	DBG_FIFO_RD_EN_OUT        => dbg_rd_en,
	
	DBG_SELECT_REC_IN	=> dbg_select_rec,
	DBG_SELECT_SENT_IN	=> dbg_select_sent,
	DBG_SELECT_PROTOS_IN	=> dbg_select_protos,
	
	SCTRL_DUMMY_SIZE_OUT      => dummy_size,
	SCTRL_DUMMY_PAUSE_OUT     => dummy_pause,
	
	DBG_FIFO_Q_IN             => dbg_q
	
	--DBG_FIFO_RESET_OUT        => dbg_reset_fifo  -- gk 28.09.10
);
end generate;

setup_sim_gen : if (DO_SIMULATION = 1) generate
-- gk 22.04.10 new entity to set values via slow control
SETUP : gbe_setup
port map(
	CLK                       => CLK,
	RESET                     => RESET,

	-- gk 26.04.10
	-- interface to regio bus
	BUS_ADDR_IN               => BUS_ADDR_IN,
	BUS_DATA_IN               => BUS_DATA_IN,
	BUS_DATA_OUT              => BUS_DATA_OUT,
	BUS_WRITE_EN_IN           => BUS_WRITE_EN_IN,
	BUS_READ_EN_IN            => BUS_READ_EN_IN,
	BUS_ACK_OUT               => BUS_ACK_OUT,

	GBE_TRIG_NR_IN            => pc_trig_nr, -- gk 26.04.10

	-- output to gbe_buf
	GBE_SUBEVENT_ID_OUT       => pc_event_id,
	GBE_SUBEVENT_DEC_OUT      => pc_decoding,
	GBE_QUEUE_DEC_OUT         => pc_queue_dec,
	GBE_MAX_PACKET_OUT        => max_packet,
	GBE_MIN_PACKET_OUT        => min_packet,  -- gk 20.07.10
	GBE_MAX_FRAME_OUT         => pc_max_frame_size,
	GBE_USE_GBE_OUT           => open, --use_gbe,
	GBE_USE_TRBNET_OUT        => use_trbnet,
	GBE_USE_MULTIEVENTS_OUT   => use_multievents,
	GBE_READOUT_CTR_OUT       => readout_ctr,  -- gk 26.04.10
	GBE_READOUT_CTR_VALID_OUT => readout_ctr_valid,  -- gk 26.04.10
	GBE_DELAY_OUT             => pc_delay,
	GBE_ALLOW_LARGE_OUT       => open,
	GBE_ALLOW_RX_OUT          => open,
	GBE_ALLOW_BRDCST_ETH_OUT  => open,
	GBE_ALLOW_BRDCST_IP_OUT   => open,
	GBE_FRAME_DELAY_OUT       => frame_delay, -- gk 09.12.10
	GBE_ALLOWED_TYPES_OUT     => fr_allowed_types,
	GBE_ALLOWED_IP_OUT	  => fr_allowed_ip,
	GBE_ALLOWED_UDP_OUT	  => fr_allowed_udp,
	GBE_VLAN_ID_OUT	          => vlan_id,
	-- gk 28.07.10
	MONITOR_BYTES_IN          => bytes_sent_ctr,
	MONITOR_SENT_IN           => monitor_sent,
	MONITOR_DROPPED_IN        => monitor_dropped,
	MONITOR_SM_IN             => monitor_sm,
	MONITOR_LR_IN             => monitor_lr,
	MONITOR_HDR_IN            => monitor_hr,
	MONITOR_FIFOS_IN          => monitor_fifos_q,
	MONITOR_DISCFRM_IN        => monitor_discfrm,
	MONITOR_EMPTY_IN          => monitor_empty,
	MONITOR_LINK_DWN_IN(15 downto 0)  => link_down_ctr,  -- gk 30.09.10
	MONITOR_LINK_DWN_IN(19 downto 16) => link_state,
	MONITOR_LINK_DWN_IN(23 downto 20) => ft_bsm_trans,
	MONITOR_LINK_DWN_IN(27 downto 24) => fc_bsm_trans,
	MONITOR_LINK_DWN_IN(31 downto 28) => (others => '0'),
	MONITOR_RX_FRAMES_IN      => rc_frames_rec_ctr,
	MONITOR_RX_BYTES_IN       => rc_bytes_rec,
	MONITOR_RX_BYTES_R_IN     => rc_debug(31 downto 0),
	
	SCTRL_DUMMY_SIZE_OUT      => dummy_size,
	SCTRL_DUMMY_PAUSE_OUT     => dummy_pause,
	
	-- gk 01.06.10
	DBG_IPU2GBE1_IN           => dbg_ipu2gbe1,
	DBG_IPU2GBE2_IN           => dbg_ipu2gbe2,
	DBG_IPU2GBE3_IN           => dbg_ipu2gbe3,
	DBG_IPU2GBE4_IN           => dbg_ipu2gbe4,
	DBG_IPU2GBE5_IN           => dbg_ipu2gbe5,
	DBG_IPU2GBE6_IN           => dbg_ipu2gbe6,
	DBG_IPU2GBE7_IN           => dbg_ipu2gbe7,
	DBG_IPU2GBE8_IN           => dbg_ipu2gbe8,
	DBG_IPU2GBE9_IN           => dbg_ipu2gbe9,
	DBG_IPU2GBE10_IN          => dbg_ipu2gbe10,
	DBG_IPU2GBE11_IN          => dbg_ipu2gbe11,
	DBG_IPU2GBE12_IN          => dbg_ipu2gbe12,
	DBG_PC1_IN                => dbg_pc1,
	DBG_PC2_IN                => dbg_pc2,
	DBG_FC1_IN                => dbg_fc1,
	DBG_FC2_IN                => dbg_fc2,
	DBG_FT1_IN                => dbg_ft1,
	DBG_FT2_IN                => dbg_ft(31 downto 0),
	DBG_FR_IN                 => dbg_fr(63 downto 0),
	DBG_RC_IN                 => dbg_rc,
	DBG_MC_IN                 => dbg_mc,
	DBG_TC_IN                 => dbg_tc(31 downto 0),
	DBG_FIFO_RD_EN_OUT        => dbg_rd_en,
		
	DBG_SELECT_REC_IN	=> dbg_select_rec,
	DBG_SELECT_SENT_IN	=> dbg_select_sent,
	DBG_SELECT_PROTOS_IN	=> dbg_select_protos,
	
	DBG_FIFO_Q_IN             => dbg_q
	--DBG_FIFO_RESET_OUT        => dbg_reset_fifo  -- gk 28.09.10
);

use_gbe <= '1';

allow_rx <= '1';
allow_large <= '0';

end generate;


---- IP configurator: allows IP config to change for each event builder
--THE_IP_CONFIGURATOR: ip_configurator
--port map( 
--	CLK					=> CLK,
--	RESET					=> RESET,
--	-- configuration interface
--	START_CONFIG_IN				=> ip_cfg_start, --IP_CFG_START_IN, -- new  -- gk 7.03.10
--	BANK_SELECT_IN				=> ip_cfg_bank, --IP_CFG_BANK_SEL_IN, -- new  -- gk 27.03.10
--	CONFIG_DONE_OUT				=> ip_cfg_done, --IP_CFG_DONE_OUT, -- new  -- gk 27.03.10
--	MEM_ADDR_OUT				=> ip_cfg_mem_addr, --IP_CFG_MEM_ADDR_OUT, -- new  -- gk 27.03.10
--	MEM_DATA_IN				=> ip_cfg_mem_data, --IP_CFG_MEM_DATA_IN, -- new  -- gk 27.03.10
--	MEM_CLK_OUT				=> ip_cfg_mem_clk, --IP_CFG_MEM_CLK_OUT, -- new  -- gk 27.03.10
--	-- information for IP cores
--	DEST_MAC_OUT				=> ic_dest_mac,
--	DEST_IP_OUT				=> ic_dest_ip,
--	DEST_UDP_OUT				=> ic_dest_udp,
--	SRC_MAC_OUT				=> ic_src_mac,
--	SRC_IP_OUT				=> ic_src_ip,
--	SRC_UDP_OUT				=> ic_src_udp,
--	MTU_OUT					=> open, --pc_max_frame_size,  -- gk 22.04.10
--	-- Debug
--	DEBUG_OUT				=> open
--);
--
---- gk 27.03.01
--MB_IP_CONFIG: slv_mac_memory
--port map( 
--	CLK		=> CLK, -- clk_100,
--	RESET           => RESET, --reset_i,
--	BUSY_IN         => '0',
--	-- Slave bus
--	SLV_ADDR_IN     => SLV_ADDR_IN, --x"00", --mb_ip_mem_addr(7 downto 0),
--	SLV_READ_IN     => SLV_READ_IN, --'0', --mb_ip_mem_read,
--	SLV_WRITE_IN    => SLV_WRITE_IN, --mb_ip_mem_write,
--	SLV_BUSY_OUT    => SLV_BUSY_OUT,
--	SLV_ACK_OUT     => SLV_ACK_OUT, --mb_ip_mem_ack,
--	SLV_DATA_IN     => SLV_DATA_IN, --mb_ip_mem_data_wr,
--	SLV_DATA_OUT    => SLV_DATA_OUT, --mb_ip_mem_data_rd,
--	-- I/O to the backend
--	MEM_CLK_IN      => ip_cfg_mem_clk,
--	MEM_ADDR_IN     => ip_cfg_mem_addr,
--	MEM_DATA_OUT    => ip_cfg_mem_data,
--	-- Status lines
--	STAT            => open
--);

-- First stage: get data from IPU channel, buffer it and terminate the IPU transmission to CTS
--THE_IPU_INTERFACE: trb_net16_ipu2gbe
--port map( 
--	CLK					=> CLK,
--	RESET					=> RESET,
--	--Event information coming from CTS
--	CTS_NUMBER_IN				=> CTS_NUMBER_IN,
--	CTS_CODE_IN				=> CTS_CODE_IN,
--	CTS_INFORMATION_IN			=> CTS_INFORMATION_IN,
--	CTS_READOUT_TYPE_IN			=> CTS_READOUT_TYPE_IN,
--	CTS_START_READOUT_IN			=> CTS_START_READOUT_IN,
--	--Information sent to CTS
--	--status data, equipped with DHDR
--	CTS_DATA_OUT				=> cts_data,
--	CTS_DATAREADY_OUT			=> cts_dataready,
--	CTS_READOUT_FINISHED_OUT		=> cts_readout_finished,
--	CTS_READ_IN				=> CTS_READ_IN,
--	CTS_LENGTH_OUT				=> cts_length,
--	CTS_ERROR_PATTERN_OUT			=> cts_error_pattern,
--	-- Data from Frontends
--	FEE_DATA_IN				=> FEE_DATA_IN,
--	FEE_DATAREADY_IN			=> FEE_DATAREADY_IN,
--	FEE_READ_OUT				=> fee_read,
--	FEE_STATUS_BITS_IN			=> FEE_STATUS_BITS_IN,
--	FEE_BUSY_IN				=> FEE_BUSY_IN,
--	-- slow control interface
--	START_CONFIG_OUT			=> ip_cfg_start, --open, --: out	std_logic; -- reconfigure MACs/IPs/ports/packet size  -- gk 27.03.10
--	BANK_SELECT_OUT				=> ip_cfg_bank, --open, --: out	std_logic_vector(3 downto 0); -- configuration page address -- gk 27.03.10
--	CONFIG_DONE_IN				=> ip_cfg_done, --'1', --: in	std_logic; -- configuration finished -- gk 27.03.10
--	DATA_GBE_ENABLE_IN			=> use_gbe, --'1', --: in	std_logic; -- IPU data is forwarded to GbE  -- gk 22.04.10
--	DATA_IPU_ENABLE_IN			=> use_trbnet, --'0', --: in	std_logic; -- IPU data is forwarded to CTS / TRBnet -- gk 22.04.10
--	MULT_EVT_ENABLE_IN			=> use_multievents,
--	MAX_MESSAGE_SIZE_IN			=> max_packet, --x"0000_FDE8",  -- gk 08.04.10  -- temporarily fixed here, to be set by slow ctrl -- gk 22.04.10
--	MIN_MESSAGE_SIZE_IN			=> min_packet, -- gk 20.07.10
--	READOUT_CTR_IN				=> readout_ctr, -- gk 26.04.10
--	READOUT_CTR_VALID_IN			=> readout_ctr_valid, -- gk 26.04.10
--	ALLOW_LARGE_IN				=> allow_large, -- gk 21.07.10
--	SCTRL_DUMMY_SIZE_IN      => dummy_size,
--	SCTRL_DUMMY_PAUSE_IN     => dummy_pause,
--	-- PacketConstructor interface
--	PC_WR_EN_OUT				=> pc_wr_en,
--	PC_DATA_OUT				=> pc_data,
--	PC_READY_IN				=> pc_ready,
--	PC_SOS_OUT				=> pc_sos,
--	PC_EOS_OUT				=> pc_eos,  -- gk 07.10.10
--	PC_EOD_OUT				=> pc_eod,
--	PC_SUB_SIZE_OUT				=> pc_sub_size,
--	PC_TRIG_NR_OUT				=> pc_trig_nr,
--	PC_PADDING_OUT				=> pc_padding,
--	MONITOR_OUT(31 downto 0)                => monitor_sent,
--	MONITOR_OUT(63 downto 32)               => monitor_dropped,
--	MONITOR_OUT(95 downto 64)               => monitor_hr,
--	MONITOR_OUT(127 downto 96)              => monitor_sm,
--	MONITOR_OUT(159 downto 128)             => monitor_lr,
--	MONITOR_OUT(191 downto 160)             => monitor_fifos,
--	MONITOR_OUT(223 downto 192)             => monitor_empty,
--	DEBUG_OUT(31 downto 0)                  => dbg_ipu2gbe1,
--	DEBUG_OUT(63 downto 32)                 => dbg_ipu2gbe2,
--	DEBUG_OUT(95 downto 64)                 => dbg_ipu2gbe3,
--	DEBUG_OUT(127 downto 96)                => dbg_ipu2gbe4,
--	DEBUG_OUT(159 downto 128)               => dbg_ipu2gbe5,
--	DEBUG_OUT(191 downto 160)               => dbg_ipu2gbe6,
--	DEBUG_OUT(223 downto 192)               => dbg_ipu2gbe7,
--	DEBUG_OUT(255 downto 224)               => dbg_ipu2gbe8,
--	DEBUG_OUT(287 downto 256)               => dbg_ipu2gbe9,
--	DEBUG_OUT(319 downto 288)               => dbg_ipu2gbe10,
--	DEBUG_OUT(351 downto 320)               => dbg_ipu2gbe11,
--	DEBUG_OUT(383 downto 352)               => dbg_ipu2gbe12
--);

---- Second stage: Packet constructor
--PACKET_CONSTRUCTOR : trb_net16_gbe_packet_constr
--port map( 
--	-- ports for user logic
--	RESET				=> RESET,
--	CLK				=> CLK,
--	MULT_EVT_ENABLE_IN		=> use_multievents,  -- gk 06.10.10
--	PC_WR_EN_IN			=> pc_wr_en,
--	PC_DATA_IN			=> pc_data,
--	PC_READY_OUT			=> pc_ready,
--	PC_START_OF_SUB_IN		=> pc_sos, --CHANGED TO SLOW CONTROL PULSE
--	PC_END_OF_SUB_IN		=> pc_eos, -- gk 07.10.10
--	PC_END_OF_DATA_IN		=> pc_eod,
--	PC_TRANSMIT_ON_OUT		=> pc_transmit_on,
--	-- queue and subevent layer headers
--	PC_SUB_SIZE_IN			=> pc_sub_size,
--	PC_PADDING_IN			=> pc_padding, -- gk 29.03.10
--	PC_DECODING_IN			=> pc_decoding,
--	PC_EVENT_ID_IN			=> pc_event_id,
--	PC_TRIG_NR_IN			=> pc_trig_nr,
--	PC_QUEUE_DEC_IN			=> pc_queue_dec,
--	PC_MAX_FRAME_SIZE_IN            => pc_max_frame_size,
--	PC_DELAY_IN                     => pc_delay, -- gk 28.04.10
--	-- NEW PORTS
--	TC_WR_EN_OUT			=> tc_wr_en,
--	TC_DATA_OUT			=> tc_data,
--	TC_H_READY_IN			=> tc_pc_h_ready,
--	TC_READY_IN			=> tc_pc_ready,
--	TC_IP_SIZE_OUT			=> tc_ip_size,
--	TC_UDP_SIZE_OUT			=> tc_udp_size,
--	--FC_IDENT_OUT			=> fc_ident,
--	TC_FLAGS_OFFSET_OUT		=> tc_flags_offset,
--	TC_SOD_OUT			=> tc_sod,
--	TC_EOD_OUT			=> tc_eod,
--	DEBUG_OUT(31 downto 0)		=> dbg_pc1,
--	DEBUG_OUT(63 downto 32)         => dbg_pc2
--);

-- Third stage: Frame Constructor
FRAME_CONSTRUCTOR: trb_net16_gbe_frame_constr
port map( 
	-- ports for user logic
	RESET				=> RESET,
	CLK				=> CLK,
	LINK_OK_IN			=> link_ok, --pcs_an_complete,  -- gk 03.08.10  -- gk 30.09.10
	--
	WR_EN_IN			=> fc_wr_en,
	DATA_IN				=> fc_data,
	START_OF_DATA_IN		=> fc_sod,
	END_OF_DATA_IN			=> fc_eod,
	IP_F_SIZE_IN			=> fc_ip_size,
	UDP_P_SIZE_IN			=> fc_udp_size,
	HEADERS_READY_OUT		=> fc_h_ready,
	READY_OUT			=> fc_ready,
	DEST_MAC_ADDRESS_IN		=> fc_dest_mac,
	DEST_IP_ADDRESS_IN		=> fc_dest_ip,
	DEST_UDP_PORT_IN		=> fc_dest_udp,
	SRC_MAC_ADDRESS_IN		=> fc_src_mac,
	SRC_IP_ADDRESS_IN		=> fc_src_ip,
	SRC_UDP_PORT_IN			=> fc_src_udp,
	FRAME_TYPE_IN			=> fc_type,
	IHL_VERSION_IN			=> fc_ihl_version,
	TOS_IN				=> fc_tos,
	IDENTIFICATION_IN		=> fc_ident,
	FLAGS_OFFSET_IN			=> fc_flags_offset,
	TTL_IN				=> fc_ttl,
	PROTOCOL_IN			=> fc_protocol,
	FRAME_DELAY_IN			=> frame_delay, -- gk 09.12.10
	-- ports for packetTransmitter
	RD_CLK				=> serdes_clk_125,
	FT_DATA_OUT 			=> ft_data,
	--FT_EOD_OUT			=> ft_eod, -- gk 04.05.10
	FT_TX_EMPTY_OUT			=> ft_tx_empty,
	FT_TX_RD_EN_IN			=> mac_tx_read,
	FT_START_OF_PACKET_OUT		=> ft_start_of_packet,
	FT_TX_DONE_IN			=> mac_tx_done,
	FT_TX_DISCFRM_IN		=> mac_tx_discfrm,
	-- debug ports
	BSM_CONSTR_OUT			=> fc_bsm_constr,
	BSM_TRANS_OUT			=> fc_bsm_trans,
	DEBUG_OUT(31 downto 0)		=> dbg_fc1,
	DEBUG_OUT(63 downto 32)         => dbg_fc2
);


RECEIVE_CONTROLLER : trb_net16_gbe_receive_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signals to/from frame_receiver
	RC_DATA_IN		=> fr_q,
	FR_RD_EN_OUT		=> fr_rd_en,
	FR_FRAME_VALID_IN	=> fr_frame_valid,
	FR_GET_FRAME_OUT	=> fr_get_frame,
	FR_FRAME_SIZE_IN	=> fr_frame_size,
	FR_FRAME_PROTO_IN	=> fr_frame_proto,
	FR_IP_PROTOCOL_IN	=> fr_ip_proto,
	
	FR_SRC_MAC_ADDRESS_IN	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_IN  => fr_dest_mac,
	FR_SRC_IP_ADDRESS_IN	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_IN	=> fr_dest_ip,
	FR_SRC_UDP_PORT_IN	=> fr_src_udp,
	FR_DEST_UDP_PORT_IN	=> fr_dest_udp,

-- signals to/from main controller
	RC_RD_EN_IN		=> rc_rd_en,
	RC_Q_OUT		=> rc_q,
	RC_FRAME_WAITING_OUT	=> rc_frame_ready,
	RC_LOADING_DONE_IN	=> rc_loading_done,
	RC_FRAME_SIZE_OUT	=> rc_frame_size,
	RC_FRAME_PROTO_OUT	=> rc_frame_proto,
	
	RC_SRC_MAC_ADDRESS_OUT	=> rc_src_mac,
	RC_DEST_MAC_ADDRESS_OUT => rc_dest_mac,
	RC_SRC_IP_ADDRESS_OUT	=> rc_src_ip,
	RC_DEST_IP_ADDRESS_OUT	=> rc_dest_ip,
	RC_SRC_UDP_PORT_OUT	=> rc_src_udp,
	RC_DEST_UDP_PORT_OUT	=> rc_dest_udp,

-- statistics
	FRAMES_RECEIVED_OUT	=> rc_frames_rec_ctr,
	BYTES_RECEIVED_OUT      => rc_bytes_rec,


	DEBUG_OUT		=> rc_debug
);
dbg_q(15 downto 9) <= (others  => '0');

FRAME_TRANSMITTER: trb_net16_gbe_frame_trans
port map( 
	CLK				=> CLK,
	RESET				=> RESET,
	LINK_OK_IN			=> link_ok, --pcs_an_complete,  -- gk 03.08.10  -- gk 30.09.10
	TX_MAC_CLK			=> serdes_clk_125,
	TX_EMPTY_IN			=> ft_tx_empty,
	START_OF_PACKET_IN		=> ft_start_of_packet,
	DATA_ENDFLAG_IN			=> ft_data(8),  -- ft_eod -- gk 04.05.10
	
	TX_FIFOAVAIL_OUT		=> mac_fifoavail,
	TX_FIFOEOF_OUT			=> mac_fifoeof,
	TX_FIFOEMPTY_OUT		=> mac_fifoempty,
	TX_DONE_IN			=> mac_tx_done,	
	TX_STAT_EN_IN			=> mac_tx_staten,
	TX_STATVEC_IN			=> mac_tx_statevec,
	TX_DISCFRM_IN			=> mac_tx_discfrm,
	-- Debug
	BSM_INIT_OUT			=> ft_bsm_init,
	BSM_MAC_OUT			=> ft_bsm_mac,
	BSM_TRANS_OUT			=> ft_bsm_trans,
	DBG_RD_DONE_OUT			=> open,
	DBG_INIT_DONE_OUT		=> open,
	DBG_ENABLED_OUT			=> open,
	DEBUG_OUT			=> dbg_ft
	--DEBUG_OUT(31 downto 0)		=> open,
	--DEBUG_OUT(63 downto 32)		=> open
);  

  FRAME_RECEIVER : trb_net16_gbe_frame_receiver
  port map(
	  CLK			=> CLK,
	  RESET			=> RESET,
	  LINK_OK_IN		=> link_ok,
	  ALLOW_RX_IN		=> '1', --allow_rx,
	  RX_MAC_CLK		=> serdes_rx_clk, --serdes_clk_125,

  -- input signals from TS_MAC
	  MAC_RX_EOF_IN		=> mac_rx_eof,
	  MAC_RX_ER_IN		=> mac_rx_er,
	  MAC_RXD_IN		=> mac_rxd,
	  MAC_RX_EN_IN		=> mac_rx_en,
	  MAC_RX_FIFO_ERR_IN	=> mac_rx_fifo_err,
	  MAC_RX_FIFO_FULL_OUT	=> mac_rx_fifo_full,
	  MAC_RX_STAT_EN_IN	=> mac_rx_stat_en,
	  MAC_RX_STAT_VEC_IN	=> mac_rx_stat_vec,
  -- output signal to control logic
	  FR_Q_OUT		=> fr_q,
	  FR_RD_EN_IN		=> fr_rd_en,
	  FR_FRAME_VALID_OUT	=> fr_frame_valid,
	  FR_GET_FRAME_IN	=> fr_get_frame,
	  FR_FRAME_SIZE_OUT	=> fr_frame_size,
	  FR_FRAME_PROTO_OUT	=> fr_frame_proto,
	  FR_IP_PROTOCOL_OUT	=> fr_ip_proto,
	  FR_ALLOWED_TYPES_IN   => fr_allowed_types,
	  FR_ALLOWED_IP_IN      => fr_allowed_ip,
	  FR_ALLOWED_UDP_IN     => fr_allowed_udp,
	  FR_VLAN_ID_IN		=> vlan_id,
	
	FR_SRC_MAC_ADDRESS_OUT	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_OUT => fr_dest_mac,
	FR_SRC_IP_ADDRESS_OUT	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_OUT	=> fr_dest_ip,
	FR_SRC_UDP_PORT_OUT	=> fr_src_udp,
	FR_DEST_UDP_PORT_OUT	=> fr_dest_udp,

	  DEBUG_OUT		=> dbg_fr
  );


-- in case of real hardware, we use the IP cores for MAC and PHY, and also put a SerDes in
imp_gen: if (DO_SIMULATION = 0) generate
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	-- Implementation
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	
	
	TIMEOUT_CTR_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1' or mac_tx_done = '1') then
				timeout_ctr <= (others => '0');
			else
				timeout_ctr <= timeout_ctr + x"1";
			end if;
		end if;
	end process TIMEOUT_CTR_PROC;
	
	TIMEOUT_NOTICED_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') then
				timeout_noticed <= '0';
			elsif (timeout_ctr(30) = '1') then
				timeout_noticed <= '1';
			end if;	
		end if;
	end process TIMEOUT_NOTICED_PROC;
	
	
	-- MAC part
	MAC: tsmac36 --tsmac35
	port map(
	----------------- clock and reset port declarations ------------------
		hclk				=> CLK,
		txmac_clk			=> serdes_clk_125,
		rxmac_clk			=> serdes_rx_clk, --serdes_clk_125,
		reset_n				=> GSR_N,
		txmac_clk_en			=> mac_tx_clk_en,
		rxmac_clk_en			=> mac_rx_clk_en,
	------------------- Input signals to the GMII ----------------  NOT USED
		rxd				=> pcs_rxd_qq, --x"00",
		rx_dv 				=> pcs_rx_en_qq, --'0',
		rx_er				=> pcs_rx_er_qq, --'0',
		col				=> mac_col,
		crs				=> mac_crs,
	-------------------- Input signals to the CPU I/F -------------------
		haddr				=> mac_haddr,
		hdatain				=> mac_hdataout,
		hcs_n				=> mac_hcs,
		hwrite_n			=> mac_hwrite,
		hread_n				=> mac_hread,
	---------------- Input signals to the Tx MAC FIFO I/F ---------------
		tx_fifodata			=> ft_data(7 downto 0),
		tx_fifoavail			=> mac_fifoavail,
		tx_fifoeof			=> mac_fifoeof,
		tx_fifoempty			=> mac_fifoempty,
		tx_sndpaustim			=> x"0000",
		tx_sndpausreq			=> '0',
		tx_fifoctrl			=> '0',  -- always data frame
	---------------- Input signals to the Rx MAC FIFO I/F --------------- 
		rx_fifo_full			=> mac_rx_fifo_full, --'0',
		ignore_pkt			=> '0',
	---------------- Output signals from the GMII -----------------------
		txd				=> pcs_txd,
		tx_en				=> pcs_tx_en,
		tx_er				=> pcs_tx_er,
	----------------- Output signals from the CPU I/F -------------------
		hdataout			=> open,
		hdataout_en_n			=> mac_hdata_en,
		hready_n			=> mac_hready,
		cpu_if_gbit_en			=> tsmac_gbit_en,
	------------- Output signals from the Tx MAC FIFO I/F --------------- 
		tx_macread			=> mac_tx_read,
		tx_discfrm			=> mac_tx_discfrm,
		tx_staten			=> mac_tx_staten,  -- gk 08.06.10
		tx_statvec			=> mac_tx_statevec,  -- gk 08.06.10
		tx_done				=> mac_tx_done,
	------------- Output signals from the Rx MAC FIFO I/F ---------------   
		rx_fifo_error			=> mac_rx_fifo_err, --open,
		rx_stat_vector			=> mac_rx_stat_vec, --open,
		rx_dbout			=> mac_rxd, --open,
		rx_write			=> mac_rx_en, --open,
		rx_stat_en			=> mac_rx_stat_en, --open,
		rx_eof				=> mac_rx_eof, --open,
		rx_error			=> mac_rx_er --open
	);
	
	SYNC_GMII_RX_PROC : process(serdes_rx_clk)
	begin
		if rising_edge(serdes_rx_clk) then
			pcs_rxd_q   <= pcs_rxd;
			pcs_rx_en_q <= pcs_rx_en;
			pcs_rx_er_q <= pcs_rx_er;
			
			pcs_rxd_qq   <= pcs_rxd_q;
			pcs_rx_en_qq <= pcs_rx_en_q;
			pcs_rx_er_qq <= pcs_rx_er_q;
			--mac_col_q   <= mac_col;
			--mac_crs_q   <= mac_crs;
		end if;
	end process SYNC_GMII_RX_PROC;
	
	SYNC_GMII_TX_PROC : process(serdes_clk_125)
	begin
		if rising_edge(serdes_clk_125) then
			pcs_txd_q   <= pcs_txd;
			pcs_tx_en_q <= pcs_tx_en;
			pcs_tx_er_q <= pcs_tx_er;
			
			pcs_txd_qq   <= pcs_txd_q;
			pcs_tx_en_qq <= pcs_tx_en_q;
			pcs_tx_er_qq <= pcs_tx_er_q; 
		end if;
	end process SYNC_GMII_TX_PROC;

	-- gk 08.06.10
	dbg_statevec_proc : process(serdes_clk_125)
	begin
		if rising_edge(serdes_clk_125) then
			if (RESET = '1') then
				dbg_ft1              <= (others => '0');
			elsif (mac_tx_staten = '1') then
				dbg_ft1(30 downto 0) <= mac_tx_statevec;
				dbg_ft1(31)          <= mac_tx_discfrm;
			end if;
		end if;
	end process dbg_statevec_proc;

	serdes_intclk_gen: if (USE_125MHZ_EXTCLK = 0) generate
		-- PHY part
		PCS_SERDES : trb_net16_med_ecp_sfp_gbe_8b
		generic map(
			USE_125MHZ_EXTCLK		=> 0
		)
		port map(
			RESET				=> RESET,
			GSR_N				=> GSR_N,
			CLK_125_OUT			=> serdes_clk_125,
			CLK_125_RX_OUT			=> serdes_rx_clk, --open,
			CLK_125_IN			=> CLK_125_IN,
			FT_TX_CLK_EN_OUT		=> mac_tx_clk_en,
			FT_RX_CLK_EN_OUT		=> mac_rx_clk_en,
			--connection to frame transmitter (tsmac)
			FT_COL_OUT			=> mac_col,
			FT_CRS_OUT			=> mac_crs,
			FT_TXD_IN			=> pcs_txd_qq,
			FT_TX_EN_IN			=> pcs_tx_en_qq,
			FT_TX_ER_IN			=> pcs_tx_er_qq,
			FT_RXD_OUT			=> pcs_rxd,
			FT_RX_EN_OUT			=> pcs_rx_en,
			FT_RX_ER_OUT			=> pcs_rx_er,
			--SFP Connection
			SD_RXD_P_IN			=> SFP_RXD_P_IN,
			SD_RXD_N_IN			=> SFP_RXD_N_IN,
			SD_TXD_P_OUT			=> SFP_TXD_P_OUT,
			SD_TXD_N_OUT			=> SFP_TXD_N_OUT,
			SD_REFCLK_P_IN			=> SFP_REFCLK_P_IN,
			SD_REFCLK_N_IN			=> SFP_REFCLK_N_IN,
			SD_PRSNT_N_IN			=> SFP_PRSNT_N_IN,
			SD_LOS_IN			=> SFP_LOS_IN,
			SD_TXDIS_OUT			=> SFP_TXDIS_OUT,
			-- Autonegotiation stuff
			MR_ADV_ABILITY_IN		=> x"0020", -- full duplex only
			MR_AN_LP_ABILITY_OUT		=> pcs_an_lp_ability,
			MR_AN_PAGE_RX_OUT		=> pcs_an_page_rx,
			MR_AN_COMPLETE_OUT		=> pcs_an_complete,
			MR_RESET_IN			=> RESET,
			MR_MODE_IN			=> '0', --MR_MODE_IN,
			MR_AN_ENABLE_IN			=> '1', -- do autonegotiation
			MR_RESTART_AN_IN		=> '0', --MR_RESTART_IN,
			-- Status and control port
			STAT_OP				=> open,
			CTRL_OP				=> x"0000",
			STAT_DEBUG			=> pcs_stat_debug, --open,
			CTRL_DEBUG			=> x"0000_0000_0000_0000"
		);
	end generate serdes_intclk_gen;

	serdes_extclk_gen: if (USE_125MHZ_EXTCLK = 1) generate
		-- PHY part
		PCS_SERDES : trb_net16_med_ecp_sfp_gbe_8b
		generic map(
			USE_125MHZ_EXTCLK		=> 1
		)
		port map(
			RESET				=> RESET,
			GSR_N				=> GSR_N,
			CLK_125_OUT			=> serdes_clk_125,
			CLK_125_RX_OUT			=> serdes_rx_clk,
			CLK_125_IN			=> '0',  -- not used
			FT_TX_CLK_EN_OUT		=> mac_tx_clk_en,
			FT_RX_CLK_EN_OUT		=> mac_rx_clk_en,
			--connection to frame transmitter (tsmac)
			FT_COL_OUT			=> mac_col,
			FT_CRS_OUT			=> mac_crs,
			FT_TXD_IN			=> pcs_txd,
			FT_TX_EN_IN			=> pcs_tx_en,
			FT_TX_ER_IN			=> pcs_tx_er,
			FT_RXD_OUT			=> pcs_rxd,
			FT_RX_EN_OUT			=> pcs_rx_en,
			FT_RX_ER_OUT			=> pcs_rx_er,
			--SFP Connection
			SD_RXD_P_IN			=> SFP_RXD_P_IN,
			SD_RXD_N_IN			=> SFP_RXD_N_IN,
			SD_TXD_P_OUT			=> SFP_TXD_P_OUT,
			SD_TXD_N_OUT			=> SFP_TXD_N_OUT,
			SD_REFCLK_P_IN			=> SFP_REFCLK_P_IN,
			SD_REFCLK_N_IN			=> SFP_REFCLK_N_IN,
			SD_PRSNT_N_IN			=> SFP_PRSNT_N_IN,
			SD_LOS_IN			=> SFP_LOS_IN,
			SD_TXDIS_OUT			=> SFP_TXDIS_OUT,
			-- Autonegotiation stuff
			MR_ADV_ABILITY_IN		=> x"0020", -- full duplex only
			MR_AN_LP_ABILITY_OUT		=> pcs_an_lp_ability,
			MR_AN_PAGE_RX_OUT		=> pcs_an_page_rx,
			MR_AN_COMPLETE_OUT		=> pcs_an_complete,
			MR_RESET_IN			=> MR_RESET_IN,
			MR_MODE_IN			=> MR_MODE_IN,
			MR_AN_ENABLE_IN			=> '1', -- do autonegotiation
			MR_RESTART_AN_IN		=> MR_RESTART_IN,
			-- Status and control port
			STAT_OP				=> open,
			CTRL_OP				=> x"0000",
			STAT_DEBUG			=> pcs_stat_debug, --open,
			CTRL_DEBUG			=> x"0000_0000_0000_0000"
		);
	end generate serdes_extclk_gen;

	stage_stat_regs(31 downto 28) <= x"e";
	stage_stat_regs(27 downto 24) <= pcs_stat_debug(25 downto 22); -- link s-tatus 
	stage_stat_regs(23 downto 20) <= pcs_stat_debug(35 downto 32); -- reset bsm
	stage_stat_regs(19)           <= '0';
	stage_stat_regs(18)           <= link_ok;  -- gk 30.09.10
	stage_stat_regs(17)           <= pcs_an_complete;
	stage_stat_regs(16)           <= pcs_an_page_rx;
	stage_stat_regs(15 downto 0)  <= pcs_an_lp_ability;

end generate imp_gen;

-- in case of simulation we include a fake MAC and no PHY/SerDes.
sim_gen: if (DO_SIMULATION = 1) generate
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	-- Simulation
	--------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------
	MAC: mb_mac_sim
	port map( --------------------------------------------------------------------------
			  --------------- clock, reset, clock enable -------------------------------
			  HCLK					=> CLK,
			  TX_MAC_CLK			=> serdes_clk_125,
			  RX_MAC_CLK			=> serdes_rx_clk, --serdes_clk_125,
			  RESET_N				=> GSR_N,
			  TXMAC_CLK_EN			=> mac_tx_clk_en,
			  RXMAC_CLK_EN			=> mac_rx_clk_en,
			  --------------------------------------------------------------------------
			  --------------- SGMII receive interface ----------------------------------
			  RXD					=> x"00",
			  RX_DV					=> '0',
			  RX_ER					=> '0',
			  COL					=> mac_col,
			  CRS					=> mac_crs,
			  --------------------------------------------------------------------------
			  --------------- SGMII transmit interface ---------------------------------
			  TXD					=> pcs_txd,
			  TX_EN					=> pcs_tx_en,
			  TX_ER					=> pcs_tx_er,
			  --------------------------------------------------------------------------
			  --------------- CPU configuration interface ------------------------------
			  HADDR					=> mac_haddr,
			  HDATAIN				=> mac_hdataout,
			  HCS_N					=> mac_hcs,
			  HWRITE_N				=> mac_hwrite,
			  HREAD_N				=> mac_hread,
			  HDATAOUT				=> open,
			  HDATAOUT_EN_N			=> mac_hdata_en,
			  HREADY_N				=> mac_hready,
			  CPU_IF_GBIT_EN		=> open,
			  --------------------------------------------------------------------------
			  --------------- Transmit FIFO interface ----------------------------------
			  TX_FIFODATA			=> ft_data(7 downto 0),
			  TX_FIFOAVAIL			=> mac_fifoavail,
			  TX_FIFOEOF			=> mac_fifoeof,
			  TX_FIFOEMPTY			=> mac_fifoempty,
			  TX_MACREAD			=> mac_tx_read,
			  TX_DONE				=> mac_tx_done,
			  TX_SNDPAUSTIM			=> x"0000",
			  TX_SNDPAUSREQ			=> '0',
			  TX_FIFOCTRL			=> '0',
			  TX_DISCFRM			=> open,
			  TX_STATEN				=> open,
			  TX_STATVEC			=> open,
			  --------------------------------------------------------------------------
			  --------------- Receive FIFO interface -----------------------------------
			  RX_DBOUT				=> open,
			  RX_FIFO_FULL			=> '0',
			  IGNORE_PKT			=> '0',	
			  RX_FIFO_ERROR			=> open,
			  RX_STAT_VECTOR		=> open,
			  RX_STAT_EN			=> open,
			  RX_WRITE				=> open,
			  RX_EOF				=> open,
			  RX_ERROR				=> open
			);

	-- add external test clock for the MAC part
	serdes_clk_125 <= TEST_CLK;

	-- fake signals
	pcs_an_lp_ability <= x"4060";
	pcs_an_page_rx    <= '0';
	pcs_an_complete   <= '1';
	mac_tx_clk_en     <= '1';
	mac_rx_clk_en     <= '1';
	
	stage_stat_regs(31 downto 0)  <= (others => '0');

	pcs_stat_debug(63 downto 0)   <= (others => '0');

	SFP_TXD_P_OUT                 <= '1';
	SFP_TXD_N_OUT                 <= '0';
	SFP_TXDIS_OUT                 <= '0';
	

end generate sim_gen;


--***********************
--	MONITORING & DEBUG
--***********************


-- gk 04.08.10
MON_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		monitor_fifos_q(3 downto 0)           <= monitor_fifos(3 downto 0);
		if (dbg_pc1(28) = '1') then
			monitor_fifos_q(5 downto 4)   <= b"11";
		else 
			monitor_fifos_q(5 downto 4)   <= b"00";
		end if;
		if (dbg_pc1(30) = '1') then
			monitor_fifos_q(7 downto 6)   <= b"11";
		else 
			monitor_fifos_q(7 downto 6)   <= b"00";
		end if;
		if (dbg_fc1(28) = '1') then
			monitor_fifos_q(11 downto 8)  <= b"1111";
		else
			monitor_fifos_q(11 downto 8)  <= b"0000";
		end if;
		if (pcs_an_complete = '0') then
			monitor_fifos_q(15 downto 12) <= b"1111";
		else
			monitor_fifos_q(15 downto 12) <= b"0000";
		end if;
	end if;
end process MON_PROC;

-- gk 28.07.10
BYTES_SENT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			bytes_sent_ctr <= (others => '0');
		elsif (fc_wr_en = '1') then
			bytes_sent_ctr <= bytes_sent_ctr + x"1";
		end if;
	end if;
end process BYTES_SENT_CTR_PROC;

-- gk 02.08.10
DISCFRM_PROC : process(serdes_clk_125)
begin
	if rising_edge(serdes_clk_125) then
		if (RESET = '1') then
			discfrm_ctr <= (others => '0');
		elsif (mac_tx_discfrm = '1') then
			discfrm_ctr <= discfrm_ctr + x"1";
		end if;
	end if;
end process DISCFRM_PROC;

discfrm_sync : signal_sync
	generic map(
	  DEPTH => 2,
	  WIDTH => 32
	  )
	port map(
	  RESET    => RESET,
	  D_IN     => discfrm_ctr,
	  CLK0     => serdes_clk_125,
	  CLK1     => CLK,
	  D_OUT    => monitor_discfrm
	  );


------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

--***************
--	LOGIC ANALYZER SIGNALS
--***************
--ANALYZER_DEBUG_OUT <= dbg_mc or dbg_tc or (dbg_fc1 & dbg_fc2) or rc_debug or dbg_ft or dbg_fr(63 downto 0) or (dbg_fr(95 downto 64) & x"00000000");
--ANALYZER_DEBUG_OUT(3 downto 0) <= dbg_select_protos(99 downto 96);
--ANALYZER_DEBUG_OUT(63 downto 4) <= (others => '0');

-- Outputs
--FEE_READ_OUT             <= fee_read;

CTS_READOUT_FINISHED_OUT <= cts_readout_finished;
CTS_DATAREADY_OUT        <= cts_dataready;
CTS_DATA_OUT             <= cts_data;
CTS_LENGTH_OUT           <= cts_length;
CTS_ERROR_PATTERN_OUT    <= cts_error_pattern;

STAGE_STAT_REGS_OUT      <= stage_stat_regs;


end architecture;
