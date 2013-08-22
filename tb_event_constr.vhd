LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.all;
USE ieee.numeric_std.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

ENTITY aa_tb_event_constr IS
END aa_tb_event_constr;

ARCHITECTURE behavior OF aa_tb_event_constr IS

signal clk, reset,RX_MAC_CLK : std_logic;
signal fc_data                   : std_logic_vector(7 downto 0);
signal fc_wr_en                  : std_logic;
signal fc_sod                    : std_logic;
signal fc_eod                    : std_logic;
signal fc_h_ready                : std_logic;
signal fc_ip_size                : std_logic_vector(15 downto 0);
signal fc_udp_size               : std_logic_vector(15 downto 0);
signal fc_ready                  : std_logic;
signal fc_dest_mac               : std_logic_vector(47 downto 0);
signal fc_dest_ip                : std_logic_vector(31 downto 0);
signal fc_dest_udp               : std_logic_vector(15 downto 0);
signal fc_src_mac                : std_logic_vector(47 downto 0);
signal fc_src_ip                 : std_logic_vector(31 downto 0);
signal fc_src_udp                : std_logic_vector(15 downto 0);
signal fc_type                   : std_logic_vector(15 downto 0);
signal fc_ihl                    : std_logic_vector(7 downto 0);
signal fc_tos                    : std_logic_vector(7 downto 0);
signal fc_ident                  : std_logic_vector(15 downto 0);
signal fc_flags                  : std_logic_vector(15 downto 0);
signal fc_ttl                    : std_logic_vector(7 downto 0);
signal fc_proto                  : std_logic_vector(7 downto 0);
signal tc_src_mac                : std_logic_vector(47 downto 0);
signal tc_dest_mac               : std_logic_vector(47 downto 0);
signal tc_src_ip                 : std_logic_vector(31 downto 0);
signal tc_dest_ip                : std_logic_vector(31 downto 0);
signal tc_src_udp                : std_logic_vector(15 downto 0);
signal tc_dest_udp               : std_logic_vector(15 downto 0);
signal tc_dataready, tc_rd_en, tc_done : std_logic;
signal tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_data : std_logic_vector(8 downto 0);
signal tc_frame_size, tc_size_left, tc_frame_type, tc_flags, tc_ident : std_logic_vector(15 downto 0);
signal response_ready, selected, dhcp_start, mc_busy : std_logic;

signal ps_data : std_logic_vector(8 downto 0);
signal ps_wr_en, ps_rd_en, ps_frame_ready : std_logic;
signal ps_proto, ps_busy : std_logic_vector(4 downto 0);
signal ps_frame_size : std_logic_vector(15 downto 0);

signal gsc_reply_dataready, gsc_busy : std_logic;
signal gsc_reply_data : std_logic_vector(15 downto 0);

SIGNAL CTS_NUMBER_IN :  std_logic_vector(15 downto 0);
SIGNAL CTS_CODE_IN :  std_logic_vector(7 downto 0);
SIGNAL CTS_INFORMATION_IN :  std_logic_vector(7 downto 0);
SIGNAL CTS_READOUT_TYPE_IN :  std_logic_vector(3 downto 0);
SIGNAL CTS_START_READOUT_IN :  std_logic;
SIGNAL CTS_DATA_OUT :  std_logic_vector(31 downto 0);
SIGNAL CTS_DATAREADY_OUT :  std_logic;
SIGNAL CTS_READOUT_FINISHED_OUT :  std_logic;
SIGNAL CTS_READ_IN :  std_logic;
SIGNAL CTS_LENGTH_OUT :  std_logic_vector(15 downto 0);
SIGNAL CTS_ERROR_PATTERN_OUT :  std_logic_vector(31 downto 0);
SIGNAL FEE_DATA_IN :  std_logic_vector(15 downto 0);
SIGNAL FEE_DATAREADY_IN :  std_logic;
SIGNAL FEE_READ_OUT :  std_logic;
SIGNAL FEE_STATUS_BITS_IN :  std_logic_vector(31 downto 0);
SIGNAL FEE_BUSY_IN :  std_logic;

begin

MAIN_CONTROL : trb_net16_gbe_main_control
  port map(
	  CLK			=> CLK,
	  CLK_125		=> RX_MAC_CLK,
	  RESET			=> RESET,

	  MC_LINK_OK_OUT	=> open,
	  MC_RESET_LINK_IN	=> '0',
	  MC_IDLE_TOO_LONG_OUT => open,

  -- signals to/from receive controller
	  RC_FRAME_WAITING_IN	=> ps_frame_ready,
	  RC_LOADING_DONE_OUT	=> open,
	  RC_DATA_IN		=> ps_data,
	  RC_RD_EN_OUT		=> ps_rd_en,
	  RC_FRAME_SIZE_IN	=> ps_frame_size,
	  RC_FRAME_PROTO_IN	=> ps_proto,

	RC_SRC_MAC_ADDRESS_IN	=> x"001122334455",
	RC_DEST_MAC_ADDRESS_IN  => x"001122334455",
	RC_SRC_IP_ADDRESS_IN	=> x"c0a80001",
	RC_DEST_IP_ADDRESS_IN	=> x"c0a80003",
	RC_SRC_UDP_PORT_IN	    => x"c350",
	RC_DEST_UDP_PORT_IN	    => x"c350",

	  -- signals to/from transmit controller
	  TC_TRANSMIT_CTRL_OUT	=> tc_dataready,
	  
	TC_DATA_OUT				=> tc_data,
	TC_RD_EN_IN				=> tc_rd_en,
	TC_FRAME_SIZE_OUT	    => tc_frame_size,
	TC_FRAME_TYPE_OUT	    => tc_frame_type,
	TC_IP_PROTOCOL_OUT	    => tc_ip_proto,
	TC_IDENT_OUT            => tc_ident,
	
	TC_DEST_MAC_OUT		    => tc_dest_mac,
	TC_DEST_IP_OUT		    => tc_dest_ip,
	TC_DEST_UDP_OUT		    => tc_dest_udp,
	TC_SRC_MAC_OUT		    => tc_src_mac,
	TC_SRC_IP_OUT		    => tc_src_ip,
	TC_SRC_UDP_OUT		    => tc_src_udp,
  	TC_TRANSMIT_DONE_IN		=> tc_done,

  -- signals to/from sgmii/gbe pcs_an_complete
	  PCS_AN_COMPLETE_IN	=> '1',

  -- signals to/from hub
	GSC_CLK_IN               => '0',
	GSC_INIT_DATAREADY_OUT   => open,
	GSC_INIT_DATA_OUT        => open,
	GSC_INIT_PACKET_NUM_OUT  => open,
	GSC_INIT_READ_IN         => '0',
	GSC_REPLY_DATAREADY_IN   => gsc_reply_dataready,
	GSC_REPLY_DATA_IN        => gsc_reply_data,
	GSC_REPLY_PACKET_NUM_IN  => (others => '0'),
	GSC_REPLY_READ_OUT       => open,
	GSC_BUSY_IN              => gsc_busy,

	MAKE_RESET_OUT           => open, --MAKE_RESET_OUT,

	CTS_NUMBER_IN				=> cts_number_in,
	CTS_CODE_IN					=> cts_code_in,
	CTS_INFORMATION_IN			=> cts_information_in,
	CTS_READOUT_TYPE_IN			=> cts_readout_type_in,
	CTS_START_READOUT_IN		=> cts_start_readout_in,
	CTS_DATA_OUT				=> cts_data_out,
	CTS_DATAREADY_OUT			=> cts_dataready_out,
	CTS_READOUT_FINISHED_OUT	=> cts_readout_finished_out,
	CTS_READ_IN					=> cts_read_in,
	CTS_LENGTH_OUT				=> cts_length_out,
	CTS_ERROR_PATTERN_OUT		=> cts_error_pattern_out,
	-- Data payload interface
	FEE_DATA_IN					=> fee_data_in,
	FEE_DATAREADY_IN			=> fee_dataready_in,
	FEE_READ_OUT				=> fee_read_out,
	FEE_STATUS_BITS_IN			=> fee_status_bits_in,
	FEE_BUSY_IN					=> fee_busy_in,
	-- ip configurator
	SLV_ADDR_IN                  => (others => '0'),
	SLV_READ_IN                  => '0',
	SLV_WRITE_IN                 => '0',
	SLV_BUSY_OUT                 => open,
	SLV_ACK_OUT                  => open,
	SLV_DATA_IN                  => (others => '0'),
	SLV_DATA_OUT                 => open,
	
	CFG_GBE_ENABLE_IN           => '0',
	CFG_IPU_ENABLE_IN           => '0',
	CFG_MULT_ENABLE_IN          => '0',
	
	MC_UNIQUE_ID_IN => (others => '0'),

  -- signal to/from Host interface of TriSpeed MAC
	  TSM_HADDR_OUT		=> open,
	  TSM_HDATA_OUT		=> open,
	  TSM_HCS_N_OUT		=> open,
	  TSM_HWRITE_N_OUT	=> open,
	  TSM_HREAD_N_OUT	=> open,
	  TSM_HREADY_N_IN	=> '0',
	  TSM_HDATA_EN_N_IN	=> '0',
	  TSM_RX_STAT_VEC_IN  => (others => '0'),
	  TSM_RX_STAT_EN_IN   => '0',
	  
	  SELECT_REC_FRAMES_OUT		=> open,
	  SELECT_SENT_FRAMES_OUT	=> open,
	  SELECT_PROTOS_DEBUG_OUT	=> open,

	  DEBUG_OUT		=> open
  );
  
transmit_controller : trb_net16_gbe_transmit_control2
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	TC_DATAREADY_IN        => tc_dataready,
	TC_RD_EN_OUT		        => tc_rd_en,
	TC_DATA_IN		        => tc_data(7 downto 0),
	TC_FRAME_SIZE_IN	    => tc_frame_size,
	TC_FRAME_TYPE_IN	    => tc_frame_type,
	TC_IP_PROTOCOL_IN	    => tc_ip_proto,	
	TC_DEST_MAC_IN		    => tc_dest_mac,
	TC_DEST_IP_IN		    => tc_dest_ip,
	TC_DEST_UDP_IN		    => tc_dest_udp,
	TC_SRC_MAC_IN		    => tc_src_mac,
	TC_SRC_IP_IN		    => tc_src_ip,
	TC_SRC_UDP_IN		    => tc_src_udp,
	TC_TRANSMISSION_DONE_OUT => tc_done,
	TC_IDENT_IN            => tc_ident,
	
-- signal to/from frame constructor
	FC_DATA_OUT		=> fc_data,
	FC_WR_EN_OUT		=> fc_wr_en,
	FC_READY_IN		=> fc_ready,
	FC_H_READY_IN		=> fc_h_ready,
	FC_FRAME_TYPE_OUT	=> fc_type,
	FC_IP_SIZE_OUT		=> fc_ip_size,
	FC_UDP_SIZE_OUT		=> fc_udp_size,
	FC_IDENT_OUT		=> fc_ident,
	FC_FLAGS_OFFSET_OUT	=> fc_flags,
	FC_SOD_OUT		=> fc_sod,
	FC_EOD_OUT		=> fc_eod,
	FC_IP_PROTOCOL_OUT	=> fc_proto,

	DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
	DEST_IP_ADDRESS_OUT     => fc_dest_ip,
	DEST_UDP_PORT_OUT       => fc_dest_udp,
	SRC_MAC_ADDRESS_OUT     => fc_src_mac,
	SRC_IP_ADDRESS_OUT      => fc_src_ip,
	SRC_UDP_PORT_OUT        => fc_src_udp,

	DEBUG_OUT		=> open
);

frame_constructor : trb_net16_gbe_frame_constr
port map( 
	-- ports for user logic
	RESET                   => RESET,
	CLK                     => CLK,
	LINK_OK_IN              => '1',
	--
	WR_EN_IN                => fc_wr_en,
	DATA_IN                 => fc_data,
	START_OF_DATA_IN        => fc_sod,
	END_OF_DATA_IN          => fc_eod,
	IP_F_SIZE_IN            => fc_ip_size,
	UDP_P_SIZE_IN           => fc_udp_size,
	HEADERS_READY_OUT       => fc_h_ready,
	READY_OUT               => fc_ready,
	DEST_MAC_ADDRESS_IN     => fc_dest_mac,
	DEST_IP_ADDRESS_IN      => fc_dest_ip,
	DEST_UDP_PORT_IN        => fc_dest_udp,
	SRC_MAC_ADDRESS_IN      => fc_src_mac,
	SRC_IP_ADDRESS_IN       => fc_src_ip,
	SRC_UDP_PORT_IN         => fc_src_udp,
	FRAME_TYPE_IN           => fc_type,
	IHL_VERSION_IN          => fc_ihl,
	TOS_IN                  => fc_tos,
	IDENTIFICATION_IN       => fc_ident,
	FLAGS_OFFSET_IN         => fc_flags,
	TTL_IN                  => fc_ttl,
	PROTOCOL_IN             => fc_proto,
	FRAME_DELAY_IN          => x"0000_0000",
	-- ports for packetTransmitter
	RD_CLK                  => RX_MAC_CLK,
	FT_DATA_OUT             => open,
	FT_TX_EMPTY_OUT         => open,
	FT_TX_RD_EN_IN          => '1',
	FT_START_OF_PACKET_OUT  => open,
	FT_TX_DONE_IN           => '1',
	FT_TX_DISCFRM_IN	=> '0',
	-- debug ports
	BSM_CONSTR_OUT          => open,
	BSM_TRANS_OUT           => open,
	DEBUG_OUT               => open
);


g_MAX_FRAME_SIZE <= x"0578";


-- 125 MHz MAC clock
CLOCK2_GEN_PROC: process
begin
	RX_MAC_CLK <= '1'; wait for 3.0 ns;
	RX_MAC_CLK <= '0'; wait for 4.0 ns;
end process CLOCK2_GEN_PROC;

-- 100 MHz system clock
CLOCK_GEN_PROC: process
begin
	CLK <= '1'; wait for 5.0 ns;
	CLK <= '0'; wait for 5.0 ns;
end process CLOCK_GEN_PROC;

testbench_proc : process
-- test data from TRBnet
variable test_data_len : integer range 0 to 65535 := 1;
variable test_loop_len : integer range 0 to 65535 := 0;
variable test_hdr_len : unsigned(15 downto 0) := x"0000";
variable test_evt_len : unsigned(15 downto 0) := x"0000";
variable test_data : unsigned(15 downto 0) := x"ffff";
variable test_data2 : unsigned(7 downto 0) := x"ff";

variable trigger_counter : unsigned(15 downto 0) := x"4710";
variable trigger_loop : integer range 0 to 65535 := 15;

-- 1400 bytes MTU => 350 as limit for fragmentation
variable max_event_size : real := 512.0;

variable seed1 : positive; -- seed for random generator
variable seed2 : positive; -- seed for random generator
variable rand : real; -- random value (0.0 ... 1.0)
variable int_rand : integer; -- random value, scaled to your needs
variable cts_random_number : std_logic_vector(7 downto 0);

variable stim : std_logic_vector(15 downto 0);
begin
	reset <= '1'; 
	
	cts_number_in <= x"0000";
	cts_code_in <= x"00";
	cts_information_in <= x"00";
	cts_readout_type_in <= x"0";
	cts_start_readout_in <= '0';
	cts_read_in <= '0';
	
	fee_data_in <= x"0000";
	fee_dataready_in <= '0';
	fee_status_bits_in <= x"1234_5678";
	fee_busy_in <= '0';
	
	gsc_reply_data <= (others => '0');
	gsc_busy <= '0';
	gsc_reply_dataready <= '0';
	
	wait for 100 ns;
	reset <= '0';
	
	wait for 1 us;
	
--		MY_TRIGGER_LOOP: for J in 0 to 0 loop
--		-- generate a real random byte for CTS
--		UNIFORM(seed1, seed2, rand);
--		int_rand := INTEGER(TRUNC(rand*256.0));
--		cts_random_number := std_logic_vector(to_unsigned(int_rand, cts_random_number'LENGTH));
--	
--		-- IPU transmission starts
--		wait until rising_edge(clk);
--		cts_number_in <= std_logic_vector( trigger_counter );
--		cts_code_in <= cts_random_number;
--		cts_information_in <= x"d2"; -- cts_information_in <= x"de"; -- gk 29.03.10
--		cts_readout_type_in <= x"1";
--		cts_start_readout_in <= '1';
--		wait until rising_edge(clk);
--		wait for 400 ns;
--
--		wait until rising_edge(clk);
--		fee_busy_in <= '1';
--		wait for 300 ns;
--		wait until rising_edge(clk);
--
--		-- ONE DATA TRANSMISSION
--		-- dice a length
--		UNIFORM(seed1, seed2, rand);
--		--test_data_len := INTEGER(TRUNC(rand * 800.0)) + 1;
--		
--		--test_data_len := 9685;
--		test_data_len := 182; --26; --100; -- + (1 - J) * 200;
--		
--		-- calculate the needed variables
--		test_loop_len := 2*(test_data_len - 1) + 1;
--		test_hdr_len := to_unsigned( test_data_len + 1, 16 );
--		test_evt_len := to_unsigned( test_data_len, 16 );
--
--		-- original data block (trigger 1, random 0xaa, number 0x4711, source 0x21)
--		fee_dataready_in <= '1';
--		fee_data_in <= x"10" & cts_random_number;
--		wait until rising_edge(clk) and (fee_read_out = '1'); -- transfer of first data word
--		fee_dataready_in <= '0';
--		wait until rising_edge(clk); -- BLA
--		wait until rising_edge(clk); -- BLA
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		fee_dataready_in <= '1';
--		fee_data_in <= std_logic_vector( trigger_counter );
--		wait until rising_edge(clk) and (fee_read_out = '1'); -- transfer of second data word
--		fee_dataready_in <= '0';
--		wait until rising_edge(clk); -- BLA
--		wait until rising_edge(clk); -- BLA
--		wait until rising_edge(clk); -- BLA
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		fee_dataready_in <= '1';
--		fee_data_in <= std_logic_vector( test_hdr_len );
--		wait until rising_edge(clk) and (fee_read_out = '1'); -- transfer of third data word
--		fee_data_in <= x"ff21";
--		wait until rising_edge(clk) and (fee_read_out = '1'); -- transfer of fourth data word
--		fee_dataready_in <= '0';
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		fee_dataready_in <= '1';
--		fee_data_in <= std_logic_vector( test_evt_len );
--		wait until rising_edge(clk) and (fee_read_out = '1');
--		fee_data_in <= x"ff22";	
--		wait until rising_edge(clk) and (fee_read_out = '1');
--		fee_dataready_in <= '0';
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--
--		test_data     := x"ffff";
--		MY_DATA_LOOP: for J in 0 to test_loop_len loop
--			test_data := test_data + 1;
--			wait until rising_edge(clk);
--			fee_data_in <= std_logic_vector(test_data); 
--			if( (test_data MOD 5) = 0 ) then
--				fee_dataready_in <= '0';
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				wait until rising_edge(clk);
--				fee_dataready_in <= '1';
--			else
--				fee_dataready_in <= '1';
--			end if;
-- 				--fee_dataready_in <= '1';
--		end loop MY_DATA_LOOP;
--		-- there must be padding words to get multiple of four LWs
--	
--		wait until rising_edge(clk);
--		fee_dataready_in <= '0';
--		fee_data_in <= x"0000";	
--
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		fee_busy_in <= '0';
--
--
--		trigger_loop    := trigger_loop + 1;
--		trigger_counter := trigger_counter + 1;
--
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		cts_read_in <= '1';
--		wait until rising_edge(clk);
--		cts_read_in <= '0';
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		cts_start_readout_in <= '0';
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);
--		wait until rising_edge(clk);	
--		
--		wait for 8 us;
		
		--wait for 10 us;

--	end loop MY_TRIGGER_LOOP;
	
-- REPLY TESTBENCH
	
	for k in 0 to 100 loop
	
		wait until rising_edge(clk);
		gsc_reply_dataready <= '1';
		gsc_busy <= '1';
		gsc_reply_data <= std_logic_vector(to_unsigned(k, 16));
			
	end loop;
	wait until rising_edge(clk);
	gsc_reply_dataready <= '0';
	gsc_busy <= '0';
		
	

	wait;

end process testbench_proc;

end; 