LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_protocols.all;

--********
-- performs response constructors readout and splitting into frames

entity trb_net16_gbe_transmit_control2 is
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
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);
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
end trb_net16_gbe_transmit_control2;


architecture trb_net16_gbe_transmit_control2 of trb_net16_gbe_transmit_control2 is

attribute syn_encoding : string;

type transmit_states is (IDLE, PREPARE_HEADERS, WAIT_FOR_H, TRANSMIT, SEND_ONE, SEND_TWO, CLOSE, WAIT_FOR_TRANS, DIVIDE, CLEANUP);
signal transmit_current_state, transmit_next_state : transmit_states;
attribute syn_encoding of transmit_current_state : signal is "onehot";

signal tc_rd, tc_rd_q, tc_rd_qq : std_logic;
signal local_end : std_logic_vector(15 downto 0);

signal actual_frame_bytes, full_packet_size, ip_size, packet_loaded_bytes : std_logic_vector(15 downto 0);
signal go_to_divide, more_fragments : std_logic;
signal first_frame : std_logic;
signal mon_packets_sent_ctr : std_logic_vector(31 downto 0); 

begin

TRANSMIT_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		transmit_current_state <= IDLE;
	elsif rising_edge(CLK) then
		transmit_current_state <= transmit_next_state;
	end if;
end process TRANSMIT_MACHINE_PROC;

TRANSMIT_MACHINE : process(transmit_current_state, FC_H_READY_IN, TC_DATAREADY_IN, FC_READY_IN, local_end, TC_MAX_FRAME_IN, actual_frame_bytes, go_to_divide)
begin
	case transmit_current_state is
	
		when IDLE =>
			if (TC_DATAREADY_IN = '1') then
				transmit_next_state <= PREPARE_HEADERS;
			else
				transmit_next_state <= IDLE;
			end if;
			
		when PREPARE_HEADERS =>
			transmit_next_state<= WAIT_FOR_H;
		
		when WAIT_FOR_H =>
			if (FC_H_READY_IN = '1') then
				transmit_next_state <= TRANSMIT;
			else
				transmit_next_state <= WAIT_FOR_H;
			end if;
		
		when TRANSMIT =>
			if (local_end = x"0000") then
				transmit_next_state <= SEND_ONE;
			else
				if (actual_frame_bytes = TC_MAX_FRAME_IN - x"1") then
					transmit_next_state <= SEND_ONE;
				else
					transmit_next_state <= TRANSMIT;
				end if;
			end if;
			
		when SEND_ONE =>
			transmit_next_state <= SEND_TWO;
			
		when SEND_TWO =>
			transmit_next_state <= CLOSE;
			
		when CLOSE =>
			transmit_next_state <= WAIT_FOR_TRANS;
			
		when WAIT_FOR_TRANS =>
			if (FC_READY_IN = '1') then
				if (go_to_divide = '1') then
					transmit_next_state <= DIVIDE;
				else
					transmit_next_state <= CLEANUP;
				end if;
			else
				transmit_next_state <= WAIT_FOR_TRANS;
			end if;
		
		when DIVIDE =>
			transmit_next_state <= PREPARE_HEADERS;
			
		when CLEANUP =>
			transmit_next_state <= IDLE;
	
	end case;
end process TRANSMIT_MACHINE;

tc_rd               <= '1' when transmit_current_state = TRANSMIT else '0';
TC_RD_EN_OUT        <= tc_rd;

SYNC_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		tc_rd_q <= tc_rd;
		tc_rd_qq <= tc_rd_q;
		FC_WR_EN_OUT <= tc_rd_qq;
	end if;
end process SYNC_PROC;

ACTUAL_FRAME_BYTES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = IDLE or transmit_current_state = DIVIDE) then
			actual_frame_bytes <= (others => '0');
		elsif (transmit_current_state = TRANSMIT) then
			actual_frame_bytes <= actual_frame_bytes + x"1";
		else
			actual_frame_bytes <= actual_frame_bytes;
		end if;
	end if;
end process ACTUAL_FRAME_BYTES_PROC;

GO_TO_DIVIDE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = IDLE or transmit_current_state = DIVIDE) then
			go_to_divide <= '0';
		elsif (transmit_current_state = TRANSMIT and actual_frame_bytes = TC_MAX_FRAME_IN - x"1") then
			go_to_divide <= '1';
--		elsif (transmit_current_state = SEND_ONE and full_packet_size < packet_loaded_bytes - x"1") then
--			go_to_divide <= '1';
--		elsif (transmit_current_state = SEND_TWO and full_packet_size < packet_loaded_bytes - x"1") then
--			go_to_divide <= '1';
		elsif (transmit_current_state = SEND_ONE and full_packet_size = packet_loaded_bytes) then
			go_to_divide <= '0';
		else
			go_to_divide <= go_to_divide;
		end if;		
	end if;
end process GO_TO_DIVIDE_PROC;

LOCAL_END_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = IDLE and TC_DATAREADY_IN = '1') then
			local_end <= TC_FRAME_SIZE_IN - x"1";
			full_packet_size <= TC_FRAME_SIZE_IN;
		elsif (transmit_current_state = TRANSMIT) then
			local_end <= local_end - x"1";
			full_packet_size <= full_packet_size;
		else
			local_end <= local_end;
			full_packet_size <= full_packet_size;
		end if; 
	end if;
end process LOCAL_END_PROC;

FC_DATA_OUT         <= TC_DATA_IN;
FC_SOD_OUT			<= '1' when transmit_current_state = WAIT_FOR_H else '0';
FC_EOD_OUT			<= '1' when transmit_current_state = CLOSE else '0';

process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = PREPARE_HEADERS) then
			if (local_end >= TC_MAX_FRAME_IN) then
				ip_size <= TC_MAX_FRAME_IN;
			else
				ip_size <= local_end + x"1";
			end if;
		else
			ip_size <= ip_size;
		end if;
	end if;
end process;
FC_IP_SIZE_OUT      <= ip_size; 
FC_UDP_SIZE_OUT		<= full_packet_size; --TC_FRAME_SIZE_IN;

FC_FLAGS_OFFSET_OUT(15 downto 14) <= "00";
FC_FLAGS_OFFSET_OUT(13) <= more_fragments;
MORE_FRAGMENTS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = PREPARE_HEADERS) then
			if (local_end >= TC_MAX_FRAME_IN) then
				more_fragments <= '1';
			else
				more_fragments <= '0';
			end if;
		else
			more_fragments <= more_fragments;
		end if;
	end if;
end process MORE_FRAGMENTS_PROC;
FC_FLAGS_OFFSET_OUT(12 downto 0) <= ('0' & x"000") when first_frame = '1' else (packet_loaded_bytes(15 downto 3) + x"1");

PACKET_LOADED_BYTES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = IDLE) then
			packet_loaded_bytes <= x"0000";
		elsif (transmit_current_state = TRANSMIT) then
			packet_loaded_bytes <= packet_loaded_bytes + x"1";
--		elsif (transmit_current_state = DIVIDE and first_frame = '1') then	
--			packet_loaded_bytes <= packet_loaded_bytes + x"8";	-- 8bytes for udp headers added for the first offset
		else
			packet_loaded_bytes <= packet_loaded_bytes;
		end if;
	end if;
end process PACKET_LOADED_BYTES_PROC;

FIRST_FRAME_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = IDLE) then
			first_frame <= '1';
		elsif (transmit_current_state = DIVIDE) then
			first_frame <= '0';
		else
			first_frame <= first_frame;
		end if;
	end if;	
end process FIRST_FRAME_PROC;


TC_TRANSMISSION_DONE_OUT <= '1' when transmit_current_state = CLEANUP else '0';

FC_FRAME_TYPE_OUT    <= TC_FRAME_TYPE_IN;
FC_IP_PROTOCOL_OUT   <= TC_IP_PROTOCOL_IN;
DEST_MAC_ADDRESS_OUT <= TC_DEST_MAC_IN;
DEST_IP_ADDRESS_OUT  <= TC_DEST_IP_IN;
DEST_UDP_PORT_OUT    <= TC_DEST_UDP_IN;
SRC_MAC_ADDRESS_OUT  <= TC_SRC_MAC_IN;
SRC_IP_ADDRESS_OUT   <= TC_SRC_IP_IN;
SRC_UDP_PORT_OUT     <= TC_SRC_UDP_IN;
FC_IDENT_OUT         <= TC_IDENT_IN;

-- monitoring

process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			mon_packets_sent_ctr <= (others => '0');
		elsif (transmit_current_state = CLEANUP) then
			mon_packets_sent_ctr <= mon_packets_sent_ctr + x"1";
		else
			mon_packets_sent_ctr <= mon_packets_sent_ctr;
		end if;
	end if;
end process;

MONITOR_TX_PACKETS_OUT <= mon_packets_sent_ctr;

end trb_net16_gbe_transmit_control2;


