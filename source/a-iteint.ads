pragma License (Unrestricted);
--  Ada 2012
generic
--  type Cursor;
   type Cursor is private; -- [gcc-4.6] formal incomplete type is unimplemented
   with function Has_Element (Position : Cursor) return Boolean;
   pragma Unreferenced (Has_Element);
package Ada.Iterator_Interfaces is
   pragma Pure;

   type Forward_Iterator is limited interface;
   function First (Object : Forward_Iterator) return Cursor is abstract;
   function Next (Object : Forward_Iterator; Position : Cursor)
      return Cursor is abstract;

   type Reversible_Iterator is limited interface and Forward_Iterator;
   function Last (Object : Reversible_Iterator) return Cursor is abstract;
   function Previous (Object : Reversible_Iterator; Position : Cursor)
      return Cursor is abstract;

end Ada.Iterator_Interfaces;
