--------------------------------------------------------------------------------
--
-- Title            : Message Receiver
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : This is the first module that the data passes, here the data stored in the FIFO according to the Avalon inputs.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 30/04/2019		 Reef Baltter	 File Creation
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;
library lego_fifo_1_7;
use lego_fifo_1_7.all;

entity Message_Reciever is
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
end entity Message_Reciever;

architecture message_receiver_RTL of Message_Reciever is

	-- signal declaration
	signal Avalon_Data_Valid         : std_logic;
	signal Receiver_Counter          : unsigned(3 downto 0) := "0000";
	signal Reset_counter             : std_logic;
	signal Complete_Message_Received : std_logic;
	signal FIFO_Data                 : std_logic_vector(G_BusSize - 1 downto 0);

	-- component declaration
	component receiver_SM
		port(
			clk                       : in  std_logic;
			rst                       : in  std_logic;
			Sink_Valid                : in  std_logic;
			Sink_SOP                  : in  std_logic;
			Sink_EOP                  : in  std_logic;
			Errors                    : out std_logic_vector(3 downto 0);
			Avalon_Data_Valid         : out std_logic;
			Complete_Message_Received : out std_logic
		);
	end component receiver_SM;
begin
	Receiver2Handler_Message_Received <= Complete_Message_Received;
	Reset_counter                     <= Complete_Message_Received;
	Receiver2Handler_UDP_Header_Ready <= '1' when Receiver_Counter = to_unsigned(7, 4) else '0';

	FIFO_Data_Reg : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				FIFO_Data <= (others => '0');
			else
				FIFO_Data <= Sink_Data;
			end if;
		end if;
	end process FIFO_Data_Reg;

	-- component Instantiation
	receiver_SM_inst : component receiver_SM
		port map(
			clk                       => clk,
			rst                       => rst,
			Sink_Valid                => Sink_Valid,
			Sink_SOP                  => Sink_SOP,
			Sink_EOP                  => Sink_EOP,
			Errors                    => Errors,
			Avalon_Data_Valid         => Avalon_Data_Valid,
			Complete_Message_Received => Complete_Message_Received
		);

	Receiver_Message_Byte_Counter : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Receiver_Counter <= to_unsigned(0, 4);
			else
				if Avalon_Data_Valid = '1' AND Receiver_Counter /= 9 then
					Receiver_Counter <= Receiver_Counter + 1;
				end if;
				if Reset_counter = '1' then
					Receiver_Counter <= to_unsigned(0, 4);
				end if;
			end if;
		end if;
	end process Receiver_Message_Byte_Counter;

	fifo_tl_inst : entity lego_fifo_1_7.fifo_tl
		generic map(
			G_RST_POLARITY      => '1',
			G_FIFO_WIDTH_IN     => G_BusSize,
			G_FIFO_WIDTH_OUT    => G_BusSize,
			G_FIFO_DEPTH        => 2 * G_MAX_MSG_LEN,
			G_ASYNC             => FALSE,
			BIG_END             => TRUE,
			G_FIFO_ALMOST_EMPTY => 0,
			G_FIFO_ALMOST_FULL  => 2 * G_MAX_MSG_LEN,
			G_VENDOR            => "Xilinx",
			G_RAM_TYPE          => "DRAM"
		)
		port map(
			w_clk          => clk,
			r_clk          => clk,
			w_rst          => rst,
			r_rst          => rst,
			r_srst         => rst,
			w_srst         => rst,
			r_empty        => open,
			r_almost_empty => open,
			r_capacity     => open,
			w_full         => open,
			w_almost_full  => open,
			w_capacity     => open,
			w_en           => Avalon_Data_Valid,
			r_en           => Read_Data_Enable,
			w_data         => FIFO_Data,
			r_data         => Receiver_Data,
			overflow       => open,
			underflow      => open
		);

end architecture message_receiver_RTL;
