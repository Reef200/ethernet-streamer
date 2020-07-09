library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity message_dropper_TB is
end entity message_dropper_TB;

architecture RTL of message_dropper_TB is
	component Message_Dropper
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                    : in  std_logic;
			rst                    : in  std_logic;
			Drop_Message           : in  std_logic;
			Dropped_Message_Length : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Message_Dropped        : out std_logic;
			Dropper_Data_Ready     : out std_logic
		);
	end component Message_Dropper;

	--TB SIGNALS, I/O signals
	signal clk                    : std_logic                                       := '0';
	signal rst                    : std_logic                                       := '0';
	signal Drop_Message           : std_logic                                       := '0';
	signal Dropped_Message_Length : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := x"0000";
	signal Message_Dropped        : std_logic                                       := '0';
	signal Dropper_Data_Ready     : std_logic                                       := '0';
begin

	UUT_dropper : Message_Dropper
		generic map(
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                    => clk,
			rst                    => rst,
			Drop_Message           => Drop_Message,
			Dropped_Message_Length => Dropped_Message_Length,
			Message_Dropped        => Message_Dropped,
			Dropper_Data_Ready     => Dropper_Data_Ready
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
		Dropped_Message_Length <= x"000A";
		wait for 4 * G_halfDC;
		Drop_Message           <= '1';
		wait for 20 * G_halfDC;
		Drop_Message           <= '0';
		wait;
	end process Test;
	
end architecture RTL;
