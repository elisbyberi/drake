pragma License (Unrestricted);
--  implementation unit
generic
package Ada.Containers.Ordered_Sets.Debug is
   pragma Preelaborate;

   procedure Dump (Source : Set);

   function Validate (Source : Set) return Boolean;

end Ada.Containers.Ordered_Sets.Debug;
