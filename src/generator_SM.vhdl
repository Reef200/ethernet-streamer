--------------------------------------------------------------------------------
--
-- Title            : Generator SM
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Generator state machine that decides if the Generator is in Start state and generating messages or in Idle state and waiting for input.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 12/06/2019		 Reef Baltter	 File Creation
-- 		 2 			 19/06/2019		 Reef Baltter	 Added state Wait_for_Sender and input Sender2Generator_Ready
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Generator_SM is
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
end entity Generator_SM;

architecture Generator_SM_RTL of Generator_SM is
	type state_type is (Idle, Wait_for_Sender, Start);

	signal generator_state : state_type := Idle;

begin

	process(clk, rst) is
	begin
		if rst = '1' then
			generator_state                   <= Idle;
			Generator2Sender_Send_Message     <= '0';
			Generator2Handler_Working         <= '0';
			Generator_Message_Organizer_Start <= '0';
		elsif rising_edge(clk) then
			case generator_state is
				when Idle =>
					if Handler2Generator_Message_Start = '1' AND Sender2Generator_Ready = '0' then
						generator_state                   <= Wait_for_Sender;
						Generator2Sender_Send_Message     <= '1';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '0';
					elsif Handler2Generator_Message_Start = '1' AND Sender2Generator_Ready = '1' then
						generator_state                   <= Start;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '1';
					else
						generator_state                   <= Idle;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '0';
						Generator_Message_Organizer_Start <= '0';
					end if;
				when Wait_for_Sender =>
					if Sender2Generator_Ready = '1' then
						generator_state                   <= Start;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '1';
					else
						generator_state                   <= Wait_for_Sender;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '0';
					end if;
				when Start =>
					if Generator_Done = '1' AND Sender2Generator_Ready = '1' then
						generator_state                   <= Wait_for_Sender;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '0';
					elsif Generator_Done = '1' AND Sender2Generator_Ready = '0' then
						generator_state                   <= Idle;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '0';
						Generator_Message_Organizer_Start <= '0';
					else
						generator_state                   <= Start;
						Generator2Sender_Send_Message     <= '0';
						Generator2Handler_Working         <= '1';
						Generator_Message_Organizer_Start <= '1';
					end if;
			end case;
		end if;
	end process;

end architecture Generator_SM_RTL;
