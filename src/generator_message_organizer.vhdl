--------------------------------------------------------------------------------
--
-- Title            : generator message organizer
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : The module exports the select channel bits out depending on the Generator Counter that counts the byte place in each output message.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 13/06/2019		 Reef Baltter	 File Creation
-- 		 2 			 17/06/2019		 Reef Baltter	 Added Output_Clk_Sync as module output, used to sync data to output clk rate.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity generator_message_organizer is
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
end entity generator_message_organizer;

architecture generator_message_organizer_RTL of generator_message_organizer is
	--signal declerations
	signal Constant_Select             : std_logic;
	signal MUX_constant                : unsigned(8 downto 0);
	signal Generator_Counter_count     : unsigned(8 downto 0);
	signal Organizer_Counter_Select    : std_logic;
	signal Organizer_Counter           : unsigned(8 downto 0);
	signal Generator_Counter_Increment : std_logic;
	signal Counter_Mod_Ten_Count       : unsigned(3 downto 0);
	signal Reduce_Length_Not_Synced    : std_logic;
	signal Data_Ready_Not_Synced       : std_logic;

begin

	-- Asynchronous logic
	Constant_Select             <= '1' when Generator_Counter_count > Current_Length + 7 else '0';
	MUX_constant                <= to_unsigned(15, 9) when Constant_Select = '1' else to_unsigned(8, 9);
	Organizer_Counter_Select    <= '1' when Generator_Counter_count < 9 else '0';
	Organizer_Counter           <= Generator_Counter_count when Organizer_Counter_Select = '1' else MUX_constant;
	Generator_Counter_Increment <= '1' when Counter_Mod_Ten_Count = 0 else '0';
	Output_Clk_Sync             <= Generator_Counter_Increment;

	Data_Ready_Not_Synced         <= '1' when 7 < Generator_Counter_count AND Generator_Counter_count < Current_Length + 8 else '0';
	Generator2Receiver_Data_Ready <= Data_Ready_Not_Synced AND Output_Clk_Sync;
	Reduce_Length_Not_Synced      <= '1' when Generator_Counter_count = to_unsigned(G_PAYLOAD_OUT_SIZE + 7, 9) else '0';
	Reduce_Length                 <= Reduce_Length_Not_Synced AND Output_Clk_Sync;
	Generator_Select              <= std_logic_vector(Organizer_Counter(3 downto 0));

	Rate_Stabilizer_cnt_mod10 : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Counter_Mod_Ten_Count <= to_unsigned(9, 4); -- in order to not mess up the Generator_Counter_Count
			else
				if Generator_Message_Organizer_Start = '1' then
					Counter_Mod_Ten_Count <= Counter_Mod_Ten_Count + 1;
				else
					Counter_Mod_Ten_Count <= "1111";
				end if;
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
				Generator_Counter_count <= to_unsigned(0, 9);
			else
				if Generator_Message_Organizer_Start = '1' then
					if Generator_Counter_Increment = '1' then
						Generator_Counter_count <= Generator_Counter_count + 1;
					end if;
					if Generator_Counter_count = to_unsigned(G_PAYLOAD_OUT_SIZE + 7, 9) AND Generator_Counter_Increment = '1' then -- modulo G_PAYLOAD_OUT_SIZE logic
						Generator_Counter_count <= to_unsigned(0, 9);
					end if;
				else
					Generator_Counter_count <= to_unsigned(0, 9);
				end if;
			end if;
		end if;
	end process Generator_Counter_Mod_G_SIZE;

end architecture generator_message_organizer_RTL;
