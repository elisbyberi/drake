pragma License (Unrestricted);
--  implementation unit
with Ada.Streams.Stream_IO.Inside.Standard_Files;
package Ada.Text_IO.Inside is

   --  handle of stream

   procedure Open (
      File : in out File_Type;
      Stream : Streams.Stream_IO.Stream_Access;
      Mode : File_Mode;
      Name : String := "";
      Form : String := "");

   function Stream (File : File_Type) return Streams.Stream_IO.Stream_Access;
   pragma Inline (Stream);
   function Stream_IO (File : File_Type)
      return not null access Streams.Stream_IO.Inside.Non_Controlled_File_Type;
   pragma Inline (Stream_IO);

   --  non-controlled

   type Text_Type (<>) is limited private;
   type Non_Controlled_File_Type is access all Text_Type;

   type Encoding_Type is (
      Locale, -- Is_Terminal = False
      Terminal, -- Is_Terminal = True
      UTF_8);
   pragma Discard_Names (Encoding_Type);

   procedure Create (
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode := Out_File;
      Name : String := "";
      Form : String := "");
   procedure Open (
      File : in out Non_Controlled_File_Type;
      Mode : File_Mode;
      Name : String;
      Form : String := "");

   procedure Close (
      File : in out Non_Controlled_File_Type;
      Raise_On_Error : Boolean := True);
   procedure Delete (File : in out Non_Controlled_File_Type);
   procedure Reset (
      File : not null access Non_Controlled_File_Type;
      Mode : File_Mode);

   function Mode (File : Non_Controlled_File_Type) return File_Mode;
   function Name (File : Non_Controlled_File_Type) return String;
   function Form (File : Non_Controlled_File_Type) return String;

   function Encoding (File : Non_Controlled_File_Type) return Encoding_Type;
   pragma Inline (Encoding);

   function Is_Open (File : Non_Controlled_File_Type) return Boolean;
   pragma Inline (Is_Open);

   procedure Flush (File : Non_Controlled_File_Type);

   procedure Set_Size (
      File : Non_Controlled_File_Type;
      Line_Length, Page_Length : Count);

   procedure Set_Line_Length (File : Non_Controlled_File_Type; To : Count);
   procedure Set_Page_Length (File : Non_Controlled_File_Type; To : Count);

   procedure Size (
      File : Non_Controlled_File_Type;
      Line_Length, Page_Length : out Count);

   function Line_Length (File : Non_Controlled_File_Type) return Count;
   pragma Inline (Line_Length);
   function Page_Length (File : Non_Controlled_File_Type) return Count;
   pragma Inline (Page_Length);

   procedure New_Line (
      File : Non_Controlled_File_Type;
      Spacing : Positive_Count := 1);
   procedure Skip_Line (
      File : Non_Controlled_File_Type;
      Spacing : Positive_Count := 1);

   function End_Of_Line (File : Non_Controlled_File_Type) return Boolean;

   procedure New_Page (File : Non_Controlled_File_Type);
   procedure Skip_Page (File : Non_Controlled_File_Type);

   function End_Of_Page (File : Non_Controlled_File_Type) return Boolean;
   function End_Of_File (File : Non_Controlled_File_Type) return Boolean;

   procedure Set_Position_Within_Terminal (
      File : Non_Controlled_File_Type;
      Col, Line : Count);
   procedure Set_Col_Within_Terminal (
      File : Non_Controlled_File_Type;
      To : Count);

   procedure Set_Col (File : Non_Controlled_File_Type; To : Positive_Count);
   procedure Set_Line (File : Non_Controlled_File_Type; To : Positive_Count);

   procedure Position (
      File : Non_Controlled_File_Type;
      Col, Line : out Positive_Count);

   function Col (File : Non_Controlled_File_Type) return Positive_Count;
   pragma Inline (Col);
   function Line (File : Non_Controlled_File_Type) return Positive_Count;
   pragma Inline (Line);
   function Page (File : Non_Controlled_File_Type) return Positive_Count;
   pragma Inline (Page);

   procedure Get (File : Non_Controlled_File_Type; Item : out Character);
   procedure Put (File : Non_Controlled_File_Type; Item : Character);

   procedure Look_Ahead (
      File : Non_Controlled_File_Type;
      Item : out Character;
      End_Of_Line : out Boolean);

   procedure Get_Immediate (
      File : Non_Controlled_File_Type;
      Item : out Character);

   procedure Get_Immediate (
      File : Non_Controlled_File_Type;
      Item : out Character;
      Available : out Boolean);

   procedure View (
      File : Non_Controlled_File_Type;
      Left, Top : out Positive_Count;
      Right, Bottom : out Count);

   --  handle of stream for non-controlled

   procedure Open (
      File : in out Non_Controlled_File_Type;
      Stream : Streams.Stream_IO.Stream_Access;
      Mode : File_Mode;
      Name : String := "";
      Form : String := "");

   function Stream (File : Non_Controlled_File_Type)
      return Streams.Stream_IO.Stream_Access;
   function Stream_IO (File : Non_Controlled_File_Type)
      return not null access Streams.Stream_IO.Inside.Non_Controlled_File_Type;

   --  standard I/O

   Standard_Input : constant Non_Controlled_File_Type;
   Standard_Output : constant Non_Controlled_File_Type;
   Standard_Error : constant Non_Controlled_File_Type;

   --  form parameter

   type Line_Mark_Type is (LF, CR, CRLF);
   pragma Discard_Names (Line_Mark_Type);

   function Form_Encoding (Form : String) return Encoding_Type;
   function Form_Line_Mark (Form : String) return Line_Mark_Type;
   function Form_SUB (Form : String) return Boolean;

private

   type Dummy_Mark_Type is (None, EOP, EOP_EOF, EOF);
   pragma Discard_Names (Dummy_Mark_Type);

   type Text_Type (
      Name_Length : Natural;
      Form_Length : Natural) is limited
   record
      Stream : Streams.Stream_IO.Stream_Access; -- internal stream
      File : aliased Streams.Stream_IO.Inside.Non_Controlled_File_Type;
      Page : Count := 1;
      Line : Count := 1;
      Col : Count := 1;
      Line_Length : Count := 0;
      Page_Length : Count := 0;
      Buffer_Col : Count := 0; -- converted length
      Last : Natural := 0;
      Buffer : String (1 .. 12); -- 2 code-points of UTF-8
      Converted : Boolean := False;
      End_Of_File : Boolean := False;
      Dummy_Mark : Dummy_Mark_Type := None;
      Mode : File_Mode;
      Encoding : Encoding_Type;
      Line_Mark : Line_Mark_Type;
      SUB : Boolean; -- ASCII.SUB = 16#1A#
      Name : String (1 .. Name_Length);
      Form : String (1 .. Form_Length);
   end record;
   pragma Suppress_Initialization (Text_Type);

   Standard_Input_Text : aliased Text_Type := (
      Name_Length => 0,
      Form_Length => 0,
      Stream => Streams.Stream_IO.Inside.Stream (
         Streams.Stream_IO.Inside.Standard_Files.Standard_Input),
      File => Streams.Stream_IO.Inside.Standard_Files.Standard_Input,
      Mode => In_File,
      Encoding => Encoding_Type'Val (Boolean'Pos (
         Streams.Stream_IO.Inside.Is_Terminal (
            Streams.Stream_IO.Inside.Handle (
               Streams.Stream_IO.Inside.Standard_Files.Standard_Input)))),
      Line_Mark => CRLF,
      others => <>);

   Standard_Output_Text : aliased Text_Type := (
      Name_Length => 0,
      Form_Length => 0,
      Stream => Streams.Stream_IO.Inside.Stream (
         Streams.Stream_IO.Inside.Standard_Files.Standard_Output),
      File => Streams.Stream_IO.Inside.Standard_Files.Standard_Output,
      Mode => Out_File,
      Encoding => Encoding_Type'Val (Boolean'Pos (
         Streams.Stream_IO.Inside.Is_Terminal (
            Streams.Stream_IO.Inside.Handle (
               Streams.Stream_IO.Inside.Standard_Files.Standard_Output)))),
      Line_Mark => CRLF,
      others => <>);

   Standard_Error_Text : aliased Text_Type := (
      Name_Length => 0,
      Form_Length => 0,
      Stream => Streams.Stream_IO.Inside.Stream (
         Streams.Stream_IO.Inside.Standard_Files.Standard_Error),
      File => Streams.Stream_IO.Inside.Standard_Files.Standard_Error,
      Mode => Out_File,
      Encoding => Encoding_Type'Val (Boolean'Pos (
         Streams.Stream_IO.Inside.Is_Terminal (
            Streams.Stream_IO.Inside.Handle (
               Streams.Stream_IO.Inside.Standard_Files.Standard_Error)))),
      Line_Mark => CRLF,
      others => <>);

   Standard_Input : constant Non_Controlled_File_Type :=
      Standard_Input_Text'Access;
   Standard_Output : constant Non_Controlled_File_Type :=
      Standard_Output_Text'Access;
   Standard_Error : constant Non_Controlled_File_Type :=
      Standard_Error_Text'Access;

   --  for Wide_Text_IO/Wide_Wide_Text_IO

   procedure Look_Ahead (
      File : Non_Controlled_File_Type;
      Item : out String; -- 1 .. 6
      Last : out Natural;
      End_Of_Line : out Boolean);
   procedure Get_Immediate (
      File : Non_Controlled_File_Type;
      Item : out String; -- 1 .. 6
      Last : out Natural;
      Wait : Boolean);

end Ada.Text_IO.Inside;
