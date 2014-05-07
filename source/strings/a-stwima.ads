pragma License (Unrestricted);
with Ada.Strings.Maps;
package Ada.Strings.Wide_Maps is
   pragma Preelaborate;

   --  Representation for a set of Wide_Character values:
--  type Wide_Character_Set is private;
   type Wide_Character_Set is new Maps.Character_Set;
   pragma Preelaborable_Initialization (Wide_Character_Set);

--  Null_Set : constant Wide_Character_Set;
   --  function Null_Set is inherited

--  type Wide_Character_Range is record
--    Low : Wide_Character;
--    High : Wide_Character;
--  end record;
   subtype Wide_Character_Range is Maps.Wide_Character_Range;
   --  Represents Wide_Character range Low..High

--  type Wide_Character_Ranges is
--    array (Positive range <>) of Wide_Character_Range;
   subtype Wide_Character_Ranges is Maps.Wide_Character_Ranges;

   function To_Set (Ranges : Wide_Character_Ranges)
      return Wide_Character_Set
      renames Overloaded_To_Set;

   function To_Set (Span : Wide_Character_Range)
      return Wide_Character_Set
      renames Overloaded_To_Set;

   function To_Ranges (Set : Wide_Character_Set) return Wide_Character_Ranges
      renames Overloaded_To_Ranges;

--  function "=" (Left, Right : Wide_Character_Set) return Boolean;
   --  function "=" is inherited

--  function "not" (Right : Wide_Character_Set) return Wide_Character_Set;
--  function "and" (Left, Right : Wide_Character_Set)
--    return Wide_Character_Set;
--  function "or" (Left, Right : Wide_Character_Set) return Wide_Character_Set;
--  function "xor" (Left, Right : Wide_Character_Set)
--    return Wide_Character_Set;
--  function "-" (Left, Right : Wide_Character_Set) return Wide_Character_Set;
   --  "not", "and", "or", "xor" and "-" are inherited

   function Is_In (Element : Wide_Character; Set : Wide_Character_Set)
      return Boolean
      renames Overloaded_Is_In;

--  function Is_Subset (
--    Elements : Wide_Character_Set;
--    Set : Wide_Character_Set)
--    return Boolean;
   --  function Is_Subset is inherited

   function "<=" (Left : Wide_Character_Set; Right : Wide_Character_Set)
      return Boolean
      renames Is_Subset;

   --  Alternative representation for a set of Wide_Character values:
   subtype Wide_Character_Sequence is Wide_String;

   function To_Set (Sequence : Wide_Character_Sequence)
      return Wide_Character_Set
      renames Overloaded_To_Set;

   function To_Set (Singleton : Wide_Character)
      return Wide_Character_Set
      renames Overloaded_To_Set;

   function To_Sequence (Set : Wide_Character_Set)
      return Wide_Character_Sequence
      renames Overloaded_To_Sequence;

   --  hiding
   function To_Set (Ranges : Maps.Character_Ranges)
      return Wide_Character_Set is abstract;
   function To_Set (Span : Maps.Character_Range)
      return Wide_Character_Set is abstract;
   function To_Ranges (Set : Wide_Character_Set)
      return Maps.Character_Ranges is abstract;
   function Is_In (Element : Character; Set : Wide_Character_Set)
      return Boolean is abstract;
   function To_Set (Sequence : Maps.Character_Sequence)
      return Wide_Character_Set is abstract;
   function To_Set (Singleton : Character)
      return Wide_Character_Set is abstract;
   function To_Sequence (Set : Wide_Character_Set)
      return Maps.Character_Sequence is abstract;

   --  Representation for a Wide_Character to Wide_Character mapping:
--  type Wide_Character_Mapping is private;
   type Wide_Character_Mapping is new Maps.Character_Mapping;
   pragma Preelaborable_Initialization (Wide_Character_Mapping);

   function Value (Map : Wide_Character_Mapping; Element : Wide_Character)
      return Wide_Character
      renames Overloaded_Value;

--  Identity : constant Wide_Character_Mapping;
   --  function Identity is inehrited

   function To_Mapping (From, To : Wide_Character_Sequence)
      return Wide_Character_Mapping
      renames Overloaded_To_Mapping;

   function To_Domain (Map : Wide_Character_Mapping)
      return Wide_Character_Sequence
      renames Overloaded_To_Domain;

   function To_Range (Map : Wide_Character_Mapping)
      return Wide_Character_Sequence
      renames Overloaded_To_Range;

   --  hiding
   function Value (Map : Wide_Character_Mapping; Element : Character)
      return Character is abstract;
   function To_Mapping (From, To : Maps.Character_Sequence)
      return Wide_Character_Mapping is abstract;
   function To_Domain (Map : Wide_Character_Mapping)
      return Maps.Character_Sequence is abstract;
   function To_Range (Map : Wide_Character_Mapping)
      return Maps.Character_Sequence is abstract;

   type Wide_Character_Mapping_Function is
      access function (From : Wide_Character) return Wide_Character;

end Ada.Strings.Wide_Maps;
