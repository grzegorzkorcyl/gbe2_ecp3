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
generic ( STAT_ADDRESS_BASE : integer := 0;
	SLOWCTRL_BUFFER_SIZE : integer range 1 to 4 := 1
);
	port (
		CLK			: in	std_logic;  -- system clock
		RESET			: in	std_logic;
		
	-- INTERFACE	
		MY_MAC_IN				: in std_logic_vector(47 downto 0);
		MY_IP_IN				: in std_logic_vector(31 downto 0);
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
		
		DEBUG_OUT		  : out std_logic_vector(63 downto 0);
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
		CFG_ADDITIONAL_HDR_IN    : in std_logic;
		CFG_MAX_REPLY_SIZE_IN    : in std_logic_vector(31 downto 0);
	-- end of protocol specific ports
	
		MONITOR_SELECT_REC_OUT	      : out	std_logic_vector(31 downto 0);
		MONITOR_SELECT_REC_BYTES_OUT  : out	std_logic_vector(31 downto 0);
		MONITOR_SELECT_SENT_BYTES_OUT : out	std_logic_vector(31 downto 0);
		MONITOR_SELECT_SENT_OUT	      : out	std_logic_vector(31 downto 0);
		
		DATA_HIST_OUT : out hist_array
	);
end entity trb_net16_gbe_response_constructor_SCTRL;

architecture RTL of trb_net16_gbe_response_constructor_SCTRL is

attribute syn_encoding	: string;

--type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_TO_HUB, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_TC, DIVIDE, WAIT_FOR_LOAD, CLEANUP);
type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_TO_HUB, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_LOAD, CLEANUP);
--type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_A_WORD, WAIT_ONE, WAIT_TWO, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_TC, DIVIDE, WAIT_FOR_LOAD, CLEANUP);
--type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_HUB, LOAD_TO_HUB, WAIT_FOR_RESPONSE, SAVE_RESPONSE, LOAD_FRAME, WAIT_FOR_TC, DIVIDE, WAIT_FOR_LOAD, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "onehot";

type stats_states is (IDLE, LOAD_RECEIVED, LOAD_REPLY, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;
attribute syn_encoding of stats_current_state : signal is "onehot";

signal saved_target_ip          : std_logic_vector(31 downto 0);
signal data_ctr                 : integer range 0 to 30;


signal stat_data_temp           : std_logic_vector(31 downto 0);
signal rec_frames               : std_logic_vector(15 downto 0);

signal rx_fifo_q                : std_logic_vector(17 downto 0);
signal rx_fifo_qq                : std_logic_vector(17 downto 0);
signal rx_fifo_wr, rx_fifo_rd   : std_logic;
signal tx_eod, rx_eod           : std_logic;

signal tx_fifo_q                : std_logic_vector(8 downto 0);
signal tx_fifo_wr, tx_fifo_rd   : std_logic;
signal tx_fifo_reset            : std_logic;
signal gsc_reply_read           : std_logic;
signal gsc_init_dataready       : std_logic;
signal gsc_init_dataready_q       : std_logic;

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


signal fifo_rd_q               : std_logic;

signal too_much_data           : std_logic;

signal rx_fifo_data            : std_logic_vector(8 downto 0);
signal tx_fifo_data            : std_logic_vector(17 downto 0);

signal tc_wr                   : std_logic;
signal state                   : std_logic_vector(3 downto 0);
signal saved_hdr_1              : std_logic_vector(7 downto 0) := x"ab";
signal saved_hdr_2              : std_logic_vector(7 downto 0) := x"cd";
signal saved_hdr_ctr            : std_logic_vector(3 downto 0);

signal mon_rec_frames, mon_rec_bytes, mon_sent_frames, mon_sent_bytes : std_logic_vector(31 downto 0);

attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of rx_fifo_wr, rx_fifo_rd, gsc_init_dataready, tx_fifo_wr, tx_fifo_rd, gsc_reply_read, state : signal is true;
attribute syn_preserve of rx_fifo_wr, rx_fifo_rd, gsc_init_dataready, tx_fifo_wr, tx_fifo_rd, gsc_reply_read, state : signal is true;

signal hist_inst : hist_array;
signal reset_all_hist : std_logic_vector(31 downto 0);

begin

MAKE_RESET_OUT <= make_reset;

receive_fifo : fifo_2048x8x16
  PORT map(
    Reset            => RESET,
	RPReset          => RESET,
    WrClock          => CLK,
	RdClock          => CLK,
    Data             => rx_fifo_data,
    WrEn             => rx_fifo_wr,
    RdEn             => rx_fifo_rd,
    Q                => rx_fifo_q,
    Full             => rx_full,
    Empty            => rx_empty
  );

--TODO: change to synchronous
rx_fifo_rd              <= '1' when (gsc_init_dataready = '1' and dissect_current_state = LOAD_TO_HUB) or 
								(gsc_init_dataready = '1' and dissect_current_state = WAIT_FOR_HUB and GSC_INIT_READ_IN = '1') or
								(dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1')
								else '0';  -- preload first word
								
RX_FIFO_WR_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
	
		if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1' and (saved_hdr_ctr = "0100" or saved_hdr_ctr = "1000")) then
			rx_fifo_wr <= '1';
		else
			rx_fifo_wr <= '0';
		end if;
		
		rx_fifo_data <= PS_DATA_IN;
	end if;
end process RX_FIFO_WR_SYNC;

SAVED_HDR_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE and PS_WR_EN_IN = '0' and PS_ACTIVATE_IN = '0') then
			saved_hdr_ctr <= "0001";
		elsif (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1' and saved_hdr_ctr /= "1000") then
			saved_hdr_ctr(3 downto 0) <= saved_hdr_ctr(2 downto 0) & '0';
		else
			saved_hdr_ctr <= saved_hdr_ctr;
		end if;
	end if;
end process SAVED_HDR_CTR_PROC;

SAVED_HDR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			if (saved_hdr_ctr = "0001") then
				saved_hdr_1 <= PS_DATA_IN(7 downto 0);
				saved_hdr_2 <= saved_hdr_2;
			elsif (saved_hdr_ctr = "0010") then
				saved_hdr_2 <= PS_DATA_IN(7 downto 0);
				saved_hdr_1 <= saved_hdr_1;
			else
				saved_hdr_1 <= saved_hdr_1;
				saved_hdr_2 <= saved_hdr_2;
			end if;
		else
			saved_hdr_1 <= saved_hdr_1;
			saved_hdr_2 <= saved_hdr_2;
		end if;
	end if;
end process SAVED_HDR_PROC;

--RX_FIFO_RD_SYNC : process(CLK)
--begin
--	if rising_edge(CLK) then
--	
--		if (dissect_current_state = LOAD_A_WORD) then
--			rx_fifo_rd <= '1';
--		else
--			rx_fifo_rd <= '0';
--		end if;
--		
----		if (dissect_current_state = WAIT_ONE) then
----			gsc_init_dataready <= '1';
----		elsif (dissect_current_state = WAIT_FOR_HUB and GSC_INIT_READ_IN = '0') then
----			gsc_init_dataready <= '1';
----		else
----			gsc_init_dataready <= '0';
----		end if;
--
----		if (dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1') then  -- preload the first byte
----			rx_fifo_rd <= '1';
----		elsif (dissect_current_state = LOAD_TO_HUB) then
----			rx_fifo_rd <= '1';
----		elsif (dissect_current_state = WAIT_FOR_HUB and GSC_INIT_READ_IN = '1') then
----			rx_fifo_rd <= '1';
----		else
----			rx_fifo_rd <= '0';
----		end if;
----		
----		if (dissect_current_state = WAIT_FOR_HUB) then
----			gsc_init_dataready <= '1';
----		elsif (dissect_current_state = LOAD_TO_HUB and GSC_INIT_READ_IN = '1') then
----			gsc_init_dataready <= '1';
----		else
----			gsc_init_dataready <= '0';
----		end if;
----		
----		if (dissect_current_state = WAIT_FOR_HUB) then
----			packet_num <= "100";
----		elsif (dissect_current_state = LOAD_TO_HUB) then
----			if (gsc_init_dataready = '1' and packet_num = "100") then
----				packet_num <= "000";
----			elsif (gsc_init_dataready = '1' and packet_num /= "100") then
----				packet_num <= packet_num + "1";
----			else
----				packet_num <= packet_num;
----			end if;
----		else
----			packet_num <= packet_num;
----		end if;
--
--		if (dissect_current_state = READ_FRAME) then
--			packet_num <= "011";
--		elsif (dissect_current_state = LOAD_A_WORD) then
--			if (packet_num = "100") then
--				packet_num <= "000";
--			else
--				packet_num <= packet_num + "1";
--			end if;
--		else
--			packet_num <= packet_num;
--		end if;
--	
--		GSC_INIT_DATA_OUT(7 downto 0)  <= rx_fifo_q(16 downto 9);
--		GSC_INIT_DATA_OUT(15 downto 8) <= rx_fifo_q(7 downto 0);
--		
--		--GSC_INIT_DATAREADY_OUT  <= gsc_init_dataready;
--		
----		GSC_INIT_PACKET_NUM_OUT <= packet_num;
--	
--	end if;
--end process RX_FIFO_RD_SYNC;
--
--GSC_INIT_DATAREADY_OUT <= '1' when dissect_current_state = WAIT_FOR_HUB else '0';

----TODO: add a register
GSC_INIT_DATA_OUT(7 downto 0)  <= rx_fifo_q(16 downto 9);
GSC_INIT_DATA_OUT(15 downto 8) <= rx_fifo_q(7 downto 0);

------ TODO: change it to synchronous
GSC_INIT_PACKET_NUM_OUT <= packet_num;
GSC_INIT_DATAREADY_OUT  <= gsc_init_dataready;
gsc_init_dataready <= '1' when (GSC_INIT_READ_IN = '1' and dissect_current_state = LOAD_TO_HUB) or
							   (dissect_current_state = WAIT_FOR_HUB) else '0';

PACKET_NUM_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			packet_num <= "100";
		elsif (GSC_INIT_READ_IN = '1' and rx_fifo_rd = '1' and packet_num = "100") then
			packet_num <= "000";
		elsif (rx_fifo_rd = '1' and packet_num /= "100") then
			packet_num <= packet_num + "1";
		end if;
	end if;
end process PACKET_NUM_PROC;

tf_4k_gen : if SLOWCTRL_BUFFER_SIZE = 1 generate
	transmit_fifo : fifo_4kx18x9
	  PORT map(
	    Reset             => tx_fifo_reset,
		RPReset           => tx_fifo_reset,
	    WrClock           => CLK,
		RdClock           => CLK,
		Data              => tx_fifo_data,
	    WrEn              => tx_fifo_wr,
	    RdEn              => tx_fifo_rd,
	    Q                 => tx_fifo_q,
	    Full              => tx_full,
	    Empty             => tx_empty
	  );
end generate tf_4k_gen;

tf_65k_gen : if SLOWCTRL_BUFFER_SIZE = 2 generate
	transmit_fifo : fifo_65536x18x9
	  PORT map(
	    Reset             => tx_fifo_reset,
		RPReset           => tx_fifo_reset,
	    WrClock           => CLK,
		RdClock           => CLK,
		Data              => tx_fifo_data,
	    WrEn              => tx_fifo_wr,
	    RdEn              => tx_fifo_rd,
	    Q                 => tx_fifo_q,
	    Full              => tx_full,
	    Empty             => tx_empty
	  );
end generate tf_65k_gen;

TX_FIFO_WR_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (GSC_REPLY_DATAREADY_IN = '1' and gsc_reply_read = '1') then
			tx_fifo_wr <= '1';
		elsif (saved_hdr_ctr = "0010") then
			tx_fifo_wr <= '1';
		else
			tx_fifo_wr <= '0';
		end if;
		
		if (saved_hdr_ctr = "010") then
			tx_fifo_data <= '0' & PS_DATA_IN(7 downto 0) & '0' & x"02";
		else
			tx_fifo_data(7 downto 0)  <= GSC_REPLY_DATA_IN(15 downto 8);
			tx_fifo_data(8)           <= '0';
			tx_fifo_data(16 downto 9) <= GSC_REPLY_DATA_IN(7 downto 0);
			tx_fifo_data(17)          <= '0';
		end if;
	end if;
end process TX_FIFO_WR_SYNC;

--TX_FIFO_RD_SYNC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (dissect_current_state = LOAD_FRAME and PS_SELECTED_IN = '1' and tx_frame_loaded /= g_MAX_FRAME_SIZE) then
--			tx_fifo_rd <= '1';
--		else
--			tx_fifo_rd <= '0';
--		end if;
--	end if;
--end process TX_FIFO_RD_SYNC;
tx_fifo_rd <= '1' when TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1' else '0';
		
TX_FIFO_SYNC_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (too_much_data = '1' and dissect_current_state = CLEANUP) then
			tx_fifo_reset <= '1';
		else
			tx_fifo_reset <= '0';
		end if;
	end if;
end process TX_FIFO_SYNC_PROC;

TC_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then

		TC_DATA_OUT(7 downto 0) <= tx_fifo_q(7 downto 0);
		
		--if (tx_loaded_ctr = tx_data_ctr + x"1" or tx_frame_loaded = g_MAX_FRAME_SIZE - x"1") then
		if (tx_loaded_ctr = tx_data_ctr) then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
	end if;
end process TC_DATA_PROC;

GSC_REPLY_READ_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = WAIT_FOR_RESPONSE or dissect_current_state = SAVE_RESPONSE) then
			gsc_reply_read <= '1';
		else
			gsc_reply_read <= '0';
		end if;
	end if;
end process GSC_REPLY_READ_PROC;
GSC_REPLY_READ_OUT      <= gsc_reply_read;

-- counter of data received from TRBNet hub
TX_DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			tx_data_ctr <= (others => '0');
		elsif (tx_fifo_wr = '1') then
			tx_data_ctr <= tx_data_ctr + x"2";
		end if;
	end if;
end process TX_DATA_CTR_PROC;

TOO_MUCH_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			too_much_data <= '0';
		elsif (dissect_current_state = SAVE_RESPONSE) and (tx_data_ctr = CFG_MAX_REPLY_SIZE_IN(15 downto 0)) then
			too_much_data <= '1';
		else
			too_much_data <= too_much_data;
		end if;
	end if;
end process TOO_MUCH_DATA_PROC;

-- total counter of data transported to frame constructor
TX_LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			tx_loaded_ctr <= x"0000";
		elsif (dissect_current_state = LOAD_FRAME and PS_SELECTED_IN = '1' and TC_RD_EN_IN = '1') then
			tx_loaded_ctr <= tx_loaded_ctr + x"1";
		else
			tx_loaded_ctr <= tx_loaded_ctr;
		end if;
	end if;
end process TX_LOADED_CTR_PROC;
						
PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (too_much_data = '0') then
			if (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or dissect_current_state = CLEANUP) then
				PS_RESPONSE_READY_OUT <= '1';
			else
				PS_RESPONSE_READY_OUT <= '0';
			end if;
		end if;
		
		if (dissect_current_state = IDLE or dissect_current_state = WAIT_FOR_RESPONSE) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
	end if;	
end process PS_RESPONSE_SYNC;

TC_FRAME_TYPE_OUT  <= x"0008";
TC_DEST_MAC_OUT    <= PS_SRC_MAC_ADDRESS_IN;
TC_DEST_IP_OUT     <= PS_SRC_IP_ADDRESS_IN;
TC_DEST_UDP_OUT(7 downto 0)    <= PS_SRC_UDP_PORT_IN(15 downto 8);
TC_DEST_UDP_OUT(15 downto 8)   <= PS_SRC_UDP_PORT_IN(7 downto 0);
TC_SRC_MAC_OUT     <= MY_MAC_IN;
TC_SRC_IP_OUT      <= MY_IP_IN;
TC_SRC_UDP_OUT     <= x"9065"; --x"a861";
TC_IP_PROTOCOL_OUT <= x"11";
TC_IDENT_OUT       <= x"3" & reply_ctr(11 downto 0);

TC_FRAME_SIZE_OUT   <= tx_data_ctr;

DISSECT_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		dissect_current_state <= IDLE;
	elsif rising_edge(CLK) then
--		if (RESET = '1') then
--			if (g_SIMULATE = 0) then
--				dissect_current_state <= IDLE;
--			else
--				dissect_current_state <= WAIT_FOR_RESPONSE;
--			end if;
--		else
			dissect_current_state <= dissect_next_state;
--		end if;
	end if;
end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, reset_detected, too_much_data, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN, PS_SELECTED_IN, GSC_INIT_READ_IN, GSC_REPLY_DATAREADY_IN, tx_loaded_ctr, tx_data_ctr, rx_fifo_q, GSC_BUSY_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			state <= x"0";
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			state <= x"1";
			if (PS_DATA_IN(8) = '1') then
				dissect_next_state <= WAIT_FOR_HUB;
			else
				dissect_next_state <= READ_FRAME;
			end if;
			
		when WAIT_FOR_HUB =>
			state <= x"2";
			if (GSC_INIT_READ_IN = '1') then
				dissect_next_state <= LOAD_TO_HUB;
			else
				dissect_next_state <= WAIT_FOR_HUB;
			end if;						
		
		when LOAD_TO_HUB =>
			state <= x"3";
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
			state <= x"4";
			if (GSC_REPLY_DATAREADY_IN = '1') then
				dissect_next_state <= SAVE_RESPONSE;
			else
				dissect_next_state <= WAIT_FOR_RESPONSE;
			end if;
			
		when SAVE_RESPONSE =>
			state <= x"5";
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
			state <= x"6";
			if (PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
			
		when LOAD_FRAME =>
			state <= x"7";
			if (tx_loaded_ctr = tx_data_ctr) then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD_FRAME;
			end if;
		
		when CLEANUP =>
			state <= x"8";
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

-- reset request packet detection
 RESET_DETECTED_PROC : process(CLK)
 begin
	 if rising_edge(CLK) then
		 if (dissect_current_state = IDLE) then
			 reset_detected <= '0';
		 elsif (PS_DATA_IN(7 downto 0) = x"80" and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1' and saved_hdr_ctr = "0100") then
			 reset_detected <= '1';
		else
			reset_detected <= reset_detected;
		 end if;
	 end if;
 end process RESET_DETECTED_PROC;
 
 MAKE_RESET_PROC : process(CLK)
 begin
	 if rising_edge(CLK) then
		 if (dissect_current_state = IDLE) then
			 make_reset <= '0';
		 elsif (dissect_current_state = CLEANUP and reset_detected = '1') then
			 make_reset <= '1';
		else
			make_reset <= make_reset;
		 end if;
	 end if;
 end process MAKE_RESET_PROC;


-- monitoring

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

	process(CLK)
	begin
		if rising_edge(CLK) then
			if (reset_all_hist /= x"0000_0000") then
				hist_inst(i) <= (others => '0');
			elsif (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr and i = to_integer(unsigned(tx_data_ctr(15 downto 11)))) then
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
		DEBUG_OUT(0) <= rx_full;
		DEBUG_OUT(1) <= rx_empty;
		DEBUG_OUT(2) <= tx_full;
		DEBUG_OUT(3) <= tx_empty;
		DEBUG_OUT(7 downto 4) <= state;
	end if;
end process;

DEBUG_OUT(63 downto 8) <= (others => '0');

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_rec_frames <= (others => '0');
		elsif (dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1') then
			mon_rec_frames <= mon_rec_frames + x"1";
		else
			mon_rec_frames <= mon_rec_frames;
		end if;
	end if;
end process;
MONITOR_SELECT_REC_OUT <= mon_rec_frames;

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_rec_bytes <= (others => '0');
		elsif (rx_fifo_wr = '1') then
			mon_rec_bytes <= mon_rec_bytes + x"1";
		else
			mon_rec_bytes <= mon_rec_bytes;
		end if;
	end if;
end process;
MONITOR_SELECT_REC_BYTES_OUT <= mon_rec_bytes;

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_sent_frames <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr) then
			mon_sent_frames <= mon_sent_frames + x"1";
		else
			mon_sent_frames <= mon_sent_frames;
		end if;
	end if;
end process;
MONITOR_SELECT_SENT_OUT <= mon_sent_frames;

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_sent_bytes <= (others => '0');
		elsif (tx_fifo_rd = '1') then
			mon_sent_bytes <= mon_sent_bytes + x"1";
		else
			mon_sent_bytes <= mon_sent_bytes;
		end if;
	end if;
end process;
MONITOR_SELECT_SENT_BYTES_OUT <= mon_sent_bytes;

-- statistics
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
--
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
--STATS_MACHINE : process(stats_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, dissect_current_state, tx_loaded_ctr, tx_data_ctr)
--begin
--
--	case (stats_current_state) is
--	
--		when IDLE =>
--			if ((dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') or (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr)) then
--				stats_next_state <= LOAD_RECEIVED;
--			else
--				stats_next_state <= IDLE;
--			end if;
--		
--		when LOAD_RECEIVED =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= LOAD_REPLY;
--			else
--				stats_next_state <= LOAD_RECEIVED;
--			end if;
--			
--		when LOAD_REPLY =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= CLEANUP;
--			else
--				stats_next_state <= LOAD_REPLY;
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
--			when LOAD_RECEIVED =>
--				stat_data_temp <= x"0502" & rec_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE, 8));
--			
--			when LOAD_REPLY =>
--				stat_data_temp <= x"0503" & reply_ctr;
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
----STAT_DATA_RDY_OUT <= '1' when stats_current_state /= IDLE and stats_current_state /= CLEANUP else '0';
--
---- end of statistics


end architecture RTL;
