--------------------------------------------------------------------------------
--
-- Title            : message handler
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Handles the message recieved from the Receiver, saving the header, pass the message if valid and drop it if not.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 30/04/2019		 Reef Baltter	 File Creation
-- 		 2 			 05/06/2019		 Reef Baltter	 Fixed some bugs
-- 		 3 			 05/06/2019		 Reef Baltter	 connected Error_Invalid_Length to Drop_Message signal as it should be
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Message_Handler is
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
		Handler2Generator_Length          : out unsigned(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Checksum        : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
	);
end entity Message_Handler;

architecture Message_Handler_RTL of Message_Handler is

	-- signals declaration

	--Dropper signals
	signal Drop_Message           : std_logic                                       := '0';
	signal Dropped_Message_Length : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Dropper_Data_Ready     : std_logic                                       := '0';
	signal Message_Dropped        : std_logic                                       := '0';
	--Initial UDP Header Handler signals
	signal Store_UDP_Header       : std_logic                                       := '0';
	signal UDP_Header_Stored      : std_logic                                       := '0';
	signal UDP_Header_Data_Ready  : std_logic                                       := '0';
	--Handler SM signals
	signal Message_Ready          : std_logic                                       := '0';
	signal Length_Valid           : std_logic                                       := '0';
	--signals for the counter
	signal Decrement_Counter      : std_logic                                       := '0';
	signal Message_Counter_Count  : unsigned(5 downto 0)                            := (others => '0');
	--UDP header length field
	signal Message_Length         : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');

	--decleration of components
	component Handler_SM
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Length_Valid                      : in  std_logic;
			Receiver2Handler_UDP_Header_Ready : in  std_logic;
			Generator2Handler_Working           : in  std_logic;
			Message_Ready                     : in  std_logic;
			Message_Dropped                   : in  std_logic;
			UDP_Header_Stored                 : in  std_logic;
			Store_UDP_Header                  : out std_logic;
			Drop_Message                      : out std_logic;
			Handler2Generator_Message_Start   : out std_logic
		);
	end component Handler_SM;

	component Message_Dropper
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                    : in  std_logic;
			rst                    : in  std_logic;
			Drop_Message           : in  std_logic;
			Dropped_Message_Length : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Message_Dropped        : out std_logic;
			Dropper_Data_Ready     : out std_logic
		);
	end component Message_Dropper;

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
			Handler2Generator_Length      : out unsigned(G_HeaderFieldsSize - 1 downto 0);
			Handler2Generator_Checksum    : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
		);
	end component initial_UDP_header_handler;

begin

	---------------------------------------------------------------------------------------	
	--		Besic Logic																	
	---------------------------------------------------------------------------------------
	Handler2Receiver_Data_Ready <= Dropper_Data_Ready OR UDP_Header_Data_Ready;
	Decrement_Counter           <= Generator2Handler_Message_Done OR Message_Dropped;
	Message_Ready               <= '1' when Message_Counter_Count > to_unsigned(0, 5) else '0';
	Dropped_Message_Length      <= Handler2Generator_Length;
	Message_Length              <= Handler2Generator_Length;
	Length_Valid                <= '1' when to_unsigned(G_MIN_MSG_LEN, G_HeaderFieldsSize) < Message_Length AND Message_Length < to_unsigned(G_MAX_MSG_LEN, G_HeaderFieldsSize) else '0';
	Error_Invalid_Length        <= Drop_Message;
	---------------------------------------------------------------------------------------	
	--		Handler's components																	
	---------------------------------------------------------------------------------------

	SM : component Handler_SM
		port map(
			clk                               => clk,
			rst                               => rst,
			Length_Valid                      => Length_Valid,
			Receiver2Handler_UDP_Header_Ready => Receiver2Handler_UDP_Header_Ready,
			Generator2Handler_Working           => Generator2Handler_Working,
			Message_Ready                     => Message_Ready,
			Message_Dropped                   => Message_Dropped,
			UDP_Header_Stored                 => UDP_Header_Stored,
			Store_UDP_Header                  => Store_UDP_Header,
			Drop_Message                      => Drop_Message,
			Handler2Generator_Message_Start   => Handler2Generator_Message_Start
		);

	msg_dropper : component Message_Dropper
		generic map(
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                    => clk,
			rst                    => rst,
			Drop_Message           => Drop_Message,
			Dropped_Message_Length => Dropped_Message_Length,
			Message_Dropped        => Message_Dropped,
			Dropper_Data_Ready     => Dropper_Data_Ready
		);

	init_UDP_header_hndlr : initial_UDP_header_handler
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

	---------------------------------------------------------------------------------------	
	--		Message Counter																	
	---------------------------------------------------------------------------------------

	Message_Counter : process(clk) is
		variable Counter_Count : integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Counter_Count := 0;
			else
				if Receiver2Handler_Message_Received = '1' then
					Counter_Count := Counter_Count + 1;
				end if;
				if Decrement_Counter = '1' then
					Counter_Count := Counter_Count - 1;
				end if;
			end if;
		end if;
		Message_Counter_Count <= to_unsigned(Counter_Count, 6);
	end process Message_Counter;

end architecture Message_Handler_RTL;
