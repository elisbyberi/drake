with Ada.Unchecked_Conversion;
with C.winnt;
package body System.Native_Stack is
   pragma Suppress (All_Checks);

   procedure Get (Top, Bottom : out Address) is
      function Cast is new
         Ada.Unchecked_Conversion (C.winnt.PVOID, System.Address);
      function Cast is new
         Ada.Unchecked_Conversion (C.winnt.struct_TEB_ptr, C.winnt.NT_TIB_ptr);
      TEB : constant C.winnt.struct_TEB_ptr := C.winnt.NtCurrentTeb;
      TIB : constant C.winnt.NT_TIB_ptr := Cast (TEB);
   begin
      Top := Cast (TIB.StackLimit);
      Bottom := Cast (TIB.StackBase);
   end Get;

end System.Native_Stack;