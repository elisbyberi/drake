pragma License (Unrestricted);
--  separated and auto-loaded by compiler
generic
   type Num is range <>;
package Ada.Text_IO.Integer_IO is

   Default_Width : Field := Num'Width;
   Default_Base : Number_Base := 10;

   --  extended
   Default_Padding : Character := ' ';

   procedure Get (
      File : File_Type;
      Item : out Num;
      Width : Field := 0);
   procedure Get (
      Item : out Num;
      Width : Field := 0);
   procedure Get (
      File : not null File_Access; -- alt
      Item : out Num;
      Width : Field := 0);

   --  modified
   procedure Put (
      File : File_Type;
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding); -- additional
   procedure Put (
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding); -- additional
   procedure Put (
      File : not null File_Access; -- alt
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding);

   procedure Get (
      From : String;
      Item : out Num;
      Last : out Positive);
   --  modified
   procedure Put (
      To : out String;
      Item : Num;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding); -- additional

end Ada.Text_IO.Integer_IO;
