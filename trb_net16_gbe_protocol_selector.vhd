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
-- multiplexes between different protocols and manages the responses
-- 
-- 


entity trb_net16_gbe_protocol_selector is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	PS_DATA_IN		: in	std_logic_vector(8 downto 0); 
	PS_WR_EN_IN		: in	std_logic;
	PS_PROTO_SELECT_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_BUSY_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	PS_RESPONSE_READY_OUT	: out	std_logic;
	
	
-- singals to/from transmi controller with constructed response
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_BUSY_IN		: in	std_logic;
	
	-- counters from response constructors
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_protocol_selector;


architecture trb_net16_gbe_protocol_selector of trb_net16_gbe_protocol_selector is

signal rd_en                    : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal resp_ready               : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal tc_data                  : std_logic_vector(c_MAX_PROTOCOLS * 9 - 1 downto 0);
signal tc_size                  : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal busy                     : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal selected                 : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

begin

-- protocol Nr. 1
Forward : trb_net16_gbe_response_constructor_Forward
port map (
	CLK			=> CLK,
	RESET			=> RESET,
	
-- INTERFACE	
	PS_DATA_IN		=> PS_DATA_IN,
	PS_WR_EN_IN		=> PS_WR_EN_IN,
	PS_ACTIVATE_IN		=> PS_PROTO_SELECT_IN(0),
	PS_RESPONSE_READY_OUT	=> resp_ready(0),
	PS_BUSY_OUT		=> busy(0),
	PS_SELECTED_IN		=> selected(0),
	
	TC_RD_EN_IN		=> TC_RD_EN_IN,
	TC_DATA_OUT		=> tc_data(1 * 9 - 1 downto 0 * 9),
	TC_FRAME_SIZE_OUT	=> tc_size(1 * 16 - 1 downto 0 * 16),
	TC_BUSY_IN		=> TC_BUSY_IN,
	
	RECEIVED_FRAMES_OUT	=> RECEIVED_FRAMES_OUT(1 * 15 - 1 downto 0 * 9),
	SENT_FRAMES_OUT		=> SENT_FRAMES_OUT(1 * 15 - 1 downto 0 * 9),
-- END OF INTERFACE

-- debug
	DEBUG_OUT		=> open
);

-- protocol Nr. 2
ARP : trb_net16_gbe_response_constructor_ARP
port map (
	CLK			=> CLK,
	RESET			=> RESET,
	
-- INTERFACE	
	PS_DATA_IN		=> PS_DATA_IN,
	PS_WR_EN_IN		=> PS_WR_EN_IN,
	PS_ACTIVATE_IN		=> PS_PROTO_SELECT_IN(1),
	PS_RESPONSE_READY_OUT	=> resp_ready(1),
	PS_BUSY_OUT		=> busy(1),
	PS_SELECTED_IN		=> selected(1),
	
	TC_RD_EN_IN		=> TC_RD_EN_IN,
	TC_DATA_OUT		=> tc_data(2 * 9 - 1 downto 1 * 9),
	TC_FRAME_SIZE_OUT	=> tc_size(2 * 16 - 1 downto 1 * 16),
	TC_BUSY_IN		=> TC_BUSY_IN,
	
	RECEIVED_FRAMES_OUT	=> RECEIVED_FRAMES_OUT(2 * 15 - 1 downto 1 * 9),
	SENT_FRAMES_OUT		=> SENT_FRAMES_OUT(2 * 15 - 1 downto 1 * 9),
-- END OF INTERFACE

-- debug
	DEBUG_OUT		=> open
);


--***************
-- DO NOT TOUCH, selection logic
PS_BUSY_OUT <= busy;

SELECTOR_PROC : process(CLK)
	variable found : boolean := false;
begin
	if rising_edge(CLK) then
	
		selected              <= (others => '0');
	
		if (RESET = '1') then
			TC_DATA_OUT           <= (others => '0');
			TC_FRAME_SIZE_OUT     <= (others => '0');
			PS_RESPONSE_READY_OUT <= '0';
			selected              <= (others => '0');
			found := false;
		else
			if (or_all(resp_ready) = '1') then
				for i in 0 to c_MAX_PROTOCOLS - 1 loop
					if (resp_ready(i) = '1') then
						TC_DATA_OUT           <= tc_data((i + 1) * 9 - 1 downto i * 9);
						TC_FRAME_SIZE_OUT     <= tc_size ((i + 1) * 16 - 1 downto i * 16);
						PS_RESPONSE_READY_OUT <= '1';
						selected(i)           <= '1';
						found := true;
					elsif (i = c_MAX_PROTOCOLS) and (resp_ready(i) = '0') and (found = false) then
						found := false;
						PS_RESPONSE_READY_OUT <= '0';
					end if;
				end loop;
			else
				TC_DATA_OUT           <= (others => '0');
				TC_FRAME_SIZE_OUT     <= (others => '0');
				PS_RESPONSE_READY_OUT <= '0';
				found := false;
			end if;
		end if;
	end if;
end process SELECTOR_PROC;
-- ************

end trb_net16_gbe_protocol_selector;


