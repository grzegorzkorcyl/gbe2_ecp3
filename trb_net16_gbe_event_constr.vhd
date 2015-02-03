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
generic (
	READOUT_BUFFER_SIZE : integer range 1 to 4 := 1
);
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(7 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_START_OF_SUB_IN      : in    std_logic;
	PC_END_OF_SUB_IN        : in    std_logic;  -- gk 07.10.10
	PC_END_OF_QUEUE_IN      : in    std_logic;
	-- queue and subevent layer headers
	PC_SUB_SIZE_IN          : in    std_logic_vector(31 downto 0); -- store and swap
	PC_DECODING_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_EVENT_ID_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_TRIG_NR_IN           : in    std_logic_vector(31 downto 0); -- store and swap!
	PC_TRIGGER_TYPE_IN      : in	std_logic_vector(3 downto 0);
	PC_QUEUE_DEC_IN         : in    std_logic_vector(31 downto 0); -- swap
	PC_INSERT_TTYPE_IN      : in    std_logic;
	-- FrameConstructor ports
	TC_RD_EN_IN             : in    std_logic;
	TC_DATA_OUT             : out   std_logic_vector(8 downto 0);
	TC_EVENT_SIZE_OUT       : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end entity trb_net16_gbe_event_constr;

architecture RTL of trb_net16_gbe_event_constr is

attribute syn_encoding	: string;

type loadStates is (IDLE, GET_Q_SIZE, START_TRANSFER, LOAD_Q_HEADERS, LOAD_DATA, LOAD_SUB, LOAD_PADDING, LOAD_TERM, CLEANUP);
signal load_current_state, load_next_state : loadStates;
attribute syn_encoding of load_current_state : signal is "onehot";

type saveSubHdrStates is (IDLE, SAVE_SIZE, SAVE_DECODING, SAVE_ID, SAVE_TRG_NR);
signal save_sub_hdr_current_state, save_sub_hdr_next_state : saveSubHdrStates;
attribute syn_encoding of save_sub_hdr_current_state : signal is "onehot";

signal df_eos, df_wr_en, df_rd_en, df_empty, df_full, load_eod : std_logic;
signal df_q, df_qq : std_logic_vector(7 downto 0);
	
signal header_ctr : integer range 0 to 31;

signal shf_data, shf_q, shf_qq : std_logic_vector(7 downto 0);
signal shf_wr_en, shf_rd_en, shf_empty, shf_full : std_logic;
signal sub_int_ctr : integer range 0 to 3;
signal sub_size_to_save : std_logic_vector(31 downto 0);

signal qsf_data : std_logic_vector(31 downto 0);
signal qsf_q : std_logic_vector(7 downto 0);
signal qsf_wr, qsf_wr_en, qsf_wr_en_q, qsf_wr_en_qq, qsf_wr_en_qqq, qsf_rd_en, qsf_rd_en_q, qsf_empty : std_logic;

signal queue_size : std_logic_vector(31 downto 0);

signal termination : std_logic_vector(255 downto 0);
signal term_ctr : integer range 0 to 33;

signal actual_q_size : std_logic_vector(15 downto 0);
signal tc_data : std_logic_vector(7 downto 0);
signal df_data : std_logic_vector(7 downto 0);
signal df_eos_q, df_eos_qq : std_logic;
signal df_wr_en_q, df_wr_en_qq : std_logic;
signal qsf_full : std_logic;

signal padding_needed, insert_padding : std_logic;
signal load_eod_q : std_logic;
signal loaded_queue_bytes : std_logic_vector(15 downto 0);
signal shf_padding : std_logic;
signal block_shf_after_divide, previous_tc_rd : std_logic;
signal block_term_after_divide : std_logic;

begin
	
--*******
-- SAVING PART
--*******

DF_EOD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (PC_END_OF_SUB_IN = '1') then
			df_eos <= '1';
		else
			df_eos <= '0';
		end if;
		
		df_eos_q <= df_eos;
		df_eos_qq <= df_eos_q;
	end if; 
end process DF_EOD_PROC;

DF_WR_EN_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (PC_WR_EN_IN = '1') then
			df_wr_en <= '1';
		else
			df_wr_en <= '0';
		end if;
		
		df_wr_en_q <= df_wr_en;
		df_wr_en_qq <= df_wr_en_q;
		
		df_data <= PC_DATA_IN;
	end if;
end process DF_WR_EN_PROC;

df_64k_gen : if READOUT_BUFFER_SIZE = 4 generate
	DATA_FIFO : fifo_64kx9
	port map(
		Data(7 downto 0) =>  df_data,
		Data(8)          =>  df_eos_q,
		WrClock          =>  CLK,
		RdClock          =>  CLK,
		WrEn             =>  df_wr_en_qq,
		RdEn             =>  df_rd_en,
		Reset            =>  RESET,
		RPReset          =>  RESET,
		Q(7 downto 0)    =>  df_q,
		Q(8)             =>  load_eod,
		Empty            =>  df_empty,
		Full             =>  df_full
	);
end generate df_64k_gen;

df_8k_gen : if READOUT_BUFFER_SIZE = 2 generate
	DATA_FIFO : entity work.fifo_8kx9
	port map(
		Data(7 downto 0) =>  df_data,
		Data(8)          =>  df_eos_q,
		WrClock          =>  CLK,
		RdClock          =>  CLK,
		WrEn             =>  df_wr_en_qq,
		RdEn             =>  df_rd_en,
		Reset            =>  RESET,
		RPReset          =>  RESET,
		Q(7 downto 0)    =>  df_q,
		Q(8)             =>  load_eod,
		Empty            =>  df_empty,
		Full             =>  df_full
	);
end generate df_8k_gen;

df_4k_gen : if READOUT_BUFFER_SIZE = 1 generate
	DATA_FIFO : fifo_4096x9
	port map(
		Data(7 downto 0) =>  df_data,
		Data(8)          =>  df_eos_q,
		WrClock          =>  CLK,
		RdClock          =>  CLK,
		WrEn             =>  df_wr_en_qq,
		RdEn             =>  df_rd_en,
		Reset            =>  RESET,
		RPReset          =>  RESET,
		Q(7 downto 0)    =>  df_q,
		Q(8)             =>  load_eod,
		Empty            =>  df_empty,
		Full             =>  df_full
	);
end generate df_4k_gen;

DF_QQ_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		df_qq <= df_q;
	end if;
end process DF_QQ_PROC;

READY_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		PC_READY_OUT <= not df_full;
	end if;	
end process READY_PROC;

--*****
-- subevent headers
SUBEVENT_HEADERS_FIFO : fifo_4096x9 --fifo_4kx8_ecp3
port map(
	Data(7 downto 0) => shf_data,
	Data(8)     => PC_SUB_SIZE_IN(2),
	WrClock     => CLK,
	RdClock		=> CLK,
	WrEn        => shf_wr_en,
	RdEn        => shf_rd_en,
	Reset       => RESET,
	RPReset		=> RESET,
	Q(7 downto 0)    => shf_q,
	Q(8)             => shf_padding,
	Empty       => shf_empty,
	Full        => shf_full
);		

SHF_WR_EN_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (save_sub_hdr_current_state = IDLE) then
			shf_wr_en <= '0';
		else
			shf_wr_en <= '1';
		end if;
	end if;
end process SHF_WR_EN_PROC;

VARIOUS_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		shf_qq <= shf_q;
	end if;
end process VARIOUS_SYNC;

SAVE_SUB_HDR_MACHINE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		save_sub_hdr_current_state <= IDLE;
	elsif rising_edge(CLK) then
		save_sub_hdr_current_state <= save_sub_hdr_next_state;
	end if;
end process SAVE_SUB_HDR_MACHINE_PROC;

SAVE_SUB_HDR_MACHINE : process(save_sub_hdr_current_state, PC_START_OF_SUB_IN, sub_int_ctr)
begin
	case (save_sub_hdr_current_state) is
	
		when IDLE =>
			if (PC_START_OF_SUB_IN = '1') then
				save_sub_hdr_next_state <= SAVE_SIZE;
			else
				save_sub_hdr_next_state <= IDLE;
			end if;
			
		when SAVE_SIZE =>
			if (sub_int_ctr = 0) then
				save_sub_hdr_next_state <= SAVE_DECODING;
			else
				save_sub_hdr_next_state <= SAVE_SIZE;
			end if;
			
		when SAVE_DECODING =>
			if (sub_int_ctr = 0) then
				save_sub_hdr_next_state <= SAVE_ID;
			else
				save_sub_hdr_next_state <= SAVE_DECODING;
			end if;
			
		when SAVE_ID =>
			if (sub_int_ctr = 0) then
				save_sub_hdr_next_state <= SAVE_TRG_NR;
			else
				save_sub_hdr_next_state <= SAVE_ID;
			end if;
			
		when SAVE_TRG_NR =>
			if (sub_int_ctr = 0) then
				save_sub_hdr_next_state <= IDLE;
			else
				save_sub_hdr_next_state <= SAVE_TRG_NR;
			end if;
			
		when others => save_sub_hdr_next_state <= IDLE;
		
	end case;
end process SAVE_SUB_HDR_MACHINE;

SUB_INT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (save_sub_hdr_current_state = IDLE) then
			sub_int_ctr <= 3;
		else
			if (sub_int_ctr = 0) then
				sub_int_ctr <= 3;
			else
				sub_int_ctr <= sub_int_ctr - 1;
			end if;
		end if;
	end if;
end process SUB_INT_CTR_PROC;
  
SUB_SIZE_TO_SAVE_PROC : process (CLK)
begin
	if rising_edge(CLK) then
		sub_size_to_save <= PC_SUB_SIZE_IN + x"10" + x"8"; -- addition for subevent headers and subsubevent
	end if;
end process SUB_SIZE_TO_SAVE_PROC;

SHF_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		case (save_sub_hdr_current_state) is
			
			when IDLE => 
				shf_data <= x"ac";
			
			when SAVE_SIZE =>
				shf_data <= sub_size_to_save(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
			
			when SAVE_DECODING =>
				if (PC_INSERT_TTYPE_IN = '0') then
					shf_data <= PC_DECODING_IN(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
				else
					if (sub_int_ctr = 0) then
						shf_data(3 downto 0) <= PC_DECODING_IN(3 downto 0);
						shf_data(7 downto 4) <= PC_TRIGGER_TYPE_IN;
					else
						shf_data <= PC_DECODING_IN(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
					end if;
				end if;
			
			when SAVE_ID =>
				shf_data <= PC_EVENT_ID_IN(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
			
			when SAVE_TRG_NR =>
				shf_data <= PC_TRIG_NR_IN(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
			
			when others => shf_data <= x"00";
		
		end case;
	end if;
end process SHF_DATA_PROC;

--*******
-- queue sizes

QUEUE_SIZE_FIFO : fifo_512x32x8
port map(
	Data        =>  qsf_data,
	WrClock     =>  CLK,
	RdClock     =>  CLK,
	WrEn        =>  qsf_wr,
	RdEn        =>  qsf_rd_en,
	Reset       =>  RESET,
	RPReset     =>  RESET,
	Q           =>  qsf_q,
	Empty       =>  qsf_empty,
	Full        =>  qsf_full
);

qsf_wr <= qsf_wr_en_qqq or qsf_wr_en_qq or qsf_wr_en_q;

QSF_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		-- queue size is saved twice in a row to facilitate readout and packet construction 
		if (qsf_wr_en = '1' or qsf_wr_en_q = '1') then
			if (qsf_wr_en = '1' and qsf_wr_en_q = '0') then	
				qsf_data(7)            <= padding_needed;
				qsf_data(6 downto 0)   <= (others => '0');
			else
				qsf_data(7 downto 0)   <= queue_size(31 downto 24);
			end if;
			qsf_data(15 downto 8)  <= queue_size(23 downto 16);
			qsf_data(23 downto 16) <= queue_size(15 downto 8);
			qsf_data(31 downto 24) <= queue_size(7 downto 0);
		elsif (qsf_wr_en_qq = '1') then
			qsf_data(7 downto 0)   <= PC_QUEUE_DEC_IN(31 downto 24);
			qsf_data(15 downto 8)  <= PC_QUEUE_DEC_IN(23 downto 16);
			qsf_data(23 downto 16) <= PC_QUEUE_DEC_IN(15 downto 8);
			qsf_data(31 downto 24) <= PC_QUEUE_DEC_IN(7 downto 0);
		else
			qsf_data <= (others => '1');
		end if;
	end if;
end process QSF_DATA_PROC;

QSF_WR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		qsf_wr_en_q   <= qsf_wr_en;
		qsf_wr_en_qq  <= qsf_wr_en_q;
		qsf_wr_en_qqq <= qsf_wr_en_qq;
		
		qsf_wr_en <= PC_END_OF_QUEUE_IN;
	end if;
end process QSF_WR_PROC;

QUEUE_SIZE_PROC : process(RESET, CLK)
begin
	if RESET = '1' then
		queue_size <= x"0000_0008"; -- queue headers
	elsif rising_edge(CLK) then
		if (qsf_wr_en_qqq = '1') then
			queue_size <= x"0000_0008";
		elsif (save_sub_hdr_current_state = SAVE_SIZE and sub_int_ctr = 0) then
			if (PC_SUB_SIZE_IN(2) = '1') then
				queue_size <= queue_size + PC_SUB_SIZE_IN + x"4" + x"10" + x"8";  -- subevent data size + padding + subevent headers + subsubevent 
			else
				queue_size <= queue_size + PC_SUB_SIZE_IN + x"10" + x"8";  -- subevent data size + subevent headers + subsubevent
			end if;
		else
			queue_size <= queue_size;
		end if;
	end if;
end process QUEUE_SIZE_PROC;

process(CLK)
begin
	if rising_edge(CLK) then
		if (PC_START_OF_SUB_IN = '1') then
			padding_needed <= '0';
		elsif (save_sub_hdr_current_state = SAVE_SIZE and sub_int_ctr = 0) then
			if (PC_SUB_SIZE_IN(2) = '1') then
				padding_needed <= '1';
			else
				padding_needed <= '0';
			end if;
		else
			padding_needed <= padding_needed;
		end if;
	end if;
end process;

--*******
-- LOADING PART
--*******

LOAD_MACHINE_PROC : process(RESET, CLK) is
begin
	if RESET = '1' then
		load_current_state <= IDLE;
	elsif rising_edge(CLK) then
		load_current_state <= load_next_state;
	end if;
end process LOAD_MACHINE_PROC;

LOAD_MACHINE : process(load_current_state, qsf_empty, header_ctr, load_eod_q, term_ctr, insert_padding, loaded_queue_bytes, actual_q_size)
begin
	case (load_current_state) is
	
		when IDLE =>
			if (qsf_empty = '0') then -- something in queue sizes fifo means entire queue is waiting
				load_next_state <= GET_Q_SIZE;
			else
				load_next_state <= IDLE;
			end if;
			
		when GET_Q_SIZE =>
			if (header_ctr = 0) then
				load_next_state <= START_TRANSFER;
			else
				load_next_state <= GET_Q_SIZE;
			end if;
			
		when START_TRANSFER =>
			load_next_state <= LOAD_Q_HEADERS;
			
		when LOAD_Q_HEADERS =>
			if (header_ctr = 0) then
				load_next_state <= LOAD_SUB;
			else
				load_next_state <= LOAD_Q_HEADERS;
			end if;			
			
		when LOAD_SUB =>
			if (header_ctr = 0) then
				load_next_state <= LOAD_DATA;
			else
				load_next_state <= LOAD_SUB;
			end if;
			
		when LOAD_DATA =>
			if (load_eod_q = '1' and term_ctr = 33) then
				if (insert_padding = '1') then
					load_next_state <= LOAD_PADDING;
				else
					if (loaded_queue_bytes = actual_q_size) then
						load_next_state <= LOAD_TERM;
					else
						load_next_state <= LOAD_SUB;
					end if;
				end if;
			else
				load_next_state <= LOAD_DATA;
			end if;
			
		when LOAD_PADDING =>
			if (header_ctr = 0) then
				if (loaded_queue_bytes = actual_q_size) then
					load_next_state <= LOAD_TERM;
				else
					load_next_state <= LOAD_SUB;
				end if;
			else
				load_next_state <= LOAD_PADDING;
			end if;			
			
		when LOAD_TERM =>
			if (header_ctr = 0) then
				load_next_state <= CLEANUP;
			else
				load_next_state <= LOAD_TERM;
			end if;
		
		when CLEANUP =>
			load_next_state <= IDLE;
		
	end case;
end process LOAD_MACHINE;

process(CLK)
begin
	if rising_edge(CLK) then
		load_eod_q <= load_eod;
	end if;
end process;

HEADER_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			header_ctr <= 3;
		elsif (load_current_state = GET_Q_SIZE and header_ctr = 0) then
			header_ctr <= 8;
		elsif (load_current_state = LOAD_Q_HEADERS and header_ctr = 0) then
			header_ctr <= 15;
		elsif (load_current_state = LOAD_SUB and header_ctr = 0) then
			if (insert_padding = '1') then
				header_ctr <= 3;
			else
				header_ctr <= 31;
			end if;
		elsif (load_current_state = LOAD_PADDING and header_ctr = 0) then
			if (loaded_queue_bytes = actual_q_size) then
				header_ctr <= 31;
			else
				header_ctr <= 15;
			end if;
		elsif (load_current_state = LOAD_DATA and load_eod_q = '1' and term_ctr = 33 and loaded_queue_bytes = actual_q_size and insert_padding = '0') then
			header_ctr <= 31;
		elsif (load_current_state = LOAD_DATA and load_eod_q = '1' and term_ctr = 33 and loaded_queue_bytes /= actual_q_size and insert_padding = '0') then
			header_ctr <= 15;	
		elsif (load_current_state = LOAD_DATA and load_eod_q = '1' and term_ctr = 33 and loaded_queue_bytes /= actual_q_size and insert_padding = '1') then
			header_ctr <= 3;	
		elsif (load_current_state = LOAD_TERM and header_ctr = 0) then
			header_ctr <= 3;
		elsif (TC_RD_EN_IN = '1') then
			if (load_current_state = LOAD_Q_HEADERS or load_current_state = LOAD_TERM or load_current_state = LOAD_PADDING) then
				if (load_current_state = LOAD_TERM) then
					if (block_term_after_divide = '1') then
						header_ctr <= 31;
					else
						header_ctr <= header_ctr - 1;
					end if;
				else
					header_ctr <= header_ctr - 1;
				end if;
			elsif (load_current_state = LOAD_SUB and block_shf_after_divide = '0') then
				header_ctr <= header_ctr - 1;
			else
				header_ctr <= header_ctr;
			end if;
		elsif (load_current_state = GET_Q_SIZE) then
			header_ctr <= header_ctr - 1;
		else
			header_ctr <= header_ctr;
		end if;
	end if;
end process HEADER_CTR_PROC;

SIZE_FOR_PADDING_PROC : process(CLK)
begin	
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			insert_padding <= '0';
		elsif (load_current_state = LOAD_SUB and header_ctr = 12) then
			insert_padding <= shf_padding;
		else
			insert_padding <= insert_padding;
		end if;
	end if;
end process SIZE_FOR_PADDING_PROC;

TC_SOD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = START_TRANSFER) then
			TC_SOD_OUT <= '1';
		else
			TC_SOD_OUT <= '0';
		end if;
	end if;
end process TC_SOD_PROC;

process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			loaded_queue_bytes <= (others => '0');
		elsif (TC_RD_EN_IN = '1') then
			loaded_queue_bytes <= loaded_queue_bytes + x"1";
		else
			loaded_queue_bytes <= loaded_queue_bytes;
		end if;
	end if;
end process;

--*****
-- read from fifos

df_rd_en <= '1' when (load_current_state = LOAD_DATA and TC_RD_EN_IN = '1' and load_eod_q = '0') or 
					(load_current_state = LOAD_SUB and header_ctr = 0 and TC_RD_EN_IN = '1')
					else '0';

shf_rd_en <= '1' when (load_current_state = LOAD_SUB and TC_RD_EN_IN = '1' and header_ctr /= 0 and block_shf_after_divide = '0') or
					(load_current_state = LOAD_Q_HEADERS and header_ctr = 0 and TC_RD_EN_IN = '1') or
					(load_current_state = LOAD_DATA and load_eod_q = '1' and (loaded_queue_bytes /= actual_q_size) and (loaded_queue_bytes + x"4" /= actual_q_size))
					else '0';


-- nasty workaround for the case when the packet is divided on LOAD_SUB state
process(CLK)
begin
	if rising_edge(CLK) then
		previous_tc_rd <= TC_RD_EN_IN;
	end if;
end process;
block_shf_after_divide <= '1' when previous_tc_rd = '0' and TC_RD_EN_IN = '1' and header_ctr = 15 else '0';
block_term_after_divide <= '1' when previous_tc_rd = '0' and TC_RD_EN_IN = '1' and header_ctr = 31 else '0'; 

QUEUE_FIFO_RD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = GET_Q_SIZE and header_ctr /= 0) then
			qsf_rd_en_q <= '1';
		elsif (load_current_state = IDLE and qsf_empty = '0') then
			qsf_rd_en_q <= '1';
		else 
			qsf_rd_en_q <= '0';
		end if;
	end if;
end process QUEUE_FIFO_RD_PROC;

qsf_rd_en <= '1' when load_current_state = LOAD_Q_HEADERS and TC_RD_EN_IN = '1' and header_ctr /= 0 else qsf_rd_en_q;

ACTUAL_Q_SIZE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = START_TRANSFER) then
			actual_q_size(7 downto 0) <= qsf_q;
		elsif (load_current_state = GET_Q_SIZE and header_ctr = 0) then
			actual_q_size(15 downto 8)  <= qsf_q;
		end if;
	end if;
end process ACTUAL_Q_SIZE_PROC;

TC_EVENT_SIZE_OUT <= actual_q_size;  -- queue size without termination

TERMINATION_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			termination(255 downto 8) <= (others => '0');
		elsif (TC_RD_EN_IN = '1' and term_ctr /= 33 and term_ctr /= 0) then
			termination(255 downto 8) <= termination(247 downto 0);			
		else
			termination(255 downto 8) <= termination(255 downto 8);
		end if;
	end if;
end process TERMINATION_PROC;

term_bits_gen : for I in 0 to 7 generate
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (TC_RD_EN_IN = '1' and term_ctr /= 33 and term_ctr /= 0) then
				case (load_current_state) is
					when LOAD_Q_HEADERS => termination(I) <= qsf_q(I);
					when LOAD_SUB  => termination(I) <= shf_q(I);
					when LOAD_DATA => termination(I) <= df_q(I);
					when others    => termination(I) <= '0';
				end case;
			else
				termination(I) <= termination(I);
			end if;
		end if;
	end process;
end generate term_bits_gen;

TERM_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			term_ctr <= 0;
		elsif (TC_RD_EN_IN = '1' and term_ctr /= 33) then
			term_ctr <= term_ctr + 1;
		end if;
	end if;
end process TERM_CTR_PROC;

TC_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		case (load_current_state) is
			when LOAD_Q_HEADERS => tc_data <= qsf_q; 
			when LOAD_SUB       => tc_data <= shf_q;
			when LOAD_DATA      => tc_data <= df_q;
			when LOAD_PADDING   => tc_data <= x"aa";
			when LOAD_TERM      => tc_data <= termination((header_ctr + 1) * 8 - 1 downto  header_ctr * 8);
			when others         => tc_data <= x"cc";
		end case;
	end if;
end process TC_DATA_PROC;

TC_DATA_OUT(7 downto 0) <= tc_data;
TC_DATA_8_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = LOAD_TERM and header_ctr = 0) then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
	end if;	
end process TC_DATA_8_PROC;

--*****
-- outputs



DEBUG_OUT <= (others => '0');

end architecture RTL;
