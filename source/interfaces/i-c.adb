with Ada.Exception_Identification.From_Here;
with Ada.Unchecked_Conversion;
with Interfaces.C.Inside;
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
   package Simple_Conversions is

      pragma Compile_Time_Error (
         String_Type'Component_Size /= Element_Array'Component_Size,
         "size mismatch!");

      procedure To_Non_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t;
         Substitute : Element); -- unreferenced

      procedure From_Non_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural;
         Substitute : Character_Type); -- unreferenced

   end Simple_Conversions;

   package body Simple_Conversions is

      procedure To_Non_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t;
         Substitute : Element)
      is
         pragma Unreferenced (Substitute);
         C_Item : Element_Array (0 .. Item'Length - 1);
         for C_Item'Address use Item'Address;
      begin
         Count := C_Item'Length;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First .. Target'First + C_Item'Length - 1) := C_Item;
      end To_Non_Nul_Terminated;

      procedure From_Non_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural;
         Substitute : Character_Type)
      is
         pragma Unreferenced (Substitute);
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

   generic
      type Character_Type is (<>);
      type String_Type is array (Positive range <>) of Character_Type;
      type Element is (<>);
      type Element_Array is array (size_t range <>) of aliased Element;
      with function Length (Item : Element_Array) return size_t;
      with procedure To_Non_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t;
         Substitute : Element);
      with procedure From_Non_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural;
         Substitute : Character_Type);
      Expanding_To_C : size_t;
      Expanding_To_Ada : size_t;
   package Functions is

      function To_Nul_Terminated (
         Item : String_Type;
         Substitute : Element)
         return Element_Array;
      function To_Non_Nul_Terminated (
         Item : String_Type;
         Substitute : Element)
         return Element_Array;

      function From_Nul_Terminated (
         Item : Element_Array;
         Substitute : Character_Type)
         return String_Type;
      function From_Non_Nul_Terminated (
         Item : Element_Array;
         Substitute : Character_Type)
         return String_Type;

      procedure To_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t;
         Substitute : Element);

      procedure From_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural;
         Substitute : Character_Type);

   end Functions;

   package body Functions is

      function To_Nul_Terminated (
         Item : String_Type;
         Substitute : Element)
         return Element_Array
      is
         Result : Element_Array (
            0 ..
            Expanding_To_C * Item'Length); -- +1 for nul
         Count : size_t;
      begin
         To_Non_Nul_Terminated (Item, Result, Count,
            Substitute => Substitute);
         Result (Count) := Element'Val (0);
         Count := Count + 1;
         return Result (0 .. Count - 1);
      end To_Nul_Terminated;

      function To_Non_Nul_Terminated (
         Item : String_Type;
         Substitute : Element)
         return Element_Array
      is
         Result : Element_Array (
            0 ..
            Expanding_To_C * Item'Length - 1);
         Count : size_t;
      begin
         To_Non_Nul_Terminated (Item, Result, Count,
            Substitute => Substitute);
         return Result (0 .. Count - 1);
      end To_Non_Nul_Terminated;

      function From_Nul_Terminated (
         Item : Element_Array;
         Substitute : Character_Type)
         return String_Type
      is
         Item_Length : constant size_t := Length (Item);
         Result : String_Type (
            1 ..
            Natural (Expanding_To_Ada * Item_Length));
         Count : Natural;
      begin
         From_Non_Nul_Terminated (
            Item (Item'First .. Item'First + Item_Length - 1),
            Result,
            Count,
            Substitute => Substitute);
         return Result (1 .. Count);
      end From_Nul_Terminated;

      function From_Non_Nul_Terminated (
         Item : Element_Array;
         Substitute : Character_Type)
         return String_Type
      is
         Item_Length : constant size_t := Item'Length;
         Result : String_Type (
            1 ..
            Natural (Expanding_To_Ada * Item_Length));
         Count : Natural;
      begin
         From_Non_Nul_Terminated (
            Item,
            Result,
            Count,
            Substitute => Substitute);
         return Result (1 .. Count);
      end From_Non_Nul_Terminated;

      procedure To_Nul_Terminated (
         Item : String_Type;
         Target : out Element_Array;
         Count : out size_t;
         Substitute : Element) is
      begin
         To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
         Count := Count + 1;
         if Count > Target'Length then
            raise Constraint_Error;
         end if;
         Target (Target'First + Count - 1) := Element'Val (0);
      end To_Nul_Terminated;

      procedure From_Nul_Terminated (
         Item : Element_Array;
         Target : out String_Type;
         Count : out Natural;
         Substitute : Character_Type)
      is
         Item_Length : constant size_t := Length (Item);
      begin
         From_Non_Nul_Terminated (
            Item (Item'First .. Item'First + Item_Length - 1),
            Target,
            Count,
            Substitute => Substitute);
      end From_Nul_Terminated;

   end Functions;

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

   package char_Func is
      new Functions (
         Character,
         String,
         char,
         char_array,
         char_Lengths.Length,
         Inside.To_Non_Nul_Terminated,
         Inside.From_Non_Nul_Terminated,
         Expanding_To_C => Inside.Expanding_To_char,
         Expanding_To_Ada => Inside.Expanding_To_Character);

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

   package wchar_Wide_Func is
      new Functions (
         Wide_Character,
         Wide_String,
         wchar_t,
         wchar_array,
         wchar_Lengths.Length,
         Inside.To_Non_Nul_Terminated,
         Inside.From_Non_Nul_Terminated,
         Expanding_To_C => Inside.Expanding_From_Wide_To_wchar_t,
         Expanding_To_Ada => Inside.Expanding_From_wchar_t_To_Wide);

   package wchar_Wide_Wide_Func is
      new Functions (
         Wide_Wide_Character,
         Wide_Wide_String,
         wchar_t,
         wchar_array,
         wchar_Lengths.Length,
         Inside.To_Non_Nul_Terminated,
         Inside.From_Non_Nul_Terminated,
         Expanding_To_C => Inside.Expanding_From_Wide_Wide_To_wchar_t,
         Expanding_To_Ada => Inside.Expanding_From_wchar_t_To_Wide_Wide);

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
         char16_array);

   package char16_Func is
      new Functions (
         Wide_Character,
         Wide_String,
         char16_t,
         char16_array,
         char16_Lengths.Length,
         char16_Conv.To_Non_Nul_Terminated,
         char16_Conv.From_Non_Nul_Terminated,
         Expanding_To_C => 1,
         Expanding_To_Ada => 1);

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
         char32_array);

   package char32_Func is
      new Functions (
         Wide_Wide_Character,
         Wide_Wide_String,
         char32_t,
         char32_array,
         char32_Lengths.Length,
         char32_Conv.To_Non_Nul_Terminated,
         char32_Conv.From_Non_Nul_Terminated,
         Expanding_To_C => 1,
         Expanding_To_Ada => 1);

   --  implementation of Characters and Strings

   function To_char (
      Item : Character;
      Substitute : char)
      return char
      renames Inside.To_char;

   function To_char (
      Item : Character)
      return char is
   begin
      return To_char (Item, Substitute => '?');
   end To_char;

   function To_Character (
      Item : char;
      Substitute : Character)
      return Character
      renames Inside.To_Character;

   function To_Character (
      Item : char)
      return Character is
   begin
      return To_Character (Item, Substitute => '?');
   end To_Character;

   function Is_Nul_Terminated (Item : char_array) return Boolean
      renames char_Lengths.Is_Nul_Terminated;

   function Length (Item : char_array) return size_t
      renames char_Lengths.Length;

   function To_char_array (
      Item : String;
      Append_Nul : Boolean := True;
      Substitute : char := '?')
      return char_array is
   begin
      if Append_Nul then
         return char_Func.To_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return char_Func.To_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_char_array;

   function To_String (
      Item : char_array;
      Trim_Nul : Boolean := True;
      Substitute : Character := '?')
      return String is
   begin
      if Trim_Nul then
         return char_Func.From_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return char_Func.From_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_String;

   procedure To_char_array (
      Item : String;
      Target : out char_array;
      Count : out size_t;
      Append_Nul : Boolean := True;
      Substitute : char := '?') is
   begin
      if Append_Nul then
         char_Func.To_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      end if;
   end To_char_array;

   procedure To_String (
      Item : char_array;
      Target : out String;
      Count : out Natural;
      Trim_Nul : Boolean := True;
      Substitute : Character := '?') is
   begin
      if Trim_Nul then
         char_Func.From_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.From_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      end if;
   end To_String;

   --  implementation of Wide Character and Wide String

   function To_wchar_t (
      Item : Wide_Character;
      Substitute : wchar_t)
      return wchar_t
      renames Inside.To_wchar_t;

   function To_wchar_t (
      Item : Wide_Character)
      return wchar_t is
   begin
      return To_wchar_t (Item, Substitute => Wide_Character'Pos ('?'));
   end To_wchar_t;

   function To_Wide_Character (
      Item : wchar_t;
      Substitute : Wide_Character)
      return Wide_Character
      renames Inside.To_Wide_Character;

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
      Append_Nul : Boolean := True;
      Substitute : wchar_t := Wide_Character'Pos ('?'))
      return wchar_array is
   begin
      if Append_Nul then
         return wchar_Wide_Func.To_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return wchar_Wide_Func.To_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_wchar_array;

   function To_Wide_String (
      Item : wchar_array;
      Trim_Nul : Boolean := True;
      Substitute : Wide_Character := '?')
      return Wide_String is
   begin
      if Trim_Nul then
         return wchar_Wide_Func.From_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return wchar_Wide_Func.From_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_Wide_String;

   procedure To_wchar_array (
      Item : Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Append_Nul : Boolean := True;
      Substitute : wchar_t := Wide_Character'Pos ('?')) is
   begin
      if Append_Nul then
         wchar_Wide_Func.To_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      end if;
   end To_wchar_array;

   procedure To_Wide_String (
      Item : wchar_array;
      Target : out Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True;
      Substitute : Wide_Character := '?') is
   begin
      if Trim_Nul then
         wchar_Wide_Func.From_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.From_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      end if;
   end To_Wide_String;

   --  implementation of Wide Wide Character and Wide Wide String

   function To_wchar_t (
      Item : Wide_Wide_Character;
      Substitute : wchar_t := Wide_Wide_Character'Pos ('?'))
      return wchar_t
      renames Inside.To_wchar_t;

   function To_Wide_Wide_Character (
      Item : wchar_t;
      Substitute : Wide_Wide_Character := '?')
      return Wide_Wide_Character
      renames Inside.To_Wide_Wide_Character;

   function To_wchar_array (
      Item : Wide_Wide_String;
      Append_Nul : Boolean := True;
      Substitute : wchar_t := Wide_Wide_Character'Pos ('?'))
      return wchar_array is
   begin
      if Append_Nul then
         return wchar_Wide_Wide_Func.To_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return wchar_Wide_Wide_Func.To_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_wchar_array;

   function To_Wide_Wide_String (
      Item : wchar_array;
      Trim_Nul : Boolean := True;
      Substitute : Wide_Wide_Character := '?')
      return Wide_Wide_String is
   begin
      if Trim_Nul then
         return wchar_Wide_Wide_Func.From_Nul_Terminated (Item,
            Substitute => Substitute);
      else
         return wchar_Wide_Wide_Func.From_Non_Nul_Terminated (Item,
            Substitute => Substitute);
      end if;
   end To_Wide_Wide_String;

   procedure To_wchar_array (
      Item : Wide_Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Append_Nul : Boolean := True;
      Substitute : wchar_t := Wide_Wide_Character'Pos ('?')) is
   begin
      if Append_Nul then
         wchar_Wide_Wide_Func.To_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      end if;
   end To_wchar_array;

   procedure To_Wide_Wide_String (
      Item : wchar_array;
      Target : out Wide_Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True;
      Substitute : Wide_Wide_Character := '?') is
   begin
      if Trim_Nul then
         wchar_Wide_Wide_Func.From_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
      else
         Inside.From_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Substitute);
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
         return char16_Func.To_Nul_Terminated (Item,
            Substitute => char16_nul);
      else
         return char16_Func.To_Non_Nul_Terminated (Item,
            Substitute => char16_nul);
      end if;
   end To_C;

   function To_Ada (Item : char16_array; Trim_Nul : Boolean := True)
      return Wide_String is
   begin
      if Trim_Nul then
         return char16_Func.From_Nul_Terminated (Item,
            Substitute => Wide_Character'Val (0));
      else
         return char16_Func.From_Non_Nul_Terminated (Item,
            Substitute => Wide_Character'Val (0));
      end if;
   end To_Ada;

   procedure To_C (
      Item : Wide_String;
      Target : out char16_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         char16_Func.To_Nul_Terminated (Item, Target, Count,
            Substitute => char16_nul);
      else
         char16_Conv.To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => char16_nul);
      end if;
   end To_C;

   procedure To_Ada (
      Item : char16_array;
      Target : out Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         char16_Func.From_Nul_Terminated (Item, Target, Count,
            Substitute => Wide_Character'Val (0));
      else
         char16_Conv.From_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Wide_Character'Val (0));
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
         return char32_Func.To_Nul_Terminated (Item,
            Substitute => char32_nul);
      else
         return char32_Func.To_Non_Nul_Terminated (Item,
            Substitute => char32_nul);
      end if;
   end To_C;

   function To_Ada (Item : char32_array; Trim_Nul : Boolean := True)
      return Wide_Wide_String is
   begin
      if Trim_Nul then
         return char32_Func.From_Nul_Terminated (Item,
            Substitute => Wide_Wide_Character'Val (0));
      else
         return char32_Func.From_Non_Nul_Terminated (Item,
            Substitute => Wide_Wide_Character'Val (0));
      end if;
   end To_Ada;

   procedure To_C (
      Item : Wide_Wide_String;
      Target : out char32_array;
      Count : out size_t;
      Append_Nul : Boolean := True) is
   begin
      if Append_Nul then
         char32_Func.To_Nul_Terminated (Item, Target, Count,
            Substitute => char32_nul);
      else
         char32_Conv.To_Non_Nul_Terminated (Item, Target, Count,
            Substitute => char32_nul);
      end if;
   end To_C;

   procedure To_Ada (
      Item : char32_array;
      Target : out Wide_Wide_String;
      Count : out Natural;
      Trim_Nul : Boolean := True) is
   begin
      if Trim_Nul then
         char32_Func.From_Nul_Terminated (Item, Target, Count,
            Substitute => Wide_Wide_Character'Val (0));
      else
         char32_Conv.From_Non_Nul_Terminated (Item, Target, Count,
            Substitute => Wide_Wide_Character'Val (0));
      end if;
   end To_Ada;

end Interfaces.C;
