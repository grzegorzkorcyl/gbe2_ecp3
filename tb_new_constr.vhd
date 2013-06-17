LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.math_real.all;
USE ieee.numeric_std.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

ENTITY testbench IS
END testbench;

ARCHITECTURE behavior OF testbench IS 


signal CLK			: std_logic;
signal RESET			: std_logic;
signal LINK_OK_IN               : std_logic;
signal ALLOW_RX_IN		: std_logic;
signal RX_MAC_CLK		: std_logic;
signal MAC_RX_EOF_IN		: std_logic;
signal MAC_RX_ER_IN		: std_logic;
signal MAC_RXD_IN		: std_logic_vector(7 downto 0);
signal MAC_RX_EN_IN		: std_logic;
signal MAC_RX_FIFO_ERR_IN	: std_logic;
signal MAC_RX_FIFO_FULL_OUT	: std_logic;
signal MAC_RX_STAT_EN_IN	: std_logic;
signal MAC_RX_STAT_VEC_IN	: std_logic_vector(31 downto 0);
signal FR_Q_OUT			: std_logic_vector(8 downto 0);
signal FR_RD_EN_IN		: std_logic;
signal FR_FRAME_VALID_OUT	: std_logic;
signal FR_GET_FRAME_IN		: std_logic;
signal FR_FRAME_SIZE_OUT	: std_logic_vector(15 downto 0);
signal FR_FRAME_PROTO_OUT	: std_logic_vector(15 downto 0);
signal DEBUG_OUT		: std_logic_vector(95 downto 0);
signal	FR_ALLOWED_TYPES_IN	: std_logic_vector(31 downto 0);

signal	RC_RD_EN_IN		: std_logic;
signal	RC_Q_OUT		: std_logic_vector(8 downto 0);
signal	RC_FRAME_WAITING_OUT	: std_logic;
signal	RC_LOADING_DONE_IN	: std_logic;
signal	RC_FRAME_SIZE_OUT	: std_logic_vector(15 downto 0);
signal	FRAMES_RECEIVED_OUT	: std_logic_vector(31 downto 0);
signal	BYTES_RECEIVED_OUT	: std_logic_vector(31 downto 0);

signal MC_TRANSMIT_CTRL_OUT     : std_logic;
signal MC_TRANSMIT_DATA_OUT     : std_logic;
signal MC_DATA_OUT              : std_logic_vector(8 downto 0);
signal MC_RD_EN_IN              : std_logic;
signal MC_FRAME_SIZE_OUT        : std_logic_vector(15 downto 0);
signal MC_BUSY_IN               : std_logic;
signal MC_TRANSMIT_DONE_IN      : std_logic;
signal RC_FRAME_PROTO_OUT	: std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

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
signal mc_type                   : std_logic_vector(15 downto 0);
signal fc_ihl                    : std_logic_vector(7 downto 0);
signal fc_tos                    : std_logic_vector(7 downto 0);
signal fc_ident                  : std_logic_vector(15 downto 0);
signal fc_flags                  : std_logic_vector(15 downto 0);
signal fc_ttl                    : std_logic_vector(7 downto 0);
signal fc_proto                  : std_logic_vector(7 downto 0);
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

signal mc_dest_mac               : std_logic_vector(47 downto 0);
signal mc_dest_ip                : std_logic_vector(31 downto 0);
signal mc_dest_udp               : std_logic_vector(15 downto 0);
signal mc_src_mac                : std_logic_vector(47 downto 0);
signal mc_src_ip                 : std_logic_vector(31 downto 0);
signal mc_src_udp                : std_logic_vector(15 downto 0);

signal fr_allowed_ip             : std_logic_vector(31 downto 0);
signal fr_allowed_udp            : std_logic_vector(31 downto 0);

signal fr_ip_proto               : std_logic_vector(7 downto 0);
signal mc_ip_proto               : std_logic_vector(7 downto 0);

signal additional_rand_pause     : std_logic;

signal pc_ready, pc_sos, pc_transmit_on, pc_wr_en, pc_sod, pc_eod, pc_fc_h_ready, pc_fc_ready : std_logic;
signal pc_data : std_logic_vector(7 downto 0);
signal pc_ip_size, pc_udp_size : std_logic_vector(15 downto 0);
signal gsc_init_read, gsc_init_dataready : std_logic;
signal gsc_reply_read, gsc_reply_dataready : std_logic;
signal gsc_reply_data, gsc_init_data : std_logic_vector(15 downto 0);
signal gsc_busy : std_logic;
signal gsc_init_packet_num, gsc_reply_packet_num : std_logic_vector(2 downto 0);
signal mc_flags, mc_ip_size, mc_udp_size : std_logic_vector(15 downto 0);

signal mc_fc_wr_en, mc_fc_ready, mc_fc_h_ready, data_not_valid : std_logic;

BEGIN

receiver : trb_net16_gbe_frame_receiver
port map (
	CLK			=> CLK,
	RESET			=> RESET,
	LINK_OK_IN              => LINK_OK_IN,
	ALLOW_RX_IN		=> ALLOW_RX_IN,
	RX_MAC_CLK		=> RX_MAC_CLK,

	MAC_RX_EOF_IN		=> MAC_RX_EOF_IN,
	MAC_RX_ER_IN		=> MAC_RX_ER_IN,
	MAC_RXD_IN		=> MAC_RXD_IN,
	MAC_RX_EN_IN		=> MAC_RX_EN_IN,
	MAC_RX_FIFO_ERR_IN	=> MAC_RX_FIFO_ERR_IN,
	MAC_RX_FIFO_FULL_OUT	=> MAC_RX_FIFO_FULL_OUT,
	MAC_RX_STAT_EN_IN	=> MAC_RX_STAT_EN_IN,
	MAC_RX_STAT_VEC_IN	=> MAC_RX_STAT_VEC_IN,

	FR_Q_OUT		=> FR_Q_OUT,
	FR_RD_EN_IN		=> FR_RD_EN_IN,
	FR_FRAME_VALID_OUT	=> FR_FRAME_VALID_OUT,
	FR_GET_FRAME_IN		=> FR_GET_FRAME_IN,
	FR_FRAME_SIZE_OUT	=> FR_FRAME_SIZE_OUT,
	FR_FRAME_PROTO_OUT	=> FR_FRAME_PROTO_OUT,
	FR_IP_PROTOCOL_OUT	=> fr_ip_proto,
	FR_ALLOWED_TYPES_IN     => FR_ALLOWED_TYPES_IN,
	FR_ALLOWED_IP_IN        => fr_allowed_ip,
	FR_ALLOWED_UDP_IN       => fr_allowed_udp,
	FR_VLAN_ID_IN		=> x"aabb_0000",
	
	FR_SRC_MAC_ADDRESS_OUT	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_OUT => fr_dest_mac,
	FR_SRC_IP_ADDRESS_OUT	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_OUT	=> fr_dest_ip,
	FR_SRC_UDP_PORT_OUT	=> fr_src_udp,
	FR_DEST_UDP_PORT_OUT	=> fr_dest_udp,

	DEBUG_OUT		=> DEBUG_OUT
);

receive_controler : trb_net16_gbe_receive_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signals to/from frame_receiver
	RC_DATA_IN		=> FR_Q_OUT,
	FR_RD_EN_OUT		=> FR_RD_EN_IN,
	FR_FRAME_VALID_IN	=> FR_FRAME_VALID_OUT,
	FR_GET_FRAME_OUT	=> FR_GET_FRAME_IN,
	FR_FRAME_SIZE_IN	=> FR_FRAME_SIZE_OUT,
	FR_FRAME_PROTO_IN	=> FR_FRAME_PROTO_OUT,
	FR_IP_PROTOCOL_IN	=> fr_ip_proto,
	
	FR_SRC_MAC_ADDRESS_IN	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_IN  => fr_dest_mac,
	FR_SRC_IP_ADDRESS_IN	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_IN	=> fr_dest_ip,
	FR_SRC_UDP_PORT_IN	=> fr_src_udp,
	FR_DEST_UDP_PORT_IN	=> fr_dest_udp,

-- signals to/from main controller
	RC_RD_EN_IN		=> RC_RD_EN_IN,
	RC_Q_OUT		=> RC_Q_OUT,
	RC_FRAME_WAITING_OUT	=> RC_FRAME_WAITING_OUT,
	RC_LOADING_DONE_IN	=> RC_LOADING_DONE_IN,
	RC_FRAME_SIZE_OUT	=> RC_FRAME_SIZE_OUT,
	RC_FRAME_PROTO_OUT	=> RC_FRAME_PROTO_OUT,

	RC_SRC_MAC_ADDRESS_OUT	=> rc_src_mac,
	RC_DEST_MAC_ADDRESS_OUT => rc_dest_mac,
	RC_SRC_IP_ADDRESS_OUT	=> rc_src_ip,
	RC_DEST_IP_ADDRESS_OUT	=> rc_dest_ip,
	RC_SRC_UDP_PORT_OUT	=> rc_src_udp,
	RC_DEST_UDP_PORT_OUT	=> rc_dest_udp,

-- statistics
	FRAMES_RECEIVED_OUT	=> open,
	BYTES_RECEIVED_OUT	=> open,

	DEBUG_OUT		=> open
);

main_controller : trb_net16_gbe_main_control
port map (
	CLK			=> CLK,
	CLK_125			=> RX_MAC_CLK,
	RESET			=> RESET,

	MC_LINK_OK_OUT		=> open,
	MC_RESET_LINK_IN	=> '0',
	MC_IDLE_TOO_LONG_OUT => open,

-- signals to/from receive controller
	RC_FRAME_WAITING_IN	=> RC_FRAME_WAITING_OUT,
	RC_LOADING_DONE_OUT	=> RC_LOADING_DONE_IN,
	RC_DATA_IN		=> RC_Q_OUT,
	RC_RD_EN_OUT		=> RC_RD_EN_IN,
	RC_FRAME_SIZE_IN	=> RC_FRAME_SIZE_OUT,
	RC_FRAME_PROTO_IN	=> RC_FRAME_PROTO_OUT,

	RC_SRC_MAC_ADDRESS_IN	=> rc_src_mac,
	RC_DEST_MAC_ADDRESS_IN  => rc_dest_mac,
	RC_SRC_IP_ADDRESS_IN	=> rc_src_ip,
	RC_DEST_IP_ADDRESS_IN	=> rc_dest_ip,
	RC_SRC_UDP_PORT_IN	=> rc_src_udp,
	RC_DEST_UDP_PORT_IN	=> rc_dest_udp,

-- signals to/from transmit controller
	TC_TRANSMIT_CTRL_OUT	=> MC_TRANSMIT_CTRL_OUT,
	TC_DATA_OUT		=> MC_DATA_OUT,
	TC_WR_EN_OUT		=> MC_RD_EN_IN,
	TC_FRAME_SIZE_OUT	=> MC_FRAME_SIZE_OUT,
	TC_FRAME_TYPE_OUT	=> mc_type,
	TC_IP_PROTOCOL_OUT	=> mc_ip_proto,
	
	TC_DEST_MAC_OUT		=> mc_dest_mac,
	TC_DEST_IP_OUT		=> mc_dest_ip,
	TC_DEST_UDP_OUT		=> mc_dest_udp,
	TC_SRC_MAC_OUT		=> mc_src_mac,
	TC_SRC_IP_OUT		=> mc_src_ip,
	TC_SRC_UDP_OUT		=> mc_src_udp,
	
	TC_IP_SIZE_OUT		=> mc_ip_size,
	TC_UDP_SIZE_OUT		=> mc_udp_size,
	TC_FLAGS_OFFSET_OUT	=> mc_flags,
	
	TC_FC_H_READY_IN => mc_fc_h_ready,
	TC_FC_READY_IN => mc_fc_ready,
	TC_FC_WR_EN_OUT => mc_fc_wr_en,

	TC_BUSY_IN		=> MC_BUSY_IN,
	TC_TRANSMIT_DONE_IN	=> MC_TRANSMIT_DONE_IN,

-- signals to/from sgmii/gbe pcs_an_complete
	PCS_AN_COMPLETE_IN	=> '1',

-- signals to/from hub
	MC_UNIQUE_ID_IN		=> (others => '0'),
	
	GSC_CLK_IN               => CLK,
	GSC_INIT_DATAREADY_OUT   => gsc_init_dataready,
	GSC_INIT_DATA_OUT        => gsc_init_data,
	GSC_INIT_PACKET_NUM_OUT  => gsc_init_packet_num,
	GSC_INIT_READ_IN         => gsc_init_read,
	GSC_REPLY_DATAREADY_IN   => gsc_reply_dataready,
	GSC_REPLY_DATA_IN        => gsc_reply_data,
	GSC_REPLY_PACKET_NUM_IN  => gsc_reply_packet_num,
	GSC_REPLY_READ_OUT       => gsc_reply_read,
	GSC_BUSY_IN              => gsc_busy,
	
	-- signal for data readout
	-- CTS interface
	CTS_NUMBER_IN				=> (others => '0'),
	CTS_CODE_IN					=> (others => '0'),
	CTS_INFORMATION_IN			=> (others => '0'),
	CTS_READOUT_TYPE_IN			=> (others => '0'),
	CTS_START_READOUT_IN		=> '0',
	CTS_DATA_OUT				=> open,
	CTS_DATAREADY_OUT			=> open,
	CTS_READOUT_FINISHED_OUT	=> open,
	CTS_READ_IN					=> '0',
	CTS_LENGTH_OUT				=> open,
	CTS_ERROR_PATTERN_OUT		=> open,
	-- Data payload interface
	FEE_DATA_IN				    => (others => '0'),
	FEE_DATAREADY_IN			=> '0',
	FEE_READ_OUT				=> open,
	FEE_STATUS_BITS_IN			=> (others => '0'),
	FEE_BUSY_IN					=> '0',
	-- ip configurator
	SLV_ADDR_IN                  => (others => '0'),
	SLV_READ_IN                  => '0',
	SLV_WRITE_IN                 => '0',
	SLV_BUSY_OUT                 => open,
	SLV_ACK_OUT                  => open,
	SLV_DATA_IN                  => (others => '0'),
	SLV_DATA_OUT                 => open,
	
	CFG_GBE_ENABLE_IN            => '1',
	CFG_IPU_ENABLE_IN            => '0',
	CFG_MULT_ENABLE_IN           => '0',
	
	MAKE_RESET_OUT           => open,
	
-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		=> open,
	TSM_HDATA_OUT		=> open,
	TSM_HCS_N_OUT		=> open,
	TSM_HWRITE_N_OUT	=> open,
	TSM_HREAD_N_OUT		=> open,
	TSM_HREADY_N_IN		=> '0',
	TSM_HDATA_EN_N_IN	=> '1',
	TSM_RX_STAT_VEC_IN  => (others => '0'),
	TSM_RX_STAT_EN_IN   => '0',

	SELECT_REC_FRAMES_OUT	=> open,
	SELECT_SENT_FRAMES_OUT	=> open,
	SELECT_PROTOS_DEBUG_OUT	=> open,
	
	DEBUG_OUT		=> open
);

transmit_controller : trb_net16_gbe_transmit_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	MC_TRANSMIT_CTRL_IN	=> MC_TRANSMIT_CTRL_OUT,
	MC_DATA_IN		=> MC_DATA_OUT,
	MC_DATA_NOT_VALID_IN => data_not_valid,
	MC_WR_EN_IN		=> MC_RD_EN_IN,
	MC_FRAME_SIZE_IN	=> MC_FRAME_SIZE_OUT,
	MC_FRAME_TYPE_IN	=> mc_type,
	MC_IP_PROTOCOL_IN	=> mc_ip_proto,
	
	MC_DEST_MAC_IN		=> mc_dest_mac,
	MC_DEST_IP_IN		=> mc_dest_ip,
	MC_DEST_UDP_IN		=> mc_dest_udp,
	MC_SRC_MAC_IN		=> mc_src_mac,
	MC_SRC_IP_IN		=> mc_src_ip,
	MC_SRC_UDP_IN		=> mc_src_udp,
	
	MC_IP_SIZE_IN		=> mc_ip_size,
	MC_UDP_SIZE_IN		=> mc_udp_size,
	MC_FLAGS_OFFSET_IN	=> mc_flags,
	
	MC_BUSY_OUT		=> MC_BUSY_IN,
	MC_TRANSMIT_DONE_OUT	=> MC_TRANSMIT_DONE_IN,
	
	MC_FC_H_READY_OUT => mc_fc_h_ready,
	MC_FC_READY_OUT => mc_fc_ready,
	MC_FC_WR_EN_IN => mc_fc_wr_en,

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

frame_constructor : trb_net16_gbe_frame_constr
port map( 
	-- ports for user logic
	RESET                   => RESET,
	CLK                     => CLK,
	LINK_OK_IN              => '1',
	--
	WR_EN_IN                => fc_wr_en,
	DATA_IN                 => fc_data,
	START_OF_DATA_IN        => fc_sod,
	END_OF_DATA_IN          => fc_eod,
	IP_F_SIZE_IN            => fc_ip_size,
	UDP_P_SIZE_IN           => fc_udp_size,
	HEADERS_READY_OUT       => fc_h_ready,
	READY_OUT               => fc_ready,
	DEST_MAC_ADDRESS_IN     => fc_dest_mac,
	DEST_IP_ADDRESS_IN      => fc_dest_ip,
	DEST_UDP_PORT_IN        => fc_dest_udp,
	SRC_MAC_ADDRESS_IN      => fc_src_mac,
	SRC_IP_ADDRESS_IN       => fc_src_ip,
	SRC_UDP_PORT_IN         => fc_src_udp,
	FRAME_TYPE_IN           => fc_type,
	IHL_VERSION_IN          => fc_ihl,
	TOS_IN                  => fc_tos,
	IDENTIFICATION_IN       => fc_ident,
	FLAGS_OFFSET_IN         => fc_flags,
	TTL_IN                  => fc_ttl,
	PROTOCOL_IN             => fc_proto,
	FRAME_DELAY_IN          => x"0000_0000",
	-- ports for packetTransmitter
	RD_CLK                  => RX_MAC_CLK,
	FT_DATA_OUT             => open,
	FT_TX_EMPTY_OUT         => open,
	FT_TX_RD_EN_IN          => '1',
	FT_START_OF_PACKET_OUT  => open,
	FT_TX_DONE_IN           => '1',
	FT_TX_DISCFRM_IN	=> '0',
	-- debug ports
	BSM_CONSTR_OUT          => open,
	BSM_TRANS_OUT           => open,
	DEBUG_OUT               => open
);

-- 100 MHz system clock
CLOCK_GEN_PROC: process
begin
	CLK <= '1'; wait for 5.0 ns;
	CLK <= '0'; wait for 5.0 ns;
end process CLOCK_GEN_PROC;

-- 125 MHz MAC clock
CLOCK2_GEN_PROC: process
begin
	RX_MAC_CLK <= '1'; wait for 3.0 ns;
	RX_MAC_CLK <= '0'; wait for 4.0 ns;
end process CLOCK2_GEN_PROC;

TESTBENCH_PROC : process

variable seed1 : positive; -- seed for random generator
variable seed2 : positive; -- seed for random generator
variable rand : real; -- random value (0.0 ... 1.0)
variable int_rand : integer; -- random value, scaled to your needs

begin

	wait for 50 ns;
	RESET <= '1';
	
	LINK_OK_IN  <= '1';
	ALLOW_RX_IN <= '1';
	
	MAC_RX_EOF_IN		<= '0';
	MAC_RX_ER_IN		<= '0';
	MAC_RXD_IN		<= x"00";
	MAC_RX_EN_IN		<= '0';
	MAC_RX_FIFO_ERR_IN	<= '0';
	FR_ALLOWED_TYPES_IN     <= x"0000_000f";
	fr_allowed_ip           <= x"0000_000f";
	fr_allowed_udp          <= x"0000_000f";
	additional_rand_pause   <= '0';
	pc_sos                  <= '0';
--	gsc_init_read           <= '0';
--	gsc_busy                <= '0';
--	gsc_reply_data          <= (others => '0');
--	gsc_reply_dataready     <= '0';
--	
	wait for 10 ns;
	RESET <= '0';
	wait for 50 ns;
	
	--for i in 0 to 1000 loop
	
	wait for 400 ns;
	
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
	MAC_RXD_IN		<= x"de";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"ad";
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
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(RX_MAC_CLK);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(RX_MAC_CLK);
		MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(RX_MAC_CLK);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	wait for 1 us;
end process testbench_proc;

END;