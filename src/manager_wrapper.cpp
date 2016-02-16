
#include "Defs.h"
#include "Manager.h"
#include "Notification.h"
#include "Options.h"
#include "value_classes/ValueID.h"

OpenZWave::Options* Opt;
OpenZWave::Manager* Ptr;
std::string         S_Result;

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

void Create (char* Configuration_Path, char* User_Path, char* Command_Line_Options) {
   std::string S_Config (Configuration_Path);
   std::string S_User   (User_Path);
   std::string S_Line   (Command_Line_Options);

   Opt = OpenZWave::Options::Create (S_Config, S_User, S_Line);

   bool Lock = Opt->Lock ();

   Ptr = OpenZWave::Manager::Create ();
}

void Destroy () {
   Ptr->Destroy ();
}

void Add_Watcher (Notification_Ptr Watcher, void* Context) {
   bool Junk = Ptr->AddWatcher (Watcher, Context);
}

void Split (OpenZWave::Notification* Notif,
            int* M_Type,
            int* Type_ID,
            uint8* Index,
            uint8* Command_Class_ID,
            int* Genre,
            uint8* Node,
            uint8* Command_Class_Index,
            uint32* Home_ID,
            uint8* M_Byte)
{
   *M_Type = Notif->GetType ();
   *Type_ID = Notif->GetValueID ().GetType ();
   *Index = Notif->GetValueID ().GetIndex ();
   *Command_Class_ID = Notif->GetValueID ().GetCommandClassId ();
   *Genre = Notif->GetValueID ().GetGenre ();
   *Node = Notif->GetNodeId ();
   *Command_Class_Index = Notif->GetValueID ().GetInstance ();
   *Home_ID = Notif->GetHomeId ();
   *M_Byte = Notif->GetByte ();
}

const char* Version_String () {
   S_Result = Ptr->getVersionAsString ();

   return (S_Result.c_str () );
}

uint32_t Version_Number () {
   return (Ptr->getVersion ()._v);
}

void Write_Configuration (uint32 ID) {
   Ptr->WriteConfig (ID);
}

int Set_Parameter (uint32 Controller, uint8 Node, uint8 Index, int32 Value, uint8 Num_Bytes) {
   return (Ptr->SetConfigParam (Controller, Node, Index, Value, Num_Bytes) );
}

void Get_Parameter (uint32 Controller, uint8 Node, uint8 Index) {
   Ptr->RequestConfigParam (Controller, Node, Index);
}

void Get_All_Parameters (uint32 Controller, uint8 Node) {
   Ptr->RequestAllConfigParams (Controller, Node);
}

int Bool_Option (char* Name, int* Result) {
   bool        Success;
   std::string S_Name (Name);
   bool        B_Result;

   Success = Opt->GetOptionAsBool (S_Name, &B_Result);
   *Result = B_Result;

   return (Success);
}

int Int_Option (char* Name, int32* Result) {
   bool        Success;
   std::string S_Name (Name);

   Success = Opt->GetOptionAsInt (S_Name, Result);

   return (Success);
}

int String_Option (char* Name, const char** Result) {
   bool         Success;
   std::string  S_Name (Name);

   Success = Opt->GetOptionAsString (S_Name, &S_Result);
   *Result = S_Result.c_str ();

   return (Success);
}

int Option_Type (char* Name) {
   std::string  S_Name (Name);

   return (Opt->GetOptionType (Name) );
}

int Add_Driver (char* Controller_Path, int Interface) {
   std::string                            S_Path (Controller_Path);
   OpenZWave::Driver::ControllerInterface IF     = (OpenZWave::Driver::ControllerInterface) Interface;

   return (Ptr->AddDriver (S_Path, IF) );
}

void Remove_Driver (char* Controller_Path) {
   std::string S_Path (Controller_Path);

   bool Junk = Ptr->RemoveDriver (S_Path);
}

uint8 Controller_Node_ID (uint32 ID) {
   return (Ptr->GetControllerNodeId (ID) );
}

uint8 Static_Update_Controller_ID (uint32 ID) {
   return (Ptr->GetSUCNodeId (ID) );
}

int Primary_Controller (uint32 ID) {
   return (Ptr->IsPrimaryController (ID) );
}

int Static_Update_Controller (uint32 ID) {
   return (Ptr->IsStaticUpdateController (ID) );
}

int Bridge_Controller (uint32 ID) {
   return (Ptr->IsBridgeController (ID) );
}

const char* Library_Version (uint32 ID) {
   S_Result = Ptr->GetLibraryVersion (ID);

   return (S_Result.c_str () );
}

const char* Library_Type (uint32 ID) {
   S_Result = Ptr->GetLibraryTypeName (ID);

   return (S_Result.c_str () );
}

int32 Send_Queue_Count (uint32 ID) {
   return (Ptr->GetSendQueueCount (ID) );
}

void Log_Driver_Statistics (uint32 ID) {
   Ptr->LogDriverStatistics (ID);
}

int Interface_Type (uint32 ID) {
   return (Ptr->GetControllerInterfaceType (ID) );
}

const char* Controller_Path (uint32 ID) {
   S_Result = Ptr->GetControllerPath (ID);

   return (S_Result.c_str () );
}

int Refresh_Node_Info (uint32 ID, uint8 Node) {
   return (Ptr->RefreshNodeInfo (ID, Node) );
}

int Request_Node_State (uint32 ID, uint8 Node) {
   return (Ptr->RequestNodeState (ID, Node) );
}

int Request_Node_Dynamic (uint32 ID, uint8 Node) {
   return (Ptr->RequestNodeDynamic (ID, Node) );
}

int Listening_Device (uint32 ID, uint8 Node) {
   return (Ptr->IsNodeListeningDevice (ID, Node) );
}

int Frequent_Listening_Device (uint32 ID, uint8 Node) {
   return (Ptr->IsNodeFrequentListeningDevice (ID, Node) );
}

int Beaming_Device (uint32 ID, uint8 Node) {
   return (Ptr->IsNodeBeamingDevice (ID, Node) );
}

int Routing_Device (uint32 ID, uint8 Node) {
   return (Ptr->IsNodeRoutingDevice (ID, Node) );
}

int Security_Device (uint32 ID, uint8 Node) {
   return (Ptr->IsNodeSecurityDevice (ID, Node) );
}

uint32 Max_Baud_Rate (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeMaxBaudRate (ID, Node) );
}

uint8 Node_Version (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeVersion (ID, Node) );
}

uint8 Security (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeSecurity (ID, Node) );
}

uint8 Basic_Type (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeBasic (ID, Node) );
}

uint8 Generic_Type (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeGeneric (ID, Node) );
}

uint8 Specific_Type (uint32 ID, uint8 Node) {
   return (Ptr->GetNodeSpecific (ID, Node) );
}

const char* Description (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeType (ID, Node);

   return (S_Result.c_str () );
}

const char* Manufacturer_Name (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeManufacturerName (ID, Node);

   return (S_Result.c_str () );
}

const char* Product_Name (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeProductName (ID, Node);

   return (S_Result.c_str () );
}

const char* Node_Name (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeName (ID, Node);

   return (S_Result.c_str () );
}

const char* Location (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeLocation (ID, Node);

   return (S_Result.c_str () );
}

const char* Manufacturer_ID (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeManufacturerId (ID, Node);

   return (S_Result.c_str () );
}

const char* Product_Type (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeProductType (ID, Node);

   return (S_Result.c_str () );
}

const char* Product_ID (uint32 ID, uint8 Node) {
   S_Result = Ptr->GetNodeProductId (ID, Node);

   return (S_Result.c_str () );
}

void Set_On (uint32 ID, uint8 Node) {
   Ptr->SetNodeOn (ID, Node);
}

void Set_Off (uint32 ID, uint8 Node) {
   Ptr->SetNodeOff (ID, Node);
}

void Set_Level (uint32 ID, uint8 Node, uint8 Level) {
   Ptr->SetNodeLevel (ID, Node, Level);
}

OpenZWave::ValueID New_ValueID (uint32                        Home_ID,
                                uint8                         Node_ID,
                                int                           Genre,
                                uint8                         Command_Class_ID,
                                uint8                         Instance,
                                uint8                         Index,
                                OpenZWave::ValueID::ValueType Type)
{
   OpenZWave::ValueID Result (Home_ID, Node_ID, (OpenZWave::ValueID::ValueGenre)Genre, Command_Class_ID, Instance, Index, Type);

   return Result;
}

int Bool_Value
   (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int* Result)
{
   bool Bool;
   bool Success =
      Ptr->GetValueAsBool
         (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_Bool), &Bool);

   *Result = Bool;

   return (Success);
}
int Byte_Value
   (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, uint8* Result)
{
   return (Ptr->GetValueAsByte
              (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_Byte),
               Result) );
}

int Float_Value
   (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, float* Result)
{
   return (Ptr->GetValueAsFloat
              (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_Decimal),
               Result) );
}

int Int32_Value
   (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int32* Result)
{
   return (Ptr->GetValueAsInt
              (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_Int),
               Result) );
}

int Int16_Value
   (uint8 Index, uint8 Command_Class_ID, int Genre, uint8 Node_ID, uint8 Instance, uint32 Home_ID, int16* Result)
{
   return (Ptr->GetValueAsShort
              (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_Short),
               Result) );
}

int String_Value (uint8        Index,
                  uint8        Command_Class_ID,
                  int          Genre,
                  uint8        Node_ID,
                  uint8        Instance,
                  uint32       Home_ID,
                  const char** Result)
{
   bool         Success;

   Success = Ptr->GetValueAsString
                (New_ValueID (Home_ID, Node_ID, Genre, Command_Class_ID, Instance, Index, OpenZWave::ValueID::ValueType_String),
                 &S_Result);
   *Result = S_Result.c_str ();

   return (Success);
}

