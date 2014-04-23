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
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IDENT_OUT		: out	std_logic_vector(15 downto 0);
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	DEBUG_OUT		  : out std_logic_vector(63 downto 0);
-- END OF INTERFACE

	TRANSMITTER_BUSY_IN         : in    std_logic;

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

	MONITOR_SELECT_REC_OUT	      : out	std_logic_vector(31 downto 0);
	MONITOR_SELECT_REC_BYTES_OUT  : out	std_logic_vector(31 downto 0);
	MONITOR_SELECT_SENT_BYTES_OUT : out	std_logic_vector(31 downto 0);
	MONITOR_SELECT_SENT_OUT	      : out	std_logic_vector(31 downto 0);
	
	DATA_HIST_OUT : out hist_array
);
end trb_net16_gbe_response_constructor_TrbNetData;


architecture trb_net16_gbe_response_constructor_TrbNetData of trb_net16_gbe_response_constructor_TrbNetData is

attribute syn_encoding : string;

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
signal pc_event_id				: std_logic_vector(31 downto 0);
signal pc_sub_size				: std_logic_vector(31 downto 0);
signal pc_trig_nr				: std_logic_vector(31 downto 0);
signal pc_eos                   : std_logic;
signal pc_transmit_on           : std_logic;

signal tc_rd_en					: std_logic;
signal tc_data					: std_logic_vector(8 downto 0);
signal tc_size					: std_logic_vector(15 downto 0);
signal tc_sod					: std_logic;
signal pc_trig_type             : std_logic_vector(3 downto 0);

type dissect_states is (IDLE, WAIT_FOR_LOAD, LOAD, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state : signal is "onehot";
 
signal event_bytes : std_logic_vector(15 downto 0);
signal loaded_bytes : std_logic_vector(15 downto 0);
signal sent_packets : std_logic_vector(15 downto 0);

signal mon_sent_frames, mon_sent_bytes : std_logic_vector(31 downto 0);
signal ipu_dbg : std_logic_vector(383 downto 0);
signal constr_dbg : std_logic_vector(63 downto 0);

signal hist_inst : hist_array;
signal tc_sod_flag : std_logic;
signal reset_all_hist : std_logic_vector(31 downto 0);

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
	READOUT_CTR_IN			 => CFG_READOUT_CTR_IN, --x"00_0000",
	READOUT_CTR_VALID_IN	 => CFG_READOUT_CTR_VALID_IN, --'0',
	ALLOW_LARGE_IN			 => '0',
	-- PacketConstructor interface
	PC_WR_EN_OUT			 => pc_wr_en,
	PC_DATA_OUT				 => pc_data,
	PC_READY_IN				 => pc_ready,
	PC_SOS_OUT				 => pc_sos,
	PC_EOS_OUT				 => pc_eos,
	PC_EOD_OUT				 => pc_eod,
	PC_SUB_SIZE_OUT			 => pc_sub_size,
	PC_TRIG_NR_OUT			 => pc_trig_nr,
	PC_TRIGGER_TYPE_OUT      => pc_trig_type,
	PC_PADDING_OUT			 => pc_padding,
	MONITOR_OUT              => open,
	DEBUG_OUT                => ipu_dbg
);

--TODO: add missing values from setup
PACKET_CONSTRUCTOR : trb_net16_gbe_event_constr --trb_net16_gbe_packet_constr
port map(
	CLK						=> CLK,
	RESET					=> RESET,
	MULT_EVT_ENABLE_IN		=> '0', --CFG_MULT_ENABLE_IN
	PC_WR_EN_IN				=> pc_wr_en,
	PC_DATA_IN				=> pc_data,
	PC_READY_OUT			=> pc_ready,
	PC_START_OF_SUB_IN		=> pc_sos,
	PC_END_OF_SUB_IN		=> pc_eos,
	PC_END_OF_DATA_IN		=> pc_eod,
	PC_TRANSMIT_ON_OUT		=> pc_transmit_on,
	PC_SUB_SIZE_IN			=> pc_sub_size,
	PC_PADDING_IN			=> pc_padding,
	PC_DECODING_IN			=> CFG_SUBEVENT_DEC_IN, --x"0002_0001", --pc_decoding,
	PC_EVENT_ID_IN			=> CFG_SUBEVENT_ID_IN, --x"0000_8000", --pc_event_id,
	PC_TRIG_NR_IN			=> pc_trig_nr,
	PC_TRIGGER_TYPE_IN      => pc_trig_type,
	PC_QUEUE_DEC_IN			=> CFG_QUEUE_DEC_IN, --x"0003_0062", --pc_queue_dec,
	PC_MAX_FRAME_SIZE_IN    => g_MAX_FRAME_SIZE,
	PC_MAX_QUEUE_SIZE_IN    => x"0000_0fd0",  -- not used for the moment
	PC_DELAY_IN             => (others => '0'),
	PC_INSERT_TTYPE_IN      => CFG_INSERT_TTYPE_IN,
	TC_RD_EN_IN				=> tc_rd_en,
	TC_DATA_OUT				=> tc_data,
	TC_EVENT_SIZE_OUT		=> tc_size,
	TC_SOD_OUT				=> tc_sod,
	DEBUG_OUT				=> constr_dbg
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

DISSECT_MACHINE : process(dissect_current_state, tc_sod, event_bytes, loaded_bytes, PS_SELECTED_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			if (tc_sod = '1') then
				dissect_next_state <= WAIT_FOR_LOAD;
			else
				dissect_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD =>
			if (event_bytes = loaded_bytes) then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD;
			end if;
		
		when CLEANUP =>
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

PS_BUSY_OUT <= '0' when dissect_current_state = IDLE else '1';
PS_RESPONSE_READY_OUT <= '1' when (dissect_current_state = LOAD) or (dissect_current_state = WAIT_FOR_LOAD) else '0';

TC_DATA_OUT <= tc_data;
--TC_DATA_EOD_PROC : process (clk) is
--begin
--	if rising_edge(clk) then
--		if (dissect_current_state = LOAD and event_bytes = loaded_bytes - x"2") then
--			TC_DATA_OUT(8) <= '1';
--		else
--			TC_DATA_OUT(8) <= '0';
--		end if;
--	end if;
--end process TC_DATA_EOD_PROC;

EVENT_BYTES_PROC : process (clk) is
begin
	if rising_edge(clk) then
		if dissect_current_state = IDLE and tc_sod = '1' then
			event_bytes <= tc_size + x"20";  -- adding termination bytes
		else
			event_bytes <= event_bytes;
		end if;
	end if;
end process EVENT_BYTES_PROC;

LOADED_BYTES_PROC : process (clk) is
begin
	if rising_edge(clk) then
		if (dissect_current_state = IDLE) then
			loaded_bytes <= (others => '0');
		elsif (dissect_current_state = LOAD and TC_RD_EN_IN = '1') then
			loaded_bytes <= loaded_bytes + x"1";
		else
			loaded_bytes <= loaded_bytes;
		end if;
	end if;
end process LOADED_BYTES_PROC;

TC_FRAME_SIZE_OUT 	  <= event_bytes;
TC_FRAME_TYPE_OUT     <= x"0008";
TC_DEST_MAC_OUT       <= ic_dest_mac;
TC_DEST_IP_OUT        <= ic_dest_ip;
TC_DEST_UDP_OUT       <= ic_dest_udp;
TC_SRC_MAC_OUT        <= g_MY_MAC;
TC_SRC_IP_OUT         <= ic_src_ip; --g_MY_IP;
TC_SRC_UDP_OUT        <= ic_src_udp;
TC_IP_PROTOCOL_OUT    <= x"11";
TC_IDENT_OUT          <= x"4" & sent_packets(11 downto 0);

SENT_PACKETS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			sent_packets <= (others => '0');
		elsif (dissect_current_state = IDLE and tc_sod = '1') then
			sent_packets <= sent_packets + x"1";
		end if;
	end if;
end process SENT_PACKETS_PROC;

-- monitoring


process(CLK)
begin
	if rising_edge(CLK) then
		if (tc_sod = '1' and tc_sod_flag = '0') then
			tc_sod_flag <= '1';
		elsif (tc_sod = '0') then
			tc_sod_flag <= '0';
		else
			tc_sod_flag <= tc_sod_flag;
		end if;
	end if;	
end process;

hist_ctrs_gen : for i in 0 to 31 generate

	process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') then
				reset_all_hist(i) <= '1';
			elsif (hist_inst(i) = x"ffff_ffff") then
				reset_all_hist(i) <= '1';
			else
				reset_all_hist(i) <= '0';
			end if;				
		end if;
	end process;

	HIST_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') or (reset_all_hist /= x"0000_0000") then
				hist_inst(i) <= (others => '0');
			elsif (tc_sod = '1' and tc_sod_flag = '0' and i = to_integer(unsigned(event_bytes(15 downto 11)))) then
				hist_inst(i) <= hist_inst(i) + x"1"; 
			else
				hist_inst(i) <= hist_inst(i);
			end if;
		end if;
	end process;
end generate hist_ctrs_gen;

DATA_HIST_OUT <= hist_inst;

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_sent_frames <= (others => '0');
		elsif (dissect_current_state = LOAD and event_bytes = loaded_bytes) then
			mon_sent_frames <= mon_sent_frames + x"1";
		else
			mon_sent_frames <= mon_sent_frames;
		end if;
	end if;
end process;
MONITOR_SELECT_SENT_OUT      <= mon_sent_frames;

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_sent_bytes <= (others => '0');
		elsif (tc_rd_en = '1') then
			mon_sent_bytes <= mon_sent_bytes + x"1";
		else
			mon_sent_bytes <= mon_sent_bytes;
		end if;
	end if;
end process;

MONITOR_SELECT_SENT_BYTES_OUT <= mon_sent_bytes;


MONITOR_SELECT_REC_BYTES_OUT  <= (others => '0');
MONITOR_SELECT_REC_OUT        <= (others => '0');

DEBUG_OUT(31 downto 0) <= ipu_dbg(31 downto 0);
DEBUG_OUT(63 downto 32) <= constr_dbg(31 downto 0);

end trb_net16_gbe_response_constructor_TrbNetData;


