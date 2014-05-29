pragma License (Unrestricted);
--  implementation unit for Ada.Directories
with Ada.IO_Exceptions;
with Ada.Streams;
with System.Native_Time;
with C.winbase;
with C.windef;
with C.winnt;
private package Ada.Directory_Searching is

   subtype Directory_Entry_Type is C.winbase.WIN32_FIND_DATA;

   type Directory_Entry_Additional_Type is record
      Filled : Boolean;
   end record;
   pragma Suppress_Initialization (Directory_Entry_Additional_Type);

   --  same as Directories.File_Kind
   type File_Kind is (Directory, Ordinary_File, Special_File);
   pragma Discard_Names (File_Kind);
   --  same as Directories.Filter_Type
   type Filter_Type is array (File_Kind) of Boolean;
   pragma Pack (Filter_Type);
   pragma Suppress_Initialization (Filter_Type);

   subtype Handle_Type is C.winnt.HANDLE;

   Null_Handle : constant Handle_Type := Handle_Type (System.Null_Address);

   type Search_Type is record
      Handle : C.winnt.HANDLE;
      Filter : Filter_Type;
   end record;
   pragma Suppress_Initialization (Search_Type);

   procedure Start_Search (
      Search : in out Search_Type;
      Directory : String;
      Pattern : String;
      Filter : Filter_Type;
      Directory_Entry : aliased out Directory_Entry_Type;
      Has_Next_Entry : out Boolean);

   procedure End_Search (Search : in out Search_Type);

   procedure Get_Next_Entry (
      Search : in out Search_Type;
      Directory_Entry : aliased out Directory_Entry_Type;
      Has_Next_Entry : out Boolean);

   function Simple_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Kind (Directory_Entry : Directory_Entry_Type)
      return File_Kind;

   function Size (
      Directory : String;
      Directory_Entry : Directory_Entry_Type;
      Additional : aliased in out Directory_Entry_Additional_Type)
      return Streams.Stream_Element_Count;

   function Modification_Time (
      Directory : String;
      Directory_Entry : Directory_Entry_Type;
      Additional : aliased in out Directory_Entry_Additional_Type)
      return System.Native_Time.Native_Time;

   Name_Error : exception
      renames IO_Exceptions.Name_Error;
   Use_Error : exception
      renames IO_Exceptions.Use_Error;

   --  for Ada.Directories

   function To_File_Kind (Attributes : C.windef.DWORD) return File_Kind;

end Ada.Directory_Searching;
