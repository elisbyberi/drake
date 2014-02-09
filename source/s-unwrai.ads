pragma License (Unrestricted);
--  runtime unit
with Ada;
package System.Unwind.Raising is
   pragma Preelaborate;

   --  (s-stalib.ads)
   Local_Partition_ID : Natural := 0;

   --  equivalent to Raise_With_Location_And_Msg (a-except-2005.adb)
   procedure Raise_Exception (
      E : not null Exception_Data_Access;
      File : String := "";
      Line : Integer := 0;
      Column : Integer := 0;
      Message : String := "";
      Stack_Guard : Address := Null_Address);
   pragma No_Return (Raise_Exception);

   --  equivalent to Raise_From_Signal_Handler (a-except-2005.adb)
   procedure Raise_From_Signal_Handler (
      E : not null Exception_Data_Access;
      File : String := "";
      Line : Integer := 0;
      Column : Integer := 0;
      Message : String;
      Stack_Guard : Address)
      renames Raise_Exception;

   --  implementation for raising (a-except-2005.adb)
   procedure Raise_E (
      E : Exception_Data_Access;
      Message : String);
   pragma No_Return (Raise_E);
   pragma Export (Ada, Raise_E, "ada__exceptions__raise_exception");

   procedure Raise_Exception_From_Here (
      E : not null Exception_Data_Access;
      File : String := Ada.Debug.File;
      Line : Integer := Ada.Debug.Line);
   pragma No_Return (Raise_Exception_From_Here);
   pragma Export (Ada, Raise_Exception_From_Here,
      "__drake_raise_exception_from_here");

   procedure Raise_Exception_From_Here_With (
      E : not null Exception_Data_Access;
      File : String := Ada.Debug.File;
      Line : Integer := Ada.Debug.Line;
      Message : String);
   pragma No_Return (Raise_Exception_From_Here_With);
   pragma Export (Ada, Raise_Exception_From_Here_With,
      "__drake_raise_exception_from_here_with");

   --  implementation for reraising (a-except-2005.adb)
   procedure Reraise (X : Exception_Occurrence);
   pragma No_Return (Reraise);
   pragma Export (Ada, Reraise, "ada__exceptions__reraise_occurrence_always");

   --  implementation for reraising from when all others (a-except-2005.adb)
   procedure Reraise_From_All_Others (X : Exception_Occurrence);
   pragma No_Return (Reraise_From_All_Others);
   pragma Export (Ada, Reraise_From_All_Others,
      "ada__exceptions__reraise_occurrence_no_defer");

   --  implementation for raising from controlled objects (a-except-2005.adb)
   procedure Reraise_From_Controlled_Operation (X : Exception_Occurrence);
   pragma No_Return (Reraise_From_Controlled_Operation);
   pragma Export (Ada, Reraise_From_Controlled_Operation,
      "__gnat_raise_from_controlled_operation");

   --  utility for implementing a dummy subprogram
   procedure Raise_Program_Error;
   pragma Export (Ada, Raise_Program_Error, "__drake_program_error");

   --  shortcut required by compiler (a-except-2005.adb)

   procedure rcheck_00 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_00);
   pragma Export (C, rcheck_00, "__gnat_rcheck_00");

   procedure rcheck_02 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_02);
   pragma Export (C, rcheck_02, "__gnat_rcheck_02");

   procedure rcheck_03 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_03);
   pragma Export (C, rcheck_03, "__gnat_rcheck_03");

   --  equivalent to rcheck_03
   procedure Zero_Division (
      File : String := Ada.Debug.File;
      Line : Integer := Ada.Debug.Line);
   pragma No_Return (Zero_Division);

   procedure rcheck_04 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_04);
   pragma Export (C, rcheck_04, "__gnat_rcheck_04");

   procedure rcheck_05 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_05);
   pragma Export (C, rcheck_05, "__gnat_rcheck_05");

   procedure rcheck_06 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_06);
   pragma Export (C, rcheck_06, "__gnat_rcheck_06");

   procedure rcheck_07 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_07);
   pragma Export (C, rcheck_07, "__gnat_rcheck_07");

   procedure rcheck_09 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_09);
   pragma Export (C, rcheck_09, "__gnat_rcheck_09");

   procedure rcheck_10 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_10);
   pragma Export (C, rcheck_10, "__gnat_rcheck_10");

   --  equivalent to rcheck_10
   procedure Overflow (
      File : String := Ada.Debug.File;
      Line : Integer := Ada.Debug.Line);
   pragma No_Return (Overflow);

   procedure rcheck_12 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_12);
   pragma Export (C, rcheck_12, "__gnat_rcheck_12");

   procedure rcheck_13 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_13);
   pragma Export (C, rcheck_13, "__gnat_rcheck_13");

   procedure rcheck_14 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_14);
   pragma Export (C, rcheck_14, "__gnat_rcheck_14");

   procedure rcheck_15 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_15);
   pragma Export (C, rcheck_15, "__gnat_rcheck_15");

   procedure rcheck_21 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_21);
   pragma Export (C, rcheck_21, "__gnat_rcheck_21");

   procedure rcheck_22 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_22);
   pragma Export (C, rcheck_22, "__gnat_rcheck_22");

   procedure rcheck_23 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_23);
   pragma Export (C, rcheck_23, "__gnat_rcheck_23");

   procedure rcheck_24 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_24);
   pragma Export (C, rcheck_24, "__gnat_rcheck_24");

   procedure rcheck_25 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_25);
   pragma Export (C, rcheck_25, "__gnat_rcheck_25");

   procedure rcheck_26 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_26);
   pragma Export (C, rcheck_26, "__gnat_rcheck_26");

   procedure rcheck_29 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_29);
   pragma Export (C, rcheck_29, "__gnat_rcheck_29");

   procedure rcheck_31 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_31);
   pragma Export (C, rcheck_31, "__gnat_rcheck_31");

   procedure rcheck_32 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_32);
   pragma Export (C, rcheck_32, "__gnat_rcheck_32");

   procedure rcheck_34 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_34);
   pragma Export (C, rcheck_34, "__gnat_rcheck_34");

   --  excluding code range
   function AAA return Address;
   function ZZZ return Address;

   --  implementation for tasking (a-except-2005.adb)
   function Triggered_By_Abort return Boolean;
   pragma Export (Ada, Triggered_By_Abort,
      "ada__exceptions__triggered_by_abort");

   --  gdb knows below names for "catch exception" command
   --  but, if those symbols are existing, gdb may report another error.
   --  this is not a problem of drake,
   --  same report may be also seen with original GNAT runtime in gcc-4.7.
   --  after all, this command only works completely with debug info
   --    generated by custom version gcc in GNAT-GPL.
--  procedure __gnat_debug_raise_exception (E : Exception_Data_Ptr);
--  procedure __gnat_unhandled_exception (E : Exception_Data_Ptr);
--  procedure __gnat_debug_raise_assert_failure;
--  procedure __gnat_raise_nodefer_with_msg (E : Exception_Data_Ptr);

end System.Unwind.Raising;
