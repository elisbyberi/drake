with System.Soft_Links;
with System.Address_To_Named_Access_Conversions;
with System.Tasking.Inside;
with System.Termination;
package body System.Tasking.Stages is

   package Task_Record_Conv is new Address_To_Named_Access_Conversions (
      Inside.Task_Record,
      Inside.Task_Id);

   procedure Unregister;
   procedure Unregister is
   begin
      Soft_Links.Current_Master := Soft_Links.Zero'Access;
      Soft_Links.Enter_Master := Soft_Links.Nop'Access;
      Soft_Links.Complete_Master := Soft_Links.Nop'Access;
   end Unregister;

   function Current_Master return Master_Level;
   function Current_Master return Master_Level is
   begin
      return Inside.Master_Within (Inside.Get_Current_Task_Id);
   end Current_Master;

   procedure Enter_Master;
   procedure Enter_Master is
   begin
      Inside.Enter_Master (Inside.Get_Current_Task_Id);
   end Enter_Master;

   procedure Complete_Master;
   procedure Complete_Master is
   begin
      Inside.Leave_Master (Inside.Get_Current_Task_Id);
   end Complete_Master;

   --  implementation

   procedure Create_Task (
      Priority : Integer;
      Size : Parameters.Size_Type;
      Task_Info : System.Task_Info.Task_Info_Type;
      CPU : Integer;
      Relative_Deadline : Ada.Real_Time.Time_Span;
      Num_Entries : Task_Entry_Index;
      Master : Master_Level;
      State : Task_Procedure_Access;
      Discriminants : Address;
      Elaborated : not null access Boolean;
      Chain : in out Activation_Chain;
      Task_Image : String;
      Created_Task : out Task_Id;
      Build_Entry_Names : Boolean)
   is
      pragma Unreferenced (Priority);
      pragma Unreferenced (Size);
      pragma Unreferenced (Task_Info);
      pragma Unreferenced (CPU);
      pragma Unreferenced (Relative_Deadline);
      pragma Unreferenced (Num_Entries);
      pragma Unreferenced (Elaborated);
      pragma Unreferenced (Task_Image);
      pragma Unreferenced (Build_Entry_Names);
      Parent : Inside.Task_Id;
      New_Task_Id : Inside.Task_Id;
   begin
      Parent := Inside.Get_Current_Task_Id;
      while Inside.Master_Level_Of (Parent) >= Master loop
         Parent := Inside.Parent (Parent);
      end loop;
      Inside.Create (
         New_Task_Id,
         Discriminants,
         State,
         Chain => Chain'Unrestricted_Access,
         Master => Master,
         Parent => Parent);
      Created_Task := Task_Record_Conv.To_Address (New_Task_Id);
   end Create_Task;

   procedure Complete_Activation is
   begin
      Inside.Accept_Activation;
   end Complete_Activation;

   procedure Activate_Tasks (
      Chain_Access : not null access Activation_Chain) is
   begin
      Inside.Activate (Chain_Access);
   end Activate_Tasks;

   procedure Free_Task (T : Task_Id) is
      Id : Inside.Task_Id := Task_Record_Conv.To_Pointer (T);
   begin
      Inside.Wait (Id);
   end Free_Task;

   procedure Move_Activation_Chain (
      From, To : Activation_Chain_Access;
      New_Master : Master_ID) is
   begin
      Inside.Move (From, To, New_Master);
   end Move_Activation_Chain;

begin
   Soft_Links.Current_Master := Current_Master'Access;
   Soft_Links.Enter_Master := Enter_Master'Access;
   Soft_Links.Complete_Master := Complete_Master'Access;
   Termination.Register_Exit (Unregister'Access);
end System.Tasking.Stages;