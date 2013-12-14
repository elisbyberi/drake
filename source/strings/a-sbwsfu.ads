pragma License (Unrestricted);
--  extended unit
with Ada.Strings.Wide_Functions;
package Ada.Strings.Bounded_Wide_Strings.Functions is new Generic_Functions (
   Space => Wide_Space,
   Fixed_Index_From => Wide_Functions.Index,
   Fixed_Index => Wide_Functions.Index,
   Fixed_Index_Non_Blank_From => Wide_Functions.Index_Non_Blank,
   Fixed_Index_Non_Blank => Wide_Functions.Index_Non_Blank,
   Fixed_Count => Wide_Functions.Count,
   Fixed_Replace_Slice => Wide_Functions.Replace_Slice,
   Fixed_Insert => Wide_Functions.Insert,
   Fixed_Overwrite => Wide_Functions.Overwrite,
   Fixed_Delete => Wide_Functions.Delete,
   Fixed_Trim => Wide_Functions.Trim,
   Fixed_Head => Wide_Functions.Head,
   Fixed_Tail => Wide_Functions.Tail);
pragma Preelaborate (Ada.Strings.Bounded_Wide_Strings.Functions);
