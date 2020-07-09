library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity generator_message_organizer_TB is
end entity generator_message_organizer_TB;

architecture RTL of generator_message_organizer_TB is

	component generator_message_organizer
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Current_Length                    : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Generator_Message_Organizer_Start : in  std_logic;
			Generator_Select                  : out std_logic_vector(3 downto 0);
			Reduce_Length                     : out std_logic;
			Generator2Receiver_Data_Ready     : out std_logic
		);
	end component generator_message_organizer;

	signal clk                               : std_logic                                 := '0';
	signal rst                               : std_logic                                 := '0';
	signal Current_Length                    : unsigned(G_HeaderFieldsSize - 1 downto 0) := to_unsigned(0, G_HeaderFieldsSize);
	signal Generator_Message_Organizer_Start : std_logic                                 := '0';
	signal Generator_Select                  : std_logic_vector(3 downto 0)              := (others => '0');
	signal Reduce_Length                     : std_logic                                 := '0';
	signal Generator2Receiver_Data_Ready     : std_logic                                 := '0';
begin
	UUT_Gener_msg_org : generator_message_organizer
		generic map(
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                               => clk,
			rst                               => rst,
			Current_Length                    => Current_Length,
			Generator_Message_Organizer_Start => Generator_Message_Organizer_Start,
			Generator_Select                  => Generator_Select,
			Reduce_Length                     => Reduce_Length,
			Generator2Receiver_Data_Ready     => Generator2Receiver_Data_Ready
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
		wait until rising_edge(clk);
		Generator_Message_Organizer_Start <= '1';
		--Current_Length                    <= x"0020";
		wait until rising_edge(clk);
		wait until rising_edge(Reduce_Length);
--		Current_Length                    <= x"0001";
		Generator_Message_Organizer_Start <= '0';
		wait;
	end process Test;

end architecture RTL;
