package body Ada.Streams.Stream_IO.Inside.Standard_Files is
begin
   System.Native_IO.Initialize (
      Standard_Input_Stream.Handle,
      Standard_Output_Stream.Handle,
      Standard_Error_Stream.Handle);
end Ada.Streams.Stream_IO.Inside.Standard_Files;
