with System.Formatting.Literals.Float;
with System.Value_Error;
package body System.Val_Dec is
   pragma Suppress (All_Checks);

   function Value_Decimal (Str : String; Scale : Integer) return Integer is
      Last : Natural := Str'First - 1;
      Result : Long_Long_Float;
      Error : Boolean;
   begin
      Formatting.Literals.Float.Get_Literal (Str, Last, Result, Error);
      if not Error then
         Formatting.Literals.Check_Last (Str, Last, Error);
         if not Error then
            return Integer (Result * 10.0 ** Scale);
         end if;
      end if;
      Value_Error ("Decimal", Str);
   end Value_Decimal;

end System.Val_Dec;
