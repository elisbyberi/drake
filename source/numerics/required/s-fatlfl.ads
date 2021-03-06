pragma License (Unrestricted);
--  implementation unit required by compiler
package System.Fat_Lflt is
   pragma Pure;

   package Attr_Long_Float is

      --  required for Long_Float'Adjacent by compiler (s-fatgen.ads)
      function Adjacent (X, Towards : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Adjacent, "__builtin_nextafter");

      --  required for Long_Float'Ceiling by compiler (s-fatgen.ads)
      function Ceiling (X : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Ceiling, "__builtin_ceil");

      --  required for Long_Float'Compose by compiler (s-fatgen.ads)
      function Compose (Fraction : Long_Float; Exponent : Integer)
         return Long_Float;

      --  required for Long_Float'Copy_Sign by compiler (s-fatgen.ads)
      function Copy_Sign (X, Y : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Copy_Sign, "__builtin_copysign");

      --  required for Long_Float'Exponent by compiler (s-fatgen.ads)
      function Exponent (X : Long_Float) return Integer;

      --  required for Long_Float'Floor by compiler (s-fatgen.ads)
      function Floor (X : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Floor, "__builtin_floor");

      --  required for Long_Float'Fraction by compiler (s-fatgen.ads)
      function Fraction (X : Long_Float) return Long_Float;

      --  required for Long_Float'Leading_Part by compiler (s-fatgen.ads)
      function Leading_Part (X : Long_Float; Radix_Digits : Integer)
         return Long_Float;

      --  required for Long_Float'Machine by compiler (s-fatgen.ads)
      function Machine (X : Long_Float) return Long_Float;

      --  required for Long_Float'Machine_Rounding by compiler (s-fatgen.ads)
      function Machine_Rounding (X : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Machine_Rounding, "__builtin_nearbyint");

      --  required for Long_Float'Model by compiler (s-fatgen.ads)
      function Model (X : Long_Float) return Long_Float
         renames Machine;

      --  required for Long_Float'Pred by compiler (s-fatgen.ads)
      function Pred (X : Long_Float) return Long_Float;

      --  required for Long_Float'Remainder by compiler (s-fatgen.ads)
      function Remainder (X, Y : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Remainder, "__builtin_remainder");

      --  required for Long_Float'Rounding by compiler (s-fatgen.ads)
      function Rounding (X : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Rounding, "__builtin_round");

      --  required for Long_Float'Scaling by compiler (s-fatgen.ads)
      function Scaling (X : Long_Float; Adjustment : Integer)
         return Long_Float;
      pragma Import (Intrinsic, Scaling, "__builtin_ldexp");

      --  required for Long_Float'Succ by compiler (s-fatgen.ads)
      function Succ (X : Long_Float) return Long_Float;

      --  required for Long_Float'Truncation by compiler (s-fatgen.ads)
      function Truncation (X : Long_Float) return Long_Float;
      pragma Import (Intrinsic, Truncation, "__builtin_trunc");

      --  required for Long_Float'Unbiased_Rounding by compiler (s-fatgen.ads)
      function Unbiased_Rounding (X : Long_Float) return Long_Float;

      --  required for Long_Float'Valid by compiler (s-fatgen.ads)
      function Valid (X : not null access Long_Float) return Boolean;
      pragma Export (Ada, Valid, "system__fat_lflt__attr_long_float__valid");
      function Unaligned_Valid (A : Address) return Boolean;
      pragma Import (Ada, Unaligned_Valid,
         "system__fat_lflt__attr_long_float__valid");
      pragma Pure_Function (Unaligned_Valid);

   end Attr_Long_Float;

end System.Fat_Lflt;
