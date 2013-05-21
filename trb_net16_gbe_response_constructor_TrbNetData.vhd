LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity trb_net16_gbe_response_constructor_TrbNetData is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_DATA_NOT_VALID_OUT : out std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	: out	std_logic_vector(15 downto 0);
	
	TC_FC_H_READY_IN : in std_logic;
	TC_FC_READY_IN : in std_logic;
	TC_FC_WR_EN_OUT : out std_logic;
		
	TC_BUSY_IN		: in	std_logic;
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

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

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_TrbNetData;


architecture trb_net16_gbe_response_constructor_TrbNetData of trb_net16_gbe_response_constructor_TrbNetData is

attribute syn_encoding	: string;

signal ip_cfg_start				: std_logic;
signal ip_cfg_bank				: std_logic_vector(3 downto 0);
signal ip_cfg_done				: std_logic;
signal ip_cfg_mem_addr			: std_logic_vector(7 downto 0);
signal ip_cfg_mem_data			: std_logic_vector(31 downto 0);
signal ip_cfg_mem_clk			: std_logic;

signal ic_dest_mac				: std_logic_vector(47 downto 0);
signal ic_dest_ip				: std_logic_vector(31 downto 0);
signal ic_dest_udp				: std_logic_vector(15 downto 0);
signal ic_src_mac				: std_logic_vector(47 downto 0);
signal ic_src_ip				: std_logic_vector(31 downto 0);
signal ic_src_udp				: std_logic_vector(15 downto 0);

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
signal pc_sub_size				: std_logic_vector(31 downto 0);
signal pc_trig_nr				: std_logic_vector(31 downto 0);
signal pc_eos                   : std_logic;
signal pc_transmit_on           : std_logic;

signal tc_rd_en					: std_logic;
signal tc_data					: std_logic_vector(7 downto 0);
signal tc_ip_size				: std_logic_vector(15 downto 0);
signal tc_udp_size				: std_logic_vector(15 downto 0);
signal tc_ident					: std_logic_vector(15 downto 0);
signal tc_flags_offset			: std_logic_vector(15 downto 0);
signal tc_sod					: std_logic;
signal tc_eod					: std_logic;
signal tc_h_ready				: std_logic;
signal tc_ready					: std_logic;
signal tc_not_valid             : std_logic;

type dissect_states is (IDLE, WAIT_FOR_LOAD, LOAD, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;

signal frame_size              : std_logic_vector(15 downto 0) := x"0000";

begin


THE_IP_CONFIGURATOR: ip_configurator
port map( 
	CLK					=> CLK,
	RESET				=> RESET,
	-- configuration interface
	START_CONFIG_IN		=> ip_cfg_start,
	BANK_SELECT_IN		=> ip_cfg_bank,
	CONFIG_DONE_OUT		=> ip_cfg_done,
	MEM_ADDR_OUT		=> ip_cfg_mem_addr,
	MEM_DATA_IN			=> ip_cfg_mem_data,
	MEM_CLK_OUT			=> ip_cfg_mem_clk,
	-- information for IP cores
	DEST_MAC_OUT		=> ic_dest_mac,
	DEST_IP_OUT			=> ic_dest_ip,
	DEST_UDP_OUT		=> ic_dest_udp,
	SRC_MAC_OUT			=> ic_src_mac,
	SRC_IP_OUT			=> ic_src_ip,
	SRC_UDP_OUT			=> ic_src_udp,
	MTU_OUT				=> open,
	-- Debug
	DEBUG_OUT			=> open
);

MB_IP_CONFIG: slv_mac_memory
port map( 
	CLK				=> CLK,
	RESET           => RESET,
	BUSY_IN         => '0',
	-- Slave bus
	SLV_ADDR_IN     => SLV_ADDR_IN,
	SLV_READ_IN     => SLV_READ_IN,
	SLV_WRITE_IN    => SLV_WRITE_IN,
	SLV_BUSY_OUT    => SLV_BUSY_OUT,
	SLV_ACK_OUT     => SLV_ACK_OUT,
	SLV_DATA_IN     => SLV_DATA_IN,
	SLV_DATA_OUT    => SLV_DATA_OUT,
	-- I/O to the backend
	MEM_CLK_IN      => ip_cfg_mem_clk,
	MEM_ADDR_IN     => ip_cfg_mem_addr,
	MEM_DATA_OUT    => ip_cfg_mem_data,
	-- Status lines
	STAT            => open
);

THE_IPU_INTERFACE: trb_net16_gbe_ipu_interface --ipu2gbe
port map( 
	CLK_IPU 			     => CLK,
	CLK_GBE					 => CLK,
	RESET					 => RESET,
	--Event information coming from CTS
	CTS_NUMBER_IN			 => CTS_NUMBER_IN,
	CTS_CODE_IN				 => CTS_CODE_IN,
	CTS_INFORMATION_IN		 => CTS_INFORMATION_IN,
	CTS_READOUT_TYPE_IN		 => CTS_READOUT_TYPE_IN,
	CTS_START_READOUT_IN	 => CTS_START_READOUT_IN,
	--Information sent to CTS
	--status data, equipped with DHDR
	CTS_DATA_OUT			 => CTS_DATA_OUT,
	CTS_DATAREADY_OUT		 => CTS_DATAREADY_OUT,
	CTS_READOUT_FINISHED_OUT => CTS_READOUT_FINISHED_OUT,
	CTS_READ_IN				 => CTS_READ_IN,
	CTS_LENGTH_OUT			 => CTS_LENGTH_OUT,
	CTS_ERROR_PATTERN_OUT	 => CTS_ERROR_PATTERN_OUT,
	-- Data from Frontends
	FEE_DATA_IN				 => FEE_DATA_IN,
	FEE_DATAREADY_IN		 => FEE_DATAREADY_IN,
	FEE_READ_OUT			 => FEE_READ_OUT,
	FEE_STATUS_BITS_IN		 => FEE_STATUS_BITS_IN,
	FEE_BUSY_IN				 => FEE_BUSY_IN,
	-- slow control interface
	START_CONFIG_OUT		 => ip_cfg_start,
	BANK_SELECT_OUT			 => ip_cfg_bank,
	CONFIG_DONE_IN			 => ip_cfg_done,
	DATA_GBE_ENABLE_IN		 => CFG_GBE_ENABLE_IN,
	DATA_IPU_ENABLE_IN		 => CFG_IPU_ENABLE_IN,
	MULT_EVT_ENABLE_IN		 => '0', --CFG_MULT_ENABLE_IN,
	MAX_MESSAGE_SIZE_IN		 => x"0000_0fd0",
	MIN_MESSAGE_SIZE_IN		 => x"0000_0007",
	READOUT_CTR_IN			 => x"00_0000",
	READOUT_CTR_VALID_IN	 => '0',
	ALLOW_LARGE_IN			 => '0',
	-- only for simple sender
--	SCTRL_DUMMY_SIZE_IN      => x"0100",
--	SCTRL_DUMMY_PAUSE_IN     => x"0040_0000",
	-- PacketConstructor interface
	PC_WR_EN_OUT			 => pc_wr_en,
	PC_DATA_OUT				 => pc_data,
	PC_READY_IN				 => pc_ready,
	PC_SOS_OUT				 => pc_sos,
	PC_EOS_OUT				 => pc_eos,
	PC_EOD_OUT				 => pc_eod,
	PC_SUB_SIZE_OUT			 => pc_sub_size,
	PC_TRIG_NR_OUT			 => pc_trig_nr,
	PC_PADDING_OUT			 => pc_padding,
	MONITOR_OUT              => open,
	DEBUG_OUT                => open
);

--TODO: add missing values from setup
PACKET_CONSTRUCTOR : trb_net16_gbe_event_constr --trb_net16_gbe_packet_constr
port map(
	CLK						=> CLK,
	RESET					=> RESET,
	MULT_EVT_ENABLE_IN		=> '0',
	PC_WR_EN_IN				=> pc_wr_en,
	PC_DATA_IN				=> pc_data,
	PC_READY_OUT			=> pc_ready,
	PC_START_OF_SUB_IN		=> pc_sos,
	PC_END_OF_SUB_IN		=> pc_eos,
	PC_END_OF_DATA_IN		=> pc_eod,
	PC_TRANSMIT_ON_OUT		=> pc_transmit_on,
	PC_SUB_SIZE_IN			=> pc_sub_size,
	PC_PADDING_IN			=> pc_padding,
	PC_DECODING_IN			=> x"0002_0001", --pc_decoding,
	PC_EVENT_ID_IN			=> pc_event_id,
	PC_TRIG_NR_IN			=> pc_trig_nr,
	PC_QUEUE_DEC_IN			=> x"0003_0062", --pc_queue_dec,
	PC_MAX_FRAME_SIZE_IN    => x"0050", --x"0578",
	PC_MAX_QUEUE_SIZE_IN    => x"0000_0fd0",
	PC_DELAY_IN             => (others => '0'),
	TC_RD_EN_IN				=> tc_rd_en,
	TC_DATA_OUT				=> tc_data,
	TC_H_READY_IN			=> tc_h_ready,
	TC_READY_IN				=> tc_ready,
	TC_IP_SIZE_OUT			=> tc_ip_size,
	TC_UDP_SIZE_OUT			=> tc_udp_size,
	TC_FLAGS_OFFSET_OUT		=> tc_flags_offset,
	TC_SOD_OUT				=> tc_sod,
	TC_EOD_OUT				=> tc_eod,
	TC_DATA_NOT_VALID_OUT   => tc_not_valid,
	DEBUG_OUT				=> open
);

tc_rd_en <= '1' when PS_SELECTED_IN = '1' and TC_RD_EN_IN = '1' else '0'; 

DISSECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			dissect_current_state <= IDLE;
		else
			dissect_current_state <= dissect_next_state;
		end if;
	end if;
end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, tc_sod, TC_BUSY_IN, tc_eod)
begin
	case dissect_current_state is
	
		when IDLE =>
			if (tc_sod = '1') then
				dissect_next_state <= WAIT_FOR_LOAD;
			else
				dissect_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD =>
			if (tc_eod = '1') then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD;
			end if;
		
		when CLEANUP =>
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

--TODO: change this to real "ready" signals 
tc_ready <= '1' when TC_BUSY_IN = '0' else '0'; --not TC_BUSY_IN);
tc_h_ready <= '1' when dissect_current_state = WAIT_FOR_LOAD and TC_BUSY_IN = '0' else '0';

PS_BUSY_OUT <= '0' when dissect_current_state = IDLE else '1';
PS_RESPONSE_READY_OUT <= '1' when (dissect_current_state = LOAD) or (dissect_current_state = WAIT_FOR_LOAD) else '0';

TC_DATA_OUT           <= "0" & tc_data;
TC_DATA_NOT_VALID_OUT <= tc_not_valid;

FRAME_SIZE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if tc_flags_offset'event then
			if (tc_flags_offset(12 downto 0) = "0000000000000") then
				frame_size <= tc_ip_size + x"4";
			else
				frame_size <= tc_ip_size;
			end if;
		else
			frame_size <= frame_size;
		end if; 	
	end if;
end process;
TC_FRAME_SIZE_OUT 	  <= frame_size; --tc_ip_size + x"4" when tc_flags_offset(12 downto 0) = "0000000000000" else tc_ip_size;
TC_IP_SIZE_OUT		  <= tc_ip_size;
TC_UDP_SIZE_OUT		  <= tc_udp_size;

TC_FRAME_TYPE_OUT     <= x"0008";
TC_DEST_MAC_OUT       <= ic_dest_mac;
TC_DEST_IP_OUT        <= ic_dest_ip;
TC_DEST_UDP_OUT       <= x"cb20";
TC_SRC_MAC_OUT        <= g_MY_MAC;
TC_SRC_IP_OUT         <= g_MY_IP;
TC_SRC_UDP_OUT        <= x"cb20";
TC_IP_PROTOCOL_OUT    <= x"11";
TC_FLAGS_OFFSET_OUT   <= tc_flags_offset;


end trb_net16_gbe_response_constructor_TrbNetData;


