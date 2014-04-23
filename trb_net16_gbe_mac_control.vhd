LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

--********
-- configures TriSpeed MAC and signalizes when it's ready
-- used also to filter out frames with different addresses
-- after main configuration (by setting TsMAC filtering accordingly)



entity trb_net16_gbe_mac_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	MC_TSMAC_READY_OUT	: out	std_logic;
	MC_RECONF_IN		: in	std_logic;
	MC_GBE_EN_IN		: in	std_logic;
	MC_RX_DISCARD_FCS	: in	std_logic;
	MC_PROMISC_IN		: in	std_logic;
	MC_MAC_ADDR_IN		: in	std_logic_vector(47 downto 0);

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HDATA_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HCS_N_OUT		: out	std_logic;
	TSM_HWRITE_N_OUT	: out	std_logic;
	TSM_HREAD_N_OUT		: out	std_logic;
	TSM_HREADY_N_IN		: in	std_logic;
	TSM_HDATA_EN_N_IN	: in	std_logic;

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_mac_control;


architecture trb_net16_gbe_mac_control of trb_net16_gbe_mac_control is

attribute syn_encoding : string;

type mac_conf_states is (IDLE, DISABLE, WRITE_TX_RX_CTRL1, WRITE_TX_RX_CTRL2, ENABLE, READY);
signal mac_conf_current_state, mac_conf_next_state : mac_conf_states;
attribute syn_encoding of mac_conf_current_state : signal is "onehot";

signal tsmac_ready                          : std_logic;
signal reg_mode                             : std_logic_vector(7 downto 0);
signal reg_tx_rx_ctrl1, reg_tx_rx_ctrl2     : std_logic_vector(7 downto 0);
signal reg_max_pkt_size                     : std_logic_vector(15 downto 0);
signal reg_ipg                              : std_logic_vector(15 downto 0);
signal reg_mac0                             : std_logic_vector(15 downto 0);
signal reg_mac1                             : std_logic_vector(15 downto 0);
signal reg_mac2                             : std_logic_vector(15 downto 0);

signal haddr                                : std_logic_vector(7 downto 0);
signal hcs_n                                : std_logic;
signal hwrite_n                             : std_logic;
signal hdata_pointer                        : integer range 0 to 1;
signal state                                : std_logic_vector(3 downto 0);
signal hready_n_q                           : std_logic;

begin

reg_mode(7 downto 4)  <= x"0";
reg_mode(3)           <= '1'; -- tx_en
reg_mode(2)           <= '1'; -- rx_en
reg_mode(1)           <= '1'; -- flow_control en
reg_mode(0)           <= MC_GBE_EN_IN; -- gbe en

reg_tx_rx_ctrl2(7 downto 1) <= (others => '0'); -- reserved
reg_tx_rx_ctrl2(0)           <= '1'; -- receive short
reg_tx_rx_ctrl1(7)           <= '1'; -- receive broadcast
reg_tx_rx_ctrl1(6)           <= '1'; -- drop control
reg_tx_rx_ctrl1(5)           <= '0'; -- half_duplex en 
reg_tx_rx_ctrl1(4)           <= '1'; -- receive multicast
reg_tx_rx_ctrl1(3)           <= '1'; -- receive pause
reg_tx_rx_ctrl1(2)           <= '0'; -- transmit disable FCS
reg_tx_rx_ctrl1(1)           <= '1'; -- receive discard FCS and padding
reg_tx_rx_ctrl1(0)           <= MC_PROMISC_IN; -- promiscuous mode


MAC_CONF_MACHINE_PROC : process(CLK)
begin
	if RESET = '1' then
		mac_conf_current_state <= IDLE;
  elsif rising_edge(CLK) then
--    if (RESET = '1') then
--      mac_conf_current_state <= IDLE;
--    else
      mac_conf_current_state <= mac_conf_next_state;
--    end if;
  end if;
end process MAC_CONF_MACHINE_PROC;

MAC_CONF_MACHINE : process(mac_conf_current_state, MC_RECONF_IN, TSM_HREADY_N_IN)
begin

  case mac_conf_current_state is

    when IDLE =>
    	if (MC_RECONF_IN = '1') then
			mac_conf_next_state <= DISABLE;
		else
			mac_conf_next_state <= IDLE;
		end if;

    when DISABLE =>
    	if (TSM_HREADY_N_IN = '0') then
			mac_conf_next_state <= WRITE_TX_RX_CTRL1;
		else
			mac_conf_next_state <= DISABLE;
		end if;
		
    when WRITE_TX_RX_CTRL1 =>
    	if (TSM_HREADY_N_IN = '0') then
			mac_conf_next_state <= WRITE_TX_RX_CTRL2;
		else
			mac_conf_next_state <= WRITE_TX_RX_CTRL1;
		end if;
		
	when WRITE_TX_RX_CTRL2 =>
		if (TSM_HREADY_N_IN = '0') then
			mac_conf_next_state <= ENABLE;
		else
			mac_conf_next_state <= WRITE_TX_RX_CTRL2;
		end if;	

    when ENABLE =>
    	if (TSM_HREADY_N_IN = '0') then
			mac_conf_next_state <= READY;
		else
			mac_conf_next_state <= ENABLE;
		end if;

    when READY =>
    	if (MC_RECONF_IN = '1') then
			mac_conf_next_state <= DISABLE;
		else
			mac_conf_next_state <= READY;
		end if;			

  end case;

end process MAC_CONF_MACHINE;

HADDR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
   		case mac_conf_current_state is 
   			when IDLE =>
   				TSM_HADDR_OUT <= x"00";
   			when DISABLE =>
   				TSM_HADDR_OUT <= x"00";
   			when WRITE_TX_RX_CTRL1 =>
   				TSM_HADDR_OUT <= x"02";
   			when WRITE_TX_RX_CTRL2 =>
   				TSM_HADDR_OUT <= x"03";
   			when ENABLE =>
   				TSM_HADDR_OUT <= x"00";
   			when READY =>
   				TSM_HADDR_OUT <= x"00";
   		end case;
	end if;
end process HADDR_PROC;

HDATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		case mac_conf_current_state is 
			when IDLE =>
				TSM_HDATA_OUT <= x"00";
			when DISABLE =>
				TSM_HDATA_OUT <= x"00";
			when WRITE_TX_RX_CTRL1 =>
				TSM_HDATA_OUT <= reg_tx_rx_ctrl1;
			when WRITE_TX_RX_CTRL2 =>
				TSM_HDATA_OUT <= reg_tx_rx_ctrl2;
			when ENABLE =>
				TSM_HDATA_OUT <= reg_mode;
			when READY =>
				TSM_HDATA_OUT <= x"00";
		end case;
	end if;
end process HDATA_PROC;

process(CLK)
begin
	if rising_edge(CLK) then
		if (mac_conf_current_state = IDLE or mac_conf_current_state = READY) then
			hcs_n    <= '1';
			hwrite_n <= '1';
		elsif (TSM_HREADY_N_IN = '1') then
			hcs_n <= '0';
			hwrite_n <= '0';
		else
			hcs_n <= '1';
			hwrite_n <= '1';
		end if;
		
		if (mac_conf_current_state = READY) then
			tsmac_ready <= '1';
		else
			tsmac_ready <= '0';
		end if;
	end if;
end process;

TSM_HCS_N_OUT      <= hcs_n;
TSM_HWRITE_N_OUT   <= hwrite_n;
TSM_HREAD_N_OUT    <= '1';
MC_TSMAC_READY_OUT <= tsmac_ready;


end trb_net16_gbe_mac_control;


