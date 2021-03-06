pragma License (Unrestricted);
--  implementation unit specialized for POSIX (Darwin, FreeBSD, or Linux)
package Interfaces.C.Inside is
   pragma Pure;

   --  Character (UTF-8) from/to char (UTF-8)
   --  In POSIX, other packages (Ada.Command_Line, Ada.Environment_Variables,
   --    Ada.Text_IO, etc) also assume that the system encoding is UTF-8.

   function To_char (
      Item : Character;
      Substitute : char) -- unreferenced
      return char;

   function To_Character (
      Item : char;
      Substitute : Character) -- unreferenced
      return Character;

   procedure To_Non_Nul_Terminated (
      Item : String;
      Target : out char_array;
      Count : out size_t;
      Substitute : char); -- unreferenced

   procedure From_Non_Nul_Terminated (
      Item : char_array;
      Target : out String;
      Count : out Natural;
      Substitute : Character); -- unreferenced

   Expanding_To_char : constant := 1;
   Expanding_To_Character : constant := 1;

   --  Wide_Character (UTF-16) from/to wchar_t (UTF-32)

   function To_wchar_t (
      Item : Wide_Character;
      Substitute : wchar_t)
      return wchar_t;

   function To_Wide_Character (
      Item : wchar_t;
      Substitute : Wide_Character)
      return Wide_Character;

   procedure To_Non_Nul_Terminated (
      Item : Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Substitute : wchar_t);

   procedure From_Non_Nul_Terminated (
      Item : wchar_array;
      Target : out Wide_String;
      Count : out Natural;
      Substitute : Wide_Character);

   Expanding_From_Wide_To_wchar_t : constant := 1; -- Expanding_From_16_To_32
   Expanding_From_wchar_t_To_Wide : constant := 2; -- Expanding_From_32_To_16

   --  Wide_Wide_Character (UTF-32) from/to wchar_t (UTF-32)

   function To_wchar_t (
      Item : Wide_Wide_Character;
      Substitute : wchar_t) -- unreferenced
      return wchar_t;

   function To_Wide_Wide_Character (
      Item : wchar_t;
      Substitute : Wide_Wide_Character) -- unreferenced
      return Wide_Wide_Character;

   procedure To_Non_Nul_Terminated (
      Item : Wide_Wide_String;
      Target : out wchar_array;
      Count : out size_t;
      Substitute : wchar_t); -- unreferenced

   procedure From_Non_Nul_Terminated (
      Item : wchar_array;
      Target : out Wide_Wide_String;
      Count : out Natural;
      Substitute : Wide_Wide_Character); -- unreferenced

   Expanding_From_Wide_Wide_To_wchar_t : constant := 1;
   Expanding_From_wchar_t_To_Wide_Wide : constant := 1;

end Interfaces.C.Inside;
