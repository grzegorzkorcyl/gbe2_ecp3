library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
library work;
use work.trb_net_std.all;

use work.trb_net_gbe_protocols.all;

package trb_net_gbe_components is



component trb_net16_gbe_transmit_control2 is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	TC_DATAREADY_IN        : in 	std_logic;
	TC_RD_EN_OUT		        : out	std_logic;
	TC_DATA_IN		        : in	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_MAX_FRAME_IN         : in std_logic_vector(15 downto 0);

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

	MONITOR_TX_PACKETS_OUT : out std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_event_constr is
generic (
	READOUT_BUFFER_SIZE : integer range 1 to 4 := 1
);
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(7 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_START_OF_SUB_IN      : in    std_logic;
	PC_END_OF_SUB_IN        : in    std_logic;  -- gk 07.10.10
	PC_END_OF_QUEUE_IN      : in    std_logic;
	-- queue and subevent layer headers
	PC_SUB_SIZE_IN          : in    std_logic_vector(31 downto 0); -- store and swap
	PC_DECODING_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_EVENT_ID_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_TRIG_NR_IN           : in    std_logic_vector(31 downto 0); -- store and swap!
	PC_TRIGGER_TYPE_IN      : in	std_logic_vector(3 downto 0);
	PC_QUEUE_DEC_IN         : in    std_logic_vector(31 downto 0); -- swap
	PC_INSERT_TTYPE_IN      : in    std_logic;
	-- FrameConstructor ports
	TC_RD_EN_IN             : in    std_logic;
	TC_DATA_OUT             : out   std_logic_vector(8 downto 0);
	TC_EVENT_SIZE_OUT       : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_ipu_interface is
	port (
	CLK_IPU                     : in    std_logic;
	CLK_GBE                     : in	std_logic;
	RESET                       : in    std_logic;
	-- IPU interface directed toward the CTS
	CTS_NUMBER_IN               : in    std_logic_vector (15 downto 0);
	CTS_CODE_IN                 : in    std_logic_vector (7  downto 0);
	CTS_INFORMATION_IN          : in    std_logic_vector (7  downto 0);
	CTS_READOUT_TYPE_IN         : in    std_logic_vector (3  downto 0);
	CTS_START_READOUT_IN        : in    std_logic;
	CTS_READ_IN                 : in    std_logic;
	CTS_DATA_OUT                : out   std_logic_vector (31 downto 0);
	CTS_DATAREADY_OUT           : out   std_logic;
	CTS_READOUT_FINISHED_OUT    : out   std_logic;      --no more data, end transfer, send TRM
	CTS_LENGTH_OUT              : out   std_logic_vector (15 downto 0);
	CTS_ERROR_PATTERN_OUT       : out   std_logic_vector (31 downto 0);
	-- Data from Frontends
	FEE_DATA_IN                 : in    std_logic_vector (15 downto 0);
	FEE_DATAREADY_IN            : in    std_logic;
	FEE_READ_OUT                : out   std_logic;
	FEE_BUSY_IN                 : in    std_logic;
	FEE_STATUS_BITS_IN          : in    std_logic_vector (31 downto 0);
	-- slow control interface
	START_CONFIG_OUT			: out	std_logic; -- reconfigure MACs/IPs/ports/packet size
	BANK_SELECT_OUT				: out	std_logic_vector(3 downto 0); -- configuration page address
	CONFIG_DONE_IN				: in	std_logic; -- configuration finished
	DATA_GBE_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to GbE
	DATA_IPU_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to CTS / TRBnet
	MULT_EVT_ENABLE_IN			: in    std_logic;
	MAX_SUBEVENT_SIZE_IN		: in	std_logic_vector(15 downto 0);
	MAX_QUEUE_SIZE_IN           : in    std_logic_vector(15 downto 0);
	MAX_SUBS_IN_QUEUE_IN        : in    std_logic_vector(15 downto 0);
	MAX_SINGLE_SUB_SIZE_IN      : in    std_logic_vector(15 downto 0);
	READOUT_CTR_IN				: in	std_logic_vector(23 downto 0); -- gk 26.04.10
	READOUT_CTR_VALID_IN		: in	std_logic; -- gk 26.04.10
	-- PacketConstructor interface
	PC_WR_EN_OUT                : out   std_logic;
	PC_DATA_OUT                 : out   std_logic_vector (7 downto 0);
	PC_READY_IN                 : in    std_logic;
	PC_SOS_OUT                  : out   std_logic;
	PC_EOS_OUT                  : out   std_logic;
	PC_EOQ_OUT                  : out   std_logic;
	PC_SUB_SIZE_OUT             : out   std_logic_vector(31 downto 0);
	PC_TRIG_NR_OUT              : out   std_logic_vector(31 downto 0);
	PC_TRIGGER_TYPE_OUT         : out	std_logic_vector(3 downto 0);
	MONITOR_OUT                 : out   std_logic_vector(223 downto 0);
	DEBUG_OUT                   : out   std_logic_vector(383 downto 0)
	);
end component;

component gbe_ipu_dummy is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		INCREMENTAL_MODE : integer range 0 to 1 := 0;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		UP_DOWN_MODE : integer range 0 to 1 := 0;
		UP_DOWN_LIMIT : integer range 0 to 16777215 := 0;
		FIXED_DELAY : integer range 0 to 16777215 := 16777215
		);
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

component gbe_sctrl_dummy is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		FIXED_DELAY : integer range 0 to 65535 := 4096	
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		
		RC_RD_EN_IN		: in	std_logic;
		RC_Q_OUT		: out	std_logic_vector(8 downto 0);
		RC_FRAME_WAITING_OUT	: out	std_logic;
		RC_LOADING_DONE_IN	: in	std_logic;
		RC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
		RC_FRAME_PROTO_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
		
		RC_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
		RC_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
		RC_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
		RC_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
		RC_SRC_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
		RC_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
		
		GSC_REPLY_DATAREADY_OUT   : out std_logic;
		GSC_REPLY_DATA_OUT        : out std_logic_vector(15 downto 0);
		GSC_REPLY_PACKET_NUM_OUT  : out std_logic_vector(2 downto 0);
		GSC_REPLY_READ_IN       : in std_logic;
		GSC_BUSY_OUT              : out std_logic
	);
end component;

component trb_net16_gbe_buf is
generic( 
	DO_SIMULATION		: integer range 0 to 1 := 1;
	RX_PATH_ENABLE      : integer range 0 to 1 := 1;
	USE_INTERNAL_TRBNET_DUMMY : integer range 0 to 1 := 0;
	USE_125MHZ_EXTCLK       : integer range 0 to 1 := 1;
		
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		INCREMENTAL_MODE : integer range 0 to 1 := 0;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		UP_DOWN_MODE : integer range 0 to 1 := 0;
		UP_DOWN_LIMIT : integer range 0 to 16777215 := 0;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		FIXED_DELAY : integer range 0 to 16777215 := 16777215
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


component trb_net16_gbe_protocol_prioritizer is
port (
	CLK			: in	std_logic;
	RESET			: in	std_logic;
	
	FRAME_TYPE_IN		: in	std_logic_vector(15 downto 0);  -- recovered frame type	
	PROTOCOL_CODE_IN	: in	std_logic_vector(7 downto 0);  -- ip protocol
	UDP_PROTOCOL_IN		: in	std_logic_vector(15 downto 0);
	
	CODE_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0)
);
end component;

component trb_net16_gbe_type_validator is
port (
	CLK			: in	std_logic;
	RESET			: in	std_logic;
	FRAME_TYPE_IN		: in	std_logic_vector(15 downto 0);  -- recovered frame type	
	SAVED_VLAN_ID_IN	: in	std_logic_vector(15 downto 0);  -- recovered vlan id
	ALLOWED_TYPES_IN	: in	std_logic_vector(31 downto 0);  -- signal from gbe_setup
	VLAN_ID_IN		: in	std_logic_vector(31 downto 0);  -- two values from gbe setup

	-- IP level
	IP_PROTOCOLS_IN		: in	std_logic_vector(7 downto 0);
	ALLOWED_IP_PROTOCOLS_IN	: in	std_logic_vector(31 downto 0);
	
	-- UDP level
	UDP_PROTOCOL_IN		: in	std_logic_vector(15 downto 0);
	ALLOWED_UDP_PROTOCOLS_IN : in	std_logic_vector(31 downto 0);
	
	VALID_OUT		: out	std_logic
);
end component;

component trb_net16_gbe_protocol_selector is
generic(
		RX_PATH_ENABLE : integer range 0 to 1 := 1;
		DO_SIMULATION  : integer range 0 to 1 := 0;
		
		INCLUDE_READOUT  : std_logic := '0';
		INCLUDE_SLOWCTRL : std_logic := '0';
		INCLUDE_DHCP     : std_logic := '0';
		INCLUDE_ARP      : std_logic := '0';
		INCLUDE_PING     : std_logic := '0';
		
		READOUT_BUFFER_SIZE : integer range 1 to 4;
		SLOWCTRL_BUFFER_SIZE : integer range 1 to 4 
	);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	RESET_FOR_DHCP : in std_logic;

-- signals to/from main controller
	PS_DATA_IN		: in	std_logic_vector(8 downto 0); 
	PS_WR_EN_IN		: in	std_logic;
	PS_PROTO_SELECT_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_BUSY_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	PS_RESPONSE_READY_OUT	: out	std_logic;
	
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
-- singals to/from transmi controller with constructed response
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_IDENT_OUT        : out   std_logic_vector(15 downto 0);
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	MC_BUSY_IN          : in	std_logic;
	
	-- misc signals for response constructors
	MY_MAC_IN			: in	std_logic_vector(47 downto 0);
	MY_IP_OUT			: out	std_logic_vector(31 downto 0);	
	DHCP_START_IN		: in	std_logic;
	DHCP_DONE_OUT		: out	std_logic;
		
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
	
	-- signal for data readout
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
	-- ip configurator
	SLV_ADDR_IN                  : in std_logic_vector(7 downto 0);
	SLV_READ_IN                  : in std_logic;
	SLV_WRITE_IN                 : in std_logic;
	SLV_BUSY_OUT                 : out std_logic;
	SLV_ACK_OUT                  : out std_logic;
	SLV_DATA_IN                  : in std_logic_vector(31 downto 0);
	SLV_DATA_OUT                 : out std_logic_vector(31 downto 0);
	
	CFG_GBE_ENABLE_IN            : in std_logic;                    
	CFG_IPU_ENABLE_IN            : in std_logic;                    
	CFG_MULT_ENABLE_IN           : in std_logic;                    
	CFG_SUBEVENT_ID_IN			 : in std_logic_vector(31 downto 0);
	CFG_SUBEVENT_DEC_IN          : in std_logic_vector(31 downto 0);
	CFG_QUEUE_DEC_IN             : in std_logic_vector(31 downto 0);
	CFG_READOUT_CTR_IN           : in std_logic_vector(23 downto 0);
	CFG_READOUT_CTR_VALID_IN     : in std_logic;
	CFG_INSERT_TTYPE_IN          : in std_logic;
	CFG_MAX_SUB_IN               : in std_logic_vector(15 downto 0);
	CFG_MAX_QUEUE_IN             : in std_logic_vector(15 downto 0);
	CFG_MAX_SUBS_IN_QUEUE_IN     : in std_logic_vector(15 downto 0);
	CFG_MAX_SINGLE_SUB_IN        : in std_logic_vector(15 downto 0);
	  
	CFG_ADDITIONAL_HDR_IN        : in std_logic;
	CFG_MAX_REPLY_SIZE_IN        : in std_logic_vector(31 downto 0);
	
	-- input for statistics from outside	
	STAT_DATA_IN             : in std_logic_vector(31 downto 0);
	STAT_ADDR_IN             : in std_logic_vector(7 downto 0);
	STAT_DATA_RDY_IN         : in std_logic;
	STAT_DATA_ACK_OUT        : out std_logic;
	
	MONITOR_SELECT_REC_OUT	      : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_REC_BYTES_OUT  : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_BYTES_OUT : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_OUT	      : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_IN_OUT    : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_OUT_OUT   : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_GEN_DBG_OUT    : out	std_logic_vector(2*c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DATA_HIST_OUT : out hist_array;
	SCTRL_HIST_OUT : out hist_array 	
);
end component;

component trb_net16_gbe_mac_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	MC_TSMAC_READY_OUT	: out	std_logic;
	MC_RECONF_IN		: in	std_logic;
	MC_GBE_EN_IN		: in	std_logic;
	MC_RX_DISCARD_FCS	: in	std_logic;
	MC_PROMISC_IN		: in	std_logic;
	MC_MAC_ADDR_IN		: in	std_logic_vector(47 downto 0);

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HDATA_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HCS_N_OUT		: out	std_logic;
	TSM_HWRITE_N_OUT	: out	std_logic;
	TSM_HREAD_N_OUT		: out	std_logic;
	TSM_HREADY_N_IN		: in	std_logic;
	TSM_HDATA_EN_N_IN	: in	std_logic;

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_main_control is
generic(
		RX_PATH_ENABLE : integer range 0 to 1 := 1;
		DO_SIMULATION  : integer range 0 to 1 := 0;
		
		INCLUDE_READOUT  : std_logic := '0';
		INCLUDE_SLOWCTRL : std_logic := '0';
		INCLUDE_DHCP     : std_logic := '0';
		INCLUDE_ARP      : std_logic := '0';
		INCLUDE_PING     : std_logic := '0';
		
		READOUT_BUFFER_SIZE : integer range 1 to 4;
		SLOWCTRL_BUFFER_SIZE : integer range 1 to 4 
	);
port (
	CLK			: in	std_logic;  -- system clock
	CLK_125			: in	std_logic;
	RESET			: in	std_logic;

	MC_LINK_OK_OUT		: out	std_logic;
	MC_RESET_LINK_IN	: in	std_logic;
	MC_IDLE_TOO_LONG_OUT : out std_logic;
	MC_DHCP_DONE_OUT : out std_logic;
	MC_MY_MAC_OUT : out std_logic_vector(47 downto 0);
	MC_MY_MAC_IN : in std_logic_vector(47 downto 0);

-- signals to/from receive controller
	RC_FRAME_WAITING_IN	: in	std_logic;
	RC_LOADING_DONE_OUT	: out	std_logic;
	RC_DATA_IN		: in	std_logic_vector(8 downto 0);
	RC_RD_EN_OUT		: out	std_logic;
	RC_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	
	RC_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);

-- signals to/from transmit controller
	TC_TRANSMIT_CTRL_OUT	: out	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_IDENT_OUT        : out   std_logic_vector(15 downto 0);
	TC_TRANSMIT_DONE_IN	: in	std_logic;

-- signals to/from sgmii/gbe pcs_an_complete
	PCS_AN_COMPLETE_IN	: in	std_logic;

-- signals to/from hub
	MC_UNIQUE_ID_IN		: in	std_logic_vector(63 downto 0);
	
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
	
	-- signal for data readout
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
	-- ip configurator
	SLV_ADDR_IN                  : in std_logic_vector(7 downto 0);
	SLV_READ_IN                  : in std_logic;
	SLV_WRITE_IN                 : in std_logic;
	SLV_BUSY_OUT                 : out std_logic;
	SLV_ACK_OUT                  : out std_logic;
	SLV_DATA_IN                  : in std_logic_vector(31 downto 0);
	SLV_DATA_OUT                 : out std_logic_vector(31 downto 0);
	
	CFG_GBE_ENABLE_IN            : in std_logic;                    
	CFG_IPU_ENABLE_IN            : in std_logic;                    
	CFG_MULT_ENABLE_IN           : in std_logic;                    
	CFG_SUBEVENT_ID_IN			 : in std_logic_vector(31 downto 0);
	CFG_SUBEVENT_DEC_IN          : in std_logic_vector(31 downto 0);
	CFG_QUEUE_DEC_IN             : in std_logic_vector(31 downto 0);
	CFG_READOUT_CTR_IN           : in std_logic_vector(23 downto 0);
	CFG_READOUT_CTR_VALID_IN     : in std_logic;
	CFG_INSERT_TTYPE_IN          : in std_logic;
	CFG_MAX_SUB_IN               : in std_logic_vector(15 downto 0);
	CFG_MAX_QUEUE_IN             : in std_logic_vector(15 downto 0);
	CFG_MAX_SUBS_IN_QUEUE_IN     : in std_logic_vector(15 downto 0);
	CFG_MAX_SINGLE_SUB_IN        : in std_logic_vector(15 downto 0);
	  
	CFG_ADDITIONAL_HDR_IN        : in std_logic;      
	CFG_MAX_REPLY_SIZE_IN        : in std_logic_vector(31 downto 0);
	
	MAKE_RESET_OUT           	: out std_logic;
	
-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HDATA_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HCS_N_OUT		: out	std_logic;
	TSM_HWRITE_N_OUT	: out	std_logic;
	TSM_HREAD_N_OUT		: out	std_logic;
	TSM_HREADY_N_IN		: in	std_logic;
	TSM_HDATA_EN_N_IN	: in	std_logic;
	TSM_RX_STAT_VEC_IN  : in    std_logic_vector(31 downto 0);
	TSM_RX_STAT_EN_IN   : in	std_logic;
	
	MAC_READY_CONF_IN		: in	std_logic;
	MAC_RECONF_OUT			: out	std_logic;

	
	MONITOR_SELECT_REC_OUT	      : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_REC_BYTES_OUT  : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_BYTES_OUT : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_OUT	      : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_IN_OUT    : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_OUT_OUT   : out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_GEN_DBG_OUT    : out	std_logic_vector(2*c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DATA_HIST_OUT : out hist_array;
	SCTRL_HIST_OUT : out hist_array
);
end component;

component trb_net16_gbe_transmit_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signal to/from main controller
	MC_TRANSMIT_CTRL_IN	: in	std_logic;  -- slow control frame is waiting to be built and sent
	MC_DATA_IN		: in	std_logic_vector(8 downto 0);
	MC_DATA_NOT_VALID_IN : in std_logic;
	MC_WR_EN_IN   		 : in	std_logic;
	MC_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	MC_FRAME_TYPE_IN	: in	std_logic_vector(15 downto 0);
	
	MC_DEST_MAC_IN		: in	std_logic_vector(47 downto 0);
	MC_DEST_IP_IN		: in	std_logic_vector(31 downto 0);
	MC_DEST_UDP_IN		: in	std_logic_vector(15 downto 0);
	MC_SRC_MAC_IN		: in	std_logic_vector(47 downto 0);
	MC_SRC_IP_IN		: in	std_logic_vector(31 downto 0);
	MC_SRC_UDP_IN		: in	std_logic_vector(15 downto 0);
	
	MC_IP_PROTOCOL_IN	: in	std_logic_vector(7 downto 0);
	MC_IDENT_IN          : in   std_logic_vector(15 downto 0);
	
	MC_IP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	MC_UDP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	MC_FLAGS_OFFSET_IN	: in	std_logic_vector(15 downto 0);
	
	MC_FC_H_READY_OUT : out std_logic;
	MC_FC_READY_OUT : out std_logic;
	MC_FC_WR_EN_IN : in std_logic;
	
	MC_BUSY_OUT		: out	std_logic;
	MC_TRANSMIT_DONE_OUT	: out	std_logic;

-- signal to/from frame constructor
	FC_DATA_OUT		: out	std_logic_vector(7 downto 0);
	FC_WR_EN_OUT		: out	std_logic;
	FC_READY_IN		: in	std_logic;
	FC_H_READY_IN		: in	std_logic;
	FC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	FC_IP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	FC_UDP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	FC_IDENT_OUT		: out	std_logic_vector(15 downto 0);  -- internal packet counter
	FC_FLAGS_OFFSET_OUT	: out	std_logic_vector(15 downto 0);
	FC_SOD_OUT		: out	std_logic;
	FC_EOD_OUT		: out	std_logic;
	FC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);

	DEST_MAC_ADDRESS_OUT    : out    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_OUT     : out    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_OUT       : out    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_OUT     : out    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_OUT      : out    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_OUT        : out    std_logic_vector(15 downto 0);


-- debug
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_receive_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from frame_receiver
	RC_DATA_IN		: in	std_logic_vector(8 downto 0);
	FR_RD_EN_OUT		: out	std_logic;
	FR_FRAME_VALID_IN	: in	std_logic;
	FR_GET_FRAME_OUT	: out	std_logic;
	FR_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	FR_FRAME_PROTO_IN	: in	std_logic_vector(15 downto 0);
	FR_IP_PROTOCOL_IN	: in	std_logic_vector(7 downto 0);
	
	FR_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	FR_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	FR_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	FR_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	FR_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	FR_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);

-- signals to the rest of the logic
	RC_RD_EN_IN		: in	std_logic;
	RC_Q_OUT		: out	std_logic_vector(8 downto 0);
	RC_FRAME_WAITING_OUT	: out	std_logic;
	RC_LOADING_DONE_IN	: in	std_logic;
	RC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	
	RC_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);

-- statistics
	FRAMES_RECEIVED_OUT	: out	std_logic_vector(31 downto 0);
	BYTES_RECEIVED_OUT	: out	std_logic_vector(31 downto 0);


	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_frame_receiver is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	LINK_OK_IN              : in    std_logic;
	ALLOW_RX_IN		: in	std_logic;
	RX_MAC_CLK		: in	std_logic;  -- receiver serdes clock
	MY_MAC_IN		: in	std_logic_vector(47 downto 0);

-- input signals from TS_MAC
	MAC_RX_EOF_IN		: in	std_logic;
	MAC_RX_ER_IN		: in	std_logic;
	MAC_RXD_IN		: in	std_logic_vector(7 downto 0);
	MAC_RX_EN_IN		: in	std_logic;
	MAC_RX_FIFO_ERR_IN	: in	std_logic;
	MAC_RX_FIFO_FULL_OUT	: out	std_logic;
	MAC_RX_STAT_EN_IN	: in	std_logic;
	MAC_RX_STAT_VEC_IN	: in	std_logic_vector(31 downto 0);
-- output signal to control logic
	FR_Q_OUT		: out	std_logic_vector(8 downto 0);
	FR_RD_EN_IN		: in	std_logic;
	FR_FRAME_VALID_OUT	: out	std_logic;
	FR_GET_FRAME_IN		: in	std_logic;
	FR_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	FR_FRAME_PROTO_OUT	: out	std_logic_vector(15 downto 0);
	FR_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	FR_ALLOWED_TYPES_IN	: in	std_logic_vector(31 downto 0);
	FR_ALLOWED_IP_IN	: in	std_logic_vector(31 downto 0);
	FR_ALLOWED_UDP_IN	: in	std_logic_vector(31 downto 0);
	FR_VLAN_ID_IN		: in	std_logic_vector(31 downto 0);
	
	FR_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
	FR_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
	FR_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	FR_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	FR_SRC_UDP_PORT_OUT	    : out	std_logic_vector(15 downto 0);
	FR_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);

	MONITOR_RX_BYTES_OUT  : out	std_logic_vector(31 downto 0);
	MONITOR_RX_FRAMES_OUT : out	std_logic_vector(31 downto 0);
	MONITOR_DROPPED_OUT   : out	std_logic_vector(31 downto 0)
);
end component;

-- gk 01.07.10
component trb_net16_ipu2gbe is
port( 
	CLK                         : in    std_logic;
	RESET                       : in    std_logic;
	-- IPU interface directed toward the CTS
	CTS_NUMBER_IN               : in    std_logic_vector (15 downto 0);
	CTS_CODE_IN                 : in    std_logic_vector (7  downto 0);
	CTS_INFORMATION_IN          : in    std_logic_vector (7  downto 0);
	CTS_READOUT_TYPE_IN         : in    std_logic_vector (3  downto 0);
	CTS_START_READOUT_IN        : in    std_logic;
	CTS_READ_IN                 : in    std_logic;
	CTS_DATA_OUT                : out   std_logic_vector (31 downto 0);
	CTS_DATAREADY_OUT           : out   std_logic;
	CTS_READOUT_FINISHED_OUT    : out   std_logic;      --no more data, end transfer, send TRM
	CTS_LENGTH_OUT              : out   std_logic_vector (15 downto 0);
	CTS_ERROR_PATTERN_OUT       : out   std_logic_vector (31 downto 0);
	-- Data from Frontends
	FEE_DATA_IN                 : in    std_logic_vector (15 downto 0);
	FEE_DATAREADY_IN            : in    std_logic;
	FEE_READ_OUT                : out   std_logic;
	FEE_BUSY_IN                 : in    std_logic;
	FEE_STATUS_BITS_IN          : in    std_logic_vector (31 downto 0);
	-- slow control interface
	START_CONFIG_OUT			: out	std_logic; -- reconfigure MACs/IPs/ports/packet size
	BANK_SELECT_OUT				: out	std_logic_vector(3 downto 0); -- configuration page address
	CONFIG_DONE_IN				: in	std_logic; -- configuration finished
	DATA_GBE_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to GbE
	DATA_IPU_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to CTS / TRBnet
	MULT_EVT_ENABLE_IN			: in    std_logic;
	MAX_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- the maximum size of one HadesQueue  -- gk 08.04.10
	MIN_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- gk 20.07.10
	READOUT_CTR_IN				: in	std_logic_vector(23 downto 0); -- gk 26.04.10
	READOUT_CTR_VALID_IN			: in	std_logic; -- gk 26.04.10
	
--	SCTRL_DUMMY_SIZE_IN      : in std_logic_vector(15 downto 0);
--	SCTRL_DUMMY_PAUSE_IN     : in std_logic_vector(31 downto 0);
	
	-- PacketConstructor interface
	ALLOW_LARGE_IN				: in	std_logic;  -- gk 21.07.10
	PC_WR_EN_OUT                : out   std_logic;
	PC_DATA_OUT                 : out   std_logic_vector (7 downto 0);
	PC_READY_IN                 : in    std_logic;
	PC_SOS_OUT                  : out   std_logic;
	PC_EOS_OUT                  : out   std_logic; -- gk 07.10.10
	PC_EOD_OUT                  : out   std_logic;
	PC_SUB_SIZE_OUT             : out   std_logic_vector(31 downto 0);
	PC_TRIG_NR_OUT              : out   std_logic_vector(31 downto 0);
	PC_PADDING_OUT              : out   std_logic;
	MONITOR_OUT                 : out   std_logic_vector(223 downto 0);
	DEBUG_OUT                   : out   std_logic_vector(383 downto 0)
);
end component;

component trb_net16_gbe_packet_constr is
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	MULT_EVT_ENABLE_IN      : in    std_logic;  -- gk 06.10.10
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(7 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_START_OF_SUB_IN      : in    std_logic;
	PC_END_OF_SUB_IN        : in    std_logic;  -- gk 07.10.10
	PC_END_OF_DATA_IN       : in    std_logic;
	PC_TRANSMIT_ON_OUT	: out	std_logic;
	-- queue and subevent layer headers
	PC_SUB_SIZE_IN          : in    std_logic_vector(31 downto 0); -- store and swap
	PC_PADDING_IN           : in std_logic;  -- gk 29.03.10
	PC_DECODING_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_EVENT_ID_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_TRIG_NR_IN           : in    std_logic_vector(31 downto 0); -- store and swap!
	PC_QUEUE_DEC_IN         : in    std_logic_vector(31 downto 0); -- swap
	PC_MAX_FRAME_SIZE_IN    : in	std_logic_vector(15 downto 0); -- DO NOT SWAP
	PC_DELAY_IN             : in	std_logic_vector(31 downto 0);  -- gk 28.04.10
	-- FrameConstructor ports
	TC_WR_EN_OUT            : out   std_logic;
	TC_DATA_OUT             : out   std_logic_vector(7 downto 0);
	TC_H_READY_IN           : in    std_logic;
	TC_READY_IN             : in    std_logic;
	TC_IP_SIZE_OUT          : out   std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT         : out   std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT     : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	TC_EOD_OUT              : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_frame_constr is
generic (
	FRAME_BUFFER_SIZE : integer range 1 to 4 := 1
);
port( 
	-- ports for user logic
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	LINK_OK_IN              : in    std_logic;  -- gk 03.08.10
	--
	WR_EN_IN                : in    std_logic;
	DATA_IN                 : in    std_logic_vector(7 downto 0);
	START_OF_DATA_IN        : in    std_logic;
	END_OF_DATA_IN          : in    std_logic;
	IP_F_SIZE_IN            : in    std_logic_vector(15 downto 0);
	UDP_P_SIZE_IN           : in    std_logic_vector(15 downto 0); -- needed for fragmentation
	HEADERS_READY_OUT       : out   std_logic;
	READY_OUT               : out   std_logic;
	DEST_MAC_ADDRESS_IN     : in    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_IN      : in    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_IN        : in    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_IN      : in    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_IN       : in    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_IN         : in    std_logic_vector(15 downto 0);
	FRAME_TYPE_IN           : in    std_logic_vector(15 downto 0);
	IHL_VERSION_IN          : in    std_logic_vector(7 downto 0);
	TOS_IN                  : in    std_logic_vector(7 downto 0);
	IDENTIFICATION_IN       : in    std_logic_vector(15 downto 0);
	FLAGS_OFFSET_IN         : in    std_logic_vector(15 downto 0);
	TTL_IN                  : in    std_logic_vector(7 downto 0);
	PROTOCOL_IN             : in    std_logic_vector(7 downto 0);
	FRAME_DELAY_IN		: in	std_logic_vector(31 downto 0);
	-- ports for packetTransmitter
	RD_CLK                  : in    std_logic; -- 125MHz clock!!!
	FT_DATA_OUT             : out   std_logic_vector(8 downto 0);
	FT_TX_EMPTY_OUT         : out   std_logic;
	FT_TX_RD_EN_IN          : in    std_logic;
	FT_START_OF_PACKET_OUT  : out   std_logic;
	FT_TX_DONE_IN           : in    std_logic;
	FT_TX_DISCFRM_IN	: in	std_logic;
	
	MONITOR_TX_BYTES_OUT    : out std_logic_vector(31 downto 0);
	MONITOR_TX_FRAMES_OUT   : out std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_frame_trans is
port (
	CLK					: in	std_logic;
	RESET				: in	std_logic;
	LINK_OK_IN              : in    std_logic;  -- gk 03.08.10
	TX_MAC_CLK			: in	std_logic;
	TX_EMPTY_IN			: in	std_logic;
	START_OF_PACKET_IN	: in	std_logic;
	DATA_ENDFLAG_IN		: in	std_logic; -- (8) is end flag, rest is only for TSMAC
	-- NEW PORTS
-- 	HADDR_OUT			: out	std_logic_vector(7 downto 0);
-- 	HDATA_OUT			: out	std_logic_vector(7 downto 0);
-- 	HCS_OUT				: out	std_logic;
-- 	HWRITE_OUT			: out	std_logic;
-- 	HREAD_OUT			: out	std_logic;
-- 	HREADY_IN			: in	std_logic;
-- 	HDATA_EN_IN			: in	std_logic;
	TX_FIFOAVAIL_OUT	: out	std_logic;
	TX_FIFOEOF_OUT		: out	std_logic;
	TX_FIFOEMPTY_OUT	: out	std_logic;
	TX_DONE_IN			: in	std_logic;
	TX_STAT_EN_IN		: in	std_logic;
	TX_STATVEC_IN		: in	std_logic_vector(30 downto 0);
	TX_DISCFRM_IN		: in 	std_logic;
	-- Debug
	BSM_INIT_OUT		: out	std_logic_vector(3 downto 0);
	BSM_MAC_OUT			: out	std_logic_vector(3 downto 0);
	BSM_TRANS_OUT		: out	std_logic_vector(3 downto 0);
	DBG_RD_DONE_OUT		: out	std_logic;
	DBG_INIT_DONE_OUT	: out	std_logic;
	DBG_ENABLED_OUT		: out	std_logic;
	DEBUG_OUT			: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_med_ecp_sfp_gbe_8b is
-- gk 28.04.10
generic (
	USE_125MHZ_EXTCLK			: integer range 0 to 1 := 1
);
port(
	RESET					: in	std_logic;
	GSR_N					: in	std_logic;
	CLK_125_OUT				: out	std_logic;
	CLK_125_RX_OUT				: out	std_logic;
	CLK_125_IN				: in std_logic;  -- gk 28.04.10  used when intclk
	--SGMII connection to frame transmitter (tsmac)
	FT_TX_CLK_EN_OUT		: out	std_logic;
	FT_RX_CLK_EN_OUT		: out	std_logic;
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
	SD_TXD_P_OUT			: out	std_logic;
	SD_TXD_N_OUT			: out	std_logic;
	SD_REFCLK_P_IN			: in	std_logic;
	SD_REFCLK_N_IN			: in	std_logic;
	SD_PRSNT_N_IN			: in	std_logic; -- SFP Present ('0' = SFP in place, '1' = no SFP mounted)
	SD_LOS_IN				: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	SD_TXDIS_OUT			: out	std_logic; -- SFP disable
	-- Autonegotiation stuff
	MR_RESET_IN				: in	std_logic;
	MR_MODE_IN				: in	std_logic;
	MR_ADV_ABILITY_IN		: in 	std_logic_vector(15 downto 0);
	MR_AN_LP_ABILITY_OUT	: out	std_logic_vector(15 downto 0);
	MR_AN_PAGE_RX_OUT		: out	std_logic;
	MR_AN_COMPLETE_OUT		: out	std_logic; 
	MR_AN_ENABLE_IN			: in	std_logic;
	MR_RESTART_AN_IN		: in	std_logic;
	-- Status and control port
	STAT_OP					: out	std_logic_vector (15 downto 0);
	CTRL_OP					: in	std_logic_vector (15 downto 0);
	STAT_DEBUG				: out	std_logic_vector (63 downto 0);
	CTRL_DEBUG				: in	std_logic_vector (63 downto 0)
);
end component;

component gbe_setup is
port(
	CLK                       : in std_logic;
	RESET                     : in std_logic;

	-- interface to regio bus
	BUS_ADDR_IN               : in std_logic_vector(7 downto 0);
	BUS_DATA_IN               : in std_logic_vector(31 downto 0);
	BUS_DATA_OUT              : out std_logic_vector(31 downto 0);
	BUS_WRITE_EN_IN           : in std_logic;
	BUS_READ_EN_IN            : in std_logic;
	BUS_ACK_OUT               : out std_logic;

	-- output to gbe_buf
	GBE_SUBEVENT_ID_OUT       : out std_logic_vector(31 downto 0);
	GBE_SUBEVENT_DEC_OUT      : out std_logic_vector(31 downto 0);
	GBE_QUEUE_DEC_OUT         : out std_logic_vector(31 downto 0);
	GBE_MAX_FRAME_OUT         : out std_logic_vector(15 downto 0);
	GBE_USE_GBE_OUT           : out std_logic;
	GBE_USE_TRBNET_OUT        : out std_logic;
	GBE_USE_MULTIEVENTS_OUT   : out std_logic;
	GBE_READOUT_CTR_OUT       : out std_logic_vector(23 downto 0);
	GBE_READOUT_CTR_VALID_OUT : out std_logic;
	GBE_ALLOW_RX_OUT          : out std_logic;
	GBE_ADDITIONAL_HDR_OUT    : out std_logic;
	GBE_INSERT_TTYPE_OUT      : out std_logic;
	GBE_SOFT_RESET_OUT        : out std_logic;
	GBE_MAX_REPLY_OUT         : out std_logic_vector(31 downto 0);
	
	GBE_MAX_SUB_OUT           : out std_logic_vector(15 downto 0);
	GBE_MAX_QUEUE_OUT         : out std_logic_vector(15 downto 0);
	GBE_MAX_SUBS_IN_QUEUE_OUT : out std_logic_vector(15 downto 0);
	GBE_MAX_SINGLE_SUB_OUT    : out std_logic_vector(15 downto 0);
	
	MONITOR_RX_BYTES_IN       : in std_logic_vector(31 downto 0);
	MONITOR_RX_FRAMES_IN      : in std_logic_vector(31 downto 0);
	MONITOR_TX_BYTES_IN       : in std_logic_vector(31 downto 0);
	MONITOR_TX_FRAMES_IN      : in std_logic_vector(31 downto 0);
	MONITOR_TX_PACKETS_IN     : in std_logic_vector(31 downto 0);
	MONITOR_DROPPED_IN        : in std_logic_vector(31 downto 0);
	
	MONITOR_SELECT_REC_IN	      : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_REC_BYTES_IN   : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_BYTES_IN  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_IN	      : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_IN_IN	  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_OUT_IN	  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_GEN_DBG_IN     : in	std_logic_vector(2*c_MAX_PROTOCOLS * 32 - 1 downto 0);
		
	DUMMY_EVENT_SIZE_OUT : out std_logic_vector(15 downto 0);
	DUMMY_TRIGGERED_MODE_OUT : out std_logic;
	
	DATA_HIST_IN : in hist_array;
	SCTRL_HIST_IN : in hist_array
);
end component;


component ip_configurator is
port( 
	CLK							: in	std_logic;
	RESET						: in	std_logic;
	-- configuration interface
	START_CONFIG_IN				: in	std_logic; -- start configuration run
	BANK_SELECT_IN				: in	std_logic_vector(3 downto 0); -- selects config bank 
	CONFIG_DONE_OUT				: out	std_logic; -- configuration run ended, new values can be used
	MEM_ADDR_OUT				: out	std_logic_vector(7 downto 0); -- address for
	MEM_DATA_IN					: in	std_logic_vector(31 downto 0); -- data from IP memory
	MEM_CLK_OUT					: out	std_logic; -- clock for BlockRAM
	-- information for IP cores
	DEST_MAC_OUT				: out	std_logic_vector(47 downto 0); -- destination MAC address
	DEST_IP_OUT					: out	std_logic_vector(31 downto 0); -- destination IP address
	DEST_UDP_OUT				: out	std_logic_vector(15 downto 0); -- destination port
	SRC_MAC_OUT					: out	std_logic_vector(47 downto 0); -- source MAC address
	SRC_IP_OUT					: out	std_logic_vector(31 downto 0); -- source IP address
	SRC_UDP_OUT					: out	std_logic_vector(15 downto 0); -- source port
	MTU_OUT						: out	std_logic_vector(15 downto 0); -- MTU size (max frame size)
	-- Debug
	DEBUG_OUT					: out	std_logic_vector(31 downto 0)
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

component fifo_2048x8 is
port( 
	Data    : in    std_logic_vector(7 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(7 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component fifo_4096x32 is
port( 
	Data    : in    std_logic_vector(31 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(31 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component fifo_512x32 is
port( 
	Data    : in    std_logic_vector(31 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(31 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component fifo_512x72 is
port( 
	Data    : in    std_logic_vector(71 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(71 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component fifo_1024x16x8 is
port( 
	Data    : in    std_logic_vector(17 downto 0);
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

component fifo_65536x18x9 is
port( 
	Data    : in    std_logic_vector(17 downto 0);
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

component fifo_4kx18x9 is
port( 
	Data    : in    std_logic_vector(17 downto 0);
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


component fifo_2048x8x16 is
port( 
	Data    : in    std_logic_vector(8 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(17 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component fifo_4kx8_ecp3 is
port( 
	Data    : in    std_logic_vector(7 downto 0);
	WrClock : in    std_logic;
	RdClock : in    std_logic;
	WrEn    : in    std_logic;
	RdEn    : in    std_logic;
	Reset   : in    std_logic;
	RPReset : in    std_logic;
	Q       : out   std_logic_vector(7 downto 0);
	Empty   : out   std_logic;
	Full    : out   std_logic
);
end component;

component statts_mem is
    port (
        WrAddress: in  std_logic_vector(7 downto 0); 
        RdAddress: in  std_logic_vector(9 downto 0); 
        Data: in  std_logic_vector(31 downto 0); 
        WE: in  std_logic; 
        RdClock: in  std_logic; 
        RdClockEn: in  std_logic; 
        Reset: in  std_logic; 
        WrClock: in  std_logic; 
        WrClockEn: in  std_logic; 
        Q: out  std_logic_vector(7 downto 0));
end component;

--component slv_mac_memory is
--port( 
--	CLK             : in    std_logic;
--	RESET           : in    std_logic;
--	BUSY_IN         : in    std_logic;
--	-- Slave bus
--	SLV_ADDR_IN     : in    std_logic_vector(7 downto 0);
--	SLV_READ_IN     : in    std_logic;
--	SLV_WRITE_IN    : in    std_logic;
--	SLV_BUSY_OUT    : out   std_logic;
--	SLV_ACK_OUT     : out   std_logic;
--	SLV_DATA_IN     : in    std_logic_vector(31 downto 0);
--	SLV_DATA_OUT    : out   std_logic_vector(31 downto 0);
--	-- I/O to the backend
--	MEM_CLK_IN      : in    std_logic;
--	MEM_ADDR_IN     : in    std_logic_vector(7 downto 0);
--	MEM_DATA_OUT    : out   std_logic_vector(31 downto 0);
--	-- Status lines
--	 STAT           : out   std_logic_vector(31 downto 0) -- DEBUG
--);
--end component;

component fifo_32kx16x8_mb2
port( 
	Data            : in    std_logic_vector(17 downto 0); 
	WrClock         : in    std_logic;
	RdClock         : in    std_logic; 
	WrEn            : in    std_logic;
	RdEn            : in    std_logic;
	Reset           : in    std_logic; 
	RPReset         : in    std_logic; 
	AmEmptyThresh   : in    std_logic_vector(15 downto 0); 
	AmFullThresh    : in    std_logic_vector(14 downto 0); 
	Q               : out   std_logic_vector(8 downto 0); 
	WCNT            : out   std_logic_vector(15 downto 0); 
	RCNT            : out   std_logic_vector(16 downto 0);
	Empty           : out   std_logic;
	AlmostEmpty     : out   std_logic;
	Full            : out   std_logic;
	AlmostFull      : out   std_logic
);
end component;

component fifo_64kx9
port (
	Data        : in  std_logic_vector(8 downto 0); 
	WrClock     : in  std_logic; 
	RdClock     : in  std_logic; 
	WrEn        : in  std_logic; 
	RdEn        : in  std_logic; 
	Reset       : in  std_logic; 
	RPReset     : in  std_logic; 
	Q           : out  std_logic_vector(8 downto 0); 
	Empty       : out  std_logic; 
	Full        : out  std_logic
);
end component;

component fifo_16kx18x9 is
    port (
        Data: in  std_logic_vector(17 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        AmEmptyThresh: in  std_logic_vector(14 downto 0); 
        AmFullThresh: in  std_logic_vector(13 downto 0); 
        Q: out  std_logic_vector(8 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic; 
        AlmostEmpty: out  std_logic; 
        AlmostFull: out  std_logic);
end component;

component fifo_32kx9_flags is
    port (
        Data: in  std_logic_vector(8 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(8 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic;
        AlmostFull : out std_logic);
end component;


component fifo_512x32x8
port (
	Data        : in  std_logic_vector(31 downto 0); 
	WrClock     : in  std_logic; 
	RdClock     : in  std_logic; 
	WrEn        : in  std_logic; 
	RdEn        : in  std_logic; 
	Reset       : in  std_logic; 
	RPReset     : in  std_logic; 
	Q           : out  std_logic_vector(7 downto 0); 
	Empty       : out  std_logic; 
	Full        : out  std_logic
);
end component;

component fifo_512x8
port (
	Data        : in  std_logic_vector(7 downto 0);
	Clock       : in  std_logic; 
	WrEn        : in  std_logic; 
	RdEn        : in  std_logic; 
	Reset       : in  std_logic; 
	Q           : out  std_logic_vector(7 downto 0); 
	Empty       : out  std_logic; 
	Full        : out  std_logic
);
end component;

end package;