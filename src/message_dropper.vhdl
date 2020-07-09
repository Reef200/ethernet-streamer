--------------------------------------------------------------------------------
--
-- Title            : Message Dropper
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Drop entire invalid message by reading every byte of the message from the FIFO.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 30/04/2019		 Reef Baltter	 File Creation
-- 		 2 			 20/05/2019		 Reef Baltter	 Hotfixes after debugging
-- 		 3 			 05/06/2019		 Reef Baltter	 Changed Count signal name to Dropper_Count
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Message_Dropper is
	generic(G_HeaderFieldsSize : integer);
	port(
		clk                    : in  std_logic;
		rst                    : in  std_logic;
		Drop_Message           : in  std_logic;
		Dropped_Message_Length : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
		Message_Dropped        : out std_logic;
		Dropper_Data_Ready     : out std_logic
	);
end entity Message_Dropper;

architecture Message_Dropper_RTL of Message_Dropper is

	-- signal declaration

	signal Dropper_Count          : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Counter_Enable : std_logic                               := '0';
	signal Drop_Done      : std_logic                               := '0';
begin

	Drop_Done          <= '1' when Counter_Enable = '1' AND Dropper_Count = Dropped_Message_Length else '0';
	Dropper_Data_Ready <= Counter_Enable;
	Message_Dropped    <= Drop_Done;

	Dropper_Counter : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Dropper_Count          <= to_unsigned(0, G_HeaderFieldsSize);
				Counter_Enable <= '0';
			else
				if Drop_Message = '1' then
					Counter_Enable <= '1';
					Dropper_Count          <= Dropper_Count + 1;
				elsif Counter_Enable = '1' then
					if Drop_Done = '1' then
						Dropper_Count          <= to_unsigned(0, G_HeaderFieldsSize);
						Counter_Enable <= '0';
					else
						Dropper_Count <= Dropper_Count + 1;
					end if;
				else
					Counter_Enable <= '0';
				end if;
			end if;
		end if;
	end process Dropper_Counter;

end architecture Message_Dropper_RTL;
