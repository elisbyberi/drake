pragma License (Unrestricted);
--  runtime unit
package System.Synchronous_Control is
   pragma Preelaborate;

   --  no-operation
   procedure Nop is null;

   --  abortable region control

   type Unlock_Abort_Handler is access procedure;
   pragma Suppress (Access_Check, Unlock_Abort_Handler);

   Unlock_Abort_Hook : not null Unlock_Abort_Handler := Nop'Access;
   pragma Suppress (Access_Check, Unlock_Abort_Hook);

   --  enter abortable region (default is unabortable)
   --  also, implementation of System.Standard_Library.Abort_Undefer_Direct
   procedure Unlock_Abort;
   pragma Export (Ada, Unlock_Abort,
      "system__standard_library__abort_undefer_direct");

   type Lock_Abort_Handler is access procedure;
   pragma Suppress (Access_Check, Lock_Abort_Handler);

   Lock_Abort_Hook : not null Lock_Abort_Handler := Nop'Access;
   pragma Suppress (Access_Check, Lock_Abort_Hook);

   --  leave abortable region
   procedure Lock_Abort;

end System.Synchronous_Control;
