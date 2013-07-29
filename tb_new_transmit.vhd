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

ENTITY testbench_new_transmit IS
END testbench_new_transmit;

ARCHITECTURE behavior OF testbench_new_transmit IS

component test_data_source is
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
end component;

component trb_net16_gbe_transmit_control2 is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	TC_DATAREADY_IN        : in 	std_logic;
	TC_RD_EN_OUT		        : out	std_logic;
	TC_DATA_IN		        : in	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	TC_SIZE_LEFT_IN        : in	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_IN	    : in	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);

-- signal to/from frame constructor
	FC_DATA_OUT		     : out	std_logic_vector(7 downto 0);
	FC_WR_EN_OUT		 : out	std_logic;
	FC_READY_IN		     : in	std_logic;
	FC_H_READY_IN		 : in	std_logic;
	FC_FRAME_TYPE_OUT	 : out	std_logic_vector(15 downto 0);
	FC_IP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_UDP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_IDENT_OUT		 : out	std_logic_vector(15 downto 0);  -- internal packet counter
	FC_FLAGS_OFFSET_OUT	 : out	std_logic_vector(15 downto 0);
	FC_SOD_OUT		     : out	std_logic;
	FC_EOD_OUT		     : out	std_logic;
	FC_IP_PROTOCOL_OUT	 : out	std_logic_vector(7 downto 0);

	DEST_MAC_ADDRESS_OUT : out    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_OUT  : out    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_OUT    : out    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_OUT  : out    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_OUT   : out    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_OUT     : out    std_logic_vector(15 downto 0);

-- debug
	DEBUG_OUT		     : out	std_logic_vector(63 downto 0)
);
end component;

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
signal tc_data, tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_frame_size, tc_size_left, tc_frame_type, tc_flags, tc_ident : std_logic_vector(15 downto 0);


begin

data_src : test_data_source
port map(
	CLK			            => clk,
	RESET			        => reset,

	TC_DATAREADY_OUT        => tc_dataready,
	TC_RD_EN_IN		        => tc_rd_en,
	TC_DATA_OUT		        => tc_data,
	TC_FRAME_SIZE_OUT	    => tc_frame_size,
	TC_SIZE_LEFT_OUT        => tc_size_left,
	TC_FRAME_TYPE_OUT	    => tc_frame_type,
	TC_IP_PROTOCOL_OUT	    => tc_ip_proto,	
	TC_DEST_MAC_OUT		    => tc_dest_mac,
	TC_DEST_IP_OUT		    => tc_dest_ip,
	TC_DEST_UDP_OUT		    => tc_dest_udp,
	TC_SRC_MAC_OUT		    => tc_src_mac,
	TC_SRC_IP_OUT		    => tc_src_ip,
	TC_SRC_UDP_OUT		    => tc_src_udp,
	TC_FLAGS_OFFSET_OUT	    => tc_flags,
	TC_TRANSMISSION_DONE_IN => tc_done,
	TC_IDENT_OUT            => tc_ident
);

transmit_controller : trb_net16_gbe_transmit_control2
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signal to/from main controller
	TC_DATAREADY_IN        => tc_dataready,
	TC_RD_EN_OUT		        => tc_rd_en,
	TC_DATA_IN		        => tc_data,
	TC_FRAME_SIZE_IN	    => tc_frame_size,
	TC_SIZE_LEFT_IN        => tc_size_left,
	TC_FRAME_TYPE_IN	    => tc_frame_type,
	TC_IP_PROTOCOL_IN	    => tc_ip_proto,	
	TC_DEST_MAC_IN		    => tc_dest_mac,
	TC_DEST_IP_IN		    => tc_dest_ip,
	TC_DEST_UDP_IN		    => tc_dest_udp,
	TC_SRC_MAC_IN		    => tc_src_mac,
	TC_SRC_IP_IN		    => tc_src_ip,
	TC_SRC_UDP_IN		    => tc_src_udp,
	TC_FLAGS_OFFSET_IN	    => tc_flags,
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
begin
	
	wait;

end process testbench_proc;

end; 