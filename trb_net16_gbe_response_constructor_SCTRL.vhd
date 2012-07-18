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


entity trb_net16_gbe_response_constructor_SCTRL is
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
		TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
		TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
		TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
		TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
		TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
		TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
		TC_IP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
		TC_UDP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
		TC_FLAGS_OFFSET_OUT	: out	std_logic_vector(15 downto 0);
		
		TC_BUSY_IN		: in	std_logic;

		STAT_DATA_OUT : out std_logic_vector(31 downto 0);
		STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
		STAT_DATA_RDY_OUT : out std_logic;
		STAT_DATA_ACK_IN  : in std_logic;
		
		RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
		SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
	-- END OF INTERFACE
	
	-- protocol specific ports
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
	-- end of protocol specific ports
	
	-- debug
		DEBUG_OUT		: out	std_logic_vector(31 downto 0)
	);
end entity trb_net16_gbe_response_constructor_SCTRL;

architecture RTL of trb_net16_gbe_response_constructor_SCTRL is

attribute syn_encoding	: string;

type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_TO_HUB, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_TC, DIVIDE, WAIT_FOR_LOAD, CLEANUP, WAIT_FOR_LOAD_ACK, LOAD_ACK);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

type stats_states is (IDLE, LOAD_RECEIVED, LOAD_REPLY, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;
attribute syn_encoding of stats_current_state : signal is "safe,gray";

signal saved_target_ip          : std_logic_vector(31 downto 0);
signal data_ctr                 : integer range 0 to 30;
signal state                    : std_logic_vector(3 downto 0);


signal stat_data_temp           : std_logic_vector(31 downto 0);
signal rec_frames               : std_logic_vector(15 downto 0);

signal rx_fifo_q                : std_logic_vector(17 downto 0);
signal rx_fifo_wr, rx_fifo_rd   : std_logic;
signal tx_eod, rx_eod           : std_logic;

signal tx_fifo_q                : std_logic_vector(8 downto 0);
signal tx_fifo_wr, tx_fifo_rd   : std_logic;
signal tx_fifo_reset            : std_logic;
signal gsc_reply_read           : std_logic;
signal gsc_init_dataready       : std_logic;

signal tx_data_ctr              : std_logic_vector(15 downto 0);
signal tx_loaded_ctr            : std_logic_vector(15 downto 0);
signal tx_frame_loaded          : std_logic_vector(15 downto 0);

signal packet_num               : std_logic_vector(2 downto 0);
	
signal init_ctr, reply_ctr      : std_logic_vector(15 downto 0);
signal rx_empty, tx_empty       : std_logic;

signal rx_full, tx_full         : std_logic;

signal size_left                : std_logic_vector(15 downto 0);

signal reset_detected           : std_logic := '0';
signal make_reset               : std_logic := '0';


attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of tx_data_ctr, tx_loaded_ctr, state : signal is true;
attribute syn_preserve of tx_data_ctr, tx_loaded_ctr, state : signal is true;

signal temp_ctr                : std_logic_vector(7 downto 0);

signal gsc_init_read_q         : std_logic;
signal fifo_rd_q               : std_logic;

signal too_much_data           : std_logic;

signal divide_ctr              : std_logic_vector(7 downto 0);


begin

MAKE_RESET_OUT <= make_reset;

receive_fifo : fifo_2048x8x16
  PORT map(
    Reset            => RESET,
	RPReset          => RESET,
    WrClock          => CLK,
	RdClock          => CLK,
    Data             => PS_DATA_IN,
    WrEn             => rx_fifo_wr,
    RdEn             => rx_fifo_rd,
    Q                => rx_fifo_q,
    Full             => rx_full,
    Empty            => rx_empty
  );

rx_fifo_wr              <= '1' when PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1' else '0';

rx_fifo_rd              <= '1' when (gsc_init_dataready = '1' and dissect_current_state = LOAD_TO_HUB) or 
								(gsc_init_dataready = '1' and dissect_current_state = WAIT_FOR_HUB and GSC_INIT_READ_IN = '1') or
								(dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1')
								else '0';  -- preload first word

GSC_INIT_DATA_OUT(7 downto 0)  <= rx_fifo_q(16 downto 9);
GSC_INIT_DATA_OUT(15 downto 8) <= rx_fifo_q(7 downto 0);	

GSC_INIT_PACKET_NUM_OUT <= packet_num;
GSC_INIT_DATAREADY_OUT  <= gsc_init_dataready;
gsc_init_dataready <= '1' when (GSC_INIT_READ_IN = '1' and dissect_current_state = LOAD_TO_HUB) or
							   (dissect_current_state = WAIT_FOR_HUB) else '0';
								
PACKET_NUM_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) then
			packet_num <= "100";
		elsif (GSC_INIT_READ_IN = '1' and gsc_init_dataready = '1' and packet_num = "100") then
			packet_num <= "000";
		elsif (rx_fifo_rd = '1' and packet_num /= "100") then
			packet_num <= packet_num + "1";
		end if;
	end if;
end process PACKET_NUM_PROC;

transmit_fifo : fifo_65536x18x9
  PORT map(
    Reset             => tx_fifo_reset,
	RPReset           => tx_fifo_reset,
    WrClock           => CLK,
	RdClock           => CLK,
    Data(7 downto 0)  => GSC_REPLY_DATA_IN(15 downto 8),
    Data(8)           => '0',
    Data(16 downto 9) => GSC_REPLY_DATA_IN(7 downto 0),
    Data(17)          => '0',
    WrEn              => tx_fifo_wr,
    RdEn              => tx_fifo_rd,
    Q                 => tx_fifo_q,
    Full              => tx_full,
    Empty             => tx_empty
  );

tx_fifo_reset           <= '1' when (RESET = '1') or (too_much_data = '1' and dissect_current_state = CLEANUP) else '0';
tx_fifo_wr              <= '1' when GSC_REPLY_DATAREADY_IN = '1' and gsc_reply_read = '1' else '0';
tx_fifo_rd              <= '1' when TC_RD_EN_IN = '1' and dissect_current_state = LOAD_FRAME and (tx_frame_loaded /= g_MAX_FRAME_SIZE) else '0';

TC_DATA_PROC : process(dissect_current_state, tx_loaded_ctr, tx_data_ctr, tx_frame_loaded, g_MAX_FRAME_SIZE)
begin
	if (dissect_current_state = LOAD_FRAME) then
	
		TC_DATA_OUT(7 downto 0) <= tx_fifo_q(7 downto 0);
		
		if (tx_loaded_ctr = tx_data_ctr or tx_frame_loaded = g_MAX_FRAME_SIZE - x"1") then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
		
	elsif (dissect_current_state = LOAD_ACK) then
	
		TC_DATA_OUT(7 downto 0) <= tx_loaded_ctr(7 downto 0);
		
		if (tx_loaded_ctr = x"0010" + x"1") then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
	else
		TC_DATA_OUT <= (others => '0');
	end if;
end process TC_DATA_PROC;

GSC_REPLY_READ_OUT      <= gsc_reply_read;
gsc_reply_read          <= '1' when dissect_current_state = WAIT_FOR_RESPONSE or dissect_current_state = SAVE_RESPONSE else '0';

-- counter of data received from TRBNet hub
TX_DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			tx_data_ctr <= (others => '0');
		elsif (tx_fifo_wr = '1') then
			tx_data_ctr(15 downto 1) <= tx_data_ctr(15 downto 1) + x"1";
		end if;
	end if;
end process TX_DATA_CTR_PROC;

TOO_MUCH_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) then
			too_much_data <= '0';
		elsif (dissect_current_state = SAVE_RESPONSE) and (tx_data_ctr = x"fa00") then
			too_much_data <= '1';
		end if;
	end if;
end process TOO_MUCH_DATA_PROC;

DIVIDE_CTR_PROC : process(CLK)
begin
	if (RESET = '1') or (dissect_current_state = IDLE) then
		divide_ctr <= (others => '0');
	elsif (dissect_current_state = SAVE_RESPONSE) and (tx_data_ctr(10 downto 0) = b"101_0111_1000") then
		divide_ctr <= divide_ctr + x"1";
	end if;
end process DIVIDE_CTR_PROC;

-- total counter of data transported to frame constructor
TX_LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE or dissect_current_state = WAIT_FOR_HUB) then
			tx_loaded_ctr <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			tx_loaded_ctr <= tx_loaded_ctr + x"1";
		elsif (dissect_current_state = LOAD_ACK and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			tx_loaded_ctr <= tx_loaded_ctr + x"1";
		end if;
	end if;
end process TX_LOADED_CTR_PROC;

PS_BUSY_OUT <= '0' when (dissect_current_state = IDLE) else '1';

PS_RESPONSE_READY_OUT <= '1' when (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or 
									dissect_current_state = CLEANUP or dissect_current_state = WAIT_FOR_LOAD_ACK or
									dissect_current_state = LOAD_ACK or dissect_current_state = DIVIDE)
						else '0';

TC_FRAME_TYPE_OUT  <= x"0008";
TC_DEST_MAC_OUT    <= PS_SRC_MAC_ADDRESS_IN;
TC_DEST_IP_OUT     <= PS_SRC_IP_ADDRESS_IN;
TC_DEST_UDP_OUT(7 downto 0)    <= PS_SRC_UDP_PORT_IN(15 downto 8); --x"a861";
TC_DEST_UDP_OUT(15 downto 8)   <= PS_SRC_UDP_PORT_IN(7 downto 0); --x"a861";
TC_SRC_MAC_OUT     <= g_MY_MAC;
TC_SRC_IP_OUT      <= g_MY_IP;
TC_SRC_UDP_OUT     <= x"a861";
TC_IP_PROTOCOL_OUT <= x"11";

FRAME_SIZE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			TC_FRAME_SIZE_OUT <= (others => '0');
			TC_IP_SIZE_OUT    <= (others => '0');
		elsif (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = DIVIDE) then
			if  (size_left >= g_MAX_FRAME_SIZE) then
				TC_FRAME_SIZE_OUT <= g_MAX_FRAME_SIZE;
				TC_IP_SIZE_OUT    <= g_MAX_FRAME_SIZE;
			else
				TC_FRAME_SIZE_OUT <= size_left(15 downto 0);
				TC_IP_SIZE_OUT    <= size_left(15 downto 0);
			end if;
		elsif (dissect_current_state = WAIT_FOR_LOAD_ACK) then
			TC_FRAME_SIZE_OUT <= x"0010";
			TC_IP_SIZE_OUT    <= x"0010";
		end if;
	end if;
end process FRAME_SIZE_PROC;

TC_UDP_SIZE_OUT     <= tx_data_ctr - divide_ctr(7 downto 1);


TC_FLAGS_OFFSET_OUT(15 downto 14) <= "00";
MORE_FRAGMENTS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = CLEANUP) then
			TC_FLAGS_OFFSET_OUT(13) <= '0';
		elsif ((dissect_current_state = DIVIDE and TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') or (dissect_current_state = WAIT_FOR_LOAD)) then
			if ((tx_data_ctr - tx_loaded_ctr) < g_MAX_FRAME_SIZE) then
				TC_FLAGS_OFFSET_OUT(13) <= '0';  -- no more fragments
			else
				TC_FLAGS_OFFSET_OUT(13) <= '1';  -- more fragments
			end if;
		end if;
	end if;
end process MORE_FRAGMENTS_PROC;

OFFSET_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = CLEANUP) then
			TC_FLAGS_OFFSET_OUT(12 downto 0) <= (others => '0');
		elsif (dissect_current_state = DIVIDE and TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
			TC_FLAGS_OFFSET_OUT(12 downto 0) <= tx_loaded_ctr(15 downto 3) + x"1";
		end if;
	end if;
end process OFFSET_PROC;

DISSECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			if (g_SIMULATE = 0) then
				dissect_current_state <= IDLE;
			else
				dissect_current_state <= WAIT_FOR_RESPONSE;
			end if;
		else
			dissect_current_state <= dissect_next_state;
		end if;
	end if;
end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, reset_detected, too_much_data, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN, TC_BUSY_IN, data_ctr, PS_SELECTED_IN, GSC_INIT_READ_IN, GSC_REPLY_DATAREADY_IN, tx_loaded_ctr, tx_data_ctr, rx_fifo_q, GSC_BUSY_IN, tx_frame_loaded, g_MAX_FRAME_SIZE)
begin
	case dissect_current_state is
	
		when IDLE =>
			state <= x"1";
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			state <= x"2";
			if (PS_DATA_IN(8) = '1') then
				--if (reset_detected = '1') then  -- send ack only if reset command came
				--	dissect_next_state <= WAIT_FOR_LOAD_ACK;
				--else
					dissect_next_state <= WAIT_FOR_HUB;
				--end if;
			else
				dissect_next_state <= READ_FRAME;
			end if;
			
--		when WAIT_FOR_LOAD_ACK =>
--			state <= x"a";
--			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
--				dissect_next_state <= LOAD_ACK;
--			else
--				dissect_next_state <= WAIT_FOR_LOAD_ACK;
--			end if;
--			
--		when LOAD_ACK =>
--			state <= x"b";
--			if (tx_loaded_ctr = x"0010") then
--				dissect_next_state <= WAIT_FOR_HUB; --CLEANUP;
--			else
--				dissect_next_state <= LOAD_ACK;
--			end if;
			
		when WAIT_FOR_HUB =>
			state <= x"3";
			if (GSC_INIT_READ_IN = '1') then
				dissect_next_state <= LOAD_TO_HUB;
			else
				dissect_next_state <= WAIT_FOR_HUB;
			end if;						
		
		when LOAD_TO_HUB =>
			state <= x"4";
			if (rx_fifo_q(17) = '1') then
				if (reset_detected = '1') then
					dissect_next_state <= CLEANUP;
				else
					dissect_next_state <= WAIT_FOR_RESPONSE;
				end if;
			else
				dissect_next_state <= LOAD_TO_HUB;
			end if;	
			
		when WAIT_FOR_RESPONSE =>
			state <= x"5";
			if (GSC_REPLY_DATAREADY_IN = '1') then
				dissect_next_state <= SAVE_RESPONSE;
			else
				dissect_next_state <= WAIT_FOR_RESPONSE;
			end if;
			
		when SAVE_RESPONSE =>
			state <= x"6";
			if (GSC_REPLY_DATAREADY_IN = '0' and GSC_BUSY_IN = '0') then
				if (too_much_data = '0') then
					dissect_next_state <= WAIT_FOR_LOAD;
				else
					dissect_next_state <= CLEANUP;
				end if;
			else
				dissect_next_state <= SAVE_RESPONSE;
			end if;			
			
		when WAIT_FOR_LOAD =>
			state <= x"7";
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD_FRAME =>
			state <= x"8";
			if (tx_loaded_ctr = tx_data_ctr) then
				dissect_next_state <= CLEANUP;
			elsif (tx_frame_loaded = g_MAX_FRAME_SIZE) then
				dissect_next_state <= DIVIDE;
			else
				dissect_next_state <= LOAD_FRAME;
			end if;

		when DIVIDE =>
			state <= x"c";
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= DIVIDE;
			end if;
		
		when CLEANUP =>
			state <= x"9";
			dissect_next_state <= IDLE;
			
		when others =>
			state <= x"1"; 
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;


-- counter of bytes of currently constructed frame
FRAME_LOADED_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = DIVIDE or dissect_current_state = IDLE) then
			tx_frame_loaded <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			tx_frame_loaded <= tx_frame_loaded + x"1";
		end if;
	end if;
end process FRAME_LOADED_PROC;

-- counter down to 0 of bytes that have to be transmitted for a given packet
SIZE_LEFT_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = SAVE_RESPONSE) then
			size_left <= (others => '0');
		elsif (dissect_current_state = WAIT_FOR_LOAD) then
			size_left <= tx_data_ctr;
		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			size_left <= size_left - x"1";
		end if;
	end if;
end process SIZE_LEFT_PROC;


-- reset request packet detection
RESET_DETECTED_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = CLEANUP) then
			reset_detected <= '0';
		elsif (PS_DATA_IN(7 downto 0) = x"80" and dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then  -- first byte as 0x80
			reset_detected <= '1';
		end if;
	end if;
end process RESET_DETECTED_PROC;

MAKE_RESET_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			make_reset <= '0';
		elsif (dissect_current_state = CLEANUP and reset_detected = '1') then
			make_reset <= '1';
		else
			make_reset <= '0';
		end if;
	end if;
end process MAKE_RESET_PROC;










-- statistics
REC_FRAMES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			rec_frames <= (others => '0');
		elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			rec_frames <= rec_frames + x"1";
		end if;
	end if;
end process REC_FRAMES_PROC;

REPLY_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			reply_ctr <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr) then
			reply_ctr <= reply_ctr + x"1";
		end if;
	end if;
end process REPLY_CTR_PROC;


STATS_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			stats_current_state <= IDLE;
		else
			stats_current_state <= stats_next_state;
		end if;
	end if;
end process STATS_MACHINE_PROC;

STATS_MACHINE : process(stats_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, dissect_current_state, tx_loaded_ctr, tx_data_ctr)
begin

	case (stats_current_state) is
	
		when IDLE =>
			if ((dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') or (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr)) then
				stats_next_state <= LOAD_RECEIVED;
			else
				stats_next_state <= IDLE;
			end if;
		
		when LOAD_RECEIVED =>
			if (STAT_DATA_ACK_IN = '1') then
				stats_next_state <= LOAD_REPLY;
			else
				stats_next_state <= LOAD_RECEIVED;
			end if;
			
		when LOAD_REPLY =>
			if (STAT_DATA_ACK_IN = '1') then
				stats_next_state <= CLEANUP;
			else
				stats_next_state <= LOAD_REPLY;
			end if;		
		
		when CLEANUP =>
			stats_next_state <= IDLE;
	
	end case;

end process STATS_MACHINE;

SELECTOR : process(stats_current_state)
begin

	case(stats_current_state) is
		
		when LOAD_RECEIVED =>
			stat_data_temp <= x"0502" & rec_frames;
			STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE, 8));
		
		when LOAD_REPLY =>
			stat_data_temp <= x"0503" & reply_ctr;
			STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 1, 8));
			
		when others =>
			stat_data_temp <= (others => '0');
			STAT_ADDR_OUT  <= (others => '0');
	
	end case;
	
end process SELECTOR;

STAT_DATA_OUT(7 downto 0)   <= stat_data_temp(31 downto 24);
STAT_DATA_OUT(15 downto 8)  <= stat_data_temp(23 downto 16);
STAT_DATA_OUT(23 downto 16) <= stat_data_temp(15 downto 8);
STAT_DATA_OUT(31 downto 24) <= stat_data_temp(7 downto 0);

STAT_DATA_RDY_OUT <= '1' when stats_current_state /= IDLE and stats_current_state /= CLEANUP else '0';

-- end of statistics

end architecture RTL;
