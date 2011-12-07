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
	-- end of protocol specific ports
	
	-- debug
		DEBUG_OUT		: out	std_logic_vector(31 downto 0)
	);
end entity trb_net16_gbe_response_constructor_SCTRL;

architecture RTL of trb_net16_gbe_response_constructor_SCTRL is

attribute syn_encoding	: string;

type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_TO_HUB, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_LOAD, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

type stats_states is (IDLE, LOAD_RECEIVED, LOAD_INIT, LOAD_REPLY, CLEANUP);
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
signal gsc_reply_read           : std_logic;

signal tx_data_ctr              : std_logic_vector(15 downto 0);
signal tx_loaded_ctr            : std_logic_vector(15 downto 0);

signal packet_num               : std_logic_vector(2 downto 0);

signal init_ctr, reply_ctr      : std_logic_vector(15 downto 0);
signal rx_empty, tx_empty       : std_logic;

signal dbg_timeout              : std_logic_vector(27 downto 0);

	
begin

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
    Full             => open,
    Empty            => rx_empty
  );

rx_fifo_wr              <= '1' when PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1' else '0';
rx_fifo_rd              <= '1' when (GSC_INIT_READ_IN = '1' and dissect_current_state = LOAD_TO_HUB and rx_fifo_q(17) = '0') or (dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1') else '0';

GSC_INIT_DATA_OUT(7 downto 0)  <= rx_fifo_q(16 downto 9);
GSC_INIT_DATA_OUT(15 downto 8) <= rx_fifo_q(7 downto 0);
GSC_INIT_PACKET_NUM_OUT <= packet_num;
GSC_INIT_DATAREADY_OUT  <= '1' when rx_fifo_rd = '1' and (GSC_INIT_READ_IN = '1' and dissect_current_state = LOAD_TO_HUB and rx_fifo_q(17) = '0') else '0';

transmit_fifo : fifo_1024x16x8
  PORT map(
    Reset             => RESET,
	RPReset           => RESET,
    WrClock           => CLK,
	RdClock           => CLK,
    Data(7 downto 0)  => GSC_REPLY_DATA_IN(7 downto 0),
    Data(8)           => '0',
    Data(16 downto 9) => GSC_REPLY_DATA_IN(15 downto 8),
    Data(17)          => '0',
    WrEn              => tx_fifo_wr,
    RdEn              => tx_fifo_rd,
    Q                 => tx_fifo_q,
    Full              => open,
    Empty             => tx_empty
  );

tx_fifo_wr              <= '1' when GSC_REPLY_DATAREADY_IN = '1' and gsc_reply_read = '1' else '0';
tx_fifo_rd              <= '1' when TC_RD_EN_IN = '1' and dissect_current_state = LOAD_FRAME else '0';
TC_DATA_OUT(7 downto 0) <= tx_fifo_q(7 downto 0) when dissect_current_state = LOAD_FRAME else (others => '0');
TC_DATA_OUT(8)          <= '1' when tx_loaded_ctr = tx_data_ctr and dissect_current_state = LOAD_FRAME else '0';
GSC_REPLY_READ_OUT      <= gsc_reply_read;
gsc_reply_read          <= '1' when dissect_current_state = WAIT_FOR_RESPONSE or dissect_current_state = SAVE_RESPONSE else '0';

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

TX_LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			tx_loaded_ctr <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			tx_loaded_ctr <= tx_loaded_ctr + x"1";
		end if;
	end if;
end process TX_LOADED_CTR_PROC;

PS_BUSY_OUT <= '0' when (dissect_current_state = IDLE) else '1';

PS_RESPONSE_READY_OUT <= '1' when (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or dissect_current_state = CLEANUP) else '0';

TC_FRAME_SIZE_OUT  <= tx_data_ctr;

TC_FRAME_TYPE_OUT  <= x"0008";
TC_DEST_MAC_OUT    <= PS_SRC_MAC_ADDRESS_IN;
TC_DEST_IP_OUT     <= PS_SRC_IP_ADDRESS_IN;
TC_DEST_UDP_OUT    <= x"61a8";
TC_SRC_MAC_OUT     <= g_MY_MAC;
TC_SRC_IP_OUT      <= g_MY_IP;
TC_SRC_UDP_OUT     <= x"61a8";
TC_IP_PROTOCOL_OUT <= X"11";


PACKET_NUM_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			packet_num <= "111";
		elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			packet_num <= packet_num + "1";
		end if;
	end if;
end process PACKET_NUM_PROC;


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

DISSECT_MACHINE : process(dissect_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN, TC_BUSY_IN, data_ctr, PS_SELECTED_IN, GSC_INIT_READ_IN, GSC_REPLY_DATAREADY_IN, tx_loaded_ctr, tx_data_ctr, rx_fifo_q)
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
				dissect_next_state <= WAIT_FOR_HUB;
			else
				dissect_next_state <= READ_FRAME;
			end if;
			
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
				dissect_next_state <= WAIT_FOR_RESPONSE;
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
			if (GSC_REPLY_DATAREADY_IN = '0') then
				dissect_next_state <= WAIT_FOR_LOAD;
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
			else
				dissect_next_state <= LOAD_FRAME;
			end if;
		
		when CLEANUP =>
			state <= x"9";
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;



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

INIT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			init_ctr <= (others => '0');
		elsif (GSC_INIT_READ_IN = '1' and (dissect_current_state = LOAD_TO_HUB and rx_fifo_q(17) = '0')) then
			init_ctr <= init_ctr + x"1";
		end if;
	end if;
end process INIT_CTR_PROC;

REPLY_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			reply_ctr <= (others => '0');
		elsif (GSC_REPLY_DATAREADY_IN = '1' and gsc_reply_read = '1') then
			reply_ctr <= reply_ctr + x"1";
		end if;
	end if;
end process REPLY_CTR_PROC;

DBG_TIMEOUT_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			dbg_timeout <= (others => '0');
		else
			dbg_timeout <= dbg_timeout + x"1";
		end if;
	end if;
end process DBG_TIMEOUT_PROC;


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

STATS_MACHINE : process(stats_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, dissect_current_state)
begin

	case (stats_current_state) is
	
		when IDLE =>
			if ((dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') or (dbg_timeout(24) = '1')) then
				stats_next_state <= LOAD_RECEIVED;
			else
				stats_next_state <= IDLE;
			end if;
		
		when LOAD_RECEIVED =>
			if (STAT_DATA_ACK_IN = '1') then
				stats_next_state <= LOAD_INIT;
			else
				stats_next_state <= LOAD_RECEIVED;
			end if;
			
		when LOAD_INIT =>
			if (STAT_DATA_ACK_IN = '1') then
				stats_next_state <= LOAD_REPLY;
			else
				stats_next_state <= LOAD_INIT;
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
			
		when LOAD_INIT =>
			stat_data_temp <= x"050a" & init_ctr;
			STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 1, 8));
		
		when LOAD_REPLY =>
			stat_data_temp <= x"050b" & reply_ctr;
			STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 2, 8));
			
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
