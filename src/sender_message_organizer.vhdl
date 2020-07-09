--------------------------------------------------------------------------------
--
-- Title            : sender message organizer
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : The module exports the Avalon EOP, SOP and Valid bits. This module starts when a rst pulse signal is received.
-- 					  The module sends Source_Valid every 10th clock because the output rate is 100MB/s and the system clock is 125MHz.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 13/06/2019		 Reef Baltter	 File Creation
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity sender_message_organizer is
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		Source_Valid : out std_logic;
		Source_SOP   : out std_logic;
		Source_EOP   : out std_logic
	);
end entity sender_message_organizer;

architecture sender_message_organizer_RTL of sender_message_organizer is
	-- signals declaration
	signal Source_SOP_Not_Synced    : std_logic;
	signal Source_EOP_Not_Synced    : std_logic;
	signal Sender_Counter_Increment : std_logic;
	signal Counter_Mod_Ten_Count    : unsigned(3 downto 0);
	signal Sender_Counter_Count     : unsigned(8 downto 0);

begin

	-- Asynchronous logic
	Source_Valid <= Sender_Counter_Increment;
	Source_EOP   <= Source_EOP_Not_Synced AND Source_Valid;
	Source_SOP   <= Source_SOP_Not_Synced AND Source_Valid;

	Source_EOP_Not_Synced    <= '1' when Sender_Counter_Count = to_unsigned(G_PAYLOAD_OUT_SIZE + 7, 9) else '0';
	Source_SOP_Not_Synced    <= '1' when Sender_Counter_Count = 0 else '0';
	Sender_Counter_Increment <= '1' when Counter_Mod_Ten_Count = 0 else '0';

	Rate_Stabilizer_cnt_mod10 : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Counter_Mod_Ten_Count <= "1111"; -- in order to not mess up the Generator_Counter_Count
			else
				Counter_Mod_Ten_Count <= Counter_Mod_Ten_Count + 1;
				if Counter_Mod_Ten_Count = to_unsigned(9, 4) then -- modulo 10 logic
					Counter_Mod_Ten_Count <= to_unsigned(0, 4);
				end if;
			end if;
		end if;
	end process Rate_Stabilizer_cnt_mod10;

	Generator_Counter_Mod_G_SIZE : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Sender_Counter_Count <= to_unsigned(0, 9);
			else
				if Sender_Counter_Increment = '1' then
					Sender_Counter_Count <= Sender_Counter_Count + 1;
				end if;
				if Sender_Counter_Count = to_unsigned(G_PAYLOAD_OUT_SIZE + 7, 9) AND Sender_Counter_Increment = '1' then -- modulo G_PAYLOAD_OUT_SIZE logic
					Sender_Counter_Count <= to_unsigned(0, 9);
				end if;
			end if;
		end if;
	end process Generator_Counter_Mod_G_SIZE;

end architecture sender_message_organizer_RTL;
