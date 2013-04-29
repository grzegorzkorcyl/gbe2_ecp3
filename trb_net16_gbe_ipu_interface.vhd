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

entity trb_net16_gbe_ipu_interface is
	port (
	CLK_IPU                     : in    std_logic;
	CLK_GBE                     : in	std_logic;
	RESET                       : in    std_logic;
	-- IPU interface directed toward the CTS
	CTS_NUMBER_IN               : in    std_logic_vector (15 downto 0);
	CTS_CODE_IN                 : in    std_logic_vector (7  downto 0);
	CTS_INFORMATION_IN          : in    std_logic_vector (7  downto 0);
	CTS_READOUT_TYPE_IN         : in    std_logic_vector (3  downto 0);
	CTS_START_READOUT_IN        : in    std_logic;
	CTS_READ_IN                 : in    std_logic;
	CTS_DATA_OUT                : out   std_logic_vector (31 downto 0);
	CTS_DATAREADY_OUT           : out   std_logic;
	CTS_READOUT_FINISHED_OUT    : out   std_logic;      --no more data, end transfer, send TRM
	CTS_LENGTH_OUT              : out   std_logic_vector (15 downto 0);
	CTS_ERROR_PATTERN_OUT       : out   std_logic_vector (31 downto 0);
	-- Data from Frontends
	FEE_DATA_IN                 : in    std_logic_vector (15 downto 0);
	FEE_DATAREADY_IN            : in    std_logic;
	FEE_READ_OUT                : out   std_logic;
	FEE_BUSY_IN                 : in    std_logic;
	FEE_STATUS_BITS_IN          : in    std_logic_vector (31 downto 0);
	-- slow control interface
	START_CONFIG_OUT			: out	std_logic; -- reconfigure MACs/IPs/ports/packet size
	BANK_SELECT_OUT				: out	std_logic_vector(3 downto 0); -- configuration page address
	CONFIG_DONE_IN				: in	std_logic; -- configuration finished
	DATA_GBE_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to GbE
	DATA_IPU_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to CTS / TRBnet
	MULT_EVT_ENABLE_IN			: in    std_logic;
	MAX_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- the maximum size of one HadesQueue  -- gk 08.04.10
	MIN_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- gk 20.07.10
	READOUT_CTR_IN				: in	std_logic_vector(23 downto 0); -- gk 26.04.10
	READOUT_CTR_VALID_IN			: in	std_logic; -- gk 26.04.10
	-- PacketConstructor interface
	ALLOW_LARGE_IN				: in	std_logic;  -- gk 21.07.10
	PC_WR_EN_OUT                : out   std_logic;
	PC_DATA_OUT                 : out   std_logic_vector (7 downto 0);
	PC_READY_IN                 : in    std_logic;
	PC_SOS_OUT                  : out   std_logic;
	PC_EOS_OUT                  : out   std_logic; -- gk 07.10.10
	PC_EOD_OUT                  : out   std_logic;
	PC_SUB_SIZE_OUT             : out   std_logic_vector(31 downto 0);
	PC_TRIG_NR_OUT              : out   std_logic_vector(31 downto 0);
	PC_PADDING_OUT              : out   std_logic;
	MONITOR_OUT                 : out   std_logic_vector(223 downto 0);
	DEBUG_OUT                   : out   std_logic_vector(383 downto 0)
	);
end entity trb_net16_gbe_ipu_interface;

architecture RTL of trb_net16_gbe_ipu_interface is

type saveStates is (IDLE, SAVE_EVT_ADDR, WAIT_FOR_DATA, SAVE_DATA, ADD_SUBSUB1, ADD_SUBSUB2, ADD_SUBSUB3, ADD_SUBSUB4, TERMINATE, CLOSE, RESET_FIFO);
signal save_current_state, save_next_state : saveStates;

type loadStates is (IDLE, REMOVE, DECIDE, WAIT_FOR_LOAD, LOAD, DROP, CLOSE);
signal load_current_state, load_next_state : loadStates;

signal sf_data : std_Logic_vector(15 downto 0);
signal save_eod, sf_wr_en, sf_rd_en, sf_reset, sf_empty, sf_full, sf_afull, sf_eod : std_logic;
signal sf_q, pc_data : std_logic_vector(7 downto 0);

signal cts_rnd, cts_trg : std_logic_vector(15 downto 0);
signal save_ctr : std_logic_vector(15 downto 0);

signal saved_events_ctr, loaded_events_ctr, saved_events_ctr_gbe : std_logic_vector(7 downto 0);
signal loaded_bytes_ctr : std_Logic_vector(15 downto 0);

signal trigger_random : std_logic_vector(7 downto 0);
signal trigger_number : std_logic_vector(15 downto 0);
signal subevent_size : std_logic_vector(17 downto 0);

signal bank_select : std_logic_vector(3 downto 0);
	
begin

--*********
-- RECEIVING PART
--*********

SAVE_MACHINE_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (RESET = '1') then
			save_current_state <= IDLE;
		else
			save_current_state <= save_next_state;
		end if;
	end if;
end process SAVE_MACHINE_PROC;

SAVE_MACHINE : process(save_current_state, CTS_START_READOUT_IN, FEE_BUSY_IN, CTS_READ_IN)
begin
	case (save_current_state) is
	
		when IDLE =>
			if (CTS_START_READOUT_IN = '1') then
				save_next_state <= SAVE_EVT_ADDR;
			else
				save_next_state <= IDLE;
			end if;
			
		when SAVE_EVT_ADDR =>
			save_next_state <= WAIT_FOR_DATA;
			
		when WAIT_FOR_DATA =>
			if (FEE_BUSY_IN = '1') then
				save_next_state <= SAVE_DATA;
			else
				save_next_state <= WAIT_FOR_DATA;
			end if;  
		
		when SAVE_DATA =>
			if (FEE_BUSY_IN = '0') then
				save_next_state <= TERMINATE;
			else
				save_next_state <= SAVE_DATA;
			end if;
		
		when TERMINATE =>
			if (CTS_READ_IN = '1') then
				save_next_state <= CLOSE;
			else
				save_next_state <= TERMINATE;
			end if;
			
		when CLOSE => 
			if (CTS_START_READOUT_IN = '0') then
				save_next_state <= ADD_SUBSUB1;
			else
				save_next_state <= CLOSE;
			end if;
		
		when ADD_SUBSUB1 =>
			save_next_state <= ADD_SUBSUB2;
		
		when ADD_SUBSUB2 =>
			save_next_state <= ADD_SUBSUB3;
			
		when ADD_SUBSUB3 =>
			save_next_state <= ADD_SUBSUB4;
			
		when ADD_SUBSUB4 =>
			save_next_state <= IDLE;
		
		--TODO: complete with reset fifo state
			
		when others => save_next_state <= IDLE; 
		 
	end case;
end process SAVE_MACHINE;

SF_WR_EN_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (sf_afull = '0') then
			if (save_current_state = SAVE_DATA and FEE_DATAREADY_IN = '1' and FEE_BUSY_IN = '1') then
				sf_wr_en <= '1';
			elsif (save_current_state = SAVE_EVT_ADDR) then
				sf_wr_en <= '1';
			elsif (save_current_state = ADD_SUBSUB1 or save_current_state = ADD_SUBSUB2 or save_current_state = ADD_SUBSUB3 or save_current_state = ADD_SUBSUB4) then
				sf_wr_en <= '1';
			else
				sf_wr_en <= '0';
			end if;
		else
			sf_wr_en <= '0';
		end if;
	end if;
end process SF_WR_EN_PROC;

SF_DATA_EOD_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		case (save_current_state) is
		
			when SAVE_EVT_ADDR =>
				sf_data(3 downto 0)  <= CTS_INFORMATION_IN(3 downto 0);
				sf_data(15 downto 4) <= x"abc";
				save_eod <= '0';
				
			when SAVE_DATA =>
				sf_data <= FEE_DATA_IN;
				save_eod <= '0';
				
			when ADD_SUBSUB1 =>
				sf_data <= x"0001";
				save_eod <= '0';
			
			when ADD_SUBSUB2 =>
				sf_data <= x"5555";
				save_eod <= '0';
			
			when ADD_SUBSUB3 =>
				sf_data <= FEE_STATUS_BITS_IN(31 downto 16);
				save_eod <= '0';
			
			when ADD_SUBSUB4 =>
				sf_data <= FEE_STATUS_BITS_IN(15 downto 0);
				save_eod <= '1';
				
			when others => sf_data <= (others => '0'); save_eod <= '0';
			
		end case;
	end if;
end process SF_DATA_EOD_PROC;

SAVED_EVENTS_CTR_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (RESET = '1') then
			saved_events_ctr <= (others => '0');
		elsif (save_current_state = ADD_SUBSUB4) then
			saved_events_ctr <= saved_events_ctr + x"1";
		else
			saved_events_ctr <= saved_events_ctr;
		end if;
	end if;
end process SAVED_EVENTS_CTR_PROC;
				
CTS_DATAREADY_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = SAVE_DATA and FEE_BUSY_IN = '0') then
			CTS_DATAREADY_OUT <= '1';
		elsif (save_current_state = TERMINATE) then
			CTS_DATAREADY_OUT <= '1';
		else
			CTS_DATAREADY_OUT <= '0';
		end if;
	end if;
end process CTS_DATAREADY_PROC;

CTS_READOUT_FINISHED_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = CLOSE) then
			CTS_READOUT_FINISHED_OUT <= '1';
		else
			CTS_READOUT_FINISHED_OUT <= '0';
		end if;
	end if;
end process CTS_READOUT_FINISHED_PROC;

CTS_LENGTH_OUT        <= (others => '0');
CTS_ERROR_PATTERN_OUT <= (others => '0');

CTS_DATA_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		CTS_DATA_OUT <= "0001" & cts_rnd(11 downto 0) & cts_trg;
	end if;
end process CTS_DATA_PROC;

CTS_RND_TRG_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = SAVE_DATA and save_ctr = x"0000") then
			cts_rnd <= sf_data;
			cts_trg <= cts_trg;
		elsif (save_current_state = SAVE_DATA and save_ctr = x"0001") then
			cts_rnd <= cts_rnd;
			cts_trg <= sf_data;
		else
			cts_rnd <= cts_rnd;
			cts_trg <= cts_trg;
		end if;
	end if;
end process CTS_RND_TRG_PROC;

SAVE_CTR_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = IDLE) then
			save_ctr <= (others => '0');
		elsif (save_current_state = SAVE_DATA and sf_wr_en = '1') then
			save_ctr <= save_ctr + x"1";
		else
			save_ctr <= save_ctr;
		end if;
	end if;
end process SAVE_CTR_PROC;

FEE_READ_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (sf_afull = '0') then
			if (save_current_state = IDLE or save_current_state = SAVE_EVT_ADDR or save_current_state = WAIT_FOR_DATA or save_current_state = SAVE_DATA) then
				FEE_READ_OUT <= '1';
			else
				FEE_READ_OUT <= '0';
			end if;
		else
			FEE_READ_OUT <= '0';
		end if;
	end if;
end process FEE_READ_PROC;


THE_SPLIT_FIFO: fifo_32kx16x8_mb2
port map( 
	-- Byte swapping for correct byte order on readout side of FIFO
	Data(7 downto 0)  => sf_data(15 downto 8),
	Data(8)           => '0',
	Data(16 downto 9) => sf_data(7 downto 0),
	Data(17)          => save_eod,
	WrClock           => CLK_IPU,
	RdClock           => CLK_GBE,
	WrEn              => sf_wr_en,
	RdEn              => sf_rd_en,
	Reset             => sf_reset,
	RPReset           => sf_reset,
	AmEmptyThresh     => b"0000_0000_0000_0010", -- one byte ahead
	AmFullThresh      => b"111_1111_1110_1111", -- 0x7fef = 32751
	Q(7 downto 0)     => sf_q,
	Q(8)              => sf_eod,
	WCNT              => open,
	RCNT              => open,
	Empty             => sf_empty,
	AlmostEmpty       => open,
	Full              => sf_full,
	AlmostFull        => sf_afull
);
sf_reset <= RESET;

--*********
-- LOADING PART
--*********

PC_DATA_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		pc_data <= sf_q;
	end if;
end process PC_DATA_PROC;

LOAD_MACHINE_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (RESET = '1') then
			load_current_state <= IDLE;
		else
			load_current_state <= load_next_state;
		end if;
	end if;
end process LOAD_MACHINE_PROC;

LOAD_MACHINE : process(load_current_state, saved_events_ctr_gbe, loaded_events_ctr, loaded_bytes_ctr, PC_READY_IN)
begin
	case (load_current_state) is

		when IDLE =>
			if (saved_events_ctr /= loaded_events_ctr) then
				load_next_state <= REMOVE;
			else
				load_next_state <= IDLE;
			end if;
		
		when REMOVE =>
			if (loaded_bytes_ctr = x"0005") then
				load_next_state <= DECIDE;
			else
				load_next_state <= REMOVE;
			end if;
		
		when DECIDE =>
			load_next_state <= LOAD;
			
		when WAIT_FOR_LOAD =>
			if (PC_READY_IN = '1') then
				load_next_state <= LOAD;
			else
				load_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD =>
			if (sf_eod = '1') then
				load_next_state <= CLOSE;
			else
				load_next_state <= LOAD;
			end if;
			
		
		--when DROP =>
		
		when CLOSE =>
			load_next_state <= IDLE;
		
		when others => load_next_state <= IDLE;

	end case;
end process LOAD_MACHINE;

saved_ctr_sync : signal_sync
generic map(
	WIDTH => 8,
	DEPTH => 2
)
port map(
	RESET => RESET,
	CLK0  => CLK_GBE,
	CLK1  => CLK_GBE,
	D_IN  => saved_events_ctr,
	D_OUT => saved_events_ctr_gbe
);

SF_RD_EN_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = REMOVE or load_current_state = LOAD) then
			sf_rd_en <= '1';
		else
			sf_rd_en <= '0';
		end if;
	end if;
end process SF_RD_EN_PROC;

--*****
-- information extraction

TRIGGER_RANDOM_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = IDLE) then
			trigger_random <= (others => '0');
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0004") then
			trigger_random <= pc_data;
		else
			trigger_random <= trigger_random;
		end if;
	end if;
end process TRIGGER_RANDOM_PROC;

TRIGGER_NUMBER_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = IDLE) then
			trigger_number <= (others => '0');
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0006") then
			trigger_number(7 downto 0) <= pc_data;
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0005") then
			trigger_number(15 downto 8) <= pc_data;
		else
			trigger_number <= trigger_number;
		end if;
	end if;
end process TRIGGER_NUMBER_PROC;

SUBEVENT_SIZE_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = IDLE) then
			subevent_size <= (others => '0');
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0008") then
			subevent_size(9 downto 2) <= pc_data; 		
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0007") then
			subevent_size(17 downto 10) <= pc_data;
		else
			subevent_size <= subevent_size;
		end if;
	end if;
end process SUBEVENT_SIZE_PROC;

-- end of extraction
--*****

--*****
-- counters

LOADED_EVENTS_CTR_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (RESET = '1') then
			loaded_events_ctr <= (others => '0');
		elsif (load_current_state = CLOSE) then
			loaded_events_ctr <= loaded_events_ctr + x"1";
		else
			loaded_events_ctr <= loaded_events_ctr;
		end if;
	end if;
end process LOADED_EVENTS_CTR_PROC;

LOADED_BYTES_CTR_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = IDLE or load_current_state = DECIDE) then
			loaded_bytes_ctr <= (others => '0');
		elsif (sf_rd_en = '1') then
			elsif (load_current_state = REMOVE or load_current_state = LOAD or load_current_state = DROP) then
				loaded_bytes_ctr <= loaded_bytes_ctr + x"1";
			else
				loaded_bytes_ctr <= loaded_bytes_ctr;
			end if;
		else
			loaded_bytes_ctr <= loaded_bytes_ctr;
		end if;		
	end if;
end process LOADED_BYTES_CTR_PROC;

-- end of counters
--*****

--*****
-- event builder selection

BANK_SELECT_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = IDLE) then
			bank_select <= x"0";
		elsif (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0000") then
			bank_select <= pc_data(3 downto 0);
		else
			bank_select <= bank_select;
		end if;
	end if;
end process BANK_SELECT_PROC;

BANK_SELECT_OUT <= bank_select;

START_CONFIG_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = REMOVE and sf_rd_en = '1' and loaded_bytes_ctr = x"0000") then
			START_CONFIG_OUT <= '1';
		elsif (CONFIG_DONE_IN = '1') then
			START_CONFIG_OUT <= '0';
		end if;
	end if;
end process START_CONFIG_PROC;

-- end of event builder selection
--*****


PC_WR_EN_PROC : process(CLK_GBE)
begin
	if (load_current_state = LOAD and sf_rd_en = '1') then
		PC_WR_EN_OUT <= '1';
	else
		PC_WR_EN_OUT <= '0';
	end if;
end process PC_WR_EN_PROC;

PC_SOS_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = DECIDE) then
			PC_SOS_OUT <= '1';
		else
			PC_SOS_OUT <= '0';
		end if; 
	end if;
end process PC_SOS_PROC;

PC_EOD_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		if (load_current_state = CLOSE) then
			PC_EOD_OUT <= '1';
		else
			PC_EOD_OUT <= '0';
		end if;
	end if;
end process PC_EOD_PROC;

PC_EOS_PROC : process(CLK_GBE)
begin
	if rising_edge(CLK_GBE) then
		PC_EOS_OUT <= '0';
	end if;
end process PC_EOS_PROC;

PC_DATA_OUT <= pc_data;

--TODO: register and put correct values
PC_SUB_SIZE_OUT <= b"0000_0000_0000_00" & subevent_size;

PC_TRIG_NR_OUT <= b"0000_0000" & trigger_number & trigger_random; 

DEBUG_OUT <= (others => '0');
MONITOR_OUT <= (others => '0');

end architecture RTL;
