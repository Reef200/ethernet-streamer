library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity message_generator_TB is
end entity message_generator_TB;

architecture RTL of message_generator_TB is
	component Message_Generator
		generic(G_BusSize, G_HeaderFieldsSize : integer);
		port(
			clk                             : in  std_logic;
			rst                             : in  std_logic;
			Handler2Generator_Source        : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Destination   : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Length        : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Checksum      : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Message_Start : in  std_logic;
			Receiver_Data                   : in  std_logic_vector(G_BusSize - 1 downto 0);
			Generator2Receiver_Data_Ready   : out std_logic;
			Generator2Handler_Ready         : out std_logic;
			Generator2Handler_Message_Done  : out std_logic;
			Generator2Sender_Data           : out std_logic_vector(G_BusSize - 1 downto 0);
			Generator2Sender_Send_Message   : out std_logic
		);
	end component Message_Generator;

	signal clk                             : std_logic                                       := '0';
	signal rst                             : std_logic                                       := '0';
	signal Handler2Generator_Source        : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Destination   : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Length        : unsigned(G_HeaderFieldsSize - 1 downto 0)         := to_unsigned(0, G_HeaderFieldsSize);
	signal Handler2Generator_Checksum      : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Message_Start : std_logic                                       := '0';
	signal Receiver_Data                   : std_logic_vector(G_BusSize - 1 downto 0)          := (others => '0');
	signal Generator2Receiver_Data_Ready   : std_logic                                       := '0';
	signal Generator2Handler_Ready         : std_logic                                       := '0';
	signal Generator2Handler_Message_Done  : std_logic                                       := '0';
	signal Generator2Sender_Data           : std_logic_vector(G_BusSize - 1 downto 0)          := (others => '0');
	signal Generator2Sender_Send_Message   : std_logic                                       := '0';
begin

	UUT_msg_generator : Message_Generator
		generic map(
			G_BusSize          => G_BusSize,
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                             => clk,
			rst                             => rst,
			Handler2Generator_Source        => Handler2Generator_Source,
			Handler2Generator_Destination   => Handler2Generator_Destination,
			Handler2Generator_Length        => Handler2Generator_Length,
			Handler2Generator_Checksum      => Handler2Generator_Checksum,
			Handler2Generator_Message_Start => Handler2Generator_Message_Start,
			Receiver_Data                   => Receiver_Data,
			Generator2Receiver_Data_Ready   => Generator2Receiver_Data_Ready,
			Generator2Handler_Ready         => Generator2Handler_Ready,
			Generator2Handler_Message_Done  => Generator2Handler_Message_Done,
			Generator2Sender_Data           => Generator2Sender_Data,
			Generator2Sender_Send_Message   => Generator2Sender_Send_Message
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

	Handler : process is
	begin
		wait for 100 ns;
		wait until rising_edge(clk);
		Handler2Generator_Source        <= x"AAAA";
		Handler2Generator_Destination   <= x"BBBB";
		Handler2Generator_Length        <= x"0258";
		Handler2Generator_Checksum      <= x"CCCC";
		wait until rising_edge(clk);
		Handler2Generator_Message_Start <= '1';
		wait until rising_edge(clk);
		Handler2Generator_Message_Start <= '0';
		wait;
	end process Handler;

	Receiver : process is
	begin
		wait until rising_edge(clk);
		Receiver_Data <= x"12";
		wait until rising_edge(clk);
		Receiver_Data <= x"34";
		wait until rising_edge(clk);
		Receiver_Data <= x"56";
	end process Receiver;
end architecture RTL;
