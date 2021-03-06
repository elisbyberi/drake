with Ada.Exception_Identification.From_Here;
package body Ada.Environment_Encoding.Encoding_Streams is
   use Exception_Identification.From_Here;
   use type Streams.Stream_Element;
   use type Streams.Stream_Element_Array;
   use type System.Address;

   subtype Stream_Element_Offset is Streams.Stream_Element_Offset;

   procedure Adjust_Buffer (
      Buffer : in out Buffer_Type;
      First : in out Streams.Stream_Element_Offset;
      Last : in out Streams.Stream_Element_Offset);
   procedure Adjust_Buffer (
      Buffer : in out Buffer_Type;
      First : in out Streams.Stream_Element_Offset;
      Last : in out Streams.Stream_Element_Offset) is
   begin
      if First >= Buffer_Type'First + Half_Buffer_Length then
         --  shift
         declare
            New_Last : constant Streams.Stream_Element_Offset :=
               Buffer_Type'First + Last - First;
         begin
            Buffer (Buffer_Type'First .. New_Last) := Buffer (First .. Last);
            First := Buffer_Type'First;
            Last := New_Last;
         end;
      end if;
   end Adjust_Buffer;

   procedure Initialize (Context : in out Reading_Context_Type);
   procedure Initialize (Context : in out Reading_Context_Type) is
   begin
      Context.First := Buffer_Type'First;
      Context.Last := Buffer_Type'First - 1;
      Context.Converted_First := Buffer_Type'First;
      Context.Converted_Last := Buffer_Type'First - 1;
      Context.Status := Continuing;
   end Initialize;

   procedure Set_Substitute_To_Reading_Converter (
      Object : in out Converter;
      Substitute : Streams.Stream_Element_Array)
      renames Set_Substitute; -- System.Native_Encoding.Set_Substitute

   procedure Read (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Item : out Streams.Stream_Element_Array;
      Last : out Streams.Stream_Element_Offset;
      Object : Converter;
      Context : in out Reading_Context_Type);
   procedure Read (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Item : out Streams.Stream_Element_Array;
      Last : out Streams.Stream_Element_Offset;
      Object : Converter;
      Context : in out Reading_Context_Type)
   is
      Read_Zero : Boolean := False;
   begin
      Last := Item'First - 1;
      while Last /= Item'Last loop
         --  filling
         if Context.Status = Continuing then
            Adjust_Buffer (Context.Buffer, Context.First, Context.Last);
            if Context.Last /= Buffer_Type'Last then
               declare
                  Old_Context_Last : constant Stream_Element_Offset :=
                     Context.Last;
               begin
                  Streams.Read (
                     Stream.all,
                     Context.Buffer (Context.Last + 1 .. Buffer_Type'Last),
                     Context.Last);
                  Read_Zero := Old_Context_Last = Context.Last;
               exception
                  when End_Error =>
                     Context.Status := Finishing;
               end;
            end if;
         end if;
         --  converting
         if Context.Status <= Finishing then
            Adjust_Buffer (
               Context.Converted_Buffer,
               Context.Converted_First,
               Context.Converted_Last);
            --  try to convert subsequence
            declare
               Taken : Stream_Element_Offset;
               Status : System.Native_Encoding.Subsequence_Status_Type;
            begin
               Convert_No_Check (
                  Object,
                  Context.Buffer (Context.First .. Context.Last),
                  Taken,
                  Context.Converted_Buffer (
                     Context.Converted_Last + 1 ..
                     Buffer_Type'Last),
                  Context.Converted_Last,
                  Finish => Context.Status > Continuing,
                  Status => Status);
               case Status is
                  when System.Native_Encoding.Finished =>
                     Context.Status := Ended;
                  when System.Native_Encoding.Success =>
                     null;
                  when System.Native_Encoding.Overflow =>
                     if Context.Converted_Last < Context.Converted_First then
                        raise Constraint_Error; -- Converted is too smaller
                     end if;
                  when System.Native_Encoding.Truncated =>
                     pragma Assert (Context.Status = Continuing);
                     if Context.Converted_Last < Context.Converted_First then
                        exit; -- wait tail-bytes
                     end if;
                  when System.Native_Encoding.Illegal_Sequence =>
                     declare
                        Is_Overflow : Boolean;
                     begin
                        Put_Substitute (
                           Object,
                           Context.Converted_Buffer (
                              Context.Converted_Last + 1 ..
                              Buffer_Type'Last),
                           Context.Converted_Last,
                           Is_Overflow);
                        if Is_Overflow then
                           exit; -- wait a next try
                        end if;
                     end;
                     --  skip one element
                     Taken := Stream_Element_Offset'Min (
                        Context.Last,
                        Context.First
                           + Min_Size_In_From_Stream_Elements (Object)
                           - 1);
               end case;
               --  drop converted subsequence
               Context.First := Taken + 1;
            end;
         end if;
         --  copy converted elements
         declare
            Move_Length : constant Stream_Element_Offset :=
               Stream_Element_Offset'Min (
                  Item'Last - Last,
                  Context.Converted_Last - Context.Converted_First + 1);
            New_Last : constant Stream_Element_Offset :=
               Last + Move_Length;
            New_Context_Converted_First : constant Stream_Element_Offset :=
               Context.Converted_First + Move_Length;
         begin
            Item (Last + 1 .. New_Last) :=
               Context.Converted_Buffer (
                  Context.Converted_First ..
                  New_Context_Converted_First - 1);
            Last := New_Last;
            Context.Converted_First := New_Context_Converted_First;
         end;
         exit when (Context.Status = Ended or else Read_Zero)
            and then Context.Converted_Last < Context.Converted_First;
      end loop;
      if Last = Item'First - 1 -- do not use "<" since underflow
         and then Context.Status = Ended
         and then Context.Converted_Last < Context.Converted_First
      then
         Raise_Exception (End_Error'Identity);
      end if;
   end Read;

   procedure Initialize (Context : in out Writing_Context_Type);
   procedure Initialize (Context : in out Writing_Context_Type) is
   begin
      Context.First := Buffer_Type'First;
      Context.Last := Buffer_Type'First - 1;
   end Initialize;

   procedure Set_Substitute_To_Writing_Converter (
      Object : in out Converter;
      Substitute : Streams.Stream_Element_Array);
   procedure Set_Substitute_To_Writing_Converter (
      Object : in out Converter;
      Substitute : Streams.Stream_Element_Array)
   is
      Substitute_Last : Streams.Stream_Element_Offset :=
         Substitute'First - 1;
      S2 : Streams.Stream_Element_Array (1 .. Max_Substitute_Length);
      S2_Last : Streams.Stream_Element_Offset := S2'First - 1;
   begin
      --  convert substitute from internal to external
      loop
         declare
            Status : System.Native_Encoding.Substituting_Status_Type;
         begin
            Convert_No_Check (
               Object,
               Substitute (Substitute_Last + 1 .. Substitute'Last),
               Substitute_Last,
               S2 (S2_Last + 1 .. S2'Last),
               S2_Last,
               Finish => True,
               Status => Status);
            case Status is
               when System.Native_Encoding.Finished =>
                  exit;
               when System.Native_Encoding.Success =>
                  null;
               when System.Native_Encoding.Overflow =>
                  raise Constraint_Error;
            end case;
         end;
      end loop;
      Set_Substitute (
         Object,
         S2 (1 .. S2_Last));
   end Set_Substitute_To_Writing_Converter;

   procedure Write (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Item : Streams.Stream_Element_Array;
      Object : Converter;
      Context : in out Writing_Context_Type);
   procedure Write (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Item : Streams.Stream_Element_Array;
      Object : Converter;
      Context : in out Writing_Context_Type)
   is
      Item_Last : Stream_Element_Offset := Item'First - 1;
   begin
      loop
         --  filling
         if Item_Last /= Item'Last then
            Adjust_Buffer (Context.Buffer, Context.First, Context.Last);
            if Context.Last /= Buffer_Type'Last then
               declare
                  Rest : constant Stream_Element_Offset :=
                     Stream_Element_Offset'Min (
                        Item'Last - Item_Last,
                        Buffer_Type'Last - Context.Last);
                  New_Context_Last : constant Stream_Element_Offset :=
                     Context.Last + Rest;
                  New_Item_Last : constant Stream_Element_Offset :=
                     Item_Last + Rest;
               begin
                  Context.Buffer (Context.Last + 1 .. New_Context_Last) :=
                     Item (Item_Last + 1 .. New_Item_Last);
                  Context.Last := New_Context_Last;
                  Item_Last := New_Item_Last;
               end;
            end if;
         else
            exit when Context.Last < Context.First;
         end if;
         --  try to convert subsequence
         declare
            Taken : Stream_Element_Offset;
            Out_Buffer : Streams.Stream_Element_Array (0 .. 63);
            Out_Last : Stream_Element_Offset;
            Status : System.Native_Encoding.Continuing_Status_Type;
         begin
            Convert_No_Check (
               Object,
               Context.Buffer (Context.First .. Context.Last),
               Taken,
               Out_Buffer,
               Out_Last,
               Status => Status);
            case Status is
               when System.Native_Encoding.Success =>
                  null;
               when System.Native_Encoding.Overflow =>
                  if Out_Last < Out_Buffer'First then
                     raise Constraint_Error; -- Out_Buffer is too smaller
                  end if;
               when System.Native_Encoding.Truncated =>
                  if Out_Last < Out_Buffer'First then
                     exit; -- wait tail-bytes
                  end if;
               when System.Native_Encoding.Illegal_Sequence =>
                  declare
                     Is_Overflow : Boolean;
                  begin
                     Put_Substitute (
                        Object,
                        Out_Buffer,
                        Out_Last,
                        Is_Overflow);
                     if Is_Overflow then
                        exit; -- wait a next try
                     end if;
                  end;
                  --  skip one element
                  Taken := Stream_Element_Offset'Min (
                     Context.Last,
                     Context.First
                        + Min_Size_In_From_Stream_Elements (Object)
                        - 1);
            end case;
            --  write converted subsequence
            Streams.Write (
               Stream.all,
               Out_Buffer (Out_Buffer'First .. Out_Last));
            --  drop converted subsequence
            Context.First := Taken + 1;
         end;
      end loop;
   end Write;

   procedure Finish (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Object : Converter;
      Context : in out Writing_Context_Type);
   procedure Finish (
      Stream : not null access Streams.Root_Stream_Type'Class;
      Object : Converter;
      Context : in out Writing_Context_Type)
   is
      Out_Buffer : Streams.Stream_Element_Array (0 .. 63);
      Out_Last : Stream_Element_Offset := -1;
      Status : System.Native_Encoding.Finishing_Status_Type;
   begin
      if Context.First <= Context.Last then
         --  put substitute instead of incomplete sequence in the buffer
         declare
            Is_Overflow : Boolean; -- ignore
         begin
            Put_Substitute (
               Object,
               Out_Buffer (Out_Last + 1 .. Out_Buffer'Last),
               Out_Last,
               Is_Overflow);
         end;
         Initialize (Context); -- reset indexes
      end if;
      --  finish
      loop
         Convert_No_Check (
            Object,
            Out_Buffer (Out_Last + 1 .. Out_Buffer'Last),
            Out_Last,
            Finish => True,
            Status => Status);
         Streams.Write (
            Stream.all,
            Out_Buffer (Out_Buffer'First .. Out_Last));
         case Status is
            when System.Native_Encoding.Finished =>
               exit;
            when System.Native_Encoding.Success =>
               null;
            when System.Native_Encoding.Overflow =>
               if Out_Last < Out_Buffer'First then
                  raise Constraint_Error; -- Out_Buffer is too smaller
               end if;
         end case;
      end loop;
   end Finish;

   --  implementation of only reading

   function Open (
      Decoder : Converter;
      Stream : not null access Streams.Root_Stream_Type'Class)
      return In_Type
   is
      pragma Suppress (Accessibility_Check);
      function To_Address (Value : access Streams.Root_Stream_Type'Class)
         return System.Address;
      pragma Import (Intrinsic, To_Address);
   begin
      return Result : In_Type do
         Result.Stream := To_Address (Stream);
         Result.Reading_Converter := Decoder'Unrestricted_Access;
         Initialize (Result.Reading_Context);
      end return;
   end Open;

   function Is_Open (Object : In_Type) return Boolean is
   begin
      return Object.Stream /= System.Null_Address;
   end Is_Open;

   function Stream (Object : aliased in out In_Type)
      return not null access Streams.Root_Stream_Type'Class is
   begin
      if not Is_Open (Object) then
         Raise_Exception (Status_Error'Identity);
      end if;
      return Object'Unchecked_Access;
   end Stream;

   overriding procedure Read (
      Object : in out In_Type;
      Item : out Streams.Stream_Element_Array;
      Last : out Streams.Stream_Element_Offset)
   is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      Read (
         To_Pointer (Object.Stream),
         Item,
         Last,
         Object.Reading_Converter.all,
         Object.Reading_Context);
   end Read;

   --  implementation of only writing

   function Open (
      Encoder : Converter;
      Stream : not null access Streams.Root_Stream_Type'Class)
      return Out_Type
   is
      pragma Suppress (Accessibility_Check);
      function To_Address (Value : access Streams.Root_Stream_Type'Class)
         return System.Address;
      pragma Import (Intrinsic, To_Address);
   begin
      return Result : Out_Type do
         Result.Stream := To_Address (Stream);
         Result.Writing_Converter := Encoder'Unrestricted_Access;
         Initialize (Result.Writing_Context);
      end return;
   end Open;

   function Is_Open (Object : Out_Type) return Boolean is
   begin
      return Object.Stream /= System.Null_Address;
   end Is_Open;

   function Stream (Object : aliased in out Out_Type)
      return not null access Streams.Root_Stream_Type'Class is
   begin
      if not Is_Open (Object) then
         Raise_Exception (Status_Error'Identity);
      end if;
      return Object'Unchecked_Access;
   end Stream;

   procedure Finish (Object : in out Out_Type) is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      if not Is_Open (Object) then
         Raise_Exception (Status_Error'Identity);
      end if;
      Finish (
         To_Pointer (Object.Stream),
         Object.Writing_Converter.all,
         Object.Writing_Context);
   end Finish;

   overriding procedure Write (
      Object : in out Out_Type;
      Item : Streams.Stream_Element_Array)
   is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      Write (
         To_Pointer (Object.Stream),
         Item,
         Object.Writing_Converter.all,
         Object.Writing_Context);
   end Write;

   --  implementation of bidirectional

   function Open (
      Internal : Encoding_Id;
      External : Encoding_Id;
      Stream : not null access Streams.Root_Stream_Type'Class)
      return Inout_Type
   is
      pragma Suppress (Accessibility_Check);
      function To_Address (Value : access Streams.Root_Stream_Type'Class)
         return System.Address;
      pragma Import (Intrinsic, To_Address);
   begin
      return Result : Inout_Type do
         Result.Internal := Internal;
         Result.External := External;
         Result.Stream := To_Address (Stream);
         Result.Substitute_Length := -1;
         Initialize (Result.Reading_Context);
         Initialize (Result.Writing_Context);
      end return;
   end Open;

   function Is_Open (Object : Inout_Type) return Boolean is
   begin
      return Object.Stream /= System.Null_Address;
   end Is_Open;

   function Substitute (Object : Inout_Type)
      return Streams.Stream_Element_Array is
   begin
      if Object.Substitute_Length < 0 then
         return Default_Substitute (Object.Internal);
      else
         return Object.Substitute (1 .. Object.Substitute_Length);
      end if;
   end Substitute;

   procedure Set_Substitute (
      Object : in out Inout_Type;
      Substitute : Streams.Stream_Element_Array) is
   begin
      if Substitute'Length > Object.Substitute'Length then
         raise Constraint_Error;
      end if;
      Object.Substitute_Length := Substitute'Length;
      Object.Substitute (1 .. Object.Substitute_Length) := Substitute;
      --  set to converters
      if Is_Open (Object.Reading_Converter) then
         Set_Substitute_To_Reading_Converter (
            Object.Reading_Converter,
            Substitute);
      end if;
      if Is_Open (Object.Writing_Converter) then
         Set_Substitute_To_Writing_Converter (
            Object.Writing_Converter,
            Substitute);
      end if;
   end Set_Substitute;

   function Stream (Object : aliased in out Inout_Type)
      return not null access Streams.Root_Stream_Type'Class is
   begin
      if not Is_Open (Object) then
         Raise_Exception (Status_Error'Identity);
      end if;
      return Object'Unchecked_Access;
   end Stream;

   procedure Finish (Object : in out Inout_Type) is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      if not Is_Open (Object) then
         Raise_Exception (Status_Error'Identity);
      end if;
      if Is_Open (Object.Writing_Converter) then
         Finish (
            To_Pointer (Object.Stream),
            Object.Writing_Converter,
            Object.Writing_Context);
      end if;
   end Finish;

   overriding procedure Read (
      Object : in out Inout_Type;
      Item : out Streams.Stream_Element_Array;
      Last : out Streams.Stream_Element_Offset)
   is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      if not Is_Open (Object.Reading_Converter) then
         Open (
            Object.Reading_Converter,
            From => System.Native_Encoding.Encoding_Id (Object.External),
            To => System.Native_Encoding.Encoding_Id (Object.Internal));
         if Object.Substitute_Length >= 0 then
            Set_Substitute_To_Reading_Converter (
               Object.Reading_Converter,
               Object.Substitute (1 .. Object.Substitute_Length));
         end if;
      end if;
      Read (
         To_Pointer (Object.Stream),
         Item,
         Last,
         Object.Reading_Converter,
         Object.Reading_Context);
   end Read;

   overriding procedure Write (
      Object : in out Inout_Type;
      Item : Streams.Stream_Element_Array)
   is
      function To_Pointer (Value : System.Address)
         return access Streams.Root_Stream_Type'Class;
      pragma Import (Intrinsic, To_Pointer);
   begin
      if not Is_Open (Object.Writing_Converter) then
         Open (
            Object.Writing_Converter,
            From => System.Native_Encoding.Encoding_Id (Object.Internal),
            To => System.Native_Encoding.Encoding_Id (Object.External));
         if Object.Substitute_Length >= 0 then
            Set_Substitute_To_Writing_Converter (
               Object.Writing_Converter,
               Object.Substitute (1 .. Object.Substitute_Length));
         end if;
      end if;
      Write (
         To_Pointer (Object.Stream),
         Item,
         Object.Writing_Converter,
         Object.Writing_Context);
   end Write;

end Ada.Environment_Encoding.Encoding_Streams;
