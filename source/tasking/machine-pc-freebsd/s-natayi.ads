pragma License (Unrestricted);
--  implementation unit specialized for FreeBSD (or Linux)
procedure System.Native_Tasks.Yield;
--  Yield forces the running task to relinquish the processor for an instant.
pragma Preelaborate (System.Native_Tasks.Yield);
