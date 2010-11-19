with Ada.Command_Line;
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Strings.Equal_Case_Insensitive;
with Ada.Strings.Fixed;
with Ada.Strings.Less_Case_Insensitive;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
procedure run_acats is
	use type Ada.Containers.Count_Type;
	use type Ada.Strings.Unbounded.Unbounded_String;
	function "+" (Right : Ada.Strings.Unbounded.Unbounded_String) return String
		renames Ada.Strings.Unbounded.To_String;
	
	Unknown : exception;
	Command_Failure : exception;
	Compile_Failure : exception;
	Test_Failure : exception;
	Should_Be_Failure : exception;
	Configuration_Error : exception;
	
	procedure Shell_Execute (Command : in String; Result : out Integer) is
		function system (S : String) return Integer;
		pragma Import (C, system);
		Code : Integer;
	begin
		Ada.Text_IO.Put_Line (Command);
		Code := system (Command & ASCII.NUL);
		if Code mod 256 /= 0 then
			raise Command_Failure with Command & Integer'Image (Code);
		end if;
		Result := Code / 256;
	end Shell_Execute;
	
	procedure Shell_Execute (Command : in String) is
		Result : Integer;
	begin
		Shell_Execute (Command, Result);
		if Result /= 0 then
			raise Command_Failure with Command;
		end if;
	end Shell_Execute;
	
	function Get_Prefix return String is
	begin
		if Ada.Environment_Variables.Exists ("TARGET") then
			return Ada.Environment_Variables.Value ("TARGET") & "-";
		else
			return "";
		end if;
	end Get_Prefix;
	
	Prefix : constant String := Get_Prefix;
	
	Start_Dir : constant String := Ada.Directories.Current_Directory;
	
	ACATS_Dir : constant String := Ada.Environment_Variables.Value ("ACATSDIR");
	Support_Dir : constant String := Ada.Environment_Variables.Value ("SUPPORTDIR");
	Test_Dir : constant String := Ada.Environment_Variables.Value ("TESTDIR");
	
	function Get_RTS_Dir return String is
	begin
		if Ada.Environment_Variables.Exists ("RTSDIR") then
			return Ada.Environment_Variables.Value ("RTSDIR");
		else
			return "";
		end if;
	end Get_RTS_Dir;
	
	RTS_Dir : constant String := Get_RTS_Dir;
	
	type Runtime_Type is (GNAT, Drake);
	
	function Get_Runtime return Runtime_Type is
	begin
		if RTS_Dir = "" then
			return GNAT;
		else
			return Drake;
		end if;
	end Get_Runtime;
	
	Runtime : constant Runtime_Type := Get_Runtime;
	
	procedure Symbolic_Link (Source, Destination : in String) is
	begin
		Shell_Execute ("ln -s " & Source & " " & Destination);
	end Symbolic_Link;
	
	procedure Chop (
		Name : in String;
		Destination_Directory : in String := "";
		Accept_Error : in Boolean := False)
	is
		Command : Ada.Strings.Unbounded.Unbounded_String;
	begin
		Ada.Strings.Unbounded.Append (Command, "gnatchop -w");
		if Prefix /= "" then
			Ada.Strings.Unbounded.Append (Command, " --GCC=");
			Ada.Strings.Unbounded.Append (Command, Prefix);
			Ada.Strings.Unbounded.Append (Command, "gcc");
		end if;
		Ada.Strings.Unbounded.Append (Command, " ");
		Ada.Strings.Unbounded.Append (Command, Name);
		if Destination_Directory /= "" then
			Ada.Strings.Unbounded.Append (Command, " ");
			Ada.Strings.Unbounded.Append (Command, Destination_Directory);
		end if;
		begin
			Shell_Execute (+Command);
		exception
			when Command_Failure =>
				if not Accept_Error then
					raise;
				end if;
		end;
	end Chop;
	
	type Ada_Spec is (Ada_95, Ada_2005);
	
	procedure Compile_Only (Name : in String) is
		Command : Ada.Strings.Unbounded.Unbounded_String;
	begin
		Ada.Strings.Unbounded.Append (Command, Prefix);
		Ada.Strings.Unbounded.Append (Command, "gcc -c ");
		Ada.Strings.Unbounded.Append (Command, Name);
		Shell_Execute (+Command);
	end Compile_Only;
	
	procedure Compile (
		Name : in String;
		Spec : in Ada_Spec;
		Stack_Check : in Boolean := False;
		Overflow_Check : in Boolean := False;
		Dynamic_Elaboration : in Boolean := False;
		UTF_8 : in Boolean := False;
		Link_With : in String := "";
		RTS : in String := "";
		Save_Log : in Boolean := False)
	is
		Command : Ada.Strings.Unbounded.Unbounded_String;
	begin
		Ada.Strings.Unbounded.Append (Command, "gnatmake");
		if Support_Dir /= "" then
			Ada.Strings.Unbounded.Append (Command, " -I../"); -- relative path from Test_Dir
			Ada.Strings.Unbounded.Append (Command, Support_Dir);
		end if;
		case Spec is
			when Ada_95 =>
				Ada.Strings.Unbounded.Append (Command, " -gnat95");
			when Ada_2005 =>
				Ada.Strings.Unbounded.Append (Command, " -gnat05");
		end case;
		if Stack_Check then
			Ada.Strings.Unbounded.Append (Command, " -fstack-check");
		end if;
		if Overflow_Check then
			Ada.Strings.Unbounded.Append (Command, " -gnato");
		end if;
		if Dynamic_Elaboration then
			Ada.Strings.Unbounded.Append (Command, " -gnatE -f");
		end if;
		Ada.Strings.Unbounded.Append (Command, " -gnatws"); -- suppress all warnings
		if UTF_8 then
			Ada.Strings.Unbounded.Append (Command, " -gnatW8");
		end if;
		Ada.Strings.Unbounded.Append (Command, " ");
		Ada.Strings.Unbounded.Append (Command, Name);
		if Link_With /= "" then
			Ada.Strings.Unbounded.Append (Command, " -largs ");
			Ada.Strings.Unbounded.Append (Command, Link_With);
		end if;
		if RTS /= "" then
			Ada.Strings.Unbounded.Append (Command, " --RTS=");
			Ada.Strings.Unbounded.Append (Command, RTS);
		end if;
		if Save_Log then
			Ada.Strings.Unbounded.Append (Command, " 2>&1 | tee log.txt");
		end if;
		Shell_Execute (+Command);
	exception
		when Command_Failure => raise Compile_Failure with +Command;
	end Compile;
	
	type Test_Result is (
		Passed, -- 0
		Any_Exception, -- 1
		Not_Applicative, -- 2
		Tentatively, -- 3,
		Failed, -- 4
		Untested);
	
	procedure Invoke (
		Executable : in String;
		Expected : in Test_Result;
		Result : not null access Test_Result)
	is
		C : Integer;
	begin
		Shell_Execute ("./" & Executable, C);
		Result.all := Test_Result'Val (C);
		if Result.all /= Expected then
			raise Test_Failure;
		end if;
	exception
		when Command_Failure =>
			Result.all := Any_Exception;
			raise Test_Failure;
	end Invoke;
	
	procedure Setup_Test_Dir is
	begin
		if Ada.Directories.Exists (Test_Dir) then
			Ada.Directories.Delete_Tree (Test_Dir);
		end if;
		Ada.Directories.Create_Directory (Test_Dir);
	end Setup_Test_Dir;
	
	function Is_Only_Pragmas (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "cxh30030.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70010.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70030.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70040.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70050.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70060.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70070.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70080.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxd70090.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40010.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40021.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40030.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40041.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40051.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40060.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40071.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40082.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40090.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40101.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40111.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40121.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40130.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40140.a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "lxh40142.a");
	end Is_Only_Pragmas;
	
	procedure Adjust_After_Extract (Name : in String) is
		procedure Delete (Name : in String) is
		begin
			Ada.Text_IO.Put_Line ("remove " & Name);
			Ada.Directories.Delete_File (Name);
		end Delete;
		procedure Copy (Source, Destination : in String) is
		begin
			Ada.Text_IO.Put_Line ("copy " & Source & " to " & Destination);
			Ada.Directories.Copy_File (Source, Destination);
		end Copy;
	begin
		if Ada.Strings.Equal_Case_Insensitive (Name, "ca1020e") then
			Delete ("ca1020e_func1.adb");
			Delete ("ca1020e_func2.adb");
			Delete ("ca1020e_proc1.adb");
			Delete ("ca1020e_proc2.adb");
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "ca14028") then
			Delete ("ca14028_func2.adb");
			Delete ("ca14028_func3.adb");
			Delete ("ca14028_proc1.adb");
			Delete ("ca14028_proc3.adb");
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "ce2108f") then
			Copy ("../X2108E", "X2108E");
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "ce2108h") then
			Copy ("../X2108G", "X2108G");
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "ce3112d") then
			Copy ("../X3112C", "X3112C");
		end if;
	end Adjust_After_Extract;
	
	function Ada_Spec_Of_Test (Name : String) return Ada_Spec is
	begin
		if Ada.Strings.Equal_Case_Insensitive (Name, "c34008a") then
			return Ada_95;
		else
			return Ada_2005;
		end if;
	end Ada_Spec_Of_Test;
	
	function Stack_Check (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "c52103x")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c52104x")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c52104y")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cb1010c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cb1010d");
	end Stack_Check;
	
	function Overflow_Check (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "c43206a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45304a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45304b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45304c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45504a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45504b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45504c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45613a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45613b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45613c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45632a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45632b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45632c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c460008")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c460011")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c46014a");
	end Overflow_Check;
	
	function Dynamic_Elaboration (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "c731001")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c854002")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ca5006a");
	end Dynamic_Elaboration;
	
	function Expected_Result (Name : String; Runtime : Runtime_Type) return Test_Result is
	begin
		if Ada.Strings.Equal_Case_Insensitive (Name, "eb4011a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "eb4012a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "eb4014a")
		then
			return Any_Exception; -- TENTATIVELY?
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "c45322a") -- Float'Machine_Overflows
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c45523a") -- Float'Machine_Overflows
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c4a012b") -- Float'Machine_Overflows
			or else Ada.Strings.Equal_Case_Insensitive (Name, "c96005b") -- Duration'Base equals Duration
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cb10002") -- enough memory
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102d"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102e"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102f"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102i"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102j"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102n"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102o"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102p"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102q"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102r"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102s"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102t"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102u"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102v"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2102w"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2203a"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce2403a"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102e"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102f"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102g"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102i"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102j"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3102k"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3115a"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3304a"))
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "ce3413b"))
		then
			return Not_Applicative;
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "cz1101a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cz1103a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "e28002b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "e28005d")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ee3203a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ee3204a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ee3402b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ee3409f")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ee3412c")
		then
			return Tentatively;
		elsif Ada.Strings.Equal_Case_Insensitive (Name, "cz00004") then
			return Failed;
		else
			return Passed;
		end if;
	end Expected_Result;
	
	function Skip_Compile (Name : String; Runtime : Runtime_Type) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "cxb3006") -- ACATS is older than Ada spec
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cxb4009") -- COBOL
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cxb5004") -- Fortran
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cxb5005") -- Fortran
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd2007")) -- Asynchronous_Task_Control is not supported
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxdb001")) -- Asynchronous_Task_Control is not supported
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxdb002")) -- Asynchronous_Task_Control is not supported
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxdb003")) -- Asynchronous_Task_Control is not supported
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxdb004")) -- Asynchronous_Task_Control is not supported
			or else Ada.Strings.Equal_Case_Insensitive (Name (Name'First .. Name'First + 2), "cxe") -- GLADE required for Annex E (RPC)
			or else Ada.Strings.Equal_Case_Insensitive (Name, "cxh1001"); -- all sources should be recompilation required by pragma Normalize_Scalars
	end Skip_Compile;
	
	function Skip_Execute (Name : String; Runtime : Runtime_Type) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "c41306a") -- rendezvous before return
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ca11023") -- bug of ACATS...
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ca14028") -- GNAT can not handle non-generic body and generic spec
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name (Name'First .. Name'First + 2), "cxc")) -- Annex C is not supported
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd1003")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd1004")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd1005")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd2002")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd2003")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd2006")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd2008")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd3001")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd3002")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxd6002")) -- GNAT failed
			or else (Runtime = GNAT and then Ada.Strings.Equal_Case_Insensitive (Name, "cxda004")); -- GNAT failed
	end Skip_Execute;
	
	function Is_Error_Class (Name : String) return Boolean is
	begin
		return Name (Name'First) = 'B'
			or else Name (Name'First) = 'b'
			or else Name (Name'First) = 'L'
			or else Name (Name'First) = 'l';
	end Is_Error_Class;
	
	function Is_No_Error (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "ba1020c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba15001");
	end Is_No_Error;
	
	function Is_Missing_Subunits (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "ba2001f")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba3001e")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007d")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007e")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007f")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007g")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008d")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008e")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008f")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008g");
	end Is_Missing_Subunits;
	
	function Is_Not_Found (Name : String) return Boolean is
	begin
		return Ada.Strings.Equal_Case_Insensitive (Name, "ba11003")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba11013")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba1101a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba1101b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba1101c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba1109a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba12007")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba12008")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba16001")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba16002")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba3001a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba3001b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba3001c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "ba3001f")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5007c")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008a")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008b")
			or else Ada.Strings.Equal_Case_Insensitive (Name, "la5008c");
	end Is_Not_Found;
	
	procedure Check_Log_In_Error_Class (Name : in String) is
		File : Ada.Text_IO.File_Type;
		Error : Boolean := False;
		Runtime_Configuration_Error : Boolean := False;
	begin
		Ada.Text_IO.Open (File, Ada.Text_IO.In_File, "log.txt");
		while not Ada.Text_IO.End_Of_File (File) loop
			declare
				Line : constant String := Ada.Text_IO.Get_Line (File);
			begin
				if Ada.Strings.Fixed.Index (Line, "file can have only one compilation unit") >= 1
					or else (Ada.Strings.Fixed.Index (Line, "cannot generate code") >= 1 and then not Is_Missing_Subunits (Name))
				then
					raise Configuration_Error;
				elsif Ada.Strings.Fixed.Index (Line, "run-time library configuration error") >= 1 then
					Runtime_Configuration_Error := True;
				elsif Ada.Strings.Fixed.Index (Line, "not found") >= 1 then
					if Runtime_Configuration_Error then
						null; -- raise Should_Be_Failure
					elsif Is_Not_Found (Name) then
						Error := True;
					else
						raise Configuration_Error;
					end if;
				elsif Ada.Strings.Fixed.Index (Line, "compilation error") >= 1
					or else Ada.Strings.Fixed.Index (Line, "bind failed") >= 1
				then
					Error := True;
				end if;
			end;
		end loop;
		Ada.Text_IO.Close (File);
		if not Error and then not Is_No_Error (Name) then
			raise Should_Be_Failure;
		end if;
	end Check_Log_In_Error_Class;
	
	package String_CI_Sets is new Ada.Containers.Indefinite_Ordered_Sets (
		String,
		"<" => Ada.Strings.Less_Case_Insensitive,
		"=" => Ada.Strings.Equal_Case_Insensitive);
	
	package Test_Sets renames String_CI_Sets;
	
	function Read_Test_Set (Name : String) return Test_Sets.Set is
	begin
		return Result : Test_Sets.Set do
			declare
				File : Ada.Text_IO.File_Type;
			begin
				Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Name);
				while not Ada.Text_IO.End_Of_File (File) loop
					declare
						Line : constant String := Ada.Text_IO.Get_Line (File);
					begin
						Test_Sets.Include (Result, Line);
					end;
				end loop;
				Ada.Text_IO.Close (File);
			end;
		end return;
	end Read_Test_Set;
	
	Tasking_Tests : constant Test_Sets.Set := Read_Test_Set ("x_tasking.txt");
	Unicode_Tests : constant Test_Sets.Set := Read_Test_Set ("x_unicode.txt");
	
	type Test_Style is (Legacy, Modern);
	
	type Test_Record is record
		Result : Test_Result;
		Expected : Boolean;
	end record;
	
	package Test_Records is new Ada.Containers.Indefinite_Ordered_Maps (
		String,
		Test_Record);
	
	Records: Test_Records.Map;
	
	procedure Test (
		Directory : in String;
		Name : in String;
		Style : in Test_Style)
	is
		In_Error_Class : constant Boolean := Is_Error_Class (Name);
		Spec : constant Ada_Spec := Ada_Spec_Of_Test (Name);
		Main : Ada.Strings.Unbounded.Unbounded_String;
		Link_With : Ada.Strings.Unbounded.Unbounded_String;
		UTF_8 : Boolean := False;
		procedure Process_Extract (Dir_Entry : in Ada.Directories.Directory_Entry_Type) is
			Simple_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
		begin
			if Simple_Name (Simple_Name'First) /= '.' then
				declare
					Extension : constant String := Ada.Directories.Extension (Simple_Name);
				begin
					if Ada.Strings.Equal_Case_Insensitive (Extension, "ada")
						or else Ada.Strings.Equal_Case_Insensitive (Extension, "dep")
						or else Ada.Strings.Equal_Case_Insensitive (Extension, "a")
					then
						declare
							Only_Pragmas : constant Boolean := Is_Only_Pragmas (Simple_Name);
						begin
							if Only_Pragmas then
								Symbolic_Link (
									Source => "../" & Ada.Directories.Compose (Directory, Simple_Name),
									Destination => "gnat.adc");
							else
								Chop (
									"../" & Ada.Directories.Compose (Directory, Simple_Name),
									Accept_Error => In_Error_Class);
							end if;
						end;
					elsif Ada.Strings.Equal_Case_Insensitive (Extension, "am") then
						Chop (
							"../" & Ada.Directories.Compose (Directory, Simple_Name),
							Accept_Error => In_Error_Class);
						declare
							Main_Name : constant String := Ada.Directories.Compose (
								Name => Ada.Directories.Base_Name (Simple_Name),
								Extension => "adb");
						begin
							if Ada.Directories.Exists (Main_Name) then
								Main := Ada.Strings.Unbounded.To_Unbounded_String (Main_Name);
							end if;
						end;
					elsif Ada.Strings.Equal_Case_Insensitive (Extension, "au") then
						UTF_8 := True;
						Chop (
							"../" & Ada.Directories.Compose (Directory, Simple_Name),
							Accept_Error => In_Error_Class);
					elsif Ada.Strings.Equal_Case_Insensitive (Extension, "tst") then
						declare
							Translated : constant String := Ada.Directories.Compose (
								Name => Ada.Directories.Base_Name (Simple_Name),
								Extension => "adt");
							File : Ada.Text_IO.File_Type;
						begin
							Ada.Text_IO.Create (File, Name => "TSTTESTS.DAT");
							Ada.Text_IO.Put_Line (File, Simple_Name);
							Ada.Text_IO.Close (File);
							Symbolic_Link (
								Source => "../" & Ada.Directories.Compose (Directory, Simple_Name),
								Destination => Simple_Name);
							Symbolic_Link (
								Source => "../gcc_support/MACRO.DFS",
								Destination => "MACRO.DFS");
							Shell_Execute (Ada.Directories.Compose (
								Containing_Directory => Ada.Directories.Compose ("..", Support_Dir),
								Name => "macrosub"));
						end;
						Chop (
							Ada.Directories.Compose (Name => Ada.Directories.Base_Name (Simple_Name), Extension => "adt"),
							Accept_Error => In_Error_Class);
					elsif Ada.Strings.Equal_Case_Insensitive (Extension, "c")
						or else Ada.Strings.Equal_Case_Insensitive (Extension, "cbl")
						or else Ada.Strings.Equal_Case_Insensitive (Extension, "ftn")
					then
						Symbolic_Link (
							Source => "../" & Ada.Directories.Compose (Directory, Simple_Name),
							Destination => Simple_Name);
						if not Skip_Compile (Name, Runtime) then
							Compile_Only (Simple_Name);
							if Link_With /= "" then
								Ada.Strings.Unbounded.Append (Link_With, " ");
							end if;
							Ada.Strings.Unbounded.Append (Link_With,
								Ada.Directories.Compose (
									Name => Ada.Directories.Base_Name (Simple_Name),
									Extension => "o"));
						end if;
					else
						raise Unknown with "unknown extension """ & Extension & """ of " & Simple_Name;
					end if;
				end;
			end if;
		end Process_Extract;
		Result : aliased Test_Result := Untested;
		Expected : Boolean := False;
	begin
		Ada.Text_IO.Put_Line ("**** " & Name & " ****");
		begin
			Setup_Test_Dir;
			Ada.Directories.Set_Directory (Test_Dir);
			Ada.Directories.Search (
				Directory => Start_Dir & "/" & Directory,
				Pattern => Name & "*",
				Filter => (others => True),
				Process => Process_Extract'Access);
			Adjust_After_Extract (Name);
			if In_Error_Class then
				declare
					package Library_Unit_Sets renames String_CI_Sets;
					Library_Units : Library_Unit_Sets.Set;
					procedure Process_Collect (Dir_Entry : in Ada.Directories.Directory_Entry_Type) is
						Simple_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
						File : Ada.Text_IO.File_Type;
					begin
						Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Simple_Name);
						while not Ada.Text_IO.End_Of_File (File) loop
							declare
								Separate_Word : constant String := "SEPARATE";
								Line : constant String := Ada.Text_IO.Get_Line (File);
							begin
								if Line'Length >= Separate_Word'Length
									and then Ada.Strings.Equal_Case_Insensitive (
										Line (Line'First .. Line'First + Separate_Word'Length - 1),
										Separate_Word)
								then
									return; -- separate unit is not a library unit
								end if;
							end;
						end loop;
						Ada.Text_IO.Close (File);
						declare
							Unit_Name : String := Ada.Directories.Base_Name (Simple_Name);
						begin
							for I in Unit_Name'Range loop
								if Unit_Name (I) = '-' then
									Unit_Name (I) := '.';
								end if;
							end loop;
							Library_Unit_Sets.Include (Library_Units, Unit_Name);
						end;
					end Process_Collect;
					File : Ada.Text_IO.File_Type;
					procedure Process_With (Position : in Library_Unit_Sets.Cursor) is
					begin
						Ada.Text_IO.Put_Line (File, "with " & Library_Unit_Sets.Element (Position) & ";");
					end Process_With;
				begin
					Ada.Directories.Search (
						Directory => ".", -- Test_Dir
						Pattern => "*.ad?",
						Filter => (Ada.Directories.Ordinary_File => True, others => False),
						Process => Process_Collect'Access);
					Ada.Text_IO.Create (File, Name => "main.adb");
					Library_Unit_Sets.Iterate (Library_Units, Process_With'Access);
					Ada.Text_IO.Put_Line (File, "procedure main is");
					Ada.Text_IO.Put_Line (File, "begin");
					Ada.Text_IO.Put_Line (File, "   null;");
					Ada.Text_IO.Put_Line (File, "end main;");
					Ada.Text_IO.Close (File);
					Compile ("main.adb",
						Spec => Spec,
						UTF_8 => UTF_8,
						RTS => RTS_Dir,
						Save_Log => True);
					Check_Log_In_Error_Class (Name);
					Result := Passed;
					Expected := True;
				exception
					when Command_Failure =>
						Check_Log_In_Error_Class (Name);
						Result := Passed;
						Expected := True;
				end;
			else
				if Main = "" then
					declare
						procedure Process_Find_Main (Dir_Entry : in Ada.Directories.Directory_Entry_Type) is
							Simple_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
							Base_Name : constant String := Ada.Directories.Base_Name (Simple_Name);
						begin
							if Ada.Strings.Equal_Case_Insensitive (Name, Base_Name)
								or else (Base_Name'Length > Name'Length
									and then Ada.Strings.Equal_Case_Insensitive (Name, Base_Name (1 .. Name'Length))
									and then (Base_Name (Base_Name'Last) = 'M' or else Base_Name (Base_Name'Last) = 'm'))
							then
								Main := Ada.Strings.Unbounded.To_Unbounded_String (Simple_Name);
							end if;
						end Process_Find_Main;
					begin
						Ada.Directories.Search (
							Directory => ".", -- Test_Dir
							Pattern => "*.adb",
							Filter => (Ada.Directories.Ordinary_File => True, others => False),
							Process => Process_Find_Main'Access);
					end;
				end if;
				if Skip_Compile (Name, Runtime) then
					Ada.Text_IO.Put_Line ("skip compiling...");
				else
					if Main = "" then
						raise Configuration_Error with "main subprogram is not found.";
					end if;
					Compile (
						+Main,
						Spec => Spec,
						Stack_Check => Stack_Check (Name),
						Overflow_Check => Overflow_Check (Name),
						Dynamic_Elaboration => Dynamic_Elaboration (Name),
						Link_With => +Link_With,
						RTS => RTS_Dir,
						UTF_8 => UTF_8);
					if Skip_Execute (Name, Runtime) then
						Ada.Text_IO.Put_Line ("skip executing...");
					else
						Invoke (
							Ada.Directories.Base_Name (+Main),
							Expected => Expected_Result (Name, Runtime),
							Result => Result'Access);
						Expected := True;
					end if;
				end if;
			end if;
		exception
			when E : Compile_Failure | Test_Failure | Should_Be_Failure =>
				Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (E));
				if Runtime = Drake then
					if Tasking_Tests.Contains (Name) then
						Ada.Text_IO.Put_Line ("tasking test failure.");
						Expected := True;
					elsif Unicode_Tests.Contains (Name) then
						Ada.Text_IO.Put_Line ("unicode test failure.");
						Expected := True;
					else
						Expected := False;
					end if;
				else
					Expected := False;
				end if;
		end;
		Test_Records.Include (Records, Name, Test_Record'(Result => Result, Expected => Expected));
		Ada.Directories.Set_Directory (Start_Dir);
		Ada.Text_IO.New_Line;
	end Test;
	
	Executed_Tests : Test_Sets.Set;
	
	type State_Type is (Skip, Run, Stop);
	State : State_Type;
	
	Continue_From : Ada.Strings.Unbounded.Unbounded_String;
	Run_Until : Ada.Strings.Unbounded.Unbounded_String;
	
	Report_File : Ada.Text_IO.File_Type;
	
	procedure Process_File (
		Directory : in String;
		Dir_Entry : in Ada.Directories.Directory_Entry_Type)
	is
		Simple_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
	begin
		if Simple_Name (Simple_Name'First) /= '.' then
			declare
				Base_Name : constant String := Ada.Directories.Base_Name (Simple_Name);
				Test_Name : String renames Base_Name (1 .. 7);
				Extension : constant String := Ada.Directories.Extension (Simple_Name);
				function Eq_Test_Name (S : String) return Boolean is
				begin
					return Ada.Strings.Equal_Case_Insensitive (S, Simple_Name)
						or else Ada.Strings.Equal_Case_Insensitive (S, Base_Name)
						or else Ada.Strings.Equal_Case_Insensitive (S, Test_Name);
				end Eq_Test_Name;
			begin
				if State = Skip and then Eq_Test_Name (+Continue_From) then
					State := Run;
				end if;
				if not Executed_Tests.Contains (Test_Name) then
					Test_Sets.Insert (Executed_Tests, Test_Name);
					if State = Run then
						if Ada.Strings.Equal_Case_Insensitive (Extension, "ada")
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "dep") -- implementation depending
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "tst") -- macro
						then
							Test (Directory, Test_Name, Legacy);
						elsif Ada.Strings.Equal_Case_Insensitive (Extension, "a")
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "am") -- main of multiple source
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "au") -- UTF-8
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "c") -- C source
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "cbl") -- COBOL source
							or else Ada.Strings.Equal_Case_Insensitive (Extension, "ftn") -- Fortran source
						then
							Test (Directory, Test_Name, Modern);
						else
							raise Unknown with "unknown extension """ & Extension & """ of " & Simple_Name;
						end if;
					else
						if not Records.Contains (Test_Name) then
							Test_Records.Include (
								Records,
								Test_Name,
								Test_Record'(Result => Untested, Expected => False));
						end if;
					end if;
					declare
						R : Test_Record renames Test_Records.Element (Records, Test_Name);
						RI : array (Test_Result) of Character := "PANTFU";
						XO : array (Boolean) of Character := "XO";
					begin
						Ada.Text_IO.Put_Line (
							Report_File,
							Test_Name & ' ' & RI (R.Result) & ' ' & XO (R.Expected));
					end;
				end if;
				if State = Run and then Eq_Test_Name (+Run_Until) then
					State := Stop;
				end if;
			end;
		end if;
	end Process_File;
	
	procedure Process_Dir (Dir_Entry : in Ada.Directories.Directory_Entry_Type) is
		Simple_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
	begin
		if Simple_Name (Simple_Name'First) /= '.'
			and then not Ada.Strings.Equal_Case_Insensitive (Simple_Name, "docs")
			and then not Ada.Strings.Equal_Case_Insensitive (Simple_Name, "support")
		then
			declare
				Directory : constant String := Ada.Directories.Compose (
					Containing_Directory => ACATS_Dir,
					Name => Simple_Name);
				procedure Process (Dir_Entry : in Ada.Directories.Directory_Entry_Type) is
				begin
					Process_File (Directory, Dir_Entry);
				end Process;
			begin
				Ada.Directories.Search (
					Directory => Ada.Directories.Full_Name (Dir_Entry),
					Pattern => "*",
					Filter => (others => True),
					Process => Process'Access);
			end;
		end if;
	end Process_Dir;
	
begin
	if Ada.Command_Line.Argument_Count < 1 then
		State := Run;
	else
		State := Skip;
		Continue_From := Ada.Strings.Unbounded.To_Unbounded_String (Ada.Command_Line.Argument (1));
		if Ada.Command_Line.Argument_Count < 2 then
			Run_Until := Continue_From;
		elsif Ada.Command_Line.Argument (2) = ".." then
			Run_Until := Ada.Strings.Unbounded.Null_Unbounded_String;
		else
			Run_Until := Ada.Strings.Unbounded.To_Unbounded_String (Ada.Command_Line.Argument (2));
		end if;
	end if;
	begin
		Ada.Text_IO.Open (Report_File, Ada.Text_IO.In_File, Name => "result.txt");
		Ada.Text_IO.Put ("reading result.txt...");
		while not Ada.Text_IO.End_Of_File (Report_File) loop
			declare
				Line : constant String := Ada.Text_IO.Get_Line (Report_File);
				Result : Test_Result;
				Expected : Boolean;
			begin
				if Line (8) /= ' ' or else Line (10) /= ' ' then
					raise Ada.Text_IO.Data_Error with Line;
				end if;
				case Line (9) is
					when 'P' => Result := Passed;
					when 'A' => Result := Any_Exception;
					when 'N' => Result := Not_Applicative;
					when 'T' => Result := Tentatively;
					when 'F' => Result := Failed;
					when 'U' => Result := Untested;
					when others => raise Ada.Text_IO.Data_Error with Line;
				end case;
				case Line (11) is
					when 'X' => Expected := False;
					when 'O' => Expected := True;
					when others => raise Ada.Text_IO.Data_Error with Line;
				end case;
				Test_Records.Include (
					Records,
					Line (1 .. 7),
					Test_Record'(Result => Result, Expected => Expected));
			end;
		end loop;
		Ada.Text_IO.Close (Report_File);
		Ada.Text_IO.Put_Line ("done.");
	exception
		when Ada.Text_IO.Name_Error => null;
	end;
	Ada.Text_IO.Create (Report_File, Name => "result.txt");
	Ada.Directories.Search (
		Directory => ACATS_Dir,
		Pattern => "*",
		Filter => (Ada.Directories.Directory => True, others => False),
		Process => Process_Dir'Access);
	Ada.Text_IO.Close (Report_File);
	if State = Run then
		Ada.Text_IO.Put_Line ("**** complete ****");
	end if;
end run_acats;
