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
-- doing shit right now

entity trb_net16_gbe_transmit_control2 is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	TC_DATAREADY_IN        : in 	std_logic;
	TC_RD_EN_OUT		        : out	std_logic;
	TC_DATA_IN		        : in	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	TC_SIZE_LEFT_IN        : in	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_IN	    : in	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);

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

-- debug
	DEBUG_OUT		     : out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_transmit_control2;


architecture trb_net16_gbe_transmit_control2 of trb_net16_gbe_transmit_control2 is

type transmit_states is (IDLE, WAIT_FOR_H, TRANSMIT, WAIT_FOR_TRANS);
signal transmit_current_state, transmit_next_state : transmit_states;

signal tc_rd, tc_rd_q, tc_rd_qq : std_logic;
signal local_end : std_logic_vector(15 downto 0);

begin

TRANSMIT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			transmit_current_state <= IDLE;
		else
			transmit_current_state <= transmit_next_state;
		end if;
	end if;
end process TRANSMIT_MACHINE_PROC;

TRANSMIT_MACHINE : process(FC_H_READY_IN, TC_DATAREADY_IN, FC_READY_IN, local_end)
begin
	case transmit_current_state is
	
		when IDLE =>
			if (TC_DATAREADY_IN = '1') then
				transmit_next_state <= WAIT_FOR_H;
			else
				transmit_next_state <= IDLE;
			end if;
		
		when WAIT_FOR_H =>
			if (FC_H_READY_IN = '1') then
				transmit_next_state <= TRANSMIT;
			else
				transmit_next_state <= WAIT_FOR_H;
			end if;
		
		when TRANSMIT =>
			if (local_end = x"0000") then
				transmit_next_state <= WAIT_FOR_TRANS;
			else
				transmit_next_state <= TRANSMIT;
			end if;
			
		when WAIT_FOR_TRANS =>
			if (FC_READY_IN = '1') then
				transmit_next_state <= IDLE;
			else
				transmit_next_state <= WAIT_FOR_TRANS;
			end if;
		
--		when DIVIDE =>
--			transmit_next_state <= IDLE;
		
--		when CLEANUP =>
--			transmit_next_state <= IDLE;
--			
--		when others =>
--			transmit_next_state <= IDLE;
	
	end case;
end process TRANSMIT_MACHINE;

tc_rd               <= '1' when transmit_current_state = TRANSMIT else '0';
TC_RD_EN_OUT        <= tc_rd;

process(CLK)
begin
	if rising_edge(CLK) then
		tc_rd_q <= tc_rd;
		tc_rd_qq <= tc_rd_q;
		FC_WR_EN_OUT <= tc_rd_q;
	end if;
end process;

process(CLK)
begin
	if rising_edge(CLK) then
		if (transmit_current_state = WAIT_FOR_H) then
			local_end <= TC_FRAME_SIZE_IN + x"1";
		elsif (transmit_current_state = TRANSMIT) then
			local_end <= local_end - x"1";
		else
			local_end <= local_end;
		end if; 
	end if;
end process;

FC_DATA_OUT         <= TC_DATA_IN;
FC_SOD_OUT			<= '1' when transmit_current_state = WAIT_FOR_H else '0'; 
FC_EOD_OUT			<= '1' when local_end = x"0000" else '0';
FC_IP_SIZE_OUT		<= TC_FRAME_SIZE_IN;
FC_UDP_SIZE_OUT		<= TC_FRAME_SIZE_IN;
--FC_WR_EN_OUT		<= '1' when transmit_current_state = TRANSMIT else '0';
TC_TRANSMISSION_DONE_OUT <= '1' when transmit_current_state = WAIT_FOR_TRANS and FC_READY_IN = '1' else '0';

FC_FRAME_TYPE_OUT    <= TC_FRAME_TYPE_IN;
FC_IP_PROTOCOL_OUT   <= TC_IP_PROTOCOL_IN; 
FC_FLAGS_OFFSET_OUT  <= TC_FLAGS_OFFSET_IN;
DEST_MAC_ADDRESS_OUT <= TC_DEST_MAC_IN;
DEST_IP_ADDRESS_OUT  <= TC_DEST_IP_IN;
DEST_UDP_PORT_OUT    <= TC_DEST_UDP_IN;
SRC_MAC_ADDRESS_OUT  <= TC_SRC_MAC_IN;
SRC_IP_ADDRESS_OUT   <= TC_SRC_IP_IN;
SRC_UDP_PORT_OUT     <= TC_SRC_UDP_IN;
FC_IDENT_OUT         <= TC_IDENT_IN;

end trb_net16_gbe_transmit_control2;


