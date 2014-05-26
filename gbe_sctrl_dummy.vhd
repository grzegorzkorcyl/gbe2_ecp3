LIBRARY ieee;

use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity gbe_sctrl_dummy is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		FIXED_DELAY : integer range 0 to 65535 := 4096	
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		
		RC_RD_EN_IN		: in	std_logic;
		RC_Q_OUT		: out	std_logic_vector(8 downto 0);
		RC_FRAME_WAITING_OUT	: out	std_logic;
		RC_LOADING_DONE_IN	: in	std_logic;
		RC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
		RC_FRAME_PROTO_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
		
		RC_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
		RC_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
		RC_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
		RC_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
		RC_SRC_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
		RC_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
		
		GSC_REPLY_DATAREADY_OUT   : out std_logic;
		GSC_REPLY_DATA_OUT        : out std_logic_vector(15 downto 0);
		GSC_REPLY_PACKET_NUM_OUT  : out std_logic_vector(2 downto 0);
		GSC_REPLY_READ_IN       : in std_logic;
		GSC_BUSY_OUT              : out std_logic
	);
end entity gbe_sctrl_dummy;

architecture RTL of gbe_sctrl_dummy is
	
	type states is (IDLE, TIMEOUT, GENERATE_REQUEST, WAIT_A_BIT, GENERATE_REPLY, CLEANUP);
	signal current_state, next_state : states;
	
	signal data : std_logic_vector(251 downto 0);
	signal ptr : integer range 0 to 255;
	signal timeout_ctr : integer range 0 to 65535;
	signal wait_ctr,  reply_delay, reply_ctr, reply_size : integer range 0 to 65535;
	
begin
	
	reply_delay <= 100;
	
	reply_size <= 100;
	
	RC_FRAME_PROTO_OUT <= "00100";
	
	data <= x"abcd0031ffffffffffff00080030005000000000000000330000000000000008";
	
	RC_FRAME_WAITING_OUT <= '1' when current_state = GENERATE_REQUEST else '0';

	RC_Q_OUT <= data(ptr * 8 - 1 downto (ptr - 1 ) * 8);

	GSC_REPLY_DATA_OUT <= std_logic_vector(to_unsigned(reply_ctr, 16));
	
	GSC_REPLY_DATAREADY_OUT <= '1' when current_state = GENERATE_REPLY else '0';
	
	GSC_BUSY_OUT <= '1' when current_state = GENERATE_REPLY else '0';

	process(RST, CLK)
	begin
		if RST = '1' then
			current_state <= IDLE;
		elsif rising_edge(CLK) then
			current_state <= next_state;
		end if;
	end process;
	
	process(current_state, timeout_ctr, ptr, wait_ctr, reply_delay, reply_ctr, reply_size)
	begin
		case current_state is 
			
			when IDLE =>
				next_state <= TIMEOUT;
				
			when TIMEOUT =>
				if (timeout_ctr = FIXED_DELAY) then
					next_state <= GENERATE_REQUEST;
				else
					next_state <= TIMEOUT;
				end if;
			
			when GENERATE_REQUEST =>
				if (ptr = 0) then
					next_state <= WAIT_A_BIT;
				else
					next_state <= GENERATE_REQUEST;
				end if;
			
			when WAIT_A_BIT =>
				if (wait_ctr = reply_delay) then
					next_state <= GENERATE_REPLY;
				else
					next_state <= WAIT_A_BIT;
				end if;
			
			when GENERATE_REPLY =>
				if (reply_ctr = reply_size) then
					next_state <= CLEANUP;
				else
					next_state <= GENERATE_REPLY;
				end if;
			
			when CLEANUP =>
				next_state <= IDLE;
				
		end case;
	end process;
			
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				ptr <= 31;
			elsif (current_state = GENERATE_REQUEST and RC_RD_EN_IN = '1') then
				ptr <= ptr - 1;
			else
				ptr <= ptr;
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				wait_ctr <= 0;
			elsif (current_state = WAIT_A_BIT) then
				wait_ctr <= wait_ctr + 1;
			else
				wait_ctr <= wait_ctr;
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				reply_ctr <= 0;
			elsif (current_state = GENERATE_REPLY) then
				reply_ctr <= reply_ctr + 1;
			else
				reply_ctr <= reply_ctr;
			end if;
		end if;
	end process;
				
end architecture RTL;
