LIBRARY ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;
--use work.version.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity gbe_setup is
port(
	CLK                       : in std_logic;
	RESET                     : in std_logic;

	-- interface to regio bus
	BUS_ADDR_IN               : in std_logic_vector(7 downto 0);
	BUS_DATA_IN               : in std_logic_vector(31 downto 0);
	BUS_DATA_OUT              : out std_logic_vector(31 downto 0);
	BUS_WRITE_EN_IN           : in std_logic;
	BUS_READ_EN_IN            : in std_logic;
	BUS_ACK_OUT               : out std_logic;

	-- output to gbe_buf
	GBE_SUBEVENT_ID_OUT       : out std_logic_vector(31 downto 0);
	GBE_SUBEVENT_DEC_OUT      : out std_logic_vector(31 downto 0);
	GBE_QUEUE_DEC_OUT         : out std_logic_vector(31 downto 0);
	GBE_MAX_FRAME_OUT         : out std_logic_vector(15 downto 0);
	GBE_USE_GBE_OUT           : out std_logic;
	GBE_USE_TRBNET_OUT        : out std_logic;
	GBE_USE_MULTIEVENTS_OUT   : out std_logic;
	GBE_READOUT_CTR_OUT       : out std_logic_vector(23 downto 0);
	GBE_READOUT_CTR_VALID_OUT : out std_logic;
	GBE_ALLOW_RX_OUT          : out std_logic;
	GBE_ADDITIONAL_HDR_OUT    : out std_logic;
	GBE_INSERT_TTYPE_OUT      : out std_logic;
	GBE_SOFT_RESET_OUT        : out std_logic;
	GBE_MAX_REPLY_OUT         : out std_logic_vector(31 downto 0);
	
	GBE_MAX_SUB_OUT           : out std_logic_vector(15 downto 0);
	GBE_MAX_QUEUE_OUT         : out std_logic_vector(15 downto 0);
	GBE_MAX_SUBS_IN_QUEUE_OUT : out std_logic_vector(15 downto 0);
	GBE_MAX_SINGLE_SUB_OUT    : out std_logic_vector(15 downto 0);
	
	MONITOR_RX_BYTES_IN       : in std_logic_vector(31 downto 0);
	MONITOR_RX_FRAMES_IN      : in std_logic_vector(31 downto 0);
	MONITOR_TX_BYTES_IN       : in std_logic_vector(31 downto 0);
	MONITOR_TX_FRAMES_IN      : in std_logic_vector(31 downto 0);
	MONITOR_TX_PACKETS_IN     : in std_logic_vector(31 downto 0);
	MONITOR_DROPPED_IN        : in std_logic_vector(31 downto 0);
	
	MONITOR_SELECT_REC_IN	      : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_REC_BYTES_IN   : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_BYTES_IN  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_SENT_IN	      : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_IN_IN	  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_DROP_OUT_IN	  : in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	MONITOR_SELECT_GEN_DBG_IN     : in	std_logic_vector(2*c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DUMMY_EVENT_SIZE_OUT : out std_logic_vector(15 downto 0);
	DUMMY_TRIGGERED_MODE_OUT : out std_logic;
	
	DATA_HIST_IN : in hist_array;
	SCTRL_HIST_IN : in hist_array
);
end entity;

architecture gbe_setup of gbe_setup is

signal reset_values      : std_logic;
signal subevent_id       : std_logic_vector(31 downto 0);
signal subevent_dec      : std_logic_vector(31 downto 0);
signal queue_dec         : std_logic_vector(31 downto 0);
signal max_frame         : std_logic_vector(15 downto 0);
signal use_gbe           : std_logic;
signal use_trbnet        : std_logic;
signal use_multievents   : std_logic;
signal readout_ctr       : std_logic_vector(23 downto 0);
signal readout_ctr_valid : std_logic;
signal ack               : std_logic;
signal ack_q             : std_logic;
signal data_out          : std_logic_vector(31 downto 0);
signal allow_rx          : std_logic;
signal additional_hdr    : std_logic;
signal insert_ttype      : std_logic;
signal max_reply         : std_logic_vector(31 downto 0);
  signal max_sub, max_queue, max_subs_in_queue, max_single_sub : std_logic_vector(15 downto 0);
  signal dummy_event : std_logic_vector(15 downto 0);
  signal dummy_mode : std_logic;

begin

OUT_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		GBE_SUBEVENT_ID_OUT       <= subevent_id;
		GBE_SUBEVENT_DEC_OUT      <= subevent_dec;
		GBE_QUEUE_DEC_OUT         <= queue_dec;
		GBE_MAX_FRAME_OUT         <= max_frame;
		GBE_USE_GBE_OUT           <= use_gbe;
		GBE_USE_TRBNET_OUT        <= use_trbnet;
		GBE_USE_MULTIEVENTS_OUT   <= use_multievents;
		GBE_READOUT_CTR_OUT       <= readout_ctr;
		GBE_READOUT_CTR_VALID_OUT <= readout_ctr_valid;
		BUS_ACK_OUT               <= ack_q;
		ack_q                     <= ack;
		BUS_DATA_OUT              <= data_out;
		GBE_ALLOW_RX_OUT          <= '1'; --allow_rx;
		GBE_INSERT_TTYPE_OUT      <= insert_ttype;
		GBE_ADDITIONAL_HDR_OUT    <= additional_hdr;
		GBE_MAX_SUB_OUT           <= max_sub;
		GBE_MAX_QUEUE_OUT         <= max_queue;
		GBE_MAX_SUBS_IN_QUEUE_OUT <= max_subs_in_queue;
		GBE_MAX_SINGLE_SUB_OUT    <= max_single_sub;
		GBE_MAX_REPLY_OUT         <= max_reply;
		DUMMY_EVENT_SIZE_OUT      <= dummy_event;
		DUMMY_TRIGGERED_MODE_OUT  <= dummy_mode;
	end if;
end process OUT_PROC;

ACK_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			ack <= '0';
		elsif ((BUS_WRITE_EN_IN = '1') or (BUS_READ_EN_IN = '1')) then
			ack <= '1';
		else
			ack <= '0';
		end if;
	end if;
end process ACK_PROC;

WRITE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if ( (RESET = '1') or (reset_values = '1') ) then
			subevent_id       <= x"0000_00cf";
			subevent_dec      <= x"0002_0001";
			queue_dec         <= x"0003_0062";
			max_frame         <= x"0578";
			use_gbe           <= '0';
			use_trbnet        <= '0';
			use_multievents   <= '0';
			reset_values      <= '0';
			readout_ctr       <= x"00_0000";
			readout_ctr_valid <= '0';
			allow_rx          <= '1';
			insert_ttype      <= '0';
			additional_hdr    <= '1';	
			GBE_SOFT_RESET_OUT <= '0';
			max_sub           <= x"e998";  --  59800
			max_queue         <= x"ea60";  -- 60000   
			max_subs_in_queue <= x"00c8";  -- 200     
			max_single_sub    <= x"7d00";  -- 32000   
			max_reply         <= x"0000_fa00";
			dummy_event       <= x"0100";
			dummy_mode        <= '0';

		elsif (BUS_WRITE_EN_IN = '1') then
		
			GBE_SOFT_RESET_OUT <= '0';
		
			case BUS_ADDR_IN is

				when x"00" =>
					subevent_id <= BUS_DATA_IN;

				when x"01" =>
					subevent_dec <= BUS_DATA_IN;

				when x"02" =>
					queue_dec <= BUS_DATA_IN;

				when x"04" =>
					max_frame <= BUS_DATA_IN(15 downto 0);

				when x"05" =>
					if (BUS_DATA_IN = x"0000_0000") then
						use_gbe <= '0';
					else
						use_gbe <= '1';
					end if;

				when x"06" =>
					if (BUS_DATA_IN = x"0000_0000") then
						use_trbnet <= '0';
					else
						use_trbnet <= '1';
					end if;

				when x"07" =>
					if (BUS_DATA_IN = x"0000_0000") then
						use_multievents <= '0';
					else
						use_multievents <= '1';
					end if;

				when x"08" =>
					readout_ctr <= BUS_DATA_IN(23 downto 0);
					readout_ctr_valid <= '1';
					
				when x"09" =>
					allow_rx         <= BUS_DATA_IN(0);
					
				when x"0a" =>
					additional_hdr   <= BUS_DATA_IN(0);
					
				when x"0b" =>
					insert_ttype     <= BUS_DATA_IN(0);
					
				when x"0c" =>
					max_sub          <= BUS_DATA_IN(15 downto 0);
					
				when x"10" =>
					max_queue        <= BUS_DATA_IN(15 downto 0);
					
				when x"0e" =>
					max_subs_in_queue <= BUS_DATA_IN(15 downto 0);
					
				when x"0f" =>
					max_single_sub   <= BUS_DATA_IN(15 downto 0);
					
				when x"11" =>
					max_reply        <= BUS_DATA_IN;
					
				when x"12" =>
					dummy_event      <= BUS_DATA_IN(15 downto 0);
					
				when x"13" =>
					dummy_mode       <= BUS_DATA_IN(0);

				when x"ff" =>
					if (BUS_DATA_IN = x"ffff_ffff") then
						reset_values <= '0';
						GBE_SOFT_RESET_OUT <= '1';
					else
						reset_values <= '0';
						GBE_SOFT_RESET_OUT <= '0';
					end if;

				when others =>
					subevent_id        <= subevent_id;
					subevent_dec       <= subevent_dec;
					queue_dec          <= queue_dec;
					max_frame          <= max_frame;
					use_gbe            <= use_gbe;
					use_trbnet         <= use_trbnet;
					use_multievents    <= use_multievents;
					reset_values       <= reset_values;
					readout_ctr        <= readout_ctr;
					readout_ctr_valid  <= readout_ctr_valid;
					allow_rx           <= allow_rx;
					additional_hdr     <= additional_hdr;
					insert_ttype       <= insert_ttype;
					max_sub            <= max_sub;          
					max_queue          <= max_queue;        
					max_subs_in_queue  <= max_subs_in_queue;
					max_single_sub     <= max_single_sub;	
					max_reply          <= max_reply;	
					dummy_event        <= dummy_event;
					dummy_mode         <= dummy_mode;	
			end case;
		else
			reset_values      <= '0';
			readout_ctr_valid <= '0';
			GBE_SOFT_RESET_OUT <= '0';
		end if;
	end if;
end process WRITE_PROC;

READ_PROC : process(CLK)
	variable address : integer range 0 to 255;
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			data_out <= (others => '0');
		elsif (BUS_READ_EN_IN = '1') then
		
			address := to_integer(unsigned(BUS_ADDR_IN));
		
			case address is

				when 0 =>
					data_out <= subevent_id;

				when 1 =>
					data_out <= subevent_dec;

				when 2 =>
					data_out <= queue_dec;

				when 4 =>
					data_out(15 downto 0) <= max_frame;
					data_out(31 downto 16) <= (others => '0');

				when 5 =>
					if (use_gbe = '0') then
						data_out <= x"0000_0000";
					else
						data_out <= x"0000_0001";
					end if;

				when 6 =>
					if (use_trbnet = '0') then
						data_out <= x"0000_0000";
					else
						data_out <= x"0000_0001";
					end if;

				when 7 =>
					if (use_multievents = '0') then
						data_out <= x"0000_0000";
					else
						data_out <= x"0000_0001";
					end if;
					
				when 9 =>
					data_out(0) <= allow_rx;
					data_out(31 downto 1) <= (others => '0');
					
				when 10 =>
					data_out(0) <= additional_hdr;
					data_out(31 downto 1) <= (others => '0');
					
				when 11 =>
					data_out(0) <= insert_ttype;
					data_out(31 downto 1) <= (others => '0');
					
				when 12 =>
					data_out(15 downto 0) <= max_sub;
					data_out(31 downto 16) <= (others => '0');
					
				when 14 =>
					data_out(15 downto 0) <= max_subs_in_queue;
					data_out(31 downto 16) <= (others => '0');
					
				when 15 =>
					data_out(15 downto 0) <= max_single_sub;
					data_out(31 downto 16) <= (others => '0');
					
				when 16 =>
					data_out(15 downto 0) <= max_queue;
					data_out(31 downto 16) <= (others => '0');
					
				when 17 =>
					data_out <= max_reply;
					
				when 18 =>
					data_out(15 downto 0)  <= dummy_event;
					data_out(31 downto 16) <= (others => '0');
					
				when 19 =>
					data_out(0) <= dummy_mode;
					data_out(31 downto 1) <= (others => '0');
					
										
				-- Histogram of sctrl data sizes
				when 96 to 127 =>
					data_out <= SCTRL_HIST_IN(address - 96);
					
				-- Histogram of TrbNetData data sizes
				when 128 to 159 =>
					data_out <= DATA_HIST_IN(address - 128);
				
				-- General statistics	
				when 224 =>
					data_out <= MONITOR_RX_BYTES_IN;

				when 225 =>
					data_out <= MONITOR_RX_FRAMES_IN;

				when 226 =>
					data_out <= MONITOR_TX_BYTES_IN;

				when 227 =>
					data_out <= MONITOR_TX_FRAMES_IN;

				when 228 =>
					data_out <= MONITOR_TX_PACKETS_IN;

				when 229 =>
					data_out <= MONITOR_DROPPED_IN;
					
				-- Sctrl
				when 160 =>
					data_out <= MONITOR_SELECT_REC_IN(3 * 32 - 1 downto 2 * 32);
				when 161 =>
					data_out <= MONITOR_SELECT_REC_BYTES_IN(3 * 32 - 1 downto 2 * 32);
				when 162 =>
					data_out <= MONITOR_SELECT_SENT_IN(3 * 32 - 1 downto 2 * 32);
				when 163 =>
					data_out <= MONITOR_SELECT_SENT_BYTES_IN(3 * 32 - 1 downto 2 * 32);
				when 164 =>
					data_out <= MONITOR_SELECT_GEN_DBG_IN(3 * 64 - 1 - 32 downto 2 * 64);
				when 165 =>
					data_out <= MONITOR_SELECT_GEN_DBG_IN(3 * 64 - 1 downto 2 * 64 + 32);
				when 166 =>
					data_out <= MONITOR_SELECT_DROP_IN_IN(3 * 32 - 1 downto 2 * 32);
				when 167 =>
					data_out <= MONITOR_SELECT_DROP_OUT_IN(3 * 32 - 1 downto 2 * 32);
							
				-- TrbnetData
				when 176 =>
					data_out <= MONITOR_SELECT_REC_IN(4 * 32 - 1 downto 3 * 32);
				when 177 =>
					data_out <= MONITOR_SELECT_REC_BYTES_IN(4 * 32 - 1 downto 3 * 32);
				when 178 =>
					data_out <= MONITOR_SELECT_SENT_IN(4 * 32 - 1 downto 3 * 32);
				when 179 =>
					data_out <= MONITOR_SELECT_SENT_BYTES_IN(4 * 32 - 1 downto 3 * 32);
				when 180 =>
					data_out <= MONITOR_SELECT_GEN_DBG_IN(4 * 64 - 1 - 32 downto 3 * 64);
				when 181 =>
					data_out <= MONITOR_SELECT_GEN_DBG_IN(4 * 64 - 1 downto 3 * 64 + 32);
				when 182 =>
					data_out <= MONITOR_SELECT_DROP_IN_IN(4 * 32 - 1 downto 3 * 32);
				when 183 =>
					data_out <= MONITOR_SELECT_DROP_OUT_IN(4 * 32 - 1 downto 3 * 32);
				
				-- for older network monitors	
				when 243 =>
					data_out <= MONITOR_TX_BYTES_IN;
					
				when 244 =>
					data_out <= MONITOR_TX_FRAMES_IN;
					
				when others =>
					data_out <= (others => '0');
			end case;
		end if;
	end if;
end process READ_PROC;

end architecture;