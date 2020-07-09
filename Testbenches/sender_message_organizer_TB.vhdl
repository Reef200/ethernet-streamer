library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity sender_message_organizer_TB is
end entity sender_message_organizer_TB;

architecture RTL of sender_message_organizer_TB is
	component sender_message_organizer
		port(
			clk          : in  std_logic;
			rst          : in  std_logic;
			Source_Valid : out std_logic;
			Source_SOP   : out std_logic;
			Source_EOP   : out std_logic
		);
	end component sender_message_organizer;

	-- signal declaration
	signal clk          : std_logic := '0';
	signal rst          : std_logic := '0';
	signal Source_Valid : std_logic := '0';
	signal Source_SOP   : std_logic := '0';
	signal Source_EOP   : std_logic := '0';
begin

	UUT_sender_msg_organizer : sender_message_organizer
		port map(
			clk          => clk,
			rst          => rst,
			Source_Valid => Source_Valid,
			Source_SOP   => Source_SOP,
			Source_EOP   => Source_EOP
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

end architecture RTL;
