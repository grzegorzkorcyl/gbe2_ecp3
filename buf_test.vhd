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
signal tc_data					: std_logic_vector(7 downto 0);
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

signal fc_flags                  : std_logic_vector(15 downto 0);
signal fc_proto                  : std_logic_vector(7 downto 0);
signal tc_src_mac                : std_logic_vector(47 downto 0);
signal tc_dest_mac               : std_logic_vector(47 downto 0);
signal tc_src_ip                 : std_logic_vector(31 downto 0);
signal tc_dest_ip                : std_logic_vector(31 downto 0);
signal tc_src_udp                : std_logic_vector(15 downto 0);
signal tc_dest_udp               : std_logic_vector(15 downto 0);
signal tc_dataready, tc_rd_en, tc_done : std_logic;
signal tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_frame_size, tc_size_left, tc_frame_type, tc_flags  : std_logic_vector(15 downto 0);
begin

stage_ctrl_regs <= STAGE_CTRL_REGS_IN;

-- gk 23.04.10
LED_PACKET_SENT_OUT <= timeout_noticed; --pc_ready;
LED_AN_DONE_N_OUT   <= not link_ok; --not pcs_an_complete;

fc_ihl_version      <= x"45";
fc_tos              <= x"10";
fc_ttl              <= x"ff";


data_src : test_data_source
port map(
	CLK			            => CLK,
	RESET			        => RESET,

	TC_DATAREADY_OUT        => tc_dataready,
	TC_RD_EN_IN		        => tc_rd_en,
	TC_DATA_OUT		        => tc_data,
	TC_FRAME_SIZE_OUT	    => tc_frame_size,
	TC_SIZE_LEFT_OUT        => tc_size_left,
	TC_FRAME_TYPE_OUT	    => tc_frame_type,
	TC_IP_PROTOCOL_OUT	    => tc_ip_proto,	
	TC_DEST_MAC_OUT		    => tc_dest_mac,
	TC_DEST_IP_OUT		    => tc_dest_ip,
	TC_DEST_UDP_OUT		    => tc_dest_udp,
	TC_SRC_MAC_OUT		    => tc_src_mac,
	TC_SRC_IP_OUT		    => tc_src_ip,
	TC_SRC_UDP_OUT		    => tc_src_udp,
	TC_FLAGS_OFFSET_OUT	    => tc_flags,
	TC_TRANSMISSION_DONE_IN => tc_done,
	TC_IDENT_OUT            => tc_ident
);

transmit_controller : trb_net16_gbe_transmit_control2
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	TC_DATAREADY_IN        => tc_dataready,
	TC_RD_EN_OUT		        => tc_rd_en,
	TC_DATA_IN		        => tc_data,
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




end architecture;
