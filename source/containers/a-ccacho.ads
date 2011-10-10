pragma License (Unrestricted);
--  extended unit
private with Ada.Containers.Inside.Weak_Access_Holders;
private with Ada.Finalization;
private with System.Reference_Counting;
generic
   type Name is private; -- it must have default value
   with procedure Free (X : in out Name) is <>;
package Ada.Containers.Counted_Access_Holders is
   --  Reference counted access types.
   pragma Preelaborate;

   type Holder is tagged private;

   function "=" (Left, Right : Holder) return Boolean;

   function To_Holder (Source : Name) return Holder;
   function "+" (Right : Name) return Holder
      renames To_Holder;

   function Null_Holder return Holder;

   function Is_Null (Container : Holder) return Boolean;

   procedure Clear (Container : in out Holder);

   function Constant_Reference (Container : Holder) return Name;
   function Element (Container : Holder'Class) return Name;

   procedure Replace_Element (
      Target : in out Holder;
      Source : Name);
   procedure Assign (Target : in out Holder; Source : Holder);

   procedure Move (
      Target : in out Holder;
      Source : in out Holder);

   procedure Swap (I, J : in out Holder);

   package Weak is

      type Weak_Holder is tagged private;

      function "=" (Left, Right : Weak_Holder) return Boolean;

      function To_Weak_Holder (Source : Holder) return Weak_Holder;
      function "+" (Right : Holder) return Weak_Holder
         renames To_Weak_Holder;

      function Null_Weak_Holder return Weak_Holder;

      function To_Holder (Source : Weak_Holder) return Holder;
      function "+" (Right : Weak_Holder) return Holder
         renames To_Holder;

      function Is_Null (Container : Weak_Holder) return Boolean;

      procedure Clear (Container : in out Weak_Holder);

      procedure Assign (
         Target : in out Weak_Holder;
         Source : Holder);
      procedure Assign (
         Target : in out Holder;
         Source : Weak_Holder);

   private

      type Weak_Holder is new Finalization.Controlled with record
         Super : aliased Containers.Inside.Weak_Access_Holders.Weak_Holder;
      end record;

      overriding procedure Initialize (Object : in out Weak_Holder);
      overriding procedure Adjust (Object : in out Weak_Holder);
      overriding procedure Finalize (Object : in out Weak_Holder);

   end Weak;

private

   type Data is limited record
      Super : aliased Containers.Inside.Weak_Access_Holders.Data;
      Item : aliased Name;
   end record;
   pragma Suppress_Initialization (Data);

   for Data use record
      Super at 0 range
         0 ..
         Containers.Inside.Weak_Access_Holders.Data_Size - 1;
   end record;

   Null_Data : aliased Data := (
      Super => (System.Reference_Counting.Static, null),
      Item => <>);

   type Data_Access is access all Data;

   type Holder is new Finalization.Controlled with record
      Data : aliased not null Data_Access := Null_Data'Access;
   end record;

   overriding procedure Adjust (Object : in out Holder);
   overriding procedure Finalize (Object : in out Holder);

end Ada.Containers.Counted_Access_Holders;