with Ada.Float;
with System.Long_Long_Elementary_Functions;
package body Ada.Numerics.Generic_Elementary_Functions is
   pragma Suppress (All_Checks);

   procedure Modulo_Divide_By_1 is
      new Float.Modulo_Divide_By_1 (
         Float_Type'Base,
         Float_Type'Base,
         Float_Type'Base);
   subtype Float is Standard.Float; -- hiding "Float" package

   --  constants for Sinh/Cosh on high precision mode
   Log_Two : constant := 0.69314_71805_59945_30941_72321_21458_17656_80755;
   Lnv : constant := 8#0.542714#;
   V2minus1 : constant := 0.13830_27787_96019_02638E-4;

   --  implementation

   function Sqrt (X : Float_Type'Base) return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then X < 0.0 then
         raise Argument_Error; -- CXA5A10
      elsif Float_Type'Digits <= Float'Digits then
         declare
            function sqrtf (A1 : Float) return Float;
            pragma Import (Intrinsic, sqrtf, "__builtin_sqrtf");
         begin
            return Float_Type'Base (sqrtf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function sqrt (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, sqrt, "__builtin_sqrt");
         begin
            return Float_Type'Base (sqrt (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Sqrt (
               Long_Long_Float (X)));
      end if;
   end Sqrt;

   function Log (X : Float_Type'Base) return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then X < 0.0 then
         raise Argument_Error; -- CXA5A09
      elsif not Standard'Fast_Math and then X = 0.0 then
         raise Constraint_Error; -- CXG2011
      elsif Float_Type'Digits <= Float'Digits then
         declare
            function logf (A1 : Float) return Float;
            pragma Import (Intrinsic, logf, "__builtin_logf");
         begin
            return Float_Type'Base (logf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function log (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, log, "__builtin_log");
         begin
            return Float_Type'Base (log (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Log (
               Long_Long_Float (X)));
      end if;
   end Log;

   function Log (X, Base : Float_Type'Base) return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then (Base <= 0.0 or else Base = 1.0) then
         raise Argument_Error; -- CXA5A09
      else
         return Log (X) / Log (Base);
      end if;
   end Log;

   function Exp (X : Float_Type'Base) return Float_Type'Base is
   begin
      if Float_Type'Digits <= Float'Digits then
         declare
            function expf (A1 : Float) return Float;
            pragma Import (Intrinsic, expf, "__builtin_expf");
         begin
            return Float_Type'Base (expf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function exp (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, exp, "__builtin_exp");
         begin
            return Float_Type'Base (exp (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Exp (
               Long_Long_Float (X)));
      end if;
   end Exp;

   function "**" (Left, Right : Float_Type'Base) return Float_Type'Base is
      function powf (A1, A2 : Float) return Float;
      pragma Import (Intrinsic, powf, "__builtin_powf");
      function pow (A1, A2 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, pow, "__builtin_pow");
   begin
      if Standard'Fast_Math then
         if Float_Type'Digits <= Float'Digits then
            return Float_Type'Base (powf (Float (Left), Float (Right)));
         elsif Float_Type'Digits <= Long_Float'Digits then
            return Float_Type'Base (pow (
               Long_Float (Left),
               Long_Float (Right)));
         else
            return Float_Type'Base (
               System.Long_Long_Elementary_Functions.Fast_Pow (
                  Long_Long_Float (Left),
                  Long_Long_Float (Right)));
         end if;
      else
         if Left < 0.0 or else (Left = 0.0 and then Right = 0.0) then
            raise Argument_Error; -- CXA5A09
         elsif Left = 0.0 and then Right < 0.0 then
            raise Constraint_Error; -- CXG2012
         else
            --  CXG2012 requires high precision
            declare
               RT : constant Float_Type'Base := Float_Type'Truncation (Right);
               RR : Float_Type'Base;
               Coef : Float_Type'Base;
               Result : Float_Type'Base;
            begin
               if Right - RT = 0.25 then
                  RR := RT;
                  Coef := Sqrt (Sqrt (Left));
               elsif Right - RT = 0.5 then
                  RR := RT;
                  Coef := Sqrt (Left);
               else
                  RR := Right;
                  Coef := 1.0;
               end if;
               if Float_Type'Digits <= Float'Digits then
                  Result := Float_Type (powf (Float (Left), Float (RR)));
               elsif Float_Type'Digits <= Long_Float'Digits then
                  Result := Float_Type (pow (
                     Long_Float (Left),
                     Long_Float (RR)));
               else
                  Result := Float_Type'Base (
                     System.Long_Long_Elementary_Functions.Fast_Pow (
                        Long_Long_Float (Left),
                        Long_Long_Float (RR)));
               end if;
               return Result * Coef;
            end;
         end if;
      end if;
   end "**";

   function Sin (X : Float_Type'Base) return Float_Type'Base is
   begin
      if Float_Type'Digits <= Float'Digits then
         declare
            function sinf (A1 : Float) return Float;
            pragma Import (Intrinsic, sinf, "__builtin_sinf");
         begin
            return Float_Type'Base (sinf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function sin (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, sin, "__builtin_sin");
         begin
            return Float_Type'Base (sin (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Sin (
               Long_Long_Float (X)));
      end if;
   end Sin;

   function Sin (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Sin (2.0 * Pi * X / Cycle);
      else
         --  CXA5A01 requires just result that is 0.0, 1.0 or -1.0
         --  CXG2004 requires just result that is 0.5
         if Cycle <= 0.0 then
            raise Argument_Error;
         else
            declare
               Q, R : Float_Type'Base;
            begin
               Modulo_Divide_By_1 (X / Cycle, Q, R);
               if R = 1.0 / 12.0 then
                  return 0.5;
               elsif R = 0.25 then
                  return 1.0;
               elsif R = 5.0 / 12.0 then
                  return 0.5;
               elsif R = 0.5 then
                  return 0.0;
               elsif R = 7.0 / 12.0 then
                  return -0.5;
               elsif R = 0.75 then
                  return -1.0;
               elsif R = 11.0 / 12.0 then
                  return -0.5;
               else
                  return Sin (2.0 * Pi * R);
               end if;
            end;
         end if;
      end if;
   end Sin;

   function Cos (X : Float_Type'Base) return Float_Type'Base is
   begin
      if Float_Type'Digits <= Float'Digits then
         declare
            function cosf (A1 : Float) return Float;
            pragma Import (Intrinsic, cosf, "__builtin_cosf");
         begin
            return Float_Type'Base (cosf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function cos (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, cos, "__builtin_cos");
         begin
            return Float_Type'Base (cos (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Cos (
               Long_Long_Float (X)));
      end if;
   end Cos;

   function Cos (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Cos (2.0 * Pi * X / Cycle);
      else
         --  CXA5A02 requires just result that is 0.0, 1.0 or -1.0
         --  CXG2004 requires just result that is 0.5
         if Cycle <= 0.0 then
            raise Argument_Error;
         else
            declare
               Q, R : Float_Type'Base;
            begin
               Modulo_Divide_By_1 (X / Cycle, Q, R);
               if R = 2.0 / 12.0 then
                  return 0.5;
               elsif R = 0.25 then
                  return 0.0;
               elsif R = 4.0 / 12.0 then
                  return -0.5;
               elsif R = 0.5 then
                  return -1.0;
               elsif R = 8.0 / 12.0 then
                  return -0.5;
               elsif R = 0.75 then
                  return 0.0;
               elsif R = 10.0 / 12.0 then
                  return 0.5;
               else
                  return Cos (2.0 * Pi * R);
               end if;
            end;
         end if;
      end if;
   end Cos;

   function Tan (X : Float_Type'Base) return Float_Type'Base is
      function tanf (A1 : Float) return Float;
      pragma Import (Intrinsic, tanf, "__builtin_tanf");
      function tan (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, tan, "__builtin_tan");
   begin
      if Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (tanf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (tan (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Tan (
               Long_Long_Float (X)));
      end if;
   end Tan;

   function Tan (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Tan (2.0 * Pi * X / Cycle);
      else
         if Cycle <= 0.0 then
            raise Argument_Error; -- CXA5A01
         else
            --  CXG2013 requires just result that is 0.0
            declare
               Q, R : Float_Type'Base;
            begin
               Modulo_Divide_By_1 (X / Cycle, Q, R);
               if R = 0.5 then
                  return 0.0;
               else
                  return Tan (2.0 * Pi * R);
               end if;
            end;
         end if;
      end if;
   end Tan;

   function Cot (X : Float_Type'Base) return Float_Type'Base is
   begin
      return 1.0 / Tan (X);
   end Cot;

   function Cot (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Cot (2.0 * Pi * X / Cycle);
      else
         if Cycle <= 0.0 then
            raise Argument_Error; -- CXA5A04
         else
            --  CXG2013 requires just result that is 0.0
            declare
               Q, R : Float_Type'Base;
            begin
               Modulo_Divide_By_1 (X / Cycle, Q, R);
               if R = 0.25 then
                  return 0.0;
               elsif R = 0.75 then
                  return 0.0;
               else
                  return Cot (2.0 * Pi * R);
               end if;
            end;
         end if;
      end if;
   end Cot;

   function Arcsin (X : Float_Type'Base) return Float_Type'Base is
      function asinf (A1 : Float) return Float;
      pragma Import (Intrinsic, asinf, "__builtin_asinf");
      function asin (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, asin, "__builtin_asin");
   begin
      if not Standard'Fast_Math and then abs X > 1.0 then
         raise Argument_Error; -- CXA5A05
      elsif Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (asinf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (asin (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arcsin (
               Long_Long_Float (X)));
      end if;
   end Arcsin;

   function Arcsin (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Arcsin (X) * Cycle / (2.0 * Pi);
      else
         if Cycle <= 0.0 then
            raise Argument_Error; -- CXA5A05
         elsif abs X = 1.0 then
            return Float_Type'Base'Copy_Sign (Cycle / 4.0, X); -- CXG2015
         else
            return Arcsin (X) * Cycle / (2.0 * Pi);
         end if;
      end if;
   end Arcsin;

   function Arccos (X : Float_Type'Base) return Float_Type'Base is
      function acosf (A1 : Float) return Float;
      pragma Import (Intrinsic, acosf, "__builtin_acosf");
      function acos (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, acos, "__builtin_acos");
   begin
      if not Standard'Fast_Math and then abs X > 1.0 then
         raise Argument_Error; -- CXA5A06
      elsif Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (acosf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (acos (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arccos (
               Long_Long_Float (X)));
      end if;
   end Arccos;

   function Arccos (X, Cycle : Float_Type'Base) return Float_Type'Base is
   begin
      if Standard'Fast_Math then
         return Arccos (X) * Cycle / (2.0 * Pi);
      else
         if Cycle <= 0.0 then
            raise Argument_Error; -- CXA5A06
         elsif X = -1.0 then
            return Cycle / 2.0; -- CXG2015
         else
            return Arccos (X) * Cycle / (2.0 * Pi);
         end if;
      end if;
   end Arccos;

   function Arctan (Y : Float_Type'Base; X : Float_Type'Base := 1.0)
      return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then X = 0.0 and then Y = 0.0 then
         raise Argument_Error; -- CXA5A07
      elsif Float_Type'Digits <= Float'Digits then
         declare
            function atan2f (A1, A2 : Float) return Float;
            pragma Import (Intrinsic, atan2f, "__builtin_atan2f");
         begin
            return Float_Type'Base (atan2f (Float (Y), Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function atan2 (A1, A2 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, atan2, "__builtin_atan2");
         begin
            return Float_Type'Base (atan2 (Long_Float (Y), Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arctan (
               Long_Long_Float (Y),
               Long_Long_Float (X)));
      end if;
   end Arctan;

   function Arctan (
      Y : Float_Type'Base;
      X : Float_Type'Base := 1.0;
      Cycle : Float_Type'Base)
      return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then Cycle <= 0.0 then
         raise Argument_Error; -- CXA5A07
      elsif not Standard'Fast_Math and then Y = 0.0 then
         --  CXG2016 requires
         if X < 0.0 then
            return Cycle / 2.0 * Float_Type'Copy_Sign (1.0, Y);
         else
            return 0.0;
         end if;
      else
         return Arctan (Y, X) * Cycle / (2.0 * Pi);
      end if;
   end Arctan;

   function Arccot (X : Float_Type'Base; Y : Float_Type'Base := 1.0)
      return Float_Type'Base is
   begin
      return Arctan (Y, X);
   end Arccot;

   function Arccot (
      X : Float_Type'Base;
      Y : Float_Type'Base := 1.0;
      Cycle : Float_Type'Base)
      return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then Cycle <= 0.0 then
         raise Argument_Error; -- CXA5A08
      else
         return Arccot (X, Y) * Cycle / (2.0 * Pi);
      end if;
   end Arccot;

   function Sinh (X : Float_Type'Base) return Float_Type'Base is
      Log_Inverse_Epsilon : constant Float_Type'Base :=
         Float_Type'Base (Float_Type'Base'Model_Mantissa - 1) * Log_Two;
   begin
      if not Standard'Fast_Math and then abs X > Log_Inverse_Epsilon then
         --  CXG2014 requires high precision
         declare
            Y : constant Float_Type'Base := Exp (abs X - Lnv);
            Z : constant Float_Type'Base := Y + V2minus1 * Y;
         begin
            return Float_Type'Copy_Sign (Z, X);
         end;
      elsif Float_Type'Digits <= Float'Digits then
         declare
            function sinhf (A1 : Float) return Float;
            pragma Import (Intrinsic, sinhf, "__builtin_sinhf");
         begin
            return Float_Type'Base (sinhf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function sinh (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, sinh, "__builtin_sinh");
         begin
            return Float_Type'Base (sinh (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Sinh (
               Long_Long_Float (X)));
      end if;
   end Sinh;

   function Cosh (X : Float_Type'Base) return Float_Type'Base is
      Log_Inverse_Epsilon : constant Float_Type'Base :=
         Float_Type'Base (Float_Type'Base'Model_Mantissa - 1) * Log_Two;
   begin
      if not Standard'Fast_Math and then abs X > Log_Inverse_Epsilon then
         --  CXG2014 requires high precision
         --  graph of Cosh draws catenary line (Cosh (X) = abs Sinh (X))
         declare
            Y : constant Float_Type'Base := Exp (abs X - Lnv);
            Z : constant Float_Type'Base := Y + V2minus1 * Y;
         begin
            return Z;
         end;
      elsif Float_Type'Digits <= Float'Digits then
         declare
            function coshf (A1 : Float) return Float;
            pragma Import (Intrinsic, coshf, "__builtin_coshf");
         begin
            return Float_Type'Base (coshf (Float (X)));
         end;
      elsif Float_Type'Digits <= Long_Float'Digits then
         declare
            function cosh (A1 : Long_Float) return Long_Float;
            pragma Import (Intrinsic, cosh, "__builtin_cosh");
         begin
            return Float_Type'Base (cosh (Long_Float (X)));
         end;
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Cosh (
               Long_Long_Float (X)));
      end if;
   end Cosh;

   function Tanh (X : Float_Type'Base) return Float_Type'Base is
      function tanhf (A1 : Float) return Float;
      pragma Import (Intrinsic, tanhf, "__builtin_tanhf");
      function tanh (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, tanh, "__builtin_tanh");
   begin
      if Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (tanhf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (tanh (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Tanh (
               Long_Long_Float (X)));
      end if;
   end Tanh;

   function Coth (X : Float_Type'Base) return Float_Type'Base is
   begin
      return 1.0 / Tanh (X);
   end Coth;

   function Arcsinh (X : Float_Type'Base) return Float_Type'Base is
      function asinhf (A1 : Float) return Float;
      pragma Import (Intrinsic, asinhf, "__builtin_asinhf");
      function asinh (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, asinh, "__builtin_asinh");
   begin
      if Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (asinhf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (asinh (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arcsinh (
               Long_Long_Float (X)));
      end if;
   end Arcsinh;

   function Arccosh (X : Float_Type'Base) return Float_Type'Base is
      function acoshf (A1 : Float) return Float;
      pragma Import (Intrinsic, acoshf, "__builtin_acoshf");
      function acosh (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, acosh, "__builtin_acosh");
   begin
      if not Standard'Fast_Math and then X < 1.0 then
         raise Argument_Error; -- CXA5A06
      elsif Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (acoshf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (acosh (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arccosh (
               Long_Long_Float (X)));
      end if;
   end Arccosh;

   function Arctanh (X : Float_Type'Base) return Float_Type'Base is
      function atanhf (A1 : Float) return Float;
      pragma Import (Intrinsic, atanhf, "__builtin_atanhf");
      function atanh (A1 : Long_Float) return Long_Float;
      pragma Import (Intrinsic, atanh, "__builtin_atanh");
   begin
      if not Standard'Fast_Math and then abs X > 1.0 then
         raise Argument_Error; -- CXA5A03
      elsif Float_Type'Digits <= Float'Digits then
         return Float_Type'Base (atanhf (Float (X)));
      elsif Float_Type'Digits <= Long_Float'Digits then
         return Float_Type'Base (atanh (Long_Float (X)));
      else
         return Float_Type'Base (
            System.Long_Long_Elementary_Functions.Fast_Arctanh (
               Long_Long_Float (X)));
      end if;
   end Arctanh;

   function Arccoth (X : Float_Type'Base) return Float_Type'Base is
   begin
      if not Standard'Fast_Math and then abs X < 1.0 then
         raise Argument_Error; -- CXA5A04
      else
         return Log ((X + 1.0) / (X - 1.0)) * 0.5;
      end if;
   end Arccoth;

end Ada.Numerics.Generic_Elementary_Functions;
