LIBRARY ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity trb_net16_gbe_event_constr is
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	MULT_EVT_ENABLE_IN      : in    std_logic;  -- gk 06.10.10
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(7 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_START_OF_SUB_IN      : in    std_logic;
	PC_END_OF_SUB_IN        : in    std_logic;  -- gk 07.10.10
	PC_END_OF_DATA_IN       : in    std_logic;
	PC_TRANSMIT_ON_OUT	: out	std_logic;
	-- queue and subevent layer headers
	PC_SUB_SIZE_IN          : in    std_logic_vector(31 downto 0); -- store and swap
	PC_PADDING_IN           : in    std_logic;  -- gk 29.03.10
	PC_DECODING_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_EVENT_ID_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_TRIG_NR_IN           : in    std_logic_vector(31 downto 0); -- store and swap!
	PC_QUEUE_DEC_IN         : in    std_logic_vector(31 downto 0); -- swap
	PC_MAX_FRAME_SIZE_IN    : in	std_logic_vector(15 downto 0); -- DO NOT SWAP
	PC_DELAY_IN             : in	std_logic_vector(31 downto 0);  -- gk 28.04.10
	-- FrameConstructor ports
	TC_WR_EN_OUT            : out   std_logic;
	TC_DATA_OUT             : out   std_logic_vector(7 downto 0);
	TC_H_READY_IN           : in    std_logic;
	TC_READY_IN             : in    std_logic;
	TC_IP_SIZE_OUT          : out   std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT         : out   std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT     : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	TC_EOD_OUT              : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end entity trb_net16_gbe_event_constr;

architecture RTL of trb_net16_gbe_event_constr is

type saveStates is (IDLE, SAVE_DATA, CLEANUP);
signal save_current_state, save_next_state : saveStates;

type loadStates is (IDLE, WAIT_FOR_FC, PUT_Q_LEN, PUT_Q_DEC, LOAD_DATA, CLEANUP);
signal load_current_state, load_next_state : loadStates;

signal df_eod, df_wr_en, df_rd_en, df_empty, df_full, load_eod : std_logic;
signal df_q : std_logic_vector(7 downto 0);
	
begin

--*******
-- SAVING PART
--*******

SAVE_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			save_current_state <= IDLE;
		else
			save_current_state <= save_next_state;
		end if;
	end if;
end process SAVE_MACHINE_PROC;

SAVE_MACHINE : process(save_current_state)
begin
	case (save_current_state) is

		when IDLE =>
			if (PC_START_OF_SUB_IN = '1') then
				save_next_state <= SAVE_DATA;
			else
				save_next_state <= IDLE;
			end if;
		
		when SAVE_DATA =>
			if (PC_END_OF_DATA_IN = '1') then
				save_next_state <= CLOSE;
			else
				save_next_state <= SAVE_DATA;
			end if;			
		
		when CLOSE =>
			save_next_state <= IDLE;
		
		when others => save_next_state <= IDLE;

	end case;
end process SAVE_MACHINE;

DF_EOD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (PC_END_OF_DATA_IN = '1') then
			df_eod <= '1';
		else
			df_eod <= '0';
		end if;
	end if; 
end process DF_EOD_PROC;

DF_WR_EN_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (save_current_state = SAVE_DATA and PC_WR_EN_IN = '1') then
			df_wr_en <= '1';
		else
			df_wr_en <= '0';
		end if;
	end if;
end process DF_WR_EN_PROC;


DATA_FIFO : fifo_64kx9
port map(
	Data(7 downto 0) =>  PC_DATA_IN,
	Data(8)          =>  df_eod,
	WrClock          =>  CLK,
	RdClock          =>  CLK,
	WrEn             =>  df_wr_en,
	RdEn             =>  df_rd_en,
	Reset            =>  RESET,
	RPReset          =>  RESET,
	Q(7 downto 0)    =>  df_q,
	Q(8)             =>  load_eod,
	Empty            =>  df_empty,
	Full             =>  df_full
);

--*******
-- LOADING PART
--*******

LOAD_MACHINE_PROC : process(CLK) is
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			load_current_state <= IDLE;
		else
			load_current_state <= load_next_state;
		end if;
	end if;
end process LOAD_MACHINE_PROC;

LOAD_MACHINE : process(load_current_state)
begin
	case (load_current_state) is
	
		when IDLE =>
		
		when CLEANUP =>
		
		when others => load_next_state <= IDLE;
		
	end case;
end process LOAD_MACHINE;


--*****
-- outputs

PC_TRANSMIT_ON_OUT <= '0';
PC_READY_OUT <= '1' when save_current_state = IDLE else '0';

DEBUG_OUT <= (others => '0)';

end architecture RTL;
