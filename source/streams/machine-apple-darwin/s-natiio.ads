pragma License (Unrestricted);
--  implementation unit specialized for POSIX (Darwin, FreeBSD, or Linux)
with Ada.IO_Exceptions;
with Ada.IO_Modes;
with Ada.Exception_Identification;
with Ada.Streams;
with System.Zero_Terminated_Strings;
with C.unistd;
package System.Native_IO is
   pragma Preelaborate;
   use type C.signed_int;

   subtype Name_Length is C.size_t;
   subtype Name_Character is C.char;
   subtype Name_String is C.char_array;
   subtype Name_Pointer is C.char_ptr;

   subtype Handle_Type is C.signed_int;

   Invalid_Handle : constant Handle_Type := -1;

   --  name

   function Value (
      First : not null access constant Name_Character;
      Length : Name_Length)
      return String
      renames Zero_Terminated_Strings.Value;

   procedure Free (Item : in out Name_Pointer);

   procedure New_Full_Name (
      Item : String;
      Out_Item : aliased out Name_Pointer; -- Full_Name (Name) & NUL
      Out_Length : out Name_Length);

   procedure New_External_Name (
      Item : String;
      Out_Item : aliased out Name_Pointer; -- '*' & Name & NUL
      Out_Length : out Name_Length);

   --  file management

   procedure Open_Temporary (
      Handle : aliased out Handle_Type;
      Out_Item : aliased out Name_Pointer;
      Out_Length : out Name_Length);

   type Open_Method is (Open, Create, Reset);
   pragma Discard_Names (Open_Method);

   type Packed_Form is record
      Shared : Ada.IO_Modes.File_Shared_Spec;
      Wait : Boolean;
      Overwrite : Boolean;
   end record;
   pragma Suppress_Initialization (Packed_Form);
   pragma Pack (Packed_Form);
   pragma Compile_Time_Error (Packed_Form'Size /= 4, "not packed");

   procedure Open_Ordinary (
      Method : Open_Method;
      Handle : aliased out Handle_Type;
      Mode : Ada.IO_Modes.File_Mode;
      Name : not null Name_Pointer;
      Form : Packed_Form);

   procedure Close_Temporary (
      Handle : Handle_Type;
      Name : not null Name_Pointer;
      Raise_On_Error : Boolean);

   procedure Close_Ordinary (
      Handle : Handle_Type;
      Raise_On_Error : Boolean);

   procedure Delete_Ordinary (
      Handle : Handle_Type;
      Name : not null Name_Pointer;
      Raise_On_Error : Boolean)
      renames Close_Temporary;

   procedure Set_Close_On_Exec (Handle : Handle_Type);

   function Is_Terminal (Handle : Handle_Type) return Boolean;
   function Is_Seekable (Handle : Handle_Type) return Boolean;

   function Block_Size (Handle : Handle_Type)
      return Ada.Streams.Stream_Element_Count;

   --  read from file

   procedure Read (
      Handle : Handle_Type;
      Item : Address;
      Length : Ada.Streams.Stream_Element_Offset;
      Out_Length : out Ada.Streams.Stream_Element_Offset); -- -1 when error

   --  write into file

   procedure Write (
      Handle : Handle_Type;
      Item : Address;
      Length : Ada.Streams.Stream_Element_Offset;
      Out_Length : out Ada.Streams.Stream_Element_Offset); -- -1 when error

   procedure Flush (Handle : Handle_Type);

   --  position within file

   From_Begin : constant := C.unistd.SEEK_SET;
   From_Current : constant := C.unistd.SEEK_CUR;
   From_End : constant := C.unistd.SEEK_END;

   procedure Set_Relative_Index (
      Handle : Handle_Type;
      Relative_To : Ada.Streams.Stream_Element_Offset; -- 0-origin
      Whence : C.signed_int;
      New_Index : out Ada.Streams.Stream_Element_Offset); -- 1-origin

   function Index (Handle : Handle_Type)
      return Ada.Streams.Stream_Element_Offset; -- 1-origin

   function Size (Handle : Handle_Type)
      return Ada.Streams.Stream_Element_Count;

   --  default input and output files

   Standard_Input : constant Handle_Type := 0;
   Standard_Output : constant Handle_Type := 1;
   Standard_Error : constant Handle_Type := 2;

   Uninitialized_Standard_Input : Handle_Type
      renames Standard_Input;
   Uninitialized_Standard_Output : Handle_Type
      renames Standard_Output;
   Uninitialized_Standard_Error : Handle_Type
      renames Standard_Error;

   procedure Initialize (
      Standard_Input_Handle : aliased in out Handle_Type;
      Standard_Output_Handle : aliased in out Handle_Type;
      Standard_Error_Handle : aliased in out Handle_Type) is null;

   --  exceptions

   function IO_Exception_Id (errno : C.signed_int)
      return Ada.Exception_Identification.Exception_Id;

   Name_Error : exception
      renames Ada.IO_Exceptions.Name_Error;
   Use_Error : exception
      renames Ada.IO_Exceptions.Use_Error;
   Device_Error : exception
      renames Ada.IO_Exceptions.Device_Error;

end System.Native_IO;
