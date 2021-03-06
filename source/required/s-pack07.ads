pragma License (Unrestricted);
--  implementation unit required by compiler
with System.Packed_Arrays;
package System.Pack_07 is
   pragma Pure;

   type Bits_07 is mod 2 ** 7;
   for Bits_07'Size use 7;

   package Indexing is new Packed_Arrays.Indexing (Bits_07);

   --  required for accessing arrays by compiler
   function Get_07 (Arr : Address; N : Natural) return Bits_07
      renames Indexing.Get;
   procedure Set_07 (Arr : Address; N : Natural; E : Bits_07)
      renames Indexing.Set;

end System.Pack_07;
