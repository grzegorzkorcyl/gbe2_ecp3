LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_protocols.all;
use work.trb_net_gbe_components.all;

entity test_data_source is
port (
	CLK			            : in	std_logic;
	RESET			        : in	std_logic;

	TC_DATAREADY_OUT        : out 	std_logic;
	TC_RD_EN_IN		        : in	std_logic;
	TC_DATA_OUT		        : out	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_OUT	    : out	std_logic_vector(15 downto 0);
	TC_SIZE_LEFT_OUT        : out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	    : out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	    : out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		    : out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		    : out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		    : out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		    : out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		    : out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		    : out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	    : out	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_IN : in	std_logic;
	TC_IDENT_OUT            : out	std_logic_vector(15 downto 0)
);
end test_data_source;


architecture test_data_source of test_data_source is

signal df_data, df_q : std_logic_vector(7 downto 0);
signal df_eod, df_wr_en, df_rd_en, load_eod, df_empty, df_full, df_reset : std_logic;

type states is (IDLE, GENERATE_DATA, TRANSMIT_DATA, WAIT_A_SEC);
signal current_state, next_state : states; 

signal gen_data_ctr, full_size, size_left : std_logic_vector(15 downto 0);
signal wait_ctr : std_logic_vector(31 downto 0);

begin

DATA_FIFO : fifo_4096x9
port map(
	Data(7 downto 0) =>  df_data,
	Data(8)          =>  df_eod,
	WrClock          =>  CLK,
	RdClock          =>  CLK,
	WrEn             =>  df_wr_en,
	RdEn             =>  df_rd_en,
	Reset            =>  df_reset,
	RPReset          =>  df_reset,
	Q(7 downto 0)    =>  df_q,
	Q(8)             =>  load_eod,
	Empty            =>  df_empty,
	Full             =>  df_full
);

df_reset <= '1' when RESET = '1' or current_state = IDLE else '0';
df_wr_en <= '1' when current_state = GENERATE_DATA else '0';
df_data  <= gen_data_ctr(7 downto 0);
df_eod <= '0';

STATE_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			current_state <= IDLE;
		else
			current_state <= next_state;
		end if;
	end if;
end process STATE_MACHINE_PROC;

STATE_MACHINE : process(gen_data_ctr, TC_TRANSMISSION_DONE_IN, wait_ctr)
begin
	case current_state is
		when IDLE =>
			next_state <= WAIT_A_SEC;
			
		when WAIT_A_SEC =>
			if (wait_ctr = x"10") then
				next_state <= GENERATE_DATA;
			else
				next_state <= WAIT_A_SEC;
			end if;

		when GENERATE_DATA =>
			if (gen_data_ctr = x"1000") then
				next_state <= TRANSMIT_DATA;
			else
				next_state <= GENERATE_DATA;
			end if;
			
		when TRANSMIT_DATA =>
			if (TC_TRANSMISSION_DONE_IN = '1') then
				next_state <= IDLE;
			else
				next_state <= TRANSMIT_DATA;
			end if;
			
	end case;
end process STATE_MACHINE;

process(CLK)
begin
	if rising_edge(CLK) then
		if (current_state = IDLE) then
			wait_ctr <= (others => '0');
		elsif (current_state = WAIT_A_SEC) then
			wait_ctr <= wait_ctr + x"1";
		else
			wait_ctr <= wait_ctr;
		end if;
	end if;
end process;

process(CLK)
begin
	if rising_edge(CLK) then
		if (current_state = IDLE) then
			gen_data_ctr <= (others => '0');
		elsif (current_state = GENERATE_DATA) then
			gen_data_ctr <= gen_data_ctr + x"1";
		else
			gen_data_ctr <= gen_data_ctr;
		end if;
	end if;
end process;

process(CLK)
begin
	if rising_edge(CLK) then
		if (current_state = GENERATE_DATA and gen_data_ctr = x"1000") then
			size_left <= full_size;
		elsif (current_state = TRANSMIT_DATA and TC_RD_EN_IN = '1') then
			size_left <= size_left - x"1";
		else
			size_left <= size_left;		
		end if;
	end if;
end process;

process(CLK)
begin
	if rising_edge(CLK) then
		df_rd_en    <= TC_RD_EN_IN;
		TC_DATA_OUT <= df_q;
	end if; 
end process;

full_size <= x"00f0";

TC_DATAREADY_OUT <= '1' when (current_state = GENERATE_DATA and gen_data_ctr = x"1000") else '0';

TC_FRAME_SIZE_OUT	<= full_size;
TC_SIZE_LEFT_OUT    <= size_left;
TC_FRAME_TYPE_OUT	<= x"0008";
TC_IP_PROTOCOL_OUT	<= x"11";	
TC_DEST_MAC_OUT		<= x"000022334455";
TC_DEST_IP_OUT	    <= x"c0a80003";
TC_DEST_UDP_OUT		<= x"c305";
TC_SRC_MAC_OUT		<= x"000022334456";
TC_SRC_IP_OUT		<= x"c0a800a1";
TC_SRC_UDP_OUT		<= x"c305";
TC_FLAGS_OFFSET_OUT	<= (others => '0');
TC_IDENT_OUT        <= x"abcd";

end test_data_source;


