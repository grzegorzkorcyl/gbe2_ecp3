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
	PC_MAX_QUEUE_SIZE_IN    : in    std_logic_vector(31 downto 0);
	PC_DELAY_IN             : in	std_logic_vector(31 downto 0);  -- gk 28.04.10
	-- FrameConstructor ports
	TC_RD_EN_IN             : in    std_logic;
	TC_DATA_OUT             : out   std_logic_vector(7 downto 0);
	TC_H_READY_IN           : in    std_logic;
	TC_READY_IN             : in    std_logic;
	TC_IP_SIZE_OUT          : out   std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT         : out   std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT     : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	TC_EOD_OUT              : out   std_logic;
	TC_DATA_NOT_VALID_OUT   : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end entity trb_net16_gbe_event_constr;

architecture RTL of trb_net16_gbe_event_constr is

type saveStates is (IDLE, SAVE_DATA, CLEANUP);
signal save_current_state, save_next_state : saveStates;

type loadStates is (IDLE, WAIT_FOR_FC, PUT_Q_LEN, PUT_Q_DEC, LOAD_DATA, LOAD_SUB, LOAD_PADDING, LOAD_TERM, CLOSE_FRAME, DIVIDE, CLEANUP);
signal load_current_state, load_next_state : loadStates;

type saveSubHdrStates is (IDLE, SAVE_SIZE, SAVE_DECODING, SAVE_ID, SAVE_TRG_NR);
signal save_sub_hdr_current_state, save_sub_hdr_next_state : saveSubHdrStates;

signal df_eod, df_wr_en, df_rd_en, df_empty, df_full, load_eod : std_logic;
signal df_q, df_qq : std_logic_vector(7 downto 0);
	
signal header_ctr : integer range 0 to 31;

signal shf_data, shf_q, shf_qq : std_logic_vector(7 downto 0);
signal shf_wr_en, shf_rd_en, shf_empty, shf_full : std_logic;
signal sub_int_ctr : integer range 0 to 3;
signal sub_size_to_save : std_logic_vector(31 downto 0);

signal fc_data : std_logic_vector(7 downto 0);

signal qsf_data, qsf_q, qsf_qq : std_logic_vector(31 downto 0);
signal qsf_wr_en, qsf_rd_en, qsf_rd_en_q, qsf_empty : std_logic;

signal queue_size : std_logic_vector(31 downto 0);

signal termination : std_logic_vector(255 downto 0);
signal term_ctr : integer range 0 to 32;
signal size_for_padding : std_logic_vector(7 downto 0);
signal loaded_bytes_frame, loaded_bytes_packet : std_logic_vector(15 downto 0);
signal divide_position : std_logic_vector(1 downto 0);

signal not_valid_ctr : integer range 0 to 7;

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

SAVE_MACHINE : process(save_current_state, PC_START_OF_SUB_IN, PC_END_OF_DATA_IN)
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
				save_next_state <= CLEANUP;
			else
				save_next_state <= SAVE_DATA;
			end if;
		
		when CLEANUP =>
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
		if (PC_WR_EN_IN = '1') then
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

DF_QQ_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		df_qq <= df_q;
	end if;
end process DF_QQ_PROC;

PC_READY_OUT <= '1' when save_current_state = IDLE and df_full = '0' else '0';

--*****
-- subevent headers

--TODO: exchange to a smaller fifo
SUBEVENT_HEADERS_FIFO : fifo_4kx8_ecp3
port map(
	Data        =>  shf_data,
	WrClock     =>  CLK,
	RdClock     =>  CLK,
	WrEn        =>  shf_wr_en,
	RdEn        =>  shf_rd_en,
	Reset       =>  RESET,
	RPReset     =>  RESET,
	Q           =>  shf_q,
	Empty       =>  shf_empty,
	Full        =>  shf_full
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

SHF_Q_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		shf_qq <= shf_q;
	end if;
end process SHF_Q_PROC;

SAVE_SUB_HDR_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			save_sub_hdr_current_state <= IDLE;
		else
			save_sub_hdr_current_state <= save_sub_hdr_next_state;
		end if;
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

SUB_SIZE_TO_SAVE_PROC : process (CLK) is
begin
	if rising_edge(CLK) then
		if (PC_PADDING_IN = '0') then
			sub_size_to_save <= PC_SUB_SIZE_IN + x"10";
		else
			sub_size_to_save <= PC_SUB_SIZE_IN + x"c";
		end if;
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
				shf_data <= PC_DECODING_IN(sub_int_ctr * 8 + 7 downto sub_int_ctr * 8);
			
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

QUEUE_SIZE_FIFO : fifo_512x32
port map(
	Data        =>  qsf_data,
	WrClock     =>  CLK,
	RdClock     =>  CLK,
	WrEn        =>  qsf_wr_en,
	RdEn        =>  qsf_rd_en_q,
	Reset       =>  RESET,
	RPReset     =>  RESET,
	Q           =>  qsf_q,
	Empty       =>  qsf_empty,
	Full        =>  open
);

qsf_data <= queue_size;

QSF_QQ_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		qsf_qq <= qsf_q;
	end if;
end process QSF_QQ_PROC;

QSF_WR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (MULT_EVT_ENABLE_IN = '1') then
			if (save_sub_hdr_current_state = SAVE_SIZE and sub_int_ctr = 0) then
				if (queue_size + x"10" + PC_SUB_SIZE_IN > PC_MAX_QUEUE_SIZE_IN) then
					qsf_wr_en <= '1';
				else
					qsf_wr_en <= '0';
				end if;
			else
				qsf_wr_en <= '0';
			end if;
		else
			if (PC_END_OF_DATA_IN = '1') then
				qsf_wr_en <= '1';
			else
				qsf_wr_en <= '0';
			end if; 
		end if;
	end if;
end process QSF_WR_PROC;

QUEUE_SIZE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (MULT_EVT_ENABLE_IN = '1') then
			if (save_sub_hdr_next_state = SAVE_DECODING and sub_int_ctr = 3) then
				queue_size <= x"0000_0000"; --queue_size <= x"0000_0028";
			elsif (save_sub_hdr_current_state = SAVE_DECODING and sub_int_ctr = 2) then
				if (PC_SUB_SIZE_IN(2) = '1') then
					queue_size <= queue_size + x"10" + PC_SUB_SIZE_IN + x"4" + x"8";
				else
					queue_size <= queue_size + x"10" + PC_SUB_SIZE_IN + x"8";
				end if;
			else
				queue_size <= queue_size;
			end if;
		else
			if (save_current_state = IDLE) then
				queue_size <= x"0000_0000"; --queue_size <= x"0000_0028";
			elsif (save_sub_hdr_current_state = SAVE_SIZE and sub_int_ctr = 0) then
				if (PC_SUB_SIZE_IN(2) = '1') then
					queue_size <= queue_size + x"10" + PC_SUB_SIZE_IN + x"4" + x"8";
				else
					queue_size <= queue_size + x"10" + PC_SUB_SIZE_IN + x"8";
				end if;
			end if;			
		end if;
	end if;
end process QUEUE_SIZE_PROC;



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

LOAD_MACHINE : process(load_current_state, size_for_padding, qsf_empty, TC_H_READY_IN, divide_position, header_ctr, load_eod, loaded_bytes_frame, PC_MAX_FRAME_SIZE_IN)
begin
	case (load_current_state) is
	
		when IDLE =>
			if (qsf_empty = '0') then -- something in queue sizes fifo means entire queue is waiting
				load_next_state <= WAIT_FOR_FC;
			else
				load_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_FC =>
			if (TC_H_READY_IN = '1') then
				load_next_state <= PUT_Q_LEN;
			else
				load_Next_state <= WAIT_FOR_FC;
			end if;
			
		when PUT_Q_LEN =>
			if (header_ctr = 0) then
				load_next_state <= PUT_Q_DEC;
			else
				load_next_state <= PUT_Q_LEN;
			end if;
			
		when PUT_Q_DEC =>
			if (header_ctr = 0) then
				load_next_state <= LOAD_SUB;
			else
				load_next_state <= PUT_Q_DEC;
			end if;
			
		when LOAD_SUB =>
			if (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
				load_next_state <= CLOSE_FRAME;
			else
				if (header_ctr = 0) then
					load_next_state <= LOAD_DATA;
				else
					load_next_state <= LOAD_SUB;
				end if;
			end if;
			
		when LOAD_DATA =>
			if (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
				load_next_state <= CLOSE_FRAME;
			else
				if (load_eod = '1') then
					if (size_for_padding(2) = '1') then
						load_next_state <= LOAD_PADDING;
					else
						load_next_state <= LOAD_TERM;
					end if;
				else
					load_next_state <= LOAD_DATA;
				end if;
			end if;
			
		when LOAD_PADDING =>
			if (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
				load_next_state <= CLOSE_FRAME;
			else
				if (header_ctr = 0) then
					load_next_state <= LOAD_TERM;
				else
					load_next_state <= LOAD_PADDING;
				end if;
			end if;
			
			
		when LOAD_TERM =>
			if (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
				load_next_state <= CLOSE_FRAME;
			else
				if (header_ctr = 0) then
					load_next_state <= CLEANUP;
				else
					load_next_state <= LOAD_TERM;
				end if;
			end if;			
			
		when CLOSE_FRAME =>
			load_next_state <= DIVIDE;
		
		when DIVIDE =>
			if (TC_H_READY_IN = '1') then
				if (divide_position = "00") then
					load_next_state <= LOAD_SUB;
				elsif (divide_position = "01") then
					load_next_state <= LOAD_DATA;
				elsif (divide_position = "10") then
					load_next_state <= LOAD_PADDING;
				elsif (divide_position = "11") then
					load_next_state <= LOAD_TERM;
				end if;				
			else
				load_next_state <= DIVIDE;
			end if;
		
		when CLEANUP =>
			load_next_state <= IDLE;
		
		when others => load_next_state <= IDLE;
		
	end case;
end process LOAD_MACHINE;

DIVIDE_POSITION_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
			case (load_current_state) is
				when LOAD_SUB     => divide_position <= "00";
				when LOAD_DATA    => divide_position <= "01";
				when LOAD_PADDING => divide_position <= "10";
				when LOAD_TERM    => divide_position <= "11";
				when others       => divide_position <= "00";
			end case;
		else
			divide_position <= divide_position;
		end if;
	end if;
end process DIVIDE_POSITION_PROC;

LOADED_BYTES_FRAME_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			loaded_bytes_frame <= (others => '0');
		elsif (loaded_bytes_frame = PC_MAX_FRAME_SIZE_IN) then
			loaded_bytes_frame <= (others => '0');
		elsif (load_current_state = CLOSE_FRAME or load_current_state = DIVIDE) then
			loaded_bytes_frame <= (others => '0');
		elsif (TC_RD_EN_IN = '1') then
			loaded_bytes_frame <= loaded_bytes_frame + x"1";
		else
			loaded_bytes_frame <= loaded_bytes_frame;
		end if;
	end if;
end process LOADED_BYTES_FRAME_PROC;

LOADED_BYTES_PACKET_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			loaded_bytes_packet <= (others => '0');
		elsif (TC_RD_EN_IN = '1') then
			loaded_bytes_packet <= loaded_bytes_packet + x"1";
		else
			loaded_bytes_packet <= loaded_bytes_packet;
		end if;
	end if;
end process LOADED_BYTES_PACKET_PROC;

HEADER_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			header_ctr <= 3;
		elsif (load_current_state = PUT_Q_LEN and header_ctr = 0) then
			header_ctr <= 3;
		elsif (load_current_state = PUT_Q_DEC and header_ctr = 0) then
			header_ctr <= 15;
		elsif (load_current_state = LOAD_SUB and header_ctr = 0) then
			if (size_for_padding(2) = '1') then
				header_ctr <= 3;
			else
				header_ctr <= 31;
			end if;
		elsif (load_current_state = LOAD_PADDING and header_ctr = 0) then
			header_ctr <= 31;
		elsif (load_current_state = LOAD_TERM and header_ctr = 0) then
			header_ctr <= 3;
		elsif (TC_RD_EN_IN = '1') then
			if (load_current_state = PUT_Q_LEN or load_current_state = PUT_Q_DEC or load_current_state = LOAD_SUB or load_current_state = LOAD_TERM or load_current_state = LOAD_PADDING) then
				header_ctr <= header_ctr - 1;
			else
				header_ctr <= header_ctr;
			end if;
		else
			header_ctr <= header_ctr;
		end if;
	end if;
end process HEADER_CTR_PROC;

SIZE_FOR_PADDING_PROC : process(CLK)
begin
	if (load_current_state = LOAD_SUB and header_ctr = 13) then
		size_for_padding <= shf_q;
	else
		size_for_padding <= size_for_padding;
	end if;
end process SIZE_FOR_PADDING_PROC;

TC_SOD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			TC_SOD_OUT <= '0';
		elsif (load_current_state = WAIT_FOR_FC) and (TC_READY_IN = '1') then
			TC_SOD_OUT <= '1';
		elsif (load_current_state = DIVIDE) and (TC_READY_IN = '1') then
			TC_SOD_OUT <= '1';
		else
			TC_SOD_OUT <= '0';
		end if;
	end if;
end process TC_SOD_PROC;

TC_EOD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			TC_EOD_OUT <= '0';
--		elsif (load_current_state = LOAD_DATA) and (load_eod = '1') then
--			TC_EOD_OUT <= '1';
		elsif (load_current_state = LOAD_TERM) and (header_ctr = 0) then
			TC_EOD_OUT <= '1';
		elsif (load_current_state = CLOSE_FRAME) then
			TC_EOD_OUT <= '1';
		else
			TC_EOD_OUT <= '0';
		end if;
	end if;
end process TC_EOD_PROC;

TC_DATA_NOT_VALID_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = LOAD_DATA and not_valid_ctr /= 3) then
			TC_DATA_NOT_VALID_OUT <= '1';
		else
			TC_DATA_NOT_VALID_OUT <= '0';
		end if;
	end if;
end process TC_DATA_NOT_VALID_PROC;

NOT_VALID_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (TC_RD_EN_IN = '1') then
			if (load_current_state = DIVIDE and divide_position = "01") then
				not_valid_ctr <= 0;
			elsif (load_current_state = LOAD_SUB) then
				not_valid_ctr <= 3;
			elsif (load_current_state = LOAD_DATA and not_valid_ctr /= 3) then
				not_valid_ctr <= not_valid_ctr + 1;
			else
				not_valid_ctr <= not_valid_ctr;
			end if;
		else
			not_valid_ctr <= not_valid_ctr;
		end if;
	end if;
end process NOT_VALID_CTR_PROC;

--*****
-- read from fifos

DATA_FIFO_RD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = LOAD_DATA and TC_RD_EN_IN = '1') then
			df_rd_en <= '1';
		elsif (load_current_state = LOAD_SUB and header_ctr = 0) then  -- preload the first word
			df_rd_en <= '1';
		elsif (load_current_state = LOAD_SUB and header_ctr = 1) then  -- preload the first word
			df_rd_en <= '1';
		elsif (load_current_state = LOAD_SUB and header_ctr = 2) then  -- preload the first word
			df_rd_en <= '1';
		elsif (load_current_state = LOAD_SUB and header_ctr = 3) then  -- preload the first word
			df_rd_en <= '1';
		else
			df_rd_en <= '0';
		end if;
	end if;
end process DATA_FIFO_RD_PROC;

SUB_FIFO_RD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = LOAD_SUB and TC_RD_EN_IN = '1') then
			shf_rd_en <= '1';
		elsif (load_current_state = PUT_Q_DEC and header_ctr = 2) then -- preload the first word
			shf_rd_en <= '1';
		elsif (load_current_state = PUT_Q_DEC and header_ctr = 1) then -- preload the first word
			shf_rd_en <= '1';
		elsif (load_current_state = PUT_Q_DEC and header_ctr = 0) then -- preload the first word
			shf_rd_en <= '1';
		else
			shf_rd_en <= '0';
		end if;
	end if;
end process SUB_FIFO_RD_PROC;

QUEUE_FIFO_RD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE and qsf_empty = '0') then
			qsf_rd_en <= '1';
		else
			qsf_rd_en <= '0';
		end if;
		
		qsf_rd_en_q <= qsf_rd_en;
	end if;
end process QUEUE_FIFO_RD_PROC;

TERMINATION_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			termination <= (others => '0');
		elsif (TC_RD_EN_IN = '1' and term_ctr /= 32) then
			termination(255 downto 8) <= termination(247 downto 0);
			
			for I in 0 to 7 loop
				case (load_current_state) is
					when PUT_Q_LEN => termination(I) <= qsf_qq(header_ctr * 8 + I);
					when PUT_Q_DEC => termination(I) <= PC_QUEUE_DEC_IN(header_ctr * 8 + I);
					when LOAD_SUB  => termination(I) <= shf_qq(I);
					when LOAD_DATA => termination(I) <= df_qq(I);
					when others    => termination(I) <= '0';
				end case;
			end loop;
			
		else
			termination <= termination;
		end if;
	end if;
end process TERMINATION_PROC;

TERM_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (load_current_state = IDLE) then
			term_ctr <= 0;
		elsif (TC_RD_EN_IN = '1' and term_ctr /= 32) then
			term_ctr <= term_ctr + 1;
		end if;
	end if;
end process TERM_CTR_PROC;

TC_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		case (load_current_state) is
			when PUT_Q_LEN    => TC_DATA_OUT <= qsf_qq((header_ctr + 1) * 8 - 1  downto header_ctr * 8);
			when PUT_Q_DEC    => TC_DATA_OUT <= PC_QUEUE_DEC_IN((header_ctr + 1) * 8 - 1  downto header_ctr * 8);
			when LOAD_SUB     => TC_DATA_OUT <= shf_qq;
			when LOAD_DATA    => TC_DATA_OUT <= df_qq;
			when LOAD_PADDING => TC_DATA_OUT <= x"aa";
			when LOAD_TERM    => TC_DATA_OUT <= termination((header_ctr + 1) * 8 - 1 downto  header_ctr * 8);
			when others       => TC_DATA_OUT <= df_qq; --(others => '0');
		end case;
	end if;
end process TC_DATA_PROC;

--*****
-- outputs

TC_PACKET_SIZES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_UDP_SIZE_OUT     <= qsf_qq(15 downto 0) + x"20";
	end if;
end process TC_PACKET_SIZES_PROC;

TC_FLAGS_OFFSET_PROC : process(CLK)
begin
	TC_FLAGS_OFFSET_OUT(15 downto 14) <= "00";

	if rising_edge(CLK) then
		if ((load_current_state = DIVIDE or load_current_state = WAIT_FOR_FC or load_current_state = PUT_Q_LEN) and loaded_bytes_frame = x"0000") then
			if ((qsf_qq + x"20" - loaded_bytes_packet) < PC_MAX_FRAME_SIZE_IN) then
				TC_FLAGS_OFFSET_OUT(13) <= '0';
			else
				TC_FLAGS_OFFSET_OUT(13) <= '1';
			end if;
			
			TC_FLAGS_OFFSET_OUT(12 downto 0) <= loaded_bytes_packet(15 downto 3);
		end if;
	end if;
end process TC_FLAGS_OFFSET_PROC;

TC_IP_SIZE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if ((load_current_state = DIVIDE or load_current_state = WAIT_FOR_FC or load_current_state = PUT_Q_LEN) and loaded_bytes_frame = x"0000") then
			if (qsf_qq + x"20" - loaded_bytes_packet >= PC_MAX_FRAME_SIZE_IN) then
				TC_IP_SIZE_OUT <= PC_MAX_FRAME_SIZE_IN;
			else
				TC_IP_SIZE_OUT <= qsf_qq(15 downto 0) + x"20" - loaded_bytes_packet;
			end if;		
		end if;
	end if;
end process TC_IP_SIZE_PROC;

PC_TRANSMIT_ON_OUT <= '0';

DEBUG_OUT <= (others => '0');

end architecture RTL;
