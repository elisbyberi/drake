pragma License (Unrestricted);
--  implementation unit
with System.Native_Tasks;
with System.Storage_Elements;
with System.Synchronous_Objects;
private with System.Unwind.Mapping;
package System.Tasks is
   pragma Preelaborate;

   --  same as somethings of Tasking

   subtype Master_Level is Integer;

   Foreign_Task_Level : constant Master_Level := 0;
   Environment_Task_Level : constant Master_Level := 1;
   Independent_Task_Level : constant Master_Level := 2;
   Library_Task_Level : constant Master_Level := 3;

   subtype Task_Entry_Index is Integer range 0 .. Integer'Last;

   type Activation_Chain is limited private;
   type Activation_Chain_Access is access all Activation_Chain;
   for Activation_Chain_Access'Storage_Size use 0;
   pragma No_Strict_Aliasing (Activation_Chain_Access);

   --  this shold be called when Standard'Abort_Signal
   procedure When_Abort_Signal;

   type Task_Record (<>) is limited private;
   type Task_Id is access all Task_Record;

   function Current_Task_Id return Task_Id;
   pragma Export (Ada, Current_Task_Id, "__drake_current_task");
   function Main_Task_Id return Task_Id;

   type Master_Record is limited private;
   type Master_Access is access all Master_Record;

   procedure Create (
      T : out Task_Id;
      Params : Address;
      Process : not null access procedure (Params : Address);
      --  name
      Name : String := "";
      --  activation
      Chain : access Activation_Chain := null;
      Elaborated : access Boolean := null;
      --  completion
      Master : Master_Access := null;
      --  rendezvous
      Entry_Last_Index : Task_Entry_Index := 0);

   procedure Wait (T : in out Task_Id; Aborted : out Boolean);
   procedure Detach (T : in out Task_Id);
   function Terminated (T : Task_Id) return Boolean;
   function Activated (T : Task_Id) return Boolean;

   type Free_Mode is (Wait, Detach);
   pragma Discard_Names (Free_Mode);

   function Preferred_Free_Mode (T : not null Task_Id) return Free_Mode;
   procedure Set_Preferred_Free_Mode (T : not null Task_Id; Mode : Free_Mode);

   procedure Get_Stack (
      T : not null Task_Id;
      Addr : out Address;
      Size : out Storage_Elements.Storage_Count);

   --  name
   function Name (T : not null Task_Id)
      return not null access constant String;

   --  abort
   procedure Send_Abort (T : not null Task_Id);
   procedure Enable_Abort;
   procedure Disable_Abort (Aborted : Boolean); -- check and disable
   procedure Lock_Abort;
   procedure Unlock_Abort;
   function Is_Aborted return Boolean;
   function Abort_Attribute
      return access Native_Tasks.Task_Attribute_Of_Abort;

   --  for manual activation (Chain /= null)
   function Elaborated (T : not null Task_Id) return Boolean;
   procedure Accept_Activation (Aborted : out Boolean);
   procedure Activate ( -- activate all task
      Chain : not null access Activation_Chain;
      Aborted : out Boolean);
   procedure Activate (T : not null Task_Id); -- activate single task
   procedure Move (
      From, To : not null access Activation_Chain;
      New_Master : Master_Access);

   --  for manual completion (Master /= null)
   function Parent (T : not null Task_Id) return Task_Id;
   function Master_Level_Of (T : not null Task_Id) return Master_Level;
   function Master_Within return Master_Level;
   procedure Enter_Master;
   procedure Leave_Master;
   procedure Leave_All_Masters; -- for System.Tasking.Stages.Complete_Task
   function Master_Of_Parent (Level : Master_Level) return Master_Access;

   --  for rendezvous
   procedure Cancel_Calls; -- for System.Tasking.Stages.Complete_Task
   procedure Call (
      T : not null Task_Id;
      Item : not null Synchronous_Objects.Queue_Node_Access);
   procedure Uncall (
      T : not null Task_Id;
      Item : not null Synchronous_Objects.Queue_Node_Access;
      Already_Taken : out Boolean);
   procedure Accept_Call (
      Item : out Synchronous_Objects.Queue_Node_Access;
      Params : Address;
      Filter : Synchronous_Objects.Queue_Filter;
      Aborted : out Boolean);
   function Call_Count (
      T : not null Task_Id;
      Params : Address;
      Filter : Synchronous_Objects.Queue_Filter)
      return Natural;
   function Callable (T : not null Task_Id) return Boolean;

   type Cancel_Call_Handler is access procedure (
      X : in out Synchronous_Objects.Queue_Node_Access);

   Cancel_Call_Hook : Cancel_Call_Handler := null;

   --  attribute for Ada.Task_Attributes

   type Attribute_Index is limited private;

   procedure Allocate (Index : in out Attribute_Index);
   procedure Free (Index : in out Attribute_Index);
   procedure Query (
      T : not null Task_Id;
      Index : in out Attribute_Index;
      Process : not null access procedure (Item : Address));
   procedure Set (
      T : not null Task_Id;
      Index : in out Attribute_Index;
      New_Item : not null access function return Address;
      Finalize : not null access procedure (Item : Address));
   procedure Reference (
      T : not null Task_Id;
      Index : in out Attribute_Index;
      New_Item : not null access function return Address;
      Finalize : not null access procedure (Item : Address);
      Result : out Address);
   procedure Clear (
      T : not null Task_Id;
      Index : in out Attribute_Index);

private

   type String_Access is access String;

   type Counter is mod 2 ** 32;
   for Counter'Size use 32;

   type Activation_Error is (None, Any_Exception, Elaboration_Error);
   pragma Discard_Names (Activation_Error);

   type Activation_Chain_Data;
   type Activation_Chain is access all Activation_Chain_Data;
   for Activation_Chain'Size use Standard'Address_Size;
   type Activation_Chain_Data is limited record
      List : Task_Id;
      Task_Count : Counter;
      Activated_Count : aliased Counter;
      Release_Count : aliased Counter;
      Mutex : Synchronous_Objects.Mutex;
      Condition_Variable : Synchronous_Objects.Condition_Variable;
      Error : Activation_Error;
      Merged : Activation_Chain;
      Self : access Activation_Chain;
   end record;
   pragma Suppress_Initialization (Activation_Chain_Data);

   type Task_Kind is (Main, Sub);
   pragma Discard_Names (Task_Kind);

   type Finalize_Handler is access procedure (Params : Address);

   type Attribute is record
      Index : access Attribute_Index;
      Item : Address;
      Finalize : Finalize_Handler;
      Previous : Task_Id;
      Next : Task_Id;
   end record;
   pragma Suppress_Initialization (Attribute);
   type Attribute_Array is array (Natural) of Attribute;
   pragma Suppress_Initialization (Attribute_Array);
   type Attribute_Array_Access is access all Attribute_Array;

   type Activation_State is range 0 .. 4;
   for Activation_State'Size use 8;
   pragma Atomic (Activation_State);
   AS_Suspended : constant Activation_State := 0;
   AS_Created : constant Activation_State := 1;
   AS_Active_Before_Activation : Activation_State := 2;
   AS_Active : constant Activation_State := 3;
   AS_Error : constant Activation_State := 4;

   type Termination_State is range 0 .. 2;
   for Termination_State'Size use 8;
   pragma Atomic (Termination_State);
   TS_Active : constant Termination_State := 0;
   TS_Detached : constant Termination_State := 1;
   TS_Terminated : constant Termination_State := 2;

   type Rendezvous_Record is limited record
      Mutex : aliased Synchronous_Objects.Mutex;
      Calling : aliased Synchronous_Objects.Queue;
   end record;
   pragma Suppress_Initialization (Rendezvous_Record);

   type Rendezvous_Access is access Rendezvous_Record;

   type Abort_Handler is access procedure (T : Task_Id);
   type Process_Handler is access procedure (Params : Address);

   type Task_Record (Kind : Task_Kind) is limited record
      Handle : aliased Native_Tasks.Handle_Type;
      Aborted : Boolean;
      pragma Atomic (Aborted);
      Abort_Handler : Tasks.Abort_Handler;
      Abort_Locking : Natural;
      Abort_Attribute : aliased Native_Tasks.Task_Attribute_Of_Abort;
      Attributes : Attribute_Array_Access;
      Attributes_Length : Natural;
      --  activation / completion
      Activation_State : aliased Tasks.Activation_State;
      pragma Atomic (Activation_State);
      Termination_State : aliased Tasks.Termination_State;
      pragma Atomic (Termination_State);
      Master_Level : Tasks.Master_Level; -- level of self
      Master_Top : Master_Access; -- stack
      --  for sub task
      case Kind is
         when Main =>
            null;
         when Sub =>
            Params : Address;
            Process : not null Process_Handler;
            --  free mode
            Preferred_Free_Mode : Free_Mode;
            --  name
            Name : String_Access;
            --  manual activation
            Activation_Chain : Tasks.Activation_Chain;
            Next_Of_Activation_Chain : Task_Id;
            Activation_Chain_Living : Boolean;
            Elaborated : access Boolean;
            --  manual completion
            Master_Of_Parent : Master_Access;
            Previous_At_Same_Level : Task_Id;
            Next_At_Same_Level : Task_Id;
            Auto_Detach : Boolean;
            --  rendezvous
            Rendezvous : Rendezvous_Access;
            --  stack
            Stack_Attribute : Native_Tasks.Task_Attribute_Of_Stack;
            --  signal alt stack
            Signal_Stack : aliased Unwind.Mapping.Signal_Stack_Type;
      end case;
   end record;
   pragma Suppress_Initialization (Task_Record);

   type Master_Record is limited record
      Previous : Master_Access; -- previous item in stack
      Parent : Task_Id;
      Within : Master_Level; -- level of stack
      List : Task_Id; -- ringed list
      Mutex : aliased Synchronous_Objects.Mutex;
   end record;
   pragma Suppress_Initialization (Master_Record);

--  type TLS_Index is new C.pthread.pthread_key_t;

   type Attribute_Index is limited record
      Index : Integer range -1 .. Integer'Last;
      List : aliased Task_Id;
      Mutex : aliased Synchronous_Objects.Mutex;
   end record;
   pragma Suppress_Initialization (Attribute_Index);

end System.Tasks;
