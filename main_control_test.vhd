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

--********
-- controls the work of the whole gbe in both directions
-- multiplexes the output between data stream and output slow control packets based on priority
-- reacts to incoming gbe slow control commands
-- 




entity main_crap is
port (
	CLK			: in	std_logic;  -- system clock
	CLK_125			: in	std_logic;
	RESET			: in	std_logic;

	MC_LINK_OK_OUT		: out	std_logic;
	MC_RESET_LINK_IN	: in	std_logic;
	MC_IDLE_TOO_LONG_OUT : out std_logic;

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
	TC_WR_EN_OUT		: out	std_logic;
	TC_DATA_NOT_VALID_OUT : out std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	TC_IP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_IDENT_OUT        : out   std_logic_vector(15 downto 0);
	
	TC_FC_H_READY_IN : in std_logic;
	TC_FC_READY_IN : in std_logic;
	TC_FC_WR_EN_OUT : out std_logic;
	
	TC_BUSY_IN		: in	std_logic;
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
	
	MAKE_RESET_OUT           : out std_logic;

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

	SELECT_REC_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SELECT_SENT_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SELECT_PROTOS_DEBUG_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end main_crap;


architecture main_crap of main_crap is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_main_control : architecture is "GBE_MAIN_group";

signal tsm_ready                            : std_logic;
signal tsm_reconf                           : std_logic;
signal tsm_haddr                            : std_logic_vector(7 downto 0);
signal tsm_hdata                            : std_logic_vector(7 downto 0);
signal tsm_hcs_n                            : std_logic;
signal tsm_hwrite_n                         : std_logic;
signal tsm_hread_n                          : std_logic;

type link_states is (ACTIVE, INACTIVE, ENABLE_MAC, TIMEOUT, FINALIZE);
signal link_current_state, link_next_state : link_states;

signal link_down_ctr                 : std_logic_vector(15 downto 0);
signal link_down_ctr_lock            : std_logic;
signal link_ok                       : std_logic;
signal link_ok_timeout_ctr           : std_logic_vector(15 downto 0);

signal mac_control_debug             : std_logic_vector(63 downto 0);

type flow_states is (IDLE, WAIT_FOR_H, TRANSMIT_CTRL, WAIT_FOR_FC, CLEANUP);
signal flow_current_state, flow_next_state : flow_states;

signal state                        : std_logic_vector(3 downto 0);
signal link_state                   : std_logic_vector(3 downto 0);
signal redirect_state               : std_logic_vector(3 downto 0);

signal ps_wr_en                     : std_logic;
signal ps_response_ready            : std_logic;
signal ps_busy                      : std_logic_vector(c_MAX_PROTOCOLS -1 downto 0);
signal rc_rd_en                     : std_logic;
signal first_byte                   : std_logic;
signal first_byte_q                 : std_logic;
signal first_byte_qq                : std_logic;
signal proto_select                 : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal loaded_bytes_ctr             : std_Logic_vector(15 downto 0);

signal dhcp_start                   : std_logic;
signal dhcp_done                    : std_logic;
signal wait_ctr                     : std_logic_vector(31 downto 0);

signal rc_data_local                : std_logic_vector(8 downto 0);

-- debug
signal frame_waiting_ctr            : std_logic_vector(15 downto 0);
signal ps_busy_q                    : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal rc_frame_proto_q             : std_Logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

type redirect_states is (IDLE, CHECK_TYPE, DROP, CHECK_BUSY, LOAD, BUSY, FINISH, CLEANUP);
signal redirect_current_state, redirect_next_state : redirect_states;

signal disable_redirect, ps_wr_en_q : std_logic;

type stats_states is (IDLE, LOAD_VECTOR, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;

signal stat_rdy, stat_ack           : std_logic;
signal rx_stat_en_q                 : std_logic;
signal rx_stat_vec_q                : std_logic_vector(31 downto 0);

type array_of_ctrs is array(15 downto 0) of std_logic_vector(31 downto 0);
signal arr : array_of_ctrs;
signal stats_ctr                    : integer range 0 to 15;
signal stat_data                    : std_logic_vector(31 downto 0);
signal stat_addr                    : std_logic_vector(7 downto 0);

signal unique_id                    : std_logic_vector(63 downto 0);


signal nothing_sent                 : std_logic;
signal nothing_sent_ctr             : std_logic_vector(31 downto 0);

signal dbg_ps                       : std_Logic_vector(63 downto 0);

signal tc_data                      : std_logic_vector(8 downto 0);

attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of unique_id, nothing_sent, link_state, state, redirect_state : signal is true;
attribute syn_preserve of unique_id, nothing_sent, link_state, state, redirect_state : signal is true;

signal mc_busy                      : std_logic;

begin

unique_id <= MC_UNIQUE_ID_IN;


--***********************
--	LINK STATE CONTROL

LINK_STATE_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			if (g_SIMULATE = 0) then
				link_current_state <= INACTIVE;
			else
				link_current_state <= ACTIVE;
			end if;
		else
			link_current_state <= link_next_state;
		end if;
	end if;
end process;

LINK_STATE_MACHINE : process(link_current_state, dhcp_done, wait_ctr, PCS_AN_COMPLETE_IN, tsm_ready, link_ok_timeout_ctr)
begin
	case link_current_state is

		when ACTIVE =>
			link_state <= x"1";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				link_next_state <= ACTIVE;
			end if;

		when INACTIVE =>
			link_state <= x"2";
			if (PCS_AN_COMPLETE_IN = '1') then
				link_next_state <= TIMEOUT;
			else
				link_next_state <= INACTIVE;
			end if;

		when TIMEOUT =>
			link_state <= x"3";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (link_ok_timeout_ctr = x"ffff") then
					link_next_state <= ENABLE_MAC; --FINALIZE;
				else
					link_next_state <= TIMEOUT;
				end if;
			end if;

		when ENABLE_MAC =>
			link_state <= x"4";
			if (PCS_AN_COMPLETE_IN = '0') then
			  link_next_state <= INACTIVE;
			elsif (tsm_ready = '1') then
			  link_next_state <= FINALIZE; --INACTIVE;
			else
			  link_next_state <= ENABLE_MAC;
			end if;

		when FINALIZE =>
			link_state <= x"5";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				link_next_state <= ACTIVE; --ACTIVE;
			end if;
			

	end case;
end process LINK_STATE_MACHINE;

LINK_OK_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (link_current_state /= TIMEOUT) then
			link_ok_timeout_ctr <= (others => '0');
		elsif (link_current_state = TIMEOUT) then
			link_ok_timeout_ctr <= link_ok_timeout_ctr + x"1";
		end if;
	end if;
end process LINK_OK_CTR_PROC;

link_ok <= '1' when (link_current_state = ACTIVE)  else '0';



LINK_DOWN_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			link_down_ctr      <= (others => '0');
			link_down_ctr_lock <= '0';
		elsif (PCS_AN_COMPLETE_IN = '1') then
			link_down_ctr_lock <= '0';
		elsif ((PCS_AN_COMPLETE_IN = '0') and (link_down_ctr_lock = '0')) then
			link_down_ctr      <= link_down_ctr + x"1";
			link_down_ctr_lock <= '1';
		end if;
	end if;
end process LINK_DOWN_CTR_PROC;

MC_LINK_OK_OUT <= link_ok; -- or nothing_sent;

-- END OF LINK STATE CONTROL
--*************

--*************
-- GENERATE MAC_ADDRESS
g_MY_MAC <= unique_id(31 downto 8) & x"be0002";

--g_MAX_FRAME_SIZE <= x"0578";

--g_MAX_PACKET_SIZE <= x"fa00" when g_SIMULATE = 0 else x"0600";
--
--*************

--****************
-- TRI SPEED MAC CONTROLLER

TSMAC_CONTROLLER : trb_net16_gbe_mac_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signals to/from main controller
	MC_TSMAC_READY_OUT	=> tsm_ready,
	MC_RECONF_IN		=> tsm_reconf,
	MC_GBE_EN_IN		=> '1',
	MC_RX_DISCARD_FCS	=> '0',
	MC_PROMISC_IN		=> '1',
	MC_MAC_ADDR_IN		=> x"001122334455",

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		=> tsm_haddr,
	TSM_HDATA_OUT		=> tsm_hdata,
	TSM_HCS_N_OUT		=> tsm_hcs_n,
	TSM_HWRITE_N_OUT	=> tsm_hwrite_n,
	TSM_HREAD_N_OUT		=> tsm_hread_n,
	TSM_HREADY_N_IN		=> TSM_HREADY_N_IN,
	TSM_HDATA_EN_N_IN	=> TSM_HDATA_EN_N_IN,

	DEBUG_OUT		=> mac_control_debug
);

--DEBUG_OUT <= mac_control_debug;

tsm_reconf <= '1' when (link_current_state = INACTIVE) and (PCS_AN_COMPLETE_IN = '1') else '0';

TSM_HADDR_OUT     <= tsm_haddr;
TSM_HCS_N_OUT     <= tsm_hcs_n;
TSM_HDATA_OUT     <= tsm_hdata;
TSM_HREAD_N_OUT   <= tsm_hread_n;
TSM_HWRITE_N_OUT  <= tsm_hwrite_n;

end main_crap;


