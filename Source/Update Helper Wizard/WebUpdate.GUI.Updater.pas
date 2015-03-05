unit WebUpdate.GUI.Updater;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Forms,
  ImgList,
  Controls,
  StdCtrls,
  Graphics,
  ExtCtrls,
  ComCtrls,
  Dialogs,
  VirtualTrees,
  WebUpdate.Classes.Updater,
  WebUpdate.Classes.FileItem,
  WebUpdate.Classes.UpdaterThread;

type
  TNodeFileItem = record
    FileItem: TFileItem;
  end;
  PNodeFileItem = ^TNodeFileItem;

  TFormWebUpdate = class(TForm)
    ButtonClose: TButton;
    ButtonNext: TButton;
    CheckBoxStartApplication: TCheckBox;
    ComboBoxChannels: TComboBox;
    ImageHeader: TImage;
    ImageList: TImageList;
    LabelCurrentFile: TLabel;
    LabelFileList: TLabel;
    LabelHeader: TLabel;
    LabelRemainingTime: TLabel;
    LabelSelectChannel: TLabel;
    lblBytesProgress: TLabel;
    LabelSummary: TLabel;
    LabelTotalStatus: TLabel;
    PageControl: TPageControl;
    PanelControl: TPanel;
    PanelHeader: TPanel;
    ProgressBarCurrent: TProgressBar;
    ProgressBarTotal: TProgressBar;
    RadioButtonAlternative: TRadioButton;
    RadioButtonStable: TRadioButton;
    TabFileList: TTabSheet;
    TabProgress: TTabSheet;
    TabSelectChannel: TTabSheet;
    TabSummary: TTabSheet;
    TreeFiles: TVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonAbortClick(Sender: TObject);
    procedure ButtonFinishClick(Sender: TObject);
    procedure ButtonNextClick(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure RadioButtonChannelClick(Sender: TObject);
    procedure TabProgressShow(Sender: TObject);
    procedure TabSelectChannelShow(Sender: TObject);
    procedure TabFileListShow(Sender: TObject);
    procedure TabSummaryShow(Sender: TObject);
    procedure TreeFilesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
    procedure TreeFilesGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
  private
    FWebUpdater: TWebUpdater;
    FMainAppWindowCaption: string;
    FMainAppExecutable: string;
    FDelay: Integer;
    FVerbose: Boolean;

    procedure ProgressEventHandler(Sender: TObject; Progress: Integer;
      ByteCount: Integer; RemainingTime: TDateTime);
    procedure FileNameProgressEventHandler(Sender: TObject; const FileName: TFileName);
    procedure WebUpdateCompleteEventHandler(Sender: TObject);
    procedure ErrorHandler(Sender: TObject; ErrorType: TWebUpdateErrorType;
      const FileName: TFileName; var Ignore: Boolean);
  public
    procedure ScanCommandLineParameters;
    procedure PerformWebUpdate;
    function CloseMainApplication: Boolean;
  end;

var
  FormWebUpdate: TFormWebUpdate;

implementation

{$R *.dfm}

uses
  StrUtils,
  ShellAPI,
  WebUpdate.Tools.Windows,
  Updater.CmdLine.Processor;

resourcestring
  rsBaseURL = 'http://127.0.0.1/snapshots/';
  rsDownloadProgressInfo = '%s %.2f of %.2f MiB (%.2f%s)';

resourcestring
  RStrMD5MismatchUpdate = 'MD5 mismatch, update might be corrupt!';
  //RStrChannelDefinitionError = 'Could not load channel definition!';
  //RStrSetupLoadError = 'Could not load setup!';

{ TFormWebUpdate }

procedure TFormWebUpdate.FormCreate(Sender: TObject);
begin
  PageControl.ActivePage := TabSelectChannel;
  TreeFiles.NodeDataSize := SizeOf(TNodeFileItem);
  TreeFiles.OnGetText := Self.TreeFilesGetText;
  
  FMainAppWindowCaption := '';
  FMainAppExecutable := '';

  // create WebUpdater
  FWebUpdater := TWebUpdater.Create;
  FWebUpdater.BaseURL := rsBaseURL;
  FWebUpdater.OnProgress := ProgressEventHandler;
  FWebUpdater.OnFileNameProgress := FileNameProgressEventHandler;
  FWebUpdater.OnDone := WebUpdateCompleteEventHandler;
  FWebUpdater.OnError := ErrorHandler;

  ScanCommandLineParameters;
end;

procedure TFormWebUpdate.FormDestroy(Sender: TObject);
begin
  FWebUpdater.Free;
end;

procedure TFormWebUpdate.ButtonAbortClick(Sender: TObject);
begin
  if Assigned(FWebUpdater) then
    FWebUpdater.Abort;
  Close;
end;

procedure TFormWebUpdate.ButtonFinishClick(Sender: TObject);
var
  AppName: TFileName;
begin
  if CheckBoxStartApplication.Visible and CheckBoxStartApplication.Checked then begin
    AppName := FWebUpdater.MainAppFileName;
    if AppName <> '' then begin
      ShellExecute(Application.Handle, 'open', PChar(AppName), nil,
        PChar(ExtractFileDir(AppName)), SW_SHOW);
    end;
  end;
  Close;
end;

procedure TFormWebUpdate.ButtonNextClick(Sender: TObject);
begin
  if RadioButtonStable.Checked then begin
    FWebUpdater.ChannelName := 'Stable';
  end else begin
    FWebUpdater.ChannelName := ComboBoxChannels.Text;
  end;
  if FVerbose then begin
    PageControl.ActivePage := TabFileList;
  end else begin
    PerformWebUpdate;
    PageControl.ActivePage := TabProgress;
    Update;
  end;
end;

procedure TFormWebUpdate.ButtonStartClick(Sender: TObject);
begin
  PerformWebUpdate;
  PageControl.ActivePage := TabProgress;
  Update;
end;

procedure TFormWebUpdate.FileNameProgressEventHandler(Sender: TObject;
  const FileName: TFileName);
begin
  LabelCurrentFile.Caption := 'Current File: ' + FileName;
end;

procedure TFormWebUpdate.ProgressEventHandler(Sender: TObject;
  Progress: Integer; ByteCount: Integer; RemainingTime: TDateTime);
var
  VPercent: Single;
  VTotal, VDone: Int64;
begin
  ProgressBarCurrent.Position := Progress;
  ProgressBarTotal.Position := ProgressBarTotal.Position + ByteCount;

  LabelRemainingTime.Caption := 'Time remaining: ' + TimeToStr(RemainingTime);
  LabelRemainingTime.Visible := True;

  VTotal := FWebUpdater.TotalBytes;
  VDone := ProgressBarTotal.Position;

  if VTotal > 0 then begin
    if VDone = VTotal then begin
      VPercent := 100;
    end else begin
      VPercent := (VDone / VTotal) * 100;
    end;
  end else begin
    VPercent := 0.0;
  end;

  lblBytesProgress.Caption :=
    Format(
      rsDownloadProgressInfo,
      [
        'Total: ',
        VDone / 1024 / 1024,
        VTotal / 1024 / 1024,
        VPercent,
        '%'
      ]
    );
  lblBytesProgress.Visible := True;
end;

procedure TFormWebUpdate.WebUpdateCompleteEventHandler(Sender: TObject);
begin
  // allow starting the application, if an (existing!) app is specified
  CheckBoxStartApplication.Visible := FileExists(FWebUpdater.MainAppFileName);
  CheckBoxStartApplication.Checked := CheckBoxStartApplication.Visible;
  
  PageControl.ActivePage := TabSummary;
end;

procedure TFormWebUpdate.ErrorHandler(Sender: TObject;
  ErrorType: TWebUpdateErrorType; const FileName: TFileName; var Ignore: Boolean);
begin
  if ErrorType = etChecksum then
    case MessageDlg(RStrMD5MismatchUpdate, mtWarning, [mbAbort, mbIgnore], 0) of
      mrAbort:
        Ignore := False;
      mrIgnore:
        Ignore := True;
    end
  else
    Ignore := False;
end;

procedure TFormWebUpdate.RadioButtonChannelClick(Sender: TObject);
begin
  ComboBoxChannels.Visible := RadioButtonAlternative.Checked;
end;

procedure TFormWebUpdate.ScanCommandLineParameters;
var
  Index: Integer;
  ChannelNames: TStringList;
begin
  FVerbose := False;
  if ParamCount >= 1 then begin
    if not ScanParameters(FWebUpdater, FMainAppExecutable, FMainAppWindowCaption, FDelay) then begin
      Assert(False);
    end;
    PerformWebUpdate;
    PageControl.ActivePage := TabProgress;
    Update;
  end else begin
    FVerbose := True;
    ChannelNames := TStringList.Create;
    try
      ComboBoxChannels.Clear;
      FWebUpdater.GetChannelNames(ChannelNames);        // HTTP REQUEST !!!
      for Index := 0 to ChannelNames.Count - 1 do
        if not SameText(ChannelNames[Index], 'Stable') then
          ComboBoxChannels.Items.Add(ChannelNames[Index]);
      ComboBoxChannels.ItemIndex := 0;
    finally
      ChannelNames.Free;
    end;
  end;
end;

procedure TFormWebUpdate.TabProgressShow(Sender: TObject);
begin
  ProgressBarTotal.Max := FWebUpdater.TotalBytes;
  ProgressBarTotal.Position := 0;

  ButtonNext.Visible := False;
  ButtonClose.Caption := '&Abort';
  ButtonClose.OnClick := ButtonAbortClick;
end;

procedure TFormWebUpdate.TabSelectChannelShow(Sender: TObject);
begin
  ButtonNext.Visible := True;
  if FVerbose then
    ButtonNext.Caption := '&Next >'
  else
    ButtonNext.Caption := '&Start >';
  ButtonNext.OnClick := ButtonNextClick;
  ButtonClose.Caption := '&Abort';
  ButtonClose.OnClick := ButtonAbortClick;
end;

procedure TFormWebUpdate.TabFileListShow(Sender: TObject);
var
  I: Integer;
  FileList: TFileItemList;
  FileItem: TFileItem;
  Node: PVirtualNode;
  NodeData: PNodeFileItem;
begin
  ButtonNext.Visible := True;
  ButtonNext.Caption := '&Start >';
  ButtonNext.OnClick := ButtonStartClick;
  ButtonClose.Caption := '&Abort';
  ButtonClose.OnClick := ButtonAbortClick;

  TreeFiles.BeginUpdate;
  try
    TreeFiles.Clear;
    FileList := FWebUpdater.FileItemList;               // HTTP REQUEST !!!
    for I := 0 to FileList.Count - 1 do begin
      FileItem := TFileItem(FileList[I]);
      Node := TreeFiles.AddChild(TreeFiles.RootNode);
      NodeData := TreeFiles.GetNodeData(Node);
      NodeData^.FileItem := FileItem;
    end;
  finally
    TreeFiles.EndUpdate
  end;
end;

procedure TFormWebUpdate.TabSummaryShow(Sender: TObject);
begin
  ButtonNext.Visible := False;
  ButtonClose.Caption := '&Finish';
  ButtonClose.OnClick := ButtonFinishClick;
end;

procedure TFormWebUpdate.TreeFilesGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  NodeData: PNodeFileItem;
begin
  // Ignore overlay and other columns
  if (Kind = ikOverlay) or (Column <> 0) then
    Exit;

  NodeData := TreeFiles.GetNodeData(Node);

  case NodeData.FileItem.Action of
    faAdd:
      ImageIndex := 0;
    faChange:
      ImageIndex := 1;
    faDelete:
      ImageIndex := 2;
    faVerify:
      ImageIndex := 3;
  end;
end;

procedure TFormWebUpdate.TreeFilesGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: {$IFDEF UNICODE} string {$ELSE} WideString {$ENDIF});
var
  NodeData: PNodeFileItem;
begin
  CellText := '';
  NodeData := TreeFiles.GetNodeData(Node);
  case Column of
    0:
      CellText := NodeData^.FileItem.FileName;
    1:
      if NodeData^.FileItem.Modified > 0 then
        CellText := DateTimeToStr(NodeData^.FileItem.Modified);
    2:
      if NodeData^.FileItem.FileSize > 0 then
        CellText := IntToStr(NodeData^.FileItem.FileSize);
  end;
end;

function TFormWebUpdate.CloseMainApplication: Boolean;
var
  VMsgResult: Integer;
begin
  Result := CloseApplication(FMainAppExecutable, FMainAppWindowCaption, FDelay, False);
  while not Result do begin
    VMsgResult := MessageDlg(
      'Main application is already running!' + #13#10#13#10 +
      'Force closing the main application?', mtWarning, [mbYes, mbAbort, mbRetry], 0
    );
    case VMsgResult of
      mrRetry: begin
        Result := CloseApplication(FMainAppExecutable, FMainAppWindowCaption, FDelay, False);
      end;
      mrYes: begin
        Result := CloseApplication(FMainAppExecutable, FMainAppWindowCaption, FDelay, True);
      end;
      mrAbort: begin
        Exit;
      end;
    end;
  end;
end;

procedure TFormWebUpdate.PerformWebUpdate;
begin
  // give other applications time to close
  Sleep(1 + FDelay);

  // first check if main application is still running
  if CloseMainApplication then
    FWebUpdater.PerformWebUpdate;
end;

end.
