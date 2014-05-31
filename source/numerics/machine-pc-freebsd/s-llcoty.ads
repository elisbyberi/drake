pragma License (Unrestricted);
--  implementation unit
package System.Long_Long_Complex_Types is
   pragma Pure;

   --  Complex

   type Imaginary is new Float;

   type Complex is record
      Re, Im : Float;
   end record;
   pragma Complex_Representation (Complex);

   function Fast_Argument (X : Complex) return Float;
   pragma Inline (Fast_Argument);

   function cabsf (x : Complex) return Float;
   pragma Import (Intrinsic, cabsf, "__builtin_cabsf");
   function Fast_Modulus (X : Complex) return Float
      renames cabsf;

   function conjf (x : Complex) return Complex;
   pragma Import (Intrinsic, conjf, "__builtin_conjf");
   function Fast_Conjugate (X : Complex) return Complex
      renames conjf;

   --  Long_Complex

   type Long_Imaginary is new Long_Float;

   type Long_Complex is record
      Re, Im : Long_Float;
   end record;
   pragma Complex_Representation (Long_Complex);

   function Fast_Argument (X : Long_Complex) return Long_Float;
   pragma Inline (Fast_Argument);

   function cabs (x : Long_Complex) return Long_Float;
   pragma Import (Intrinsic, cabs, "__builtin_cabs");
   function Fast_Modulus (X : Long_Complex) return Long_Float
      renames cabs;

   function conj (x : Long_Complex) return Long_Complex;
   pragma Import (Intrinsic, conj, "__builtin_conj");
   function Fast_Conjugate (X : Long_Complex) return Long_Complex
      renames conj;

   --  Long_Long_Complex

   type Long_Long_Imaginary is new Long_Long_Float;

   type Long_Long_Complex is record
      Re, Im : Long_Long_Float;
   end record;
   pragma Complex_Representation (Long_Long_Complex);

   function Fast_Argument (X : Long_Long_Complex) return Long_Long_Float;
   pragma Inline (Fast_Argument);

   function Fast_Modulus (X : Long_Long_Complex) return Long_Long_Float;
   pragma Inline (Fast_Modulus);

   function conjl (x : Long_Long_Complex) return Long_Long_Complex;
   pragma Import (Intrinsic, conjl, "__builtin_conjl");
   function Fast_Conjugate (X : Long_Long_Complex) return Long_Long_Complex
      renames conjl;

end System.Long_Long_Complex_Types;
