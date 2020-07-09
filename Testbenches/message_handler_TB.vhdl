library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity message_handler_TB is
end entity message_handler_TB;

architecture message_handler_TB_RTL of message_handler_TB is
	component Message_Handler
		generic(G_BusSize, G_HeaderFieldsSize : integer);
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			-- Receiver status
			Receiver2Handler_UDP_Header_Ready : in  std_logic;
			Receiver2Handler_Message_Received : in  std_logic;
			-- Generator status
			Generator2Handler_Working           : in  std_logic;
			Generator2Handler_Message_Done    : in  std_logic;
			--Bus data
			Receiver_Data                     : in  std_logic_vector(G_BusSize - 1 downto 0);
			--Enabler read from FIFO
			Handler2Receiver_Data_Ready       : out std_logic;
			--Start to generate messages
			Handler2Generator_Message_Start   : out std_logic;
			--Error vector
			Error_Invalid_Length              : out std_logic;
			--UDP Header fields
			Handler2Generator_Source          : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Destination     : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Length          : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Checksum        : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
		);
	end component Message_Handler;

	--TB SIGNALS, I/O signals
	signal clk                               : std_logic                                       := '0';
	signal rst                               : std_logic                                       := '0';
	signal Receiver2Handler_UDP_Header_Ready : std_logic                                       := '0';
	signal Receiver2Handler_Message_Received : std_logic                                       := '0';
	signal Generator2Handler_Ready           : std_logic                                       := '0';
	signal Generator2Handler_Message_Done    : std_logic                                       := '0';
	signal Receiver_Data                     : std_logic_vector(G_BusSize - 1 downto 0)          := (others => '0');
	signal Handler2Receiver_Data_Ready       : std_logic                                       := '0';
	signal Handler2Generator_Message_Start   : std_logic                                       := '0';
	signal Error_Invalid_Length              : std_logic                                       := '0';
	signal Handler2Generator_Source          : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Destination     : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Length          : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Handler2Generator_Checksum        : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');

begin
	UUT_handler : Message_Handler
		generic map(G_BusSize, G_HeaderFieldsSize)
		port map(
			clk                               => clk,
			rst                               => rst,
			Receiver2Handler_UDP_Header_Ready => Receiver2Handler_UDP_Header_Ready,
			Receiver2Handler_Message_Received => Receiver2Handler_Message_Received,
			Generator2Handler_Working           => Generator2Handler_Ready,
			Generator2Handler_Message_Done    => Generator2Handler_Message_Done,
			Receiver_Data                     => Receiver_Data,
			Handler2Receiver_Data_Ready       => Handler2Receiver_Data_Ready,
			Handler2Generator_Message_Start   => Handler2Generator_Message_Start,
			Error_Invalid_Length              => Error_Invalid_Length,
			Handler2Generator_Source          => Handler2Generator_Source,
			Handler2Generator_Destination     => Handler2Generator_Destination,
			Handler2Generator_Length          => Handler2Generator_Length,
			Handler2Generator_Checksum        => Handler2Generator_Checksum
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

	Receiver : process is
	begin
		-- Generate message with length of 100 bytes.
		wait for 120 ns;
		wait until rising_edge(clk);
		Receiver2Handler_UDP_Header_Ready <= '1';
		wait for 4 * G_halfDC;
		Receiver_Data                     <= x"AA";
		Receiver2Handler_UDP_Header_Ready <= '0';
		wait for 4 * G_halfDC;
		Receiver_Data                     <= x"BB";
		wait for 4 * G_halfDC;
		Receiver_Data                     <= x"DD";
		wait until rising_edge(clk);
		Receiver_Data                     <= x"05";
		wait until rising_edge(clk);
		Receiver_Data                     <= x"CC";
		wait for 4 * G_halfDC;
		Receiver_Data                     <= x"DD";
		Receiver2Handler_Message_Received <= '1';
		wait for 2 * G_halfDC;
		Receiver2Handler_Message_Received <= '0';
		wait for 91 * 2 * G_halfDC;
		Receiver_Data                     <= x"00";
		wait;
	end process Receiver;

	Generator : process is
	begin
		wait for 100 ns;
		wait until rising_edge(clk);
		Generator2Handler_Ready        <= '1';
		wait for 20 ns;
		wait for 20 * G_halfDC;
		Generator2Handler_Ready        <= '0';
		wait until rising_edge(clk);
		--Generator2Handler_Message_Done <= '1';
		wait for 2 * G_halfDC;
		--Generator2Handler_Message_Done <= '0';
		wait;
	end process Generator;

end architecture message_handler_TB_RTL;
