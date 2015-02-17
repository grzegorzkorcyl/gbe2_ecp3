LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;

entity gbe_med_interface is
	generic (
		DO_SIMULATION : integer range 0 to 1;
		NUMBER_OF_GBE_LINKS : integer range 1 to 4;
		LINKS_ACTIVE : std_logic_vector(3 downto 0)
	);
	port (
		RESET					: in	std_logic;
		GSR_N					: in	std_logic;
		CLK_SYS_IN				: in	std_logic;
		CLK_125_OUT				: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		CLK_125_IN				: in	std_logic;
		CLK_125_RX_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		
		-- MAC status and config
		MAC_READY_CONF_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RECONF_IN			: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_AN_READY_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		
		-- MAC data interface
		MAC_FIFOAVAIL_IN		: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_FIFOEOF_IN			: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_FIFOEMPTY_IN		: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RX_FIFOFULL_IN		: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		
		MAC_TX_DATA_IN			: in	std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
		MAC_TX_READ_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_TX_DISCRFRM_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_TX_STAT_EN_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_TX_STATS_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS * 31 - 1 downto 0);
		MAC_TX_DONE_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);

		MAC_RX_FIFO_ERR_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RX_STATS_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS * 32 - 1 downto 0);
		MAC_RX_DATA_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
		MAC_RX_WRITE_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RX_STAT_EN_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RX_EOF_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		MAC_RX_ERROR_OUT		: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		
		--SFP Connection
		SD_RXD_P_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_RXD_N_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_TXD_P_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_TXD_N_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_PRSNT_N_IN			: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
		SD_LOS_IN				: in	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0); -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
		SD_TXDIS_OUT			: out	std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0); -- SFP disable

		DEBUG_OUT				: out	std_logic_vector(255 downto 0)		
	);
end entity gbe_med_interface;

architecture RTL of gbe_med_interface is
	
	component sgmii_gbe_pcs35
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

component tsmac35 --tsmac36 --tsmac35
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
	
	signal sd_rx_clk : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_tx_kcntl_q, sd_tx_kcntl : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_tx_data_q, sd_tx_data : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal xmit : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_tx_correct_disp_q, sd_tx_correct_disp : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_rx_data, sd_rx_data_q : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal sd_rx_kcntl, sd_rx_kcntl_q  : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_rx_disp_error, sd_rx_disp_error_q : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal sd_rx_cv_error, sd_rx_cv_error_q : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tx_power, rx_power : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal los, signal_detected : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal rx_cdr_lol: std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tx_pll_lol, quad_rst : std_logic;
	signal tx_pcs_rst, rx_pcs_rst, rx_serdes_rst : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	--signal rst_n : std_logic;
	signal rx_clk_en : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tx_clk_en : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal operational_rate : std_logic_vector(NUMBER_OF_GBE_LINKS * 2 - 1 downto 0);
	signal an_complete : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mr_page_rx : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mr_lp_adv_ability : std_logic_vector(NUMBER_OF_GBE_LINKS * 16 - 1 downto 0);
	signal mr_main_reset : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mr_restart_an : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal mr_adv_ability : std_logic_vector(NUMBER_OF_GBE_LINKS * 16 - 1 downto 0);
	signal mr_an_enable : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal pcs_rxd, pcs_rxd_q, pcs_rxd_qq : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal pcs_rx_en, pcs_rx_en_q, pcs_rx_en_qq : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal pcs_rx_er, pcs_rx_er_q, pcs_rx_er_qq : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal pcs_col, pcs_crs : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);  
	signal pcs_txd, pcs_txd_q, pcs_txd_qq : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal pcs_tx_en, pcs_tx_en_q, pcs_tx_en_qq : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal pcs_tx_er, pcs_tx_er_q, pcs_tx_er_qq : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hdataout_en_n : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hready_n : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hread_n : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hwrite_n : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hcs_n : std_logic_vector(NUMBER_OF_GBE_LINKS - 1 downto 0);
	signal tsm_hdata : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	signal tsm_haddr : std_logic_vector(NUMBER_OF_GBE_LINKS * 8 - 1 downto 0);
	
	signal synced_rst, ff : std_logic;
	
begin
	
	rx_power <= "1111";
	tx_power <= "1111";
	
	--rst_n <= not RESET;
	
	reset_sync : process(GSR_N, CLK_SYS_IN)
	begin
		if (GSR_N = '0') then
			ff <= '0';
			synced_rst <= '0';
		elsif rising_edge(CLK_SYS_IN) then
			ff <= '1';
			synced_rst <= ff;
		end if;
	end process reset_sync;
	
	SD_TXDIS_OUT <= "0000";
	
	CLK_125_OUT    <= CLK_125_IN & CLK_125_IN & CLK_125_IN & CLK_125_IN;
	CLK_125_RX_OUT <= sd_rx_clk;
	
	impl_gen : if DO_SIMULATION = 0 generate
		
		gbe_serdes : entity work.serdes_gbe_4ch
		port map(
			------------------
			-- CH0 --
			hdinp_ch0		=> SD_RXD_P_IN(0),
			hdinn_ch0		=> SD_RXD_N_IN(0),
			hdoutp_ch0		=> SD_TXD_P_OUT(0),
			hdoutn_ch0		=> SD_TXD_N_OUT(0),
			rxiclk_ch0		=> sd_rx_clk(0),
			txiclk_ch0		=> CLK_125_IN,
			rx_full_clk_ch0		=> sd_rx_clk(0),
			rx_half_clk_ch0		=> open,
			tx_full_clk_ch0		=> open,
			tx_half_clk_ch0		=> open,
			fpga_rxrefclk_ch0		=> CLK_125_IN,
			txdata_ch0		=> sd_tx_data_q(7 downto 0),
			tx_k_ch0		=> sd_tx_kcntl_q(0),
			xmit_ch0		=> xmit(0),
			tx_disp_correct_ch0		=> sd_tx_correct_disp_q(0),
			rxdata_ch0		=> sd_rx_data(7 downto 0),
			rx_k_ch0		=> sd_rx_kcntl(0),
			rx_disp_err_ch0		=> sd_rx_disp_error(0),
			rx_cv_err_ch0		=> sd_rx_cv_error(0),
		    rx_serdes_rst_ch0_c		=> rx_serdes_rst(0),
			sb_felb_ch0_c		=> '0',
			sb_felb_rst_ch0_c		=> '0',
			tx_pwrup_ch0_c		=> tx_power(0),
			rx_pwrup_ch0_c		=> rx_power(0),
			rx_los_low_ch0_s		=> los(0),
			lsm_status_ch0_s		=> signal_detected(0),
			rx_cdr_lol_ch0_s		=> rx_cdr_lol(0),
			tx_pcs_rst_ch0_c		=> tx_pcs_rst(0),
		    rx_pcs_rst_ch0_c		=> rx_pcs_rst(0),
			-- CH1 --
			hdinp_ch1		=> SD_RXD_P_IN(1),
			hdinn_ch1		=> SD_RXD_N_IN(1),
			hdoutp_ch1		=> SD_TXD_P_OUT(1),
			hdoutn_ch1		=> SD_TXD_N_OUT(1),
			rxiclk_ch1		=> sd_rx_clk(1),
			txiclk_ch1		=> CLK_125_IN,
			rx_full_clk_ch1		=> sd_rx_clk(1),
			rx_half_clk_ch1		=> open,
			tx_full_clk_ch1		=> open,
			tx_half_clk_ch1		=> open,
			fpga_rxrefclk_ch1		=> CLK_125_IN,
			txdata_ch1		=> sd_tx_data_q(15 downto 8),
			tx_k_ch1		=> sd_tx_kcntl_q(1),
			xmit_ch1		=> xmit(1),
			tx_disp_correct_ch1		=> sd_tx_correct_disp_q(1),
			rxdata_ch1		=> sd_rx_data(15 downto 8),
			rx_k_ch1		=> sd_rx_kcntl(1),
			rx_disp_err_ch1		=> sd_rx_disp_error(1),
			rx_cv_err_ch1		=> sd_rx_cv_error(1),
		    rx_serdes_rst_ch1_c		=> rx_serdes_rst(1),
			sb_felb_ch1_c		=> '0',
			sb_felb_rst_ch1_c		=> '0',
			tx_pwrup_ch1_c		=> tx_power(1),
			rx_pwrup_ch1_c		=> rx_power(1),
			rx_los_low_ch1_s		=> los(1),
			lsm_status_ch1_s		=> signal_detected(1),
			rx_cdr_lol_ch1_s		=> rx_cdr_lol(1),
			tx_pcs_rst_ch1_c		=> tx_pcs_rst(1),
		    rx_pcs_rst_ch1_c		=> rx_pcs_rst(1),
			-- CH2 --
			hdinp_ch2		=> SD_RXD_P_IN(2),
			hdinn_ch2		=> SD_RXD_N_IN(2),
			hdoutp_ch2		=> SD_TXD_P_OUT(2),
			hdoutn_ch2		=> SD_TXD_N_OUT(2),
			rxiclk_ch2		=> sd_rx_clk(2),
			txiclk_ch2		=> CLK_125_IN,
			rx_full_clk_ch2		=> sd_rx_clk(2),
			rx_half_clk_ch2		=> open,
			tx_full_clk_ch2		=> open,
			tx_half_clk_ch2		=> open,
			fpga_rxrefclk_ch2		=> CLK_125_IN,
			txdata_ch2		=> sd_tx_data_q(23 downto 16),
			tx_k_ch2		=> sd_tx_kcntl_q(2),
			xmit_ch2		=> xmit(2),
			tx_disp_correct_ch2		=> sd_tx_correct_disp_q(2),
			rxdata_ch2		=> sd_rx_data(23 downto 16),
			rx_k_ch2		=> sd_rx_kcntl(2),
			rx_disp_err_ch2		=> sd_rx_disp_error(2),
			rx_cv_err_ch2		=> sd_rx_cv_error(2),
		    rx_serdes_rst_ch2_c		=> rx_serdes_rst(2),
			sb_felb_ch2_c		=> '0',
			sb_felb_rst_ch2_c		=> '0',
			tx_pwrup_ch2_c		=> tx_power(2),
			rx_pwrup_ch2_c		=> rx_power(2),
			rx_los_low_ch2_s		=> los(2),
			lsm_status_ch2_s		=> signal_detected(2),
			rx_cdr_lol_ch2_s		=> rx_cdr_lol(2),
			tx_pcs_rst_ch2_c		=> tx_pcs_rst(2),
		    rx_pcs_rst_ch2_c		=> rx_pcs_rst(2),
			-- CH3 --
			hdinp_ch3		=> SD_RXD_P_IN(3),
			hdinn_ch3		=> SD_RXD_N_IN(3),
			hdoutp_ch3		=> SD_TXD_P_OUT(3),
			hdoutn_ch3		=> SD_TXD_N_OUT(3),
			rxiclk_ch3		=> sd_rx_clk(3),
			txiclk_ch3		=> CLK_125_IN,
			rx_full_clk_ch3		=> sd_rx_clk(3),
			rx_half_clk_ch3		=> open,
			tx_full_clk_ch3		=> open,
			tx_half_clk_ch3		=> open,
			fpga_rxrefclk_ch3		=> CLK_125_IN,
			txdata_ch3		=> sd_tx_data_q(31 downto 24),
			tx_k_ch3		=> sd_tx_kcntl_q(3),
			xmit_ch3		=> xmit(3),
			tx_disp_correct_ch3		=> sd_tx_correct_disp_q(3),
			rxdata_ch3		=> sd_rx_data(31 downto 24),
			rx_k_ch3		=> sd_rx_kcntl(3),
			rx_disp_err_ch3		=> sd_rx_disp_error(3),
			rx_cv_err_ch3		=> sd_rx_cv_error(3),
		    rx_serdes_rst_ch3_c		=> rx_serdes_rst(3),
			sb_felb_ch3_c		=> '0',
			sb_felb_rst_ch3_c		=> '0',
			tx_pwrup_ch3_c		=> tx_power(3),
			rx_pwrup_ch3_c		=> rx_power(3),
			rx_los_low_ch3_s		=> los(3),
			lsm_status_ch3_s		=> signal_detected(3),
			rx_cdr_lol_ch3_s		=> rx_cdr_lol(3),
			tx_pcs_rst_ch3_c		=> tx_pcs_rst(3),
		    rx_pcs_rst_ch3_c		=> rx_pcs_rst(3),
			---- Miscillaneous ports
			fpga_txrefclk		=> CLK_125_IN,
			tx_serdes_rst_c		=> '0',
			tx_pll_lol_qd_s		=> tx_pll_lol,
			tx_sync_qd_c		=> '0',
			rst_qd_c		=> quad_rst,
		    serdes_rst_qd_c		=> '0'
		);
		
		SYNC_TX_PROC : process(CLK_125_IN)
		begin
			if rising_edge(CLK_125_IN) then
				sd_tx_data_q <= sd_tx_data;
				sd_tx_kcntl_q <= sd_tx_kcntl;
				sd_tx_correct_disp_q <= sd_tx_correct_disp;
			end if;
		end process SYNC_TX_PROC;
		
	
		pcs_gen : for i in 0 to NUMBER_OF_GBE_LINKS - 1 generate
		
			SYNC_RX_PROC : process(sd_rx_clk)
			begin
				if rising_edge(sd_rx_clk(i)) then
					sd_rx_data_q( (i + 1) * 8 - 1 downto i * 8) <= sd_rx_data( (i + 1) * 8 - 1 downto i * 8);
					sd_rx_kcntl_q(i) <= sd_rx_kcntl(i);
					sd_rx_disp_error_q(i) <= sd_rx_disp_error(i);
					sd_rx_cv_error_q(i) <= sd_rx_cv_error(i);
				end if;
			end process SYNC_RX_PROC;	
			
			SGMII_GBE_PCS : sgmii_gbe_pcs35
			port map(
				rst_n					=> synced_rst, --rst_n,
				signal_detect			=> signal_detected(i),
				gbe_mode				=> '1',
				sgmii_mode				=> '0',
				operational_rate		=> operational_rate( (i + 1) * 2 - 1 downto (i * 2)),
				debug_link_timer_short	=> '0',
		 
				force_isolate			=> '0',
				force_loopback			=> '0',
				force_unidir			=> '0',
		 
				rx_compensation_err		=> open,
		 
				ctc_drop_flag			=> open,
				ctc_add_flag			=> open,
				an_link_ok				=> open,
		 
		 	-- MAC interface
				tx_clk_125				=> CLK_125_IN, --refclkcore, -- original clock from SerDes
				tx_clock_enable_source	=> tx_clk_en(i),
				tx_clock_enable_sink	=> tx_clk_en(i),
				tx_d					=> pcs_txd( (i + 1) * 8 - 1 downto i * 8), -- TX data from MAC
				tx_en					=> pcs_tx_en(i), -- TX data enable from MAC
				tx_er					=> pcs_tx_er(i), -- TX error from MAC
				rx_clk_125				=> sd_rx_clk(i),
				rx_clock_enable_source	=> rx_clk_en(i),
				rx_clock_enable_sink	=> rx_clk_en(i),
				rx_d					=> pcs_rxd( (i + 1) * 8 - 1 downto i * 8), -- RX data to MAC
				rx_dv					=> pcs_rx_en(i), -- RX data enable to MAC
				rx_er					=> pcs_rx_er(i), -- RX error to MAC
				col						=> pcs_col(i),
				crs						=> pcs_crs(i),
				
				-- SerDes interface
				tx_data					=> sd_tx_data( (i + 1) * 8 - 1 downto i * 8), -- TX data to SerDes
				tx_kcntl				=> sd_tx_kcntl(i), -- TX komma control to SerDes
				tx_disparity_cntl		=> sd_tx_correct_disp(i), -- idle parity state control in IPG (to SerDes)
		 
				xmit_autoneg 			=> xmit(i),
		 
		 		serdes_recovered_clk	=> sd_rx_clk(i), -- 125MHz recovered from receive bit stream
				rx_data					=> sd_rx_data_q( (i + 1) * 8 - 1 downto i * 8), -- RX data from SerDes
				rx_kcntl				=> sd_rx_kcntl_q(i), -- RX komma control from SerDes
				rx_err_decode_mode		=> '0', -- receive error control mode fixed to normal
				rx_even					=> '0', -- unused (receive error control mode = normal, tie to GND)
				rx_disp_err				=> sd_rx_disp_error_q(i), -- RX disparity error from SerDes
				rx_cv_err				=> sd_rx_cv_error_q(i), -- RX code violation error from SerDes
				-- Autonegotiation stuff
				mr_an_complete			=> an_complete(i),
				mr_page_rx				=> mr_page_rx(i),
				mr_lp_adv_ability		=> mr_lp_adv_ability( (i + 1) * 16 - 1 downto i * 16),
				mr_main_reset			=> mr_main_reset(i),
				mr_an_enable			=> '1',
				mr_restart_an			=> mr_restart_an(i),
				mr_adv_ability			=> mr_adv_ability( (i + 1) * 16 - 1 downto i * 16)
		 	);
		 	
		 	MAC_AN_READY_OUT(i) <= an_complete(i);
		 	
			u0_reset_controller_pcs : reset_controller_pcs port map(
				rst_n           => synced_rst, --rst_n,
				clk             => CLK_125_IN,
				tx_plol         => tx_pll_lol,
				rx_cdr_lol      => rx_cdr_lol(i),
				quad_rst_out    => open, --quad_rst,
				tx_pcs_rst_out  => tx_pcs_rst(i),
				rx_pcs_rst_out  => rx_pcs_rst(i)
			);
			
			u0_reset_controller_cdr : reset_controller_cdr port map(
				rst_n           => synced_rst, --rst_n,
				clk             => CLK_125_IN,
				cdr_lol         => rx_cdr_lol(i),
				cdr_rst_out     => rx_serdes_rst(i)
			);
			
			u0_rate_resolution : rate_resolution port map(
				gbe_mode          => '1',
				sgmii_mode        => '0',
				an_enable         => '1',
				advertised_rate   => mr_adv_ability(i * 16 + 11 downto i * 16 + 10),
				link_partner_rate => mr_lp_adv_ability(i * 16 + 11 downto i * 16 + 10),
				non_an_rate       => "10", -- 1Gbps is rate when auto-negotiation disabled
			                          
				operational_rate  => operational_rate( (i + 1) * 2 - 1 downto i * 2)
			);
			
			u0_ri : register_interface_hb port map(
					-- Control Signals
				rst_n      => synced_rst, --rst_n,
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
				mr_an_enable   => mr_an_enable(i),
				mr_restart_an  => mr_restart_an(i),
				mr_main_reset      => mr_main_reset(i),
				mr_adv_ability => mr_adv_ability( (i + 1 ) * 16 - 1 downto i * 16),
				
				-- Register Inputs
				mr_an_complete     => an_complete(i),
				mr_page_rx         => mr_page_rx(i),
				mr_lp_adv_ability  => mr_lp_adv_ability( (i + 1 ) * 16 - 1 downto i * 16)
			);
			
			MAC: tsmac35
			port map(
			----------------- clock and reset port declarations ------------------
				hclk				=> CLK_SYS_IN,
				txmac_clk			=> CLK_125_IN,
				rxmac_clk			=> sd_rx_clk(i),
				reset_n				=> GSR_N,
				txmac_clk_en		=> '1',
				rxmac_clk_en		=> '1',
			------------------- Input signals to the GMII ----------------
				rxd					=> pcs_rxd_qq( (i + 1) * 8 - 1 downto i * 8),
				rx_dv 				=> pcs_rx_en_qq(i),
				rx_er				=> pcs_rx_er_qq(i),
				col					=> pcs_col(i),
				crs					=> pcs_crs(i),
			-------------------- Input signals to the CPU I/F -------------------
				haddr				=> tsm_haddr( (i + 1) * 8 - 1 downto i * 8),
				hdatain				=> tsm_hdata( (i + 1) * 8 - 1 downto i * 8),
				hcs_n				=> tsm_hcs_n(i),
				hwrite_n			=> tsm_hwrite_n(i),
				hread_n				=> tsm_hread_n(i),
			---------------- Input signals to the Tx MAC FIFO I/F ---------------
				tx_fifodata			=> MAC_TX_DATA_IN( (i + 1) * 8 - 1 downto i * 8),
				tx_fifoavail		=> MAC_FIFOAVAIL_IN(i),
				tx_fifoeof			=> MAC_FIFOEOF_IN(i),
				tx_fifoempty		=> MAC_FIFOEMPTY_IN(i),
				tx_sndpaustim		=> x"0000",
				tx_sndpausreq		=> '0',
				tx_fifoctrl			=> '0',  -- always data frame
			---------------- Input signals to the Rx MAC FIFO I/F --------------- 
				rx_fifo_full		=> MAC_RX_FIFOFULL_IN(i), --'0',
				ignore_pkt			=> '0',
			---------------- Output signals from the GMII -----------------------
				txd					=> pcs_txd( (i + 1) * 8 - 1 downto i * 8),
				tx_en				=> pcs_tx_en(i),
				tx_er				=> pcs_tx_er(i),
			----------------- Output signals from the CPU I/F -------------------
				hdataout			=> open,
				hdataout_en_n		=> tsm_hdataout_en_n(i),
				hready_n			=> tsm_hready_n(i),
				cpu_if_gbit_en		=> open,
			------------- Output signals from the Tx MAC FIFO I/F --------------- 
				tx_macread			=> MAC_TX_READ_OUT(i),
				tx_discfrm			=> MAC_TX_DISCRFRM_OUT(i),
				tx_staten			=> MAC_TX_STAT_EN_OUT(i),
				tx_statvec			=> MAC_TX_STATS_OUT( (i + 1) * 31 - 1 downto i * 31),
				tx_done				=> MAC_TX_DONE_OUT(i),
			------------- Output signals from the Rx MAC FIFO I/F ---------------   
				rx_fifo_error		=> MAC_RX_FIFO_ERR_OUT(i),
				rx_stat_vector		=> MAC_RX_STATS_OUT( (i + 1) * 32 - 1 downto i * 32),
				rx_dbout			=> MAC_RX_DATA_OUT( (i + 1) * 8 - 1 downto i * 8),
				rx_write			=> MAC_RX_WRITE_OUT(i),
				rx_stat_en			=> MAC_RX_STAT_EN_OUT(i),
				rx_eof				=> MAC_RX_EOF_OUT(i),
				rx_error			=> MAC_RX_ERROR_OUT(i)
			);
			
			TSMAC_CONTROLLER : trb_net16_gbe_mac_control
			port map(
				CLK				=> CLK_SYS_IN,
				RESET			=> RESET, 
				
			-- signals to/from main controller
				MC_TSMAC_READY_OUT	=> MAC_READY_CONF_OUT(i),
				MC_RECONF_IN		=> MAC_RECONF_IN(i),
				MC_GBE_EN_IN		=> '1',
				MC_RX_DISCARD_FCS	=> '0',
				MC_PROMISC_IN		=> '1',
				MC_MAC_ADDR_IN		=> (others => '0'),
			
			-- signal to/from Host interface of TriSpeed MAC
				TSM_HADDR_OUT		=> tsm_haddr( (i + 1) * 8 - 1 downto i * 8),
				TSM_HDATA_OUT		=> tsm_hdata( (i + 1) * 8 - 1 downto i * 8),
				TSM_HCS_N_OUT		=> tsm_hcs_n(i),
				TSM_HWRITE_N_OUT	=> tsm_hwrite_n(i),
				TSM_HREAD_N_OUT		=> tsm_hread_n(i),
				TSM_HREADY_N_IN		=> tsm_hready_n(i),
				TSM_HDATA_EN_N_IN	=> tsm_hdataout_en_n(i),
			
				DEBUG_OUT		=> open
			);
			
			SYNC_GMII_RX_PROC : process(sd_rx_clk)
			begin
				if rising_edge(sd_rx_clk(i)) then
					pcs_rxd_q( (i + 1) * 8 - 1 downto i * 8)   <= pcs_rxd( (i + 1) * 8 - 1 downto i * 8);
					pcs_rx_en_q(i) <= pcs_rx_en(i);
					pcs_rx_er_q(i) <= pcs_rx_er(i);
					
					pcs_rxd_qq( (i + 1) * 8 - 1 downto i * 8)   <= pcs_rxd_q( (i + 1) * 8 - 1 downto i * 8);
					pcs_rx_en_qq(i) <= pcs_rx_en_q(i);
					pcs_rx_er_qq(i) <= pcs_rx_er_q(i);
				end if;
			end process SYNC_GMII_RX_PROC;
			
			SYNC_GMII_TX_PROC : process(CLK_125_IN)
			begin
				if rising_edge(CLK_125_IN) then
					pcs_txd_q( (i + 1) * 8 - 1 downto i * 8)   <= pcs_txd( (i + 1) * 8 - 1 downto i * 8);
					pcs_tx_en_q <= pcs_tx_en;
					pcs_tx_er_q <= pcs_tx_er;
					
					pcs_txd_qq( (i + 1) * 8 - 1 downto i * 8)   <= pcs_txd_q( (i + 1) * 8 - 1 downto i * 8);
					pcs_tx_en_qq <= pcs_tx_en_q;
					pcs_tx_er_qq <= pcs_tx_er_q; 
				end if;
			end process SYNC_GMII_TX_PROC;
		 	
		end generate pcs_gen;
		
	end generate impl_gen;

	sim_gen : if DO_SIMULATION =  1 generate
		
		process
		begin
			
			MAC_AN_READY_OUT <= (others => '0');
			wait for 2 us;
			MAC_AN_READY_OUT <= (others => '1');
			
			wait;
		end process;
		
		process(CLK_125_IN)
		begin
			if rising_edge(CLK_125_IN) then
				MAC_TX_READ_OUT <= MAC_FIFOAVAIL_IN;
				
				MAC_TX_DONE_OUT <= MAC_FIFOEOF_IN;
			end if;
		end process;
		
		
	end generate sim_gen;
	

end architecture RTL;
