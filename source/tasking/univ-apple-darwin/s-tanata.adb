with System.Tasking.Yield;
with C.errno;
with C.signal;
package body System.Tasking.Native_Tasks is
   use type C.signed_int;

   type sigaction_Wrapper is record -- ??? for No_Elaboration_Code
      Handle : aliased C.signal.struct_sigaction;
   end record;
   pragma Suppress_Initialization (sigaction_Wrapper);

   Old_SIGTERM_Action : aliased sigaction_Wrapper; -- uninitialized
   Installed_Abort_Handler : Abort_Handler;

   procedure SIGTERM_Handler (
      Signal_Number : C.signed_int;
      Info : access C.signal.struct_siginfo;
      Context : C.void_ptr);
   pragma Convention (C, SIGTERM_Handler);
   procedure SIGTERM_Handler (
      Signal_Number : C.signed_int;
      Info : access C.signal.struct_siginfo;
      Context : C.void_ptr)
   is
      pragma Unreferenced (Signal_Number);
      pragma Unreferenced (Info);
      pragma Unreferenced (Context);
   begin
      Installed_Abort_Handler.all;
   end SIGTERM_Handler;

   procedure Mask_SIGTERM (How : C.signed_int);
   procedure Mask_SIGTERM (How : C.signed_int) is
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
      Mask : aliased C.signal.sigset_t;
   begin
      Dummy := C.signal.sigemptyset (Mask'Access);
      Dummy := C.signal.sigaddset (Mask'Access, C.signal.SIGTERM);
      Dummy := C.pthread.pthread_sigmask (How, Mask'Access, null);
   end Mask_SIGTERM;

   --  implementation of thread

   procedure Create (
      Handle : not null access Handle_Type;
      Parameter : Parameter_Type;
      Thread_Body : Thread_Body_Type;
      Error : out Boolean) is
   begin
      Error := C.pthread.pthread_create (
         Handle,
         null,
         Thread_Body.all'Access, -- type is different between platforms
         Parameter) /= 0;
   end Create;

   procedure Join (
      Handle : Handle_Type;
      Result : not null access Result_Type;
      Error : out Boolean) is
   begin
      Error := C.pthread.pthread_join (Handle, Result) /= 0;
   end Join;

   procedure Detach (
      Handle : Handle_Type;
      Error : out Boolean) is
   begin
      Error := C.pthread.pthread_detach (Handle) /= 0;
   end Detach;

   --  implementation of signals

   procedure Install_Abort_Handler (Handler : Abort_Handler) is
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
      act : aliased C.signal.struct_sigaction :=
         (others => <>); -- uninitialized
   begin
      Installed_Abort_Handler := Handler;
      act.sigaction_u.sa_sigaction := SIGTERM_Handler'Access;
      act.sa_flags := -- C.signal.SA_NODEFER +
         C.signal.SA_RESTART
         + C.signal.SA_SIGINFO;
      Dummy := C.signal.sigemptyset (act.sa_mask'Access);
      Dummy := C.signal.sigaction (
         C.signal.SIGTERM,
         act'Access,
         Old_SIGTERM_Action.Handle'Access);
   end Install_Abort_Handler;

   procedure Uninstall_Abort_Handler is
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
   begin
      Dummy := C.signal.sigaction (
         C.signal.SIGTERM,
         Old_SIGTERM_Action.Handle'Access,
         null);
   end Uninstall_Abort_Handler;

   procedure Send_Abort_Signal (Handle : Handle_Type; Error : out Boolean) is
   begin
--    pragma Check (Trace, Ada.Debug.Put ("abort " & Name (T)));
      case C.pthread.pthread_kill (Handle, C.signal.SIGTERM) is
         when 0 =>
            Yield;
            Error := False;
         when C.errno.ESRCH =>
--          pragma Assert (Terminated (T));
            Error := False; -- it is already terminated, C9A003A
         when others =>
            Error := True;
      end case;
   end Send_Abort_Signal;

   procedure Block_Abort_Signal is
   begin
      Mask_SIGTERM (C.signal.SIG_BLOCK);
   end Block_Abort_Signal;

   procedure Unblock_Abort_Signal is
   begin
      Mask_SIGTERM (C.signal.SIG_UNBLOCK);
   end Unblock_Abort_Signal;

end System.Tasking.Native_Tasks;
