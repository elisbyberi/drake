function Ada.Numerics.Generic_Elementary_Sqrt (X : Float_Type'Base)
   return Float_Type'Base
is
   function sqrtf (A1 : Float) return Float;
   pragma Import (Intrinsic, sqrtf, "__builtin_sqrtf");
   function sqrt (A1 : Long_Float) return Long_Float;
   pragma Import (Intrinsic, sqrt, "__builtin_sqrt");
   function sqrtl (A1 : Long_Long_Float) return Long_Long_Float;
   pragma Import (Intrinsic, sqrtl, "__builtin_sqrtl");
begin
   if not Standard'Fast_Math and then X < 0.0 then
      raise Argument_Error; -- CXA5A10
   elsif Float_Type'Digits <= Float'Digits then
      return Float_Type (sqrtf (Float (X)));
   elsif Float_Type'Digits <= Long_Float'Digits then
      return Float_Type (sqrt (Long_Float (X)));
   else
      return Float_Type (sqrtl (Long_Long_Float (X)));
   end if;
end Ada.Numerics.Generic_Elementary_Sqrt;