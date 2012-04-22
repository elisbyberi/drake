with Ada.Exceptions.Finally;
with Ada.Permissions.Inside;
with Ada.Unchecked_Conversion;
with System.Address_To_Named_Access_Conversions;
with System.Memory;
with System.Native_Time;
with System.Storage_Elements;
with C.errno;
with C.sys.stat;
with C.sys.types;
with C.unistd;
package body Ada.Directories.Information is
   use type C.size_t;
   use type C.sys.types.mode_t;
   use type C.sys.types.ssize_t;

   function To_Permission_Set (Mode : C.sys.types.mode_t)
      return Permission_Set_Type;
   function To_Permission_Set (Mode : C.sys.types.mode_t)
      return Permission_Set_Type is
   begin
      return (
         Others_Execute => (Mode and C.sys.stat.S_IXOTH) /= 0,
         Others_Write => (Mode and C.sys.stat.S_IWOTH) /= 0,
         Others_Read => (Mode and C.sys.stat.S_IROTH) /= 0,
         Group_Execute => (Mode and C.sys.stat.S_IXGRP) /= 0,
         Group_Write => (Mode and C.sys.stat.S_IWGRP) /= 0,
         Group_Read => (Mode and C.sys.stat.S_IRGRP) /= 0,
         Owner_Execute => (Mode and C.sys.stat.S_IXUSR) /= 0,
         Owner_Write => (Mode and C.sys.stat.S_IWUSR) /= 0,
         Owner_Read => (Mode and C.sys.stat.S_IRUSR) /= 0,
         Set_Group_ID => (Mode and C.sys.stat.S_ISGID) /= 0,
         Set_User_ID => (Mode and C.sys.stat.S_ISUID) /= 0);
   end To_Permission_Set;

   --  implementation

   function Group (Name : String) return String is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return Permissions.Inside.Group_Name (Attributes.st_gid);
   end Group;

   function Group (Directory_Entry : Directory_Entry_Type) return String is
   begin
      Check_Assigned (Directory_Entry);
      return Permissions.Inside.Group_Name (Directory_Entry.State_Data.st_gid);
   end Group;

   function Is_Block_Special_File (Name : String) return Boolean is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return (Attributes.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFBLK;
   end Is_Block_Special_File;

   function Is_Block_Special_File (Directory_Entry : Directory_Entry_Type)
      return Boolean is
   begin
      Check_Assigned (Directory_Entry);
      return (Directory_Entry.State_Data.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFBLK;
   end Is_Block_Special_File;

   function Is_Character_Special_File (Name : String) return Boolean is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return (Attributes.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFCHR;
   end Is_Character_Special_File;

   function Is_Character_Special_File (Directory_Entry : Directory_Entry_Type)
      return Boolean is
   begin
      Check_Assigned (Directory_Entry);
      return (Directory_Entry.State_Data.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFCHR;
   end Is_Character_Special_File;

   function Is_FIFO (Name : String) return Boolean is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return (Attributes.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFIFO;
   end Is_FIFO;

   function Is_FIFO (Directory_Entry : Directory_Entry_Type)
      return Boolean is
   begin
      Check_Assigned (Directory_Entry);
      return (Directory_Entry.State_Data.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFIFO;
   end Is_FIFO;

   function Is_Socket (Name : String) return Boolean is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return (Attributes.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFSOCK;
   end Is_Socket;

   function Is_Socket (Directory_Entry : Directory_Entry_Type)
      return Boolean is
   begin
      Check_Assigned (Directory_Entry);
      return (Directory_Entry.State_Data.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFSOCK;
   end Is_Socket;

   function Is_Symbolic_Link (Name : String) return Boolean is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return (Attributes.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFLNK;
   end Is_Symbolic_Link;

   function Is_Symbolic_Link (Directory_Entry : Directory_Entry_Type)
      return Boolean is
   begin
      Check_Assigned (Directory_Entry);
      return (Directory_Entry.State_Data.st_mode and C.sys.stat.S_IFMT) =
         C.sys.stat.S_IFLNK;
   end Is_Symbolic_Link;

   function Last_Access_Time (Name : String) return Calendar.Time is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return Cast (System.Native_Time.To_Time (Attributes.st_atimespec));
   end Last_Access_Time;

   function Last_Access_Time (Directory_Entry : Directory_Entry_Type)
      return Calendar.Time
   is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
   begin
      Check_Assigned (Directory_Entry);
      return Cast (
         System.Native_Time.To_Time (Directory_Entry.State_Data.st_atimespec));
   end Last_Access_Time;

   function Last_Status_Change_Time (Name : String)
      return Calendar.Time
   is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return Cast (System.Native_Time.To_Time (Attributes.st_ctimespec));
   end Last_Status_Change_Time;

   function Last_Status_Change_Time (Directory_Entry : Directory_Entry_Type)
      return Calendar.Time
   is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
   begin
      Check_Assigned (Directory_Entry);
      return Cast (
         System.Native_Time.To_Time (Directory_Entry.State_Data.st_ctimespec));
   end Last_Status_Change_Time;

   function Owner (Name : String) return String is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return Permissions.Inside.User_Name (Attributes.st_uid);
   end Owner;

   function Owner (Directory_Entry : Directory_Entry_Type) return String is
   begin
      Check_Assigned (Directory_Entry);
      return Permissions.Inside.User_Name (Directory_Entry.State_Data.st_uid);
   end Owner;

   function Permission_Set (Name : String) return Permission_Set_Type is
      Attributes : C.sys.stat.struct_stat;
   begin
      Get_Attributes (Name, Attributes);
      return To_Permission_Set (Attributes.st_mode);
   end Permission_Set;

   function Permission_Set (Directory_Entry : Directory_Entry_Type)
      return Permission_Set_Type is
   begin
      Check_Assigned (Directory_Entry);
      return To_Permission_Set (Directory_Entry.State_Data.st_mode);
   end Permission_Set;

   function Read_Symbolic_Link (Name : String) return String is
      package Conv is new System.Address_To_Named_Access_Conversions (
         C.char,
         C.char_ptr);
      Buffer_Length : C.size_t := 1024;
      Buffer : aliased C.char_ptr := Conv.To_Pointer (System.Memory.Allocate (
         System.Storage_Elements.Storage_Count (Buffer_Length)));
      procedure Finally (X : not null access C.char_ptr);
      procedure Finally (X : not null access C.char_ptr) is
      begin
         System.Memory.Free (Conv.To_Address (X.all));
      end Finally;
      package Holder is new Exceptions.Finally.Scoped_Holder (
         C.char_ptr,
         Finally);
      Z_Name : constant String := Name & Character'Val (0);
      C_Name : C.char_array (C.size_t);
      for C_Name'Address use Z_Name'Address;
   begin
      Holder.Assign (Buffer'Access);
      loop
         declare
            function To_size (X : C.size_t) return C.size_t renames "+"; -- OSX
            function To_size (X : C.size_t) return C.signed_int; -- FreeBSD
            function To_size (X : C.size_t) return C.signed_int is
            begin
               return C.signed_int (X);
            end To_size;
            pragma Warnings (Off, To_size);
            Result : constant C.sys.types.ssize_t := C.unistd.readlink (
               C_Name (0)'Access,
               Buffer,
               To_size (Buffer_Length));
         begin
            if Result < 0 then
               case C.errno.errno is
                  when C.errno.ENAMETOOLONG
                     | C.errno.ENOENT
                     | C.errno.ENOTDIR
                  =>
                     raise Name_Error;
                  when others =>
                     raise Use_Error;
               end case;
            end if;
            if C.size_t (Result) < Buffer_Length then
               declare
                  Image : String (1 .. Natural (Result));
                  for Image'Address use Conv.To_Address (Buffer);
               begin
                  return Image;
               end;
            end if;
            Buffer_Length := Buffer_Length * 2;
            Buffer := Conv.To_Pointer (System.Memory.Reallocate (
               Conv.To_Address (Buffer),
               System.Storage_Elements.Storage_Count (Buffer_Length)));
         end;
      end loop;
   end Read_Symbolic_Link;

   function Read_Symbolic_Link (Directory_Entry : Directory_Entry_Type)
      return String is
   begin
      return Read_Symbolic_Link (Full_Name (Directory_Entry));
   end Read_Symbolic_Link;

end Ada.Directories.Information;