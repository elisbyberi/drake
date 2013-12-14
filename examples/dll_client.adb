with Ada.Dynamic_Linking;
with Ada.IO_Exceptions;
with Interfaces.C.Strings;
procedure dll_client is
begin
	use_zlib : declare
		zlib : Ada.Dynamic_Linking.Library;
	begin
		begin
			Ada.Dynamic_Linking.Open (zlib, "libz.so");
			pragma Debug (Ada.Debug.Put ("in BSD or Linux"));
		exception
			when Ada.IO_Exceptions.Name_Error =>
				begin
					Ada.Dynamic_Linking.Open (zlib, "libz.dylib");
					pragma Debug (Ada.Debug.Put ("in Darwin"));
				exception
					when Ada.IO_Exceptions.Name_Error =>
						Ada.Dynamic_Linking.Open (zlib, "libz.dll");
						pragma Debug (Ada.Debug.Put ("in Windows"));
				end;
		end;
		declare
			function zlibVersion return Interfaces.C.Strings.const_chars_ptr;
			pragma Import (C, zlibVersion);
			for zlibVersion'Address use
				Ada.Dynamic_Linking.Import (zlib, "zlibVersion");
		begin
			Ada.Debug.Put (Interfaces.C.Strings.Value (zlibVersion));
		end;
	end use_zlib;
	pragma Debug (Ada.Debug.Put ("OK"));
end dll_client;
