with System.Formatting.Literals;
with System.Value_Error;
package body System.Val_Int is
   pragma Suppress (All_Checks);

   function Value_Integer (Str : String) return Integer is
      Last : Natural;
      Result : Integer;
      Error : Boolean;
   begin
      Formatting.Literals.Get_Literal (Str, Last, Result, Error);
      if not Error then
         Formatting.Literals.Check_Last (Str, Last, Error);
         if not Error then
            return Result;
         end if;
      end if;
      Value_Error ("Integer", Str);
   end Value_Integer;

end System.Val_Int;
