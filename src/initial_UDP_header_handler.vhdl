--------------------------------------------------------------------------------
--
-- Title            : initial UDP header handler
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Stores the UDP Header fields for the entire message processing time.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 30/04/2019		 Reef Baltter	 File Creation
-- 		 2 			 05/06/2019		 Reef Baltter	 Fixed timing problem, made everythins synchronous
-- 		 3 			 16/06/2019		 Reef Baltter	 Change Handler2Generator_Length and Length signals to unsigned from std_logic_vector
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ethernet_streamer_USE_Package.all;

entity initial_UDP_header_handler is
	generic(G_BusSize, G_HeaderFieldsSize : integer);
	port(
		clk                           : in  std_logic;
		rst                           : in  std_logic;
		Store_UDP_Header              : in  std_logic;
		Receiver_Data                 : in  std_logic_vector(G_BusSize - 1 downto 0);
		UDP_Header_Data_Ready         : out std_logic;
		UDP_Header_Stored             : out std_logic;
		Handler2Generator_Source      : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Destination : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Length      : out unsigned(G_HeaderFieldsSize - 1 downto 0);
		Handler2Generator_Checksum    : out std_logic_vector(G_HeaderFieldsSize - 1 downto 0)
	);
end entity initial_UDP_header_handler;

architecture initial_UDP_header_handler_RTL of initial_UDP_header_handler is

	-- signal declaration
	-- counter signals
	signal Enable_Storing : std_logic            := '0';
	signal Count          : unsigned(2 downto 0) := (others => '0');

	-- DeMUX signals
	signal Source      : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Destination : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');
	signal Length      : unsigned(G_HeaderFieldsSize - 1 downto 0)         := (others => '0');
	signal Checksum    : std_logic_vector(G_HeaderFieldsSize - 1 downto 0) := (others => '0');

begin

	-- Asynchronous logic
	UDP_Header_Stored     <= '1' when count = to_unsigned(7, 3) else '0';
	UDP_Header_Data_Ready <= Enable_Storing;

	-- 8-3 DeMUX
	Source(G_BusSize - 1 downto 0)                     <= (others => '0') when rst = '1'
		else Receiver_Data when count = 0
	;
	Source(G_HeaderFieldsSize - 1 downto G_BusSize)      <= (others => '0') when rst = '1'
		else Receiver_Data when count = 1
	;
	Destination(G_BusSize - 1 downto 0)                <= (others => '0') when rst = '1'
		else Receiver_Data when count = 2
	;
	Destination(G_HeaderFieldsSize - 1 downto G_BusSize) <= (others => '0') when rst = '1'
		else Receiver_Data when count = 3
	;
	Length(G_BusSize - 1 downto 0)                     <= to_unsigned(0, G_BusSize) when rst = '1'
		else unsigned(Receiver_Data) when count = 4
	;
	Length(G_HeaderFieldsSize - 1 downto G_BusSize)      <= to_unsigned(0, G_BusSize) when rst = '1'
		else unsigned(Receiver_Data) when count = 5
	;
	Checksum(G_BusSize - 1 downto 0)                   <= (others => '0') when rst = '1'
		else Receiver_Data when count = 6
	;
	Checksum(G_HeaderFieldsSize - 1 downto G_BusSize)    <= (others => '0') when rst = '1'
		else Receiver_Data when count = 7
	;

	Count_To_Eight_Counter : process(clk) is
		variable counter_enable : boolean := False;

	begin
		if rising_edge(clk) then
			if rst = '1' then
				Count          <= to_unsigned(0, 3);
				Enable_Storing <= '0';
			else
				if Count = 7 then
					Count          <= to_unsigned(0, 3);
					Enable_Storing <= '0';
					counter_enable := FALSE;
				elsif Store_UDP_Header = '1' then
					counter_enable := TRUE;
					Enable_Storing <= '1';
				elsif counter_enable = TRUE then
					Count <= Count + 1;
				else
					Count <= to_unsigned(0, 3);
				end if;
			end if;
		end if;
	end process Count_To_Eight_Counter;

	Header_Registers : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Handler2Generator_Source      <= (others => '0');
				Handler2Generator_Destination <= (others => '0');
				Handler2Generator_Length      <= (others => '0');
				Handler2Generator_Checksum    <= (others => '0');
			elsif Enable_Storing = '1' then
				Handler2Generator_Source      <= Source;
				Handler2Generator_Destination <= Destination;
				Handler2Generator_Length      <= Length;
				Handler2Generator_Checksum    <= Checksum;
			end if;
		end if;
	end process Header_Registers;
end architecture initial_UDP_header_handler_RTL;
