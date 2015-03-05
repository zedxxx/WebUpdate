unit WebUpdate.GUI.Options;

interface

uses
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  ComCtrls,
  VirtualTrees;

type
  TOptionsItem = record
    TabSheet: TTabSheet;
  end;
  POptionsItem = ^TOptionsItem;

  TfrmOptions = class(TForm)
    ButtonCancel: TButton;
    ButtonOK: TButton;
    CheckBoxAutoCopyUpload: TCheckBox;
    CheckBoxCopyTo: TCheckBox;
    EditCopyPath: TEdit;
    EditFtpPassword: TEdit;
    EditFtpServer: TEdit;
    EditFtpUsername: TEdit;
    GroupBoxCopy: TGroupBox;
    GroupBoxFTP: TGroupBox;
    LabelChannelFileName: TLabel;
    LabelFileName: TLabel;
    LabelPassword: TLabel;
    LabelServer: TLabel;
    LabelUsername: TLabel;
    PageControl: TPageControl;
    Panel: TPanel;
    TabSheetFTP: TTabSheet;
    TabSheetMain: TTabSheet;
    TreeOptions: TVirtualStringTree;
    CheckBoxMD5: TCheckBox;
    dlgOpenChannelFile: TOpenDialog;
    edtBaseDir: TEdit;
    btnBaseDir: TButton;
    edtChannelFile: TEdit;
    btnChannelFile: TButton;
    procedure FormCreate(Sender: TObject);
    procedure TreeOptionsGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
    procedure TreeOptionsChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btnBaseDirClick(Sender: TObject);
    procedure btnChannelFileClick(Sender: TObject);
  private
    procedure SetupTree;
  end;

implementation

uses
  {$WARN UNIT_PLATFORM OFF}
  FileCtrl;
  {$WARN UNIT_PLATFORM ON}

{$R *.dfm}

{ TFormOptions }

procedure TfrmOptions.btnBaseDirClick(Sender: TObject);
var
  VBaseDir: string;
begin
  VBaseDir := edtBaseDir.Text;
  if SelectDirectory('Select a directory', '', VBaseDir, []) then begin
    edtBaseDir.Text := VBaseDir;
  end;
end;

procedure TfrmOptions.btnChannelFileClick(Sender: TObject);
begin
  if dlgOpenChannelFile.Execute then begin
    edtChannelFile.Text := dlgOpenChannelFile.FileName;
  end;
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  TreeOptions.NodeDataSize := SizeOf(TOptionsItem);
  SetupTree;
  PageControl.ActivePageIndex := 0;
end;

procedure TfrmOptions.TreeOptionsChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  NodeData: POptionsItem;
begin
  if Assigned(Node) then
  begin
    NodeData := TreeOptions.GetNodeData(Node);
    PageControl.ActivePage := NodeData^.TabSheet;
  end;
end;

procedure TfrmOptions.TreeOptionsGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
var
  NodeData: POptionsItem;
begin
  NodeData := TreeOptions.GetNodeData(Node);
  CellText := NodeData^.TabSheet.Caption;
end;

procedure TfrmOptions.SetupTree;
var
  Node: PVirtualNode;
  NodeData: POptionsItem;
  Index: Integer;
begin
  for Index := 0 to PageControl.PageCount - 1 do begin
    Node := TreeOptions.AddChild(TreeOptions.RootNode);
    NodeData := TreeOptions.GetNodeData(Node);
    NodeData^.TabSheet := PageControl.Pages[Index];
    if Index = 0 then begin
      TreeOptions.Selected[Node] := True;
    end else begin
      TreeOptions.Selected[Node] := False;
    end;
  end;
end;

end.
