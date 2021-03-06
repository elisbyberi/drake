pragma License (Unrestricted);
generic
   type Index is (<>);
   type Element is private;
   type Element_Array is array (Index range <>) of aliased Element;
   Default_Terminator : Element;
package Interfaces.C.Pointers is
--  pragma Preelaborate;
   pragma Pure;

   type Pointer is access all Element;
   --  modified
   for Pointer'Storage_Size use 0;
   pragma No_Strict_Aliasing (Pointer);

   --  modified
--  function Value (Ref : Pointer; Terminator : Element := Default_Terminator)
--    return Element_Array;
   function Value (
      Ref : access constant Element; -- CXB3014 requires null
      Terminator : Element := Default_Terminator)
      return Element_Array;

   --  modified
--  function Value (Ref : Pointer; Length : ptrdiff_t)
--    return Element_Array;
   function Value (
      Ref : access constant Element; -- CXB3014 requires null
      Length : ptrdiff_t)
      return Element_Array;

   Pointer_Error : exception
      renames C.Pointer_Error;

   --  C-style Pointer arithmetic

   function "+" (
      Left : Pointer; -- CXB3015 requires null
      Right : ptrdiff_t)
      return not null Pointer;
   pragma Convention (Intrinsic, "+");
   pragma Pure_Function ("+");
   pragma Inline_Always ("+");
   function "+" (
      Left : ptrdiff_t;
      Right : not null Pointer)
      return not null Pointer;
   pragma Convention (Intrinsic, "+");
   pragma Pure_Function ("+");
   pragma Inline_Always ("+");
   function "-" (
      Left : Pointer; -- CXB3015 requires null
      Right : ptrdiff_t)
      return not null Pointer;
   pragma Convention (Intrinsic, "-");
   pragma Pure_Function ("-");
   pragma Inline_Always ("-");
   --  modified
--  function "-" (Left : Pointer; Right : Pointer) return ptrdiff_t;
   function "-" (
      Left : not null Pointer;
      Right : not null access constant Element)
      return ptrdiff_t;
   pragma Convention (Intrinsic, "-");
   pragma Pure_Function ("-");
   pragma Inline_Always ("-");

   procedure Increment (Ref : in out not null Pointer);
   pragma Convention (Intrinsic, Increment);
   pragma Inline_Always (Increment);
   procedure Decrement (Ref : in out Pointer); -- CXB3015 requires null
   pragma Convention (Intrinsic, Decrement);
   pragma Inline_Always (Decrement);

   --  modified
--  function Virtual_Length (
--    Ref : Pointer;
--    Terminator : Element := Default_Terminator)
--    return ptrdiff_t;
   function Virtual_Length (
      Ref : access constant Element; -- CXB3016 requires null
      Terminator : Element := Default_Terminator)
      return ptrdiff_t;

--  procedure Copy_Terminated_Array (
--    Source : Pointer;
--    Target : Pointer;
--    Limit : ptrdiff_t := ptrdiff_t'Last;
--    Terminator : Element := Default_Terminator);
   procedure Copy_Terminated_Array (
      Source : access constant Element; -- CXB3016 requires null
      Target : access Element;
      Limit : ptrdiff_t := ptrdiff_t'Last;
      Terminator : Element := Default_Terminator);

   --  modified
--  procedure Copy_Array (
--    Source : Pointer;
--    Target : Pointer;
--    Length : ptrdiff_t);
   procedure Copy_Array (
      Source : access constant Element; -- CXB3016 requires null
      Target : access Element;
      Length : ptrdiff_t);

   --  extended from here

   type Constant_Pointer is access constant Element;
   for Constant_Pointer'Storage_Size use 0;
   pragma No_Strict_Aliasing (Constant_Pointer);

   function "+" (Left : not null Constant_Pointer; Right : ptrdiff_t)
      return not null Constant_Pointer;
   pragma Convention (Intrinsic, "+");
   pragma Pure_Function ("+");
   pragma Inline_Always ("+");
   function "+" (Left : ptrdiff_t; Right : not null Constant_Pointer)
      return not null Constant_Pointer;
   pragma Convention (Intrinsic, "+");
   pragma Pure_Function ("+");
   pragma Inline_Always ("+");
   function "-" (Left : not null Constant_Pointer; Right : ptrdiff_t)
      return not null Constant_Pointer;
   pragma Convention (Intrinsic, "-");
   pragma Pure_Function ("-");
   pragma Inline_Always ("-");
   function "-" (
      Left : not null Constant_Pointer;
      Right : not null access constant Element)
      return ptrdiff_t;
   pragma Convention (Intrinsic, "-");
   pragma Pure_Function ("-");
   pragma Inline_Always ("-");

   procedure Increment (Ref : in out not null Constant_Pointer);
   pragma Convention (Intrinsic, Increment);
   pragma Inline_Always (Increment);
   procedure Decrement (Ref : in out not null Constant_Pointer);
   pragma Convention (Intrinsic, Decrement);
   pragma Inline_Always (Decrement);

end Interfaces.C.Pointers;
