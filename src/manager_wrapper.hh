#include "Notification.h"
#include <stdint.h>
extern "C" {
   void Create (char* Configuration_Path, char* User_Path, char* Command_Line_Options);
   void Destroy ();

   typedef void (*Notification_Ptr) (OpenZWave::Notification const* _pNotification, void* _context );
   void Add_Watcher (Notification_Ptr Watcher, void* Context);

   void Split (OpenZWave::Notification* Notif, // in
               int* M_Type,                    // all others are out
               int* Type_ID,
               uint8* Index,
               uint8* Command_Class_ID,
               int* Genre,
               uint8* Node,
               uint8* Command_Class_Index,
               uint32* Home_ID,
               uint8* M_Byte);

   const char* Version_String ();
   uint32_t    Version_Number ();

   void Write_Configuration (uint32 ID);
   int  Bool_Option (char* Name, int* Result);
   int  Int_Option (char* Name, int32* Result);
   int  String_Option (char* Name, const char** Result);
   int  Option_Type (char* Name);

   int  Set_Parameter (uint32 Controller, uint8 Node, uint8 Index, int32 Value, uint8 Num_Bytes);
   void Get_Parameter (uint32 Controller, uint8 Node, uint8 Index);
   void Get_All_Parameters (uint32 Controller, uint8 Node);

   int         Add_Driver (char* Controller_Path, int Interface);
   void        Remove_Driver (char* Controller_Path);
   uint8       Controller_Node_ID (uint32 ID);
   uint8       Static_Update_Controller_ID (uint32 ID);
   int         Primary_Controller (uint32 ID);
   int         Static_Update_Controller (uint32 ID);
   int         Bridge_Controller (uint32 ID);
   const char* Library_Version (uint32 ID);
   const char* Library_Type (uint32 ID);
   int32       Send_Queue_Count (uint32 ID);
   void        Log_Driver_Statistics (uint32 ID);
   int         Interface_Type (uint32 ID);
   const char* Controller_Path (uint32 ID);

   int         Refresh_Node_Info (uint32 ID, uint8 Node);
   int         Request_Node_State (uint32 ID, uint8 Node);
   int         Request_Node_Dynamic (uint32 ID, uint8 Node);
   int         Listening_Device (uint32 ID, uint8 Node);
   int         Frequent_Listening_Device (uint32 ID, uint8 Node);
   int         Beaming_Device (uint32 ID, uint8 Node);
   int         Routing_Device (uint32 ID, uint8 Node);
   int         Security_Device (uint32 ID, uint8 Node);
   uint32      Max_Baud_Rate (uint32 ID, uint8 Node);
   uint8       Node_Version (uint32 ID, uint8 Node);
   uint8       Security (uint32 ID, uint8 Node);
   uint8       Basic_Type (uint32 ID, uint8 Node);
   uint8       Generic_Type (uint32 ID, uint8 Node);
   uint8       Specific_Type (uint32 ID, uint8 Node);
   const char* Description (uint32 ID, uint8 Node);
   const char* Manufacturer_Name (uint32 ID, uint8 Node);
   const char* Product_Name (uint32 ID, uint8 Node);
   const char* Node_Name (uint32 ID, uint8 Node);
   const char* Location (uint32 ID, uint8 Node);
   const char* Manufacturer_ID (uint32 ID, uint8 Node);
   const char* Product_Type (uint32 ID, uint8 Node);
   const char* Product_ID (uint32 ID, uint8 Node);
   void        Set_On (uint32 ID, uint8 Node);
   void        Set_Off (uint32 ID, uint8 Node);
   void        Set_Level (uint32 ID, uint8 Node, uint8 Level);

   OpenZWave::ValueID New_ValueID (uint32                        Home_ID,
                                   uint8                         Node_ID,
                                   int                           Genre,
                                   uint8                         Command_Class_ID,
                                   uint8                         Instance,
                                   uint8                         Index,
                                   OpenZWave::ValueID::ValueType Type);

   int Bool_Value
      (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int* Result);
   int Byte_Value
      (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, uint8* Result);
   int Float_Value
      (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, float* Result);
   int Int32_Value
      (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int32* Result);
   int Int16_Value
      (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int16* Result);
   int String_Value (uint8        Index,
                     uint8        Command_Class_ID,
                     int          Genre,
                     uint8        Node_ID,
                     uint8        Instance,
                     uint32       Home_ID,
                     const char** Result);
}
