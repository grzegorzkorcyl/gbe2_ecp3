----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:10:12 11/18/2011 
-- Design Name: 
-- Module Name:    trb_net16_gbe_response_constructor_Stat - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
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

entity trb_net16_gbe_response_constructor_Stat is
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
	
	TC_IP_SIZE_OUT      : out	std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT     : out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT : out	std_logic_vector(15 downto 0);
	
	TC_BUSY_IN		: in	std_logic;
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	STAT_DATA_IN : in std_logic_vector((c_MAX_PROTOCOLS + 1) * 32 - 1 downto 0);
	STAT_ADDR_IN : in std_logic_vector((c_MAX_PROTOCOLS + 1) * 8 - 1 downto 0);
	STAT_DATA_RDY_IN  : in std_logic_vector((c_MAX_PROTOCOLS + 1) - 1 downto 0);
	STAT_DATA_ACK_OUT : out std_logic_vector((c_MAX_PROTOCOLS + 1) - 1 downto 0);

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_Stat;

architecture Behavioral of trb_net16_gbe_response_constructor_Stat is

attribute syn_encoding	: string;

type construct_states is (IDLE, WAIT_FOR_LOAD, LOAD_DATA, TERMINATION, CLEANUP);
signal construct_current_state, construct_next_state : construct_states;
attribute syn_encoding of construct_current_state: signal is "safe,gray";

signal timer      : unsigned(28 downto 0);
signal state      : std_logic_vector(3 downto 0);
signal load_ctr   : integer range 0 to 255;
signal tc_data    : std_logic_vector(8 downto 0);
signal tc_data_t  : std_logic_vector(7 downto 0);
signal timer_lock : std_logic;

signal mem_din  : std_logic_vector(31 downto 0);
signal mem_dout, mem_wr_addr : std_logic_vector(7 downto 0);
signal mem_rd_addr : std_logic_vector(9 downto 0);
signal mem_wr_en : std_logic;
signal selected : std_logic_vector(c_MAX_PROTOCOLS downto 0);

signal pause    : integer range 0 to 28;

signal stat_data_temp           : std_logic_vector(31 downto 0);

begin
--pause <= 10 when g_SIMULATE = 1 else 28;
pause <= 28;


mem : statts_mem
  PORT map(
    WrClock   => CLK,
    Reset   => RESET,
    WrClockEn    => '1',
    WE => mem_wr_en,
    WrAddress => mem_wr_addr,
    Data   => mem_din,
    RdClock   => CLK,
    RdAddress  => mem_rd_addr,
    Q  => mem_dout,
    RdClockEn => '1'
  );

mem_wr_en <= or_all(selected);
STAT_DATA_ACK_OUT <= selected;

SELECTOR_PROC : process(CLK)
	variable found : boolean := false;
begin
	if rising_edge(CLK) then
	
		selected              <= (others => '0');
	
		if (RESET = '1') then
			mem_wr_addr <= (others => '0');
			mem_din     <= (others => '0');
			found := false;
		else
			if (or_all(STAT_DATA_RDY_IN) = '1') then
				for i in 0 to c_MAX_PROTOCOLS loop
					if (STAT_DATA_RDY_IN(i) = '1') then
						mem_wr_addr <= STAT_ADDR_IN((i + 1) * 8 - 1 downto i * 8);
						mem_din     <= STAT_DATA_IN((i + 1) * 32 - 1 downto i * 32);
						selected(i)           <= '1';
						found := true;
					elsif (i = c_MAX_PROTOCOLS) and (STAT_DATA_RDY_IN(i) = '0') and (found = false) then
						found := false;
					end if;
				end loop;
			else
				mem_wr_addr <= (others => '0');
				mem_din     <= (others => '0');
				found := false;
			end if;
		end if;
		
	end if;
end process SELECTOR_PROC;





TIMER_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			timer  <= (others => '0');
			timer_lock <= '0';
		elsif (timer(pause) = '0') then
			timer_lock <= '0';
			timer <= timer + 1;
		elsif (timer(pause) = '1') then
			timer_lock <= '1';
			timer <= timer + 1;
		else
			timer <= timer + 1;
		end if;
	end if;
end process TIMER_PROC;

-- **** MESSAGES CONSTRUCTING PART

CONSTRUCT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			construct_current_state <= IDLE;
		else
			construct_current_state <= construct_next_state;
		end if;
	end if;
end process CONSTRUCT_MACHINE_PROC;

CONSTRUCT_MACHINE : process(construct_current_state, timer_lock, TC_BUSY_IN, PS_SELECTED_IN, timer, load_ctr, pause)
begin
	case construct_current_state is
	
		when IDLE =>
			state <= x"1";
			if (timer(pause) = '1' and timer_lock = '0') then
				construct_next_state <= WAIT_FOR_LOAD;
			else
				construct_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_LOAD =>
			state <= x"4";
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				construct_next_state <= LOAD_DATA;
			else
				construct_next_state <= WAIT_FOR_LOAD;
			end if;
			
		when LOAD_DATA =>
			state <= x"2";
			if (load_ctr = 255) then
				construct_next_state <= TERMINATION;
			else
				construct_next_state <= LOAD_DATA;
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
		if (RESET = '1') or (construct_current_state = IDLE) then
			load_ctr <= 1;
		elsif (TC_RD_EN_IN = '1') and (PS_SELECTED_IN = '1') then
			load_ctr <= load_ctr + 1;
		end if;
	end if;
end process LOAD_CTR_PROC;

mem_rd_addr <= std_logic_vector(to_unsigned(load_ctr, 10));

TC_DATA_PROC : process(construct_current_state, tc_data_t)
begin

	tc_data(8) <= '0';

	case (construct_current_state) is
			
		when LOAD_DATA =>
			for i in 0 to 7 loop
				tc_data(i) <= mem_dout(i);
			end loop;
			
		when TERMINATION =>
			tc_data(7 downto 0) <= x"ff";
			tc_data(8)          <= '1';
		
		when others => tc_data(7 downto 0) <= x"00";
	
	end case;
	
end process;

TC_DATA_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_DATA_OUT <= tc_data;
	end if;
end process TC_DATA_SYNC;


--PS_BUSY_OUT <= '0' when (construct_current_state = IDLE) else '1';
--PS_RESPONSE_READY_OUT <= '0' when (construct_current_state = IDLE) else '1';

PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (construct_current_state = IDLE) then
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

TC_FRAME_SIZE_OUT <= x"0100";
TC_FRAME_TYPE_OUT <= x"0008";  -- frame type: ip 

TC_DEST_MAC_OUT <= x"ffffffffffff";
TC_DEST_IP_OUT  <= x"ff" & g_MY_IP(23 downto 0); --x"ff00a8c0";
TC_DEST_UDP_OUT <= x"51c3";
TC_SRC_MAC_OUT  <= g_MY_MAC;
TC_SRC_IP_OUT   <= g_MY_IP;
TC_SRC_UDP_OUT  <= x"51c3";
TC_IP_PROTOCOL_OUT <= x"11"; -- udp

TC_IP_SIZE_OUT    <= x"0100";
TC_UDP_SIZE_OUT   <= x"0100";
TC_FLAGS_OFFSET_OUT <= (others => '0');

-- **** debug
DEBUG_OUT(3 downto 0)   <= state;
DEBUG_OUT(4)            <= '0';
DEBUG_OUT(7 downto 5)   <= "000";
DEBUG_OUT(8)            <= '0';
DEBUG_OUT(11 downto 9)  <= "000";
DEBUG_OUT(31 downto 12) <= (others => '0');
-- ****

end Behavioral;

