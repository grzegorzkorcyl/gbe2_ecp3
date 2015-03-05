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
-- 

entity trb_net16_gbe_response_constructor_DHCP is
generic (
	STAT_ADDRESS_BASE : integer := 0;
	DO_SIMULATION : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE
	MY_MAC_IN		: in	std_logic_vector(47 downto 0);
	MY_IP_IN		: in	std_logic_vector(31 downto 0);
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

	MY_IP_OUT			: out	std_logic_vector(31 downto 0);
	DHCP_START_IN		: in	std_logic;
	DHCP_DONE_OUT		: out	std_logic;

-- debug
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_response_constructor_DHCP;


architecture trb_net16_gbe_response_constructor_DHCP of trb_net16_gbe_response_constructor_DHCP is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_response_constructor_DHCP : architecture is "GBE_MAIN_group";

attribute syn_encoding	: string;

type main_states is (BOOTING, DELAY, SENDING_DISCOVER, WAITING_FOR_OFFER, SENDING_REQUEST, WAITING_FOR_ACK, ESTABLISHED);
signal main_current_state, main_next_state : main_states;
attribute syn_encoding of main_current_state: signal is "onehot";

type receive_states is (IDLE, DISCARD, CLEANUP, SAVE_VALUES);
signal receive_current_state, receive_next_state : receive_states;
attribute syn_encoding of receive_current_state: signal is "onehot";

type discover_states is (IDLE, WAIT_FOR_LOAD, BOOTP_HEADERS, CLIENT_IP, YOUR_IP, ZEROS1, MY_MAC, ZEROS2, VENDOR_VALS, VENDOR_VALS2, TERMINATION, CLEANUP);
signal construct_current_state, construct_next_state : discover_states;
attribute syn_encoding of construct_current_state: signal is "onehot";


type stats_states is (IDLE, LOAD_SENT, LOAD_RECEIVED, LOAD_DISCARDED, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;
attribute syn_encoding of stats_current_state : signal is "onehot";

signal state                    : std_logic_vector(3 downto 0);
signal rec_frames               : std_logic_vector(15 downto 0);
signal sent_frames              : std_logic_vector(15 downto 0);

signal wait_ctr                 : std_logic_vector(31 downto 0);  -- wait for 5 sec before sending request
signal load_ctr                 : integer range 0 to 600 := 0;

signal bootp_hdr                : std_logic_vector(95 downto 0);

signal tc_data                  : std_logic_vector(8 downto 0);
signal vendor_values            : std_logic_vector(175 downto 0);
signal save_ctr                 : integer range 0 to 600 := 0;
signal saved_transaction_id     : std_logic_vector(31 downto 0);
signal saved_proposed_ip        : std_logic_vector(31 downto 0);
signal saved_dhcp_type          : std_logic_vector(23 downto 0);
signal saved_true_ip            : std_logic_vector(31 downto 0);
signal transaction_id           : std_logic_vector(31 downto 0);
signal client_ip_reg            : std_logic_vector(31 downto 0);
signal your_ip_reg              : std_logic_vector(31 downto 0);
signal saved_server_mac         : std_logic_vector(47 downto 0);
signal saved_server_ip          : std_logic_vector(31 downto 0);
signal state2                   : std_logic_vector(3 downto 0);
signal state3                   : std_logic_vector(3 downto 0);
signal vendor_values2           : std_logic_vector(47 downto 0);

signal discarded_ctr            : std_logic_vector(15 downto 0);

signal stat_data_temp           : std_logic_vector(31 downto 0);

attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of state, state2 : signal is true;
attribute syn_preserve of state, state2 : signal is true;

signal wait_value : std_logic_vector(31 downto 0);

signal my_ip : std_logic_vector(31 downto 0);

begin


-- ****
-- fixing the constant values for DHCP request headers
TC_DEST_MAC_OUT <= x"ffffffffffff" when (main_current_state = BOOTING or main_current_state = SENDING_DISCOVER) else saved_server_mac;
TC_DEST_IP_OUT  <= x"ffffffff" when (main_current_state = BOOTING or main_current_state = SENDING_DISCOVER) else saved_server_ip;
TC_DEST_UDP_OUT <= x"4300";
TC_SRC_MAC_OUT  <= MY_MAC_IN;
TC_SRC_IP_OUT   <= x"00000000" when (main_current_state = BOOTING or main_current_state = SENDING_DISCOVER) else saved_proposed_ip;
TC_SRC_UDP_OUT  <= x"4400";
TC_IP_PROTOCOL_OUT <= x"11"; -- udp
bootp_hdr(7 downto 0)   <= x"01";  -- message type(request)
bootp_hdr(15 downto 8)  <= x"01";  -- hardware type (eth)
bootp_hdr(23 downto 16) <= x"06";  -- hardware address length
bootp_hdr(31 downto 24) <= x"00";  -- hops
bootp_hdr(63 downto 32) <= transaction_id;  -- transaction id;
bootp_hdr(95 downto 64) <= x"0000_0000";  -- seconds elapsed/flags
transaction_id <= x"cefa" & MY_MAC_IN(47 downto 40) & MY_MAC_IN(23 downto 16);
vendor_values(31 downto 0)    <= x"63538263"; -- magic cookie (dhcp message)
vendor_values(55 downto 32)   <= x"010135" when (main_current_state = BOOTING or main_current_state = SENDING_DISCOVER) else x"030135"; -- dhcp discover, then dhcp request
vendor_values(79 downto 56)   <= x"01073d"; -- client identifier
vendor_values(127 downto 80)  <= MY_MAC_IN;  -- client identifier
vendor_values(143 downto 128) <= x"040c";  -- client name
vendor_values(175 downto 144) <= x"33425254";  -- client name (TRB3)
vendor_values2(15 downto 0)   <= x"0436";  -- server identifier
vendor_values2(47 downto 16)  <= saved_server_ip;

--*****************
-- setting of global variable for IP address
--g_MY_IP <= saved_true_ip when main_current_state = ESTABLISHED else (others => '0'); 
my_ip <= saved_true_ip when main_current_state = ESTABLISHED else (others => '0');
MY_IP_OUT <= my_ip;
--
--*****************

SAVE_SERVER_ADDR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (main_current_state = BOOTING) then
			saved_server_mac <= (others => '0');
			saved_server_ip <= (others => '0');
		elsif (main_current_state = WAITING_FOR_OFFER) and (receive_current_state = SAVE_VALUES and save_ctr = 1) then
			saved_server_mac <= PS_SRC_MAC_ADDRESS_IN;
			saved_server_ip  <= PS_SRC_IP_ADDRESS_IN;
		else
			saved_server_mac <= saved_server_mac;
			saved_server_ip  <= saved_server_ip;
		end if;
	end if;
end process SAVE_SERVER_ADDR_PROC;


-- **** MAIN MACHINE PART

MAIN_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		main_current_state <= BOOTING;
	elsif rising_edge(CLK) then
		main_current_state <= main_next_state;
	end if;
end process MAIN_MACHINE_PROC;

wait_value <= x"2000_0000" when DO_SIMULATION = 0 else x"0000_0010";

MAIN_MACHINE : process(main_current_state, DHCP_START_IN, construct_current_state, wait_ctr, receive_current_state, PS_DATA_IN, wait_value)
begin

	case (main_current_state) is
	
		when BOOTING =>
			state2 <= x"1";
			if (DHCP_START_IN = '1') then
				main_next_state <= DELAY;
			else
				main_next_state <= BOOTING;
			end if;
			
		when DELAY =>
			if (wait_ctr = wait_value) then
				main_next_state <= SENDING_DISCOVER;
			else
				main_next_state <= DELAY;
			end if;
		
		when SENDING_DISCOVER =>
			state2 <= x"2";
			if (construct_current_state = CLEANUP) then
				main_next_state <= WAITING_FOR_OFFER;
			else
				main_next_state <= SENDING_DISCOVER;
			end if;
		
		when WAITING_FOR_OFFER =>
			state2 <= x"3"; 
			if (receive_current_state = SAVE_VALUES) and (PS_DATA_IN(8) = '1') then
				main_next_state <= SENDING_REQUEST;
			elsif (wait_ctr = x"2000_0000") then
				main_next_state <= BOOTING;
			else
				main_next_state <= WAITING_FOR_OFFER;
			end if;
		
		when SENDING_REQUEST =>
			state2 <= x"4";
			if (construct_current_state = CLEANUP) then
				main_next_state <= WAITING_FOR_ACK;
			else
				main_next_state <= SENDING_REQUEST;
			end if;
		
		when WAITING_FOR_ACK =>
			state2 <= x"5";
			if (receive_current_state = SAVE_VALUES) and (PS_DATA_IN(8) = '1') then
				main_next_state <= ESTABLISHED;
			elsif (wait_ctr = x"2000_0000") then
				main_next_state <= BOOTING;
			else
				main_next_state <= WAITING_FOR_ACK;
			end if;
		
		when ESTABLISHED =>
			state2 <= x"6";
--			if (wait_ctr = x"2000_0000") then
--				main_next_state <= SENDING_DISCOVER;
--			else
				main_next_state <= ESTABLISHED;
--			end if;
	
	end case;

end process MAIN_MACHINE;

WAIT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (main_current_state = SENDING_DISCOVER or main_current_state = SENDING_REQUEST or main_current_state = BOOTING) then
			wait_ctr <= (others => '0');
		elsif (main_current_state = WAITING_FOR_ACK and receive_current_state = SAVE_VALUES and PS_DATA_IN(8) = '1') then
			wait_ctr <= (others => '0');
		elsif (main_current_state = WAITING_FOR_ACK or main_current_state = WAITING_FOR_OFFER or main_current_state = DELAY or main_current_state = ESTABLISHED) then
			wait_ctr <= wait_ctr + x"1";
		else
			wait_ctr <= wait_ctr;
		end if;
	end if;
end process WAIT_CTR_PROC;

DHCP_DONE_OUT <= '1' when main_current_state = ESTABLISHED else '0';


-- **** MESSAGES RECEIVING PART

RECEIVE_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		receive_current_state <= IDLE;
	elsif rising_edge(CLK) then
		receive_current_state <= receive_next_state;
	end if;
end process RECEIVE_MACHINE_PROC;

RECEIVE_MACHINE : process(receive_current_state, main_current_state, bootp_hdr, saved_dhcp_type, saved_transaction_id, PS_DATA_IN, PS_DEST_MAC_ADDRESS_IN, MY_MAC_IN, PS_ACTIVATE_IN, PS_WR_EN_IN, save_ctr)
begin
	case receive_current_state is
	
		when IDLE =>
			state3 <= x"1";
			if (PS_ACTIVATE_IN = '1' and PS_WR_EN_IN = '1') then
				if (main_current_state = WAITING_FOR_OFFER or main_current_state = WAITING_FOR_ACK) then  -- ready to receive dhcp frame
					if (PS_DEST_MAC_ADDRESS_IN = MY_MAC_IN) then -- check if i'm the addressee (discards broadcasts also)
						receive_next_state <= SAVE_VALUES;
					else
						receive_next_state <= DISCARD;  -- discard if the frame is not for me
					end if;
				else
					receive_next_state <= DISCARD;  -- discard if the frame arrived at wrong time
				end if;
			else
				receive_next_state <= IDLE;
			end if;
			
		when SAVE_VALUES =>
			state3 <= x"2";
			if (PS_DATA_IN(8) = '1') then
				receive_next_state <= CLEANUP;
			-- check if the same transaction
			elsif (save_ctr = 9) and (saved_transaction_id /= bootp_hdr(63 downto 32)) then
				receive_next_state <= DISCARD;
			-- if the wrong message at the wrong time
			elsif (main_current_state = WAITING_FOR_OFFER) and (save_ctr = 242) and (saved_dhcp_type /= x"020135") then
				receive_next_state <= DISCARD;
			-- if the wrong message at the wrong time
			elsif (main_current_state = WAITING_FOR_ACK) and (save_ctr = 242) and (saved_dhcp_type /= x"050135") then
				receive_next_state <= DISCARD;
			else
				receive_next_state <= SAVE_VALUES;
			end if;
		
		when DISCARD =>
			state3 <= x"3";
			if (PS_DATA_IN(8) = '1') then
				receive_next_state <= CLEANUP;
			else
				receive_next_state <= DISCARD;
			end if;
			
		when CLEANUP =>
			state3 <= x"4";
			receive_next_state <= IDLE;
	
	end case;

end process RECEIVE_MACHINE;

SAVE_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (receive_current_state = IDLE) then
			save_ctr <= 0;
		elsif (receive_current_state = SAVE_VALUES and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			save_ctr <= save_ctr + 1;
		else
			save_ctr <= save_ctr;
		end if;
	end if;
end process SAVE_CTR_PROC;

SAVE_VALUES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (main_current_state = BOOTING) then
			saved_transaction_id <= (others => '0');
			saved_proposed_ip    <= (others => '0');
			saved_true_ip        <= (others => '0');
			saved_dhcp_type      <= (others => '0');
		-- dissection of DHCP Offer message
		elsif (main_current_state = WAITING_FOR_OFFER and receive_current_state = SAVE_VALUES) then
		
			saved_true_ip <= saved_true_ip;
		
			case save_ctr is
			
				when 3 =>
					saved_transaction_id(7 downto 0) <= PS_DATA_IN(7 downto 0);
				
				when 4 =>
					saved_transaction_id(15 downto 8) <= PS_DATA_IN(7 downto 0);
			
				when 5 =>
					saved_transaction_id(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when 6 =>
					saved_transaction_id(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
					
				when 15 =>
					saved_proposed_ip(7 downto 0) <= PS_DATA_IN(7 downto 0);
				
				when 16 =>
					saved_proposed_ip(15 downto 8) <= PS_DATA_IN(7 downto 0);
					
				when 17 =>
					saved_proposed_ip(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when 18 =>
					saved_proposed_ip(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
					
				when 239 =>
					saved_dhcp_type(7 downto 0) <= PS_DATA_IN(7 downto 0);
					
				when 240 =>
					saved_dhcp_type(15 downto 8) <= PS_DATA_IN(7 downto 0);
					
				when 241 =>
					saved_dhcp_type(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when others => null;
					
			end case;
		-- dissection on DHCP Ack message
		elsif (main_current_state = WAITING_FOR_ACK and receive_current_state = SAVE_VALUES) then
		
			saved_proposed_ip <= saved_proposed_ip;
		
			case save_ctr is
			
				when 3 =>
					saved_transaction_id(7 downto 0) <= PS_DATA_IN(7 downto 0);
				
				when 4 =>
					saved_transaction_id(15 downto 8) <= PS_DATA_IN(7 downto 0);
			
				when 5 =>
					saved_transaction_id(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when 6 =>
					saved_transaction_id(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
					
				when 15 =>
					saved_true_ip(7 downto 0) <= PS_DATA_IN(7 downto 0);
				
				when 16 =>
					saved_true_ip(15 downto 8) <= PS_DATA_IN(7 downto 0);
					
				when 17 =>
					saved_true_ip(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when 18 =>
					saved_true_ip(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
					
				when 239 =>
					saved_dhcp_type(7 downto 0) <= PS_DATA_IN(7 downto 0);
					
				when 240 =>
					saved_dhcp_type(15 downto 8) <= PS_DATA_IN(7 downto 0);
					
				when 241 =>
					saved_dhcp_type(23 downto 16) <= PS_DATA_IN(7 downto 0);
					
				when others => null;
					
			end case;		
		else
			saved_transaction_id <= saved_transaction_id;
			saved_proposed_ip    <= saved_proposed_ip;
			saved_true_ip        <= saved_true_ip;
			saved_dhcp_type      <= saved_dhcp_type;		
		end if;
	end if;
end process SAVE_VALUES_PROC;


-- **** MESSAGES CONSTRUCTING PART

CONSTRUCT_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
			construct_current_state <= IDLE;
	elsif rising_edge(CLK) then
		if (main_current_state = BOOTING) then
			construct_current_state <= IDLE;
		else
			construct_current_state <= construct_next_state;
		end if;
	end if;
end process CONSTRUCT_MACHINE_PROC;

CONSTRUCT_MACHINE : process(construct_current_state, main_current_state, load_ctr, PS_SELECTED_IN)
begin
	case construct_current_state is
	
		when IDLE =>
			state <= x"1";
			if (main_current_state = SENDING_DISCOVER) or (main_current_state = SENDING_REQUEST) then
				construct_next_state <= WAIT_FOR_LOAD;
			else
				construct_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_LOAD =>
			state <= x"2";
			if (PS_SELECTED_IN = '1') then
				construct_next_state <= BOOTP_HEADERS;
			else
				construct_next_state <= WAIT_FOR_LOAD;
			end if;
		
			
		when BOOTP_HEADERS =>
			state <= x"3";
			if (load_ctr = 11) then
				construct_next_state <= CLIENT_IP;
			else
				construct_next_state <= BOOTP_HEADERS;
			end if;
			
		when CLIENT_IP =>
			state <= x"5";
			if (load_ctr = 15) then
				construct_next_state <= YOUR_IP;
			else
				construct_next_state <= CLIENT_IP;
			end if;
			
		when YOUR_IP => 
			state <= x"b";
			if (load_ctr = 19) then
				construct_next_state <= ZEROS1;
			else
				construct_next_state <= YOUR_IP;
			end if;
			
		when ZEROS1 =>
			state <= x"c";
			if (load_ctr = 27) then
				construct_next_state <= MY_MAC;
			else
				construct_next_state <= ZEROS1;
			end if;
		
		when MY_MAC =>
			state <= x"6";
			if (load_ctr = 33) then
				construct_next_state <= ZEROS2;
			else
				construct_next_state <= MY_MAC;
			end if;
		
		when ZEROS2 =>
			state <= x"7";
			if (load_ctr = 235) then
				construct_next_state <= VENDOR_VALS;
			else
				construct_next_state <= ZEROS2;
			end if;
			
		when VENDOR_VALS =>
			state <= x"8";
			if (load_ctr = 257) then
				-- for discover it's enough of values
				if (main_current_state = SENDING_DISCOVER) then
					construct_next_state <= TERMINATION;
				-- for request there is some more values needed
				else
					construct_next_state <= VENDOR_VALS2;
				end if;
			else
				construct_next_state <= VENDOR_VALS;
			end if;
			
		when VENDOR_VALS2 =>
			state <= x"d";
			if (load_ctr = 263) then
				construct_next_state <= TERMINATION;
			else
				construct_next_state <= VENDOR_VALS2;
			end if;
			
		when TERMINATION =>
			state <= x"e";
			construct_next_state <= CLEANUP;
		
		when CLEANUP =>
			state <= x"9";
			construct_next_state <= IDLE;
	
	end case;
end process CONSTRUCT_MACHINE;

LOAD_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (construct_current_state = IDLE) then
			load_ctr <= 0;
		elsif (TC_RD_EN_IN = '1') and (PS_SELECTED_IN = '1') then
			load_ctr <= load_ctr + 1;
		else
			load_ctr <= load_ctr;
		end if;
	end if;
end process LOAD_CTR_PROC;

TC_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		case (construct_current_state) is
	
			when BOOTP_HEADERS =>
				for i in 0 to 7 loop
					tc_data(i) <= bootp_hdr(load_ctr * 8 + i);
				end loop;
				tc_data(8) <= '0';
				
			when CLIENT_IP =>
				if (main_current_state = SENDING_DISCOVER) then
					tc_data(7 downto 0) <= x"00";
				elsif (main_current_state = SENDING_REQUEST) then
					for i in 0 to 7 loop
						tc_data(i) <= saved_proposed_ip((load_ctr - 12) * 8 + i);
					end loop;
				end if;
				tc_data(8) <= '0';
			
			when YOUR_IP =>
				tc_data(7 downto 0) <= x"00";
				tc_data(8) <= '0';
			
			when ZEROS1 =>
				tc_data(7 downto 0) <= x"00";
				tc_data(8) <= '0';
			
			when MY_MAC =>
				for i in 0 to 7 loop
					tc_data(i) <= MY_MAC_IN((load_ctr - 28) * 8 + i);
				end loop;
				tc_data(8) <= '0';
			
			when ZEROS2 =>
				tc_data(7 downto 0) <= x"00";
				tc_data(8) <= '0';
				
			when VENDOR_VALS =>
				for i in 0 to 7 loop
					tc_data(i) <= vendor_values((load_ctr - 236) * 8 + i);
				end loop;
				tc_data(8) <= '0';
				
			-- needed only for DHCP Request message
			when VENDOR_VALS2 =>
				for i in 0 to 7 loop
					tc_data(i) <= vendor_values2((load_ctr - 258) * 8 + i);
				end loop;
				tc_data(8) <= '0';
				
			when TERMINATION =>
				tc_data(7 downto 0) <= x"ff";
				tc_data(8)          <= '1';
			
			when others => 
				tc_data(7 downto 0) <= x"00";
				tc_data(8) <= '0';
		
		end case;

		TC_DATA_OUT  <= tc_data;
				
	end if;
end process;

PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (construct_current_state = IDLE or construct_current_state = CLEANUP) then
			PS_RESPONSE_READY_OUT <= '0';
		else
			PS_RESPONSE_READY_OUT <= '1';
		end if;
		
		if (construct_current_state = IDLE) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
	end if;	
end process PS_RESPONSE_SYNC;

-- fixed sizes for discover and request messages
TC_FRAME_SIZE_OUT   <= x"0103" when (main_current_state = SENDING_DISCOVER) else x"0109";

TC_FRAME_TYPE_OUT   <= x"0008";  -- frame type: ip

TC_IDENT_OUT        <= x"1" & sent_frames(11 downto 0);


-- **** statistics
--REC_FRAMES_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			rec_frames <= (others => '0');
--		elsif (receive_current_state = SAVE_VALUES and PS_DATA_IN(8) = '1') then
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
		elsif (construct_current_state = CLEANUP) then
			sent_frames <= sent_frames + x"1";
		end if;
	end if;
end process SENT_FRAMES_PROC;
--
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
--STATS_MACHINE : process(stats_current_state, STAT_DATA_ACK_IN, PS_DATA_IN, construct_current_state, receive_current_state)
--begin
--
--	case (stats_current_state) is
--	
--		when IDLE =>
--			if (receive_current_state = SAVE_VALUES and PS_DATA_IN(8) = '1') or (construct_current_state = CLEANUP) or (receive_current_state = DISCARD and PS_DATA_IN(8) = '1') then
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
--				stats_next_state <= LOAD_DISCARDED;
--			else
--				stats_next_state <= LOAD_RECEIVED;
--			end if;
--			
--		when LOAD_DISCARDED =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= CLEANUP;
--			else
--				stats_next_state <= LOAD_DISCARDED;
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
--				stat_data_temp <= x"0101" & sent_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE, 8));
--			
--			when LOAD_RECEIVED =>
--				stat_data_temp <= x"0102" & rec_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 1, 8));
--			
--			when LOAD_DISCARDED =>
--				stat_data_temp <= x"0103" & discarded_ctr;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 2, 8));
--			
--			when others =>
--				stat_data_temp <= (others => '0');
--				STAT_ADDR_OUT  <= (others => '0');
--		
--		end case;
--	end if;
--	
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
-- ****


-- **** debug
--DEBUG_OUT(3 downto 0)   <= state;
--DEBUG_OUT(7 downto 4)   <= state2;
--DEBUG_OUT(11 downto 8)  <= state3;
--DEBUG_OUT(15 downto 12) <= (others => '0');
--DEBUG_OUT(31 downto 16) <= discarded_ctr;
--
--DISCARDED_CTR_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			discarded_ctr <= (others => '0');
--		elsif (receive_current_state = DISCARD and PS_DATA_IN(8) = '1') then
--			discarded_ctr <= discarded_ctr + x"1";
--		end if;
--	end if;
--end process DISCARDED_CTR_PROC;
-- ****

end trb_net16_gbe_response_constructor_DHCP;


