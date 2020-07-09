library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity current_message_length_TB is
end entity current_message_length_TB;

architecture RTL of current_message_length_TB is
	component Current_Message_Length
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                             : in  std_logic;
			rst                             : in  std_logic;
			Handler2Generator_Message_Start : in  std_logic;
			Reduce_Length                   : in  std_logic;
			Handler2Generator_Length        : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Current_Length                  : out unsigned(G_HeaderFieldsSize - 1 downto 0);
			Message_Done  : out std_logic
		);
	end component Current_Message_Length;

	signal clk                             : std_logic                               := '0';
	signal rst                             : std_logic                               := '0';
	signal Handler2Generator_Message_Start : std_logic                               := '0';
	signal Reduce_Length                   : std_logic                               := '0';
	signal Handler2Generator_Length        : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Current_Length                  : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Generator2Handler_Message_Done  : std_logic                               := '0';
begin

	UUT_curr_msg_len : Current_Message_Length
		generic map(
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                             => clk,
			rst                             => rst,
			Handler2Generator_Message_Start => Handler2Generator_Message_Start,
			Reduce_Length                   => Reduce_Length,
			Handler2Generator_Length        => Handler2Generator_Length,
			Current_Length                  => Current_Length,
			Message_Done  => Generator2Handler_Message_Done
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
		Handler2Generator_Message_Start <= '1';
		Handler2Generator_Length        <= x"0258";
		wait until rising_edge(clk);
		Handler2Generator_Message_Start <= '0';
		wait for 78 ns;
		wait until rising_edge(clk);
		Reduce_Length <='1';
		wait until rising_edge(clk);
		Reduce_Length <='0';
		wait for 99 ns;
		wait until rising_edge(clk);
		Reduce_Length <='1';
		wait until rising_edge(clk);
		Reduce_Length <='0';
		wait for 99 ns;
		wait until rising_edge(clk);
		Reduce_Length <='1';
		wait until rising_edge(clk);
		Reduce_Length <='0';
	end process Test;
end architecture RTL;
