LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;

entity trb_net16_med_ecp_sfp_gbe_8b is
-- gk 28.04.10
generic (
	USE_125MHZ_EXTCLK			: integer range 0 to 1 := 1
);
port(
	RESET					: in	std_logic;
	GSR_N					: in	std_logic;
	CLK_125_OUT				: out	std_logic;
	CLK_125_IN				: in	std_logic;  -- gk 28.04.10  used when intclk
	CLK_125_RX_OUT				: out	std_logic;
	--SGMII connection to frame transmitter (tsmac)
	FT_TX_CLK_EN_OUT			: out	std_logic;
	FT_RX_CLK_EN_OUT			: out	std_logic;
	FT_COL_OUT				: out	std_logic;
	FT_CRS_OUT				: out	std_logic;
	FT_TXD_IN				: in	std_logic_vector(7 downto 0);
	FT_TX_EN_IN				: in	std_logic;
	FT_TX_ER_IN				: in	std_logic;

	FT_RXD_OUT				: out	std_logic_vector(7 downto 0);
	FT_RX_EN_OUT				: out	std_logic;
	FT_RX_ER_OUT				: out	std_logic;
	--SFP Connection
	SD_RXD_P_IN				: in	std_logic;
	SD_RXD_N_IN				: in	std_logic;
	SD_TXD_P_OUT				: out	std_logic;
	SD_TXD_N_OUT				: out	std_logic;
	SD_REFCLK_P_IN				: in	std_logic;
	SD_REFCLK_N_IN				: in	std_logic;
	SD_PRSNT_N_IN				: in	std_logic; -- SFP Present ('0' = SFP in place, '1' = no SFP mounted)
	SD_LOS_IN				: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	SD_TXDIS_OUT				: out	std_logic; -- SFP disable
	-- Autonegotiation stuff 
	MR_RESET_IN				: in	std_logic;
	MR_MODE_IN				: in	std_logic;
	MR_ADV_ABILITY_IN			: in 	std_logic_vector(15 downto 0); -- should be x"0020
	MR_AN_LP_ABILITY_OUT			: out	std_logic_vector(15 downto 0); -- advert page from link partner
	MR_AN_PAGE_RX_OUT			: out	std_logic;
	MR_AN_COMPLETE_OUT			: out	std_logic; 
	MR_AN_ENABLE_IN				: in	std_logic;
	MR_RESTART_AN_IN			: in	std_logic;
	-- Status and control port
	STAT_OP					: out	std_logic_vector (15 downto 0);
	CTRL_OP					: in	std_logic_vector (15 downto 0);
	STAT_DEBUG				: out	std_logic_vector (63 downto 0);
	CTRL_DEBUG				: in	std_logic_vector (63 downto 0)
);
end entity;

architecture trb_net16_med_ecp_sfp_gbe_8b of trb_net16_med_ecp_sfp_gbe_8b is

-- Placer Directives
--attribute HGROUP : string;
-- for whole architecture
--attribute HGROUP of trb_net16_med_ecp_sfp_gbe_8b : architecture  is "media_interface_group";
attribute syn_sharing : string;
attribute syn_sharing of trb_net16_med_ecp_sfp_gbe_8b : architecture is "off";

--component serdes_gbe_0ch is
component serdes_ch4 is
   --GENERIC (USER_CONFIG_FILE    :  String := "serdes_gbe_0ch.txt");
GENERIC (USER_CONFIG_FILE    :  String := "serdes_ch4.txt");
 port (
------------------
-- CH0 --
    hdinp_ch3, hdinn_ch3    :   in std_logic;
    hdoutp_ch3, hdoutn_ch3   :   out std_logic;
    rxiclk_ch3    :   in std_logic;
    txiclk_ch3    :   in std_logic;
    rx_full_clk_ch3   :   out std_logic;
    rx_half_clk_ch3   :   out std_logic;
    tx_full_clk_ch3   :   out std_logic;
    tx_half_clk_ch3   :   out std_logic;
    fpga_rxrefclk_ch3    :   in std_logic;
    txdata_ch3    :   in std_logic_vector (7 downto 0);
    tx_k_ch3    :   in std_logic;
    xmit_ch3    :   in std_logic;
    tx_disp_correct_ch3    :   in std_logic;
    rxdata_ch3   :   out std_logic_vector (7 downto 0);
    rx_k_ch3   :   out std_logic;
    rx_disp_err_ch3   :   out std_logic;
    rx_cv_err_ch3   :   out std_logic;
    rx_serdes_rst_ch3_c    :   in std_logic;
    sb_felb_ch3_c    :   in std_logic;
    sb_felb_rst_ch3_c    :   in std_logic;
    tx_pcs_rst_ch3_c    :   in std_logic;
    tx_pwrup_ch3_c    :   in std_logic;
    rx_pcs_rst_ch3_c    :   in std_logic;
    rx_pwrup_ch3_c    :   in std_logic;
    rx_los_low_ch3_s   :   out std_logic;
    lsm_status_ch3_s   :   out std_logic;
    rx_cdr_lol_ch3_s   :   out std_logic;
-- CH1 --
-- CH2 --
-- CH3 --
---- Miscillaneous ports
    fpga_txrefclk  :   in std_logic;
    tx_serdes_rst_c    :   in std_logic;
    tx_pll_lol_qd_s   :   out std_logic;
    rst_qd_c    :   in std_logic;
    serdes_rst_qd_c    :   in std_logic);

end component;

component serdes_gbe_0_extclock_8b is
GENERIC (USER_CONFIG_FILE    :  String := "serdes_gbe_0_extclock_8b.txt");
port( refclkp					: in	std_logic;
	  refclkn					: in	std_logic;
	  hdinp0					: in	std_logic;
	  hdinn0					: in	std_logic;
	  hdoutp0					: out	std_logic;
	  hdoutn0					: out	std_logic;
	  ff_rxiclk_ch0				: in	std_logic;
	  ff_txiclk_ch0				: in	std_logic;
	  ff_ebrd_clk_0				: in	std_logic;
	  ff_txdata_ch0				: in	std_logic_vector (7 downto 0);
	  ff_rxdata_ch0				: out	std_logic_vector (7 downto 0);
	  ff_tx_k_cntrl_ch0			: in	std_logic;
	  ff_rx_k_cntrl_ch0			: out	std_logic;
	  ff_rxfullclk_ch0			: out	std_logic;
	  ff_xmit_ch0				: in	std_logic;
	  ff_correct_disp_ch0		: in	std_logic;
	  ff_disp_err_ch0			: out	std_logic;
	  ff_cv_ch0					: out	std_logic;
	  ff_rx_even_ch0			: out	std_logic;
	  ffc_rrst_ch0				: in	std_logic;
	  ffc_lane_tx_rst_ch0		: in	std_logic;
	  ffc_lane_rx_rst_ch0		: in	std_logic;
	  ffc_txpwdnb_ch0			: in	std_logic;
	  ffc_rxpwdnb_ch0			: in	std_logic;
	  ffs_rlos_lo_ch0			: out	std_logic;
	  ffs_ls_sync_status_ch0	: out	std_logic;
	  ffs_rlol_ch0				: out	std_logic;
	  oob_out_ch0				: out	std_logic;
	  ffc_macro_rst				: in	std_logic;
	  ffc_quad_rst				: in	std_logic;
	  ffc_trst					: in	std_logic;
	  ff_txfullclk				: out	std_logic;
	  ff_txhalfclk				: out	std_logic;
	  refck2core				: out	std_logic;
	  ffs_plol					: out	std_logic
	);
end component;

component serdes_gbe_0_intclock_8b is
   GENERIC (USER_CONFIG_FILE    :  String := "serdes_gbe_0_intclock_8b.txt");
 port (
   core_txrefclk : in std_logic;
   core_rxrefclk : in std_logic;
   hdinp0, hdinn0 : in std_logic;
   hdoutp0, hdoutn0 : out std_logic;
   ff_rxiclk_ch0, ff_txiclk_ch0, ff_ebrd_clk_0 : in std_logic;
   ff_txdata_ch0 : in std_logic_vector (7 downto 0);
   ff_rxdata_ch0 : out std_logic_vector (7 downto 0);
   ff_tx_k_cntrl_ch0 : in std_logic;
   ff_rx_k_cntrl_ch0 : out std_logic;
   ff_rxfullclk_ch0 : out std_logic;
   ff_xmit_ch0 : in std_logic;
   ff_correct_disp_ch0 : in std_logic;
   ff_disp_err_ch0, ff_cv_ch0 : out std_logic;
   ff_rx_even_ch0 : out std_logic;
   ffc_rrst_ch0 : in std_logic;
   ffc_lane_tx_rst_ch0 : in std_logic;
   ffc_lane_rx_rst_ch0 : in std_logic;
   ffc_txpwdnb_ch0 : in std_logic;
   ffc_rxpwdnb_ch0 : in std_logic;
   ffs_rlos_lo_ch0 : out std_logic;
   ffs_ls_sync_status_ch0 : out std_logic;
   ffs_rlol_ch0 : out std_logic;
   oob_out_ch0 : out std_logic;
   ffc_macro_rst : in std_logic;
   ffc_quad_rst : in std_logic;
   ffc_trst : in std_logic;
   ff_txfullclk : out std_logic;
   ff_txhalfclk : out std_logic;
   ffs_plol : out std_logic);

end component;

-- component sgmii_gbe_pcs34
-- port( rst_n                  : in	std_logic;
-- 	  signal_detect          : in	std_logic;
-- 	  gbe_mode               : in	std_logic;
-- 	  sgmii_mode             : in	std_logic;
-- 	  operational_rate       : in	std_logic_vector(1 downto 0);
-- 	  debug_link_timer_short : in	std_logic;
-- 	  rx_compensation_err    : out	std_logic;
-- 	  tx_clk_125             : in	std_logic;                    
-- 	  tx_clock_enable_source : out	std_logic;
-- 	  tx_clock_enable_sink   : in	std_logic;          
-- 	  tx_d                   : in	std_logic_vector(7 downto 0); 
-- 	  tx_en                  : in	std_logic;       
-- 	  tx_er                  : in	std_logic;       
-- 	  rx_clk_125             : in	std_logic; 
-- 	  rx_clock_enable_source : out	std_logic;
-- 	  rx_clock_enable_sink   : in	std_logic;          
-- 	  rx_d                   : out	std_logic_vector(7 downto 0);       
-- 	  rx_dv                  : out	std_logic;  
-- 	  rx_er                  : out	std_logic; 
-- 	  col                    : out	std_logic;  
-- 	  crs                    : out	std_logic;  
-- 	  tx_data                : out	std_logic_vector(7 downto 0);  
-- 	  tx_kcntl               : out	std_logic; 
-- 	  tx_disparity_cntl      : out	std_logic; 
-- 	  serdes_recovered_clk   : in	std_logic; 
-- 	  rx_data                : in	std_logic_vector(7 downto 0);  
-- 	  rx_even                : in	std_logic;  
-- 	  rx_kcntl               : in	std_logic; 
-- 	  rx_disp_err            : in	std_logic; 
-- 	  rx_cv_err              : in	std_logic; 
-- 	  rx_err_decode_mode     : in	std_logic; 
-- 	  mr_an_complete         : out	std_logic; 
-- 	  mr_page_rx             : out	std_logic; 
-- 	  mr_lp_adv_ability      : out	std_logic_vector(15 downto 0); 
-- 	  mr_main_reset          : in	std_logic; 
-- 	  mr_an_enable           : in	std_logic; 
-- 	  mr_restart_an          : in	std_logic; 
-- 	  mr_adv_ability         : in	std_logic_vector(15 downto 0)  
-- 	);
-- end component;

component sgmii_gbe_pcs35 --sgmii_gbe_pcs36 -- sgmii_gbe_pcs35
port( rst_n                  : in	std_logic;
	  signal_detect          : in	std_logic;
	  gbe_mode               : in	std_logic;
	  sgmii_mode             : in	std_logic;
	  operational_rate       : in	std_logic_vector(1 downto 0);
	  debug_link_timer_short : in	std_logic;

 force_isolate : in std_logic;
 force_loopback : in std_logic;
 force_unidir : in std_logic;

	  rx_compensation_err    : out	std_logic;

 ctc_drop_flag : out std_logic;
 ctc_add_flag : out std_logic;
 an_link_ok : out std_logic;

	  tx_clk_125             : in	std_logic;                    
	  tx_clock_enable_source : out	std_logic;
	  tx_clock_enable_sink   : in	std_logic;          
	  tx_d                   : in	std_logic_vector(7 downto 0); 
	  tx_en                  : in	std_logic;       
	  tx_er                  : in	std_logic;       
	  rx_clk_125             : in	std_logic; 
	  rx_clock_enable_source : out	std_logic;
	  rx_clock_enable_sink   : in	std_logic;          
	  rx_d                   : out	std_logic_vector(7 downto 0);       
	  rx_dv                  : out	std_logic;  
	  rx_er                  : out	std_logic; 
	  col                    : out	std_logic;  
	  crs                    : out	std_logic;  
	  tx_data                : out	std_logic_vector(7 downto 0);  
	  tx_kcntl               : out	std_logic; 
	  tx_disparity_cntl      : out	std_logic; 

 xmit_autoneg : out std_logic;

	  serdes_recovered_clk   : in	std_logic; 
	  rx_data                : in	std_logic_vector(7 downto 0);  
	  rx_even                : in	std_logic;  
	  rx_kcntl               : in	std_logic; 
	  rx_disp_err            : in	std_logic; 
	  rx_cv_err              : in	std_logic; 
	  rx_err_decode_mode     : in	std_logic; 
	  mr_an_complete         : out	std_logic; 
	  mr_page_rx             : out	std_logic; 
	  mr_lp_adv_ability      : out	std_logic_vector(15 downto 0); 
	  mr_main_reset          : in	std_logic; 
	  mr_an_enable           : in	std_logic; 
	  mr_restart_an          : in	std_logic; 
	  mr_adv_ability         : in	std_logic_vector(15 downto 0)  
	);
end component;

component trb_net16_lsm_sfp_gbe is
port( SYSCLK			: in	std_logic; -- fabric clock (100MHz)
	  RESET				: in	std_logic; -- synchronous reset
	  CLEAR				: in	std_logic; -- asynchronous reset, connect to '0' if not needed / available
	  -- status signals
	  SFP_MISSING_IN	: in	std_logic; -- SFP Missing ('1' = no SFP mounted, '0' = SFP in place)
	  SFP_LOS_IN		: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	  SD_LINK_OK_IN		: in	std_logic; -- SerDes Link OK ('0' = not linked, '1' link established)
	  SD_LOS_IN			: in	std_logic; -- SerDes Loss Of Signal ('0' = OK, '1' = signal lost)
	  SD_TXCLK_BAD_IN	: in	std_logic; -- SerDes Tx Clock locked ('0' = locked, '1' = not locked)
	  SD_RXCLK_BAD_IN	: in	std_logic; -- SerDes Rx Clock locked ('0' = locked, '1' = not locked)
	  -- control signals
	  FULL_RESET_OUT	: out	std_logic; -- full reset AKA quad_reset
	  LANE_RESET_OUT	: out	std_logic; -- partial reset AKA lane_reset
	  USER_RESET_OUT	: out	std_logic; -- FPGA reset for user logic
	  -- debug signals
	  TIMING_CTR_OUT	: out	std_logic_vector(18 downto 0);
	  BSM_OUT			: out	std_logic_vector(3 downto 0);
	  DEBUG_OUT			: out	std_logic_vector(31 downto 0)
	);
end component;

component reset_controller_pcs port (
	rst_n                 : in std_logic;
	clk                   : in std_logic;
	tx_plol               : in std_logic; 
	rx_cdr_lol            : in std_logic; 
        quad_rst_out          : out std_logic; 
        tx_pcs_rst_out        : out std_logic; 
        rx_pcs_rst_out        : out std_logic
   );
end component;
component reset_controller_cdr port (
	rst_n                 : in std_logic;
	clk                   : in std_logic;
	cdr_lol               : in std_logic; 
        cdr_rst_out           : out std_logic
   );
end component;

component rate_resolution port (
	gbe_mode               : in std_logic;
	sgmii_mode             : in std_logic;
	an_enable              : in std_logic; 
	advertised_rate        : in std_logic_vector(1 downto 0);
	link_partner_rate      : in std_logic_vector(1 downto 0);
	non_an_rate            : in std_logic_vector(1 downto 0);
	operational_rate       : out std_logic_vector(1 downto 0)  
   );
end component;

component register_interface_hb port (
	rst_n                  : in std_logic;
	hclk                   : in std_logic;
	gbe_mode               : in std_logic;
	sgmii_mode             : in std_logic;
	hcs_n                  : in std_logic;
	hwrite_n               : in std_logic;
	haddr                  : in std_logic_vector(3 downto 0);
	hdatain                : in std_logic_vector(7 downto 0);
	hdataout               : out std_logic_vector(7 downto 0);   
	hready_n               : out std_logic;
	mr_an_complete         : in std_logic; 
	mr_page_rx             : in std_logic; 
	mr_lp_adv_ability      : in std_logic_vector(15 downto 0); 
	mr_main_reset          : out std_logic; 
	mr_an_enable           : out std_logic; 
	mr_restart_an          : out std_logic; 
	mr_adv_ability         : out std_logic_vector(15 downto 0) 
   );
end component;

component sgmii33 port (
	rst_n                  : in std_logic;
	signal_detect          : in std_logic;
	gbe_mode               : in std_logic;
	sgmii_mode             : in std_logic;
	--force_isolate          : in std_logic;
	--force_loopback         : in std_logic;
	--force_unidir           : in std_logic;
	operational_rate       : in std_logic_vector(1 downto 0);
	debug_link_timer_short : in std_logic;
	rx_compensation_err    : out std_logic;
	--ctc_drop_flag          : out std_logic;
	--ctc_add_flag           : out std_logic;
	--an_link_ok             : out std_logic;
	tx_clk_125             : in std_logic;                    
        tx_clock_enable_source : out std_logic;
        tx_clock_enable_sink   : in std_logic;          
	tx_d                   : in std_logic_vector(7 downto 0); 
	tx_en                  : in std_logic;       
	tx_er                  : in std_logic;       
	rx_clk_125             : in std_logic; 
        rx_clock_enable_source : out std_logic;
        rx_clock_enable_sink   : in std_logic;          
	rx_d                   : out std_logic_vector(7 downto 0);       
	rx_dv                  : out std_logic;  
	rx_er                  : out std_logic; 
	col                    : out std_logic;  
	crs                    : out std_logic;  
	tx_data                : out std_logic_vector(7 downto 0);  
	tx_kcntl               : out std_logic; 
	tx_disparity_cntl      : out std_logic; 
	--xmit_autoneg           : out std_logic; 
	serdes_recovered_clk   : in std_logic; 
	rx_data                : in std_logic_vector(7 downto 0);  
	rx_even                : in std_logic;  
	rx_kcntl               : in std_logic; 
	rx_disp_err            : in std_logic; 
	rx_cv_err              : in std_logic; 
	rx_err_decode_mode     : in std_logic; 
	mr_an_complete         : out std_logic; 
	mr_page_rx             : out std_logic; 
	mr_lp_adv_ability      : out std_logic_vector(15 downto 0); 
	mr_main_reset          : in std_logic; 
	mr_an_enable           : in std_logic; 
	mr_restart_an          : in std_logic; 
	mr_adv_ability         : in std_logic_vector(15 downto 0)
   );
end component;


signal refclkcore			: std_logic;

signal sd_link_ok			: std_logic;
signal sd_link_error		: std_logic_vector(2 downto 0);

signal sd_tx_data			: std_logic_vector(7 downto 0);
signal sd_tx_kcntl			: std_logic;
signal sd_tx_correct_disp	: std_logic;
signal sd_tx_clk			: std_logic;

signal sd_rx_data			: std_logic_vector(7 downto 0);
signal sd_rx_even			: std_logic;
signal sd_rx_kcntl			: std_logic;
signal sd_rx_disp_error		: std_logic;
signal sd_rx_cv_error		: std_logic;
signal sd_rx_clk			: std_logic;

signal sd_tx_data_q			: std_logic_vector(7 downto 0);
signal sd_tx_kcntl_q			: std_logic;
signal sd_tx_correct_disp_q	: std_logic;

signal sd_rx_data_q			: std_logic_vector(7 downto 0);
signal sd_rx_kcntl_q			: std_logic;
signal sd_rx_disp_error_q		: std_logic;
signal sd_rx_cv_error_q		: std_logic;

signal pcs_mr_an_complete	: std_logic;
signal pcs_mr_ability		: std_logic_vector(15 downto 0);
signal pcs_mr_page_rx		: std_logic;
signal pcs_mr_reset			: std_logic;

signal pcs_tx_clk_en		: std_logic;
signal pcs_rx_clk_en		: std_logic;
signal pcs_rx_comp_err		: std_logic;

signal pcs_rx_d				: std_logic_vector(7 downto 0);
signal pcs_rx_dv			: std_logic;
signal pcs_rx_er			: std_logic;

signal sd_rx_debug			: std_logic_vector(15 downto 0);
signal sd_tx_debug			: std_logic_vector(15 downto 0);

signal buf_stat_debug		: std_logic_vector(63 downto 0);

signal quad_rst				: std_logic;
signal lane_rst				: std_logic;
signal user_rst				: std_logic;

signal reset_bsm			: std_logic_vector(3 downto 0);
signal reset_debug			: std_logic_vector(31 downto 0);
signal   test_clk : std_logic;

signal xmit : std_logic;
signal signal_detected, compensation_err, tx_clk_en, rx_clk_en, rst_n, an_complete : std_logic;
signal tx_pll_lol, rx_cdr_lol, los, tx_pcs_rst, rx_pcs_rst, rx_serdes_rst : std_logic;

signal operational_rate : std_logic_vector(1 downto 0);

signal mr_an_enable, mr_restart_an, mr_main_reset, mr_page_rx : std_logic;
signal mr_lp_adv_ability, mr_adv_ability : std_logic_vector(15 downto 0);


  attribute syn_keep : boolean;
  attribute syn_preserve : boolean;

  --attribute syn_keep of sd_tx_clk : signal is true;
  --attribute syn_preserve of sd_tx_clk : signal is true;
  attribute syn_keep of sd_rx_clk : signal is true;
  attribute syn_preserve of sd_rx_clk : signal is true;
  
  attribute syn_keep of sd_tx_correct_disp_q, sd_tx_kcntl_q, sd_tx_data_q, sd_rx_data_q, sd_rx_cv_error_q, sd_rx_disp_error_q, sd_rx_kcntl_q : signal is true;
  attribute syn_preserve of sd_tx_correct_disp_q, sd_tx_kcntl_q, sd_tx_data_q, sd_rx_data_q, sd_rx_cv_error_q, sd_rx_disp_error_q, sd_rx_kcntl_q : signal is true;

begin

-- Reset state machine for SerDes
-- THE_RESET_STATEMACHINE: trb_net16_lsm_sfp_gbe
-- port map(
-- 	SYSCLK			=> CLK_125_IN,
-- 	RESET			=> '0', -- really?
-- 	CLEAR			=> RESET, -- from 100MHz PLL, includes async part
-- 	-- status signals
-- 	SFP_MISSING_IN		=> SD_PRSNT_N_IN,
-- 	SFP_LOS_IN		=> SD_LOS_IN,
-- 	SD_LINK_OK_IN		=> '1', -- not used
-- 	SD_LOS_IN		=> '0', -- not used
-- 	SD_TXCLK_BAD_IN		=> sd_link_error(2), -- plol
-- 	SD_RXCLK_BAD_IN		=> sd_link_error(1), -- rlol
-- 	-- control signals
-- 	FULL_RESET_OUT		=> quad_rst,
-- 	LANE_RESET_OUT		=> lane_rst,
-- 	USER_RESET_OUT		=> user_rst,
-- 	-- debug signals
-- 	TIMING_CTR_OUT		=> open,
-- 	BSM_OUT			=> reset_bsm,
-- 	DEBUG_OUT		=> reset_debug
-- );

-- gk 28.04.10
-- SerDes for GbE
clk_int : if (USE_125MHZ_EXTCLK = 0) generate

	refclkcore <= CLK_125_IN; --sd_tx_clk; --CLK_125_IN;

-- 	SERDES_GBE : serdes_gbe_0_intclock_8b
-- 	port map(
-- 			core_txrefclk            => CLK_125_IN,
-- 			core_rxrefclk            => CLK_125_IN,
-- 		hdinp0                   => SD_RXD_P_IN,
-- 		hdinn0                   => SD_RXD_N_IN,
-- 		hdoutp0                  => SD_TXD_P_OUT,
-- 		hdoutn0                  => SD_TXD_N_OUT,
-- 			ff_rxiclk_ch0            => sd_rx_clk,
-- 			ff_txiclk_ch0            => sd_tx_clk,
-- 			ff_ebrd_clk_0            => sd_rx_clk,
-- 		ff_txdata_ch0            => sd_tx_data,
-- 		ff_rxdata_ch0            => sd_rx_data,
-- 		ff_tx_k_cntrl_ch0        => sd_tx_kcntl,
-- 		ff_rx_k_cntrl_ch0        => sd_rx_kcntl,
-- 			ff_rxfullclk_ch0         => sd_rx_clk,
-- 		ff_xmit_ch0              => '0',
-- 		ff_correct_disp_ch0      => sd_tx_correct_disp,
-- 		ff_disp_err_ch0          => sd_rx_disp_error,
-- 		ff_cv_ch0                => sd_rx_cv_error,
-- 		ff_rx_even_ch0           => sd_rx_even,
-- 		ffc_rrst_ch0             => '0',
-- 		ffc_lane_tx_rst_ch0      => lane_rst,
-- 		ffc_lane_rx_rst_ch0      => lane_rst,
-- 		ffc_txpwdnb_ch0          => '1',
-- 		ffc_rxpwdnb_ch0          => '1',
-- 		ffs_rlos_lo_ch0          => sd_link_error(0),
-- 		ffs_ls_sync_status_ch0   => sd_link_ok,
-- 		ffs_rlol_ch0             => sd_link_error(1),
-- 		oob_out_ch0              => open,
-- 		ffc_macro_rst            => '0',
-- 		ffc_quad_rst             => quad_rst,
-- 		ffc_trst                 => '0',
-- 			ff_txfullclk             => sd_tx_clk,
-- 			ff_txhalfclk             => open,
-- 		ffs_plol                 => sd_link_error(2)
-- 	);

	--SERDES_GBE : serdes_gbe_0ch
      SERDES_GBE : serdes_ch4
	port map(
	------------------
	-- CH0 --
	    hdinp_ch3    => SD_RXD_P_IN,
	    hdinn_ch3    => SD_RXD_N_IN,
	    hdoutp_ch3   => SD_TXD_P_OUT,
	    hdoutn_ch3   => SD_TXD_N_OUT,
	      rxiclk_ch3   => sd_rx_clk,
	      txiclk_ch3   => CLK_125_IN, --sd_tx_clk,
	 rx_full_clk_ch3      => sd_rx_clk,
	    rx_half_clk_ch3      => open,
	 tx_full_clk_ch3      => open, --sd_tx_clk,
	    tx_half_clk_ch3      => open,
	       fpga_rxrefclk_ch3    => CLK_125_IN,
	    txdata_ch3           => sd_tx_data_q,
	    tx_k_ch3             => sd_tx_kcntl_q,
	    xmit_ch3             => xmit, --'0',
	    tx_disp_correct_ch3  => sd_tx_correct_disp_q,
	    rxdata_ch3           => sd_rx_data, 
	    rx_k_ch3             => sd_rx_kcntl,
	    rx_disp_err_ch3      => sd_rx_disp_error,
	    rx_cv_err_ch3        => sd_rx_cv_error,
	    rx_serdes_rst_ch3_c  => rx_serdes_rst,
	    sb_felb_ch3_c        => '0',
	    sb_felb_rst_ch3_c    => '0',
	    tx_pcs_rst_ch3_c     => tx_pcs_rst,
	    tx_pwrup_ch3_c       => '1',
	    rx_pcs_rst_ch3_c     => rx_pcs_rst,
	    rx_pwrup_ch3_c       => '1',
	    rx_los_low_ch3_s     => los,
	    lsm_status_ch3_s     => signal_detected,
	    rx_cdr_lol_ch3_s     => rx_cdr_lol,
	-- CH1 --
	-- CH2 --
	-- CH3 --
	---- Miscillaneous ports
	       fpga_txrefclk        => CLK_125_IN,
	    tx_serdes_rst_c      => '0',
	    tx_pll_lol_qd_s      => tx_pll_lol,
	    rst_qd_c                => quad_rst,
	    serdes_rst_qd_c      => '0'
	);


end generate clk_int;

clk_ext : if (USE_125MHZ_EXTCLK = 1) generate
	--SERDES_GBE : serdes_gbe_0_extclock_8b
    SERDES_GBE : serdes_gbe_0_extclock_8b                               	                                       	        
	port map( -- SerDes connection to outside world
			refclkp					=> SD_REFCLK_P_IN, -- SerDes REFCLK diff. input
			refclkn					=> SD_REFCLK_N_IN,
			hdinp0					=> SD_RXD_P_IN, -- SerDes RX diff. input
			hdinn0					=> SD_RXD_N_IN,
			hdoutp0					=> SD_TXD_P_OUT, -- SerDes TX diff. output
			hdoutn0					=> SD_TXD_N_OUT,
			refck2core				=> refclkcore, -- reference clock from input
			-- RX part
			ff_rxfullclk_ch0			=> sd_rx_clk, -- RX full clock output
			ff_rxiclk_ch0				=> sd_rx_clk,
			ff_ebrd_clk_0				=> sd_rx_clk, -- EB ist not used as recommended by Lattice
			ff_rxdata_ch0				=> sd_rx_data, -- RX data output
			ff_rx_k_cntrl_ch0			=> sd_rx_kcntl, -- RX komma output
			ff_rx_even_ch0			=> sd_rx_even, -- for autonegotiation (output)
			ff_disp_err_ch0			=> sd_rx_disp_error, -- RX disparity error
			ff_cv_ch0					=> sd_rx_cv_error, -- RX code violation error
			-- TX part
			ff_txfullclk				=> sd_tx_clk, -- TX full clock output
			ff_txiclk_ch0				=> sd_tx_clk, 
			ff_txhalfclk				=> open,
			ff_txdata_ch0				=> sd_tx_data, -- TX data input
			ff_tx_k_cntrl_ch0			=> sd_tx_kcntl, -- TX komma input
			ff_xmit_ch0				=> '0', -- for autonegotiation (input)
			ff_correct_disp_ch0		=> sd_tx_correct_disp, -- controls disparity at IPG start (input)
			-- Resets and power down
			ffc_quad_rst				=> quad_rst, -- async reset for whole QUAD (active high)
			ffc_lane_tx_rst_ch0		=> lane_rst, -- async reset for TX channel
			ffc_lane_rx_rst_ch0		=> lane_rst, -- async reset for RX channel
			ffc_rrst_ch0				=> '0', -- '0' for normal operation
			ffc_macro_rst				=> '0', -- '0' for normal operation
			ffc_trst					=> '0', -- '0' for normal operation
			ffc_txpwdnb_ch0			=> '1', -- must be '1'
			ffc_rxpwdnb_ch0			=> '1', -- must be '1'
			-- Status outputs
			ffs_ls_sync_status_ch0	=> sd_link_ok, -- synced to kommas?
			ffs_rlos_lo_ch0			=> sd_link_error(0), -- loss of signal in RX channel
			ffs_rlol_ch0				=> sd_link_error(1), -- loss of lock in RX PLL
			ffs_plol					=> sd_link_error(2), -- loss of lock in TX PLL
			oob_out_ch0				=> open -- not needed
			);
end generate clk_ext;

--SD_RX_DATA_PROC: process( sd_rx_clk )
--begin
--	if( rising_edge(sd_rx_clk) ) then
--		sd_rx_debug(15 downto 12) <= (others => '0');
--		sd_rx_debug(11)          <= sd_rx_disp_error;
--		sd_rx_debug(10)          <= sd_rx_even;
--		sd_rx_debug(9)           <= sd_rx_cv_error;
--		sd_rx_debug(8)           <= sd_rx_kcntl;
--		sd_rx_debug(7 downto 0)  <= sd_rx_data;
--	end if;
--end process SD_RX_DATA_PROC;
--
--SD_TX_DATA_PROC: process( CLK_125_IN) --sd_tx_clk )
--begin
--	if( rising_edge(CLK_125_IN)) then --sd_tx_clk) ) then
--		sd_tx_debug(15 downto 10) <= (others => '0');
--		sd_tx_debug(9)            <= sd_tx_correct_disp;
--		sd_tx_debug(8)            <= sd_tx_kcntl;
--		sd_tx_debug(7 downto 0)   <= sd_tx_data;
--	end if;
--end process SD_TX_DATA_PROC;

buf_stat_debug(63 downto 40) <= (others => '0');
buf_stat_debug(39 downto 36) <= reset_debug(3 downto 0);
buf_stat_debug(35 downto 32) <= reset_bsm;
-- logic analyzer signals
buf_stat_debug(31)           <= pcs_mr_page_rx;
buf_stat_debug(30)           <= pcs_mr_reset; --pcs_mr_an_complete;
buf_stat_debug(28 downto 26) <= reset_bsm(2 downto 0);
buf_stat_debug(25 downto 23) <= sd_link_error(2 downto 0);
buf_stat_debug(22)           <= sd_link_ok;
buf_stat_debug(21 downto 12) <= sd_tx_debug(9 downto 0);
buf_stat_debug(11 downto 0)  <= sd_rx_debug(11 downto 0);


--SGMII_GBE_PCS : sgmii33 port map (
--	rst_n                  => GSR_N,
--	signal_detect          => signal_detected,
--	gbe_mode               => '1',
--	sgmii_mode             => '0',
--	operational_rate       => operational_rate,
--	debug_link_timer_short => '0',
--	rx_compensation_err    => compensation_err,
--	tx_clk_125             => CLK_125_IN,
--        tx_clock_enable_source => tx_clk_en,
--        tx_clock_enable_sink   => tx_clk_en,
--	tx_d                   => FT_TXD_IN, --pcs_rxd, --pcs_txd,
--	tx_en                  => FT_TX_EN_IN, --pcs_rx_dv, --pcs_tx_en, 
--	tx_er                  => FT_TX_ER_IN, --pcs_rx_er, --pcs_tx_er, 
--	rx_clk_125             => CLK_125_IN,
--        rx_clock_enable_source => rx_clk_en,
--        rx_clock_enable_sink   => rx_clk_en,         
--	rx_d                   => pcs_rx_d,
--	rx_dv                  => pcs_rx_dv,
--	rx_er                  => pcs_rx_er, 
--	col                    => FT_COL_OUT,
--	crs                    => FT_CRS_OUT,
--	tx_data                => sd_tx_data,
--	tx_kcntl               => sd_tx_kcntl,
--	tx_disparity_cntl      => sd_tx_correct_disp,
--	serdes_recovered_clk   => sd_rx_clk,
--	rx_data                => sd_rx_data_q,
--	rx_even                => '0',
--	rx_kcntl               => sd_rx_kcntl_q,
--	rx_disp_err            => sd_rx_disp_error_q,
--	rx_cv_err              => sd_rx_cv_error_q,
--	rx_err_decode_mode     => '0',
--	mr_an_complete         => an_complete,
--	mr_page_rx             => mr_page_rx,
--	mr_lp_adv_ability      => mr_lp_adv_ability,
--	mr_main_reset          => mr_main_reset, --reset_i,
--	mr_an_enable           => '1', --'1',
--	mr_restart_an          => mr_restart_an,
--	mr_adv_ability         => mr_adv_ability --x"0020"
--   );
   
   SYNC_TX_PROC : process(CLK_125_IN)
   begin
   	if rising_edge(CLK_125_IN) then
   		sd_tx_data_q <= sd_tx_data;
   		sd_tx_kcntl_q <= sd_tx_kcntl;
   		sd_tx_correct_disp_q <= sd_tx_correct_disp;
   	end if;
   end process SYNC_TX_PROC;
   
   SYNC_RX_PROC : process(sd_rx_clk)
   begin
   	if rising_edge(sd_rx_clk) then
   		sd_rx_data_q <= sd_rx_data;
   		sd_rx_kcntl_q <= sd_rx_kcntl;
   		sd_rx_disp_error_q <= sd_rx_disp_error;
   		sd_rx_cv_error_q <= sd_rx_cv_error;
   	end if;
   end process SYNC_RX_PROC;
   
   

 
 SGMII_GBE_PCS : sgmii_gbe_pcs35 --sgmii_gbe_pcs36 --sgmii_gbe_pcs35
 port map(
 	rst_n				=> rst_n, --GSR_N,
 	signal_detect			=> signal_detected,
 	gbe_mode			=> '1',
 	sgmii_mode			=> '0',
 	operational_rate		=> operational_rate,
 	debug_link_timer_short		=> '0',
 
  force_isolate => '0',
  force_loopback => '0',
  force_unidir => '0',
 
 	rx_compensation_err		=> compensation_err,
 
  ctc_drop_flag => open,
  ctc_add_flag => open,
  an_link_ok => open,
 
 	-- MAC interface
 		tx_clk_125			=> CLK_125_IN, --refclkcore, -- original clock from SerDes
 	tx_clock_enable_source		=> tx_clk_en,
 	tx_clock_enable_sink		=> tx_clk_en,
 	tx_d				=> FT_TXD_IN, -- TX data from MAC
 	tx_en				=> FT_TX_EN_IN, -- TX data enable from MAC
 	tx_er				=> FT_TX_ER_IN, -- TX error from MAC
 		rx_clk_125			=> sd_rx_clk, --CLK_125_IN, --refclkcore, -- original clock from SerDes
 	rx_clock_enable_source		=> rx_clk_en,
 	rx_clock_enable_sink		=> rx_clk_en,
 	rx_d				=> pcs_rx_d, -- RX data to MAC
 	rx_dv				=> pcs_rx_dv, -- RX data enable to MAC
 	rx_er				=> pcs_rx_er, -- RX error to MAC
 	col				=> FT_COL_OUT,
 	crs				=> FT_CRS_OUT,
 	-- SerDes interface
 	tx_data				=> sd_tx_data, -- TX data to SerDes
 	tx_kcntl			=> sd_tx_kcntl, -- TX komma control to SerDes
 	tx_disparity_cntl		=> sd_tx_correct_disp, -- idle parity state control in IPG (to SerDes)
 
  xmit_autoneg => xmit,
 
 		serdes_recovered_clk		=> sd_rx_clk, -- 125MHz recovered from receive bit stream
 	rx_data				=> sd_rx_data_q, -- RX data from SerDes
 	rx_kcntl			=> sd_rx_kcntl_q, -- RX komma control from SerDes
 	rx_err_decode_mode		=> '0', -- receive error control mode fixed to normal
 	rx_even				=> '0', -- unused (receive error control mode = normal, tie to GND)
 	rx_disp_err			=> sd_rx_disp_error_q, -- RX disparity error from SerDes
 	rx_cv_err			=> sd_rx_cv_error_q, -- RX code violation error from SerDes
 	-- Autonegotiation stuff
 	mr_an_complete			=> an_complete,
 	mr_page_rx			=> mr_page_rx,
 	mr_lp_adv_ability		=> mr_lp_adv_ability,
 	mr_main_reset			=> mr_main_reset,
 	mr_an_enable			=> '1',
 	mr_restart_an			=> mr_restart_an,
 	mr_adv_ability			=> mr_adv_ability
 );

rst_n <= not RESET;

--SYNC_RX_PROC : process(sd_rx_clk)
--begin
--  if rising_edge(sd_rx_clk) then
    FT_RXD_OUT   <= pcs_rx_d;
    FT_RX_EN_OUT <= pcs_rx_dv;
    FT_RX_ER_OUT <= pcs_rx_er;
--  end if;
--end process SYNC_RX_PROC;

u0_reset_controller_pcs : reset_controller_pcs port map(
	rst_n           => rst_n,
	clk             => CLK_125_IN,
	tx_plol         => tx_pll_lol,
	rx_cdr_lol      => rx_cdr_lol,
	quad_rst_out    => quad_rst,
	tx_pcs_rst_out  => tx_pcs_rst,
	rx_pcs_rst_out  => rx_pcs_rst
);

u0_reset_controller_cdr : reset_controller_cdr port map(
	rst_n           => rst_n,
	clk             => CLK_125_IN,
	cdr_lol         => rx_cdr_lol,
	cdr_rst_out     => rx_serdes_rst
);

u0_rate_resolution : rate_resolution port map(
	gbe_mode          => '1',
	sgmii_mode        => '0',
	an_enable         => '1',
	advertised_rate   => mr_adv_ability(11 downto 10),
	link_partner_rate => mr_lp_adv_ability(11 downto 10),
	non_an_rate       => "10", -- 1Gbps is rate when auto-negotiation disabled
                          
	operational_rate  => operational_rate
);

u0_ri : register_interface_hb port map(
	-- Control Signals
	rst_n      => rst_n,
	hclk       => CLK_125_IN,
	gbe_mode   => '1',
	sgmii_mode => '0',
                   
	-- Host Bus
	hcs_n      => '1',
	hwrite_n   => '1',
	haddr      => (others => '0'),
	hdatain    => (others => '0'),
                   
	hdataout   => open,
	hready_n   => open,

	-- Register Outputs
	mr_an_enable   => mr_an_enable,
	mr_restart_an  => mr_restart_an,
	mr_main_reset      => mr_main_reset,
	mr_adv_ability => mr_adv_ability,

	-- Register Inputs
	mr_an_complete     => an_complete,
	mr_page_rx         => mr_page_rx,
	mr_lp_adv_ability  => mr_lp_adv_ability
	);



pcs_mr_reset <= MR_RESET_IN or RESET or user_rst;

FT_TX_CLK_EN_OUT     <= tx_clk_en; -- to MAC
FT_RX_CLK_EN_OUT     <= rx_clk_en; -- to MAC

MR_AN_LP_ABILITY_OUT <= pcs_mr_ability;
MR_AN_COMPLETE_OUT   <= an_complete;
MR_AN_PAGE_RX_OUT    <= pcs_mr_page_rx;

-- Clock games
CLK_125_OUT    <= CLK_125_IN; --sd_tx_clk;
CLK_125_RX_OUT <= sd_rx_clk;

-- Fakes
STAT_OP       <= (others => '0');
SD_TXDIS_OUT  <= '0'; -- enable 
STAT_DEBUG    <= buf_stat_debug;

end architecture;