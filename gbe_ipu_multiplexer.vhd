LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;


entity gbe_ipu_multiplexer is
	generic (
		DO_SIMULATION : integer range 0 to 1 := 0;
		INCLUDE_DEBUG : integer range 0 to 1 := 0;
		
		NUMBER_OF_OUTPUT_LINKS : integer range 0 to 4 := 0
	);
	port (
		CLK_SYS_IN : in std_logic;
		RESET : in std_logic;
		
			-- CTS interface
		CTS_NUMBER_IN				: in	std_logic_vector (15 downto 0);
		CTS_CODE_IN					: in	std_logic_vector (7  downto 0);
		CTS_INFORMATION_IN			: in	std_logic_vector (7  downto 0);
		CTS_READOUT_TYPE_IN			: in	std_logic_vector (3  downto 0);
		CTS_START_READOUT_IN		: in	std_logic;
		CTS_DATA_OUT				: out	std_logic_vector (31 downto 0);
		CTS_DATAREADY_OUT			: out	std_logic;
		CTS_READOUT_FINISHED_OUT	: out	std_logic;
		CTS_READ_IN					: in	std_logic;
		CTS_LENGTH_OUT				: out	std_logic_vector (15 downto 0);
		CTS_ERROR_PATTERN_OUT		: out	std_logic_vector (31 downto 0);
			-- Data payload interface
		FEE_DATA_IN					: in	std_logic_vector (15 downto 0);
		FEE_DATAREADY_IN			: in	std_logic;
		FEE_READ_OUT				: out	std_logic;
		FEE_STATUS_BITS_IN			: in	std_logic_vector (31 downto 0);
		FEE_BUSY_IN					: in	std_logic;
		
			-- CTS interface
		MLT_CTS_NUMBER_OUT				: out	std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
		MLT_CTS_CODE_OUT				: out	std_logic_vector (8 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
		MLT_CTS_INFORMATION_OUT			: out	std_logic_vector (8 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
		MLT_CTS_READOUT_TYPE_OUT		: out	std_logic_vector (4 * NUMBER_OF_OUTPUT_LINKS - 1  downto 0);
		MLT_CTS_START_READOUT_OUT		: out	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_DATA_IN					: in	std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_DATAREADY_IN			: in	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_READOUT_FINISHED_IN		: in	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_READ_OUT				: out	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_LENGTH_IN				: in	std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_CTS_ERROR_PATTERN_IN		: in	std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
			-- Data payload interface
		MLT_FEE_DATA_OUT				: out	std_logic_vector (16 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_FEE_DATAREADY_OUT			: out	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_FEE_READ_IN					: in	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_FEE_STATUS_BITS_OUT			: out	std_logic_vector (32 * NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		MLT_FEE_BUSY_OUT				: out	std_logic_vector(NUMBER_OF_OUTPUT_LINKS - 1 downto 0);
		
		DEBUG_OUT : out std_logic_vector(127 downto 0)
	);
end entity gbe_ipu_multiplexer;

architecture RTL of gbe_ipu_multiplexer is
	
	signal client_ptr : integer range 0 to NUMBER_OF_OUTPUT_LINKS - 1 := 0;
	signal cts_readout, cts_readout_q : std_logic;
	
begin
	
	process(RESET, CLK_SYS_IN)
	begin
		if (RESET = '1') then
			client_ptr <= 0;
		elsif rising_edge(CLK_SYS_IN) then
			
			cts_readout   <= CTS_START_READOUT_IN;
			cts_readout_q <= cts_readout;
			
			if (cts_readout = '0' and cts_readout_q = '1' and client_ptr < NUMBER_OF_OUTPUT_LINKS - 1) then
				client_ptr <= client_ptr + 1;
			elsif (cts_readout = '0' and cts_readout_q = '1' and client_ptr = NUMBER_OF_OUTPUT_LINKS - 1) then
				client_ptr <= 0;
			else
				client_ptr <= client_ptr;
			end if;
			
		end if;
	end process;


	process(CLK_SYS_IN)
	begin
		if rising_edge(CLK_SYS_IN) then
			MLT_CTS_NUMBER_OUT(16 * (client_ptr + 1 ) - 1 downto 16 * client_ptr) <= CTS_NUMBER_IN;			
			MLT_CTS_CODE_OUT(8 * (client_ptr + 1 ) - 1 downto 8 * client_ptr) <= CTS_CODE_IN;
			MLT_CTS_INFORMATION_OUT(8 * (client_ptr + 1 ) - 1 downto 8 * client_ptr) <= CTS_INFORMATION_IN;
			MLT_CTS_READOUT_TYPE_OUT(4 * (client_ptr + 1 ) - 1 downto 4 * client_ptr) <= CTS_READOUT_TYPE_IN;
			MLT_CTS_START_READOUT_OUT(client_ptr) <= CTS_START_READOUT_IN;
			CTS_DATA_OUT <= MLT_CTS_DATA_IN(32 * (client_ptr + 1 ) - 1 downto 32 * client_ptr);				
			CTS_DATAREADY_OUT <= MLT_CTS_DATAREADY_IN(client_ptr);		
			CTS_READOUT_FINISHED_OUT <= MLT_CTS_READOUT_FINISHED_IN(client_ptr);
			MLT_CTS_READ_OUT(client_ptr) <= CTS_READ_IN;
			CTS_LENGTH_OUT <= MLT_CTS_LENGTH_IN(16 * (client_ptr + 1 ) - 1 downto 16 * client_ptr);
			CTS_ERROR_PATTERN_OUT <= MLT_CTS_ERROR_PATTERN_IN(32 * (client_ptr + 1 ) - 1 downto 32 * client_ptr);
			
			MLT_FEE_DATA_OUT(16 * (client_ptr + 1 ) - 1 downto 16 * client_ptr) <= FEE_DATA_IN;			
			MLT_FEE_DATAREADY_OUT(client_ptr) <= FEE_DATAREADY_IN;		
			FEE_READ_OUT <= MLT_FEE_READ_IN(client_ptr);
			MLT_FEE_STATUS_BITS_OUT(32 * (client_ptr + 1 ) - 1 downto 32 * client_ptr) <= FEE_STATUS_BITS_IN;
			MLT_FEE_BUSY_OUT(client_ptr) <= FEE_BUSY_IN;
		end if;
	end process;

end architecture RTL;			