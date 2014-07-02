with Ada.Exception_Identification.From_Here;
with Ada.Unchecked_Conversion;
with System.UTF_Conversions;
package body Interfaces.C is
   pragma Suppress (All_Checks);
   use Ada.Exception_Identification.From_Here;

   generic
      type Element is private;
      type Element_Array is array (size_t range <>) of aliased Element;
      type Element_Access is access constant Element;
   function Pointer_Add (Left : not null Element_Access; Right : ptrdiff_t)
      return not null Element_Access;

   function Pointer_Add (Left : not null Element_Access; Right : ptrdiff_t)
      return not null Element_Access
   is
      function To_ptrdiff_t is
         new Ada.Unchecked_Conversion (Element_Access, ptrdiff_t);
      function To_Pointer is
         new Ada.Unchecked_Conversion (ptrdiff_t, Element_Access);
   begin
      return To_Pointer (
         To_ptrdiff_t (Left)
         + Right * (Element_Array'Component_Size / Standard'Storage_Unit));
   end Pointer_Add;

   generic
      type Element is private;
      type Element_Array is array (size_t range <>) of aliased Element;
      type Element_Access is access constant Element;
   function Pointer_Sub (Left, Right : not null Element_Access)
      return ptrdiff_t;

   function Pointer_Sub (Left, Right : not null Element_Access)
      return ptrdiff_t
   is
      function To_ptrdiff_t is
         new Ada.Unchecked_Conversion (Element_Access, ptrdiff_t);
   begin
      return (To_ptrdiff_t (Left) - To_ptrdiff_t (Right))
         / (Element_Array'Component_Size / Standard'Storage_Unit);
   end Pointer_Sub;

   generic
      type Element is (<>);
      type Element_Array is array (size_t range <>) of aliased Element;
      type Element_ptr is access constant Element;
      with function Find_nul (s : not null Element_ptr; n : size_t)
         return Element_ptr;
   package Lengths is

      function Is_Nul_Terminated (Item : Element_Array) return Boolean;

      function Length (Item : Element_Array) return size_t;

   end Lengths;

   package body Lengths is

      function Is_Nul_Terminated (Item : Element_Array) return Boolean is
         nul_Pos : constant Element_ptr :=
            Find_nul (
               Item (Item'First)'Unchecked_Access,
               Item'Length);
      begin
         return nul_Pos /= null;
      end Is_Nul_Terminated;

      function Length (Item : Element_Array) return size_t is
         function "-" is new Pointer_Sub (Element, Element_Array, Element_ptr);
         Item_ptr : constant Element_ptr := Item (Item'First)'Unchecked_Access;
         nul_Pos : constant Element_ptr := Find_nul (Item_ptr, Item'Length);
      begin
         if nul_Pos = null then
            Raise_Exception (Terminator_Error'Identity); -- CXB3005
         end if;
         return size_t (nul_Pos - Item_ptr);
      end Length;

   end Lengths;

   generic
      type Character_Type is (<>);
      type String_Type is array (Positive range <>) of Character_Type;
      type Element is (<>);
      type Element_Array is array (size_t range <>) of aliased Element;
      with function Length (Item : Element_Array) return size_t;
   package Simple_Conversions is

      pragma Compile_Time_Error (
         String_Type'Component_Size /= Element_Array'Component_Size,
         "size mismatch!");

      function To_Nul_Terminated (Item : String_Type)
         return Element_Array;
      function To_Non_Nul_Terminated (Item : String_Type)
         return Element_Array;

      function From_Nul_Terminated (Item : Element_Array)
         return String_Type;
      function From_Non_Nul_Terminated (Item : Element_Array)
         return String_Type;

      procedure To_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t);
      procedure To_Non_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t);

      procedure From_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural);
      procedure From_Non_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural);

   end Simple_Conversions;

   package body Simple_Conversions is

      function To_Nul_Terminated (Item : String_Type)
         return Element_Array
      is
         C_Item : Element_Array (0 .. Item'Length - 1);
         for C_Item'Address use Item'Address;
      begin
         return C_Item & Element'Val (0);
      end To_Nul_Terminated;

      function To_Non_Nul_Terminated (Item : String_Type)
         return Element_Array
      is
         C_Item : Element_Array (0 .. Item'Length - 1);
         for C_Item'Address use Item'Address;
      begin
         return C_Item;
      end To_Non_Nul_Terminated;

      function From_Nul_Terminated (Item : Element_Array)
         return String_Type
      is
         Ada_Item : String_Type (1 .. Item'Length);
         for Ada_Item'Address use Item'Address;
      begin
         return Ada_Item (1 .. Natural (Length (Item)));
      end From_Nul_Terminated;

      function From_Non_Nul_Terminated (Item : Element_Array)
         return String_Type
      is
         Ada_Item : String_Type (1 .. Item'Length);
         for Ada_Item'Address use Item'Address;
      begin
         return Ada_Item;
      end From_Non_Nul_Terminated;

      procedure To_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t)
      is
         C_Item : Element_Array (0 .. Item'Length - 1);
         for C_Item'Address use Item'Address;
      begin
         Count := C_Item'Length + 1;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First .. Target'First + C_Item'Length - 1) := C_Item;
         Target (Target'First + C_Item'Length) := Element'Val (0);
      end To_Nul_Terminated;

      procedure To_Non_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t)
      is
         C_Item : Element_Array (0 .. Item'Length - 1);
         for C_Item'Address use Item'Address;
      begin
         Count := C_Item'Length;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First .. Target'First + C_Item'Length - 1) := C_Item;
      end To_Non_Nul_Terminated;

      procedure From_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural)
      is
         Ada_Item : String_Type (1 .. Item'Length);
         for Ada_Item'Address use Item'Address;
      begin
         Count := Natural (Length (Item));
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First .. Target'First + Count - 1) :=
            Ada_Item (1 .. Count);
      end From_Nul_Terminated;

      procedure From_Non_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural)
      is
         Ada_Item : String_Type (1 .. Item'Length);
         for Ada_Item'Address use Item'Address;
      begin
         Count := Item'Length;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First .. Target'First + Count - 1) :=
            Ada_Item (1 .. Count);
      end From_Non_Nul_Terminated;

   end Simple_Conversions;

   --  char

   type char_const_ptr is access constant char;
   for char_const_ptr'Storage_Size use 0;

   function Find_nul (s : not null char_const_ptr; n : size_t)
      return char_const_ptr;
   function Find_nul (s : not null char_const_ptr; n : size_t)
      return char_const_ptr
   is
      function memchr (
         s : not null char_const_ptr;
         c : int;
         n : size_t)
         return char_const_ptr;
      pragma Import (Intrinsic, memchr, "__builtin_memchr");
   begin
      return memchr (s, 0, n);
   end Find_nul;

   package char_Lengths is
      new Lengths (
         char,
         char_array,
         char_const_ptr,
         Find_nul);

   package char_Conv is
      new Simple_Conversions (
         Character,
         String,
         char,
         char_array,
         char_Lengths.Length);

   --  wchar_t

   type wchar_t_const_ptr is access constant wchar_t;
   for wchar_t_const_ptr'Storage_Size use 0;

   function Find_nul (s : not null wchar_t_const_ptr; n : size_t)
      return wchar_t_const_ptr;
   function Find_nul (s : not null wchar_t_const_ptr; n : size_t)
      return wchar_t_const_ptr
   is
      function wmemchr (
         ws : not null wchar_t_const_ptr;
         wc : int;
         n : size_t)
         return wchar_t_const_ptr;
      pragma Import (C, wmemchr);
   begin
      return wmemchr (s, 0, n);
   end Find_nul;

   package wchar_Lengths is
      new Lengths (
         wchar_t,
         wchar_array,
         wchar_t_const_ptr,
         Find_nul);

   package wchar_Conv is
      new Simple_Conversions (
         Wide_Wide_Character,
         Wide_Wide_String,
         wchar_t,
         wchar_array,
         wchar_Lengths.Length);

   procedure To_Non_Nul_Terminated (
      Item : Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Substitute : wchar_t);
   procedure To_Non_Nul_Terminated (
      Item : Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Substitute : wchar_t)
   is
      Ada_Target : Wide_Wide_String (1 .. Target'Length);
      for Ada_Target'Address use Target'Address;
      Item_Index : Natural := Item'First;
      Target_Index : Natural := Ada_Target'First;
   begin
      while Item_Index <= Item'Last loop
         declare
            Code : System.UTF_Conversions.UCS_4;
            Item_Used : Natural;
            From_Status : System.UTF_Conversions.From_Status_Type;
            Target_Last : Natural;
            To_Status : System.UTF_Conversions.To_Status_Type;
         begin
            System.UTF_Conversions.From_UTF_16 (
               Item (Item_Index .. Item'Last),
               Item_Used,
               Code,
               From_Status);
            Item_Index := Item_Used + 1;
            case From_Status is
               when System.UTF_Conversions.Success =>
                  null;
               when System.UTF_Conversions.Illegal_Sequence
                  | System.UTF_Conversions.Truncated =>
                  Code := wchar_t'Pos (Substitute);
            end case;
            System.UTF_Conversions.To_UTF_32 (
               Code,
               Ada_Target (Target_Index .. Ada_Target'Last),
               Target_Last,
               To_Status);
            case To_Status is
               when System.UTF_Conversions.Success =>
                  null;
               when System.UTF_Conversions.Overflow
                  | System.UTF_Conversions.Unmappable =>
                  --  all values of UTF-16 are mappable to UTF-32
                  raise Constraint_Error;
            end case;
            Target_Index := Target_Last + 1;
         end;
      end loop;
      Count := size_t (Target_Index - Ada_Target'First);
   end To_Non_Nul_Terminated;

   procedure From_Non_Nul_Terminated (
      Item : wchar_array;
      Target : out Wide_String;
      Count : out Natural;
      Substitute : Wide_Character);
   procedure From_Non_Nul_Terminated (
      Item : wchar_array;
      Target : out Wide_String;
      Count : out Natural;
      Substitute : Wide_Character)
   is
      Ada_Item : Wide_Wide_String (1 .. Item'Length);
      for Ada_Item'Address use Item'Address;
      Item_Index : Natural := Ada_Item'First;
      Target_Index : Natural := Target'First;
   begin
      while Item_Index <= Ada_Item'Last loop
         declare
            Code : System.UTF_Conversions.UCS_4;
            Item_Used : Natural;
            From_Status : System.UTF_Conversions.From_Status_Type; -- ignored
            Target_Last : Natural;
            To_Status : System.UTF_Conversions.To_Status_Type;
         begin
            System.UTF_Conversions.From_UTF_32 (
               Ada_Item (Item_Index .. Ada_Item'Last),
               Item_Used,
               Code,
               From_Status);
            Item_Index := Item_Used + 1;
            case From_Status is
               when System.UTF_Conversions.Success =>
                  null;
               when System.UTF_Conversions.Illegal_Sequence
                  | System.UTF_Conversions.Truncated =>
                  --  Truncated does not returned in UTF-32
                  Code := Wide_Character'Pos (Substitute);
            end case;
            System.UTF_Conversions.To_UTF_16 (
               Code,
               Target (Target_Index .. Target'Last),
               Target_Last,
               To_Status);
            case To_Status is
               when System.UTF_Conversions.Success =>
                  null;
               when System.UTF_Conversions.Overflow =>
                  raise Constraint_Error;
               when System.UTF_Conversions.Unmappable =>
                  Target (Target_Index) := Substitute;
                  Target_Last := Target_Index;
            end case;
            Target_Index := Target_Last + 1;
         end;
      end loop;
      Count := Target_Index - Target'First;
   end From_Non_Nul_Terminated;

   --  char16_t

   type char16_t_const_ptr is access constant char16_t;
   for char16_t_const_ptr'Storage_Size use 0;

   function Find_nul (s : not null char16_t_const_ptr; n : size_t)
      return char16_t_const_ptr;
   function Find_nul (s : not null char16_t_const_ptr; n : size_t)
      return char16_t_const_ptr
   is
      function "+" is
         new Pointer_Add (char16_t, char16_array, char16_t_const_ptr);
      p : not null char16_t_const_ptr := s;
      r : size_t := n;
   begin
      while r > 0 loop
         if p.all = char16_nul then
            return p;
         end if;
         p := p + 1;
         r := r - 1;
      end loop;
      return null;
   end Find_nul;

   package char16_Lengths is
      new Lengths (
         char16_t,
         char16_array,
         char16_t_const_ptr,
         Find_nul);

   package char16_Conv is
      new Simple_Conversions (
         Wide_Character,
         Wide_String,
         char16_t,
         char16_array,
         char16_Lengths.Length);

   --  char32_t

   type char32_t_const_ptr is access constant char32_t;
   for char32_t_const_ptr'Storage_Size use 0;

   function Find_nul (s : not null char32_t_const_ptr; n : size_t)
      return char32_t_const_ptr;
   function Find_nul (s : not null char32_t_const_ptr; n : size_t)
      return char32_t_const_ptr
   is
      function "+" is
         new Pointer_Add (char32_t, char32_array, char32_t_const_ptr);
      p : not null char32_t_const_ptr := s;
      r : size_t := n;
   begin
      while r > 0 loop
         if p.all = char32_nul then
            return p;
         end if;
         p := p + 1;
         r := r - 1;
      end loop;
      return null;
   end Find_nul;

   package char32_Lengths is
      new Lengths (
         char32_t,
         char32_array,
         char32_t_const_ptr,
         Find_nul);

   package char32_Conv is
      new Simple_Conversions (
         Wide_Wide_Character,
         Wide_Wide_String,
         char32_t,
         char32_array,
         char32_Lengths.Length);

   --  implementation of Characters and Strings

   --  Character (UTF-8) from/to char (UTF-8)
   --  In POSIX, other packages (Ada.Command_Line, Ada.Environment_Variables,
   --    Ada.Text_IO, etc) also assume that the system encoding is UTF-8.

   function To_char (Item : Character) return char is
   begin
      return char (Item);
   end To_char;

   function To_Character (Item : char) return Character is
   begin
      return Character (Item);
   end To_Character;

   function Is_Nul_Terminated (Item : char_array) return Boolean
      renames char_Lengths.Is_Nul_Terminated;

   function Length (Item : char_array) return size_t
      renames char_Lengths.Length;

   function To_char_array (
      Item : String;
      Append_Nul : Boolean := True)
      return char_array is
   begin
      if Append_Nul then
         return char_Conv.To_Nul_Terminated (Item);
      else
         return char_Conv.To_Non_Nul_Terminated (Item);
      end if;
   end To_char_array;

   function To_String (
      Item : char_array;
      Trim_Nul : Boolean := True)
      return String is
   begin
      if Trim_Nul then
         return char_Conv.From_Nul_Terminated (Item);
      else
         return char_Conv.From_Non_Nul_Terminated (Item);
      end if;
   end To_String;

   procedure To_char_array (
      Item : String;
      Target : out char_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         char_Conv.To_Nul_Terminated (Item, Target, Count);
      else
         char_Conv.To_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_char_array;

   procedure To_String (
      Item : char_array;
      Target : out String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         char_Conv.From_Nul_Terminated (Item, Target, Count);
      else
         char_Conv.From_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_String;

   --  implementation of Wide Character and Wide String

   --  Wide_Character (UTF-16) from/to wchar_t (UTF-32)

   function To_wchar_t (
      Item : Wide_Character;
      Substitute : wchar_t)
      return wchar_t is
   begin
      if Wide_Character'Pos (Item) in 16#d800# .. 16#dfff# then
         return Substitute;
      else
         return wchar_t'Val (Wide_Character'Pos (Item));
      end if;
   end To_wchar_t;

   function To_wchar_t (
      Item : Wide_Character)
      return wchar_t is
   begin
      return To_wchar_t (Item, Substitute => '?');
   end To_wchar_t;

   function To_Wide_Character (
      Item : wchar_t;
      Substitute : Wide_Character)
      return Wide_Character is
   begin
      if wchar_t'Pos (Item) > 16#ffff# then
         --  a check for detecting illegal sequence are omitted
         return Substitute;
      else
         return Wide_Character'Val (wchar_t'Pos (Item));
      end if;
   end To_Wide_Character;

   function To_Wide_Character (
      Item : wchar_t)
      return Wide_Character is
   begin
      return To_Wide_Character (Item, Substitute => '?');
   end To_Wide_Character;

   function Is_Nul_Terminated (Item : wchar_array) return Boolean
      renames wchar_Lengths.Is_Nul_Terminated;

   function Length (Item : wchar_array) return size_t
      renames wchar_Lengths.Length;

   function To_wchar_array (
      Item : Wide_String;
      Append_Nul : Boolean;
      Substitute : wchar_t)
      return wchar_array
   is
      Result : wchar_array (0 .. Item'Length); -- +1 for nul
      Count : size_t;
   begin
      To_Non_Nul_Terminated (Item, Result, Count, Substitute);
      if Append_Nul then
         Result (Count) := wide_nul;
         Count := Count + 1;
      end if;
      return Result (0 .. Count - 1);
   end To_wchar_array;

   function To_wchar_array (
      Item : Wide_String;
      Append_Nul : Boolean := True)
      return wchar_array is
   begin
      return To_wchar_array (
         Item,
         Append_Nul => Append_Nul,
         Substitute => '?');
   end To_wchar_array;

   function To_Wide_String (
      Item : wchar_array;
      Trim_Nul : Boolean;
      Substitute : Wide_Character)
      return Wide_String
   is
      Item_Length : size_t;
   begin
      if Trim_Nul then
         Item_Length := Length (Item);
      else
         Item_Length := Item'Length;
      end if;
      declare
         Result : Wide_String (
            0 ..
            Natural (Item_Length) * 2 - 1); -- Expanding_From_32_To_16
         Count : Natural;
      begin
         From_Non_Nul_Terminated (
            Item (Item'First .. Item'First + Item_Length - 1),
            Result,
            Count,
            Substitute);
         return Result (0 .. Count - 1);
      end;
   end To_Wide_String;

   function To_Wide_String (
      Item : wchar_array;
      Trim_Nul : Boolean := True)
      return Wide_String is
   begin
      return To_Wide_String (Item, Trim_Nul => Trim_Nul, Substitute => '?');
   end To_Wide_String;

   procedure To_wchar_array (
      Item : Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Append_Nul : Boolean := True;
      Substitute : wchar_t := '?') is
   begin
      To_Non_Nul_Terminated (Item, Target, Count, Substitute);
      if Append_Nul then
         Count := Count + 1;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First + Count - 1) := wide_nul;
      end if;
   end To_wchar_array;

   procedure To_Wide_String (
      Item : wchar_array;
      Target : out Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True;
      Substitute : Wide_Character := '?')
   is
      Item_Last : size_t;
   begin
      if Trim_Nul then
         Item_Last := Item'First + Length (Item) - 1;
      else
         Item_Last := Item'Last;
      end if;
      From_Non_Nul_Terminated (
         Item (Item'First .. Item_Last),
         Target,
         Count,
         Substitute);
   end To_Wide_String;

   --  implementation of Wide Wide Character and Wide Wide String

   --  Wide_Wide_Character (UTF-32) from/to wchar_t (UTF-32)

   function To_wchar_t (Item : Wide_Wide_Character)
      return wchar_t is
   begin
      return wchar_t (Item);
   end To_wchar_t;

   function To_Wide_Wide_Character (Item : wchar_t)
      return Wide_Wide_Character is
   begin
      return Wide_Wide_Character (Item);
   end To_Wide_Wide_Character;

   function To_wchar_array (
      Item : Wide_Wide_String;
      Append_Nul : Boolean := True)
      return wchar_array is
   begin
      if Append_Nul then
         return wchar_Conv.To_Nul_Terminated (Item);
      else
         return wchar_Conv.To_Non_Nul_Terminated (Item);
      end if;
   end To_wchar_array;

   function To_Wide_Wide_String (
      Item : wchar_array;
      Trim_Nul : Boolean := True)
      return Wide_Wide_String is
   begin
      if Trim_Nul then
         return wchar_Conv.From_Nul_Terminated (Item);
      else
         return wchar_Conv.From_Non_Nul_Terminated (Item);
      end if;
   end To_Wide_Wide_String;

   procedure To_wchar_array (
      Item : Wide_Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         wchar_Conv.To_Nul_Terminated (Item, Target, Count);
      else
         wchar_Conv.To_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_wchar_array;

   procedure To_Wide_Wide_String (
      Item : wchar_array;
      Target : out Wide_Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         wchar_Conv.From_Nul_Terminated (Item, Target, Count);
      else
         wchar_Conv.From_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_Wide_Wide_String;

   --  implementation of
   --    ISO/IEC 10646:2003 compatible types defined by ISO/IEC TR 19769:2004.

   --  Wide_Character (UTF-16) from/to char16_t (UTF-16)

   function To_C (Item : Wide_Character) return char16_t is
   begin
      return char16_t (Item);
   end To_C;

   function To_Ada (Item : char16_t) return Wide_Character is
   begin
      return Wide_Character (Item);
   end To_Ada;

   function Is_Nul_Terminated (Item : char16_array) return Boolean
      renames char16_Lengths.Is_Nul_Terminated;

   function Length (Item : char16_array) return size_t
      renames char16_Lengths.Length;

   function To_C (Item : Wide_String; Append_Nul : Boolean := True)
      return char16_array is
   begin
      if Append_Nul then
         return char16_Conv.To_Nul_Terminated (Item);
      else
         return char16_Conv.To_Non_Nul_Terminated (Item);
      end if;
   end To_C;

   function To_Ada (Item : char16_array; Trim_Nul : Boolean := True)
      return Wide_String is
   begin
      if Trim_Nul then
         return char16_Conv.From_Nul_Terminated (Item);
      else
         return char16_Conv.From_Non_Nul_Terminated (Item);
      end if;
   end To_Ada;

   procedure To_C (
      Item : Wide_String;
      Target : out char16_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         char16_Conv.To_Nul_Terminated (Item, Target, Count);
      else
         char16_Conv.To_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_C;

   procedure To_Ada (
      Item : char16_array;
      Target : out Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         char16_Conv.From_Nul_Terminated (Item, Target, Count);
      else
         char16_Conv.From_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_Ada;

   --  Wide_Wide_Character (UTF-32) from/to char32_t (UTF-32)

   function To_C (Item : Wide_Wide_Character) return char32_t is
   begin
      return char32_t (Item);
   end To_C;

   function To_Ada (Item : char32_t) return Wide_Wide_Character is
   begin
      return Wide_Wide_Character (Item);
   end To_Ada;

   function Is_Nul_Terminated (Item : char32_array) return Boolean
      renames char32_Lengths.Is_Nul_Terminated;

   function Length (Item : char32_array) return size_t
      renames char32_Lengths.Length;

   function To_C (Item : Wide_Wide_String; Append_Nul : Boolean := True)
      return char32_array is
   begin
      if Append_Nul then
         return char32_Conv.To_Nul_Terminated (Item);
      else
         return char32_Conv.To_Non_Nul_Terminated (Item);
      end if;
   end To_C;

   function To_Ada (Item : char32_array; Trim_Nul : Boolean := True)
      return Wide_Wide_String is
   begin
      if Trim_Nul then
         return char32_Conv.From_Nul_Terminated (Item);
      else
         return char32_Conv.From_Non_Nul_Terminated (Item);
      end if;
   end To_Ada;

   procedure To_C (
      Item : Wide_Wide_String;
      Target : out char32_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         char32_Conv.To_Nul_Terminated (Item, Target, Count);
      else
         char32_Conv.To_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_C;

   procedure To_Ada (
      Item : char32_array;
      Target : out Wide_Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         char32_Conv.From_Nul_Terminated (Item, Target, Count);
      else
         char32_Conv.From_Non_Nul_Terminated (Item, Target, Count);
      end if;
   end To_Ada;

end Interfaces.C;
