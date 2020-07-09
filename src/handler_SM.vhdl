--------------------------------------------------------------------------------
--
-- Title            : Handler SM
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Handler module decide what to do with the message, drop it or proceed to sending.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 30/04/2019		 Reef Baltter	 File Creation
-- 		 2 			 30/04/2019		 Reef Baltter	 Added Wait_For_Message_To_Start state as hotfix
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity Handler_SM is
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
end entity Handler_SM;

architecture Handler_SM_RTL of Handler_SM is
	type state_type is (Idle, UDP_Header_Storing, Wait_For_Message_Ready, Dropping_Message, Wait_For_Generator_To_Start);

	signal handler_state : state_type := IDLE;

begin

	SM_Process : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				handler_state                   <= IDLE;
				Store_UDP_Header                <= '0';
				Drop_Message                    <= '0';
				Handler2Generator_Message_Start <= '0';
			else
				case handler_state is
					when IDLE =>
						if Generator2Handler_Working = '0' AND (Receiver2Handler_UDP_Header_Ready = '1' OR Message_Ready = '1') then
							handler_state                   <= UDP_Header_Storing;
							Store_UDP_Header                <= '1';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						else
							handler_state                   <= IDLE;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						end if;
					when UDP_Header_Storing =>
						if UDP_Header_Stored = '1' AND Length_Valid = '1' AND Message_Ready = '1' then
							handler_state                   <= Wait_For_Generator_To_Start;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '1';
						elsif UDP_Header_Stored = '1' AND Length_Valid = '1' AND Message_Ready = '0' then
							handler_state                   <= Wait_For_Message_Ready;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						elsif UDP_Header_Stored = '1' AND Length_Valid = '0' then
							handler_state                   <= Dropping_Message;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '1';
							Handler2Generator_Message_Start <= '0';
						else
							handler_state                   <= UDP_Header_Storing;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						end if;
					when Dropping_Message =>
						if Message_Dropped = '1' then
							handler_state                   <= IDLE;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						else
							handler_state                   <= Dropping_Message;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						end if;
					when Wait_For_Message_Ready =>
						if Message_Ready = '1' then
							handler_state                   <= Wait_For_Generator_To_Start;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '1';
						else
							handler_state                   <= Wait_For_Message_Ready;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						end if;
					when Wait_For_Generator_To_Start =>
						if Generator2Handler_Working = '1' then
							handler_state                   <= IDLE;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						else
							handler_state                   <= Wait_For_Generator_To_Start;
							Store_UDP_Header                <= '0';
							Drop_Message                    <= '0';
							Handler2Generator_Message_Start <= '0';
						end if;
				end case;
			end if;
		end if;
	end process;

end architecture Handler_SM_RTL;
