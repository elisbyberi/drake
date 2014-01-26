pragma License (Unrestricted);
private with Ada.Characters.Inside.Maps;
private with Ada.Characters.Inside.Maps.Case_Folding;
private with Ada.Characters.Inside.Maps.Case_Mapping;
private with Ada.Characters.Inside.Sets;
private with Ada.Characters.Inside.Sets.Constants;
private with Ada.Characters.Inside.Sets.General_Category;
private with Ada.Strings.Maps.Inside;
package Ada.Strings.Wide_Maps.Wide_Constants is
   pragma Preelaborate;

   --  extended
   --  There are sets of unicode category.
   function Unassigned_Set return Wide_Character_Set;
   pragma Inline (Unassigned_Set); -- renamed, the followings are the same
   function Uppercase_Letter_Set return Wide_Character_Set;
   pragma Inline (Uppercase_Letter_Set);
   function Lowercase_Letter_Set return Wide_Character_Set;
   pragma Inline (Lowercase_Letter_Set);
   function Titlecase_Letter_Set return Wide_Character_Set;
   pragma Inline (Titlecase_Letter_Set);
   function Modifier_Letter_Set return Wide_Character_Set;
   pragma Inline (Modifier_Letter_Set);
   function Other_Letter_Set return Wide_Character_Set;
   pragma Inline (Other_Letter_Set);
   function Decimal_Number_Set return Wide_Character_Set;
   pragma Inline (Decimal_Number_Set);
   function Letter_Number_Set return Wide_Character_Set;
   pragma Inline (Letter_Number_Set);
   function Other_Number_Set return Wide_Character_Set;
   pragma Inline (Other_Number_Set);
   function Line_Separator_Set return Wide_Character_Set;
   pragma Inline (Line_Separator_Set);
   function Paragraph_Separator_Set return Wide_Character_Set;
   pragma Inline (Paragraph_Separator_Set);
   function Control_Set return Wide_Character_Set;
   pragma Inline (Control_Set);
   function Format_Set return Wide_Character_Set;
   pragma Inline (Format_Set);
   function Private_Use_Set return Wide_Character_Set;
   pragma Inline (Private_Use_Set);
   function Surrogate_Set return Wide_Character_Set;
   pragma Inline (Surrogate_Set);

--  Control_Set : constant Wide_Character_Set;
   --  (Control_Set is declared as unicode category in above)
--  Graphic_Set : constant Wide_Character_Set;
   function Graphic_Set return Wide_Character_Set;
   pragma Inline (Graphic_Set);
--  Letter_Set : constant Wide_Character_Set;
   function Letter_Set return Wide_Character_Set;
   pragma Inline (Letter_Set);
--  Lower_Set : constant Wide_Character_Set;
   function Lower_Set return Wide_Character_Set
      renames Lowercase_Letter_Set;
   --  (Lower_Set is extended for all unicode characters)
--  Upper_Set : constant Wide_Character_Set;
   function Upper_Set return Wide_Character_Set
      renames Uppercase_Letter_Set;
   --  (Upper_Set is extended for all unicode characters)
--  Basic_Set : constant Wide_Character_Set;
   function Decimal_Digit_Set return Wide_Character_Set;
   pragma Inline (Decimal_Digit_Set);
   function Hexadecimal_Digit_Set return Wide_Character_Set;
   pragma Inline (Hexadecimal_Digit_Set);
   --  (Decimal_Digit_Set, Hexadecimal_Digit_Set are NOT extended, for parsing)
--  Alphanumeric_Set : constant Wide_Character_Set;
   function Alphanumeric_Set return Wide_Character_Set;
   pragma Inline (Alphanumeric_Set);
--  Special_Set : constant Wide_Character_Set;
   function Special_Set return Wide_Character_Set;
   pragma Inline (Special_Set);
--  ISO_646_Set : constant Wide_Character_Set;
   function ISO_646_Set return Wide_Character_Set;
   pragma Inline (ISO_646_Set);

--  Lower_Case_Map : constant Wide_Character_Mapping;
   function Lower_Case_Map return Wide_Character_Mapping;
   pragma Inline (Lower_Case_Map);
   --  Maps to lower case for letters, else identity
   --  (Lower_Case_Map is extended for all unicode characters)
--  Upper_Case_Map : constant Wide_Character_Mapping;
   function Upper_Case_Map return Wide_Character_Mapping;
   pragma Inline (Upper_Case_Map);
   --  Maps to upper case for letters, else identity
   --  (Upper_Case_Map is extended for all unicode characters)
--  Basic_Map : constant Wide_Character_Mapping;
   --  Maps to basic letter for letters, else identity

   --  extended
   function Case_Folding_Map return Wide_Character_Mapping;
   pragma Inline (Case_Folding_Map);

   --  RM A.4.7

--  Character_Set : constant Wide_Maps.Wide_Character_Set;
   function Character_Set return Wide_Character_Set
      renames ISO_646_Set;
   --  Contains each Wide_Character value WC such that
   --  Characters.Conversions.Is_Character(WC) is True

private

   function Unassigned_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.All_Unassigned);
   function Unassigned_Set return Wide_Character_Set
      renames Unassigned_Set_Body;

   function Uppercase_Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Uppercase_Letter);
   function Uppercase_Letter_Set return Wide_Character_Set
      renames Uppercase_Letter_Set_Body;

   function Lowercase_Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Lowercase_Letter);
   function Lowercase_Letter_Set return Wide_Character_Set
      renames Lowercase_Letter_Set_Body;

   function Titlecase_Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Titlecase_Letter);
   function Titlecase_Letter_Set return Wide_Character_Set
      renames Titlecase_Letter_Set_Body;

   function Modifier_Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Modifier_Letter);
   function Modifier_Letter_Set return Wide_Character_Set
      renames Modifier_Letter_Set_Body;

   function Other_Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Other_Letter);
   function Other_Letter_Set return Wide_Character_Set
      renames Other_Letter_Set_Body;

   function Decimal_Number_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Decimal_Number);
   function Decimal_Number_Set return Wide_Character_Set
      renames Decimal_Number_Set_Body;

   function Letter_Number_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Letter_Number);
   function Letter_Number_Set return Wide_Character_Set
      renames Letter_Number_Set_Body;

   function Other_Number_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Other_Number);
   function Other_Number_Set return Wide_Character_Set
      renames Other_Number_Set_Body;

   function Line_Separator_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Line_Separator);
   function Line_Separator_Set return Wide_Character_Set
      renames Line_Separator_Set_Body;

   function Paragraph_Separator_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Paragraph_Separator);
   function Paragraph_Separator_Set return Wide_Character_Set
      renames Paragraph_Separator_Set_Body;

   function Control_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Control);
   function Control_Set return Wide_Character_Set
      renames Control_Set_Body;

   function Format_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Format);
   function Format_Set return Wide_Character_Set
      renames Format_Set_Body;

   function Private_Use_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Private_Use);
   function Private_Use_Set return Wide_Character_Set
      renames Private_Use_Set_Body;

   function Surrogate_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.General_Category.Surrogate);
   function Surrogate_Set return Wide_Character_Set
      renames Surrogate_Set_Body;

   function Graphic_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Graphic_Set);
   function Graphic_Set return Wide_Character_Set
      renames Graphic_Set_Body;

   function Letter_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Letter_Set);
   function Letter_Set return Wide_Character_Set
      renames Letter_Set_Body;

   function Decimal_Digit_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Decimal_Digit_Set);
   function Decimal_Digit_Set return Wide_Character_Set
      renames Decimal_Digit_Set_Body;

   function Hexadecimal_Digit_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Hexadecimal_Digit_Set);
   function Hexadecimal_Digit_Set return Wide_Character_Set
      renames Hexadecimal_Digit_Set_Body;

   function Alphanumeric_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Alphanumeric_Set);
   function Alphanumeric_Set return Wide_Character_Set
      renames Alphanumeric_Set_Body;

   function Special_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.Special_Set);
   function Special_Set return Wide_Character_Set
      renames Special_Set_Body;

   function ISO_646_Set_Body is new Maps.Inside.To_Derived_Set (
      Wide_Character_Set,
      Characters.Inside.Sets.Constants.ISO_646_Set);
   function ISO_646_Set return Wide_Character_Set
      renames ISO_646_Set_Body;

   function Lower_Case_Map_Body is new Maps.Inside.To_Derived_Mapping (
      Wide_Character_Mapping,
      Characters.Inside.Maps.Case_Mapping.Lower_Case_Map);
   function Lower_Case_Map return Wide_Character_Mapping
      renames Lower_Case_Map_Body;

   function Upper_Case_Map_Body is new Maps.Inside.To_Derived_Mapping (
      Wide_Character_Mapping,
      Characters.Inside.Maps.Case_Mapping.Upper_Case_Map);
   function Upper_Case_Map return Wide_Character_Mapping
      renames Upper_Case_Map_Body;

   function Case_Folding_Map_Body is new Maps.Inside.To_Derived_Mapping (
      Wide_Character_Mapping,
      Characters.Inside.Maps.Case_Folding.Case_Folding_Map);
   function Case_Folding_Map return Wide_Character_Mapping
      renames Case_Folding_Map_Body;

end Ada.Strings.Wide_Maps.Wide_Constants;
