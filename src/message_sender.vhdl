--------------------------------------------------------------------------------
--
-- Title            : Message Sender 
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : This module passing the message out, sends garbage when needed and managing all the Avalon output interface.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 18/06/2019		 Reef Baltter	 File Creation
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Message_Sender is
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
end entity Message_Sender;

architecture Message_Sender_RTL of Message_Sender is
	--signal declerations
	signal Garbage            : std_logic_vector(G_BusSize - 1 downto 0) := (others => '0');
	signal Sender_SOP         : std_logic                              := '0';
	signal Sender_EOP         : std_logic                              := '0';
	signal Sender_Data_Select : std_logic                              := '0';
	---------------------------------------------------------------------------------------	
	--		Sender's components																	
	---------------------------------------------------------------------------------------
	component Sender_SM
		port(
			clk                           : in  std_logic;
			rst                           : in  std_logic;
			Generator2Sender_Send_Message : in  std_logic;
			Sender_EOP                    : in  std_logic;
			Generator2Sender_Message_Done : in  std_logic;
			Sender2Generator_Ready        : out std_logic;
			Sender_Data_Select            : out std_logic
		);
	end component Sender_SM;

	component sender_message_organizer
		port(
			clk          : in  std_logic;
			rst          : in  std_logic;
			Source_Valid : out std_logic;
			Source_SOP   : out std_logic;
			Source_EOP   : out std_logic
		);
	end component sender_message_organizer;

begin

	-- Asynchronous logic
	Source_Data <= Generator2Sender_Data when Sender_Data_Select = '1' else Garbage;
	Sender_SOP  <= Source_SOP;
	Sender_EOP  <= Source_EOP;

	---------------------------------------------------------------------------------------	
	--		Sender's components connections																	
	---------------------------------------------------------------------------------------

	Sender_SM_inst : component Sender_SM
		port map(
			clk                           => clk,
			rst                           => rst,
			Generator2Sender_Send_Message => Generator2Sender_Send_Message,
			Sender_EOP                    => Sender_EOP,
			Generator2Sender_Message_Done => Generator2Sender_Message_Done,
			Sender2Generator_Ready        => Sender2Generator_Ready,
			Sender_Data_Select            => Sender_Data_Select
		);
		
	sender_message_organizer_inst : component sender_message_organizer
		port map(
			clk          => clk,
			rst          => rst,
			Source_Valid => Source_Valid,
			Source_SOP   => Source_SOP,
			Source_EOP   => Source_EOP
		);

end architecture Message_Sender_RTL;
