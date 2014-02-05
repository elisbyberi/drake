with System.Address_To_Named_Access_Conversions;
with System.Formatting.Address_Image;
package body Ada.Task_Identification is
   pragma Suppress (All_Checks);

   function Image (T : Task_Id) return String is
   begin
      if T = null then
         return "";
      else
         declare
            package Conv is
               new System.Address_To_Named_Access_Conversions (
                  System.Tasking.Tasks.Task_Record,
                  Task_Id);
            Width : constant Natural := (Standard'Address_Size + 3) / 4;
            N : constant not null access constant String := Name (T);
            Result : String (1 .. N'Length + 1 + Width);
            Last : Natural := 0;
         begin
            if N'Length /= 0 then
               Last := N'Length;
               Result (1 .. Last) := N.all;
               Last := Last + 1;
               Result (Last) := ':';
            end if;
            System.Formatting.Address_Image (
               Conv.To_Address (T),
               Result (Last + 1 .. Result'Last),
               Last,
               Set => System.Formatting.Upper_Case);
            return Result (1 .. Last);
         end;
      end if;
   end Image;

end Ada.Task_Identification;
