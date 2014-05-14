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

ENTITY aa_tb_dummy IS
END aa_tb_dummy;

ARCHITECTURE behavior OF aa_tb_dummy IS
	
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

component trb_net16_gbe_buf is
generic( 
	DO_SIMULATION		: integer range 0 to 1 := 1;
	RX_PATH_ENABLE      : integer range 0 to 1 := 1;
	USE_INTERNAL_TRBNET_DUMMY : integer range 0 to 1 := 0;
	USE_125MHZ_EXTCLK       : integer range 0 to 1 := 1;
		
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		FIXED_DELAY : integer range 0 to 65535 := 4096
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
	LED_GBE_READY_OUT            : out std_logic;
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
SIGNAL FEE_STATUS_BITS_IN :  std_logic_vector(31 downto 0);
SIGNAL FEE_BUSY_IN :  std_logic;


signal ft_data : std_logic_vector(8 downto 0);
signal ft_tx_empty, ft_start_of_packet : std_logic;

signal mac_tx_done, mac_fifoeof : std_logic;
signal gbe_ready, gsr : std_logic;

begin
	
	gsr <= not reset;
	
buf : trb_net16_gbe_buf
generic map( 
	DO_SIMULATION		=> 1,
	RX_PATH_ENABLE      => 1,
	USE_INTERNAL_TRBNET_DUMMY => 1,
	USE_125MHZ_EXTCLK       => 0,
	
		FIXED_SIZE_MODE => 0,
		FIXED_SIZE => 10,
		FIXED_DELAY_MODE => 1,
		FIXED_DELAY => 100
)
port map(
	CLK							=> clk,
	TEST_CLK					=> RX_MAC_CLK,
	CLK_125_IN				=> RX_MAC_CLK,
	RESET						=> reset,
	GSR_N						=> gsr,
	-- Debug
	STAGE_STAT_REGS_OUT			=> open,
	STAGE_CTRL_REGS_IN			=> (others => '0'),
	-- configuration interface
	IP_CFG_START_IN				=> '0',
	IP_CFG_BANK_SEL_IN			=> (others => '0'),
	IP_CFG_DONE_OUT				=> open,
	IP_CFG_MEM_ADDR_OUT			=> open,
	IP_CFG_MEM_DATA_IN			=> (others => '0'),
	IP_CFG_MEM_CLK_OUT			=> open,
	MR_RESET_IN					=> '0',
	MR_MODE_IN					=> '0',
	MR_RESTART_IN				=> '0',
	-- gk 29.03.10
	SLV_ADDR_IN                  => (others => '0'),
	SLV_READ_IN                  => '0',
	SLV_WRITE_IN                 => '0',
	SLV_BUSY_OUT                 => open,
	SLV_ACK_OUT                  => open,
	SLV_DATA_IN                  => (others => '0'),
	SLV_DATA_OUT                 => open,
	-- gk 22.04.10
	-- registers setup interface
	BUS_ADDR_IN               => (others => '0'),
	BUS_DATA_IN               => (others => '0'),
	BUS_DATA_OUT              => open,
	BUS_WRITE_EN_IN           => '0',
	BUS_READ_EN_IN            => '0',
	BUS_ACK_OUT               => open,
	-- gk 23.04.10
	LED_PACKET_SENT_OUT         => open,
	LED_GBE_READY_OUT           => gbe_ready,
	-- CTS interface
	CTS_NUMBER_IN				=> cts_number_in,            
	CTS_CODE_IN					=> cts_code_in,              
	CTS_INFORMATION_IN			=> cts_information_in,       
	CTS_READOUT_TYPE_IN			=> cts_readout_type_in,      
	CTS_START_READOUT_IN		=> cts_start_readout_in,     
	CTS_DATA_OUT				=> cts_data_out,             
	CTS_DATAREADY_OUT			=> cts_dataready_out,        
	CTS_READOUT_FINISHED_OUT	=> cts_readout_finished_out, 
	CTS_READ_IN					=> cts_read_in,              
	CTS_LENGTH_OUT				=> cts_length_out,           
	CTS_ERROR_PATTERN_OUT		=> cts_error_pattern_out,    
	-- Data payload interface
	FEE_DATA_IN					 => fee_data_in,             
	FEE_DATAREADY_IN			 => fee_dataready_in,        
	FEE_READ_OUT				 => fee_read_out,            
	FEE_STATUS_BITS_IN			 => fee_status_bits_in,      
	FEE_BUSY_IN					 => fee_busy_in,  
	--SFP Connection
	SFP_RXD_P_IN				=> '0',
	SFP_RXD_N_IN				=> '0',
	SFP_TXD_P_OUT				=> open,
	SFP_TXD_N_OUT				=> open,
	SFP_REFCLK_P_IN				=> '0',
	SFP_REFCLK_N_IN				=> '0',
	SFP_PRSNT_N_IN				=> '0',
	SFP_LOS_IN					=> '0',
	SFP_TXDIS_OUT				=> open,
	
	-- interface between main_controller and hub logic
	MC_UNIQUE_ID_IN          => (others => '0'),		
	GSC_CLK_IN               => clk,
	GSC_INIT_DATAREADY_OUT   => open,
	GSC_INIT_DATA_OUT        => open,
	GSC_INIT_PACKET_NUM_OUT  => open,
	GSC_INIT_READ_IN         => '0',
	GSC_REPLY_DATAREADY_IN  => '0',
	GSC_REPLY_DATA_IN        => (others => '0'),
	GSC_REPLY_PACKET_NUM_IN  => (others => '0'),
	GSC_REPLY_READ_OUT       => open,
	GSC_BUSY_IN             => '0',
	
	MAKE_RESET_OUT           => open,

	-- for simulation of receiving part only
	MAC_RX_EOF_IN		=> '0',
	MAC_RXD_IN		=> (others => '0'),
	MAC_RX_EN_IN		=> '0',


	-- debug ports
	ANALYZER_DEBUG_OUT			=> open
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

testbench_proc : process
begin
	reset <= '1'; 

	wait for 100 ns;
	reset <= '0';
	
	wait for 100 ns;


	wait;

end process testbench_proc;

end; 