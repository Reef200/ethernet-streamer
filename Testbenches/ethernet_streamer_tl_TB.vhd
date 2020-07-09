library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity ethernet_streamer_tl_TB is
end entity ethernet_streamer_tl_TB;

architecture RTL of ethernet_streamer_tl_TB is
	component Ethernet_Streamer_TOP
		port(
			clk                  : in  std_logic;
			rst                  : in  std_logic;
			Sink_Valid           : in  std_logic;
			Sink_SOP             : in  std_logic;
			Sink_EOP             : in  std_logic;
			Sink_Data            : in  std_logic_vector(G_BusSize - 1 downto 0);
			Sink_Rdy             : out std_logic;
			Source_Valid         : out std_logic;
			Source_SOP           : out std_logic;
			Source_EOP           : out std_logic;
			Source_Data          : out std_logic_vector(G_BusSize - 1 downto 0);
			Errors               : out std_logic_vector(3 downto 0);
			Error_Invalid_Length : out std_logic
		);
	end component Ethernet_Streamer_TOP;

	signal clk                  : std_logic                                := '0';
	signal rst                  : std_logic                                := '0';
	signal Sink_Valid           : std_logic                                := '0';
	signal Sink_SOP             : std_logic                                := '0';
	signal Sink_EOP             : std_logic                                := '0';
	signal Sink_Data            : std_logic_vector(G_BusSize - 1 downto 0) := (others => '0');
	signal Sink_Rdy             : std_logic                                := '0';
	signal Source_Valid         : std_logic                                := '0';
	signal Source_SOP           : std_logic                                := '0';
	signal Source_EOP           : std_logic                                := '0';
	signal Source_Data          : std_logic_vector(G_BusSize - 1 downto 0) := (others => '0');
	signal Errors               : std_logic_vector(3 downto 0)             := (others => '0');
	signal Error_Invalid_Length : std_logic                                := '0';
begin

	Ethernet_Streamer_TOP_inst : component Ethernet_Streamer_TOP
		port map(
			clk                  => clk,
			rst                  => rst,
			Sink_Valid           => Sink_Valid,
			Sink_SOP             => Sink_SOP,
			Sink_EOP             => Sink_EOP,
			Sink_Data            => Sink_Data,
			Sink_Rdy             => Sink_Rdy,
			Source_Valid         => Source_Valid,
			Source_SOP           => Source_SOP,
			Source_EOP           => Source_EOP,
			Source_Data          => Source_Data,
			Errors               => Errors,
			Error_Invalid_Length => Error_Invalid_Length
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

	Sink_inputs : process is            --	generate one message
	begin
		--legit message
		wait for 100 ns;
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_Valid <= '1';
		Sink_SOP   <= '1';
		Sink_EOP   <= '0';
		Sink_Data  <= x"34";
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_SOP   <= '0';
		Sink_Data  <= x"12";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"78";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"56";
		wait until rising_edge(clk);    --	length UDP is 600 = 0x0258
		Sink_Data  <= x"58";
		wait until rising_edge(clk);    --	length UDP is 600
		Sink_Data  <= x"02";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		Sink_Data  <= x"CC";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		wait until rising_edge(clk);
		for I in 0 to 598 loop
			Sink_Valid <= '1';
			Sink_SOP   <= '0';
			Sink_EOP   <= '0';
			Sink_Data  <= std_logic_vector(to_unsigned(I MOD 256, G_BusSize));
			wait until rising_edge(clk);
		end loop;
		Sink_Valid <= '1';
		Sink_SOP   <= '0';
		Sink_EOP   <= '1';
		Sink_Data  <= x"FF";
		wait until rising_edge(clk);
		Sink_Valid <= '0';
		Sink_SOP   <= '0';
		Sink_EOP   <= '0';

		--message for dropping
		wait for 100 ns;
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_Valid <= '1';
		Sink_SOP   <= '1';
		Sink_EOP   <= '0';
		Sink_Data  <= x"11";
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_SOP   <= '0';
		Sink_Data  <= x"22";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"33";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"44";
		wait until rising_edge(clk);    --	length UDP is 1532 = 0x05FE
		Sink_Data  <= x"FE";
		wait until rising_edge(clk);    --	length UDP is 1532
		Sink_Data  <= x"05";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		Sink_Data  <= x"CC";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		wait until rising_edge(clk);
		for I in 0 to 1532 loop
			Sink_Valid <= '1';
			Sink_SOP   <= '0';
			Sink_EOP   <= '0';
			Sink_Data  <= std_logic_vector(to_unsigned(I MOD 256, G_BusSize));
			wait until rising_edge(clk);
		end loop;
		Sink_Valid <= '1';
		Sink_SOP   <= '0';
		Sink_EOP   <= '1';
		Sink_Data  <= x"FF";
		wait until rising_edge(clk);
		Sink_Valid <= '0';
		Sink_SOP   <= '0';
		Sink_EOP   <= '0';
		
		--message without padding
		wait for 100 ns;
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_Valid <= '1';
		Sink_SOP   <= '1';
		Sink_EOP   <= '0';
		Sink_Data  <= x"55";
		wait until rising_edge(clk);    --	source UDP = 0x1234
		Sink_SOP   <= '0';
		Sink_Data  <= x"66";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"77";
		wait until rising_edge(clk);    --	dest. UDP = 0x5678
		Sink_Data  <= x"88";
		wait until rising_edge(clk);    --	length UDP is 1000 = 0x3E8
		Sink_Data  <= x"E8";
		wait until rising_edge(clk);    --	length UDP is 1000
		Sink_Data  <= x"03";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		Sink_Data  <= x"CC";
		wait until rising_edge(clk);    --	CheckSUM UDP = 0xCCCC
		wait until rising_edge(clk);
		for I in 0 to 9 loop
			Sink_Valid <= '1';
			Sink_SOP   <= '0';
			Sink_EOP   <= '0';
			Sink_Data  <= std_logic_vector(to_unsigned(I MOD 256, G_BusSize));
			wait until rising_edge(clk);
		end loop;
		Sink_Valid <= '1';
		Sink_SOP   <= '0';
		Sink_EOP   <= '1';
		Sink_Data  <= x"FF";
		wait until rising_edge(clk);
		Sink_Valid <= '0';
		Sink_SOP   <= '0';
		Sink_EOP   <= '0';
		wait;
	end process Sink_inputs;

end architecture RTL;
