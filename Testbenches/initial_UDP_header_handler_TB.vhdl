library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity initial_UDP_header_handler_TB is
end entity initial_UDP_header_handler_TB;

architecture RTL of initial_UDP_header_handler_TB is
	component initial_UDP_header_handler
		generic(G_BusSize, G_HeaderFieldsSize : integer);
		port(
			clk                           : in  std_logic;
			rst                           : in  std_logic;
			Store_UDP_Header              : in  std_logic;
			Receiver_Data                 : in  std_logic_vector(G_BusSize - 1 downto 0);
			UDP_Header_Data_Ready         : out std_logic;
			UDP_Header_Stored             : out std_logic;
			Handler2Generator_Source      : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Destination : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Length      : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Checksum    : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
		);
	end component initial_UDP_header_handler;
	
	signal clk                           : std_logic:= '0';
	signal rst                           : std_logic:= '0';
	signal Store_UDP_Header              : std_logic:= '0';
	signal Receiver_Data                 : std_logic_vector(G_BusSize - 1 downto 0):= (others => '0');
	signal UDP_Header_Data_Ready         : std_logic:= '0';
	signal UDP_Header_Stored             : std_logic:= '0';
	signal Handler2Generator_Source      : std_logic_vector(G_HeaderFieldsSize - 1 downto 0):= (others => '0');
	signal Handler2Generator_Destination : std_logic_vector(G_HeaderFieldsSize - 1 downto 0):= (others => '0');
	signal Handler2Generator_Length      : std_logic_vector(G_HeaderFieldsSize - 1 downto 0):= (others => '0');
	signal Handler2Generator_Checksum    : std_logic_vector(G_HeaderFieldsSize - 1 downto 0):= (others => '0');
begin

	UUT_init_UDP_header : initial_UDP_header_handler
		generic map(
			G_BusSize          => G_BusSize,
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                           => clk,
			rst                           => rst,
			Store_UDP_Header              => Store_UDP_Header,
			Receiver_Data                 => Receiver_Data,
			UDP_Header_Data_Ready         => UDP_Header_Data_Ready,
			UDP_Header_Stored             => UDP_Header_Stored,
			Handler2Generator_Source      => Handler2Generator_Source,
			Handler2Generator_Destination => Handler2Generator_Destination,
			Handler2Generator_Length      => Handler2Generator_Length,
			Handler2Generator_Checksum    => Handler2Generator_Checksum
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
		Receiver_Data                     <= x"00";
		wait for 120 ns;
		wait until rising_edge(clk);
		Store_UDP_Header <='1';
		wait for 2*G_halfDC;
		Store_UDP_Header <='0';
		Receiver_Data                     <= x"AA";
		wait for 4*G_halfDC;
		Receiver_Data                     <= x"BB";
		wait for 4*G_halfDC;
		Receiver_Data                     <= x"10";
		wait for 4*G_halfDC;
		Receiver_Data                     <= x"CC";
		wait for 4*G_halfDC;
		Store_UDP_Header<='0';
		wait;
	end process Test;
	
	
end architecture RTL;
