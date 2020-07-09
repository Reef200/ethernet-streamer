--------------------------------------------------------------------------------
--
-- Title            : Ethernet_Streamer TOP level
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : This is the top level, this module gets and transfers Avalon packets 8-bits.
--				 	  Sink_Ready will always equal to ‘1’, because this module can handle with burst input of two G_MAX_MSG_LEN messages in a row.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 20/06/2019		 Reef Baltter	 File Creation
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Ethernet_Streamer_TOP is
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
end entity Ethernet_Streamer_TOP;

architecture Ethernet_Streamer_TOP_RTL of Ethernet_Streamer_TOP is

	---------------------------------------------------------------------------------------	
	--		Signal declaration																	
	---------------------------------------------------------------------------------------
	--	Data signals
	signal Generator2Receiver_Data_Ready     : std_logic;
	signal Handler2Receiver_Data_Ready       : std_logic;
	signal Receiver_Data                     : std_logic_vector(G_BusSize - 1 downto 0);
	signal Read_Data_Enable                  : std_logic;
	--	Receiver <-> Handler signals
	signal Receiver2Handler_UDP_Header_Ready : std_logic;
	signal Receiver2Handler_Message_Received : std_logic;
	--	Handler <-> Generator signals
	signal Generator2Handler_Working         : std_logic;
	signal Generator2Handler_Message_Done    : std_logic;
	signal Handler2Generator_Message_Start   : std_logic;
	signal Handler2Generator_Source          : std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
	signal Handler2Generator_Destination     : std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
	signal Handler2Generator_Length          : unsigned(G_HeaderFieldsSize - 1 downto 0);
	signal Handler2Generator_Checksum        : std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
	--	Generator <-> Sender signals
	signal Generator2Sender_Data             : std_logic_vector(G_BusSize - 1 downto 0);
	signal Generator2Sender_Send_Message     : std_logic;
	signal Sender2Generator_Ready            : std_logic;
	signal Generator2Sender_Message_Done     : std_logic;

	---------------------------------------------------------------------------------------	
	--		Handler's components																	
	---------------------------------------------------------------------------------------
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

	component Message_Handler
		generic(G_BusSize, G_HeaderFieldsSize : integer);
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Receiver2Handler_UDP_Header_Ready : in  std_logic;
			Receiver2Handler_Message_Received : in  std_logic;
			Generator2Handler_Working         : in  std_logic;
			Generator2Handler_Message_Done    : in  std_logic;
			Receiver_Data                     : in  std_logic_vector(G_BusSize - 1 downto 0);
			Handler2Receiver_Data_Ready       : out std_logic;
			Handler2Generator_Message_Start   : out std_logic;
			Error_Invalid_Length              : out std_logic;
			Handler2Generator_Source          : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Destination     : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Length          : out unsigned(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Checksum        : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
		);
	end component Message_Handler;

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
			Sender2Generator_Ready          : in  std_logic;
			Receiver_Data                   : in  std_logic_vector(G_BusSize - 1 downto 0);
			Generator2Receiver_Data_Ready   : out std_logic;
			Generator2Handler_Working       : out std_logic;
			Generator2Handler_Message_Done  : out std_logic;
			Generator2Sender_Data           : out std_logic_vector(G_BusSize - 1 downto 0);
			Generator2Sender_Send_Message   : out std_logic;
			Generator2Sender_Message_Done   : out std_logic
		);
	end component Message_Generator;

	component Message_Sender
		generic(G_BusSize : integer);
		port(
			clk                           : in  std_logic;
			rst                           : in  std_logic;
			Generator2Sender_Send_Message : in  std_logic;
			Generator2Sender_Message_Done : in  std_logic;
			Generator2Sender_Data         : in  std_logic_vector(G_BusSize - 1 downto 0);
			Source_Data                   : out std_logic_vector(G_BusSize - 1 downto 0);
			Sender2Generator_Ready        : out std_logic;
			Source_Valid                  : out std_logic;
			Source_SOP                    : out std_logic;
			Source_EOP                    : out std_logic
		);
	end component Message_Sender;

begin
	---------------------------------------------------------------------------------------	
	--		Besic Logic																	
	---------------------------------------------------------------------------------------
	Sink_Rdy         <= '1';            -- Eth_Streamer always ready to receive data 
	Read_Data_Enable <= Handler2Receiver_Data_Ready OR Generator2Receiver_Data_Ready; --
	---------------------------------------------------------------------------------------	
	--		Handler's components Instantiation																	
	---------------------------------------------------------------------------------------
	Message_Reciever_inst : component Message_Reciever
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
	Message_Handler_inst : component Message_Handler
		generic map(
			G_BusSize          => G_BusSize,
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                               => clk,
			rst                               => rst,
			Receiver2Handler_UDP_Header_Ready => Receiver2Handler_UDP_Header_Ready,
			Receiver2Handler_Message_Received => Receiver2Handler_Message_Received,
			Generator2Handler_Working         => Generator2Handler_Working,
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
	Message_Generator_inst : component Message_Generator
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
			Sender2Generator_Ready          => Sender2Generator_Ready,
			Receiver_Data                   => Receiver_Data,
			Generator2Receiver_Data_Ready   => Generator2Receiver_Data_Ready,
			Generator2Handler_Working       => Generator2Handler_Working,
			Generator2Handler_Message_Done  => Generator2Handler_Message_Done,
			Generator2Sender_Data           => Generator2Sender_Data,
			Generator2Sender_Send_Message   => Generator2Sender_Send_Message,
			Generator2Sender_Message_Done   => Generator2Sender_Message_Done
		);
	Message_Sender_inst : component Message_Sender
		generic map(
			G_BusSize => G_BusSize
		)
		port map(
			clk                           => clk,
			rst                           => rst,
			Generator2Sender_Send_Message => Generator2Sender_Send_Message,
			Generator2Sender_Message_Done => Generator2Sender_Message_Done,
			Generator2Sender_Data         => Generator2Sender_Data,
			Source_Data                   => Source_Data,
			Sender2Generator_Ready        => Sender2Generator_Ready,
			Source_Valid                  => Source_Valid,
			Source_SOP                    => Source_SOP,
			Source_EOP                    => Source_EOP
		);

end architecture Ethernet_Streamer_TOP_RTL;
