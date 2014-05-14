LIBRARY ieee;

use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity gbe_ipu_dummy is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		FIXED_SIZE_MODE : integer range 0 to 1 := 1;
		FIXED_SIZE : integer range 0 to 65535 := 10;
		FIXED_DELAY_MODE : integer range 0 to 1 := 1;
		FIXED_DELAY : integer range 0 to 65535 := 4096
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		GBE_READY_IN : in std_logic;
		
		CTS_NUMBER_OUT				: out	std_logic_vector (15 downto 0);
		CTS_CODE_OUT					: out	std_logic_vector (7  downto 0);
		CTS_INFORMATION_OUT			: out	std_logic_vector (7  downto 0);
		CTS_READOUT_TYPE_OUT			: out	std_logic_vector (3  downto 0);
		CTS_START_READOUT_OUT		: out	std_logic;
		CTS_DATA_IN				: in	std_logic_vector (31 downto 0);
		CTS_DATAREADY_IN			: in	std_logic;
		CTS_READOUT_FINISHED_IN	: in	std_logic;
		CTS_READ_OUT					: out	std_logic;
		CTS_LENGTH_IN				: in	std_logic_vector (15 downto 0);
		CTS_ERROR_PATTERN_IN		: in	std_logic_vector (31 downto 0);
		-- Data payload interface
		FEE_DATA_OUT					: out	std_logic_vector (15 downto 0);
		FEE_DATAREADY_OUT			: out	std_logic;
		FEE_READ_IN				: in	std_logic;
		FEE_STATUS_BITS_OUT			: out	std_logic_vector (31 downto 0);
		FEE_BUSY_OUT					: out	std_logic
	);
end entity gbe_ipu_dummy;

architecture RTL of gbe_ipu_dummy is
	
	component random_size is
    port (
        Clk: in  std_logic; 
        Enb: in  std_logic; 
        Rst: in  std_logic; 
        Dout: out  std_logic_vector(31 downto 0));
	end component;
	
	type states is (IDLE, TIMEOUT, CTS_START, FEE_START, WAIT_FOR_READ_1, WAIT_A_SEC_1, WAIT_FOR_READ_2, WAIT_A_SEC_2, WAIT_FOR_READ_3, WAIT_A_SEC_3, 
					WAIT_FOR_READ_4, WAIT_A_SEC_4, WAIT_FOR_READ_5, WAIT_A_SEC_5, WAIT_FOR_READ_6, WAIT_A_SEC_6, CLOSE
	, LOOP_OVER_DATA, SEND_ONE_WORD, WAIT_A_SEC_7, LOWER_BUSY, WAIT_A_SEC_8, WAIT_A_SEC_9, PULSE_WITH_READ);
	signal current_state, next_state : states;
	
	signal ctr : integer range 0 to 65535 := 0;
	signal timeout_stop : integer range 0 to 65535 := 4096;
	signal pause_cts_fee : integer range 0 to 65535 := 8;
	signal pause_dready : integer range 0 to 65535 := 3;
	signal pause_wait_1, pause_wait_2, pause_wait_3, pause_wait_4, pause_wait_5, pause_wait_6, send_word_pause, pause_wait_7, pause_wait_8, pause_wait_9 : integer range 0 to 10 := 4;
	signal cts_start_readout, fee_busy, fee_dready, cts_read : std_logic;
	signal cts_number, fee_data, test_data_len : std_logic_vector(15 downto 0);
	signal data_ctr : std_logic_vector(16 downto 0);
	signal size_rand_en, delay_rand_en : std_logic;
	signal delay_value : std_logic_vector(15 downto 0);
	signal d, s : std_logic_vector(31 downto 0);
	
begin
	
	
	fixed_size_gen : if FIXED_SIZE_MODE = 1 generate
		test_data_len <= std_logic_vector(to_unsigned(FIXED_SIZE, 16));
	end generate fixed_size_gen;
	
	variable_size_gen : if FIXED_SIZE_MODE = 0 generate
		
		size_rand_inst : random_size
		port map(Clk  => clk,
		     Enb  => size_rand_en,
		     Rst  => rst,
		     Dout => s);
		     
		test_data_len <= s(15 downto 0);
		     
		process(clk)
		begin
			if rising_edge(clk) then
				if (current_state = TIMEOUT and ctr = timeout_stop) then
					size_rand_en <= '1';
				else
					size_rand_en <= '0';
				end if;
			end if;
		end process;
		
	end generate variable_size_gen;
	
	fixed_delay_gen : if FIXED_DELAY_MODE = 1 generate
		timeout_stop <= FIXED_DELAY when DO_SIMULATION = 0 else 100;
	end generate fixed_delay_gen;
	
	variable_delay_gen : if FIXED_DELAY_MODE = 0 generate
		
		delay_rand_inst : random_size
		port map(Clk  => clk,
		     Enb  => delay_rand_en,
		     Rst  => rst,
		     Dout => d);
		     
		     delay_value <= d(31 downto 16);
		     
		process(clk)
		begin
			if rising_edge(clk) then
				if (current_state = IDLE and GBE_READY_IN = '1') then
					delay_rand_en <= '1';
				else
					delay_rand_en <= '0';
				end if;
			end if;
		end process;
		
		timeout_stop <= to_integer(unsigned(delay_value));
		     
	end generate variable_delay_gen;
	
	
	CTS_INFORMATION_OUT <= x"d2";
	CTS_READOUT_TYPE_OUT <= x"1";
	CTS_CODE_OUT <= x"aa";
	CTS_START_READOUT_OUT <= cts_start_readout;
	CTS_READ_OUT <= cts_read;
	FEE_BUSY_OUT <= fee_busy;
	FEE_DATAREADY_OUT <= fee_dready;
	FEE_DATA_OUT <= fee_data;
	
	state_machine_proc : process (clk, rst) is
	begin
		if rst = '1' then
			current_state <= IDLE;
		elsif rising_edge(clk) then
			current_state <= next_state;
		end if;
	end process state_machine_proc;
	
	state_machine : process (current_state, GBE_READY_IN, ctr, timeout_stop, pause_dready, pause_cts_fee, FEE_READ_IN, pause_wait_6, pause_wait_5, 
								pause_wait_4, pause_wait_3, pause_wait_2, pause_wait_1, send_word_pause, data_ctr, test_data_len, pause_wait_7, pause_wait_8, pause_wait_9
	) is
	begin
		case current_state is 
		when IDLE =>
			if (GBE_READY_IN = '1') then
				next_state <= TIMEOUT;
			else
				next_state <= IDLE;
			end if;
			
		when TIMEOUT =>
			if (ctr = timeout_stop) then
				next_state <= CTS_START;
			else
				next_state <= TIMEOUT;
			end if;
			
		when CTS_START =>
			if (ctr = pause_cts_fee) then
				next_state <= FEE_START;
			else
				next_state <= CTS_START;
			end if;
			
		when FEE_START =>
			if (ctr = pause_dready) then
				next_state <= WAIT_FOR_READ_1;
			else
				next_state <= FEE_START;
			end if;
			
		when WAIT_FOR_READ_1 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_1;
			else
				next_state <= WAIT_FOR_READ_1;
			end if;
		
		when WAIT_A_SEC_1 =>
			if (ctr = pause_wait_1) then
				next_state <= WAIT_FOR_READ_2;
			else
				next_state <= WAIT_A_SEC_1;
			end if;
			
		when WAIT_FOR_READ_2 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_2;
			else
				next_state <= WAIT_FOR_READ_2;
			end if;
			
		when WAIT_A_SEC_2 =>
			if (ctr = pause_wait_2) then
				next_state <= WAIT_FOR_READ_3;
			else
				next_state <= WAIT_A_SEC_2;
			end if;
			
		when WAIT_FOR_READ_3 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_3;
			else
				next_state <= WAIT_FOR_READ_3;
			end if;
			
		when WAIT_A_SEC_3 =>
			if (ctr = pause_wait_3) then
				next_state <= WAIT_FOR_READ_4;
			else
				next_state <= WAIT_A_SEC_3;
			end if;
			
		when WAIT_FOR_READ_4 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_4;
			else
				next_state <= WAIT_FOR_READ_4;
			end if;	
		
		when WAIT_A_SEC_4 =>
			if (ctr = pause_wait_4) then
				next_state <= WAIT_FOR_READ_5;
			else
				next_state <= WAIT_A_SEC_4;
			end if;	
			
		when WAIT_FOR_READ_5 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_5;
			else
				next_state <= WAIT_FOR_READ_5;
			end if;
			
		when WAIT_A_SEC_5 =>
			if (ctr = pause_wait_5) then
				next_state <= WAIT_FOR_READ_6;
			else
				next_state <= WAIT_A_SEC_5;
			end if;
			
		when WAIT_FOR_READ_6 =>
			if (FEE_READ_IN = '1') then
				next_state <= WAIT_A_SEC_6;
			else
				next_state <= WAIT_FOR_READ_6;
			end if;	
		
		when WAIT_A_SEC_6 =>
			if (ctr = pause_wait_6) then
				next_state <= LOOP_OVER_DATA;
			else
				next_state <= WAIT_A_SEC_6;
			end if;	
			
		when LOOP_OVER_DATA =>
			if (to_integer(unsigned(data_ctr)) = (2 * (to_integer(unsigned(test_data_len)) - 1)) + 2) then
				next_state <= WAIT_A_SEC_7;
			else
				next_state <= SEND_ONE_WORD;
			end if;
		
		when SEND_ONE_WORD => 
			if (ctr = send_word_pause) then
				next_state <= LOOP_OVER_DATA;
			else
				next_state <= SEND_ONE_WORD;
			end if;
			
		when WAIT_A_SEC_7 =>
			if (ctr = pause_wait_7) then
				next_state <= LOWER_BUSY;
			else
				next_state <= WAIT_A_SEC_7;
			end if;
			
		when LOWER_BUSY =>
			next_state <= WAIT_A_SEC_8;
		
		when WAIT_A_SEC_8 =>
			if (ctr = pause_wait_8) then
				next_state <= PULSE_WITH_READ;
			else
				next_state <= WAIT_A_SEC_8;
			end if;
			
		when PULSE_WITH_READ =>
			next_state <= WAIT_A_SEC_9;
		
		when WAIT_A_SEC_9 =>
			if (ctr = pause_wait_9) then
				next_state <= CLOSE;
			else
				next_state <= WAIT_A_SEC_9;
			end if;	
			
		when CLOSE =>
			next_state <= IDLE;
			
		end case;	
	end process state_machine;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				data_ctr <= (others => '0');
			elsif (current_state = LOOP_OVER_DATA) then
				data_ctr <= data_ctr + x"1";
			else
				data_ctr <= data_ctr;
			end if;
		end if;
	end process;			
	
	ctr_proc : process(clk)
	begin
		if rising_edge(clk) then
			
			ctr <= ctr;
			
			case current_state is 
				when IDLE =>
					ctr <= 0;
				when TIMEOUT =>
					if ctr /= timeout_stop then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when CTS_START =>
					if (ctr /= pause_cts_fee) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when FEE_START =>
					if (ctr /= pause_dready) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_1 =>
					if (ctr /= pause_wait_1) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_2 =>
					if (ctr /= pause_wait_2) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_3 =>
					if (ctr /= pause_wait_3) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_4 =>
					if (ctr /= pause_wait_4) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_5 =>
					if (ctr /= pause_wait_5) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_6 =>
					if (ctr /= pause_wait_6) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when SEND_ONE_WORD => 
					if (ctr /= send_word_pause) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_7 =>
					if (ctr /= pause_wait_7) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_8 =>
					if (ctr /= pause_wait_8) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
				when WAIT_A_SEC_9 =>
					if (ctr /= pause_wait_9) then
						ctr <= ctr + 1;
					else
						ctr <= 0;
					end if;
					
				when others =>
					ctr <= ctr;
			end case;
		end if;
	end process ctr_proc;	
		

	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				cts_start_readout <= '0';
			elsif (current_state = CTS_START and ctr = 0) then
				cts_start_readout <= '1';
			elsif (current_state = CLOSE) then
				cts_start_readout <= '0';
			else
				cts_start_readout <= cts_start_readout;
			end if;
		end if;
	end process;

	process(rst, CLK)
	begin
		if rst = '1' then
			cts_number <= x"0001";
		elsif rising_edge(CLK) then
			if (current_state = CLOSE) then
				cts_number <= cts_number + x"1";
			else
				cts_number <= cts_number;
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				fee_busy <= '0';
			elsif (current_state = FEE_START and ctr = 0) then
				fee_busy <= '1';
			elsif (current_state = LOWER_BUSY) then
				fee_busy <= '0'; 
			else
				fee_busy <= fee_busy;
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = WAIT_FOR_READ_1) then
				fee_dready <= '1';
			elsif (current_state = WAIT_FOR_READ_2) then
				fee_dready <= '1';
			elsif (current_state = WAIT_FOR_READ_3) then
				fee_dready <= '1';
			elsif (current_state = WAIT_FOR_READ_4) then
				fee_dready <= '1';
			elsif (current_state = WAIT_FOR_READ_5) then
				fee_dready <= '1';
			elsif (current_state = WAIT_FOR_READ_6) then
				fee_dready <= '1';
			elsif (current_state = SEND_ONE_WORD and ctr = send_word_pause) then
				fee_dready <= '1'; 
			else
				fee_dready <= '0';
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			case current_state is 
				when WAIT_FOR_READ_1 =>
					fee_data <= x"10aa";
				when WAIT_FOR_READ_2 =>
					fee_data <= cts_number;
				when WAIT_FOR_READ_3 =>
					fee_data <= test_data_len + x"1";
				when WAIT_FOR_READ_4 =>
					fee_data <= x"ff21";
				when WAIT_FOR_READ_5 =>
					fee_data <= test_data_len;
				when WAIT_FOR_READ_6 =>
					fee_data <= x"ff22";
				when SEND_ONE_WORD =>
					fee_data <= data_ctr(15 downto 0);
				when others =>
					fee_data <= x"12bc";
			end case;
		end if;
	end process;
			
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (current_state = IDLE) then
				cts_read <= '0';
			elsif (current_state = PULSE_WITH_READ) then
				cts_read <= '1';
			else
				cts_read <= '0';
			end if;
		end if;
	end process;

end architecture RTL;
