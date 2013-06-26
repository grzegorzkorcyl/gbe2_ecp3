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

entity trb_net16_gbe_transmit_control is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	MC_TRANSMIT_CTRL_IN	 : in	std_logic;
	MC_DATA_IN		     : in	std_logic_vector(8 downto 0);
	MC_WR_EN_IN   		 : in	std_logic;
	MC_DATA_NOT_VALID_IN : in   std_logic;
	MC_FRAME_SIZE_IN	 : in	std_logic_vector(15 downto 0);
	MC_FRAME_TYPE_IN	 : in	std_logic_vector(15 downto 0);
	
	MC_DEST_MAC_IN		 : in	std_logic_vector(47 downto 0);
	MC_DEST_IP_IN		 : in	std_logic_vector(31 downto 0);
	MC_DEST_UDP_IN		 : in	std_logic_vector(15 downto 0);
	MC_SRC_MAC_IN		 : in	std_logic_vector(47 downto 0);
	MC_SRC_IP_IN		 : in	std_logic_vector(31 downto 0);
	MC_SRC_UDP_IN		 : in	std_logic_vector(15 downto 0);
	
	MC_IP_PROTOCOL_IN	 : in	std_logic_vector(7 downto 0);
	MC_IDENT_IN          : in   std_logic_vector(15 downto 0);
	
	MC_IP_SIZE_IN		 : in	std_logic_vector(15 downto 0);
	MC_UDP_SIZE_IN		 : in	std_logic_vector(15 downto 0);
	MC_FLAGS_OFFSET_IN	 : in	std_logic_vector(15 downto 0);
	
	MC_FC_H_READY_OUT    : out std_logic;
	MC_FC_READY_OUT      : out std_logic;
	MC_FC_WR_EN_IN       : in std_logic;
	
	MC_BUSY_OUT	         : out	std_logic;
	MC_TRANSMIT_DONE_OUT : out	std_logic;

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
end trb_net16_gbe_transmit_control;


architecture trb_net16_gbe_transmit_control of trb_net16_gbe_transmit_control is

begin

SYNC_PROC : process(CLK)
begin
  if rising_edge(CLK) then
  
  	MC_FC_H_READY_OUT <= FC_H_READY_IN;
	MC_FC_READY_OUT   <= FC_READY_IN;

	FC_FRAME_TYPE_OUT <= MC_FRAME_TYPE_IN;

	FC_DATA_OUT         <= MC_DATA_IN(7 downto 0);
	FC_IP_PROTOCOL_OUT  <= MC_IP_PROTOCOL_IN; 

	if (MC_TRANSMIT_CTRL_IN = '1') then
	  FC_SOD_OUT        <= '1';
	else
	  FC_SOD_OUT        <= '0';
	end if;

	if (MC_DATA_IN(8) = '1') then
	  FC_EOD_OUT        <= '1';
	else
	  FC_EOD_OUT        <= '0';
	end if;

	if (MC_FRAME_TYPE_IN = x"0008") then
		FC_IP_SIZE_OUT  <= MC_IP_SIZE_IN;
		FC_UDP_SIZE_OUT <= MC_UDP_SIZE_IN;		
	else
		FC_IP_SIZE_OUT <= MC_FRAME_SIZE_IN;
		FC_UDP_SIZE_OUT <= MC_FRAME_SIZE_IN;
	end if;
	
	
  	if (MC_DATA_NOT_VALID_IN = '0' and MC_WR_EN_IN = '1') then
  		FC_WR_EN_OUT <= '1';
  	else
  		FC_WR_EN_OUT <= '0';
  	end if;
	
	FC_FLAGS_OFFSET_OUT <= MC_FLAGS_OFFSET_IN;

	DEST_MAC_ADDRESS_OUT <= MC_DEST_MAC_IN;
	DEST_IP_ADDRESS_OUT  <= MC_DEST_IP_IN;
	DEST_UDP_PORT_OUT    <= MC_DEST_UDP_IN;
	SRC_MAC_ADDRESS_OUT  <= MC_SRC_MAC_IN;
	SRC_IP_ADDRESS_OUT   <= MC_SRC_IP_IN;
	SRC_UDP_PORT_OUT     <= MC_SRC_UDP_IN;
	
	FC_IDENT_OUT         <= MC_IDENT_IN;
  end if;
end process SYNC_PROC;

end trb_net16_gbe_transmit_control;


