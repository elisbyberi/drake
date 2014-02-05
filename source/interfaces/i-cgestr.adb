with Ada.Exceptions;
with System.Address_To_Named_Access_Conversions;
with System.Address_To_Constant_Access_Conversions;
with System.Storage_Elements;
package body Interfaces.C.Generic_Strings is
   pragma Suppress (All_Checks);
   use type System.Storage_Elements.Storage_Offset;

   package libc is

      function strlen (Item : not null access constant Element)
         return size_t;
      pragma Import (Intrinsic, strlen, "__builtin_strlen");

      function wcslen (Item : not null access constant Element)
         return size_t;
      pragma Import (C, wcslen);

      procedure memcpy (
         s1 : not null access Element;
         s2 : not null access constant Element;
         n : size_t);
      pragma Import (Intrinsic, memcpy, "__builtin_memcpy");

      procedure memmove (
         s1 : not null access Element;
         s2 : not null access constant Element;
         n : size_t);
      pragma Import (Intrinsic, memmove, "__builtin_memmove");

      function malloc (size : size_t) return chars_ptr;
      pragma Import (Intrinsic, malloc, "__builtin_malloc");

      procedure free (ptr : chars_ptr);
      pragma Import (Intrinsic, free, "__builtin_free");

   end libc;

   package Conv is
      new System.Address_To_Named_Access_Conversions (Element, chars_ptr);
   package const_Conv is
      new System.Address_To_Constant_Access_Conversions (
         Element,
         const_chars_ptr);

   --  implementation

   function To_Chars_Ptr (
      Item : access Element_Array;
      Nul_Check : Boolean := False)
      return chars_ptr is
   begin
      if Item = null then
         return null;
      else
         if Nul_Check then
            --  raise Terminator_Error when Item contains no nul
            if Element'Size = char'Size then
               declare
                  ca_Item : char_array (Item'Range);
                  for ca_Item'Address use Item.all'Address;
                  Dummy : constant size_t := Length (ca_Item);
                  pragma Unreferenced (Dummy);
               begin
                  null;
               end;
            elsif Element'Size = wchar_t'Size then
               declare
                  wa_Item : wchar_array (Item'Range);
                  for wa_Item'Address use Item.all'Address;
                  Dummy : constant size_t := Length (wa_Item);
                  pragma Unreferenced (Dummy);
               begin
                  null;
               end;
            else
               declare
                  I : size_t := Item'First;
               begin
                  loop
                     if I <= Item'Last then
                        Ada.Exceptions.Raise_Exception_From_Here (
                           Terminator_Error'Identity);
                     end if;
                     exit when Item (I) = Element'Val (0);
                     I := I + 1;
                  end loop;
               end;
            end if;
         end if;
         return Item.all (Item.all'First)'Access;
      end if;
   end To_Chars_Ptr;

   function To_Const_Chars_Ptr (Item : not null access constant Element_Array)
      return not null const_chars_ptr is
   begin
      return Item.all (Item.all'First)'Access;
   end To_Const_Chars_Ptr;

   function New_Char_Array (Chars : Element_Array)
      return not null chars_ptr is
   begin
      return New_Chars_Ptr (
         const_Conv.To_Pointer (Chars'Address),
         Chars'Length); -- CXB3009, accept non-nul terminated
   end New_Char_Array;

   function New_String (Str : String_Type) return not null chars_ptr is
      C : constant Element_Array := To_C (Str, Append_Nul => False);
   begin
      return New_Chars_Ptr (C (C'First)'Access, C'Length);
   end New_String;

   function New_Chars_Ptr (Length : size_t) return not null chars_ptr is
      Size : constant System.Storage_Elements.Storage_Count :=
         System.Storage_Elements.Storage_Count (Length)
            * (Element'Size / Standard'Storage_Unit);
      Result : constant chars_ptr := libc.malloc (
         C.size_t (Size + Element'Size / Standard'Storage_Unit));
   begin
      if Result = null then
         raise Storage_Error;
      end if;
      Result.all := Element'Val (0);
      return Result;
   end New_Chars_Ptr;

   function New_Chars_Ptr (
      Item : not null access constant Element;
      Length : size_t)
      return not null chars_ptr
   is
      Result : constant chars_ptr := New_Chars_Ptr (Length);
      Size : constant System.Storage_Elements.Storage_Count :=
         System.Storage_Elements.Storage_Count (Length)
            * (Element'Size / Standard'Storage_Unit);
   begin
      libc.memcpy (Result, Item, C.size_t (Size));
      Conv.To_Pointer (Conv.To_Address (Result) + Size).all := Element'Val (0);
      return Result;
   end New_Chars_Ptr;

   function New_Chars_Ptr (Item : not null access constant Element)
      return not null chars_ptr is
   begin
      return New_Chars_Ptr (Item, Strlen (Item));
   end New_Chars_Ptr;

   function New_Strcat (Items : const_chars_ptr_array)
      return not null chars_ptr
   is
      Lengths : array (Items'Range) of size_t;
      Total_Length : size_t;
      Offset : size_t;
      Result : chars_ptr;
   begin
      --  get length
      Total_Length := 0;
      for I in Items'Range loop
         Lengths (I) := Strlen (Items (I));
         Total_Length := Total_Length + Lengths (I);
      end loop;
      --  allocate
      Result := New_Chars_Ptr (Total_Length);
      --  copy
      Offset := 0;
      for I in Items'Range loop
         Update (Result, Offset, Items (I), Lengths (I));
         Offset := Offset + Lengths (I);
      end loop;
      return Result;
   end New_Strcat;

   function New_Strcat (Items : const_chars_ptr_With_Length_array)
      return not null chars_ptr
   is
      Total_Length : size_t;
      Offset : size_t;
      Result : chars_ptr;
   begin
      --  get length
      Total_Length := 0;
      for I in Items'Range loop
         Total_Length := Total_Length + Items (I).Length;
      end loop;
      --  allocate
      Result := New_Chars_Ptr (Total_Length);
      --  copy
      Offset := 0;
      for I in Items'Range loop
         Update (Result, Offset, Items (I).ptr, Items (I).Length);
         Offset := Offset + Items (I).Length;
      end loop;
      return Result;
   end New_Strcat;

   procedure Free (Item : in out chars_ptr) is
   begin
      libc.free (Item);
      Item := null;
   end Free;

   function Value (Item : access constant Element)
      return Element_Array is
   begin
      if const_chars_ptr (Item) = null then
         Ada.Exceptions.Raise_Exception_From_Here (
            Dereference_Error'Identity); -- CXB3010
      end if;
      declare
         Length : constant size_t := Strlen (Item);
         Source : Element_Array (0 .. Length); -- CXB3009, including nul
         for Source'Address use Conv.To_Address (Item);
      begin
         return Source;
      end;
   end Value;

   function Value (
      Item : access constant Element;
      Length : size_t;
      Append_Nul : Boolean := False)
      return Element_Array
   is
      Actual_Length : size_t;
   begin
      if not Append_Nul and then Length = 0 then
         raise Constraint_Error; -- CXB3010
      end if;
      if const_chars_ptr (Item) = null then
         if Length > 0 then
            Ada.Exceptions.Raise_Exception_From_Here (
               Dereference_Error'Identity); -- CXB3010
         end if;
         Actual_Length := 0;
      else
         Actual_Length := Strlen (Item) + 1; -- including nul
      end if;
      declare
         Source : Element_Array (0 .. Actual_Length - 1);
         for Source'Address use Conv.To_Address (Item);
      begin
         if Append_Nul and then Length < Actual_Length then
            return Source (0 .. Length - 1) & Element'Val (0);
         else
            return Source (0 .. size_t'Min (Actual_Length, Length) - 1);
            --  CXB3010, not appending nul
         end if;
      end;
   end Value;

   function Value (Item : access constant Element)
      return String_Type
   is
      C : constant Element_Array := Value (Item);
   begin
      return To_Ada (C (C'First .. C'Last - 1), Trim_Nul => False);
   end Value;

   function Value (Item : access constant Element; Length : size_t)
      return String_Type
   is
      C : constant Element_Array := Value (Item, Length, Append_Nul => True);
   begin
      return To_Ada (C (C'First .. C'Last - 1), Trim_Nul => False);
   end Value;

   function Strlen (Item : access constant Element)
      return size_t is
   begin
      if const_chars_ptr (Item) = null then
         Ada.Exceptions.Raise_Exception_From_Here (
            Dereference_Error'Identity); -- CXB3011
      end if;
      if Element'Size = char'Size then
         return libc.strlen (Item);
      elsif Element'Size = wchar_t'Size then
         return libc.wcslen (Item);
      else
         declare
            S : const_chars_ptr := const_chars_ptr (Item);
            Length : size_t := 0;
         begin
            while S.all /= Element'Val (0) loop
               Length := Length + 1;
               S := const_Conv.To_Pointer (
                  const_Conv.To_Address (S)
                  + Element'Size / Standard'Storage_Unit);
            end loop;
            return Length;
         end;
      end if;
   end Strlen;

   procedure Update (
      Item : access Element;
      Offset : size_t;
      Chars : Element_Array;
      Check : Boolean := True) is
   begin
      if chars_ptr (Item) = null then
         Ada.Exceptions.Raise_Exception_From_Here (
            Dereference_Error'Identity); -- CXB3011
      end if;
      if Check and then Offset + Chars'Length > Strlen (Item) then
         Ada.Exceptions.Raise_Exception_From_Here (Update_Error'Identity);
      end if;
      Update (
         Item,
         Offset,
         const_Conv.To_Pointer (Chars'Address),
         Chars'Length);
   end Update;

   procedure Update (
      Item : access Element;
      Offset : size_t;
      Str : String_Type;
      Check : Boolean := True) is
   begin
      Update (
         Item,
         Offset,
         To_C (Str, Append_Nul => False),
         Check);
   end Update;

   procedure Update (
      Item : not null access Element;
      Offset : size_t;
      Source : not null access constant Element;
      Length : size_t)
   is
      Offset_Size : constant System.Storage_Elements.Storage_Count :=
         System.Storage_Elements.Storage_Count (Offset)
            * (Element'Size / Standard'Storage_Unit);
      Offsetted_Item : constant chars_ptr :=
         Conv.To_Pointer (Conv.To_Address (chars_ptr (Item)) + Offset_Size);
      Size : constant System.Storage_Elements.Storage_Count :=
         System.Storage_Elements.Storage_Count (Length)
            * (Element'Size / Standard'Storage_Unit);
   begin
      libc.memmove (Offsetted_Item, Source, C.size_t (Size));
   end Update;

   procedure Update (
      Item : not null access Element;
      Offset : size_t;
      Source : not null access constant Element) is
   begin
      Update (
         Item,
         Offset,
         Source,
         Strlen (Source));
   end Update;

end Interfaces.C.Generic_Strings;
