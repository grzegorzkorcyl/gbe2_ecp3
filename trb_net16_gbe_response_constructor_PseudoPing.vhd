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
-- Response Constructor which responds to Ping messages
--

entity trb_net16_gbe_response_constructor_PseudoPing is
generic ( STAT_ADDRESS_BASE : integer := 0
);
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
	TC_IDENT_OUT        : out	std_logic_vector(15 downto 0);	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
		
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_PseudoPing;


architecture trb_net16_gbe_response_constructor_PseudoPing of trb_net16_gbe_response_constructor_PseudoPing is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_response_constructor_Ping : architecture is "GBE_MAIN_group";

attribute syn_encoding	: string;

type dissect_states is (IDLE, READ_FRAME, GENERATE_DATA, WAIT_FOR_LOAD, LOAD_FRAME, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

type stats_states is (IDLE, LOAD_SENT, LOAD_RECEIVED, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;
attribute syn_encoding of stats_current_state : signal is "safe,gray";

signal rec_frames               : std_logic_vector(15 downto 0);
signal sent_frames              : std_logic_vector(15 downto 0);

signal saved_data               : std_logic_vector(447 downto 0);
signal saved_headers            : std_logic_vector(63 downto 0);

signal data_ctr                 : integer range 1 to 1500;
signal data_length              : integer range 1 to 1500;
signal tc_data                  : std_logic_vector(8 downto 0);

signal checksum                 : std_logic_vector(15 downto 0);

signal checksum_l, checksum_r   : std_logic_vector(19 downto 0);
signal checksum_ll, checksum_rr : std_logic_vector(15 downto 0);
signal checksum_lll, checksum_rrr : std_logic_vector(15 downto 0);

signal fifo_wr_en, fifo_rd_en   : std_logic;
signal fifo_q                   : std_logic_vector(7 downto 0);


signal stat_data_temp           : std_logic_vector(31 downto 0);

signal tc_wr                    : std_logic;

signal data_reg                 : std_logic_vector(511 downto 0);
signal fifo_data : std_logic_vector(7 downto 0);
signal gen_ctr : std_logic_vector(15 downto 0);
signal size_left : std_logic_vector(15 downto 0);

begin

--DISSECT_MACHINE_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			dissect_current_state <= IDLE;
--		else
--			dissect_current_state <= dissect_next_state;
--		end if;
--	end if;
--end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN, data_ctr, data_length, gen_ctr, size_left, PS_SELECTED_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			if (PS_DATA_IN(8) = '1') then
				dissect_next_state <= GENERATE_DATA;
			else
				dissect_next_state <= READ_FRAME;
			end if;
			
		when GENERATE_DATA =>
			if (gen_ctr = x"07ff") then
				dissect_next_state <= WAIT_FOR_LOAD;
			else
				dissect_next_state <= GENERATE_DATA;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD_FRAME =>
			if (size_left = x"0000") then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD_FRAME;
			end if;
		
		when CLEANUP =>
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

fifo : fifo_2048x8
  PORT map(
    Reset   => RESET,
	RPReset => RESET,
    WrClock => CLK,
	RdClock => CLK,
    Data    => fifo_data,
    WrEn    => fifo_wr_en,
    RdEn    => fifo_rd_en, --TC_RD_EN_IN,
    Q       => fifo_q,
    Full    => open,
    Empty   => open
  );
  
fifo_rd_en <= '1' when TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1' else '0';
fifo_wr_en <= '1' when dissect_current_state = GENERATE_DATA else '0';
fifo_data  <= gen_ctr(7 downto 0);

process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE or dissect_current_state = CLEANUP) then
			gen_ctr <= (others => '0');
		elsif (dissect_current_state = GENERATE_DATA) then
			gen_ctr <= gen_ctr + x"1";
		else
			gen_ctr <= gen_ctr;
		end if;
	end if;
end process;


TC_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = LOAD_FRAME and size_left = x"0000") then 
			tc_data(8) <= '1';
		else
			tc_data(8) <= '0';
		end if;
		
		tc_data(7 downto 0) <= fifo_q;
	end if;
end process TC_DATA_PROC;

TC_DATA_OUT <= tc_data;

PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or dissect_current_state = CLEANUP) then
			PS_RESPONSE_READY_OUT <= '1';
		else
			PS_RESPONSE_READY_OUT <= '0';
		end if;
		
		if (dissect_current_state = IDLE) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
	end if;	
end process PS_RESPONSE_SYNC;

process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = GENERATE_DATA) then
			size_left <= x"0500";
		elsif (dissect_current_state = LOAD_FRAME) then
			size_left <= size_left - x"1";
		else
			size_left <= size_left;
		end if;
	end if;	
end process;

TC_FRAME_SIZE_OUT   <= x"0500";

TC_FRAME_TYPE_OUT   <= x"0008";
TC_DEST_UDP_OUT     <= x"c350";  -- not used
TC_SRC_MAC_OUT      <= g_MY_MAC;
TC_SRC_IP_OUT       <= g_MY_IP;
TC_SRC_UDP_OUT      <= x"c350";  -- not used
TC_IP_PROTOCOL_OUT  <= X"11"; -- ICMP
TC_IDENT_OUT        <= x"2" & sent_frames(11 downto 0);

ADDR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = READ_FRAME) then
			TC_DEST_MAC_OUT <= PS_SRC_MAC_ADDRESS_IN;
			TC_DEST_IP_OUT  <= PS_SRC_IP_ADDRESS_IN;
		end if;
	end if;
end process ADDR_PROC;

-- statistics
--
--REC_FRAMES_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			rec_frames <= (others => '0');
--		elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
--			rec_frames <= rec_frames + x"1";
--		end if;
--	end if;
--end process REC_FRAMES_PROC;
--
-- needed for identification
SENT_FRAMES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			sent_frames <= (others => '0');
		elsif (dissect_current_state = WAIT_FOR_LOAD and PS_SELECTED_IN = '1') then
			sent_frames <= sent_frames + x"1";
		end if;
	end if;
end process SENT_FRAMES_PROC;
--
--RECEIVED_FRAMES_OUT <= rec_frames;
--SENT_FRAMES_OUT     <= sent_frames;
--RECEIVED_FRAMES_OUT <= rec_frames;
--SENT_FRAMES_OUT     <= sent_frames;
--	
--STATS_MACHINE_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			stats_current_state <= IDLE;
--		else
--			stats_current_state <= stats_next_state;
--		end if;
--	end if;
--end process STATS_MACHINE_PROC;
--
--STATS_MACHINE : process(stats_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, STAT_DATA_ACK_IN, PS_DATA_IN, dissect_current_state)
--begin
--
--	case (stats_current_state) is
--	
--		when IDLE =>
--			if (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') or (dissect_current_state = CLEANUP) then
--				stats_next_state <= LOAD_SENT;
--			else
--				stats_next_state <= IDLE;
--			end if;
--		
--		when LOAD_SENT =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= LOAD_RECEIVED;
--			else
--				stats_next_state <= LOAD_SENT;
--			end if;
--		
--		when LOAD_RECEIVED =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= CLEANUP;
--			else
--				stats_next_state <= LOAD_RECEIVED;
--			end if;
--			
--		when CLEANUP =>
--			stats_next_state <= IDLE;
--	
--	end case;
--
--end process STATS_MACHINE;
--
--SELECTOR : process(CLK)
--begin
--	if rising_edge(CLK) then
--		case(stats_current_state) is
--		
--			when LOAD_SENT =>
--				stat_data_temp <= x"0401" & sent_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE, 8));
--			
--			when LOAD_RECEIVED =>
--				stat_data_temp <= x"0402" & rec_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 1, 8));
--			
--			when others =>
--				stat_data_temp <= (others => '0');
--				STAT_ADDR_OUT  <= (others => '0');
--		
--		end case;
--	end if;	
--end process SELECTOR;
--
--STAT_DATA_OUT(7 downto 0)   <= stat_data_temp(31 downto 24);
--STAT_DATA_OUT(15 downto 8)  <= stat_data_temp(23 downto 16);
--STAT_DATA_OUT(23 downto 16) <= stat_data_temp(15 downto 8);
--STAT_DATA_OUT(31 downto 24) <= stat_data_temp(7 downto 0);
--
--STAT_SYNC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (stats_current_state /= IDLE and stats_current_state /= CLEANUP) then
--			STAT_DATA_RDY_OUT <= '1';
--		else
--			STAT_DATA_RDY_OUT <= '0';
--		end if;
--	end if;
--end process STAT_SYNC;
--STAT_DATA_RDY_OUT <= '1' when stats_current_state /= IDLE and stats_current_state /= CLEANUP else '0';

-- **** debug
--DEBUG_OUT(3 downto 0)   <= state;
--DEBUG_OUT(4)            <= '0';
--DEBUG_OUT(7 downto 5)   <= "000";
--DEBUG_OUT(8)            <= '0';
--DEBUG_OUT(11 downto 9)  <= "000";
--DEBUG_OUT(31 downto 12) <= (others => '0');
-- ****

end trb_net16_gbe_response_constructor_PseudoPing;


