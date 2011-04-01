pragma License (Unrestricted);
--  extended package
with Ada.Strings.Functions;
package Ada.Strings.Unbounded_Strings.Functions is new Generic_Functions (
   Space => Space,
   Fixed_Index_From => Strings.Functions.Index,
   Fixed_Index => Strings.Functions.Index,
   Fixed_Index_Non_Blank_From => Strings.Functions.Index_Non_Blank,
   Fixed_Index_Non_Blank => Strings.Functions.Index_Non_Blank,
   Fixed_Count => Strings.Functions.Count,
   Fixed_Replace_Slice => Strings.Functions.Replace_Slice,
   Fixed_Insert => Strings.Functions.Insert,
   Fixed_Overwrite => Strings.Functions.Overwrite,
   Fixed_Delete => Strings.Functions.Delete,
   Fixed_Trim => Strings.Functions.Trim,
   Fixed_Head => Strings.Functions.Head,
   Fixed_Tail => Strings.Functions.Tail);
pragma Preelaborate (Ada.Strings.Unbounded_Strings.Functions);