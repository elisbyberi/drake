with Ada.Exceptions;
with System.Address_To_Named_Access_Conversions;
with System.IO_Options;
with System.Memory;
with System.Storage_Elements;
with C.errno;
with C.fcntl;
with C.stdlib;
with C.string;
with C.sys.stat;
with C.sys.types;
with C.unistd;
package body Ada.Streams.Stream_IO.Inside is
   use type Tags.Tag;
   use type System.Address;
   use type System.Storage_Elements.Storage_Offset;
   use type C.char;
   use type C.char_array;
   use type C.char_ptr;
   use type C.signed_int; -- ssize_t is signed int or signed long
   use type C.signed_long;
   use type C.size_t;
   use type C.unsigned_short;
   use type C.unsigned_int;
   use type C.sys.types.off_t; -- 64bit off_t

   pragma Compile_Time_Error (C.sys.types.off_t'Size /= 64,
      "off_t is not 64bit");

   --  handle

   function lseek (
      Handle : Handle_Type;
      offset : C.sys.types.off_t;
      whence : C.signed_int)
      return C.sys.types.off_t;
   function lseek (
      Handle : Handle_Type;
      offset : C.sys.types.off_t;
      whence : C.signed_int)
      return C.sys.types.off_t
   is
      Result : constant C.sys.types.off_t :=
         C.unistd.lseek (Handle, offset, whence);
   begin
      if Result < 0 then
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
      return Result;
   end lseek;

   procedure fstat (
      Handle : Handle_Type;
      buf : not null access C.sys.stat.struct_stat);
   procedure fstat (
      Handle : Handle_Type;
      buf : not null access C.sys.stat.struct_stat) is
   begin
      if C.sys.stat.fstat (Handle, buf) < 0 then
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
   end fstat;

   procedure Set_Close_On_Exec (Handle : Handle_Type; Error : out Boolean);
   procedure Set_Close_On_Exec (Handle : Handle_Type; Error : out Boolean) is
   begin
      Error := C.fcntl.fcntl (
         Handle,
         C.fcntl.F_SETFD,
         C.fcntl.FD_CLOEXEC) = -1;
   end Set_Close_On_Exec;

   --  implementation of handle

   function Is_Terminal (Handle : Handle_Type) return Boolean is
   begin
      return C.unistd.isatty (Handle) /= 0;
   end Is_Terminal;

   function Is_Seekable (Handle : Handle_Type) return Boolean is
   begin
      return C.unistd.lseek (
         Handle,
         0,
         C.unistd.SEEK_CUR) >= 0;
   end Is_Seekable;

   procedure Set_Close_On_Exec (Handle : Handle_Type) is
      Error : Boolean;
   begin
      Set_Close_On_Exec (Handle, Error);
      if Error then
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
   end Set_Close_On_Exec;

   --  implementation of handle for controlled

   procedure Open (
      File : in out File_Type;
      Handle : Handle_Type;
      Mode : File_Mode;
      Name : String := "";
      Form : String := "";
      To_Close : Boolean := False) is
   begin
      Open (
         Reference (File).all,
         Handle,
         Mode,
         Name => Name,
         Form => Form,
         To_Close => To_Close);
   end Open;

   function Handle (File : File_Type) return Handle_Type is
   begin
      return Handle (Reference (File).all);
   end Handle;

   function Non_Controlled (File : File_Type)
      return not null access Non_Controlled_File_Type is
   begin
      return Reference (File);
   end Non_Controlled;

   --  non-controlled

   package char_ptr_Conv is new System.Address_To_Named_Access_Conversions (
      C.char,
      C.char_ptr);

   package Non_Controlled_File_Type_Conv is
      new System.Address_To_Named_Access_Conversions (
         Stream_Type,
         Non_Controlled_File_Type);

   function Allocate (
      Handle : Handle_Type;
      Mode : File_Mode;
      Kind : Stream_Kind;
      Name : System.Address; -- be freeing on error
      Name_Length : Natural;
      Form : String)
      return Non_Controlled_File_Type;
   function Allocate (
      Handle : Handle_Type;
      Mode : File_Mode;
      Kind : Stream_Kind;
      Name : System.Address;
      Name_Length : Natural;
      Form : String)
      return Non_Controlled_File_Type
   is
      Result_Addr : constant System.Address :=
         System.Address (C.stdlib.malloc (
            Stream_Type'Size / Standard'Storage_Unit + Form'Length));
   begin
      if Result_Addr = System.Null_Address then
         System.Memory.Free (Name);
         raise Storage_Error;
      else
         declare
            Result : constant Non_Controlled_File_Type :=
               Non_Controlled_File_Type_Conv.To_Pointer (Result_Addr);
            --  Form is into same memory block
            Result_Form : String (1 .. Form'Length);
            for Result_Form'Address use
               Result_Addr + Stream_Type'Size / Standard'Storage_Unit;
         begin
            Result.Handle := Handle;
            Result.Mode := Mode;
            Result.Kind := Kind;
            Result.Name := Name;
            Result.Name_Length := Name_Length;
            Result.Form := Result_Form'Address;
            Result.Form_Length := Form'Length;
            Result.Buffer := System.Null_Address;
            Result.Buffer_Length := Uninitialized_Buffer;
            Result.Buffer_Index := 0;
            Result.Reading_Index := 0;
            Result.Writing_Index := 0;
            Result.Dispatcher.Tag := Ada.Tags.No_Tag;
            Result.Dispatcher.File := null;
            Result_Form := Form;
            return Result;
         end;
      end if;
   end Allocate;

   procedure Free (File : Non_Controlled_File_Type);
   procedure Free (File : Non_Controlled_File_Type) is
   begin
      if File.Buffer /= File.Buffer_Inline'Address then
         System.Memory.Free (File.Buffer);
      end if;
      System.Memory.Free (File.Name);
      System.Memory.Free (Non_Controlled_File_Type_Conv.To_Address (File));
   end Free;

   procedure Set_Buffer_Index (
      File : not null Non_Controlled_File_Type;
      Buffer_Index : Stream_Element_Offset);
   procedure Set_Buffer_Index (
      File : not null Non_Controlled_File_Type;
      Buffer_Index : Stream_Element_Offset) is
   begin
      if File.Buffer_Length < Uninitialized_Buffer then
         File.Buffer_Index := Buffer_Index;
      elsif File.Buffer_Length = 0 then
         File.Buffer_Index := 0;
      else
         File.Buffer_Index := Buffer_Index rem File.Buffer_Length;
      end if;
      File.Reading_Index := File.Buffer_Index;
      File.Writing_Index := File.Buffer_Index;
   end Set_Buffer_Index;

   procedure Set_Index_To_Append (File : not null Non_Controlled_File_Type);
   procedure Set_Index_To_Append (File : not null Non_Controlled_File_Type) is
      Z_Index : constant Stream_Element_Offset := Stream_Element_Offset (
         lseek (File.Handle, 0, C.unistd.SEEK_END));
   begin
      Set_Buffer_Index (File, Z_Index);
   end Set_Index_To_Append;

   Temp_Variable : constant C.char_array := "TMPDIR" & C.char'Val (0);
   Temp_Template : constant C.char_array := "ADAXXXXXX" & C.char'Val (0);

   procedure Open_Temporary_File (
      Handle : out Handle_Type;
      Full_Name : out C.char_ptr;
      Full_Name_Length : out C.size_t);
   procedure Open_Temporary_File (
      Handle : out Handle_Type;
      Full_Name : out C.char_ptr;
      Full_Name_Length : out C.size_t)
   is
      Temp_Template_Length : constant C.size_t := Temp_Template'Length - 1;
      Temp_Dir : C.char_ptr;
      Error : Boolean;
   begin
      --  compose template
      Temp_Dir := C.stdlib.getenv (Temp_Variable (0)'Access);
      if Temp_Dir /= null then
         --  environment variable TMPDIR
         Full_Name_Length := C.string.strlen (Temp_Dir);
         Full_Name := char_ptr_Conv.To_Pointer (System.Memory.Allocate (
            System.Storage_Elements.Storage_Count (
               Full_Name_Length + Temp_Template_Length + 2))); -- '/' & NUL
         declare
            subtype Fixed_char_array is C.char_array (C.size_t);
            Temp_Dir_A : Fixed_char_array;
            for Temp_Dir_A'Address use Temp_Dir.all'Address;
            Full_Name_A : Fixed_char_array;
            for Full_Name_A'Address use Full_Name.all'Address;
         begin
            Full_Name_A (0 .. Full_Name_Length - 1) :=
               Temp_Dir_A (0 .. Full_Name_Length - 1);
         end;
      else
         --  current directory
         Full_Name := C.unistd.getcwd (null, 0);
         Full_Name_Length := C.string.strlen (Full_Name);
         --  reuse the memory from malloc (similar to reallocf)
         declare
            New_Full_Name : constant C.char_ptr :=
               char_ptr_Conv.To_Pointer (System.Address (C.stdlib.realloc (
                  C.void_ptr (char_ptr_Conv.To_Address (Full_Name)),
                  Full_Name_Length + Temp_Template_Length + 2))); -- '/' & NUL
         begin
            if New_Full_Name = null then
               C.stdlib.free (
                  C.void_ptr (char_ptr_Conv.To_Address (Full_Name)));
               raise Storage_Error;
            end if;
            Full_Name := New_Full_Name;
         end;
      end if;
      declare
         subtype Fixed_char_array is C.char_array (C.size_t);
         Full_Name_A : Fixed_char_array;
         for Full_Name_A'Address use Full_Name.all'Address;
      begin
         --  append slash
         if Full_Name_A (Full_Name_Length - 1) /= '/' then
            Full_Name_A (Full_Name_Length) := '/';
            Full_Name_Length := Full_Name_Length + 1;
         end if;
         --  append template
         Full_Name_A (
            Full_Name_Length ..
            Full_Name_Length + Temp_Template_Length) := Temp_Template; -- NUL
         Full_Name_Length := Full_Name_Length + Temp_Template_Length;
      end;
      --  open
      declare
         use C.stdlib; -- Linux, POSIX.1-2008
         use C.unistd; -- Darwin, FreeBSD
      begin
         Handle := mkstemp (Full_Name);
      end;
      if Handle < 0 then
         System.Memory.Free (char_ptr_Conv.To_Address (Full_Name));
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
      Set_Close_On_Exec (Handle, Error);
      if Error then
         System.Memory.Free (char_ptr_Conv.To_Address (Full_Name));
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
   end Open_Temporary_File;

   procedure Compose_File_Name (
      Name : String;
      Full_Name : out C.char_ptr;
      Full_Name_Length : out C.size_t);
   procedure Compose_File_Name (
      Name : String;
      Full_Name : out C.char_ptr;
      Full_Name_Length : out C.size_t)
   is
      Name_Length : constant C.size_t := Name'Length;
   begin
      if Name (Name'First) = '/' then
         --  absolute path
         Full_Name := char_ptr_Conv.To_Pointer (
            System.Memory.Allocate (
               System.Storage_Elements.Storage_Count (
                  Name_Length + 1))); -- NUL
         Full_Name_Length := 0;
      else
         --  current directory
         Full_Name := C.unistd.getcwd (null, 0);
         Full_Name_Length := C.string.strlen (Full_Name);
         --  reuse the memory from malloc (similar to reallocf)
         declare
            New_Full_Name : constant C.char_ptr :=
               char_ptr_Conv.To_Pointer (System.Address (C.stdlib.realloc (
                  C.void_ptr (char_ptr_Conv.To_Address (Full_Name)),
                  Full_Name_Length + Name_Length + 2))); -- '/' & NUL
         begin
            if New_Full_Name = null then
               C.stdlib.free (
                  C.void_ptr (char_ptr_Conv.To_Address (Full_Name)));
               raise Storage_Error;
            end if;
            Full_Name := New_Full_Name;
         end;
         --  append slash
         declare
            subtype Fixed_char_array is C.char_array (C.size_t);
            Full_Name_A : Fixed_char_array;
            for Full_Name_A'Address use Full_Name.all'Address;
         begin
            if Full_Name_A (Full_Name_Length - 1) /= '/' then
               Full_Name_A (Full_Name_Length) := '/';
               Full_Name_Length := Full_Name_Length + 1;
            end if;
         end;
      end if;
      --  append name
      declare
         subtype Fixed_char_array is C.char_array (C.size_t);
         Full_Name_A : Fixed_char_array;
         for Full_Name_A'Address use Full_Name.all'Address;
         C_Name : C.char_array (0 .. Name_Length - 1);
         for C_Name'Address use Name'Address;
      begin
         Full_Name_A (
            Full_Name_Length ..
            Full_Name_Length + Name_Length - 1) := C_Name;
         Full_Name_Length := Full_Name_Length + Name_Length;
         Full_Name_A (Full_Name_Length) := C.char'Val (0);
      end;
   end Compose_File_Name;

   function Form_Share_Mode (Form : String; Default : C.unsigned_int)
      return C.unsigned_int;
   function Form_Share_Mode (Form : String; Default : C.unsigned_int)
      return C.unsigned_int
   is
      First : Positive;
      Last : Natural;
   begin
      System.IO_Options.Form_Parameter (Form, "shared", First, Last);
      if First <= Last and then Form (First) = 'r' then -- read
         return C.fcntl.O_SHLOCK;
      elsif First <= Last and then Form (First) = 'w' then -- write
         return C.fcntl.O_EXLOCK;
      elsif First <= Last and then Form (First) = 'y' then -- yes
         return 0;
      else -- no
         return Default;
      end if;
   end Form_Share_Mode;

   type Open_Method is (Open, Create, Reset);
   pragma Discard_Names (Open_Method);

   procedure Open_Normal (
      Method : Open_Method;
      File : not null Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : not null C.char_ptr;
      Form : String);
   procedure Open_Normal (
      Method : Open_Method;
      File : not null Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : not null C.char_ptr;
      Form : String)
   is
      Handle : Handle_Type;
      Flags : C.unsigned_int;
      Default_Lock_Flags : C.unsigned_int;
      Modes : constant := 8#644#;
      errno : C.signed_int;
   begin
      --  Flags, Append_File always has read and write access for Inout_File
      if Mode = In_File then
         Default_Lock_Flags := C.fcntl.O_SHLOCK;
      else
         Default_Lock_Flags := C.fcntl.O_EXLOCK;
      end if;
      case Method is
         when Create =>
            declare
               use C.fcntl;
               Table : constant array (File_Mode) of C.unsigned_int := (
                  In_File => O_RDWR or O_CREAT or O_TRUNC,
                  Out_File => O_WRONLY or O_CREAT or O_TRUNC,
                  Append_File => O_RDWR or O_CREAT); -- no truncation
            begin
               Flags := Table (Mode);
               Default_Lock_Flags := C.fcntl.O_EXLOCK;
            end;
         when Open =>
            declare
               use C.fcntl;
               Table : constant array (File_Mode) of C.unsigned_int := (
                  In_File => O_RDONLY,
                  Out_File => O_WRONLY or O_TRUNC,
                  Append_File => O_RDWR); -- O_APPEND ignores lseek
            begin
               Flags := Table (Mode);
            end;
         when Reset =>
            declare
               use C.fcntl;
               Table : constant array (File_Mode) of C.unsigned_int := (
                  In_File => O_RDONLY,
                  Out_File => O_WRONLY,
                  Append_File => O_RDWR); -- O_APPEND ignores lseek
            begin
               Flags := Table (Mode);
            end;
      end case;
      Flags := Flags
         or Form_Share_Mode (Form, Default_Lock_Flags)
         or C.fcntl.O_CLOEXEC;
      --  open
      Handle := C.fcntl.open (Name, C.signed_int (Flags), Modes);
      if Handle < 0 then
         errno := C.errno.errno;
         Free (File); -- free on error
         case errno is
            when C.errno.ENOTDIR
               | C.errno.ENAMETOOLONG
               | C.errno.ENOENT
               | C.errno.EACCES
               | C.errno.EISDIR
               | C.errno.EROFS =>
               Exceptions.Raise_Exception_From_Here (Name_Error'Identity);
            when others =>
               Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
         end case;
      end if;
      declare
         O_CLOEXEC_Is_Missing : constant Boolean :=
            C.fcntl.O_CLOEXEC = 0;
         pragma Warnings (Off, O_CLOEXEC_Is_Missing);
         Error : Boolean;
      begin
         if O_CLOEXEC_Is_Missing then
            --  set FD_CLOEXEC if O_CLOEXEC is missing
            Set_Close_On_Exec (Handle, Error);
            if Error then
               Free (File); -- free on error
               Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
            end if;
         end if;
      end;
      --  set file
      File.Handle := Handle;
      File.Mode := Mode;
   end Open_Normal;

   procedure Allocate_And_Open (
      Method : Open_Method;
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : String;
      Form : String);
   procedure Allocate_And_Open (
      Method : Open_Method;
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : String;
      Form : String)
   is
      Handle : Handle_Type;
      Full_Name : C.char_ptr;
      Full_Name_Length : C.size_t;
   begin
      if Name /= "" then
         Compose_File_Name (Name, Full_Name, Full_Name_Length);
         declare
            New_File : aliased Non_Controlled_File_Type;
         begin
            New_File := Allocate (
               Handle => -1,
               Mode => Mode,
               Kind => Normal,
               Name => char_ptr_Conv.To_Address (Full_Name),
               Name_Length => Natural (Full_Name_Length),
               Form => Form);
            Open_Normal (Method, New_File, Mode, Full_Name, Form);
            File := New_File;
         end;
         if Mode = Append_File then
            Set_Index_To_Append (File); -- sets index to the last
         end if;
      else
         Open_Temporary_File (Handle, Full_Name, Full_Name_Length);
         File := Allocate (
            Handle => Handle,
            Mode => Mode,
            Kind => Temporary,
            Name => char_ptr_Conv.To_Address (Full_Name),
            Name_Length => Natural (Full_Name_Length),
            Form => Form);
      end if;
   end Allocate_And_Open;

   procedure Check_File_Open (File : Non_Controlled_File_Type);
   procedure Check_File_Open (File : Non_Controlled_File_Type) is
   begin
      if File = null then
         Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end if;
   end Check_File_Open;

   procedure Get_Buffer (File : not null Non_Controlled_File_Type);
   procedure Get_Buffer (File : not null Non_Controlled_File_Type) is
   begin
      if File.Buffer_Length = Uninitialized_Buffer then
         if Is_Terminal (File.Handle) then
            File.Buffer_Length := 0; -- no buffering for terminal
         else
            declare
               Info : aliased C.sys.stat.struct_stat;
               File_Type : C.sys.types.mode_t;
            begin
               fstat (File.Handle, Info'Access);
               File_Type := Info.st_mode and C.sys.stat.S_IFMT;
               if File_Type = C.sys.stat.S_IFIFO
                  or else File_Type = C.sys.stat.S_IFSOCK
               then
                  File.Buffer_Length := 0; -- no buffering for pipe and socket
               else
                  File.Buffer_Length := Stream_Element_Offset'Max (
                     2, -- Buffer_Length /= 1
                     Stream_Element_Offset (Info.st_blksize));
               end if;
            end;
         end if;
         if File.Buffer_Length = 0 then
            File.Buffer := File.Buffer_Inline'Address;
            File.Buffer_Index := 0;
         else
            File.Buffer := System.Memory.Allocate (
               System.Storage_Elements.Storage_Count (File.Buffer_Length));
            File.Buffer_Index := File.Buffer_Index rem File.Buffer_Length;
         end if;
         File.Reading_Index := File.Buffer_Index;
         File.Writing_Index := File.Buffer_Index;
      end if;
   end Get_Buffer;

   procedure Ready_Reading_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean);
   procedure Ready_Reading_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean)
   is
      Buffer_Length : constant Stream_Element_Count :=
         Stream_Element_Offset'Max (1, File.Buffer_Length);
   begin
      --  reading buffer is from File.Reading_Index until File.Buffer_Index
      File.Buffer_Index := File.Buffer_Index rem Buffer_Length;
      File.Reading_Index := File.Buffer_Index;
      declare
         Read_Size : C.sys.types.ssize_t;
      begin
         Read_Size := C.unistd.read (
            File.Handle,
            C.void_ptr (File.Buffer
               + System.Storage_Elements.Storage_Offset (
                  File.Buffer_Index)),
            C.size_t (Buffer_Length - File.Buffer_Index));
         Error := Read_Size < 0;
         if not Error then
            File.Buffer_Index :=
               File.Buffer_Index + Stream_Element_Offset (Read_Size);
         end if;
      end;
      File.Writing_Index := File.Buffer_Index;
   end Ready_Reading_Buffer;

   procedure Reset_Reading_Buffer (File : not null Non_Controlled_File_Type);
   procedure Reset_Reading_Buffer (File : not null Non_Controlled_File_Type) is
      Dummy : C.sys.types.off_t;
      pragma Unreferenced (Dummy);
   begin
      Dummy := lseek (
         File.Handle,
         C.sys.types.off_t (File.Reading_Index - File.Buffer_Index),
         C.unistd.SEEK_CUR);
      File.Buffer_Index := File.Reading_Index;
      File.Writing_Index := File.Buffer_Index;
   end Reset_Reading_Buffer;

   procedure Ready_Writing_Buffer (File : not null Non_Controlled_File_Type);
   procedure Ready_Writing_Buffer (File : not null Non_Controlled_File_Type) is
   begin
      --  writing buffer is from File.Buffer_Index until File.Writing_Index
      File.Buffer_Index := File.Buffer_Index rem File.Buffer_Length;
      File.Writing_Index := File.Buffer_Index;
      File.Reading_Index := File.Buffer_Index;
   end Ready_Writing_Buffer;

   procedure Flush_Writing_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean);
   procedure Flush_Writing_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean) is
   begin
      Error := False;
      if File.Writing_Index > File.Buffer_Index then
         if C.unistd.write (
            File.Handle,
            C.void_const_ptr (File.Buffer
               + System.Storage_Elements.Storage_Offset (File.Buffer_Index)),
            C.size_t (File.Writing_Index - File.Buffer_Index)) < 0
         then
            case C.errno.errno is
               when C.errno.EPIPE =>
                  null;
               when others =>
                  Error := True; -- Device_Error
            end case;
         end if;
         if not Error then
            File.Buffer_Index := File.Writing_Index rem File.Buffer_Length;
            File.Writing_Index := File.Buffer_Index;
            File.Reading_Index := File.Buffer_Index;
         end if;
      end if;
   end Flush_Writing_Buffer;

   procedure Flush_Writing_Buffer (File : not null Non_Controlled_File_Type);
   procedure Flush_Writing_Buffer (File : not null Non_Controlled_File_Type) is
      Error : Boolean;
   begin
      Flush_Writing_Buffer (File, Error);
      if Error then
         Exceptions.Raise_Exception_From_Here (Device_Error'Identity);
      end if;
   end Flush_Writing_Buffer;

   function Offset_Of_Buffer (File : not null Non_Controlled_File_Type)
      return Stream_Element_Offset;
   function Offset_Of_Buffer (File : not null Non_Controlled_File_Type)
      return Stream_Element_Offset is
   begin
      return (File.Writing_Index - File.Buffer_Index)
         - (File.Buffer_Index - File.Reading_Index);
   end Offset_Of_Buffer;

   procedure Close_File (
      File : Non_Controlled_File_Type;
      Raise_On_Error : Boolean);
   procedure Close_File (
      File : Non_Controlled_File_Type;
      Raise_On_Error : Boolean)
   is
      Error : Boolean;
   begin
      if File.Kind /= Temporary then
         Flush_Writing_Buffer (File, Error);
         if Error and then Raise_On_Error then
            Free (File); -- free on error
            Exceptions.Raise_Exception_From_Here (Device_Error'Identity);
         end if;
      end if;
      case File.Kind is
         when Normal | Temporary | External =>
            Error := C.unistd.close (File.Handle) < 0;
            if not Error and then File.Kind = Temporary then
               Error := C.unistd.unlink (
                  char_ptr_Conv.To_Pointer (File.Name)) < 0;
            end if;
            if Error and then Raise_On_Error then
               Free (File); -- free on error
               Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
            end if;
         when External_No_Close | Standard_Handle =>
            null;
      end case;
   end Close_File;

   procedure Read_From_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset);
   procedure Read_From_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset)
   is
      Taking_Length : constant Stream_Element_Offset :=
         Stream_Element_Offset'Min (
            Item'Last - Item'First + 1,
            File.Buffer_Index - File.Reading_Index);
      Buffer : Stream_Element_Array (Stream_Element_Count);
      for Buffer'Address use File.Buffer;
   begin
      Last := Item'First + Taking_Length - 1;
      Item (Item'First .. Last) := Buffer (
         File.Reading_Index ..
         File.Reading_Index + Taking_Length - 1);
      File.Reading_Index := File.Reading_Index + Taking_Length;
   end Read_From_Buffer;

   procedure Write_To_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array;
      First : out Stream_Element_Offset);
   procedure Write_To_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array;
      First : out Stream_Element_Offset)
   is
      Taking_Length : constant Stream_Element_Offset :=
         Stream_Element_Offset'Min (
            Item'Last - Item'First + 1,
            File.Buffer_Length - File.Writing_Index);
      Buffer : Stream_Element_Array (Stream_Element_Count);
      for Buffer'Address use File.Buffer;
      Last : Stream_Element_Count;
   begin
      First := Item'First + Taking_Length;
      Last := First - 1;
      Buffer (
         File.Writing_Index ..
         File.Writing_Index + Taking_Length - 1) := Item (Item'First .. Last);
      File.Writing_Index := File.Writing_Index + Taking_Length;
   end Write_To_Buffer;

   --  implementation of non-controlled

   procedure Create (
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode := Out_File;
      Name : String := "";
      Form : String := "") is
   begin
      if File /= null then
         Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end if;
      Allocate_And_Open (
         Method => Create,
         File => File,
         Mode => Mode,
         Name => Name,
         Form => Form);
   end Create;

   procedure Open (
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : String;
      Form : String := "") is
   begin
      if File /= null then
         Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end if;
      Allocate_And_Open (
         Method => Open,
         File => File,
         Mode => Mode,
         Name => Name,
         Form => Form);
   end Open;

   procedure Close (
      File : in out Non_Controlled_File_Type;
      Raise_On_Error : Boolean := True) is
   begin
      Check_File_Open (File);
      declare
         Freeing_File : constant not null Non_Controlled_File_Type := File;
         Kind : constant Stream_Kind := File.Kind;
      begin
         File := null;
         Close_File (Freeing_File, Raise_On_Error);
         case Kind is
            when Normal | Temporary | External | External_No_Close =>
               Free (Freeing_File);
            when Standard_Handle =>
               null; -- statically allocated
         end case;
      end;
   end Close;

   procedure Delete (File : in out Non_Controlled_File_Type) is
   begin
      Check_File_Open (File);
      case File.Kind is
         when Normal | Temporary =>
            File.Kind := Temporary;
            Close (File, Raise_On_Error => True);
         when External | External_No_Close | Standard_Handle =>
            Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end case;
   end Delete;

   procedure Reset (
      File : not null access Non_Controlled_File_Type;
      Mode : File_Mode) is
   begin
      Check_File_Open (File.all);
      case File.all.Kind is
         when Normal =>
            declare
               File2 : constant Non_Controlled_File_Type := File.all;
               Form : String (1 .. File2.Form_Length);
               for Form'Address use File2.Form;
            begin
               File.all := null;
               Close_File (File2, Raise_On_Error => True);
               File2.Buffer_Index := 0;
               File2.Reading_Index := File2.Buffer_Index;
               File2.Writing_Index := File2.Buffer_Index;
               Open_Normal (
                  Method => Reset,
                  File => File2,
                  Mode => Mode,
                  Name => char_ptr_Conv.To_Pointer (File2.Name),
                  Form => Form);
               File.all := File2;
            end;
         when Temporary =>
            File.all.Mode := Mode;
            Set_Index (File.all, 1);
         when External | External_No_Close | Standard_Handle =>
            Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end case;
      if Mode = Append_File then
         Set_Index_To_Append (File.all);
      end if;
   end Reset;

   function Mode (File : Non_Controlled_File_Type) return File_Mode is
   begin
      Check_File_Open (File);
      return File.Mode;
   end Mode;

   function Name (File : Non_Controlled_File_Type) return String is
   begin
      Check_File_Open (File);
      declare
         A_Name : String (1 .. File.Name_Length);
         for A_Name'Address use File.Name;
      begin
         return A_Name;
      end;
   end Name;

   function Form (File : Non_Controlled_File_Type) return String is
   begin
      Check_File_Open (File);
      declare
         A_Form : String (1 .. File.Form_Length);
         for A_Form'Address use File.Form;
      begin
         return A_Form;
      end;
   end Form;

   function Is_Open (File : Non_Controlled_File_Type) return Boolean is
   begin
      return File /= null;
   end Is_Open;

   function End_Of_File (File : Non_Controlled_File_Type) return Boolean is
      Info : aliased C.sys.stat.struct_stat;
   begin
      Check_File_Open (File);
      fstat (File.Handle, Info'Access);
      if (Info.st_mode and C.sys.stat.S_IFMT) /= C.sys.stat.S_IFREG then
         if File.Reading_Index = File.Buffer_Index then
            Get_Buffer (File);
            declare
               Error : Boolean;
            begin
               Ready_Reading_Buffer (File, Error);
               if Error then
                  Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
               end if;
            end;
         end if;
         return File.Reading_Index = File.Buffer_Index;
      else
         declare
            Z_Index : constant C.sys.types.off_t :=
               lseek (File.Handle, 0, C.unistd.SEEK_CUR)
               + C.sys.types.off_t (Offset_Of_Buffer (File));
         begin
            return Z_Index >= Info.st_size;
            --  whether writing buffer will expand the file size or not
         end;
      end if;
   end End_Of_File;

   function Stream (File : Non_Controlled_File_Type) return Stream_Access is
      package Conv is new System.Address_To_Named_Access_Conversions (
         Root_Stream_Type'Class,
         Stream_Access);
   begin
      Check_File_Open (File);
      if File.Dispatcher.Tag = Tags.No_Tag then
         if not Is_Seekable (File.Handle) then
            File.Dispatcher.Tag := Dispatchers.Root_Dispatcher'Tag;
         else
            File.Dispatcher.Tag := Dispatchers.Seekable_Dispatcher'Tag;
         end if;
         File.Dispatcher.File := File;
      end if;
      return Conv.To_Pointer (File.Dispatcher'Address);
   end Stream;

   procedure Read (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset) is
   begin
      if File.Mode = Out_File then
         Exceptions.Raise_Exception_From_Here (Mode_Error'Identity);
      end if;
      Last := Item'First - 1;
      if Item'First > Item'Last then
         return;
      end if;
      if File.Reading_Index < File.Buffer_Index then
         Read_From_Buffer (File, Item, Last);
      elsif File.Writing_Index > File.Buffer_Index then
         Flush_Writing_Buffer (File);
      end if;
      if Last < Item'Last then
         Get_Buffer (File);
         declare
            Error : Boolean := False;
            Buffer_Length : constant Stream_Element_Count :=
               File.Buffer_Length;
         begin
            declare
               Taking_Length : Stream_Element_Count;
               Read_Size : C.sys.types.ssize_t;
            begin
               Taking_Length := Item'Last - Last;
               if Buffer_Length > 0 then
                  declare
                     Misaligned : constant Stream_Element_Count :=
                        (Buffer_Length - File.Buffer_Index) rem Buffer_Length;
                  begin
                     if Taking_Length < Misaligned then
                        Taking_Length := 0; -- to use reading buffer
                     else
                        Taking_Length := Taking_Length - Misaligned;
                        Taking_Length := Taking_Length
                           - Taking_Length rem Buffer_Length;
                        Taking_Length := Taking_Length + Misaligned;
                     end if;
                  end;
               end if;
               if Taking_Length > 0 then
                  Read_Size := C.unistd.read (
                     File.Handle,
                     C.void_ptr (Item (Last + 1)'Address),
                     C.size_t (Taking_Length));
                  Error := Read_Size < 0;
                  if not Error then
                     Last := Last + Stream_Element_Offset (Read_Size);
                     --  update indexes
                     if Buffer_Length > 0 then
                        File.Buffer_Index :=
                           (File.Buffer_Index
                              + Stream_Element_Offset (Read_Size))
                           rem Buffer_Length;
                     else
                        File.Buffer_Index := 0;
                     end if;
                     File.Reading_Index := File.Buffer_Index;
                     File.Writing_Index := File.Buffer_Index;
                  end if;
               end if;
            end;
            if not Error
               and then Last < Item'Last
               and then File.Buffer_Length > 0
            then
               Ready_Reading_Buffer (File, Error); -- reading buffer is empty
               if not Error
                  and then File.Reading_Index < File.Buffer_Index
               then
                  Read_From_Buffer (File, Item (Last + 1 .. Item'Last), Last);
               end if;
            end if;
            if Last < Item'First and then Error then
               Exceptions.Raise_Exception_From_Here (End_Error'Identity);
            end if;
         end;
      end if;
   end Read;

   procedure Write (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array)
   is
      First : Stream_Element_Offset;
   begin
      if File.Mode = In_File then
         Exceptions.Raise_Exception_From_Here (Mode_Error'Identity);
      end if;
      First := Item'First;
      if File.Writing_Index > File.Buffer_Index then
         --  append to writing buffer
         Write_To_Buffer (File, Item, First);
         if File.Writing_Index = File.Buffer_Length then
            Flush_Writing_Buffer (File);
         end if;
      elsif File.Reading_Index < File.Buffer_Index then
         --  reset reading buffer
         Reset_Reading_Buffer (File);
      end if;
      if First <= Item'Last then
         Get_Buffer (File);
         declare
            Buffer_Length : constant Stream_Element_Count :=
               File.Buffer_Length;
         begin
            declare
               Taking_Length : Stream_Element_Count;
            begin
               Taking_Length := Item'Last - First + 1;
               if Buffer_Length > 0 then
                  declare
                     Misaligned : constant Stream_Element_Count :=
                        (Buffer_Length - File.Buffer_Index) rem Buffer_Length;
                  begin
                     if Taking_Length < Misaligned then
                        Taking_Length := 0; -- to use writing buffer
                     else
                        Taking_Length := Taking_Length - Misaligned;
                        Taking_Length := Taking_Length
                           - Taking_Length rem Buffer_Length;
                        Taking_Length := Taking_Length + Misaligned;
                     end if;
                  end;
               end if;
               if Taking_Length > 0 then
                  if C.unistd.write (
                     File.Handle,
                     C.void_const_ptr (Item (First)'Address),
                     C.size_t (Taking_Length)) < 0
                  then
                     case C.errno.errno is
                        when C.errno.EPIPE =>
                           null;
                        when others =>
                           Exceptions.Raise_Exception_From_Here (
                              Use_Error'Identity);
                     end case;
                  end if;
                  First := First + Taking_Length;
                  --  update indexes
                  if Buffer_Length > 0 then
                     File.Buffer_Index :=
                        (File.Buffer_Index + Taking_Length) rem Buffer_Length;
                     File.Reading_Index := File.Buffer_Index;
                     File.Writing_Index := File.Buffer_Index;
                  end if;
               end if;
            end;
            if First <= Item'Last and then Buffer_Length > 0 then
               Ready_Writing_Buffer (File);
               Write_To_Buffer (File, Item (First .. Item'Last), First);
            end if;
         end;
      end if;
   end Write;

   procedure Set_Index (
      File : not null Non_Controlled_File_Type;
      To : Stream_Element_Positive_Count)
   is
      Dummy : C.sys.types.off_t;
      pragma Unreferenced (Dummy);
      Z_Index : constant Stream_Element_Offset := To - 1; -- zero based
   begin
      Flush_Writing_Buffer (File);
      Dummy := lseek (
         File.Handle,
         C.sys.types.off_t (Z_Index),
         C.unistd.SEEK_SET);
      Set_Buffer_Index (File, Z_Index);
   end Set_Index;

   function Index (File : not null Non_Controlled_File_Type)
      return Stream_Element_Positive_Count
   is
      Result : constant C.sys.types.off_t :=
         lseek (File.Handle, 0, C.unistd.SEEK_CUR);
   begin
      return Stream_Element_Positive_Count (Result + 1)
         + Offset_Of_Buffer (File);
   end Index;

   function Size (File : not null Non_Controlled_File_Type)
      return Stream_Element_Count
   is
      Info : aliased C.sys.stat.struct_stat;
   begin
      Flush_Writing_Buffer (File);
      fstat (File.Handle, Info'Access);
      return Count (Info.st_size);
   end Size;

   procedure Set_Mode (
      File : not null access Non_Controlled_File_Type;
      Mode : File_Mode)
   is
      Current : Positive_Count;
   begin
      Check_File_Open (File.all);
      Current := Index (File.all);
      case File.all.Kind is
         when Normal =>
            declare
               File2 : constant Non_Controlled_File_Type := File.all;
               Form : String (1 .. File2.Form_Length);
               for Form'Address use File2.Form;
            begin
               File.all := null;
               Close_File (File2, Raise_On_Error => True);
               Open_Normal (
                  Method => Reset,
                  File => File2,
                  Mode => Mode,
                  Name => char_ptr_Conv.To_Pointer (File2.Name),
                  Form => Form);
               File.all := File2;
            end;
         when Temporary =>
            Flush_Writing_Buffer (File.all);
            File.all.Mode := Mode;
         when External | External_No_Close | Standard_Handle =>
            Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end case;
      if Mode = Append_File then
         Set_Index_To_Append (File.all);
      else
         Set_Index (File.all, Current);
      end if;
   end Set_Mode;

   procedure Flush (File : Non_Controlled_File_Type) is
   begin
      Check_File_Open (File);
      Flush_Writing_Buffer (File);
      if C.unistd.fsync (File.Handle) < 0 then
         --  EINVAL means fd is not file but FIFO, etc.
         if C.errno.errno /= C.errno.EINVAL then
            Exceptions.Raise_Exception_From_Here (Device_Error'Identity);
         end if;
      end if;
   end Flush;

   --  handle for non-controlled

   procedure Open (
      File : in out Non_Controlled_File_Type;
      Handle : Handle_Type;
      Mode : File_Mode;
      Name : String := "";
      Form : String := "";
      To_Close : Boolean := False)
   is
      Kind : Stream_Kind;
      Full_Name : C.char_ptr;
      Full_Name_Length : C.size_t;
   begin
      if File /= null then
         Exceptions.Raise_Exception_From_Here (Status_Error'Identity);
      end if;
      if To_Close then
         Kind := External;
      else
         Kind := External_No_Close;
      end if;
      Full_Name := char_ptr_Conv.To_Pointer (
         System.Memory.Allocate (Name'Length + 2));
      Full_Name_Length := Name'Length + 1;
      declare
         C_Name : C.char_array (0 .. Name'Length - 1);
         for C_Name'Address use Name'Address;
         Full_Name_A : C.char_array (C.size_t);
         for Full_Name_A'Address use Full_Name.all'Address;
      begin
         Full_Name_A (0) := '*';
         Full_Name_A (1 .. Full_Name_Length - 1) := C_Name;
         Full_Name_A (Full_Name_Length) := C.char'Val (0);
      end;
      File := Allocate (
         Handle => Handle,
         Mode => Mode,
         Kind => Kind,
         Name => char_ptr_Conv.To_Address (Full_Name),
         Name_Length => Natural (Full_Name_Length),
         Form => Form);
   end Open;

   function Handle (File : Non_Controlled_File_Type) return Handle_Type is
   begin
      Check_File_Open (File);
      return File.Handle;
   end Handle;

   function Is_Standard (File : Non_Controlled_File_Type) return Boolean is
   begin
      return File /= null and then File.Kind = Standard_Handle;
   end Is_Standard;

end Ada.Streams.Stream_IO.Inside;
