package body Ada.Strings.UTF_Encoding.Wide_Wide_Strings is

   function Add_Or_Remove_BOM is
      new Generic_Add_Or_Remove_BOM (
         Wide_Wide_Character,
         Wide_Wide_String,
         BOM_32);

   --  implementation

   function Encode (
      Item : Wide_Wide_String;
      Output_BOM : Boolean := False)
      return UTF_32_Wide_Wide_String
      renames Add_Or_Remove_BOM;

   function Decode (
      Item : UTF_String;
      Input_Scheme : Encoding_Scheme)
      return Wide_Wide_String is
   begin
      return Conversions.Convert (Item, Input_Scheme, False);
   end Decode;

   function Decode (Item : UTF_8_String) return Wide_Wide_String is
   begin
      return Conversions.Convert (Item, False);
   end Decode;

   function Decode (Item : UTF_16_Wide_String) return Wide_Wide_String is
   begin
      return Conversions.Convert (Item, False);
   end Decode;

   function Decode (Item : UTF_32_Wide_Wide_String) return Wide_Wide_String is
   begin
      return Add_Or_Remove_BOM (Item, False);
   end Decode;

end Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
