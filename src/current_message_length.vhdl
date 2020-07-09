--------------------------------------------------------------------------------
--
-- Title            : Current Message Length 
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Stores the raw message length at start and reduce the length after each sending. Notifying the Generator SM when the length is zero, meaning it completed the sendings.
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

entity Current_Message_Length is
	generic(G_HeaderFieldsSize : integer);
	port(
		clk                             : in  std_logic;
		rst                             : in  std_logic;
		Handler2Generator_Message_Start : in  std_logic;
		Reduce_Length                   : in  std_logic;
		Handler2Generator_Length        : in  unsigned(G_HeaderFieldsSize - 1 downto 0);
		Current_Length                  : out unsigned(G_HeaderFieldsSize - 1 downto 0);
		Message_Done  : out std_logic
	);
end entity Current_Message_Length;

architecture Current_Message_Length_RTL of Current_Message_Length is

	-- signal declaration
	signal Enable_Storing         : std_logic                                 := '0';
	signal Zeroed_Length          : std_logic                                 := '0';
	signal Length_To_Store        : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Current_Length_Storing : unsigned(G_HeaderFieldsSize - 1 downto 0) := (others => '0');

begin

	-- Asynchronous logic
	Enable_Storing                 <= Reduce_Length OR Handler2Generator_Message_Start;
	Length_To_Store                <= Current_Length_Storing when Reduce_Length = '1' else Handler2Generator_Length;
	Current_Length_Storing         <= Current_Length - G_PAYLOAD_OUT_SIZE when to_integer(Current_Length) - G_PAYLOAD_OUT_SIZE > 0 else (others => '0');
	Zeroed_Length                  <= '1' when Current_Length_Storing = to_unsigned(0, G_HeaderFieldsSize) else '0';
	Message_Done <= Zeroed_Length AND Reduce_Length;

	Curr_len_Reg : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Current_Length <= (others => '0');
			else
				if Enable_Storing = '1' then
					Current_Length <= Length_To_Store;
				end if;
			end if;
		end if;
	end process Curr_len_Reg;

end architecture Current_Message_Length_RTL;
