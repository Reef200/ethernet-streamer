--------------------------------------------------------------------------------
--
-- Title            : message generator
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Generator starts to work after receiveing a sign from Handler. generates the fixed length message in constant rate and pass them to sender. 
--					  Adjust UDP Header length with the actual length of the message(without padding).
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 13/06/2019		 Reef Baltter	 File Creation
-- 		 2 			 19/06/2019		 Reef Baltter	 Added input Sender2Generator_Ready and connected Generator_Message_Organizer_Start to Generator2Sender_Send_Message
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Message_Generator is
	generic(G_BusSize, G_HeaderFieldsSize : integer);
	port(
		clk                             : in  std_logic;
		rst                             : in  std_logic;
		-- UDP Header from Handler
		Handler2Generator_Source        : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Destination   : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Length        : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Checksum      : in  std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Message_Start : in  std_logic;
		-- Sender Input
		Sender2Generator_Ready          : in  std_logic;
		-- Receiver Data
		Receiver_Data                   : in  std_logic_vector(G_BusSize - 1 downto 0);
		-- Generator request data from Receiver
		Generator2Receiver_Data_Ready   : out std_logic;
		-- Generator status to Handler
		Generator2Handler_Working       : out std_logic;
		Generator2Handler_Message_Done  : out std_logic;
		-- Genetor's packets to sender
		Generator2Sender_Data           : out std_logic_vector(G_BusSize - 1 downto 0);
		Generator2Sender_Send_Message   : out std_logic;
		Generator2Sender_Message_Done   : out std_logic
	);
end entity Message_Generator;

architecture Message_Generator_RTL of Message_Generator is

	-- signals declaration
	signal Data_Reg_Store_Enable             : std_logic;
	signal Generator_Data                    : std_logic_vector(G_BusSize - 1 downto 0);
	-- signals for Generator SM
	signal Generator_Done                    : std_logic;
	signal Generator_Message_Organizer_Start : std_logic;
	-- signals for Current Message Length
	signal Reduce_Length                     : std_logic;
	signal Current_Length                    : unsigned(G_HeaderFieldsSize - 1 downto 0);
	signal Message_Done                      : std_logic;
	-- signals for Generator Message Organzizer
	signal Generator_Select                  : std_logic_vector(3 downto 0);
	--signal Generator_Select                  : integer range 0 to 3;
	signal Output_Clk_Sync                   : std_logic;

	--decleration of components
	component Current_Message_Length
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                             : in  std_logic;
			rst                             : in  std_logic;
			Handler2Generator_Message_Start : in  std_logic;
			Reduce_Length                   : in  std_logic;
			Handler2Generator_Length        : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Current_Length                  : out unsigned(G_HeaderFieldsSize - 1 downto 0);
			Message_Done                    : out std_logic
		);
	end component Current_Message_Length;

	component Generator_SM
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Generator_Done                    : in  std_logic;
			Handler2Generator_Message_Start   : in  std_logic;
			Sender2Generator_Ready            : in  std_logic;
			Generator2Sender_Send_Message     : out std_logic;
			Generator2Handler_Working         : out std_logic;
			Generator_Message_Organizer_Start : out std_logic
		);
	end component Generator_SM;

	component generator_message_organizer
		generic(G_HeaderFieldsSize : integer);
		port(
			clk                               : in  std_logic;
			rst                               : in  std_logic;
			Current_Length                    : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
			Generator_Message_Organizer_Start : in  std_logic;
			Generator_Select                  : out std_logic_vector(3 downto 0);
			Reduce_Length                     : out std_logic;
			Output_Clk_Sync                   : out std_logic;
			Generator2Receiver_Data_Ready     : out std_logic
		);
	end component generator_message_organizer;

begin

	---------------------------------------------------------------------------------------	
	--		Besic Logic																	
	---------------------------------------------------------------------------------------
	Generator_Done                 <= Generator2Handler_Message_Done;
	Data_Reg_Store_Enable          <= Output_Clk_Sync;
	Generator2Handler_Message_Done <= Message_Done;
	Generator2Sender_Message_Done  <= Message_Done;
	
	-- 16-4 MUX logic
	Generator_Data                 <= Handler2Generator_Source(G_BusSize - 1 downto 0) when Generator_Select = "0000"
		else Handler2Generator_Source(G_HeaderFieldsSize - 1 downto G_BusSize) when Generator_Select = "0001"
		else Handler2Generator_Destination(G_BusSize - 1 downto 0) when Generator_Select = "0010"
		else Handler2Generator_Destination(G_HeaderFieldsSize - 1 downto G_BusSize) when Generator_Select = "0011"
		else std_logic_vector(Current_Length(G_BusSize - 1 downto 0)) when Generator_Select = "0100"
		else std_logic_vector(Current_Length(G_HeaderFieldsSize - 1 downto G_BusSize)) when Generator_Select = "0101"
		else Handler2Generator_Checksum(G_BusSize - 1 downto 0) when Generator_Select = "0110"
		else Handler2Generator_Checksum(G_HeaderFieldsSize - 1 downto G_BusSize) when Generator_Select = "0111"
		else Receiver_Data when Generator_Select = "1000"
		else (others => '0');

	---------------------------------------------------------------------------------------	
	--		Genertator's components																	
	---------------------------------------------------------------------------------------
	current_msg_len : Current_Message_Length
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
			Message_Done                    => Message_Done
		);

	Generator_SM_inst : component Generator_SM
		port map(
			clk                               => clk,
			rst                               => rst,
			Generator_Done                    => Generator_Done,
			Handler2Generator_Message_Start   => Handler2Generator_Message_Start,
			Sender2Generator_Ready            => Sender2Generator_Ready,
			Generator2Sender_Send_Message     => Generator2Sender_Send_Message,
			Generator2Handler_Working         => Generator2Handler_Working,
			Generator_Message_Organizer_Start => Generator_Message_Organizer_Start
		);

	generator_msg_organizer : generator_message_organizer
		generic map(
			G_HeaderFieldsSize => G_HeaderFieldsSize
		)
		port map(
			clk                               => clk,
			rst                               => rst,
			Current_Length                    => Current_Length,
			Generator_Message_Organizer_Start => Generator_Message_Organizer_Start,
			Generator_Select                  => Generator_Select,
			Reduce_Length                     => Reduce_Length,
			Output_Clk_Sync                   => Output_Clk_Sync,
			Generator2Receiver_Data_Ready     => Generator2Receiver_Data_Ready
		);

	Data_Reg : process(clk) is          --in order to sync the output data to output clk rate
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Generator2Sender_Data <= (others => '0');
			else
				if Data_Reg_Store_Enable = '1' then
					Generator2Sender_Data <= Generator_Data;
				end if;
			end if;
		end if;
	end process Data_Reg;

end architecture Message_Generator_RTL;
