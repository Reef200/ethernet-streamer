--------------------------------------------------------------------------------
--
-- Title            : handler_SM
-- Project          : Ethernet Streamer
-- Author           : Reef Baltter
-- Company          : Talya corporation
--
--------------------------------------------------------------------------------
--
-- Description      : Package for all the constants in the project.
--
--------------------------------------------------------------------------------
--
-- Ver/Rev History	:
-- 	 Version No. 	 Date 			 Author 		 Description
-- 		 1 			 01/05/2019		 Reef Baltter	 File Creation
-- 		 2 			 06/05/2019		 Reef Baltter	 Added halfDC const.
--		 3			 12/05/2019		 Reef Baltter	 Added BusSize, HeaderFieldsSize, ErrorsSize const.
--------------------------------------------------------------------------------
package ethernet_streamer_USE_Package is
	-- from requirements 
	constant G_PAYLOAD_OUT_SIZE : integer := 500; -- Default value is 500
	constant G_MIN_MSG_LEN      : integer := 64; -- Default value is 64
	constant G_MAX_MSG_LEN      : integer := 1500; -- Default value is 1500
	--for clk generation
	constant G_halfDC           : time    := 4 ns;
	--for instatntiation
	constant G_BusSize          : integer := 8;
	constant G_HeaderFieldsSize : integer := 16;
	constant G_ErrorsSize       : integer := 4;

end package ethernet_streamer_USE_Package;
