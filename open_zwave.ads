------------------------------------------------------------------------------
--                                                                          --
--                   Ada Open Zwave -- A binding to Open_Zwave              --
--                                                                          --
--                                                                          --
--                                                                          --
--                     Copyright (C) 2016 Anthony Gair                      --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
--                                                                          --
-- 							                    --
------------------------------------------------------------------------------

with Interfaces;

package Open_Zwave is
   type Value_Genre_ID is (Basic, User, Config, System, Invalid);

   type Value_Type_ID is (Bool, Byte, Decimal, Int, List, Schedule, Short, String_Type, Button, Raw, Invalid);

   type Value_U8 is mod 2 ** 8;

   type Controller_ID is mod 2 ** 32;

   type Value_ID is record
      Type_ID             : Value_Type_ID;
      Index               : Value_U8;
      Command_Class_ID    : Value_U8;
      Genre               : Value_Genre_ID;
      Node                : Value_U8;
      Command_Class_Index : Value_U8;
      Home_ID             : Controller_ID;
   end record;

   type Notification_Type_ID is (Value_Added,
                                 Value_Removed,
                                 Value_Changed,
                                 Value_Refreshed,
                                 Group,
                                 Node_New,
                                 Node_Added,
                                 Node_Removed,
                                 Node_Protocol_Info,
                                 Node_Naming,
                                 Node_Event,
                                 Polling_Disabled,
                                 Polling_Enabled,
                                 Scene_Event,
                                 Create_Button,
                                 Delete_Button,
                                 Button_On,
                                 Button_Off,
                                 Driver_Ready,
                                 Driver_Failed,
                                 Driver_Reset,
                                 Essential_Node_Queries_Complete,
                                 Node_Queries_Complete,
                                 Awake_Nodes_Queried,
                                 All_Nodes_Queried_Some_Dead,
                                 All_Nodes_Queried,
                                 Notification_Type,
                                 Driver_Removed,
                                 Invalid);

   type Notification_Byte is mod 2 ** 8;

   type Notification_Info is record
      M_Type     : Notification_Type_ID;
      M_Value_ID : Value_ID;
      M_Byte     : Notification_Byte;
   end record;

   generic -- Manager
      type Context_Data is limited private;

      with procedure Process_Notification (Notification : in Notification_Info; Context : in out Context_Data);
      -- Single notification callback, or "watcher"

      Initial_Configuration_Path : String;
      -- Path to the OpenZWave library config directory, which contains XML descriptions of Z-Wave manufacturers and products

      Initial_User_Path : String;
      -- Path to the application's user data directory, where OpenZWave should store the Z-Wave network configuration and state
      -- Also where OpenZWave will look for the file Options.xml, which contains program option values

      Initial_Command_Line_Options : String;
      -- Additional options in command-line format, usually supplied on the command line

      -- There should only be one instantiation of this generic package
   package Manager is
      -- Activation/deactivation:
      Already_Active : exception; -- Raised when activating while already active

      procedure Activate (Configuration_Path   : in String := Initial_Configuration_Path;
                          User_Path            : in String := Initial_User_Path;
                          Command_Line_Options : in String := Initial_Command_Line_Options);
      -- Activates the interface
      -- Raises Already_Active if the interface is already active
      -- Called automatically with the default arguments when the package is instantiated

      procedure Deactivate;
      -- Deactivates the interface
      -- No effect if the interface is inactive
      -- Called automatically during finalization

      Inactive : exception; -- Raised by any of the following operations if the interface is not active

      -- Version information:
      function Version_String return String;
      -- Returns the version information as a String

      type Version_Number is mod 2 ** 32;
      -- Major number in the most-significant 16 bits; minor number in the least-significant 16 bits

      function Version return Version_Number;
      -- Returns the version information as a Version_Number


      -- Configuration
      procedure Write_Configuration (ID : in Controller_ID);
      -- Writes the configuration information for controller ID to disk
      -- Normally configuration information is written automatically and this operation is not needed

      Invalid_Option : exception; -- Raised if obtaining an option fails

      -- Option names are case insensitive

      function Option (Name : String) return Boolean;
      -- Returns the value of the Boolean option named Name
      -- Raises Invalid_Option if there is no such option, or it is not a Boolean option

      type Option_Integer is new Interfaces.Integer_32;

      function Option (Name : String) return Option_Integer;
      -- Returns the value of the integer option named Name
      -- Raises Invalid_Option if there is no such option, or it is not an integer option

      function Option (Name : String) return String;
      -- Returns the value of the string option named Name
      -- Raises Invalid_Option if there is no such option, or it is not a string option

      type Option_Type_ID is (Invalid, Boolean_Type, Integral, String_Type);

      function Option_Type (Name : String) return Option_Type_ID;
      -- Returns the ID identifying the type of the option named Name
      -- Returns Invalid if there is no such option

      Request_Failed : exception; -- Raised if a node-information request fails

      type Node_ID         is mod 2 ** 8;
      type Parameter_Index is mod 2 ** 8;
      type Parameter_Value is new Interfaces.Integer_32;

      procedure Set_Parameter (Controller : in Controller_ID;
                               Node       : in Node_ID;
                               Index      : in Parameter_Index;
                               Value      : in Parameter_Value;
                               Num_Bytes  : in Natural := 2);
      -- Sends a request to set parameter Index for Node (controlled by Controller) to Value
      -- Num_Bytes specifies the number of bytes of Value to send
      -- Does not wait to see if the request was successful
      -- Raises Request_Failed if a request was not sent

      procedure Get_Parameter (Controller : in Controller_ID; Node : in Node_ID; Index : in Parameter_Index);
      -- Sends a request to obtain parameter Index for Node (controlled by Controller)
      -- Does not wait to see if the request was successful

      procedure Get_All_Parameters (Controller : in Controller_ID; Node : in Node_ID);
      -- Sends a request to obtain all parameters for Node (controlled by Controller)


      -- Drivers:
      type Controller_IF_ID is (Unknown, Serial, Hid);

      Driver_Exists : exception; -- Raised when adding a driver to a controller that already has a driver

      procedure Add_Driver (Controller_Path : in String; Inter_Face : in Controller_IF_ID := Serial);
      -- Adds a driver with an interface as defined by Inter_Face for the controller identified by Controller_Path
      -- Raises Driver_Exists if Controller_Path already has a driver

      procedure Remove_Driver (Controller_Path : in String);
      -- Removes the driver for Controller_Path
      -- No effect if Controller_Path doesn't have a driver

      function Controller_Node_ID (ID : Controller_ID) return Node_ID;
      -- Returns the node ID for controller ID

      function Static_Update_Controller_ID (ID : Controller_ID) return Node_ID;
      -- Returns the node ID for the static-update controller related to controller ID

      function Primary_Controller (ID : Controller_ID) return Boolean;
      -- Returns True if ID is the primary controller; False otherwise

      function Static_Update_Controller (ID : Controller_ID) return Boolean;
      -- Returns True if ID is a static-update controller; False otherwise

      function Bridge_Controller (ID : Controller_ID) return Boolean;
      -- Returns True if ID is a bridge controller; False otherwise

      function Library_Version (ID : Controller_ID) return String;
      -- Returns a String containing the version of the library used by ID

      function Library_Type (ID : Controller_ID) return String;
      -- Returns a String containing the type of library used by ID
      -- "The possible library types are:
      --   "'Static Controller'
      --   "'Controller'
      --   "'Enhanced Slave'
      --   "'Slave'
      --   "'Installer'
      --   "'Routing Slave'
      --   "'Bridge Controller'
      --   "'Device Under Test'
      -- "The controller should never return a slave library type"

      function Send_Queue_Count (ID : Controller_ID) return Natural;
      -- Returns the number of messages in the send queue for ID

      procedure Log_Driver_Statistics (ID : in Controller_ID);
      -- Sends ID's current statistics to the log file

      function Interface_Type (ID : Controller_ID) return Controller_IF_ID;
      -- Returns the type of interface used by ID

      function Controller_Path (ID : Controller_ID) return String;
      -- Returns the identifying path for ID


      -- Polling:
--        type Interval_Value is new Interfaces.Integer_32 range 0 .. Interfaces.Integer_32'Last;
--        -- The C++ uses int32, but I presume negative values are errors
--
--        function Poll_Interval return Interval_Value;
--        -- Returns the time period between polls of a node's state (units not defined)
--
--        procedure Set_Poll_Interval (Milliseconds : in Interval_Value; Interval_Between_Polls : in Boolean);
      -- Sets the time period between polls of a node's state (presumably to Milliseconds, with units of ms
      -- [the C++ comments say "_seconds The length of the polling interval in seconds" but there's no parameter _seconds])
      -- Interval_Between_Polls is not documented in the comments


      -- Operations on Value_IDs

      Invalid_Type : exception; -- Raise by an attempt to obtain an value of an incorrect type

      function Value (ID : Value_ID) return Boolean;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= Bool or the C++ reports a problem

      function Value (ID : Value_ID) return Interfaces.Unsigned_8;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= Byte or the C++ reports a problem

      function Value (ID : Value_ID) return Float;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= Decimal or the C++ reports a problem

      function Value (ID : Value_ID) return Interfaces.Integer_32;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= Int or the C++ reports a problem

      function Value (ID : Value_ID) return Interfaces.Integer_16;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= Short or the C++ reports a problem

      function Value (ID : Value_ID) return String;
      -- Returns the value of ID
      -- Raises Invalid_Type if ID.Type_ID /= String_Type or the C++ reports a problem


      -- Node information:
      procedure Refresh_Node_Info (Controller : in Controller_ID; Node : in Node_ID);
      -- Requests data for Node controlled by Controller
      -- Normally data is requested automatically and this operation is not needed
      -- Raises Request_Failed if the request could not be sent

      procedure Request_Node_State (Controller : in Controller_ID; Node : in Node_ID);
      -- Requests the values for Node controlled by Controller
      -- Raises Request_Failed if the request could not be sent

      procedure Request_Node_Dynamic (Controller : in Controller_ID; Node : in Node_ID);
      -- Requests only the dynamic value for Node controlled by Controller
      -- Raises Request_Failed if the request could not be sent

      function Listening_Device (Controller : Controller_ID; Node : Node_ID) return Boolean;
      -- Returns True if Node (controlled by Controller) is a listening device that does not go to sleep; False otherwise

      function Frequent_Listening_Device (Controller : Controller_ID; Node : Node_ID) return Boolean;
      -- Returns True if Node (controlled by Controller) is a frequent listening device that goes to sleep
      -- but can be woken up by a beam; False otherwise

      function Beaming_Device (Controller : Controller_ID; Node : Node_ID) return Boolean;
      -- Returns True if Node (controlled by Controller) is a beam capable device; False otherwise

      function Routing_Device (Controller : Controller_ID; Node : Node_ID) return Boolean;
      -- Returns True if Node (controlled by Controller) is a routing device that passes messages to other nodes; False otherwise

      function Security_Device (Controller : Controller_ID; Node : Node_ID) return Boolean;
      -- Returns True if Node (controlled by Controller) supports security features; False otherwise

      type Baud_Rate is new Interfaces.Unsigned_32;

      function Max_Baud_Rate (Controller : Controller_ID; Node : Node_ID) return Baud_Rate;
      -- Returns the maximum baud rate for Node (controlled by Controller)

      type Node_Version_Number is mod 2 ** 8;

      function Node_Version (Controller : Controller_ID; Node : Node_ID) return Node_Version_Number;
      -- Returns the version number of Node (controlled by Controller)

      type Security_Byte is mod 2 ** 8;

      function Security (Controller : Controller_ID; Node : Node_ID) return Security_Byte;
      -- Returns the security byte for Node (controlled by Controller)

      type Type_Value is mod 2 ** 8; -- Nodes have various "type bytes"

      function Basic_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value;
      -- Returns the basic type of Node (controlled by Controller)

      function Generic_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value;
      -- Returns the generic type of Node (controlled by Controller)

      function Specific_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value;
      -- Returns the specific type of Node (controlled by Controller)

      function Description (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns a description of Node (controlled by Controller)

--        Max_Neighbors : constant := 29 * 8; -- C++ uses an array of 29 unint8s
--
--        type Neighbor_Bitmap is array (1 .. Max_Neighbors) of Boolean;
--        for Neighbor_Bitmap'Component_Size use 1;
--        pragma Pack (Neighbor_Bitmap);
--        for Neighbor_Bitmap'Size use Max_Neighbors;
--        -- Is there a better representation for this?
--
--        function Neighbors (Controller : Controller_ID; Node : Node_ID) return Neighbor_Bitmap;
--        -- Returns information about the neighbors of Node (controlled by Controller)
--        -- Meaning of uint32 return value not documented

      function Manufacturer_Name (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the manufacturer's name for Node (controlled by Controller)

      function Product_Name (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the product name for Node (controlled by Controller)

      function Node_Name (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the name of Node (controlled by Controller)

      function Location (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the location for Node (controlled by Controller)

      function Manufacturer_ID (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the manufacturer ID for Node (controlled by Controller)

      function Product_Type (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the product type for Node (controlled by Controller)

      function Product_ID (Controller : Controller_ID; Node : Node_ID) return String;
      -- Returns the product ID for Node (controlled by Controller)

      procedure Turn_On (Controller : in Controller_ID; Node : in Node_ID);
      -- Turns Node (controlled by Controller) on
      -- Sets it to the last known level (if supported by Node), or to 100%
      -- Equivalent to Set_Level with Level => 255
      -- Generates a Value_Changed notification

      procedure Turn_Off (Controller : in Controller_ID; Node : in Node_ID);
      -- Turns Node (controlled by Controller) off
      -- Equivalent to Set_Level with Level => 0
      -- Generates a Value_Changed notification

      type Node_Level is mod 2 ** 8;
      -- Valid values are 0 .. 99 and 255; 0 = off, 99 = 100%, 255 = last known level
      -- It's not specified what happens if a value in 100 .. 254 is used

      procedure Set_Level (Controller : in Controller_ID; Node : in Node_ID; Level : in Node_Level);
      -- Sets Node (controlled by Controller) to Level
      -- It's not specified what happens if Level is in 100 .. 254
      -- Generates a Value_Changed notification

      -- Leave the rest for later
   end Manager;
end Open_Zwave;
