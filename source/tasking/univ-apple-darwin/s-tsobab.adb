with System.Tasking.Tasks;
package body System.Tasking.Synchronous_Objects.Abortable is

   Abort_Checking_Span : constant Duration := 1.0;

   --  condition variable

   procedure Wait (
      Object : in out Condition_Variable;
      Mutex : in out Synchronous_Objects.Mutex;
      Notified : out Boolean;
      Aborted : out Boolean) is
   begin
      Notified := False;
      Aborted := Tasks.Is_Aborted;
      if not Aborted then
         loop
            Wait (Object, Mutex, Abort_Checking_Span, Notified);
            Aborted := Tasks.Is_Aborted;
            exit when Notified or else Aborted;
         end loop;
      end if;
   end Wait;

   procedure Wait (
      Object : in out Condition_Variable;
      Mutex : in out Synchronous_Objects.Mutex;
      Timeout : Native_Time.Native_Time;
      Notified : out Boolean;
      Aborted : out Boolean) is
   begin
      Notified := False;
      Aborted := Tasks.Is_Aborted;
      if not Aborted then
         declare
            N : Native_Time.Native_Time;
         begin
            loop
               N := Native_Time.Clock + Abort_Checking_Span;
               exit when Native_Time.To_Time (N) >=
                  Native_Time.To_Time (Timeout);
               Wait (Object, Mutex, N, Notified);
               Aborted := Tasks.Is_Aborted;
               if Notified or else Aborted then
                  return;
               end if;
            end loop;
            Wait (Object, Mutex, Timeout, Notified);
            Aborted := Tasks.Is_Aborted;
         end;
      end if;
   end Wait;

   procedure Wait (
      Object : in out Condition_Variable;
      Mutex : in out Synchronous_Objects.Mutex;
      Timeout : Duration;
      Notified : out Boolean;
      Aborted : out Boolean) is
   begin
      Notified := False;
      Aborted := Tasks.Is_Aborted;
      if not Aborted then
         declare
            R : Duration := Timeout;
         begin
            while R > Abort_Checking_Span loop
               Wait (Object, Mutex, Abort_Checking_Span, Notified);
               Aborted := Tasks.Is_Aborted;
               if Notified or else Aborted then
                  return;
               end if;
               R := R - Abort_Checking_Span;
            end loop;
            Wait (Object, Mutex, R, Notified);
            Aborted := Tasks.Is_Aborted;
         end;
      end if;
   end Wait;

   --  queue

   procedure Take (
      Object : in out Queue;
      Item : out Queue_Node_Access;
      Params : Address;
      Filter : Queue_Filter;
      Aborted : out Boolean) is
   begin
      Aborted := Tasks.Is_Aborted;
      Enter (Object.Mutex);
      declare
         Previous : Queue_Node_Access := null;
         I : Queue_Node_Access := Object.Head;
      begin
         Taking : loop
            Take_No_Sync (Object, Item, Params, Filter, Previous, I);
            exit Taking when Item /= null;
            Not_Found : declare
               Tail_On_Waiting : constant Queue_Node_Access := Object.Tail;
               Notified : Boolean; -- ignored
            begin
               Object.Params := Params;
               Object.Filter := Filter;
               loop
                  Object.Waiting := True;
                  Wait (
                     Object.Condition_Variable,
                     Object.Mutex,
                     Timeout => Abort_Checking_Span,
                     Notified => Notified,
                     Aborted => Aborted);
                  Object.Waiting := False;
                  exit Taking when Aborted;
                  exit when Object.Tail /= Tail_On_Waiting;
               end loop;
               if Tail_On_Waiting /= null then
                  Previous := Tail_On_Waiting;
                  I := Tail_On_Waiting.Next;
               else
                  Previous := null;
                  I := Object.Head;
               end if;
            end Not_Found;
         end loop Taking;
      end;
      Leave (Object.Mutex);
   end Take;

   --  event

   procedure Wait (
      Object : in out Event;
      Aborted : out Boolean) is
   begin
      Enter (Object.Mutex);
      if Object.Value then
         Aborted := Tasks.Is_Aborted;
      else
         loop
            declare
               Notified : Boolean;
            begin
               Wait (
                  Object.Condition_Variable,
                  Object.Mutex,
                  Notified => Notified,
                  Aborted => Aborted);
            end;
            exit when Object.Value or else Aborted;
         end loop;
      end if;
      Leave (Object.Mutex);
   end Wait;

   procedure Wait (
      Object : in out Event;
      Timeout : Duration;
      Value : out Boolean;
      Aborted : out Boolean) is
   begin
      Enter (Object.Mutex);
      if Object.Value then
         Value := True;
         Aborted := Tasks.Is_Aborted;
      else
         Wait (
            Object.Condition_Variable,
            Object.Mutex,
            Timeout => Timeout,
            Notified => Value,
            Aborted => Aborted);
--       pragma Assert (Object.Value >= Value);
      end if;
      Leave (Object.Mutex);
   end Wait;

   --  barrier

   procedure Wait (
      Object : in out Barrier;
      Notified : out Boolean;
      Aborted : out Boolean) is
   begin
      Enter (Object.Mutex);
      Notified := Object.Blocked = 0;
      Object.Blocked := Object.Blocked + 1;
      if Object.Blocked = Object.Release_Threshold then
         Notify_All (Object.Condition_Variable);
         Object.Blocked := 0;
         Aborted := Tasks.Is_Aborted;
      else
         declare
            Threshold_Is_Satisfied : Boolean;
         begin
            Wait (
               Object.Condition_Variable,
               Object.Mutex,
               Notified => Threshold_Is_Satisfied,
               Aborted => Aborted);
         end;
      end if;
      Leave (Object.Mutex);
   end Wait;

   --  delay

   procedure Delay_For (
      D : Duration;
      Aborted : out Boolean)
   is
      M : Mutex;
      C : Condition_Variable;
      Notified : Boolean;
   begin
      Initialize (M);
      Initialize (C);
      Enter (M);
      Wait (
         C,
         M,
         Timeout => Duration'Max (D, 0.0),
         Notified => Notified,
         Aborted => Aborted);
      Leave (M);
      Finalize (C);
      Finalize (M);
   end Delay_For;

   procedure Delay_Until (
      T : Native_Time.Native_Time;
      Aborted : out Boolean)
   is
      M : Mutex;
      C : Condition_Variable;
      Notified : Boolean;
   begin
      Initialize (M);
      Initialize (C);
      Enter (M);
      Wait (
         C,
         M,
         Timeout => T,
         Notified => Notified,
         Aborted => Aborted);
      Leave (M);
      Finalize (C);
      Finalize (M);
   end Delay_Until;

end System.Tasking.Synchronous_Objects.Abortable;
