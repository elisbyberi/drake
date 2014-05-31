pragma Check_Policy (Trace, Off);
with Ada.Unchecked_Conversion;
with System.Address_To_Named_Access_Conversions;
with System.Unwind.Handling;
with System.Unwind.Mapping;
with C.unwind;
separate (System.Unwind.Raising)
package body Separated is
   pragma Suppress (All_Checks);
   use type Handling.GNAT_GCC_Exception_Access;
   use type C.signed_int;
   use type C.unsigned_int; -- Unwind_Ptr (32bit)
   use type C.unsigned_long; -- Unwind_Ptr and Unwind_Exception_Class (64bit)
   use type C.unsigned_long_long; -- Unwind_Exception_Class (32bit)

   Foreign_Exception : aliased Exception_Data;
   pragma Import (Ada, Foreign_Exception,
      "system__exceptions__foreign_exception");

   function To_GNAT is
      new Ada.Unchecked_Conversion (
         C.unwind.struct_Unwind_Exception_ptr,
         Handling.GNAT_GCC_Exception_Access);

   --  (a-exexpr-gcc.adb)
   procedure Set_Foreign_Occurrence (
      Current : not null Exception_Occurrence_Access;
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access);

   --  set current occurrence or Foreign_Exception (a-exexpr-gcc.adb)
   procedure Setup_Current_Excep (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access;
      Current : out Exception_Occurrence_Access);

   --  SEH only, equivalent to
   --    Create_Machine_Occurrence_From_Signal_Handler (a-except-2005.adb)
   function New_Machine_Occurrence (
      E : Exception_Data_Access;
      Message : String;
      Stack_Guard : Address)
      return Handling.GNAT_GCC_Exception_Access;
   pragma Export (Ada, New_Machine_Occurrence,
      "__drake_new_machine_occurrence");

   --  hook for entering an exception handler (a-exexpr-gcc.adb)
   procedure Begin_Handler (
      GCC_Exception : Handling.GNAT_GCC_Exception_Access);
   pragma Export (C, Begin_Handler, "__gnat_begin_handler");

   --  hook for leaving an exception handler (a-exexpr-gcc.adb)
   procedure End_Handler (
      GCC_Exception : Handling.GNAT_GCC_Exception_Access);
   pragma Export (C, End_Handler, "__gnat_end_handler");

   --  (a-exexpr-gcc.adb)
   function CleanupUnwind_Handler (
      ABI_Version : C.signed_int;
      Phases : C.unwind.Unwind_Action;
      Exception_Class : C.unwind.Unwind_Exception_Class;
      Exception_Object : access C.unwind.struct_Unwind_Exception;
      Context : access C.unwind.struct_Unwind_Context;
      Argument : C.void_ptr)
      return C.unwind.Unwind_Reason_Code;
   pragma Convention (C, CleanupUnwind_Handler);

   --  (a-exexpr-gcc.adb)
   procedure GNAT_GCC_Exception_Cleanup (
      Reason : C.unwind.Unwind_Reason_Code;
      Exception_Object : access C.unwind.struct_Unwind_Exception);
   pragma Convention (C, GNAT_GCC_Exception_Cleanup);

   --  (a-exexpr-gcc.adb)
   procedure Propagate_GCC_Exception (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access);
   pragma No_Return (Propagate_GCC_Exception);

   --  (a-exexpr-gcc.adb)
   procedure Reraise_GCC_Exception (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access);
   pragma Export (C, Reraise_GCC_Exception, "__gnat_reraise_zcx");

   --  SEH only (a-exexpr-gcc.adb)
   procedure Unhandled_Except_Handler (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access);
   pragma No_Return (Unhandled_Except_Handler);
   pragma Export (C, Unhandled_Except_Handler,
      "__gnat_unhandled_except_handler");

   --  when E : others (a-exexpr-gcc.adb)
   procedure Set_Exception_Parameter (
      Current : not null Exception_Occurrence_Access;
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access);
   pragma Export (C, Set_Exception_Parameter,
      "__gnat_set_exception_parameter");

   --  implementation

   procedure Set_Foreign_Occurrence (
      Current : not null Exception_Occurrence_Access;
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access)
   is
      package GGEA_Conv is
         new Address_To_Named_Access_Conversions (
            Handling.GNAT_GCC_Exception,
            Handling.GNAT_GCC_Exception_Access);
   begin
      Current.Id := Foreign_Exception'Access;
      Current.Machine_Occurrence := GGEA_Conv.To_Address (GCC_Exception);
      Current.Msg_Length := 0;
      Current.Exception_Raised := True;
      Current.Pid := Local_Partition_ID;
      Current.Num_Tracebacks := 0;
   end Set_Foreign_Occurrence;

   procedure Setup_Current_Excep (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access;
      Current : out Exception_Occurrence_Access)
   is
      TLS : constant not null Runtime_Context.Task_Local_Storage_Access :=
         Runtime_Context.Get_Task_Local_Storage;
   begin
      Current := TLS.Current_Exception'Access;
      if GCC_Exception.Header.exception_class =
         Handling.GNAT_Exception_Class
      then
         Current.all := GCC_Exception.Occurrence;
      else
         Set_Foreign_Occurrence (Current, GCC_Exception);
      end if;
   end Setup_Current_Excep;

   function New_Machine_Occurrence (
      E : Exception_Data_Access;
      Message : String;
      Stack_Guard : Address)
      return Handling.GNAT_GCC_Exception_Access
   is
      GCC_Exception : Handling.GNAT_GCC_Exception_Access;
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      GCC_Exception := new Handling.GNAT_GCC_Exception'(
         Header => (
            exception_class => Handling.GNAT_Exception_Class,
            exception_cleanup => GNAT_GCC_Exception_Cleanup'Access,
            F_private => (others => 0)),
         Occurrence => <>,
         Stack_Guard => Stack_Guard,
         landing_pad => <>,
         ttype_filter => <>);
      Set_Exception_Message (
         Id => E,
         File => "",
         Line => 0,
         Column => 0,
         Message => Message,
         X => GCC_Exception.Occurrence);
      if Call_Chain'Address /= Null_Address then
         Call_Chain (GCC_Exception.Occurrence'Access);
         declare
            function Report return Boolean;
            function Report return Boolean is
            begin
               Report_Traceback (GCC_Exception.Occurrence);
               return True;
            end Report;
         begin
            pragma Check (Trace, Ada.Debug.Put ("info..."));
            pragma Check (Trace, Report);
         end;
      end if;
      pragma Check (Trace, Ada.Debug.Put ("leave"));
      return GCC_Exception;
   end New_Machine_Occurrence;

   procedure Begin_Handler (
      GCC_Exception : Handling.GNAT_GCC_Exception_Access)
   is
      Current : Exception_Occurrence_Access;
      pragma Unreferenced (Current);
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      Setup_Current_Excep (GCC_Exception, Current);
      pragma Check (Trace, Ada.Debug.Put ("leave"));
   end Begin_Handler;

   procedure End_Handler (
      GCC_Exception : Handling.GNAT_GCC_Exception_Access) is
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      if GCC_Exception = null then
         pragma Check (Trace, Ada.Debug.Put (
            "GCC_Exception = null, reraised"));
         null;
      else
         C.unwind.Unwind_DeleteException (GCC_Exception.Header'Access);
         --  in Win32 SEH, the chain may be rollback, so restore it
         Mapping.Reinstall_Exception_Handler;
      end if;
      pragma Check (Trace, Ada.Debug.Put ("leave"));
   end End_Handler;

   function CleanupUnwind_Handler (
      ABI_Version : C.signed_int;
      Phases : C.unwind.Unwind_Action;
      Exception_Class : C.unwind.Unwind_Exception_Class;
      Exception_Object : access C.unwind.struct_Unwind_Exception;
      Context : access C.unwind.struct_Unwind_Context;
      Argument : C.void_ptr)
      return C.unwind.Unwind_Reason_Code
   is
      pragma Unreferenced (ABI_Version);
      pragma Unreferenced (Exception_Class);
      pragma Unreferenced (Context);
      pragma Unreferenced (Argument);
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      if Phases >= C.unwind.UA_END_OF_STACK then
         Unhandled_Except_Handler (To_GNAT (Exception_Object));
      end if;
      pragma Check (Trace, Ada.Debug.Put ("leave"));
      return C.unwind.URC_NO_REASON;
   end CleanupUnwind_Handler;

   procedure GNAT_GCC_Exception_Cleanup (
      Reason : C.unwind.Unwind_Reason_Code;
      Exception_Object : access C.unwind.struct_Unwind_Exception)
   is
      pragma Unreferenced (Reason);
      Copy : Handling.GNAT_GCC_Exception_Access := To_GNAT (Exception_Object);
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      Handling.Free (Copy);
      pragma Check (Trace, Ada.Debug.Put ("leave"));
   end GNAT_GCC_Exception_Cleanup;

   --  (a-exexpr-gcc.adb)
   procedure Propagate_Exception (
      X : Exception_Occurrence;
      Stack_Guard : Address)
   is
      GCC_Exception : Handling.GNAT_GCC_Exception_Access;
   begin
      GCC_Exception := new Handling.GNAT_GCC_Exception'(
         Header => (
            exception_class => Handling.GNAT_Exception_Class,
            exception_cleanup => GNAT_GCC_Exception_Cleanup'Access,
            F_private => (others => 0)),
         Occurrence => X,
         Stack_Guard => Stack_Guard,
         landing_pad => <>,
         ttype_filter => <>);
      if Call_Chain'Address /= Null_Address then
         Call_Chain (GCC_Exception.Occurrence'Access);
         declare
            function Report return Boolean;
            function Report return Boolean is
            begin
               Report_Traceback (GCC_Exception.Occurrence);
               return True;
            end Report;
         begin
            pragma Check (Trace, Ada.Debug.Put ("raising..."));
            pragma Check (Trace, Report);
         end;
      end if;
      Propagate_GCC_Exception (GCC_Exception);
   end Propagate_Exception;

   procedure Propagate_GCC_Exception (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access)
   is
      Dummy : C.unwind.Unwind_Reason_Code;
      pragma Unreferenced (Dummy);
   begin
      pragma Check (Trace, Ada.Debug.Put ("Unwind_RaiseException"));
      Dummy := C.unwind.Unwind_RaiseException (GCC_Exception.Header'Access);
      --  in GNAT runtime, calling Notify_Unhandled_Exception here
      pragma Check (Trace, Ada.Debug.Put ("Unwind_ForcedUnwind"));
      Dummy := C.unwind.Unwind_ForcedUnwind (
         GCC_Exception.Header'Access,
         CleanupUnwind_Handler'Access,
         C.void_ptr (Null_Address));
      pragma Check (Trace, Ada.Debug.Put ("unhandled"));
      Unhandled_Except_Handler (GCC_Exception);
   end Propagate_GCC_Exception;

   procedure Reraise_GCC_Exception (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access) is
   begin
      Propagate_GCC_Exception (GCC_Exception);
   end Reraise_GCC_Exception;

   procedure Unhandled_Except_Handler (
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access)
   is
      Current : Exception_Occurrence_Access;
   begin
      pragma Check (Trace, Ada.Debug.Put ("enter"));
      Setup_Current_Excep (GCC_Exception, Current);
      Unhandled_Exception_Terminate (Current);
   end Unhandled_Except_Handler;

   procedure Set_Exception_Parameter (
      Current : not null Exception_Occurrence_Access;
      GCC_Exception : not null Handling.GNAT_GCC_Exception_Access) is
   begin
      if GCC_Exception.Header.exception_class =
         Handling.GNAT_Exception_Class
      then
         Save_Occurrence (Current.all, GCC_Exception.Occurrence);
      else
         Set_Foreign_Occurrence (Current, GCC_Exception);
      end if;
   end Set_Exception_Parameter;

end Separated;
