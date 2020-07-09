library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_use_package.all;

entity message_receiver_TB is
end entity message_receiver_TB;

architecture RTL of message_receiver_TB is
	component Message_Reciever
		generic(G_BusSize, G_ErrorsSize : integer);
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Sink_Valid                        : in  std_logic;
			Sink_SOP                          : in  std_logic;
			Sink_EOP                          : in  std_logic;
			Read_Data_Enable                  : in  std_logic;
			Sink_Data                         : in  std_logic_vector(G_BusSize - 1 downto 0);
			Receiver2Handler_Message_Received : out std_logic;
			Receiver2Handler_UDP_Header_Ready : out std_logic;
			Receiver_Data                     : out std_logic_vector(G_BusSize - 1 downto 0);
			Errors                            : out std_logic_vector(G_ErrorsSize - 1 downto 0)
		);
	end component Message_Reciever;
	signal clk                               : std_logic                                   := '0';
	signal rst                               : std_logic                                   := '0';
	signal Sink_Valid                        : std_logic                                   := '0';
	signal Sink_SOP                          : std_logic                                   := '0';
	signal Sink_EOP                          : std_logic                                   := '0';
	signal Read_Data_Enable                  : std_logic                                   := '0';
	signal Sink_Data                         : std_logic_vector(G_BusSize - 1 downto 0)    := (others => '0');
	signal Receiver2Handler_Message_Received : std_logic                                   := '0';
	signal Receiver2Handler_UDP_Header_Ready : std_logic                                   := '0';
	signal Receiver_Data                     : std_logic_vector(G_BusSize - 1 downto 0)    := (others => '0');
	signal Errors                            : std_logic_vector(G_ErrorsSize - 1 downto 0) := (others => '0');

begin

	message_reciever_inst : component Message_Reciever
		generic map(
			G_BusSize    => G_BusSize,
			G_ErrorsSize => G_ErrorsSize
		)
		port map(
			clk                               => clk,
			rst                               => rst,
			Sink_Valid                        => Sink_Valid,
			Sink_SOP                          => Sink_SOP,
			Sink_EOP                          => Sink_EOP,
			Read_Data_Enable                  => Read_Data_Enable,
			Sink_Data                         => Sink_Data,
			Receiver2Handler_Message_Received => Receiver2Handler_Message_Received,
			Receiver2Handler_UDP_Header_Ready => Receiver2Handler_UDP_Header_Ready,
			Receiver_Data                     => Receiver_Data,
			Errors                            => Errors
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

	Inputs : process is
	begin
		wait for 100 ns;
		wait until rising_edge(clk);
		Sink_Valid <= '1';
		Sink_SOP   <= '1';
		Sink_EOP   <= '0';
		Sink_Data  <= x"00";
		for I in 0 to 498 loop
			wait until rising_edge(clk);
			Sink_Valid <= '1';
			Sink_SOP   <= '0';
			Sink_EOP   <= '0';
			Sink_Data  <= std_logic_vector(to_unsigned(I / 10, G_BusSize));
		end loop;
		wait until rising_edge(clk);
		Sink_Valid <= '1';
		Sink_SOP   <= '0';
		Sink_EOP   <= '1';
		Sink_Data  <= x"FF";
		wait until rising_edge(clk);
		Sink_Valid <= '0';
		Sink_SOP   <= '0';
		Sink_EOP   <= '0';
		wait;
	end process Inputs;
	
	Read : process is
	begin
		wait for 80 us;
		wait until rising_edge(clk);
		Read_Data_Enable<='1';
	end process Read;
	
	
end architecture RTL;