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

ENTITY aa_wrapper_tb IS
END aa_wrapper_tb;

ARCHITECTURE behavior OF aa_wrapper_tb IS
	
	component gbe_ipu_dummy is
	generic (DO_SIMULATION : integer range 0 to 1 := 0);
	port (
		clk : in std_logic;
		rst : in std_logic;
		GBE_READY_IN : in std_logic;
		
		CTS_NUMBER_OUT				: out	std_logic_vector (15 downto 0);
		CTS_CODE_OUT					: out	std_logic_vector (7  downto 0);
		CTS_INFORMATION_OUT			: out	std_logic_vector (7  downto 0);
		CTS_READOUT_TYPE_OUT			: out	std_logic_vector (3  downto 0);
		CTS_START_READOUT_OUT		: out	std_logic;
		CTS_DATA_IN				: in	std_logic_vector (31 downto 0);
		CTS_DATAREADY_IN			: in	std_logic;
		CTS_READOUT_FINISHED_IN	: in	std_logic;
		CTS_READ_OUT					: out	std_logic;
		CTS_LENGTH_IN				: in	std_logic_vector (15 downto 0);
		CTS_ERROR_PATTERN_IN		: in	std_logic_vector (31 downto 0);
		-- Data payload interface
		FEE_DATA_OUT					: out	std_logic_vector (15 downto 0);
		FEE_DATAREADY_OUT			: out	std_logic;
		FEE_READ_IN				: in	std_logic;
		FEE_STATUS_BITS_OUT			: out	std_logic_vector (31 downto 0);
		FEE_BUSY_OUT					: out	std_logic
	);
end component;

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
signal ps_proto, ps_busy : std_logic_vector(4 downto 0);
signal ps_frame_size : std_logic_vector(15 downto 0);

signal gsc_reply_dataready, gsc_busy : std_logic;
signal gsc_reply_data : std_logic_vector(15 downto 0);

SIGNAL CTS_NUMBER_IN :  std_logic_vector(15 downto 0);
SIGNAL CTS_CODE_IN :  std_logic_vector(7 downto 0);
SIGNAL CTS_INFORMATION_IN :  std_logic_vector(7 downto 0);
SIGNAL CTS_READOUT_TYPE_IN :  std_logic_vector(3 downto 0);
SIGNAL CTS_START_READOUT_IN :  std_logic;
SIGNAL CTS_DATA_OUT :  std_logic_vector(31 downto 0);
SIGNAL CTS_DATAREADY_OUT :  std_logic;
SIGNAL CTS_READOUT_FINISHED_OUT :  std_logic;
SIGNAL CTS_READ_IN :  std_logic;
SIGNAL CTS_LENGTH_OUT :  std_logic_vector(15 downto 0);
SIGNAL CTS_ERROR_PATTERN_OUT :  std_logic_vector(31 downto 0);
SIGNAL FEE_DATA_IN :  std_logic_vector(15 downto 0);
SIGNAL FEE_DATAREADY_IN :  std_logic;
SIGNAL FEE_READ_OUT :  std_logic;
SIGNAL FEE_STATUS_BITS_IN :  std_logic_vector(31 downto 0) := x"0000_0000";
SIGNAL FEE_BUSY_IN :  std_logic;


signal ft_data : std_logic_vector(8 downto 0);
signal ft_tx_empty, ft_start_of_packet : std_logic;

signal mac_tx_done, mac_fifoeof : std_logic;
signal gbe_ready, gsr : std_logic;

	signal MAC_RX_EOF_IN, MAC_RX_EN_IN : std_logic;
	signal MAC_RXD_IN : std_logic_vector(7 downto 0);
	signal mac_read : std_logic;
	signal mac_fifoavail : std_logic;

begin
	
	gsr <= not reset;
	
--buf : trb_net16_gbe_buf
--generic map( 
--	DO_SIMULATION		=> 1,
--	RX_PATH_ENABLE      => 1,
--	USE_INTERNAL_TRBNET_DUMMY => 1,
--	USE_125MHZ_EXTCLK       => 0,
--	
--		FIXED_SIZE_MODE => 0,
--		INCREMENTAL_MODE => 1,
--		FIXED_SIZE => 100, --13750, --325, --335, --20000, --8832, --5000, --10000, --10, --335
--		UP_DOWN_MODE => 1,
--		UP_DOWN_LIMIT => 120, --17500, --330,
--		FIXED_DELAY_MODE => 1,
--		FIXED_DELAY => 16777215 --4096
--)
--port map(
--	CLK							=> clk,
--	TEST_CLK					=> RX_MAC_CLK,
--	CLK_125_IN				=> RX_MAC_CLK,
--	RESET						=> reset,
--	GSR_N						=> gsr,
--	-- Debug
--	STAGE_STAT_REGS_OUT			=> open,
--	STAGE_CTRL_REGS_IN			=> (others => '0'),
--	-- configuration interface
--	IP_CFG_START_IN				=> '0',
--	IP_CFG_BANK_SEL_IN			=> (others => '0'),
--	IP_CFG_DONE_OUT				=> open,
--	IP_CFG_MEM_ADDR_OUT			=> open,
--	IP_CFG_MEM_DATA_IN			=> (others => '0'),
--	IP_CFG_MEM_CLK_OUT			=> open,
--	MR_RESET_IN					=> '0',
--	MR_MODE_IN					=> '0',
--	MR_RESTART_IN				=> '0',
--	-- gk 29.03.10
--	SLV_ADDR_IN                  => (others => '0'),
--	SLV_READ_IN                  => '0',
--	SLV_WRITE_IN                 => '0',
--	SLV_BUSY_OUT                 => open,
--	SLV_ACK_OUT                  => open,
--	SLV_DATA_IN                  => (others => '0'),
--	SLV_DATA_OUT                 => open,
--	-- gk 22.04.10
--	-- registers setup interface
--	BUS_ADDR_IN               => (others => '0'),
--	BUS_DATA_IN               => (others => '0'),
--	BUS_DATA_OUT              => open,
--	BUS_WRITE_EN_IN           => '0',
--	BUS_READ_EN_IN            => '0',
--	BUS_ACK_OUT               => open,
--	-- gk 23.04.10
--	LED_PACKET_SENT_OUT         => open,
--	LED_AN_DONE_N_OUT           => gbe_ready,
--	-- CTS interface
--	CTS_NUMBER_IN				=> cts_number_in,            
--	CTS_CODE_IN					=> cts_code_in,              
--	CTS_INFORMATION_IN			=> cts_information_in,       
--	CTS_READOUT_TYPE_IN			=> cts_readout_type_in,      
--	CTS_START_READOUT_IN		=> cts_start_readout_in,     
--	CTS_DATA_OUT				=> cts_data_out,             
--	CTS_DATAREADY_OUT			=> cts_dataready_out,        
--	CTS_READOUT_FINISHED_OUT	=> cts_readout_finished_out, 
--	CTS_READ_IN					=> cts_read_in,              
--	CTS_LENGTH_OUT				=> cts_length_out,           
--	CTS_ERROR_PATTERN_OUT		=> cts_error_pattern_out,    
--	-- Data payload interface
--	FEE_DATA_IN					 => fee_data_in,             
--	FEE_DATAREADY_IN			 => fee_dataready_in,        
--	FEE_READ_OUT				 => fee_read_out,            
--	FEE_STATUS_BITS_IN			 => fee_status_bits_in,      
--	FEE_BUSY_IN					 => fee_busy_in,  
--	--SFP Connection
--	SFP_RXD_P_IN				=> '0',
--	SFP_RXD_N_IN				=> '0',
--	SFP_TXD_P_OUT				=> open,
--	SFP_TXD_N_OUT				=> open,
--	SFP_REFCLK_P_IN				=> '0',
--	SFP_REFCLK_N_IN				=> '0',
--	SFP_PRSNT_N_IN				=> '0',
--	SFP_LOS_IN					=> '0',
--	SFP_TXDIS_OUT				=> open,
--	
--	-- interface between main_controller and hub logic
--	MC_UNIQUE_ID_IN          => (others => '0'),		
--	GSC_CLK_IN               => clk,
--	GSC_INIT_DATAREADY_OUT   => open,
--	GSC_INIT_DATA_OUT        => open,
--	GSC_INIT_PACKET_NUM_OUT  => open,
--	GSC_INIT_READ_IN         => '0',
--	GSC_REPLY_DATAREADY_IN  => '0',
--	GSC_REPLY_DATA_IN        => (others => '0'),
--	GSC_REPLY_PACKET_NUM_IN  => (others => '0'),
--	GSC_REPLY_READ_OUT       => open,
--	GSC_BUSY_IN             => '0',
--	
--	MAKE_RESET_OUT           => open,
--
--	-- for simulation of receiving part only
--	MAC_RX_EOF_IN		=> MAC_RX_EOF_IN,
--	MAC_RXD_IN		=> MAC_RXD_IN,
--	MAC_RX_EN_IN		=> MAC_RX_EN_IN,
--
--
--	-- debug ports
--	ANALYZER_DEBUG_OUT			=> open
--);

	gbe_inst1 : entity work.gbe_logic_wrapper
	generic map(DO_SIMULATION             => 1,
		        INCLUDE_DEBUG             => 0,
		        USE_INTERNAL_TRBNET_DUMMY => 1,
		        RX_PATH_ENABLE            => 1,
		        FIXED_SIZE_MODE           => 0,
		        INCREMENTAL_MODE          => 1,
		        FIXED_SIZE                => 100,
		        FIXED_DELAY_MODE          => 1,
		        UP_DOWN_MODE              => 1,
		        UP_DOWN_LIMIT             => 120,
		        FIXED_DELAY               => 16777215)
	port map(
			 CLK_SYS_IN               => clk,
		     CLK_125_IN               => RX_MAC_CLK,
		     CLK_RX_125_IN            => RX_MAC_CLK,
		     RESET                    => RESET,
		     GSR_N                    => gsr,
		     
		     MAC_READY_CONF_IN        => '1',
		     MAC_RECONF_OUT           => open,
		     MAC_AN_READY_IN		  => '1',
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail,
		     MAC_FIFOEOF_OUT          => mac_fifoeof,
		     MAC_FIFOEMPTY_OUT        => open,
		     MAC_RX_FIFOFULL_OUT      => open,
		     MAC_TX_DATA_OUT          => open,
		     MAC_TX_READ_IN           => mac_read,
		     MAC_TX_DISCRFRM_IN       => '0',
		     MAC_TX_STAT_EN_IN        => '0',
		     MAC_TX_STATS_IN          => (others => '0'),
		     MAC_TX_DONE_IN           => mac_tx_done,
		     MAC_RX_FIFO_ERR_IN       => '0',
		     MAC_RX_STATS_IN          => (others => '0'),
		     MAC_RX_DATA_IN           => MAC_RXD_IN,
		     MAC_RX_WRITE_IN          => MAC_RX_EN_IN,
		     MAC_RX_STAT_EN_IN        => '0',
		     MAC_RX_EOF_IN            => MAC_RX_EOF_IN,
		     MAC_RX_ERROR_IN          => '0',
		     
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
		     
		     MC_UNIQUE_ID_IN          => (others => '0'),
		     
		     GSC_CLK_IN               => clk,
		     GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,
		     GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,
		     GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,
		     GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,
		     GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,
		     GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,
		     GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
		     GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,
		     GSC_BUSY_IN              => '0', --GSC_BUSY_IN,
		     
		     SLV_ADDR_IN              => (others => '0'), --SLV_ADDR_IN,
		     SLV_READ_IN              => '0', --SLV_READ_IN,
		     SLV_WRITE_IN             => '0', --SLV_WRITE_IN,
		     SLV_BUSY_OUT             => open, --SLV_BUSY_OUT,
		     SLV_ACK_OUT              => open, --SLV_ACK_OUT,
		     SLV_DATA_IN              => (others => '0'), --SLV_DATA_IN,
		     SLV_DATA_OUT             => open, --SLV_DATA_OUT,
		     
		     CFG_GBE_ENABLE_IN        => '1',
		     CFG_IPU_ENABLE_IN        => '0',
		     CFG_MULT_ENABLE_IN       => '0',
		     CFG_MAX_FRAME_IN         => x"0578",
		     CFG_ALLOW_RX_IN		  => '1',
		     CFG_SOFT_RESET_IN		  => '0',
		     CFG_SUBEVENT_ID_IN       => (others => '0'),
		     CFG_SUBEVENT_DEC_IN      => (others => '0'),
		     CFG_QUEUE_DEC_IN         => (others => '0'),
		     CFG_READOUT_CTR_IN       => (others => '0'),
		     CFG_READOUT_CTR_VALID_IN => '0',
		     CFG_INSERT_TTYPE_IN      => '0',
		     CFG_MAX_SUB_IN           => x"0578",
		     CFG_MAX_QUEUE_IN         => x"1000",
		     CFG_MAX_SUBS_IN_QUEUE_IN => x"0002",
		     CFG_MAX_SINGLE_SUB_IN    => x"0578",
		     CFG_ADDITIONAL_HDR_IN    => '0',
		     
		     MAKE_RESET_OUT           => open
		);

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


process
begin

	mac_tx_done <= '0';
	wait until rising_edge(mac_fifoeof);
	wait until rising_edge(rx_mac_clk);
	mac_tx_done <= '1';
	wait until rising_edge(rx_mac_clk);
end process;

process(rx_mac_clk)
begin
	if rising_edge(rx_mac_clk) then
		mac_read <= mac_fifoavail;
	end if;
end process;
	

testbench_proc : process
begin
	reset <= '1'; 
	
	MAC_RX_EN_IN <= '0';
	MAC_RXD_IN <= x"00";
	MAC_RX_EOF_IN <= '0';

	wait for 100 ns;
	reset <= '0';
	
	wait for 5 us;

-- FIRST FRAME UDP - DHCP Offer
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(RX_MAC_CLK);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"11";  -- udp
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
-- udp headers
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"43";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"44";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"2c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
-- dhcp data
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"06";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";  --transcation id
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";--transcation id
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"fa";--transcation id
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ce";--transcation id
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	
	for i in 0 to 219 loop
		wait until rising_edge(RX_MAC_CLK);
		MAC_RXD_IN		<= x"00";
	end loop;
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"35";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
		MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	wait for 6 us;
	
		wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(RX_MAC_CLK);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"11";  -- udp
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
-- udp headers
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"43";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"44";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"2c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
-- dhcp data
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"06";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"fa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ce";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	
	for i in 0 to 219 loop
		wait until rising_edge(RX_MAC_CLK);
		MAC_RXD_IN		<= x"00";
	end loop;
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"35";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"05";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
		MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	
	wait for 5 us;
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(RX_MAC_CLK);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
-- ping headers
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"47";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"d3";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"3c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
-- ping data
	MAC_RXD_IN		<= x"8c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"da";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"e7";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"4d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"36";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c4";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"09";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0b";	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0e";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0f";
	wait until rising_edge(RX_MAC_CLK);
		MAC_RX_EOF_IN <= '1';
			MAC_RXD_IN		<= x"aa";
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
		
	
	wait for 15 us;
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(RX_MAC_CLK);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"02";
-- ping headers
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"47";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"d3";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"3c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(RX_MAC_CLK);
-- ping data
	MAC_RXD_IN		<= x"8c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"da";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"e7";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"4d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"36";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"c4";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"09";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0a";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0b";	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0c";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0d";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0e";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"0f";
	wait until rising_edge(RX_MAC_CLK);
		MAC_RX_EOF_IN <= '1';
			MAC_RXD_IN		<= x"aa";
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	wait for 8 us;
	
	
--	for i in 0 to 100 loop
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RX_EN_IN <= '1';
--	-- dest mac
--		MAC_RXD_IN		<= x"02";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"be";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--	-- src mac
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"aa";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"bb";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"cc";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"dd";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"ee";
--		wait until rising_edge(RX_MAC_CLK);
--	-- frame type
--		MAC_RXD_IN		<= x"08";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--	-- ip headers
--		MAC_RXD_IN		<= x"45";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"10";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"01";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"5a";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"49";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"ff";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"01";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"cc";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"cc";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"c0";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"a8";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"01";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"c0";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"a8";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"02";
--	-- ping headers
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"08";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"47";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"d3";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0d";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"3c";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"01";
--		wait until rising_edge(RX_MAC_CLK);
--	-- ping data
--		MAC_RXD_IN		<= x"8c";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"da";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"e7";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"4d";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"36";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"c4";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0d";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"00";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"08";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"09";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0a";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0b";	
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0c";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0d";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0e";
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RXD_IN		<= x"0f";
--		wait until rising_edge(RX_MAC_CLK);
--			MAC_RX_EOF_IN <= '1';
--				MAC_RXD_IN		<= x"aa";
--		
--		wait until rising_edge(RX_MAC_CLK);
--		MAC_RX_EN_IN <='0';
--		MAC_RX_EOF_IN <= '0';
--		
--		wait for 50 us;
--		
--	end loop;
	
	wait;

end process testbench_proc;

end; 