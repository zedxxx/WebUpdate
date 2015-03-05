unit WebUpdate.GUI.Main;

interface

uses
  Types,
  SysUtils,
  Classes,
  Windows,
  Controls,
  Forms,
  Dialogs,
  ComCtrls,
  Menus,
  ActnList,
  StdActns,
  ExtCtrls,
  ImgList,
  ToolWin,
  IdComponent,
  VirtualTrees,
  WebUpdate.JSON.Preferences,
  WebUpdate.JSON.Project,
  WebUpdate.JSON.Channels,
  WebUpdate.JSON.Channel;

type
  TChannelItem = record
    Name: string;
    FileName: TFileName;
    Modified: TDateTime;
  end;
  PChannelItem = ^TChannelItem;

  TFileItem = record
    FileName: string;
    Hash: Cardinal;
    WebFileName: string;
    Caption: string;
    Modified: TDateTime;
    Size: Integer;
  end;
  PFileItem = ^TFileItem;

  TfrmMain = class(TForm)
    ActionAddChannel: TAction;
    ActionClearAll: TAction;
    ActionCopyUpload: TAction;
    ActionDeleteChannel: TAction;
    ActionDocumentation: TAction;
    ActionFileExit: TFileExit;
    ActionFileOpen: TFileOpen;
    ActionFileOptions: TAction;
    ActionFileSave: TAction;
    ActionFileSaveAs: TFileSaveAs;
    ActionHelpAbout: TAction;
    ActionList: TActionList;
    ActionScanFiles: TAction;
    ActionTakeSnapshot: TAction;
    ActionViewChannel: TAction;
    Images: TImageList;
    MainMenu: TMainMenu;
    MenuItemCheckAll: TMenuItem;
    MenuItemCheckNone: TMenuItem;
    MenuItemClearAll: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemFileOpen: TMenuItem;
    MenuItemFileSave: TMenuItem;
    MenuItemHelp: TMenuItem;
    MenuItemHelpAbout: TMenuItem;
    MenuItemHelpDocumentation: TMenuItem;
    MenuItemProjectOptions: TMenuItem;
    MenuItemSaveAs: TMenuItem;
    MenuItemsViewChannelFiles: TMenuItem;
    MenuItemView: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    PanelChannels: TPanel;
    PanelFiles: TPanel;
    PopupMenu: TPopupMenu;
    ProgressBar: TProgressBar;
    MenuItemScanDirectoriesFiles: TMenuItem;
    Separator1: TToolButton;
    Separator2: TToolButton;
    Splitter: TSplitter;
    StatusBar: TStatusBar;
    ToolBarChannels: TToolBar;
    ToolButtonChannelsAdd: TToolButton;
    ToolButtonChannelsDelete: TToolButton;
    ToolButtonChannelsStore: TToolButton;
    ToolButtonCopyUpload: TToolButton;
    ToolButtonScanFiles: TToolButton;
    TreeChannels: TVirtualStringTree;
    TreeFileList: TVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActionAddChannelExecute(Sender: TObject);
    procedure ActionCopyUploadExecute(Sender: TObject);
    procedure ActionDeleteChannelExecute(Sender: TObject);
    procedure ActionFileOpenAccept(Sender: TObject);
    procedure ActionFileOptionsExecute(Sender: TObject);
    procedure ActionFileSaveAsAccept(Sender: TObject);
    procedure ActionFileSaveExecute(Sender: TObject);
    procedure ActionScanFilesExecute(Sender: TObject);
    procedure ActionTakeSnapshotExecute(Sender: TObject);
    procedure ActionViewChannelExecute(Sender: TObject);
    procedure MenuItemCheckAllClick(Sender: TObject);
    procedure MenuItemCheckNoneClick(Sender: TObject);
    procedure TreeChannelsFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeFileListChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);

    procedure TreeChannelsChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeFileListFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);

    procedure TreeFileListGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure TreeFileListCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure ActionHelpAboutExecute(Sender: TObject);
    procedure ActionDocumentationExecute(Sender: TObject);

    procedure TreeChannelsGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
    procedure TreeChannelsNewText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex;
      NewText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
    procedure TreeFileListGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
    procedure TreeChannelsChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FAppPath: string;
    FAppName: string;
    FProject: TWebUpdateProject;
    FProjectFile: string;
    FChannels: TWebUpdateChannels;
    FPreferences: TWebUpdatePreferences;
    FProjectModified: Boolean;

    procedure ClearStatus;
    procedure WriteStatus(Text: string);

    function LocateNode(RootNode: PVirtualNode; Caption: string): PVirtualNode;
    function CreateNode(FileStrings: TStringDynArray): PVirtualNode;
    function GetCurrentChannelNodeData: PChannelItem;

    procedure CollectFileProgressEventHandler(const Directory: string; var SkipScan: Boolean);

    procedure StatusEventHandler(ASender: TObject; const AStatus: TIdStatus; const AStatusText: String);
    procedure WorkBeginEventHandler(Sender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND});
    procedure WorkEndEventHandler(Sender: TObject; AWorkMode: TWorkMode);
    procedure WorkEventHandler(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND});
    procedure SetCurrentChannelName(const Value: string);
    function GetCurrentChannelName: string;
  protected
    procedure SetupDefaultChannels;
    function LoadChannels: Boolean;
    procedure SaveChannels;
  public
    procedure ScanDirectory;
    procedure TakeSnapshot;
    procedure UploadSnapshot;
    procedure CopySnapshot;

    property Project: TWebUpdateProject read FProject;
    property CurrentChannelName: string read GetCurrentChannelName write SetCurrentChannelName;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  ShellApi,
  CommCtrl,
  IdFtp, StrUtils,
  WebUpdate.GUI.Options,
  WebUpdate.GUI.About,
  WebUpdate.JSON.Serializer,
  WebUpdate.Tools;

resourcestring
  RStrFileNotFound = 'File %s not found';
  RStrNoFileSelected = 'No file selected for update!';
  RStrSavingChannelSetup = 'Saving channel setup...';

function SimpleStringHash(const s: string): Cardinal; inline;
var
   i : Integer;
begin
   // modified FNV-1a using length as seed
   Result:=Length(s);
   for i:=1 to Result do
      Result:=(Result xor Ord(s[i]))*16777619;
end;

{ TFormWebUpdateTool }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ProgressBarStyle: Integer;
  PanelRect: TRect;
begin
  FAppPath := ExtractFilePath(ParamStr(0));

  // specify node data sizes
  TreeChannels.NodeDataSize := SizeOf(TChannelItem);
  TreeFileList.NodeDataSize := SizeOf(TFileItem);

  // create preferences
  FPreferences := TWebUpdatePreferences.Create(FAppPath + 'Preferences.json');

  // create project
  FProject := TWebUpdateProject.Create;

  // create channels
  FChannels := TWebUpdateChannels.Create;

  ProgressBar.Parent := StatusBar;
  SendMessage(StatusBar.Handle, SB_GETRECT, 0, Integer(@PanelRect));
  with PanelRect do
    ProgressBar.SetBounds(Left, Top, Right - Left, Bottom - Top);

  ProgressBarStyle := GetWindowLong(ProgressBar.Handle, GWL_EXSTYLE);
  ProgressBarStyle := ProgressBarStyle - WS_EX_STATICEDGE;
  SetWindowLong(ProgressBar.Handle, GWL_EXSTYLE, ProgressBarStyle);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FChannels.Free;
  FProject.Free;
  FPreferences.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FProjectFile := FPreferences.RecentProject;

  // eventually load or setup project
  if FileExists(FProjectFile) then begin
    FProject.LoadFromFile(FProjectFile);
  end else begin
    // set default values
    FProject.BaseDirectory := '';
    FProject.ChannelsFilename := 'WebUpdate\Channels.json';
    FProjectFile := FAppPath + 'NoName.wup';
  end;

  FProject.LocalPath := ExtractFilePath(FProjectFile);

  // load/setup channels
  if not LoadChannels then
    SetupDefaultChannels;

  ActionCopyUpload.Visible := not Project.AutoCopyUpload;
  ActionViewChannel.Checked := FPreferences.ViewFiles;
  ActionViewChannelExecute(Sender);

  Caption := Caption + ' - ' + ExtractFileName(FProjectFile);
end;

procedure TfrmMain.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FPreferences.Left := Left;
  FPreferences.Top := Top;
  FPreferences.ViewFiles := ActionViewChannel.Checked;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if FProjectModified then
    CanClose := MessageDlg('Project has been modified, but not saved yet!' +
      #13#10#13#10 + 'Do you really want to close the application without saving?',
      mtInformation, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmMain.GetCurrentChannelName: string;
begin
  Result := FProject.ChannelName;
end;

function TfrmMain.GetCurrentChannelNodeData: PChannelItem;
var
  Node: PVirtualNode;
  NodeData: PChannelItem;
  ChannelName: string;
begin
  Result := nil;

  ChannelName := FProject.ChannelName;

  // get FCurrentChannel node
  for Node in TreeChannels.Nodes do
  begin
    NodeData := TreeChannels.GetNodeData(Node);
    if SameText(NodeData^.Name, ChannelName) then begin
      Result := TreeChannels.GetNodeData(Node);
      Exit;
    end;
  end;

  // get currently checked node
  for Node in TreeChannels.CheckedNodes do begin
    Result := TreeChannels.GetNodeData(Node);
    Exit;
  end;
end;

procedure TfrmMain.ActionAddChannelExecute(Sender: TObject);
var
  Node: PVirtualNode;
  NodeData: PChannelItem;
begin
  Node := TreeChannels.AddChild(TreeChannels.RootNode);
  Node.CheckType := ctRadioButton;
  NodeData := TreeChannels.GetNodeData(Node);
  NodeData^.Name := 'Unknown';
  NodeData^.FileName := NodeData^.Name + '.json';
  FileAge(NodeData^.FileName, NodeData^.Modified);
end;

procedure TfrmMain.ActionDeleteChannelExecute(Sender: TObject);
begin
  if Assigned(TreeChannels.FocusedNode) then
    TreeChannels.DeleteNode(TreeChannels.FocusedNode);
end;

procedure TfrmMain.ActionDocumentationExecute(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', PChar((FAppPath) + 'Documentation.pdf'),
    nil, PChar(FAppPath), SW_SHOW);
end;

procedure TfrmMain.ActionCopyUploadExecute(Sender: TObject);
begin
  UploadSnapshot;
  CopySnapshot;
end;

procedure TfrmMain.ActionFileOpenAccept(Sender: TObject);
var
  FileName: TFileName;
begin
  Assert(Sender is TFileOpen);

  // get file name and exit if not exists
  FileName := TFileOpen(Sender).Dialog.FileName;
  if not FileExists(FileName) then
    Exit;

  FProject.LoadFromFile(FileName);
  FPreferences.RecentProject := FileName;
end;

procedure TfrmMain.ActionFileSaveAsAccept(Sender: TObject);
var
  FileName: TFileName;
begin
  Assert(Sender is TFileSaveAs);
  FileName := TFileSaveAs(Sender).Dialog.FileName;
  FProject.SaveToFile(FileName);
  FProjectModified := False;
  FPreferences.RecentProject := FileName;
end;

procedure TfrmMain.ActionFileSaveExecute(Sender: TObject);
begin
  if FPreferences.RecentProject <> '' then
  begin
    FProject.SaveToFile(FPreferences.RecentProject);
    FProjectModified := False;
  end;
end;

procedure TfrmMain.ActionHelpAboutExecute(Sender: TObject);
begin
  with TfrmAbout.Create(Self) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TfrmMain.ActionTakeSnapshotExecute(Sender: TObject);
begin
  TakeSnapshot;
end;

procedure TfrmMain.ActionViewChannelExecute(Sender: TObject);
begin
  if ActionViewChannel.Checked then
  begin
    TreeFileList.Visible := True;
    PanelChannels.Align := alTop;
    PanelChannels.Height := 128;
    Splitter.Visible := True;
    Splitter.Top := PanelChannels.Height;
  end
  else
  begin
    TreeFileList.Visible := False;
    Splitter.Visible := False;
    PanelChannels.Align := alClient;
  end;
end;

procedure TfrmMain.ActionFileOptionsExecute(Sender: TObject);
begin
  with TfrmOptions.Create(Self) do
  try
    edtBaseDir.Text := FProject.BaseDirectory;
    edtChannelFile.Text :=  FProject.ChannelsFilename;
    EditFtpServer.Text := FProject.FTP.Server;
    EditFtpUsername.Text := FProject.FTP.Username;
    EditFtpPassword.Text := FProject.FTP.Password;
    CheckBoxAutoCopyUpload.Checked := FProject.AutoCopyUpload;
    CheckBoxCopyTo.Checked := FProject.Copy.Enabled;
    CheckBoxMD5.Checked := FProject.UseMD5;
    EditCopyPath.Text := FProject.Copy.Path;

    if ShowModal = mrOk then begin
      FProject.BaseDirectory := edtBaseDir.Text;
      FProject.ChannelsFilename := edtChannelFile.Text;
      FProject.UseMD5 := CheckBoxMD5.Checked;
      FProject.FTP.Server := EditFtpServer.Text;
      FProject.FTP.Username := EditFtpUsername.Text;
      FProject.FTP.Password := EditFtpPassword.Text;
      FProject.AutoCopyUpload := CheckBoxAutoCopyUpload.Checked;
      FProject.Copy.Enabled := CheckBoxCopyTo.Checked;
      FProject.Copy.Path := EditCopyPath.Text;

      FProjectModified := True;

      ActionCopyUpload.Visible := not FProject.AutoCopyUpload;
    end;
  finally
    Free;
  end;
end;

procedure TfrmMain.ActionScanFilesExecute(Sender: TObject);
begin
  ScanDirectory;
end;

procedure TfrmMain.CollectFileProgressEventHandler(const Directory: string;
  var SkipScan: Boolean);
begin
  WriteStatus('Scanning: ' + Directory);
  SkipScan := False;
end;

procedure TfrmMain.ScanDirectory;
var
  VBasePath: string;
  FileStrings: Types.TStringDynArray;
  FileList: TStringList;
  FileName: TFileName;
  WebFileName: string;
  Node: PVirtualNode;
  NodeData: PFileItem;
  Fad: TWin32FileAttributeData;
begin
  TreeFileList.Clear;

  VBasePath := FProject.BasePath + FProject.ChannelName + PathDelim;

  TreeFileList.BeginUpdate;
  try
    FileList := TStringList.Create;
    try
      CollectFiles(VBasePath, '*.*', FileList, True, CollectFileProgressEventHandler);

      WriteStatus('Building tree...');

      for FileName in FileList do
      begin
        WebFileName := ExtractRelativePath(VBasePath, FileName);
        FileStrings := SplitString(WebFileName, '\');

        Node := CreateNode(FileStrings);
        NodeData := TreeFileList.GetNodeData(Node);
        NodeData^.FileName := FileName;
        NodeData^.WebFileName := LocalToWebFileName(WebFileName);
        NodeData^.Caption := FileStrings[High(FileStrings)];
        NodeData^.Hash := SimpleStringHash(NodeData^.Caption);

        if not GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @Fad) then
          RaiseLastOSError;

        NodeData^.Size := Fad.nFileSizeLow;
        NodeData^.Modified := FileTimeToDateTime(Fad.ftLastWriteTime);
      end;
    finally
      FileList.Free;
    end;

    MenuItemCheckAllClick(Self);

    WriteStatus('Sorting tree...');

    TreeFileList.SortTree(0, sdAscending);
  finally
    TreeFileList.EndUpdate;
  end;

  ClearStatus;
end;

function TfrmMain.LocateNode(RootNode: PVirtualNode; Caption: string): PVirtualNode;
var
  Node: PVirtualNode;
  NodeData: PFileItem;
  Hash: Cardinal;
begin
  Hash := SimpleStringHash(Caption);
  for Node in TreeFileList.ChildNodes(RootNode) do
  begin
    NodeData := TreeFileList.GetNodeData(Node);
    if NodeData.Hash = Hash then
      if SameText(NodeData.Caption, Caption) then begin
        Result := Node;
        Exit;
      end;
  end;

  // node not found -> create!
  Result := TreeFileList.AddChild(RootNode);
  Result.CheckType := ctCheckBox;
  NodeData := TreeFileList.GetNodeData(Result);
  NodeData^.Caption := Caption;
  NodeData^.Hash := Hash;
end;

procedure TfrmMain.MenuItemCheckAllClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  for Node in TreeFileList.Nodes do
    TreeFileList.CheckState[Node] := csCheckedNormal;
end;

procedure TfrmMain.MenuItemCheckNoneClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  for Node in TreeFileList.Nodes do
    TreeFileList.CheckState[Node] := csUncheckedNormal;
end;

function TfrmMain.CreateNode(FileStrings: Types.TStringDynArray): PVirtualNode;
var
  Level: Integer;
begin
  Result := TreeFileList.RootNode;
  for Level := 0 to High(FileStrings) do
    Result := LocateNode(Result, FileStrings[Level]);
end;

function TfrmMain.LoadChannels: Boolean;
var
  I: Integer;
  Node: PVirtualNode;
  NodeData: PChannelItem;
  ChannelItem: TWebUpdateChannelItem;
  FileName: string;
begin
  Result := False;

  // get channels file name
  FileName := FProject.FullChannelsFilename;

  if not FileExists(FileName) then begin
    Exit;
  end;

  // load channels from file
  FChannels.LoadFromFile(FileName);

  // clear channel tree
  TreeChannels.Clear;

  TreeChannels.BeginUpdate;
  try
    // enumerate channel item
    for I := 0 to FChannels.Items.Count - 1 do begin
      ChannelItem := TWebUpdateChannelItem(FChannels.Items[I]);

      Node := TreeChannels.AddChild(TreeChannels.RootNode);
      Node.CheckType := ctRadioButton;
      NodeData := TreeChannels.GetNodeData(Node);

      NodeData^.Name := ChannelItem.Name;
      NodeData^.FileName := ChannelItem.FileName;
      NodeData^.Modified := ChannelItem.Modified;

      // update check state
      if SameText(ChannelItem.Name, FProject.ChannelName) then
        TreeChannels.CheckState[Node] := csCheckedNormal;
    end;
  finally
    TreeChannels.EndUpdate;
  end;

  Result := (FChannels.Items.Count > 0);
end;

procedure TfrmMain.SaveChannels;
var
  Node: PVirtualNode;
  NodeChannelData: PChannelItem;
  ChannelItem: TWebUpdateChannelItem;
begin
  // now save channels file
  WriteStatus('Save channels file...');

  // clear existing channels
  FChannels.Items.Clear;

  // enumerate nodes
  TreeChannels.BeginUpdate;
  try
    for Node in TreeChannels.Nodes do
    begin
      NodeChannelData := TreeChannels.GetNodeData(Node);

      ChannelItem := TWebUpdateChannelItem.Create;
      ChannelItem.Name := NodeChannelData^.Name;
      ChannelItem.FileName := NodeChannelData^.FileName;
      ChannelItem.Modified := NodeChannelData^.Modified;

      // eventually create MD5 checksum
      if FProject.UseMD5 and FileExists(ChannelItem.FileName) then
        ChannelItem.MD5 := MD5(ChannelItem.FileName);

      FChannels.Items.Add(ChannelItem);
    end;
  finally
    TreeChannels.EndUpdate;
  end;
  FChannels.SaveToFile(FProject.FullChannelsFilename);
end;

procedure TfrmMain.SetCurrentChannelName(const Value: string);
var
  Node: PVirtualNode;
  NodeData: PChannelItem;
begin
  if FProject.ChannelName <> Value then
  begin
    // check node with name
    for Node in TreeChannels.Nodes do
    begin
      NodeData := TreeChannels.GetNodeData(Node);
      if SameText(NodeData^.Name, Value) then
        TreeChannels.CheckState[Node] := csCheckedNormal
      else
        TreeChannels.CheckState[Node] := csUncheckedNormal;
    end;

    FProject.ChannelName := Value;
  end;
end;

procedure TfrmMain.SetupDefaultChannels;
var
  Node: PVirtualNode;
  NodeData: PChannelItem;
  Index: Integer;
const
  CChannelNames: array [0..1] of string = ('Stable', 'Nightly');
begin
  for Index := Low(CChannelNames) to High(CChannelNames) do
  begin
    Node := TreeChannels.AddChild(TreeChannels.RootNode);
    Node.CheckType := ctRadioButton;
    NodeData := TreeChannels.GetNodeData(Node);

    NodeData^.Name := CChannelNames[Index];
    NodeData^.FileName := FProject.ChannelsPath + NodeData^.Name + '.json';
    NodeData^.Modified := 0;

    // update check state
    if SameText(NodeData^.Name, FProject.ChannelName) then
      TreeChannels.CheckState[Node] := csCheckedNormal;
  end;
end;

procedure TfrmMain.TakeSnapshot;
var
  Node: PVirtualNode;
  NodeData: PFileItem;
  NodeChannelData: PChannelItem;
  Item: TWebUpdateFileItem;
  Fad: TWin32FileAttributeData;
  LastModified: TDateTime;
  FileName: TFileName;
  ChannelSetup: TWebUpdateChannelSetup;
begin
  // check if any files are selected at all
  if TreeFileList.CheckedCount = 0 then
    if MessageDlg('No file selected for update!', mtError, [mbOK], 0) = mrOk then
      Exit;

  // update status
  WriteStatus('Taking snapshot...');

  // update status
  NodeChannelData := GetCurrentChannelNodeData;
  if not Assigned(NodeChannelData) then
    Exit;

  // get filename for currently selected channel
  FileName := Project.ChannelsPath + ExtractFileName(
    WebToLocalFileName(NodeChannelData^.FileName));

  // create selected channels
  ChannelSetup := TWebUpdateChannelSetup.Create;
  try
    // store current channel name
    ChannelSetup.AppName := FAppName;
    ChannelSetup.ChannelName := FProject.ChannelName;
    LastModified := 0;
    for Node in TreeFileList.CheckedNodes do
    begin
      NodeData := TreeFileList.GetNodeData(Node);
      if NodeData^.WebFileName = '' then
        Continue;

      // get file attribute
      if not GetFileAttributesEx(PChar(NodeData^.FileName), GetFileExInfoStandard, @Fad) then
        RaiseLastOSError;

      // update file attributes
      NodeData^.Size := Fad.nFileSizeLow;
      NodeData^.Modified := FileTimeToDateTime(Fad.ftLastWriteTime);
      TreeFileList.RepaintNode(Node);

      // create (& update) file item
      Item := TWebUpdateFileItem.Create;
      Item.FileName := NodeData^.WebFileName;
      Item.Modified := NodeData^.Modified;
      Item.FileSize := NodeData^.Size;
      if Project.UseMD5 then
        Item.MD5Hash := MD5(NodeData.FileName)
      else
        Item.MD5Hash := '';

      if NodeData^.Modified > LastModified then
        LastModified := NodeData^.Modified;

      // add item to file items list
      ChannelSetup.Items.Add(Item);
    end;
    ChannelSetup.Modified := LastModified;
    NodeChannelData^.Modified := LastModified;

    // save channel setup
    ChannelSetup.SaveToFile(FileName);
  finally
    ChannelSetup.Free;
  end;

  SaveChannels;
  TreeChannels.Invalidate;

  // eventually copy to path and upload to a server
  if Project.AutoCopyUpload then
  begin
    if Project.Copy.Enabled then
      CopySnapshot;

    if Project.FTP.Server <> '' then
      UploadSnapshot;
  end;

  ClearStatus;
end;

procedure TfrmMain.TreeChannelsChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  if Assigned(Node) then
    TreeChannels.CheckState[Node] := csCheckedNormal;
end;

procedure TfrmMain.TreeChannelsChecked(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  I: Integer;
  NewNode: PVirtualNode;
  FileStrings: Types.TStringDynArray;
  FileName, WebFileName, RealFileName: string;
  Item: TWebUpdateFileItem;
  ChannelName: string;
  ChannelSetup: TWebUpdateChannelSetup;
  ChannelNodeData: PChannelItem;
  NodeData: PFileItem;
begin
  if not Assigned(Node) then
    Exit;

  ChannelNodeData := TreeChannels.GetNodeData(Node);
  FProject.ChannelName := ChannelNodeData^.Name;

  // get channel file name
  FileName := ExtractFileName(WebToLocalFileName(ChannelNodeData^.FileName));
  FileName := Project.ChannelsPath + FileName;

  // check if file exists
  if not FileExists(FileName) then
    Exit;

  // create selected channels
  ChannelSetup := TWebUpdateChannelSetup.Create;
  try
    // load setup from file
    ChannelSetup.LoadFromFile(FileName);

    // store current channel name
    if ChannelSetup.ChannelName <> '' then
      FProject.ChannelName := ChannelSetup.ChannelName;

    ChannelName := FProject.ChannelName;

    FAppName := ChannelSetup.AppName;

    TreeFileList.BeginUpdate;
    try
      for I := 0 to ChannelSetup.Items.Count - 1 do begin
        Item := TWebUpdateFileItem(ChannelSetup.Items[I]);

        WebFileName := Item.FileName;
        FileStrings := SplitString(WebFileName, '/');

        RealFileName := FProject.BasePath + ChannelName + PathDelim + WebToLocalFileName(WebFileName);

        if FileExists(RealFileName) then
        begin
          NewNode := CreateNode(FileStrings);
          NewNode.CheckState := csCheckedNormal;
          NodeData := TreeFileList.GetNodeData(NewNode);
          NodeData^.FileName := RealFileName;
          NodeData^.WebFileName := WebFileName;
          NodeData^.Caption := FileStrings[High(FileStrings)];
          NodeData^.Hash := SimpleStringHash(NodeData^.Caption);
          NodeData^.Modified := Item.Modified;
          NodeData^.Size := Item.FileSize;
       end else
         if MessageDlg(Format(RStrFileNotFound, [RealFileName]), mtWarning,
           [mbIgnore, mbAbort], 0) = mrAbort then
           Exit;
      end;
    finally
      TreeFileList.EndUpdate;
    end;
  finally
    ChannelSetup.Free;
  end;
end;

procedure TfrmMain.TreeChannelsFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  NodeData: PChannelItem;
begin
  NodeData := TreeChannels.GetNodeData(Node);
  Finalize(NodeData^);
end;

procedure TfrmMain.TreeChannelsGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
var
  NodeData: PChannelItem;
begin
  CellText := '';
  NodeData := TreeChannels.GetNodeData(Node);
  case Column of
    0:
      CellText := NodeData^.Name;
    1:
      CellText := NodeData^.FileName;
    2:
      if NodeData^.Modified > 0 then
        CellText := DateTimeToStr(NodeData^.Modified);
  end;
end;

procedure TfrmMain.TreeChannelsNewText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex;
  NewText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
var
  NodeData: PChannelItem;
begin
  NodeData := TreeChannels.GetNodeData(Node);
  case Column of
    0:
      NodeData^.Name := NewText;
    1:
      NodeData^.FileName := NewText;
  end;
end;

procedure TfrmMain.TreeFileListChecked(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  SubNode: PVirtualNode;
begin
  for SubNode in TreeFileList.ChildNodes(Node) do
    TreeFileList.CheckState[SubNode] := TreeFileList.CheckState[Node];
end;

procedure TfrmMain.TreeFileListCompareNodes(Sender: TBaseVirtualTree;
  Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  NodeData: array [0..1] of PFileItem;
begin
  NodeData[0] := TreeFileList.GetNodeData(Node1);
  NodeData[1] := TreeFileList.GetNodeData(Node2);

  Result := AnsiCompareStr(NodeData[0].Caption, NodeData[1].Caption);
  if NodeData[0].FileName = '' then
    Result := Result - 2;
  if NodeData[1].FileName = '' then
    Result := Result + 2;
end;

procedure TfrmMain.TreeFileListFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  NodeData: PFileItem;
begin
  NodeData := TreeFileList.GetNodeData(Node);
  Finalize(NodeData^);
end;

procedure TfrmMain.TreeFileListGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  NodeData: PFileItem;
begin
  if Column = 0 then
    case Kind of
      ikNormal, ikSelected:
      begin
        NodeData := TreeFileList.GetNodeData(Node);
        if NodeData.FileName <> '' then
          ImageIndex := 17
        else if TreeFileList.Expanded[Node] then
          ImageIndex := 16
        else
          ImageIndex := 15;
      end;
    end;
end;

function FormatByteSize(const ByteSize: Int64): string;
const
  CkB = 1024; // kilobyte
  CMB = 1024 * CkB; // megabyte
  CGB = 1024 * CMB; // gigabyte
begin
  if ByteSize > CGB then
    Result := FormatFloat('#.### GiB', ByteSize / CGB)
  else if ByteSize > CMB then
    Result := FormatFloat('#.### MiB', ByteSize / CMB)
  else if ByteSize > CkB then
    Result := FormatFloat('#.### KiB', ByteSize / CkB)
  else
    Result := FormatFloat('#.### Bytes', ByteSize);
end;

procedure TfrmMain.TreeFileListGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
var
  NodeData: PFileItem;
begin
  CellText := '';
  NodeData := TreeFileList.GetNodeData(Node);
  case Column of
    0:
      CellText := NodeData^.Caption;
    1:
      if NodeData^.FileName <> '' then
        CellText := DateTimeToStr(NodeData^.Modified);
    2:
      if NodeData^.FileName <> '' then
        CellText := FormatByteSize(NodeData^.Size);
  end;
end;

procedure TfrmMain.CopySnapshot;
var
  I: Integer;
  Path: string;
  ChannelSetup: TWebUpdateChannelSetup;
  FileItem: TWebUpdateFileItem;
  ChannelName, ChannelPath: string;
  RealFileName, ChannelFileName, DestFileName: TFileName;
  NodeData: PChannelItem;
begin
  Path := IncludeTrailingPathDelimiter(Project.Copy.Path);
  if IsRelativePath(Path) then
    Path := Project.BasePath + Path;

  // get currently checked channel node
  NodeData := GetCurrentChannelNodeData;
  if not Assigned(NodeData) then
    Exit;

  ChannelName := NodeData^.Name;
  ChannelFileName := Project.ChannelsPath +
    ExtractFileName(WebToLocalFileName(NodeData^.FileName));
  ChannelPath := Path + ChannelName + PathDelim;

  // upload files
  ChannelSetup := TWebUpdateChannelSetup.Create;
  try
    // load channel setup
    ChannelSetup.LoadFromFile(ChannelFileName);

    // ensure the date is set identical in both JSON files
    if ChannelSetup.Modified <> NodeData^.Modified then
      if MessageDlg('Time stamp mismatch. Continue?', mtWarning, [mbYes, mbNo], 0) = mrNo then
        Exit;

    for I := 0 to ChannelSetup.Items.Count - 1 do begin
      FileItem := TWebUpdateFileItem(ChannelSetup.Items[I]);

      WriteStatus('Copying file ' + FileItem.FileName + '...');

      RealFileName := Project.BasePath + ChannelName + PathDelim + WebToLocalFileName(FileItem.FileName);

      // copy file
      DestFileName := ExpandFileName(ChannelPath + FileItem.FileName);
      ForceDirectories(ExtractFileDir(DestFileName));
      CopyFile(RealFileName, DestFileName, False);

      // set file date/time according to the JSON file
      FileSetDate(DestFileName, DateTimeToFileDate(FileItem.Modified));
    end;
  finally
    ChannelSetup.Free;
  end;

  // copy channel setup
  WriteStatus('Copying channel setup...');
  DestFileName := ExpandFileName(Path + ExtractFileName(NodeData^.FileName));
  ForceDirectories(ExtractFileDir(DestFileName));
  CopyFile(ChannelFileName, DestFileName, False);

  // set file date/time according to the JSON file
  FileSetDate(DestFileName, DateTimeToFileDate(NodeData^.Modified));

  // copy channel file
  WriteStatus('Copying channels list...');
  DestFileName := ExpandFileName(Path + ExtractFileName(FProject.ChannelsFilename));
  CopyFile(FProject.FullChannelsFilename, DestFileName, False);

  ClearStatus;
end;

procedure TfrmMain.UploadSnapshot;
var
  I: Integer;
  ChannelSetup: TWebUpdateChannelSetup;
  FileItem: TWebUpdateFileItem;
  ChannelName: string;
  RealFileName, ChannelFileName, ChannelWebName: TFileName;
  NodeData: PChannelItem;
begin
  // only continue if an FTP server is supplied
  if Project.FTP.Server = '' then
    Exit;

  // get currently checked channel node
  NodeData := GetCurrentChannelNodeData;
  if not Assigned(NodeData) then
    Exit;

  ChannelName := NodeData^.Name;
  ChannelFileName := Project.ChannelsPath +
    ExtractFileName(WebToLocalFileName(NodeData^.FileName));
  ChannelWebName := ChannelName + '/' + NodeData^.FileName;

  with TIdFTP.Create(nil) do
  try
    OnWork := WorkEventHandler;
    OnWorkBegin := WorkBeginEventHandler;
    OnWorkEnd := WorkEndEventHandler;
    OnStatus := StatusEventHandler;
    Host := Project.FTP.Server;
    Username := Project.FTP.Username;
    Password := Project.FTP.Password;
    Connect;
    try
      // upload files
      ChannelSetup := TWebUpdateChannelSetup.Create;
      try
        // load channel setup
        ChannelSetup.LoadFromFile(ChannelFileName);

        // ensure the date is set identical in both JSON files
        if ChannelSetup.Modified <> NodeData^.Modified then
          if MessageDlg('Time stamp mismatch. Continue?', mtWarning, [mbYes, mbNo], 0) = mrNo then
            Exit;

        for I := 0 to ChannelSetup.Items.Count - 1 do
        begin
          FileItem := TWebUpdateFileItem(ChannelSetup.Items[I]);

          WriteStatus('Uploading: ' + FileItem.FileName);

          // upload file
          RealFileName := Project.BasePath + WebToLocalFileName(FileItem.FileName);
          Put(RealFileName, ChannelName + '/' + FileItem.FileName);

          // now try to update time stamp
          try
            SetModTime(ChannelName + '/' + FileItem.FileName, FileItem.Modified);
          except end;
        end;
      finally
        ChannelSetup.Free;
      end;

      WriteStatus('Uploading channel setup...');

      // upload channel setup
      Put(ChannelFileName, ChannelWebName);
      try
        SetModTime(ChannelWebName, NodeData^.Modified);
      except end;

      WriteStatus('Uploading channels list...');

      // upload channel file
      Put(FProject.FullChannelsFilename, ExtractFileName(FProject.ChannelsFilename));

      ClearStatus;
    finally
      Disconnect;
    end;
  finally
    Free;
  end;
end;

procedure TfrmMain.StatusEventHandler(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: String);
begin
  StatusBar.Panels[1].Text := AStatusText;
end;

procedure TfrmMain.WorkBeginEventHandler(Sender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND});
begin
  ProgressBar.Max := AWorkCountMax;
end;

procedure TfrmMain.WorkEndEventHandler(Sender: TObject; AWorkMode: TWorkMode);
begin
  ProgressBar.Position := 0;
end;

procedure TfrmMain.WorkEventHandler(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND});
begin
  ProgressBar.Position := AWorkCount;
  Application.ProcessMessages;
end;

procedure TfrmMain.ClearStatus;
begin
  StatusBar.Panels[1].Text := '';
end;

procedure TfrmMain.WriteStatus(Text: string);
begin
  StatusBar.Panels[1].Text := Text;
  Application.ProcessMessages;
end;

end.
