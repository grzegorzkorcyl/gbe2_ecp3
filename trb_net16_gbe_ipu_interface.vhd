LIBRARY ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

library work;

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

component fifo_32kx16x8_mb2
port( 
	Data            : in    std_logic_vector(17 downto 0); 
	WrClock         : in    std_logic;
	RdClock         : in    std_logic; 
	WrEn            : in    std_logic;
	RdEn            : in    std_logic;
	Reset           : in    std_logic; 
	RPReset         : in    std_logic; 
	AmEmptyThresh   : in    std_logic_vector(15 downto 0); 
	AmFullThresh    : in    std_logic_vector(14 downto 0); 
	Q               : out   std_logic_vector(8 downto 0); 
	WCNT            : out   std_logic_vector(15 downto 0); 
	RCNT            : out   std_logic_vector(16 downto 0);
	Empty           : out   std_logic;
	AlmostEmpty     : out   std_logic;
	Full            : out   std_logic;
	AlmostFull      : out   std_logic
);
end component;

type saveStates is (IDLE, SAVE_EVT_ADDR, WAIT_FOR_DATA, SAVE_DATA, ADD_SUBSUB1, ADD_SUBSUB2, ADD_SUBSUB3, ADD_SUBSUB4, TERMINATE, CLOSE, RESET_FIFO);
signal save_current_state, save_next_state : saveStates;

signal sf_data : std_Logic_vector(15 downto 0);
signal save_eod, sf_wr_en, sf_rd_en, sf_reset, sf_empty, sf_full, sf_eod : std_logic;
signal sf_q : std_logic_vector(7 downto 0);

signal cts_rnd, cts_trg : std_logic_vector(15 downto 0);
signal save_ctr : std_logic_vector(15 downto 0);

	
begin

--*********
-- RECEIVING PART
--*********

SAVE_MACHINE_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if RESET = '1' then
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
				save_next_state <= IDLE;
			else
				save_next_state <= CLOSE;
			end if;
		
		--TODO: complete with add sub sub states
			
		when others => save_next_state <= IDLE; 
		 
	end case;
end process SAVE_MACHINE;

SF_WR_EN_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = SAVE_DATA and FEE_DATAREADY_IN = '1' and FEE_READ_IN = '1') then
			sf_wr_en <= '1';
		elsif (save_current_state = SAVE_EVT_ADDR) then
			sf_wr_en <= '1';
		else
			sf_wr_en <= '0';
		end if;
	end if;
end process SF_WR_EN_PROC;

SF_DATA_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		case (save_current_state) is
		
			when SAVE_EVT_ADDR =>
				sf_data(3 downto 0)  <= CTS_INFORMATION_IN(3 downto 0);
				sf_data(15 downto 4) <= x"abc";
				
			when SAVE_DATA =>
				sf_data <= FEE_DATA_IN;
				
			when others => sf_data <= (others => '0');
			
		end case;
	end if;
end process SF_DATA_PROC;
				
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
end process SAVE_CTR_PROC;

FEE_READ_PROC : process(CLK_IPU)
begin
	if rising_edge(CLK_IPU) then
		if (save_current_state = IDLE or save_current_state = SAVE_EVT_ADDR or save_current_state = WAIT_FOR_DATA or save_current_state = SAVE_DATA) then
			FEE_READ_OUT <= '1';
		--TODO: when my fifo gets full I should halt a bit
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
	AlmostFull        => open
);

end architecture RTL;
