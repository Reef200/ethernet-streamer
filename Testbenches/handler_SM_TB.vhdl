library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Handler_SM_TB is
end entity Handler_SM_TB;

architecture RTL of Handler_SM_TB is
	component Handler_SM
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Length_Valid                      : in  std_logic;
			Receiver2Handler_UDP_Header_Ready : in  std_logic;
			Generator2Handler_Working           : in  std_logic;
			Message_Ready                     : in  std_logic;
			Message_Dropped                   : in  std_logic;
			UDP_Header_Stored                 : in  std_logic;
			Store_UDP_Header                  : out std_logic;
			Drop_Message                      : out std_logic;
			Handler2Generator_Message_Start   : out std_logic
		);
	end component Handler_SM;

	--TB SIGNALS, I/O signals
	signal clk                               : std_logic := '0';
	signal rst                               : std_logic := '0';
	signal Length_Valid                      : std_logic := '0';
	signal Receiver2Handler_UDP_Header_Ready : std_logic := '0';
	signal Generator2Handler_Ready           : std_logic := '0';
	signal Message_Ready                     : std_logic := '0';
	signal Message_Dropped                   : std_logic := '0';
	signal UDP_Header_Stored                 : std_logic := '0';
	signal Store_UDP_Header                  : std_logic := '0';
	signal Drop_Message                      : std_logic := '0';
	signal Handler2Generator_Message_Start   : std_logic := '0';
begin

	UUT_handlerSM : Handler_SM
		port map(
			clk                               => clk,
			rst                               => rst,
			Length_Valid                      => Length_Valid,
			Receiver2Handler_UDP_Header_Ready => Receiver2Handler_UDP_Header_Ready,
			Generator2Handler_Working           => Generator2Handler_Ready,
			Message_Ready                     => Message_Ready,
			Message_Dropped                   => Message_Dropped,
			UDP_Header_Stored                 => UDP_Header_Stored,
			Store_UDP_Header                  => Store_UDP_Header,
			Drop_Message                      => Drop_Message,
			Handler2Generator_Message_Start   => Handler2Generator_Message_Start
		);

	clk <= NOT clk after G_halfDC;

	--reset the UUT process
	Reset : process
	begin
		wait for 10 ns;
		rst <= '1';
		wait for 25 ns;
		rst <= '0';
		wait;
	end process Reset;

	Test : process is
	begin
		wait for 120 ns;
		Generator2Handler_Ready           <= '1';
		Receiver2Handler_UDP_Header_Ready <= '1';
		wait for 2 * G_halfDC;
		UDP_Header_Stored                 <= '1';
		Length_Valid                      <= '0';
		Message_Ready                     <= '0';
		wait for 100 * G_halfDC;
		Message_Dropped                   <= '1';
		wait;
	end process Test;
end architecture RTL;
