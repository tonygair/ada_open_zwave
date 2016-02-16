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
with Ada.Finalization;
with Interfaces.C.Strings;

package body Open_Zwave is
   package body Manager is
      Active : Boolean := False;

      procedure Check_Active;
      -- Raises Inactive if not Active; no effect otherwise
      pragma Inline (Check_Active);

      type Finalizer is new Ada.Finalization.Limited_Controlled with record
         Needs_Finalization : Boolean := True;
      end record;

      overriding procedure Finalize (Object : in out Finalizer);
      -- Calls Deactivate

      Vishnu : Finalizer;
      pragma Unreferenced (Vishnu);

      procedure Activate (Configuration_Path   : in String := Initial_Configuration_Path;
                          User_Path            : in String := Initial_User_Path;
                          Command_Line_Options : in String := Initial_Command_Line_Options)
      is
         procedure Create (Configuration_Path   : in Interfaces.C.Char_Array;
                           User_Path            : in Interfaces.C.Char_Array;
                           Command_Line_Options : in Interfaces.C.Char_Array);
         pragma Import (C, Create, "Create");
      begin -- Activate
         if Active then
            raise Already_Active;
         end if;

         Create (Configuration_Path   => Interfaces.C.To_C (Configuration_Path),
                 User_Path            => Interfaces.C.To_C (User_Path),
                 Command_Line_Options => Interfaces.C.To_C (Command_Line_Options) );
         Active := True;
      end Activate;

      procedure Deactivate is
         procedure Destroy;
         pragma Import (C, Destroy, "Destroy");
      begin -- Deactivate
         if not Active then
            return;
         end if;

         Destroy;
         Active := False;
      end Deactivate;

      function Version_String return String is
         function C_Version_String return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Version_String, "Version_String");
      begin -- Version_String
         Check_Active;

         return Interfaces.C.Strings.Value (C_Version_String);
      end Version_String;

      function Version return Version_Number is
         type C_Number is mod 2 ** 32;
         pragma Convention (C, C_Number);

         function C_Version return C_Number;
         pragma Import (C, C_Version, "Version");
      begin -- Version
         Check_Active;

         return Version_Number (C_Version);
      end Version;

      type C_Controller_ID is new Controller_ID;
      pragma Convention (C, C_Controller_ID);

      procedure Write_Configuration (ID : in Controller_ID) is
         procedure C_Write (ID : in C_Controller_ID);
         pragma Import (C, C_Write, "Write_Configuration");
      begin -- Write_Configuration
         Check_Active;
         C_Write (ID => C_Controller_ID (ID) );
      end Write_Configuration;

      use type Interfaces.C.Int;

      function Option (Name : String) return Boolean is
         function Bool (Name : Interfaces.C.char_array; Result : access Interfaces.C.Int) return Interfaces.C.int;
         pragma Import (C, Bool, "Bool_Option");

         Success : Interfaces.C.Int;
         Result  : aliased Interfaces.C.Int;
      begin -- Option
         Check_Active;
         Success := Bool (Interfaces.C.To_C (Name), Result'Access);

         if Success = 0 then
            raise Invalid_Option;
         end if;

         return Result /= 0;
      end Option;

      function Option (Name : String) return Option_Integer is
         type C_Integer is new Interfaces.Integer_32;
         pragma Convention (C, C_Integer);

         function C_Option (Name : Interfaces.C.char_array; Result : access C_Integer) return Interfaces.C.Int;
         pragma Import (C, C_Option, "Int_Option");

         Success : Interfaces.C.Int;
         Result  : aliased C_Integer;
      begin -- Option
         Check_Active;
         Success := C_Option (Interfaces.C.To_C (Name), Result'Access);

         if Success = 0 then
            raise Invalid_Option;
         end if;

         return Option_Integer (Result);
      end Option;

      function Option (Name : String) return String is
         function C_String (Name : Interfaces.C.char_array; Result : access Interfaces.C.Strings.Chars_Ptr)
         return Interfaces.C.Int;
         pragma Import (C, C_String, "String_Option");

         Success : Interfaces.C.Int;
         Result  : aliased Interfaces.C.Strings.chars_ptr;
      begin -- Option
         Check_Active;
         Success := C_String (Interfaces.C.To_C (Name), Result'Access);

         if Success = 0 then
            raise Invalid_Option;
         end if;

         return Interfaces.C.Strings.Value (Result);
      end Option;

      function Option_Type (Name : String) return Option_Type_ID is
         function C_Type (Name : Interfaces.C.char_array) return Interfaces.C.Int;
         pragma Import (C, C_Type, "Option_Type");
      begin -- Option_Type
         Check_Active;

         return Option_Type_ID'Val (C_Type (Interfaces.C.To_C (Name) ) );
      end Option_Type;

      type C_Node_ID is  mod 2 ** 8;
      pragma Convention (C, C_Node_ID);

      type C_Parameter_Index is  mod 2 ** 8;
      pragma Convention (C, C_Parameter_Index);

      type CU8 is new Value_U8;
      pragma Convention (C, CU8);

      procedure Set_Parameter (Controller : in Controller_ID;
                               Node       : in Node_ID;
                               Index      : in Parameter_Index;
                               Value      : in Parameter_Value;
                               Num_Bytes  : in Natural := 2)
      is
         type C_Parameter_Value is new Interfaces.Integer_32;
         pragma Convention (C, C_Parameter_Value);

         function C_Set (Controller : C_Controller_ID;
                         Node       : C_Node_ID;
                         Index      : C_Parameter_Index;
                         Value      : C_Parameter_Value;
                         Num_Bytes  : CU8)
         return Interfaces.C.Int;
         pragma Import (C, C_Set, "Set_Parameter");
      begin -- Set_Parameter
         Check_Active;

         if C_Set (C_Controller_ID (Controller),
                   C_Node_ID (Node),
                   C_Parameter_Index (Index),
                   C_Parameter_Value (Value),
                   CU8 (Num_Bytes) ) = 0
         then
            raise Request_Failed;
         end if;
      end Set_Parameter;

      procedure Get_Parameter (Controller : in Controller_ID; Node : in Node_ID; Index : in Parameter_Index) is
         procedure C_Get (Controller : in C_Controller_ID; Node : in C_Node_ID; Index : in C_Parameter_Index);
         pragma Import (C, C_Get, "Get_Parameter");
      begin -- Get_Parameter
         Check_Active;
         C_Get (Controller => C_Controller_ID (Controller), Node => C_Node_ID (Node), Index => C_Parameter_Index (Index) );
      end Get_Parameter;

      procedure Get_All_Parameters (Controller : in Controller_ID; Node : in Node_ID) is
         procedure C_Get (Controller : in C_Controller_ID; Node : in C_Node_ID);
         pragma Import (C, C_Get, "Get_All_Parameters");
      begin -- Get_All_Parameters
         Check_Active;
         C_Get (Controller => C_Controller_ID (Controller), Node => C_Node_ID (Node) );
      end Get_All_Parameters;

      procedure Add_Driver (Controller_Path : in String; Inter_Face : in Controller_IF_ID := Serial) is
         function C_Add (Controller_Path : in Interfaces.C.Char_Array; Inter_Face : in Interfaces.C.Int) return Interfaces.C.Int;
         pragma Import (C, C_Add, "Add_Driver");
      begin -- Add_Driver
         Check_Active;

         If C_Add (Controller_Path => Interfaces.C.To_C (Controller_Path), Inter_Face => Controller_IF_ID'Pos (Inter_Face) ) = 0
         then
            raise Driver_Exists;
         end if;
      end Add_Driver;

      procedure Remove_Driver (Controller_Path : in String) is
         procedure C_Remove (Controller_Path : in Interfaces.C.Char_Array);
         pragma Import (C, C_Remove, "Remove_Driver");
      begin -- Remove_Driver
         Check_Active;
         C_Remove (Controller_Path => Interfaces.C.To_C (Controller_Path) );
      end Remove_Driver;

      function Controller_Node_ID (ID : Controller_ID) return Node_ID is
         function C_Node (ID : C_Controller_ID) return C_Node_ID;
         pragma Import (C, C_Node, "Controller_Node_ID");
      begin -- Controller_Node_ID
         Check_Active;

         return Node_ID (C_Node (C_Controller_ID (ID) ) );
      end Controller_Node_ID;

      function Static_Update_Controller_ID (ID : Controller_ID) return Node_ID is
         function C_SUC (ID : C_Controller_ID) return C_Node_ID;
         pragma Import (C, C_SUC, "Static_Update_Controller_ID");
      begin -- Static_Update_Controller_ID
         Check_Active;

         return Node_ID (C_SUC (C_Controller_ID (ID) ) );
      end Static_Update_Controller_ID;

      function Primary_Controller (ID : Controller_ID) return Boolean is
         function C_Primary (ID : C_Controller_ID) return Interfaces.C.Int;
         pragma Import (C, C_Primary, "Primary_Controller");
      begin -- Primary_Controller
         Check_Active;

         return C_Primary (C_Controller_ID (ID) ) /= 0;
      end Primary_Controller;

      function Static_Update_Controller (ID : Controller_ID) return Boolean is
         function C_SUC (ID : C_Controller_ID) return Interfaces.C.Int;
         pragma Import (C, C_SUC, "Static_Update_Controller");
      begin -- Static_Update_Controller
         Check_Active;

         return C_SUC (C_Controller_ID (ID) ) /= 0;
      end Static_Update_Controller;

      function Bridge_Controller (ID : Controller_ID) return Boolean is
         function C_Bridge (ID : C_Controller_ID) return Interfaces.C.Int;
         pragma Import (C, C_Bridge, "Bridge_Controller");
      begin -- Bridge_Controller
         Check_Active;

         return C_Bridge (C_Controller_ID (ID) ) /= 0;
      end Bridge_Controller;

      function Library_Version (ID : Controller_ID) return String is
         function C_Library (ID : C_Controller_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Library, "Library_Version");
      begin -- Library_Version
         Check_Active;

         return Interfaces.C.Strings.Value (C_Library (C_Controller_ID (ID) ) );
      end Library_Version;

      function Library_Type (ID : Controller_ID) return String is
         function C_Type (ID : C_Controller_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Type, "Library_Type");
      begin -- Library_Type
         Check_Active;

         return Interfaces.C.Strings.Value (C_Type (C_Controller_ID (ID) ) );
      end Library_Type;

      function Send_Queue_Count (ID : Controller_ID) return Natural is
         type CI32 is new Interfaces.Integer_32;
         pragma Convention (C, CI32);

         function C_Count (ID : C_Controller_ID) return CI32;
         pragma Import (C, C_Count, "Send_Queue_Count");
      begin -- Send_Queue_Count
         Check_Active;

         return Integer (C_Count (C_Controller_ID (ID) ) );
      end Send_Queue_Count;

      procedure Log_Driver_Statistics (ID : in Controller_ID) is
         procedure C_Log (ID : in C_Controller_ID);
         pragma Import (C, C_Log, "Log_Driver_Statistics");
      begin -- Log_Driver_Statistics
         Check_Active;
         C_Log (ID => C_Controller_ID (ID) );
      end Log_Driver_Statistics;

      function Interface_Type (ID : Controller_ID) return Controller_IF_ID is
         function C_Type (ID : C_Controller_ID) return Interfaces.C.Int;
         pragma Import (C, C_Type, "Interface_Type");
      begin -- Interface_Type
         Check_Active;

         return Controller_IF_ID'Val (C_Type (C_Controller_ID (ID) ) );
      end Interface_Type;

      function Controller_Path (ID : Controller_ID) return String is
         function C_Path (ID : C_Controller_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Path, "Controller_Path");
      begin -- Controller_Path
         Check_Active;

         return Interfaces.C.Strings.Value (C_Path (C_Controller_ID (ID) ) );
      end Controller_Path;

--        function Poll_Interval return Interval_Value;
--
--        procedure Set_Poll_Interval (Milliseconds : in Interval_Value; Interval_Between_Polls : in Boolean);

      function Value (ID : Value_ID) return Boolean is
         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access Interfaces.C.Int)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "Bool_Value");

         Result : aliased Interfaces.C.Int;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= Bool then
            raise Invalid_Type with "Value (Bool) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (Bool) C++ returned zero";
         end if;

         return Result /= 0;
      end Value;

      function Value (ID : Value_ID) return Interfaces.Unsigned_8 is
         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access CU8)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "Byte_Value");

         Result : aliased CU8;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= Byte then
            raise Invalid_Type with "Value (Byte) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (Byte) C++ returned zero";
         end if;

         return Interfaces.Unsigned_8 (Result);
      end Value;

      function Value (ID : Value_ID) return Float is
         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access Interfaces.C.C_float)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "Float_Value");

         Result : aliased Interfaces.C.C_float;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= Decimal then
            raise Invalid_Type with "Value (Decimal) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (Decimal) C++ returned zero";
         end if;

         return Float (Result);
      end Value;

      function Value (ID : Value_ID) return Interfaces.Integer_32 is
         type Int32 is new Interfaces.Integer_32;
         pragma Convention (C, Int32);

         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access Int32)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "Int32_Value");

         Result : aliased Int32;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= Int then
            raise Invalid_Type with "Value (Int) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (Int) C++ returned zero";
         end if;

         return Interfaces.Integer_32 (Result);
      end Value;

      function Value (ID : Value_ID) return Interfaces.Integer_16 is
         type Int16 is new Interfaces.Integer_16;
         pragma Convention (C, Int16);

         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access Int16)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "Int16_Value");

         Result : aliased Int16;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= Short then
            raise Invalid_Type with "Value (Short) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (Short) C++ returned zero";
         end if;

         return Interfaces.Integer_16 (Result);
      end Value;

      function Value (ID : Value_ID) return String is
         function C_Value (Index            : CU8;
                           Command_Class_ID : CU8;
                           Genre            : Interfaces.C.Int;
                           Node_ID          : C_Node_ID;
                           Instance         : CU8;
                           Home_ID          : C_Controller_ID;
                           Result           : access Interfaces.C.Strings.Chars_Ptr)
         return Interfaces.C.Int;
         pragma Import (C, C_Value, "String_Value");

         Result : aliased Interfaces.C.Strings.Chars_Ptr;
      begin -- Value
         Check_Active;

         if ID.Type_ID /= String_Type then
            raise Invalid_Type with "Value (String_Type) Type is " & Value_Type_ID'Image (ID.Type_ID);
         end if;

         if C_Value (CU8 (ID.Index),
                     CU8 (ID.Command_Class_ID),
                     Value_Genre_ID'Pos (ID.Genre),
                     C_Node_ID (ID.Node),
                     CU8 (ID.Command_Class_Index),
                     C_Controller_ID (ID.Home_ID),
                     Result'Access) = 0
         then
            raise Invalid_Type with "Value (String_Type) C++ returned zero";
         end if;

         return Interfaces.C.Strings.Value (Result);
      end Value;

      procedure Refresh_Node_Info (Controller : in Controller_ID; Node : in Node_ID) is
         function C_Refresh (Controller : C_Controller_ID; Node : C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Refresh, "Refresh_Node_Info");
      begin -- Refresh_Node_Info
         Check_Active;

         if C_Refresh (C_Controller_ID (Controller), C_Node_ID (Node) ) = 0 then
            raise Request_Failed;
         end if;
      end Refresh_Node_Info;

      procedure Request_Node_State (Controller : in Controller_ID; Node : in Node_ID) is
         function C_State (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_State, "Request_Node_State");
      begin -- Request_Node_State
         Check_Active;

         if C_State (C_Controller_ID (Controller), C_Node_ID (Node) ) = 0 then
            raise Request_Failed;
         end if;
      end Request_Node_State;

      procedure Request_Node_Dynamic (Controller : in Controller_ID; Node : in Node_ID) is
         function C_Dynamic (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Dynamic, "Request_Node_Dynamic");
      begin -- Request_Node_Dynamic
         Check_Active;

         if C_Dynamic (C_Controller_ID (Controller), C_Node_ID (Node) ) = 0 then
            raise Request_Failed;
         end if;
      end Request_Node_Dynamic;

      function Listening_Device (Controller : Controller_ID; Node : Node_ID) return Boolean is
         function C_Device (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Device, "Listening_Device");
      begin -- Listening_Device
         Check_Active;

         return C_Device (C_Controller_ID (Controller), C_Node_ID (Node) ) /= 0;
      end Listening_Device;

      function Frequent_Listening_Device (Controller : Controller_ID; Node : Node_ID) return Boolean is
         function C_Device (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Device, "Frequent_Listening_Device");
      begin -- Frequent_Listening_Device
         Check_Active;

         return C_Device (C_Controller_ID (Controller), C_Node_ID (Node) ) /= 0;
      end Frequent_Listening_Device;

      function Beaming_Device (Controller : Controller_ID; Node : Node_ID) return Boolean is
         function C_Device (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Device, "Beaming_Device");
      begin -- Beaming_Device
         Check_Active;

         return C_Device (C_Controller_ID (Controller), C_Node_ID (Node) ) /= 0;
      end Beaming_Device;

      function Routing_Device (Controller : Controller_ID; Node : Node_ID) return Boolean is
         function C_Device (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Device, "Routing_Device");
      begin -- Routing_Device
         Check_Active;

         return C_Device (C_Controller_ID (Controller), C_Node_ID (Node) ) /= 0;
      end Routing_Device;

      function Security_Device (Controller : Controller_ID; Node : Node_ID) return Boolean is
         function C_Device (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.int;
         pragma Import (C, C_Device, "Security_Device");
      begin -- Security_Device
         Check_Active;

         return C_Device (C_Controller_ID (Controller), C_Node_ID (Node) ) /= 0;
      end Security_Device;

      function Max_Baud_Rate (Controller : Controller_ID; Node : Node_ID) return Baud_Rate is
         type U32 is mod 2 ** 32;
         pragma Convention (C, U32);

         function Rate (Controller : in C_Controller_ID; Node : in C_Node_ID) return U32;
         pragma Import (C, Rate, "Max_Baud_Rate");
      begin -- Max_Baud_Rate
         Check_Active;

         return Baud_Rate (Rate (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Max_Baud_Rate;

      function Node_Version (Controller : Controller_ID; Node : Node_ID) return Node_Version_Number is
         function C_Version (Controller : in C_Controller_ID; Node : in C_Node_ID) return CU8;
         pragma Import (C, C_Version, "Node_Version");
      begin -- Node_Version
         Check_Active;

         return Node_Version_Number (C_Version (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Node_Version;

      function Security (Controller : Controller_ID; Node : Node_ID) return Security_Byte is
         function C_Security (Controller : in C_Controller_ID; Node : in C_Node_ID) return CU8;
         pragma Import (C, C_Security, "Security");
      begin -- Security
         Check_Active;

         return Security_Byte (C_Security (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Security;

      function Basic_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value is
         function C_Type (Controller : in C_Controller_ID; Node : in C_Node_ID) return CU8;
         pragma Import (C, C_Type, "Basic_Type");
      begin -- Basic_Type
         Check_Active;

         return Type_Value (C_Type (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Basic_Type;

      function Generic_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value is
         function C_Type (Controller : in C_Controller_ID; Node : in C_Node_ID) return CU8;
         pragma Import (C, C_Type, "Generic_Type");
      begin -- Generic_Type
         Check_Active;

         return Type_Value (C_Type (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Generic_Type;

      function Specific_Type (Controller : Controller_ID; Node : Node_ID) return Type_Value is
         function C_Type (Controller : in C_Controller_ID; Node : in C_Node_ID) return CU8;
         pragma Import (C, C_Type, "Specific_Type");
      begin -- Specific_Type
         Check_Active;

         return Type_Value (C_Type (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Specific_Type;

      function Description (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Description (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Description, "Description");
      begin -- Description
         Check_Active;

         return Interfaces.C.Strings.Value (C_Description (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Description;

      function Manufacturer_Name (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Name (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Name, "Manufacturer_Name");
      begin -- Manufacturer_Name
         Check_Active;

         return Interfaces.C.Strings.Value (C_Name (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Manufacturer_Name;

      function Product_Name (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Name (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Name, "Product_Name");
      begin -- Product_Name
         Check_Active;

         return Interfaces.C.Strings.Value (C_Name (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Product_Name;

      function Node_Name (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Name (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Name, "Node_Name");
      begin -- Node_Name
         Check_Active;

         return Interfaces.C.Strings.Value (C_Name (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Node_Name;

      function Location (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Location (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Location, "Location");
      begin -- Location
         Check_Active;

         return Interfaces.C.Strings.Value (C_Location (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Location;

      function Manufacturer_ID (Controller : Controller_ID; Node : Node_ID) return String is
         function C_ID (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_ID, "Manufacturer_ID");
      begin -- Manufacturer_ID
         Check_Active;

         return Interfaces.C.Strings.Value (C_ID (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Manufacturer_ID;

      function Product_Type (Controller : Controller_ID; Node : Node_ID) return String is
         function C_Type (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_Type, "Product_Type");
      begin -- Product_Type
         Check_Active;

         return Interfaces.C.Strings.Value (C_Type (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Product_Type;

      function Product_ID (Controller : Controller_ID; Node : Node_ID) return String is
         function C_ID (Controller : in C_Controller_ID; Node : in C_Node_ID) return Interfaces.C.Strings.Chars_Ptr;
         pragma Import (C, C_ID, "Product_ID");
      begin -- Product_ID
         Check_Active;

         return Interfaces.C.Strings.Value (C_ID (C_Controller_ID (Controller), C_Node_ID (Node) ) );
      end Product_ID;

      procedure Turn_On (Controller : in Controller_ID; Node : in Node_ID) is
         procedure Set_On (Controller : in C_Controller_ID; Node : in C_Node_ID);
         pragma Import (C, Set_On, "Set_On");
      begin --Turn_On
         Check_Active;

         Set_On (Controller => C_Controller_ID (Controller), Node => C_Node_ID (Node) );
      end Turn_On;

      procedure Turn_Off (Controller : in Controller_ID; Node : in Node_ID) is
         procedure Set_Off (Controller : in C_Controller_ID; Node : in C_Node_ID);
         pragma Import (C, Set_Off, "Set_Off");
      begin -- Turn_Off
         Check_Active;

         Set_Off (Controller => C_Controller_ID (Controller), Node => C_Node_ID (Node) );
      end Turn_Off;

      procedure Set_Level (Controller : in Controller_ID; Node : in Node_ID; Level : in Node_Level) is
         procedure C_Set_Level (Controller : in C_Controller_ID; Node : in C_Node_ID; Level : in CU8);
         pragma Import (C, C_Set_Level, "Set_Level");
      begin -- Set_Level
         Check_Active;

         C_Set_Level (Controller => C_Controller_ID (Controller), Node => C_Node_ID (Node), Level => CU8 (Level) );
      end Set_Level;

      procedure Check_Active is
         -- Empty
      begin -- Check_Active
         if not Active then
            raise Inactive;
         end if;
      end Check_Active;

      overriding procedure Finalize (Object : in out Finalizer) is
      begin -- Finalize
         if Object.Needs_Finalization then
            Deactivate;
            Object.Needs_Finalization := False;
         end if;
      end Finalize;

      type Notification_Ptr is access all Integer;
      pragma Convention (C, Notification_Ptr);

      type Watcher_Ptr is access procedure (Notification_Info : in Notification_Ptr; Context : access Context_Data);
      pragma Convention (C, Watcher_Ptr);

      procedure Add_Watcher (Watcher : in Watcher_Ptr; Context : access Context_Data);
      pragma Import (C, Add_Watcher, "Add_Watcher");

      procedure Local (Notification_Info : in Notification_Ptr; Context : access Context_Data);
      pragma Convention (C, Local);

      procedure Local (Notification_Info : in Notification_Ptr; Context : access Context_Data) is
         procedure Split (Notification_Info   : in     Notification_Ptr;
                          M_Type              :    out Interfaces.C.Int;
                          Type_ID             :    out Interfaces.C.Int;
                          Index               :    out CU8;
                          Command_Class_ID    :    out CU8;
                          Genre               :    out Interfaces.C.Int;
                          Node                :    out CU8;
                          Command_Class_Index :    out CU8;
                          Home_ID             :    out C_Controller_ID;
                          M_Byte              :    out CU8);
         pragma Import (C, Split, "Split");

         M_Type              : Interfaces.C.Int;
         Type_ID             : Interfaces.C.Int;
         Index               : CU8;
         Command_Class_ID    : CU8;
         Genre               : Interfaces.C.Int;
         Node                : CU8;
         Command_Class_Index : CU8;
         Home_ID             : C_Controller_ID;
         M_Byte              : CU8;
	 Notification        : Open_Zwave.Notification_Info;
      begin -- Local
         Split (Notification_Info   => Notification_Info,
                M_Type              => M_Type,
                Type_ID             => Type_ID,
                Index               => Index,
                Command_Class_ID    => Command_Class_ID,
                Genre               => Genre,
                Node                => Node,
                Command_Class_Index => Command_Class_Index,
                Home_ID             => Home_ID,
                M_Byte              => M_Byte);

         if M_Type in 0 .. Notification_Type_ID'Pos (Notification_Type_ID'Pred (Invalid) ) then
            Notification.M_Type := Notification_Type_ID'Val (M_Type);
         else
            Notification.M_Type := Invalid;
         end if;

         if Type_ID in 0 .. Value_Type_ID'Pos (Value_Type_ID'Pred (Invalid) ) then
            Notification.M_Value_ID.Type_ID := Value_Type_ID'Val (Type_ID);
         else
            Notification.M_Value_ID.Type_ID := Invalid;
         end if;

         Notification.M_Value_ID.Index := Value_U8 (Index);
         Notification.M_Value_ID.Command_Class_ID := Value_U8 (Command_Class_ID);

         if Genre in 0 .. Value_Genre_ID'Pos (Value_Genre_ID'Pred (Invalid) ) then
            Notification.M_Value_ID.Genre := Value_Genre_ID'Val (Genre);
         else
            Notification.M_Value_ID.Genre := Invalid;
         end if;

         Notification.M_Value_ID.Node := Value_U8 (Node);
         Notification.M_Value_ID.Command_Class_Index := Value_U8 (Command_Class_Index);
         Notification.M_Value_ID.Home_ID := Controller_ID (Home_ID);

         Notification.M_Byte := Notification_Byte (M_Byte);

         Process_Notification (Notification => Notification, Context => Context.all);
      end Local;

      Context : aliased Context_Data;
   begin -- Manager
      Activate;
      Add_Watcher (Watcher => Local'Access, Context => Context'Access);
   end Manager;
end Open_Zwave;
