pragma License (Unrestricted);
with Ada.IO_Exceptions;
with Ada.Calendar;
with Ada.Iterator_Interfaces;
with Ada.Streams;
private with Ada.Directory_Searching;
private with Ada.Finalization;
package Ada.Directories is

   --  Directory and file operations:

   function Current_Directory return String;

   procedure Set_Directory (Directory : String);

   procedure Create_Directory (
      New_Directory : String;
      Form : String := "");

   procedure Delete_Directory (Directory : String);

   procedure Create_Path (
      New_Directory : String;
      Form : String := "");

   procedure Delete_Tree (Directory : String);

   procedure Delete_File (Name : String);

   --  modified
   --  These functions fail if Overwrite = False and New_Name already exists.
   procedure Rename (
      Old_Name : String;
      New_Name : String;
      Overwrite : Boolean := True); -- additional

   --  modified
   procedure Copy_File (
      Source_Name : String;
      Target_Name : String;
      Form : String := "";
      Overwrite : Boolean := True); -- additional

   --  extended
   --  Create a symbolic link.
   procedure Symbolic_Link (
      Source_Name : String;
      Target_Name : String;
      Overwrite : Boolean := True);

   --  File and directory name operations:

   function Full_Name (Name : String) return String;

   function Simple_Name (Name : String) return String;

   function Containing_Directory (Name : String) return String;

   function Extension (Name : String) return String;

   function Base_Name (Name : String) return String;

   function Compose (
      Containing_Directory : String := "";
      Name : String;
      Extension : String := "")
      return String;

--  type Name_Case_Kind is
--    (Unknown, Case_Sensitive, Case_Insensitive, Case_Preserving);

--  function Name_Case_Equivalence (Name : in String) return Name_Case_Kind;

   --  extended
   --  There are procedure version.
   procedure Simple_Name (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Containing_Directory (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Extension (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Base_Name (
      Name : String;
      First : out Positive;
      Last : out Natural);

   --  File and directory queries:

   type File_Kind is (Directory, Ordinary_File, Special_File);

   --  modified
   --  File_Size is essentially same as Stream_Element_Count.
--  type File_Size is range 0 .. implementation-defined;
   subtype File_Size is Streams.Stream_Element_Count;

   function Exists (Name : String) return Boolean;

   function Kind (Name : String) return File_Kind;

   function Size (Name : String) return File_Size;

   function Modification_Time (Name : String) return Calendar.Time;

   --  extended
   --  Set modification time of a file.
   procedure Set_Modification_Time (Name : String; Time : Calendar.Time);

   --  Directory searching:

   type Directory_Entry_Type is limited private;

   type Filter_Type is array (File_Kind) of Boolean;
   pragma Pack (Filter_Type);

   --  modified
--  type Search_Type is limited private;
   type Search_Type is tagged limited private
      with
         Constant_Indexing => Constant_Reference,
         Default_Iterator => Iterate,
         Iterator_Element => Directory_Entry_Type;

   --  modified
   procedure Start_Search (
      Search : in out Search_Type;
      Directory : String;
      Pattern : String := "*"; -- additional default
      Filter : Filter_Type := (others => True));

   --  extended
   function Start_Search (
      Directory : String;
      Pattern : String := "*";
      Filter : Filter_Type := (others => True))
      return Search_Type;

   procedure End_Search (Search : in out Search_Type);

   function More_Entries (Search : Search_Type) return Boolean;

   procedure Get_Next_Entry (
      Search : in out Search_Type;
      Directory_Entry : out Directory_Entry_Type);

   --  modified
   procedure Search (
      Directory : String;
      Pattern : String := "*"; -- additional default
      Filter : Filter_Type := (others => True);
      Process : not null access procedure (
         Directory_Entry : Directory_Entry_Type));

   --  extended
   --  There is an iterator for AI12-0009-1 (?)
   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);
   function Has_Element (Position : Cursor) return Boolean;
   type Constant_Reference_Type (
      Element : not null access constant Directory_Entry_Type) is null record
      with Implicit_Dereference => Element;
   function Constant_Reference (
      Container : aliased Search_Type;
      Position : Cursor)
      return Constant_Reference_Type;
   package Search_Iterator_Interfaces is
      new Iterator_Interfaces (Cursor, Has_Element);
   function Iterate (Container : Search_Type)
      return Search_Iterator_Interfaces.Forward_Iterator'Class;

   --  Operations on Directory Entries:

   function Simple_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Full_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Kind (Directory_Entry : Directory_Entry_Type)
      return File_Kind;

   function Size (Directory_Entry : Directory_Entry_Type)
      return File_Size;

   function Modification_Time (Directory_Entry : Directory_Entry_Type)
      return Calendar.Time;

   Status_Error : exception
      renames IO_Exceptions.Status_Error;
   Name_Error : exception
      renames IO_Exceptions.Name_Error;
   Use_Error : exception
      renames IO_Exceptions.Use_Error;
   Device_Error : exception
      renames IO_Exceptions.Device_Error;

private

   type String_Access is access String;

   type Search_Access is access Search_Type;
   for Search_Access'Storage_Size use 0;

   type Directory_Entry_Type is record -- not limited in full view
      Search : Search_Access := null;
      Data : aliased Directory_Searching.Directory_Entry_Type;
      Additional : aliased Directory_Searching.Directory_Entry_Additional_Type;
   end record;

   type Search_Type is new Finalization.Limited_Controlled with record
      Search : Directory_Searching.Search_Type := (
         Handle => Directory_Searching.Null_Handle,
         others => <>);
      Path : String_Access;
      Next_Data : aliased Directory_Searching.Directory_Entry_Type;
      Has_Next : Boolean;
      Count : Natural;
   end record;

   overriding procedure Finalize (Search : in out Search_Type);
   procedure End_Search (Search : in out Search_Type) renames Finalize;

   type Cursor is record
      Directory_Entry : aliased Directory_Entry_Type;
      Index : Positive;
   end record;

   type Search_Iterator is new Search_Iterator_Interfaces.Forward_Iterator
      with
   record
      Search : Search_Access;
   end record;

   overriding function First (Object : Search_Iterator) return Cursor;
   overriding function Next (Object : Search_Iterator; Position : Cursor)
      return Cursor;

   --  for Temporary
   procedure Include_Trailing_Path_Delimiter (
      S : in out String;
      Last : in out Natural);

   --  for Hierarchical_File_Names
   procedure Exclude_Trailing_Path_Delimiter (
      S : String;
      Last : in out Natural);

end Ada.Directories;
