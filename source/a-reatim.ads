pragma License (Unrestricted);
private with Ada.Calendar;
private with Ada.Unchecked_Conversion;
package Ada.Real_Time is

   type Time is private;
   Time_First : constant Time;
   Time_Last : constant Time;
   Time_Unit : constant :=
      Duration'Delta; --  implementation-defined-real-number

   type Time_Span is private;
   Time_Span_First : constant Time_Span;
   Time_Span_Last : constant Time_Span;
   Time_Span_Zero : constant Time_Span;
   Time_Span_Unit : constant Time_Span;

--  Tick : constant Time_Span;
   function Clock return Time;
   pragma Inline (Clock);

--  function "+" (Left : Time; Right : Time_Span) return Time;
--  function "+" (Left : Time_Span; Right : Time) return Time;
--  function "-" (Left : Time; Right : Time_Span) return Time;
   function "-" (Left : Time; Right : Time) return Time_Span;
   pragma Inline ("-");

--  function "<" (Left, Right : Time) return Boolean;
--  function "<="(Left, Right : Time) return Boolean;
--  function ">" (Left, Right : Time) return Boolean;
--  function ">="(Left, Right : Time) return Boolean;

--  function "+" (Left, Right : Time_Span) return Time_Span;
--  function "-" (Left, Right : Time_Span) return Time_Span;
--  function "-" (Right : Time_Span) return Time_Span;
--  function "*" (Left : Time_Span; Right : Integer) return Time_Span;
--  function "*" (Left : Integer; Right : Time_Span) return Time_Span;
--  function "/" (Left, Right : Time_Span) return Integer;
--  function "/" (Left : Time_Span; Right : Integer) return Time_Span;

--  function "abs"(Right : Time_Span) return Time_Span;

--  function "<" (Left, Right : Time_Span) return Boolean;
--  function "<="(Left, Right : Time_Span) return Boolean;
--  function ">" (Left, Right : Time_Span) return Boolean;
--  function ">="(Left, Right : Time_Span) return Boolean;

   function To_Duration (TS : Time_Span) return Duration;
--  pragma Inline_Always (To_Duration); -- ??
--  function To_Time_Span (D : Duration) return Time_Span;

--  function Nanoseconds (NS : Integer) return Time_Span;
--  function Microseconds (US : Integer) return Time_Span;
--  function Milliseconds (MS : Integer) return Time_Span;
--  function Seconds (S : Integer) return Time_Span;
--  function Minutes (M : Integer) return Time_Span;

   type Seconds_Count is range
      -(2 ** (Duration'Size - 1)) / 1000000000 ..
      +(2 ** (Duration'Size - 1) - 1) / 1000000000; --  implementation-defined

--  procedure Split (T : Time; SC : out Seconds_Count; TS : out Time_Span);
--  function Time_Of (SC : Seconds_Count; TS : Time_Span) return Time;

private

   type Time is new Calendar.Time;

   function Cast is new Unchecked_Conversion (Duration, Time);

   Time_First : constant Time := Cast (Duration'First);
   Time_Last : constant Time := Cast (Duration'Last);

   type Time_Span is new Duration;

   function Cast is new Unchecked_Conversion (Time_Span, Duration);

   Time_Span_First : constant Time_Span := Time_Span'First;
   Time_Span_Last : constant Time_Span := Time_Span'Last;
   Time_Span_Zero : constant Time_Span := 0.0;
   Time_Span_Unit : constant Time_Span := Time_Span'Delta;

   function To_Duration (TS : Time_Span) return Duration
      renames Cast;

end Ada.Real_Time;
