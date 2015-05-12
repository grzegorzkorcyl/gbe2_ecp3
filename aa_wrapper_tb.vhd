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
	generic(NUMBER_OF_OUTPUT_LINKS : integer range 0 to 4 := 2);
END aa_wrapper_tb;

ARCHITECTURE behavior OF aa_wrapper_tb IS
	
	component gbe_ipu_dummy is
	generic (DO_SIMULATION : integer range 0 to 1 := 0);
	port (
		clk : in std_logic;
		rst : in std_logic;
		GBE_READY_IN : in std_logic;
		
		CFG_EVENT_SIZE_IN : in std_logic_vector(15 downto 0);
		CFG_TRIGGERED_MODE_IN : in std_logic;
		TRIGGER_IN : in std_logic;
		
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


signal mac_tx_done, mac_fifoeof : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
signal gsr : std_logic;

signal MAC_RX_EOF_IN, MAC_RX_EN_IN : std_logic;
signal MAC_RXD_IN : std_logic_vector(7 downto 0);
signal mac_read : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
signal mac_fifoavail : std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
signal master_mac : std_logic_vector(47 downto 0);

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
signal gbe_ready : std_logic;
signal trigger : std_logic;

begin
	
	gsr <= not reset;


	gbe_inst1 : entity work.gbe_logic_wrapper
	generic map(
		DO_SIMULATION             => 1,
        INCLUDE_DEBUG             => 1,
        USE_INTERNAL_TRBNET_DUMMY => 0,
        RX_PATH_ENABLE            => 1,
        
        INCLUDE_READOUT		=> '1',
		INCLUDE_SLOWCTRL	=> '1',
		INCLUDE_DHCP		=> '1',
		INCLUDE_ARP			=> '1',
		INCLUDE_PING		=> '1',
		
        FRAME_BUFFER_SIZE	 => 1,
		READOUT_BUFFER_SIZE  => 2,
		SLOWCTRL_BUFFER_SIZE => 2,
		
        FIXED_SIZE_MODE           => 1,
        INCREMENTAL_MODE          => 1,
        FIXED_SIZE                => 100,
        FIXED_DELAY_MODE          => 1,
        UP_DOWN_MODE              => 1,
        UP_DOWN_LIMIT             => 200,
        FIXED_DELAY               => 1
	)
	port map(
			 CLK_SYS_IN               => clk,
		     CLK_125_IN               => RX_MAC_CLK,
		     CLK_RX_125_IN            => RX_MAC_CLK,
		     RESET                    => RESET,
		     GSR_N                    => gsr,
		     
		     MY_MAC_OUT => master_mac,
			 MY_MAC_IN  => x"ffffffffffff",
		     
		     MAC_READY_CONF_IN        => '1',
		     MAC_RECONF_OUT           => open,
		     MAC_AN_READY_IN		  => '1',
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(0),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(0),
		     MAC_FIFOEMPTY_OUT        => open,
		     MAC_RX_FIFOFULL_OUT      => open,
		     MAC_TX_DATA_OUT          => open,
		     MAC_TX_READ_IN           => mac_read(0),
		     MAC_TX_DISCRFRM_IN       => '0',
		     MAC_TX_STAT_EN_IN        => '0',
		     MAC_TX_STATS_IN          => (others => '0'),
		     MAC_TX_DONE_IN           => mac_tx_done(0),
		     MAC_RX_FIFO_ERR_IN       => '0',
		     MAC_RX_STATS_IN          => (others => '0'),
		     MAC_RX_DATA_IN           => MAC_RXD_IN,
		     MAC_RX_WRITE_IN          => MAC_RX_EN_IN,
		     MAC_RX_STAT_EN_IN        => '0',
		     MAC_RX_EOF_IN            => MAC_RX_EOF_IN,
		     MAC_RX_ERROR_IN          => '0',
		     
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
		     CFG_MAX_REPLY_SIZE_IN	  => x"0000_fa00",
		     
		     MAKE_RESET_OUT           => open
		);
		
	gbe_inst2 : entity work.gbe_logic_wrapper
	generic map(
		DO_SIMULATION             => 1,
        INCLUDE_DEBUG             => 1,
        USE_INTERNAL_TRBNET_DUMMY => 0,
        RX_PATH_ENABLE            => 1,
        
        INCLUDE_READOUT		=> '1',
		INCLUDE_SLOWCTRL	=> '0',
		INCLUDE_DHCP		=> '0',
		INCLUDE_ARP			=> '0',
		INCLUDE_PING		=> '0',
		
        FRAME_BUFFER_SIZE	 => 1,
		READOUT_BUFFER_SIZE  => 2,
		SLOWCTRL_BUFFER_SIZE => 2,
		
        FIXED_SIZE_MODE           => 1,
        INCREMENTAL_MODE          => 1,
        FIXED_SIZE                => 100,
        FIXED_DELAY_MODE          => 1,
        UP_DOWN_MODE              => 1,
        UP_DOWN_LIMIT             => 200,
        FIXED_DELAY               => 1
        )
	port map(
			 CLK_SYS_IN               => clk,
		     CLK_125_IN               => RX_MAC_CLK,
		     CLK_RX_125_IN            => RX_MAC_CLK,
		     RESET                    => RESET,
		     GSR_N                    => gsr,
		     
		     MY_MAC_OUT => open,
			 MY_MAC_IN  => x"ffffffffffff",
		     
		     MAC_READY_CONF_IN        => '1',
		     MAC_RECONF_OUT           => open,
		     MAC_AN_READY_IN		  => '1',
		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(1),
		     MAC_FIFOEOF_OUT          => mac_fifoeof(1),
		     MAC_FIFOEMPTY_OUT        => open,
		     MAC_RX_FIFOFULL_OUT      => open,
		     MAC_TX_DATA_OUT          => open,
		     MAC_TX_READ_IN           => mac_read(1),
		     MAC_TX_DISCRFRM_IN       => '0',
		     MAC_TX_STAT_EN_IN        => '0',
		     MAC_TX_STATS_IN          => (others => '0'),
		     MAC_TX_DONE_IN           => mac_tx_done(1),
		     MAC_RX_FIFO_ERR_IN       => '0',
		     MAC_RX_STATS_IN          => (others => '0'),
		     MAC_RX_DATA_IN           => MAC_RXD_IN,
		     MAC_RX_WRITE_IN          => MAC_RX_EN_IN,
		     MAC_RX_STAT_EN_IN        => '0',
		     MAC_RX_EOF_IN            => MAC_RX_EOF_IN,
		     MAC_RX_ERROR_IN          => '0',
		     
		     CTS_NUMBER_IN            => mlt_cts_number(2 * 16 - 1 downto 1 * 16),		   
		     CTS_CODE_IN              => mlt_cts_code(2 * 8 - 1 downto 1 * 8),	           
		     CTS_INFORMATION_IN       => mlt_cts_information(2 * 8 - 1 downto 1 * 8),	   
		     CTS_READOUT_TYPE_IN      => mlt_cts_readout_type(2 * 4 - 1 downto 1 * 4),     
		     CTS_START_READOUT_IN     => mlt_cts_start_readout(1),                         
		     CTS_DATA_OUT             => mlt_cts_data(2 * 32 - 1 downto 1 * 32),			
		     CTS_DATAREADY_OUT        => mlt_cts_dataready(1),	                           
		     CTS_READOUT_FINISHED_OUT => mlt_cts_readout_finished(1),                      
		     CTS_READ_IN              => mlt_cts_read(1),		                           
		     CTS_LENGTH_OUT           => mlt_cts_length(2 * 16 - 1 downto 1 * 16),		   
		     CTS_ERROR_PATTERN_OUT    => mlt_cts_error_pattern(2 * 32 - 1 downto 1 * 32),  
		     FEE_DATA_IN              => mlt_fee_data(2 * 16 - 1 downto 1 * 16),		   
		     FEE_DATAREADY_IN         => mlt_fee_dataready(1),	                           
		     FEE_READ_OUT             => mlt_fee_read(1),			                       
		     FEE_STATUS_BITS_IN       => mlt_fee_status(2 * 32 - 1 downto 1 * 32),	       
		     FEE_BUSY_IN              => mlt_fee_busy(1),                                  
		     
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
		     CFG_MAX_REPLY_SIZE_IN    => x"0000_fa00",
		     
		     MAKE_RESET_OUT           => open
		);
-- 		
-- 	gbe_inst3 : entity work.gbe_logic_wrapper
-- 	generic map(
-- 		DO_SIMULATION             => 1,
--         INCLUDE_DEBUG             => 1,
--         USE_INTERNAL_TRBNET_DUMMY => 0,
--         RX_PATH_ENABLE            => 1,
--         
--         INCLUDE_READOUT		=> '1',
-- 		INCLUDE_SLOWCTRL	=> '0',
-- 		INCLUDE_DHCP		=> '1',
-- 		INCLUDE_ARP			=> '1',
-- 		INCLUDE_PING		=> '1',
-- 		
--         FRAME_BUFFER_SIZE	 => 1,
-- 		READOUT_BUFFER_SIZE  => 2,
-- 		SLOWCTRL_BUFFER_SIZE => 2,
-- 		
--         FIXED_SIZE_MODE           => 1,
--         INCREMENTAL_MODE          => 1,
--         FIXED_SIZE                => 100,
--         FIXED_DELAY_MODE          => 1,
--         UP_DOWN_MODE              => 1,
--         UP_DOWN_LIMIT             => 200,
--         FIXED_DELAY               => 1
--         )
-- 	port map(
-- 			 CLK_SYS_IN               => clk,
-- 		     CLK_125_IN               => RX_MAC_CLK,
-- 		     CLK_RX_125_IN            => RX_MAC_CLK,
-- 		     RESET                    => RESET,
-- 		     GSR_N                    => gsr,
-- 		     
-- 		     MY_MAC_OUT => open,
-- 			 MY_MAC_IN  => x"ffffffffffff",
-- 		     
-- 		     MAC_READY_CONF_IN        => '1',
-- 		     MAC_RECONF_OUT           => open,
-- 		     MAC_AN_READY_IN		  => '1',
-- 		     MAC_FIFOAVAIL_OUT        => mac_fifoavail(2),
-- 		     MAC_FIFOEOF_OUT          => mac_fifoeof(2),
-- 		     MAC_FIFOEMPTY_OUT        => open,
-- 		     MAC_RX_FIFOFULL_OUT      => open,
-- 		     MAC_TX_DATA_OUT          => open,
-- 		     MAC_TX_READ_IN           => mac_read(2),
-- 		     MAC_TX_DISCRFRM_IN       => '0',
-- 		     MAC_TX_STAT_EN_IN        => '0',
-- 		     MAC_TX_STATS_IN          => (others => '0'),
-- 		     MAC_TX_DONE_IN           => mac_tx_done(2),
-- 		     MAC_RX_FIFO_ERR_IN       => '0',
-- 		     MAC_RX_STATS_IN          => (others => '0'),
-- 		     MAC_RX_DATA_IN           => MAC_RXD_IN,
-- 		     MAC_RX_WRITE_IN          => MAC_RX_EN_IN,
-- 		     MAC_RX_STAT_EN_IN        => '0',
-- 		     MAC_RX_EOF_IN            => MAC_RX_EOF_IN,
-- 		     MAC_RX_ERROR_IN          => '0',
-- 		     
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
-- 		     
-- 		     MC_UNIQUE_ID_IN          => (others => '0'),
-- 		     
-- 		     GSC_CLK_IN               => clk,
-- 		     GSC_INIT_DATAREADY_OUT   => open, --GSC_INIT_DATAREADY_OUT,
-- 		     GSC_INIT_DATA_OUT        => open, --GSC_INIT_DATA_OUT,
-- 		     GSC_INIT_PACKET_NUM_OUT  => open, --GSC_INIT_PACKET_NUM_OUT,
-- 		     GSC_INIT_READ_IN         => '0', --GSC_INIT_READ_IN,
-- 		     GSC_REPLY_DATAREADY_IN   => '0', --GSC_REPLY_DATAREADY_IN,
-- 		     GSC_REPLY_DATA_IN        => (others => '0'), --GSC_REPLY_DATA_IN,
-- 		     GSC_REPLY_PACKET_NUM_IN  => (others => '0'), --GSC_REPLY_PACKET_NUM_IN,
-- 		     GSC_REPLY_READ_OUT       => open, --GSC_REPLY_READ_OUT,
-- 		     GSC_BUSY_IN              => '0', --GSC_BUSY_IN,
-- 		     
-- 		     SLV_ADDR_IN              => (others => '0'), --SLV_ADDR_IN,
-- 		     SLV_READ_IN              => '0', --SLV_READ_IN,
-- 		     SLV_WRITE_IN             => '0', --SLV_WRITE_IN,
-- 		     SLV_BUSY_OUT             => open, --SLV_BUSY_OUT,
-- 		     SLV_ACK_OUT              => open, --SLV_ACK_OUT,
-- 		     SLV_DATA_IN              => (others => '0'), --SLV_DATA_IN,
-- 		     SLV_DATA_OUT             => open, --SLV_DATA_OUT,
-- 		     
-- 		     CFG_GBE_ENABLE_IN        => '1',
-- 		     CFG_IPU_ENABLE_IN        => '0',
-- 		     CFG_MULT_ENABLE_IN       => '0',
-- 		     CFG_MAX_FRAME_IN         => x"0578",
-- 		     CFG_ALLOW_RX_IN		  => '1',
-- 		     CFG_SOFT_RESET_IN		  => '0',
-- 		     CFG_SUBEVENT_ID_IN       => (others => '0'),
-- 		     CFG_SUBEVENT_DEC_IN      => (others => '0'),
-- 		     CFG_QUEUE_DEC_IN         => (others => '0'),
-- 		     CFG_READOUT_CTR_IN       => (others => '0'),
-- 		     CFG_READOUT_CTR_VALID_IN => '0',
-- 		     CFG_INSERT_TTYPE_IN      => '0',
-- 		     CFG_MAX_SUB_IN           => x"0578",
-- 		     CFG_MAX_QUEUE_IN         => x"1000",
-- 		     CFG_MAX_SUBS_IN_QUEUE_IN => x"0002",
-- 		     CFG_MAX_SINGLE_SUB_IN    => x"0578",
-- 		     CFG_ADDITIONAL_HDR_IN    => '0',
-- 		     CFG_MAX_REPLY_SIZE_IN    => x"0000_fa00",
-- 		     
-- 		     MAKE_RESET_OUT           => open
-- 		);
		
	ipu_mult : entity work.gbe_ipu_multiplexer
	generic map(
		DO_SIMULATION          => 1,
		INCLUDE_DEBUG          => 1,
		NUMBER_OF_OUTPUT_LINKS => 2
	)
	port map(
		CLK_SYS_IN                  => CLK,
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
	
	dummy_inst : entity work.gbe_ipu_dummy
		generic map(DO_SIMULATION    => 1,
			        FIXED_SIZE_MODE  => 1,
			        FIXED_SIZE       => 100,
			        INCREMENTAL_MODE => 0,
			        UP_DOWN_MODE     => 0,
			        UP_DOWN_LIMIT    => 100,
			        FIXED_DELAY_MODE => 1,
			        FIXED_DELAY      => 50)
		port map(clk                     => CLK,
			     rst                     => RESET,
			     GBE_READY_IN            => gbe_ready,
			     
			     CFG_EVENT_SIZE_IN       => x"0100",
			     CFG_TRIGGERED_MODE_IN   => '1',
			     TRIGGER_IN              => trigger,
			     
			     CTS_NUMBER_OUT          => CTS_NUMBER_IN,
			     CTS_CODE_OUT            => CTS_CODE_IN,
			     CTS_INFORMATION_OUT     => CTS_INFORMATION_IN,
			     CTS_READOUT_TYPE_OUT    => CTS_READOUT_TYPE_IN,
			     CTS_START_READOUT_OUT   => CTS_START_READOUT_IN,
			     CTS_DATA_IN             => CTS_DATA_OUT,
			     CTS_DATAREADY_IN        => CTS_DATAREADY_OUT,
			     CTS_READOUT_FINISHED_IN => CTS_READOUT_FINISHED_OUT,
			     CTS_READ_OUT            => CTS_READ_IN,
			     CTS_LENGTH_IN           => CTS_LENGTH_OUT,
			     CTS_ERROR_PATTERN_IN    => CTS_ERROR_PATTERN_OUT,
			     FEE_DATA_OUT            => FEE_DATA_IN,
			     FEE_DATAREADY_OUT       => FEE_DATAREADY_IN,
			     FEE_READ_IN             => FEE_READ_OUT,
			     FEE_STATUS_BITS_OUT     => FEE_STATUS_BITS_IN,
			     FEE_BUSY_OUT            => FEE_BUSY_IN
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
	mac_tx_done(0) <= '0';
	wait until rising_edge(mac_fifoeof(0));
	wait until rising_edge(rx_mac_clk);
	mac_tx_done(0) <= '1';
	wait until rising_edge(rx_mac_clk);
end process;

process
begin
	mac_tx_done(1) <= '0';
	wait until rising_edge(mac_fifoeof(1));
	wait until rising_edge(rx_mac_clk);
	mac_tx_done(1) <= '1';
	wait until rising_edge(rx_mac_clk);
end process;

-- process
-- begin
-- 	mac_tx_done(1) <= '0';
-- 	wait until rising_edge(mac_fifoeof(2));
-- 	wait until rising_edge(rx_mac_clk);
-- 	mac_tx_done(1) <= '1';
-- 	wait until rising_edge(rx_mac_clk);
-- end process;

process(rx_mac_clk)
begin
	if rising_edge(rx_mac_clk) then
		mac_read(0) <= mac_fifoavail(0);
		mac_read(1) <= mac_fifoavail(1);
		--mac_read(2) <= mac_fifoavail(2);
	end if;
end process;
	

testbench_proc : process
begin
	reset <= '1'; 
	
	trigger <= '0';
	gbe_ready <= '0';
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
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
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
	MAC_RXD_IN		<= x"ff";  --transcation id
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";--transcation id
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
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
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
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ff";
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
	
	

	
--	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RX_EN_IN <= '1';
---- dest mac
--	MAC_RXD_IN		<= x"02";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"be";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
---- src mac
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"aa";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"bb";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"dd";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"ee";
--	wait until rising_edge(RX_MAC_CLK);
---- frame type
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
---- ip headers
--	MAC_RXD_IN		<= x"45";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"10";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"5a";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"49";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"a8";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"a8";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"02";
---- ping headers
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"47";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"d3";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"3c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
---- ping data
--	MAC_RXD_IN		<= x"8c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"da";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"e7";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"4d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"36";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c4";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"09";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0a";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0b";	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0e";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0f";
--	wait until rising_edge(RX_MAC_CLK);
--		MAC_RX_EOF_IN <= '1';
--			MAC_RXD_IN		<= x"aa";
--	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RX_EN_IN <='0';
--	MAC_RX_EOF_IN <= '0';
--		
--	
--	wait for 15 us;
--	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RX_EN_IN <= '1';
---- dest mac
--	MAC_RXD_IN		<= x"02";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"be";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
---- src mac
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"aa";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"bb";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"dd";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"ee";
--	wait until rising_edge(RX_MAC_CLK);
---- frame type
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
---- ip headers
--	MAC_RXD_IN		<= x"45";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"10";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"5a";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"49";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"a8";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"a8";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"02";
---- ping headers
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"47";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"d3";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"3c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(RX_MAC_CLK);
---- ping data
--	MAC_RXD_IN		<= x"8c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"da";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"e7";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"4d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"36";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"c4";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"09";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0a";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0b";	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0c";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0d";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0e";
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RXD_IN		<= x"0f";
--	wait until rising_edge(RX_MAC_CLK);
--		MAC_RX_EOF_IN <= '1';
--			MAC_RXD_IN		<= x"aa";
--	
--	wait until rising_edge(RX_MAC_CLK);
--	MAC_RX_EN_IN <='0';
--	MAC_RX_EOF_IN <= '0';
	
	wait for 2 us;
	
	gbe_ready <= '1';
	
	wait for 1 us;
	
	trigger <= '1';
	
--	for i in 0 to 100000 loop
--		wait until rising_edge(CLK);
--		trigger <= '1';
--		wait until rising_edge(CLK);
--		wait until rising_edge(CLK);
--		trigger <= '0';
--		
--		--wait for 17 us;
--	end loop;
	
	
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