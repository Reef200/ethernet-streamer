--------------------------------------------------------------------------------
--
-- Title            : Receiver SM
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : This module decide the state of the Message_Receiver.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 20/06/2019		 Reef Baltter	 File Creation
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver_SM is
	port(
		clk                       : in  std_logic;
		rst                       : in  std_logic;
		Sink_Valid                : in  std_logic;
		Sink_SOP                  : in  std_logic;
		Sink_EOP                  : in  std_logic;
		Errors                    : out std_logic_vector(3 downto 0);
		Avalon_Data_Valid         : out std_logic;
		Complete_Message_Received : out std_logic
	);
end entity receiver_SM;

architecture receiver_SM_RTL of receiver_SM is
	type state_type is (Idle, Receiving);
	signal receiver_state : state_type := Idle;

begin

	-- Error vector
	Errors <= "0001" when receiver_state = Idle and Sink_Valid = '0' and Sink_SOP = '0' and Sink_EOP = '1'
		else "0010" when receiver_state = Idle and Sink_Valid = '0' and Sink_SOP = '1' and Sink_EOP = '1'
		else "0011" when receiver_state = Idle and Sink_Valid = '0' and Sink_SOP = '1' and Sink_EOP = '1'
		else "0100" when receiver_state = Idle and Sink_Valid = '1' and Sink_SOP = '0' and Sink_EOP = '1'
		else "0101" when receiver_state = Idle and Sink_Valid = '1' and Sink_SOP = '0' and Sink_EOP = '1'
		else "0111" when receiver_state = Idle and Sink_Valid = '1' and Sink_SOP = '1' and Sink_EOP = '1'
		else "1001" when receiver_state = Receiving and Sink_Valid = '0' and Sink_SOP = '0' and Sink_EOP = '1'
		else "1010" when receiver_state = Receiving and Sink_Valid = '0' and Sink_SOP = '1' and Sink_EOP = '1'
		else "1011" when receiver_state = Receiving and Sink_Valid = '0' and Sink_SOP = '1' and Sink_EOP = '1'
		else "1110" when receiver_state = Receiving and Sink_Valid = '1' and Sink_SOP = '1' and Sink_EOP = '1'
		else "1111" when receiver_state = Receiving and Sink_Valid = '1' and Sink_SOP = '1' and Sink_EOP = '1'
		else "0000";

	process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				receiver_state                     <= Idle;
				Avalon_Data_Valid         <= '0';
				Complete_Message_Received <= '0';
			else
				if receiver_state = Idle then
					if Sink_Valid = '1' and Sink_SOP = '1' and Sink_EOP = '0' then
						receiver_state                     <= Receiving;
						Avalon_Data_Valid         <= '1';
						Complete_Message_Received <= '0';
					else
						receiver_state                     <= Idle;
						Avalon_Data_Valid         <= '0';
						Complete_Message_Received <= '0';
					end if;
				elsif receiver_state = Receiving then
					if Sink_Valid = '1' and Sink_SOP = '0' and Sink_EOP = '1' then
						receiver_state                     <= Idle;
						Avalon_Data_Valid         <= '1';
						Complete_Message_Received <= '1';
					elsif Sink_Valid = '1' and Sink_SOP = '0' and Sink_EOP = '0' then
						receiver_state                     <= Receiving;
						Avalon_Data_Valid         <= '1';
						Complete_Message_Received <= '0';
					else
						receiver_state                     <= Receiving;
						Avalon_Data_Valid         <= '0';
						Complete_Message_Received <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture receiver_SM_RTL;
