--------------------------------------------------------------------------------
--
-- Title            : Sender SM
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Sender module decide when to send Garbage or the message.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 17/06/2019		 Reef Baltter	 File Creation
-- 		 2 			 19/06/2019		 Reef Baltter	 Added state Wait_for_SOP and output Sender2Generator_Ready
-- 		 3 			 27/06/2019		 Reef Baltter	 Added Generator2Sender_Message_Done input
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Sender_SM is
	port(
		clk                           : in  std_logic;
		rst                           : in  std_logic;
		Generator2Sender_Send_Message : in  std_logic;
		Sender_EOP                    : in  std_logic;
		Generator2Sender_Message_Done : in  std_logic;
		Sender2Generator_Ready        : out std_logic;
		Sender_Data_Select            : out std_logic
	);
end entity Sender_SM;

architecture RTL of Sender_SM is
	type state_type is (Garbage_Mode, Wait_for_EOP_to_Start, Message_Mode, Wait_for_EOP_to_End);

	signal sender_state : state_type := Garbage_Mode;

begin

	process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sender_state           <= Garbage_Mode;
				Sender_Data_Select     <= '0';
				Sender2Generator_Ready <= '0';
			else
				case sender_state is
					when Garbage_Mode =>
						if Generator2Sender_Send_Message = '1' AND Sender_EOP = '0' then
							sender_state           <= Wait_for_EOP_to_Start;
							Sender_Data_Select     <= '0';
							Sender2Generator_Ready <= '0';
						elsif Generator2Sender_Send_Message = '1' AND Sender_EOP = '1' then
							sender_state           <= Message_Mode;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '0';
						else
							sender_state           <= Garbage_Mode;
							Sender_Data_Select     <= '0';
							Sender2Generator_Ready <= '0';
						end if;
					when Wait_for_EOP_to_Start =>
						if Sender_EOP = '1' then
							sender_state           <= Message_Mode;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '1';
						else
							sender_state           <= Wait_for_EOP_to_Start;
							Sender_Data_Select     <= '0';
							Sender2Generator_Ready <= '0';
						end if;
					when Message_Mode =>
						if Generator2Sender_Message_Done = '1' then
							sender_state           <= Wait_for_EOP_to_End;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '0';
						else
							sender_state           <= Message_Mode;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '0';
						end if;
					when Wait_for_EOP_to_End =>
						if Sender_EOP = '1' then
							sender_state           <= Garbage_Mode;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '0';
						else
							sender_state           <= Wait_for_EOP_to_End;
							Sender_Data_Select     <= '1';
							Sender2Generator_Ready <= '0';
						end if;
				end case;
			end if;
		end if;
	end process;

end architecture RTL;
