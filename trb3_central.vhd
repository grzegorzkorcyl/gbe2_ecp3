library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
   use work.trb_net_std.all;
   use work.trb_net_components.all;
   use work.trb3_components.all;
   use work.trb_net16_hub_func.all;
   use work.version.all;
   use work.trb_net_gbe_components.all;
   
   use work.cts_pkg.all;
   
--Configuration is done in this file:   
   use work.config.all;
-- The description of hub ports is also there!
   

--Slow Control
--    0 -    7  Readout endpoint common status
--   80 -   AF  Hub status registers
--   C0 -   CF  Hub control registers
-- 4000 - 40FF  Hub status registers
-- 7000 - 72FF  Readout endpoint registers
-- 8100 - 83FF  GbE configuration & status
-- A000 - A1FF  CTS configuration & status
-- C000 - CFFF  TDC configuration & status
-- D000 - D13F  Flash Programming




entity trb3_central is
  port(
    --Clocks
    CLK_EXT                        : in  std_logic_vector(4 downto 3); --from RJ45
    CLK_GPLL_LEFT                  : in  std_logic;  --Clock Manager 2/9, 200 MHz  <-- MAIN CLOCK
    CLK_GPLL_RIGHT                 : in  std_logic;  --Clock Manager 1/9, 125 MHz  <-- for GbE
    CLK_PCLK_LEFT                  : in  std_logic;  --Clock Fan-out, 200/400 MHz 
    CLK_PCLK_RIGHT                 : in  std_logic;  --Clock Fan-out, 200/400 MHz 

    --Trigger
    TRIGGER_LEFT                   : in  std_logic;  --left side trigger input from fan-out
    TRIGGER_RIGHT                  : in  std_logic;  --right side trigger input from fan-out
    TRIGGER_EXT                    : in  std_logic_vector(4 downto 2); --additional trigger from RJ45
    TRIGGER_OUT                    : out std_logic;  --trigger to second input of fan-out
    TRIGGER_OUT2                   : out std_logic;
    
    --Serdes
    CLK_SERDES_INT_LEFT            : in  std_logic;  --Clock Manager 2/0, 200 MHz, only in case of problems
    CLK_SERDES_INT_RIGHT           : in  std_logic;  --Clock Manager 1/0, off, 125 MHz possible
    
    --SFP
    SFP_RX_P                       : in  std_logic_vector(9 downto 1); 
    SFP_RX_N                       : in  std_logic_vector(9 downto 1); 
    SFP_TX_P                       : out std_logic_vector(9 downto 1); 
    SFP_TX_N                       : out std_logic_vector(9 downto 1); 
    SFP_TX_FAULT                   : in  std_logic_vector(8 downto 1); --TX broken
    SFP_RATE_SEL                   : out std_logic_vector(8 downto 1); --not supported by our SFP
    SFP_LOS                        : in  std_logic_vector(8 downto 1); --Loss of signal
    SFP_MOD0                       : in  std_logic_vector(8 downto 1); --SFP present
    SFP_MOD1                       : in  std_logic_vector(8 downto 1); --I2C interface
    SFP_MOD2                       : in  std_logic_vector(8 downto 1); --I2C interface
    SFP_TXDIS                      : out std_logic_vector(8 downto 1); --disable TX
    
    --Clock and Trigger Control
    TRIGGER_SELECT                 : out std_logic;  --trigger select for fan-out. 0: external, 1: signal from FPGA5
    CLOCK_SELECT                   : out std_logic;  --clock select for fan-out. 0: 200MHz, 1: external from RJ45
    CLK_MNGR1_USER                 : inout std_logic_vector(3 downto 0); --I/O lines to clock manager 1
    CLK_MNGR2_USER                 : inout std_logic_vector(3 downto 0); --I/O lines to clock manager 1
    
    --Inter-FPGA Communication
    FPGA1_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA2_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA3_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA4_COMM                     : inout std_logic_vector(11 downto 0); 
                                    -- on all FPGAn_COMM:  --Bit 0/1 output, serial link TX active
                                                           --Bit 2/3 input, serial link RX active
                                                           --others yet undefined
    FPGA1_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA2_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA3_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA4_TTL                      : inout std_logic_vector(3 downto 0);
                                    --only for not timing-sensitive signals

    --Communication to small addons
    FPGA1_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 2-3: LED for SFP3/4
    FPGA2_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 2-3: LED for SFP7/8
    FPGA3_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 0-1: LED for SFP5/6 
    FPGA4_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 0-1: LED for SFP1/2
                                                                         --Bit 0-3 connected to LED by default, two on each side
                                                                         
    --AddOn connector
    ECL_IN                         : in  std_logic_vector(3 downto 0);
    NIM_IN                         : in  std_logic_vector(1 downto 0);
    JIN1                           : in  std_logic_vector(3 downto 0);
    JIN2                           : in  std_logic_vector(3 downto 0);
    JINLVDS                        : in  std_logic_vector(15 downto 0);  --No LVDS, just TTL!
    
    DISCRIMINATOR_IN               : in  std_logic_vector(1 downto 0);
    PWM_OUT                        : out std_logic_vector(1 downto 0);
    
    JOUT1                          : out std_logic_vector(3 downto 0);
    JOUT2                          : out std_logic_vector(3 downto 0);
    JOUTLVDS                       : out std_logic_vector(7 downto 0);
    JTTL                           : inout std_logic_vector(15 downto 0);
    TRG_FANOUT_ADDON               : out std_logic;
    
    LED_BANK                       : out std_logic_vector(7 downto 0);
    LED_RJ_GREEN                   : out std_logic_vector(5 downto 0);
    LED_RJ_RED                     : out std_logic_vector(5 downto 0);
    LED_FAN_GREEN                  : out std_logic;
    LED_FAN_ORANGE                 : out std_logic;
    LED_FAN_RED                    : out std_logic;
    LED_FAN_YELLOW                 : out std_logic;
    
    --Flash ROM & Reboot
    FLASH_CLK                      : out std_logic;
    FLASH_CS                       : out std_logic;
    FLASH_DIN                      : out std_logic;
    FLASH_DOUT                     : in  std_logic;
    PROGRAMN                       : out std_logic := '1'; --reboot FPGA
    
    --Misc
    ENPIRION_CLOCK                 : out std_logic;  --Clock for power supply, not necessary, floating
    TEMPSENS                       : inout std_logic; --Temperature Sensor
    LED_CLOCK_GREEN                : out std_logic;
    LED_CLOCK_RED                  : out std_logic;
    LED_GREEN                      : out std_logic;
    LED_ORANGE                     : out std_logic; 
    LED_RED                        : out std_logic;
    LED_TRIGGER_GREEN              : out std_logic;
    LED_TRIGGER_RED                : out std_logic; 
    LED_YELLOW                     : out std_logic;

    --Test Connectors
    TEST_LINE                      : out std_logic_vector(31 downto 0)
    );


    attribute syn_useioff : boolean;
    --no IO-FF for LEDs relaxes timing constraints
    attribute syn_useioff of LED_CLOCK_GREEN    : signal is false;
    attribute syn_useioff of LED_CLOCK_RED      : signal is false;
    attribute syn_useioff of LED_TRIGGER_GREEN  : signal is false;
    attribute syn_useioff of LED_TRIGGER_RED    : signal is false;
    attribute syn_useioff of LED_GREEN          : signal is false;
    attribute syn_useioff of LED_ORANGE         : signal is false;
    attribute syn_useioff of LED_RED            : signal is false;
    attribute syn_useioff of LED_YELLOW         : signal is false;
    attribute syn_useioff of LED_FAN_GREEN      : signal is false;
    attribute syn_useioff of LED_FAN_ORANGE     : signal is false;
    attribute syn_useioff of LED_FAN_RED        : signal is false;
    attribute syn_useioff of LED_FAN_YELLOW     : signal is false;
    attribute syn_useioff of LED_BANK           : signal is false;
    attribute syn_useioff of LED_RJ_GREEN       : signal is false;
    attribute syn_useioff of LED_RJ_RED         : signal is false;
    attribute syn_useioff of FPGA1_TTL          : signal is false;
    attribute syn_useioff of FPGA2_TTL          : signal is false;
    attribute syn_useioff of FPGA3_TTL          : signal is false;
    attribute syn_useioff of FPGA4_TTL          : signal is false;
    attribute syn_useioff of SFP_TXDIS          : signal is false;
    attribute syn_useioff of PROGRAMN           : signal is false;
    
    --important signals _with_ IO-FF
    attribute syn_useioff of FLASH_CLK          : signal is true;
    attribute syn_useioff of FLASH_CS           : signal is true;
    attribute syn_useioff of FLASH_DIN          : signal is true;
    attribute syn_useioff of FLASH_DOUT         : signal is true;
    attribute syn_useioff of FPGA1_COMM         : signal is true;
    attribute syn_useioff of FPGA2_COMM         : signal is true;
    attribute syn_useioff of FPGA3_COMM         : signal is true;
    attribute syn_useioff of FPGA4_COMM         : signal is true;
    attribute syn_useioff of CLK_MNGR1_USER     : signal is false;
    attribute syn_useioff of CLK_MNGR2_USER     : signal is false;
    attribute syn_useioff of TRIGGER_SELECT     : signal is false;
    attribute syn_useioff of CLOCK_SELECT       : signal is false;
end entity;

architecture trb3_central_arch of trb3_central is
  attribute syn_keep : boolean;
  attribute syn_preserve : boolean;

  signal clk_100_i   : std_logic; --clock for main logic, 100 MHz, via Clock Manager and internal PLL
  signal clk_200_i   : std_logic; --clock for logic at 200 MHz, via Clock Manager and bypassed PLL
  signal clk_125_i   : std_logic; --125 MHz, via Clock Manager and bypassed PLL
  signal clk_20_i    : std_logic; --clock for calibrating the tdc, 20 MHz, via Clock Manager and internal PLL
  signal pll_lock    : std_logic; --Internal PLL locked. E.g. used to reset all internal logic.
  signal clear_i     : std_logic;
  signal reset_i     : std_logic;
  signal GSR_N       : std_logic;
  attribute syn_keep of GSR_N : signal is true;
  attribute syn_preserve of GSR_N : signal is true;

  

  --FPGA Test
  signal time_counter, time_counter2 : unsigned(31 downto 0);

  --Media Interface
  signal med_stat_op             : std_logic_vector (INTERFACE_NUM*16-1  downto 0);
  signal med_ctrl_op             : std_logic_vector (INTERFACE_NUM*16-1  downto 0);
  signal med_stat_debug          : std_logic_vector (INTERFACE_NUM*64-1  downto 0);
  signal med_ctrl_debug          : std_logic_vector (INTERFACE_NUM*64-1  downto 0);
  signal med_data_out            : std_logic_vector (INTERFACE_NUM*16-1  downto 0);
  signal med_packet_num_out      : std_logic_vector (INTERFACE_NUM*3-1   downto 0);
  signal med_dataready_out       : std_logic_vector (INTERFACE_NUM*1-1   downto 0);
  signal med_read_out            : std_logic_vector (INTERFACE_NUM*1-1   downto 0);
  signal med_data_in             : std_logic_vector (INTERFACE_NUM*16-1  downto 0);
  signal med_packet_num_in       : std_logic_vector (INTERFACE_NUM*3-1   downto 0);
  signal med_dataready_in        : std_logic_vector (INTERFACE_NUM*1-1   downto 0);
  signal med_read_in             : std_logic_vector (INTERFACE_NUM*1-1   downto 0);

  --Hub
  signal common_stat_regs        : std_logic_vector (std_COMSTATREG*32-1 downto 0);
  signal common_ctrl_regs        : std_logic_vector (std_COMCTRLREG*32-1 downto 0);
  signal my_address              : std_logic_vector (16-1 downto 0);
  signal regio_addr_out          : std_logic_vector (16-1 downto 0);
  signal regio_read_enable_out   : std_logic;
  signal regio_write_enable_out  : std_logic;
  signal regio_data_out          : std_logic_vector (32-1 downto 0);
  signal regio_data_in           : std_logic_vector (32-1 downto 0);
  signal regio_dataready_in      : std_logic;
  signal regio_no_more_data_in   : std_logic;
  signal regio_write_ack_in      : std_logic;
  signal regio_unknown_addr_in   : std_logic;
  signal regio_timeout_out       : std_logic;

  signal spictrl_read_en         : std_logic;
  signal spictrl_write_en        : std_logic;
  signal spictrl_data_in         : std_logic_vector(31 downto 0);
  signal spictrl_addr            : std_logic;
  signal spictrl_data_out        : std_logic_vector(31 downto 0);
  signal spictrl_ack             : std_logic;
  signal spictrl_busy            : std_logic;
  signal spimem_read_en          : std_logic;
  signal spimem_write_en         : std_logic;
  signal spimem_data_in          : std_logic_vector(31 downto 0);
  signal spimem_addr             : std_logic_vector(5 downto 0);
  signal spimem_data_out         : std_logic_vector(31 downto 0);
  signal spimem_ack              : std_logic;

  signal spi_bram_addr           : std_logic_vector(7 downto 0);
  signal spi_bram_wr_d           : std_logic_vector(7 downto 0);
  signal spi_bram_rd_d           : std_logic_vector(7 downto 0);
  signal spi_bram_we             : std_logic;

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

  signal stage_stat_regs              : std_logic_vector (31 downto 0);
  signal stage_ctrl_regs              : std_logic_vector (31 downto 0);

  signal mb_stat_reg_data_wr          : std_logic_vector(31 downto 0);
  signal mb_stat_reg_data_rd          : std_logic_vector(31 downto 0);
  signal mb_stat_reg_read             : std_logic;
  signal mb_stat_reg_write            : std_logic;
  signal mb_stat_reg_ack              : std_logic;
  signal mb_ip_mem_addr               : std_logic_vector(15 downto 0); -- only [7:0] in used
  signal mb_ip_mem_data_wr            : std_logic_vector(31 downto 0);
  signal mb_ip_mem_data_rd            : std_logic_vector(31 downto 0);
  signal mb_ip_mem_read               : std_logic;
  signal mb_ip_mem_write              : std_logic;
  signal mb_ip_mem_ack                : std_logic;
  signal ip_cfg_mem_clk				: std_logic;
  signal ip_cfg_mem_addr				: std_logic_vector(7 downto 0);
  signal ip_cfg_mem_data				: std_logic_vector(31 downto 0);
  signal ctrl_reg_addr                : std_logic_vector(15 downto 0);
  signal gbe_stp_reg_addr             : std_logic_vector(15 downto 0);
  signal gbe_stp_data                 : std_logic_vector(31 downto 0);
  signal gbe_stp_reg_ack              : std_logic;
  signal gbe_stp_reg_data_wr          : std_logic_vector(31 downto 0);
  signal gbe_stp_reg_read             : std_logic;
  signal gbe_stp_reg_write            : std_logic;
  signal gbe_stp_reg_data_rd          : std_logic_vector(31 downto 0);

  signal debug : std_logic_vector(63 downto 0);

  signal next_reset, make_reset_via_network_q : std_logic;
  signal reset_counter : std_logic_vector(11 downto 0);
  signal link_ok : std_logic;

  signal gsc_init_data, gsc_reply_data : std_logic_vector(15 downto 0);
  signal gsc_init_read, gsc_reply_read : std_logic;
  signal gsc_init_dataready, gsc_reply_dataready : std_logic;
  signal gsc_init_packet_num, gsc_reply_packet_num : std_logic_vector(2 downto 0);
  signal gsc_busy : std_logic;
  signal mc_unique_id  : std_logic_vector(63 downto 0);
  signal trb_reset_in  : std_logic;
  signal reset_via_gbe : std_logic;
  signal reset_via_gbe_delayed : std_logic_vector(2 downto 0);
  signal reset_i_temp  : std_logic;

  signal cts_rdo_trigger             : std_logic;
  signal cts_rdo_trg_data_valid      : std_logic;
  signal cts_rdo_valid_timing_trg    : std_logic;
  signal cts_rdo_valid_notiming_trg  : std_logic;
  signal cts_rdo_invalid_trg         : std_logic;

  signal cts_rdo_trg_status_bits,
    cts_rdo_trg_status_bits_cts      : std_logic_vector(31 downto 0) := (others => '0');
  signal cts_rdo_data                : std_logic_vector(31 downto 0);
  signal cts_rdo_write               : std_logic;
  signal cts_rdo_finished            : std_logic;

  signal cts_ext_trigger             : std_logic;
  signal cts_ext_status              : std_logic_vector(31 downto 0) := (others => '0');
  signal cts_ext_control             : std_logic_vector(31 downto 0);
  signal cts_ext_debug               : std_logic_vector(31 downto 0);
  signal cts_ext_header 						 : std_logic_vector(1 downto 0);

  signal cts_rdo_additional_data            : std_logic_vector(31+INCLUDE_TDC*32 downto 0);
  signal cts_rdo_additional_write           : std_logic_vector(0+INCLUDE_TDC downto 0) := (others => '0');
  signal cts_rdo_additional_finished        : std_logic_vector(0+INCLUDE_TDC downto 0) := (others => '0');
  signal cts_rdo_trg_status_bits_additional : std_logic_vector(31+INCLUDE_TDC*32 downto 0) := (others => '0');
  signal cts_rdo_trg_type                   : std_logic_vector(3 downto 0);
  signal cts_rdo_trg_code                   : std_logic_vector(7 downto 0);
  signal cts_rdo_trg_information            : std_logic_vector(23 downto 0);
  signal cts_rdo_trg_number                 : std_logic_vector(15 downto 0);
      
  
  
  signal cts_trg_send                : std_logic;
  signal cts_trg_type                : std_logic_vector(3 downto 0);
  signal cts_trg_number              : std_logic_vector(15 downto 0);
  signal cts_trg_information         : std_logic_vector(23 downto 0);
  signal cts_trg_code                : std_logic_vector(7 downto 0);
  signal cts_trg_status_bits         : std_logic_vector(31 downto 0);
  signal cts_trg_busy                : std_logic;

  signal cts_ipu_send                : std_logic;
  signal cts_ipu_type                : std_logic_vector(3 downto 0);
  signal cts_ipu_number              : std_logic_vector(15 downto 0);
  signal cts_ipu_information         : std_logic_vector(7 downto 0);
  signal cts_ipu_code                : std_logic_vector(7 downto 0);
  signal cts_ipu_status_bits         : std_logic_vector(31 downto 0);
  signal cts_ipu_busy                : std_logic;

  signal cts_regio_addr              : std_logic_vector(15 downto 0);
  signal cts_regio_read              : std_logic;
  signal cts_regio_write             : std_logic;
  signal cts_regio_data_out          : std_logic_vector(31 downto 0);
  signal cts_regio_data_in           : std_logic_vector(31 downto 0);
  signal cts_regio_dataready         : std_logic;
  signal cts_regio_no_more_data      : std_logic;
  signal cts_regio_write_ack         : std_logic;
  signal cts_regio_unknown_addr      : std_logic;

  signal cts_trigger_out             : std_logic;
  signal external_send_reset         : std_logic;
  --bit 1 ms-tick, 0 us-tick
  signal timer_ticks                 : std_logic_vector(1 downto 0);
  
  signal trigger_busy_i              : std_logic;
  signal trigger_in_buf_i            : std_logic_vector(3 downto 0);

  signal select_tc                   : std_logic_vector(31 downto 0);
  signal select_tc_data_in           : std_logic_vector(31 downto 0);
  signal select_tc_write             : std_logic;
  signal select_tc_read              : std_logic;
  signal select_tc_ack               : std_logic;

  signal hitreg_read_en    : std_logic;
  signal hitreg_write_en   : std_logic;
  signal hitreg_data_in    : std_logic_vector(31 downto 0);
  signal hitreg_addr       : std_logic_vector(6 downto 0);
  signal hitreg_data_out   : std_logic_vector(31 downto 0);
  signal hitreg_data_ready : std_logic;
  signal hitreg_invalid    : std_logic;

  signal srb_read_en    : std_logic;
  signal srb_write_en   : std_logic;
  signal srb_data_in    : std_logic_vector(31 downto 0);
  signal srb_addr       : std_logic_vector(6 downto 0);
  signal srb_data_out   : std_logic_vector(31 downto 0);
  signal srb_data_ready : std_logic;
  signal srb_invalid    : std_logic;

--     signal lhb_read_en    : std_logic;
--     signal lhb_write_en   : std_logic;
--     signal lhb_data_in    : std_logic_vector(31 downto 0);
--     signal lhb_addr       : std_logic_vector(6 downto 0);
--     signal lhb_data_out   : std_logic_vector(31 downto 0);
--     signal lhb_data_ready : std_logic;
--     signal lhb_invalid    : std_logic;

  signal esb_read_en    : std_logic;
  signal esb_write_en   : std_logic;
  signal esb_data_in    : std_logic_vector(31 downto 0);
  signal esb_addr       : std_logic_vector(6 downto 0);
  signal esb_data_out   : std_logic_vector(31 downto 0);
  signal esb_data_ready : std_logic;
  signal esb_invalid    : std_logic;

  signal fwb_read_en    : std_logic;
  signal fwb_write_en   : std_logic;
  signal fwb_data_in    : std_logic_vector(31 downto 0);
  signal fwb_addr       : std_logic_vector(6 downto 0);
  signal fwb_data_out   : std_logic_vector(31 downto 0);
  signal fwb_data_ready : std_logic;
  signal fwb_invalid    : std_logic;

  signal tdc_ctrl_read      : std_logic;
  signal last_tdc_ctrl_read : std_logic;
  signal tdc_ctrl_write     : std_logic;
  signal tdc_ctrl_addr      : std_logic_vector(2 downto 0);
  signal tdc_ctrl_data_in   : std_logic_vector(31 downto 0);
  signal tdc_ctrl_data_out  : std_logic_vector(31 downto 0);
  signal tdc_ctrl_reg   : std_logic_vector(5*32-1 downto 0);
  signal tdc_debug      : std_logic_vector(15 downto 0);  
  
  component buf_test is
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
end component;


begin

---------------------------------------------------------------------------
-- Reset Generation
---------------------------------------------------------------------------

GSR_N   <= pll_lock;
  
THE_RESET_HANDLER : trb_net_reset_handler
  generic map(
    RESET_DELAY     => x"FEEE"
    )
  port map(
    CLEAR_IN        => '0',             -- reset input (high active, async)
    CLEAR_N_IN      => '1',             -- reset input (low active, async)
    CLK_IN          => clk_200_i,       -- raw master clock, NOT from PLL/DLL!
    SYSCLK_IN       => clk_100_i,       -- PLL/DLL remastered clock
    PLL_LOCKED_IN   => pll_lock,        -- master PLL lock signal (async)
    RESET_IN        => '0',             -- general reset signal (SYSCLK)
    TRB_RESET_IN    => trb_reset_in,    -- TRBnet reset signal (SYSCLK)
    CLEAR_OUT       => clear_i,         -- async reset out, USE WITH CARE!
    RESET_OUT       => reset_i_temp,    -- synchronous reset out (SYSCLK)
    DEBUG_OUT       => open
  );

trb_reset_in <= '0'; -- reset_via_gbe or MED_STAT_OP(4*16+13); --_delayed(2)
reset_i <= '0'; --reset_i_temp; -- or trb_reset_in;



---------------------------------------------------------------------------
-- Clock Handling
---------------------------------------------------------------------------
THE_MAIN_PLL : pll_in200_out100
  port map(
    CLK    => CLK_GPLL_LEFT,
    RESET  => '0',
    CLKOP  => clk_100_i,
    CLKOK  => clk_200_i,
    LOCK   => pll_lock
    );

-- generates hits for calibration uncorrelated with tdc clk
THE_CALIBRATION_PLL : pll_in125_out20
	port map (
		CLK   => CLK_GPLL_RIGHT,
		CLKOP => clk_20_i,
		CLKOK => clk_125_i,
		LOCK  => open);

  ---------------------------------------------------------------------
  -- The GbE machine for blasting out data from TRBnet
  ---------------------------------------------------------------------

  GBE: buf_test
  generic map( 
	  DO_SIMULATION               => c_NO,
	  USE_125MHZ_EXTCLK           => c_NO
  )
  port map( 
	  CLK                         => clk_100_i,
	  TEST_CLK                    => '0',
	  CLK_125_IN                  => clk_125_i,
	  RESET                       => reset_i,
	  GSR_N                       => gsr_n,
	  --Debug
	  STAGE_STAT_REGS_OUT         => open, --stage_stat_regs, -- should be come STATUS or similar
	  STAGE_CTRL_REGS_IN          => stage_ctrl_regs, -- OBSELETE!
	  ----gk 22.04.10 not used any more, ip_configurator moved inside
	  ---configuration interface
	  IP_CFG_START_IN              => stage_ctrl_regs(15),
	  IP_CFG_BANK_SEL_IN           => stage_ctrl_regs(11 downto 8),
	  IP_CFG_DONE_OUT              => open,
	  IP_CFG_MEM_ADDR_OUT          => ip_cfg_mem_addr,
	  IP_CFG_MEM_DATA_IN           => ip_cfg_mem_data,
	  IP_CFG_MEM_CLK_OUT           => ip_cfg_mem_clk,
	  MR_RESET_IN                  => stage_ctrl_regs(3),
	  MR_MODE_IN                   => stage_ctrl_regs(1),
	  MR_RESTART_IN                => stage_ctrl_regs(0),
	  ---gk 29.03.10
	  --interface to ip_configurator memory
	  SLV_ADDR_IN                  => mb_ip_mem_addr(7 downto 0),
	  SLV_READ_IN                  => mb_ip_mem_read,
	  SLV_WRITE_IN                 => mb_ip_mem_write,
	  SLV_BUSY_OUT                 => open,
	  SLV_ACK_OUT                  => mb_ip_mem_ack,
	  SLV_DATA_IN                  => mb_ip_mem_data_wr,
	  SLV_DATA_OUT                 => mb_ip_mem_data_rd,
	  --gk 26.04.10
	  ---gk 22.04.10
	  ---registers setup interface
	  BUS_ADDR_IN                 => gbe_stp_reg_addr(7 downto 0), --ctrl_reg_addr(7 downto 0),
	  BUS_DATA_IN                 => gbe_stp_reg_data_wr, --stage_ctrl_regs,
	  BUS_DATA_OUT                => gbe_stp_reg_data_rd,
	  BUS_WRITE_EN_IN             => gbe_stp_reg_write,
	  BUS_READ_EN_IN              => gbe_stp_reg_read,
	  BUS_ACK_OUT                 => gbe_stp_reg_ack,
	  --gk 23.04.10
	  LED_PACKET_SENT_OUT         => open, --buf_SFP_LED_ORANGE(17),
	  LED_AN_DONE_N_OUT           => link_ok, --buf_SFP_LED_GREEN(17),
    --CTS interface
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
	  --SFP   Connection
	  SFP_RXD_P_IN                => SFP_RX_P(9), --these ports are don't care
	  SFP_RXD_N_IN                => SFP_RX_N(9),
	  SFP_TXD_P_OUT               => SFP_TX_P(9),
	  SFP_TXD_N_OUT               => SFP_TX_N(9),
	  SFP_REFCLK_P_IN             => open, --SFP_REFCLKP(2),
	  SFP_REFCLK_N_IN             => open, --SFP_REFCLKN(2),
	  SFP_PRSNT_N_IN              => SFP_MOD0(8), -- SFP Present ('0' = SFP in place, '1' = no SFP mounted)
	  SFP_LOS_IN                  => SFP_LOS(8), -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	  SFP_TXDIS_OUT               => SFP_TXDIS(8),  -- SFP disable

    -- interface between main_controller and hub logic
    MC_UNIQUE_ID_IN          => mc_unique_id,
    GSC_CLK_IN               => clk_100_i,
    GSC_INIT_DATAREADY_OUT   => gsc_init_dataready,
    GSC_INIT_DATA_OUT        => gsc_init_data,
    GSC_INIT_PACKET_NUM_OUT  => gsc_init_packet_num,
    GSC_INIT_READ_IN         => gsc_init_read,
    GSC_REPLY_DATAREADY_IN   => gsc_reply_dataready,
    GSC_REPLY_DATA_IN        => gsc_reply_data,
    GSC_REPLY_PACKET_NUM_IN  => gsc_reply_packet_num,
    GSC_REPLY_READ_OUT       => gsc_reply_read,
    GSC_BUSY_IN              => gsc_busy,

    MAKE_RESET_OUT           => reset_via_gbe,

	  --for simulation of receiving part only
	  MAC_RX_EOF_IN		=> '0',
	  MAC_RXD_IN		=> "00000000",
	  MAC_RX_EN_IN		=> '0',

	  ANALYZER_DEBUG_OUT          => debug
  );
    
---------------------------------------------------------------------------
-- SPI / Flash
---------------------------------------------------------------------------

THE_SPI_MASTER: spi_master
  port map(
    CLK_IN         => clk_100_i,
    RESET_IN       => reset_i,
    -- Slave bus
    BUS_READ_IN    => spictrl_read_en,
    BUS_WRITE_IN   => spictrl_write_en,
    BUS_BUSY_OUT   => spictrl_busy,
    BUS_ACK_OUT    => spictrl_ack,
    BUS_ADDR_IN(0) => spictrl_addr,
    BUS_DATA_IN    => spictrl_data_in,
    BUS_DATA_OUT   => spictrl_data_out,
    -- SPI connections
    SPI_CS_OUT     => FLASH_CS,
    SPI_SDI_IN     => FLASH_DOUT,
    SPI_SDO_OUT    => FLASH_DIN,
    SPI_SCK_OUT    => FLASH_CLK,
    -- BRAM for read/write data
    BRAM_A_OUT     => spi_bram_addr,
    BRAM_WR_D_IN   => spi_bram_wr_d,
    BRAM_RD_D_OUT  => spi_bram_rd_d,
    BRAM_WE_OUT    => spi_bram_we,
    -- Status lines
    STAT           => open
    );

-- data memory for SPI accesses
THE_SPI_MEMORY: spi_databus_memory
  port map(
    CLK_IN        => clk_100_i,
    RESET_IN      => reset_i,
    -- Slave bus
    BUS_ADDR_IN   => spimem_addr,
    BUS_READ_IN   => spimem_read_en,
    BUS_WRITE_IN  => spimem_write_en,
    BUS_ACK_OUT   => spimem_ack,
    BUS_DATA_IN   => spimem_data_in,
    BUS_DATA_OUT  => spimem_data_out,
    -- state machine connections
    BRAM_ADDR_IN  => spi_bram_addr,
    BRAM_WR_D_OUT => spi_bram_wr_d,
    BRAM_RD_D_IN  => spi_bram_rd_d,
    BRAM_WE_IN    => spi_bram_we,
    -- Status lines
    STAT          => open
    );

  TRIGGER_SELECT <= select_tc(0);
  CLOCK_SELECT   <= select_tc(8); --use on-board oscillator
  CLK_MNGR1_USER <= select_tc(19 downto 16);
  CLK_MNGR2_USER <= select_tc(27 downto 24); 
  
  
---------------------------------------------------------------------------
-- FPGA communication
---------------------------------------------------------------------------
--   FPGA1_COMM <= (others => 'Z');
--   FPGA2_COMM <= (others => 'Z');
--   FPGA3_COMM <= (others => 'Z');
--   FPGA4_COMM <= (others => 'Z');

  FPGA1_TTL <= (others => 'Z');
  FPGA2_TTL <= (others => 'Z');
  FPGA3_TTL <= (others => 'Z');
  FPGA4_TTL <= (others => 'Z');

  FPGA1_CONNECTOR <= (others => 'Z');
  FPGA2_CONNECTOR <= (others => 'Z');
  FPGA3_CONNECTOR <= (others => 'Z');
  FPGA4_CONNECTOR <= (others => 'Z');


---------------------------------------------------------------------------
-- AddOn Connecto
---------------------------------------------------------------------------
    PWM_OUT                        <= "00";
    
    JOUT1                          <= x"0";
    JOUT2                          <= x"0";
    JOUTLVDS                       <= x"00";
    JTTL                           <= x"0000";
    TRG_FANOUT_ADDON               <= '0';
    
    LED_BANK                       <= x"FF";
    LED_RJ_GREEN                   <= "111111";
    LED_RJ_RED                     <= "111111";
    LED_FAN_GREEN                  <= '1';
    LED_FAN_ORANGE                 <= '1';
    LED_FAN_RED                    <= '1';
    LED_FAN_YELLOW                 <= '1';


---------------------------------------------------------------------------
-- LED
---------------------------------------------------------------------------
  LED_CLOCK_GREEN                <= not med_stat_op(15);
  LED_CLOCK_RED                  <= not reset_via_gbe;
--   LED_GREEN                      <= not med_stat_op(9);
--   LED_YELLOW                     <= not med_stat_op(10);
--   LED_ORANGE                     <= not med_stat_op(11); 
--   LED_RED                        <= '1';
  LED_TRIGGER_GREEN              <= not med_stat_op(4*16+9);
  LED_TRIGGER_RED                <= not (med_stat_op(4*16+11) or med_stat_op(4*16+10));


LED_GREEN <= debug(0);
LED_ORANGE <= debug(1);
LED_RED <= debug(2);
LED_YELLOW <= link_ok; --debug(3);


---------------------------------------------------------------------------
-- Test Connector
---------------------------------------------------------------------------    

--   TEST_LINE(7 downto 0)   <= med_data_in(7 downto 0);
--   TEST_LINE(8)            <= med_dataready_in(0);
--   TEST_LINE(9)            <= med_dataready_out(0);

--  TEST_LINE(15 downto 0)  <= tdc_debug;
--  TEST_LINE(31 downto 16) <= (others => '0');
--   TEST_LINE(31 downto 0) <= cts_ext_debug;


---------------------------------------------------------------------------
-- Test Circuits
---------------------------------------------------------------------------
--   process
--     begin
--       wait until rising_edge(clk_100_i);
--       time_counter <= time_counter + 1;
--     end process;
-- 

end architecture;
