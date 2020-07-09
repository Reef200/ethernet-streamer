library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Message_Sender_TB is
end entity Message_Sender_TB;

architecture RTL of Message_Sender_TB is

	component Message_Sender
		generic(G_BusSize : integer);
		port(
			clk                           : in  std_logic;
			rst                           : in  std_logic;
			Generator2Sender_Send_Message : in  std_logic;
			Generator2Sender_Data         : in  std_logic_vector(G_BusSize - 1 downto 0);
			Source_Data                   : out std_logic_vector(G_BusSize - 1 downto 0);
			Sender2Generator_Ready        : out std_logic;
			Source_Valid                  : out std_logic;
			Source_SOP                    : out std_logic;
			Source_EOP                    : out std_logic
		);
	end component Message_Sender;

	signal clk                           : std_logic                              := '0';
	signal rst                           : std_logic                              := '0';
	signal Generator2Sender_Send_Message : std_logic                              := '0';
	signal Generator2Sender_Data         : std_logic_vector(G_BusSize - 1 downto 0) := (others => '0');
	signal Source_Data                   : std_logic_vector(G_BusSize - 1 downto 0) := (others => '0');
	signal Source_Valid                  : std_logic                              := '0';
	signal Source_SOP                    : std_logic                              := '0';
	signal Source_EOP                    : std_logic                              := '0';
	signal Sender2Generator_Ready        : std_logic                              := '0';
begin

	UUT_Message_Sender : component Message_Sender
		generic map(
			G_BusSize => G_BusSize
		)
		port map(
			clk                           => clk,
			rst                           => rst,
			Generator2Sender_Send_Message => Generator2Sender_Send_Message,
			Generator2Sender_Data         => Generator2Sender_Data,
			Source_Data                   => Source_Data,
			Sender2Generator_Ready        => Sender2Generator_Ready,
			Source_Valid                  => Source_Valid,
			Source_SOP                    => Source_SOP,
			Source_EOP                    => Source_EOP
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

	Generator : process is
	begin
		wait for 100 ns;
		wait until rising_edge(clk);
		Generator2Sender_Send_Message <= '1';
		wait until rising_edge(clk);
		Generator2Sender_Send_Message <= '0';
		wait;
	end process Generator;

	Data : process is
	begin
		wait until rising_edge(clk);
		Generator2Sender_Data <= x"12";
		wait until rising_edge(clk);
		Generator2Sender_Data <= x"34";
		wait until rising_edge(clk);
		Generator2Sender_Data <= x"56";
	end process Data;

end architecture RTL;
