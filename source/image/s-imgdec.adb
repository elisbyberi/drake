with System.Formatting.Decimal_Image;
package body System.Img_Dec is
   pragma Suppress (All_Checks);

   procedure Image_Decimal (
      V : Integer;
      S : in out String;
      P : out Natural;
      Scale : Integer) is
   begin
      Formatting.Decimal_Image (
         Long_Long_Integer (V),
         S,
         P,
         Scale,
         Aft_Width => Integer'Max (1, Scale));
   end Image_Decimal;

end System.Img_Dec;
