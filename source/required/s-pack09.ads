pragma License (Unrestricted);
--  implementation unit required by compiler
with System.Packed_Arrays;
package System.Pack_09 is
   pragma Pure;

   type Bits_09 is mod 2 ** 9;
   for Bits_09'Size use 9;

   package Indexing is new Packed_Arrays.Indexing (Bits_09);

   --  required for accessing arrays by compiler
   function Get_09 (Arr : Address; N : Natural) return Bits_09
      renames Indexing.Get;
   procedure Set_09 (Arr : Address; N : Natural; E : Bits_09)
      renames Indexing.Set;

end System.Pack_09;
