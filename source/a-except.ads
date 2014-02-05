pragma License (Unrestricted);
--  with Ada.Streams;
private with System.Unwind;
package Ada.Exceptions is
   pragma Preelaborate;

   type Exception_Id is private;
   pragma Preelaborable_Initialization (Exception_Id);
   Null_Id : constant Exception_Id;

   function Exception_Name (Id : Exception_Id) return String;
   function Wide_Exception_Name (Id : Exception_Id) return Wide_String;
   function Wide_Wide_Exception_Name (Id : Exception_Id)
      return Wide_Wide_String;

   type Exception_Occurrence is limited private;
   pragma Preelaborable_Initialization (Exception_Occurrence);
   type Exception_Occurrence_Access is access all Exception_Occurrence;
   Null_Occurrence : constant Exception_Occurrence;

   procedure Raise_Exception (E : Exception_Id; Message : String := "");
   pragma No_Return (Raise_Exception);
   pragma Import (Ada, Raise_Exception, "ada__exceptions__raise_exception");
   function Exception_Message (X : Exception_Occurrence) return String;
   procedure Reraise_Occurrence (X : Exception_Occurrence);

   --  [gcc-4.7] compiler lose sight of System if this has a nested package

--  package Implementation is
--
--    procedure Raise_Exception_From_Here (
--       E : Exception_Id;
--       File : String := Debug.File;
--       Line : Integer := Debug.Line);
--    pragma No_Return (Raise_Exception_From_Here);
--    pragma Import (Ada, Raise_Exception_From_Here,
--       "__drake_raise_exception_from_here");
--
--    procedure Raise_Exception_From_Here_With (
--       E : Exception_Id;
--       File : String := Debug.File;
--       Line : Integer := Debug.Line;
--       Message : String);
--    pragma No_Return (Raise_Exception_From_Here_With);
--    pragma Import (Ada, Raise_Exception_From_Here_With,
--       "__drake_raise_exception_from_here_with");
--
--  end Implementation;

   procedure Implementation_Raise_Exception_From_Here (
      E : Exception_Id;
      File : String := Debug.File;
      Line : Integer := Debug.Line);
   pragma No_Return (Implementation_Raise_Exception_From_Here);
   pragma Import (Ada, Implementation_Raise_Exception_From_Here,
      "__drake_raise_exception_from_here");

   procedure Implementation_Raise_Exception_From_Here_With (
      E : Exception_Id;
      File : String := Debug.File;
      Line : Integer := Debug.Line;
      Message : String);
   pragma No_Return (Implementation_Raise_Exception_From_Here_With);
   pragma Import (Ada, Implementation_Raise_Exception_From_Here_With,
      "__drake_raise_exception_from_here_with");

   --  extended
   --  Raise_Exception_From_Here raises a new occurrence of the identified
   --    exception with source location.
   procedure Raise_Exception_From_Here (
      E : Exception_Id;
      File : String := Debug.File;
      Line : Integer := Debug.Line)
      renames Implementation_Raise_Exception_From_Here;
   procedure Raise_Exception_From_Here (
      E : Exception_Id;
      File : String := Debug.File;
      Line : Integer := Debug.Line;
      Message : String)
      renames Implementation_Raise_Exception_From_Here_With;

   function Exception_Identity (X : Exception_Occurrence)
      return Exception_Id;
   function Exception_Name (X : Exception_Occurrence) return String;
   --  Same as Exception_Name (Exception_Identity (X)).
   function Wide_Exception_Name (X : Exception_Occurrence)
      return Wide_String;
   --  Same as Wide_Exception_Name (Exception_Identity (X)).
   function Wide_Wide_Exception_Name (X : Exception_Occurrence)
      return Wide_Wide_String;
   --  Same as Wide_Wide_Exception_Name (Exception_Identity (X)).
   function Exception_Information (X : Exception_Occurrence) return String;

   procedure Save_Occurrence (
      Target : out Exception_Occurrence;
      Source : Exception_Occurrence);
   pragma Import (Ada, Save_Occurrence, "ada__exceptions__save_occurrence");
   function Save_Occurrence (
      Source : Exception_Occurrence)
      return Exception_Occurrence_Access;

--  procedure Read_Exception_Occurrence (
--    Stream : not null access Ada.Streams.Root_Stream_Type'Class;
--    Item : out Exception_Occurrence);
--  procedure Write_Exception_Occurrence (
--    Stream : not null access Ada.Streams.Root_Stream_Type'Class;
--    Item : Exception_Occurrence);

--  for Exception_Occurrence'Read use Read_Exception_Occurrence;
--  for Exception_Occurrence'Write use Write_Exception_Occurrence;

private

   type Exception_Id is new System.Unwind.Exception_Data_Access;

   Null_Id : constant Exception_Id := null;

   type Exception_Occurrence is new System.Unwind.Exception_Occurrence;

   Null_Occurrence : constant Exception_Occurrence := (
      Id => null,
      Msg_Length => 0,
      Msg => (others => ' '),
      Exception_Raised => False,
      Pid => 0,
      Num_Tracebacks => 0,
      Tracebacks => (others => System.Null_Address));

   --  required for reraising by compiler (a-except-2005.ads)
   procedure Reraise_Occurrence_Always (X : Exception_Occurrence);
   pragma No_Return (Reraise_Occurrence_Always);
   pragma Import (Ada, Reraise_Occurrence_Always,
      "ada__exceptions__reraise_occurrence_always");

   --  optionally required by compiler (a-except-2005.ads)
   procedure Raise_From_Controlled_Operation (X : Exception_Occurrence);
   pragma Import (Ada, Raise_From_Controlled_Operation,
      "__gnat_raise_from_controlled_operation");

   --  required for tasking by compiler (a-except-2005.ads)
   function Triggered_By_Abort return Boolean;
   pragma Import (Ada, Triggered_By_Abort,
      "ada__exceptions__triggered_by_abort");

   --  required by compiler ??? (a-except-2005.ads)
--  subtype Code_Loc is System.Address;
--  function Exception_Name_Simple (X : Exception_Occurrence) return String;
--  procedure Raise_Exception_Always (
--    E : Exception_Id;
--    Message : String := "");
--  procedure Reraise_Occurrence_No_Defer (X : Exception_Occurrence);

end Ada.Exceptions;
