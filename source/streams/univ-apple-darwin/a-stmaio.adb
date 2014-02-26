with Ada.Exception_Identification.From_Here;
with C.sys.mman;
with C.sys.types;
package body Ada.Storage_Mapped_IO is
   use Exception_Identification.From_Here;
   use type Streams.Stream_IO.Count;
   use type System.Address;
   use type C.signed_int;
   use type C.size_t;
   use type C.sys.types.off_t;

   procedure Map (
      Object : in out Non_Controlled_Mapping;
      File : Streams.Stream_IO.Inside.Non_Controlled_File_Type;
      Offset : Streams.Stream_IO.Positive_Count;
      Size : Streams.Stream_IO.Count;
      Writable : Boolean);
   procedure Map (
      Object : in out Non_Controlled_Mapping;
      File : Streams.Stream_IO.Inside.Non_Controlled_File_Type;
      Offset : Streams.Stream_IO.Positive_Count;
      Size : Streams.Stream_IO.Count;
      Writable : Boolean)
   is
      Protects : constant array (Boolean) of C.signed_int := (
         C.sys.mman.PROT_READ,
         C.sys.mman.PROT_READ + C.sys.mman.PROT_WRITE);
      Mapped_Offset : constant C.sys.types.off_t :=
         C.sys.types.off_t (Offset) - 1;
      Mapped_Size : C.size_t := C.size_t (Size);
      Mapped_Address : C.void_ptr;
   begin
      if Mapped_Size = 0 then
         Mapped_Size := C.size_t (Streams.Stream_IO.Inside.Size (File))
            - C.size_t (Mapped_Offset);
      end if;
      Mapped_Address := C.sys.mman.mmap (
         C.void_ptr (System.Null_Address),
         Mapped_Size,
         Protects (Writable),
         C.sys.mman.MAP_FILE + C.sys.mman.MAP_SHARED,
         Streams.Stream_IO.Inside.Handle (File),
         Mapped_Offset);
      if System.Address (Mapped_Address) =
         System.Address (C.sys.mman.MAP_FAILED)
      then
         Raise_Exception (Use_Error'Identity);
      end if;
      Object.Address := System.Address (Mapped_Address);
      Object.Size := System.Storage_Elements.Storage_Count (Mapped_Size);
   end Map;

   procedure Unmap (
      Object : in out Non_Controlled_Mapping;
      Raise_On_Error : Boolean);
   procedure Unmap (
      Object : in out Non_Controlled_Mapping;
      Raise_On_Error : Boolean) is
   begin
      --  unmap
      if C.sys.mman.munmap (
         C.void_ptr (Object.Address),
         C.size_t (Object.Size)) /= 0
      then
         if Raise_On_Error then
            Raise_Exception (Use_Error'Identity);
         end if;
      end if;
      --  reset
      Object.Address := System.Null_Address;
      --  close file
      if Streams.Stream_IO.Inside.Is_Open (Object.File) then
         Streams.Stream_IO.Inside.Close (
            Object.File'Access,
            Raise_On_Error => Raise_On_Error);
      end if;
   end Unmap;

   --  implementation

   function Is_Map (Object : Mapping) return Boolean is
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      return NC_Mapping.Address /= System.Null_Address;
   end Is_Map;

   procedure Map (
      Object : out Mapping;
      File : Streams.Stream_IO.File_Type;
      Offset : Streams.Stream_IO.Positive_Count := 1;
      Size : Streams.Stream_IO.Count := 0)
   is
      pragma Unmodified (Object); -- modified via 'Unrestricted_Access
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      --  check already opened
      if NC_Mapping.Address /= System.Null_Address then
         Raise_Exception (Status_Error'Identity);
      end if;
      --  map
      Map (
         NC_Mapping.all,
         Streams.Stream_IO.Inside.Non_Controlled (File).all,
         Offset,
         Size,
         Writable => Streams.Stream_IO.Mode (File) /= In_File);
   end Map;

   procedure Map (
      Object : out Mapping;
      Mode : File_Mode := In_File;
      Name : String;
      Form : String := "";
      Offset : Streams.Stream_IO.Positive_Count := 1;
      Size : Streams.Stream_IO.Count := 0)
   is
      pragma Unmodified (Object); -- modified via 'Unrestricted_Access
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      --  check already opened
      if NC_Mapping.Address /= System.Null_Address then
         Raise_Exception (Status_Error'Identity);
      end if;
      --  open file
      --  this file will be closed in Finalize even if any exception is raised
      Streams.Stream_IO.Inside.Open (
         NC_Mapping.File,
         Mode,
         Name,
         Streams.Stream_IO.Inside.Pack (Form));
      --  map
      Map (
         NC_Mapping.all,
         NC_Mapping.File,
         Offset,
         Size,
         Writable => Mode /= In_File);
   end Map;

   procedure Unmap (Object : in out Mapping) is
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      if NC_Mapping.Address = System.Null_Address then
         Raise_Exception (Status_Error'Identity);
      end if;
      Unmap (NC_Mapping.all, Raise_On_Error => True);
   end Unmap;

   function Address (Object : Mapping) return System.Address is
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      return NC_Mapping.Address;
   end Address;

   function Size (Object : Mapping)
      return System.Storage_Elements.Storage_Count
   is
      NC_Mapping : constant not null access Non_Controlled_Mapping :=
         Reference (Object);
   begin
      return NC_Mapping.Size;
   end Size;

   package body Controlled is

      function Reference (Object : Mapping)
         return not null access Non_Controlled_Mapping is
      begin
         return Object.Data'Unrestricted_Access;
      end Reference;

      overriding procedure Finalize (Object : in out Mapping) is
      begin
         if Object.Data.Address /= System.Null_Address then
            Unmap (Object.Data, Raise_On_Error => False);
         end if;
      end Finalize;

   end Controlled;

end Ada.Storage_Mapped_IO;
