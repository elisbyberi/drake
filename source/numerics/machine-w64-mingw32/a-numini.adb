with Ada.Exception_Identification.From_Here;
with Ada.IO_Exceptions;
with System.Address_To_Named_Access_Conversions;
with C.windef;
with C.winbase;
with C.wincrypt;
with C.winerror;
procedure Ada.Numerics.Initiator (
   Item : System.Address;
   Size : System.Storage_Elements.Storage_Count)
is
   pragma Suppress (All_Checks);
   use Exception_Identification.From_Here;
   use type C.windef.WINBOOL;
   use type C.windef.DWORD; -- error code
   package BYTE_ptr_Conv is
      new System.Address_To_Named_Access_Conversions (
         C.windef.BYTE,
         C.windef.BYTE_ptr);
   Context : aliased C.wincrypt.HCRYPTPROV;
   Error : Boolean;
begin
   if C.wincrypt.CryptAcquireContext (
      Context'Access,
      null,
      null,
      C.wincrypt.PROV_RSA_FULL,
      C.wincrypt.CRYPT_VERIFYCONTEXT) = 0
   then
      Raise_Exception (IO_Exceptions.Use_Error'Identity);
   end if;
   for I in 1 .. 5 loop
      Error := C.wincrypt.CryptGenRandom (
         Context,
         C.windef.DWORD (Size),
         BYTE_ptr_Conv.To_Pointer (Item)) = 0;
      exit when not Error
         or else C.winbase.GetLastError /= C.winerror.ERROR_BUSY;
      C.winbase.Sleep (10); -- ???
   end loop;
   if C.wincrypt.CryptReleaseContext (Context, 0) = 0 then
      Error := True;
   end if;
   if Error then
      Raise_Exception (IO_Exceptions.Use_Error'Identity);
   end if;
end Ada.Numerics.Initiator;
