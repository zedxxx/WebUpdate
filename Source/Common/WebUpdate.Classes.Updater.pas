unit WebUpdate.Classes.Updater;

interface

uses
  SysUtils,
  Classes,
  WebUpdate.JSON.Channel,
  WebUpdate.JSON.Channels,
  WebUpdate.Classes.FileItem,
  WebUpdate.Classes.UpdaterThread,
  WebUpdate.Network.Downloader,
  WebUpdate.Network.DownloaderFactory;

type
  EHttpDownload = class(Exception);
  
  TWebUpdater = class
  private
    FBaseURL: string;
    FChannelName: string;
    FChannelsLoaded: Boolean;
    FChannels: TWebUpdateChannels;
    FChannelPath: string;
    FChannelsFileName: TFileName;
    FLocalChannelFileName: TFileName;
    FNewSetup: TWebUpdateChannelSetup;
    FThread: TUpdaterThread;
    FFileItemListCache: TFileItemList;
    FTotalSize: Int64;
    FCurrentSize: Int64;

    FOnFileNameProgress: TUpdaterThread.TFileNameProgressEvent;
    FOnDone: TNotifyEvent;
    FOnError: TUpdaterThread.TErrorEvent;
    FOnProgress: TUpdaterThread.TProgressEvent;

    FHttp: TDownloader;

    function GetFileItemList: TFileItemList;
    function GetLocalChannelFileName: TFileName;
    function GetMainAppFileName: TFileName;
    function GetTotalSize: Int64;
    procedure SetBaseURL(Value: string);
    procedure SetChannelName(const Value: string);
    procedure SetChannelsFileName(const Value: TFileName);
    procedure SetLocalChannelFileName(const Value: TFileName);
  protected
    procedure ErrorHandler(Sender: TObject; ErrorType: TWebUpdateErrorType;
      const FileName: TFileName; var Ignore: Boolean);
    procedure ProgressEventHandler(Sender: TObject; Progress: Integer;
      ByteCount: Integer; PassedTime: TDateTime);
    procedure FileChangedEventHandler(Sender: TObject; const FileName: TFileName);
    procedure DoneEventHandler(Sender: TObject);

    procedure BuildFileListCache;
    procedure ResetFileListCache;
    procedure LoadSetupFromFile(const FileName: TFileName);
    procedure LoadChannels;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Abort;
    procedure PerformWebUpdate;
    procedure GetChannelNames(const ChannelNames: TStringList);

    property BaseURL: string read FBaseURL write SetBaseURL;
    property ChannelName: string read FChannelName write SetChannelName;
    property Channels: TWebUpdateChannels read FChannels;
    property ChannelsFileName: TFileName read FChannelsFileName write SetChannelsFileName;
    property LocalChannelFileName: TFileName read GetLocalChannelFileName write SetLocalChannelFileName;
    property MainAppFileName: TFileName read GetMainAppFileName;
    property FileItemList: TFileItemList read GetFileItemList;
    property TotalBytes: Int64 read GetTotalSize;

    property OnProgress: TUpdaterThread.TProgressEvent read FOnProgress write FOnProgress;
    property OnFileNameProgress: TUpdaterThread.TFileNameProgressEvent read FOnFileNameProgress write FOnFileNameProgress;
    property OnDone: TNotifyEvent read FOnDone write FOnDone;
    property OnError: TUpdaterThread.TErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  WebUpdate.Tools;

{ TWebUpdater }

constructor TWebUpdater.Create;
begin
  FChannels := TWebUpdateChannels.Create;
  FNewSetup := TWebUpdateChannelSetup.Create;

  FBaseURL := '';
  FCurrentSize := 0;
  FChannelPath := '';

  FChannelsLoaded := False;
  FChannelsFileName := 'Channels.json';
  FLocalChannelFileName := 'WebUpdate.json';

  FHttp := CreateDownloader(ExtractFilePath(ParamStr(0)));
end;

destructor TWebUpdater.Destroy;
begin
  if Assigned(FThread) then
    FThread.Terminate;

  FFileItemListCache.Free;

  FChannels.Free;
  FNewSetup.Free;

  if Assigned(FThread) then
    FThread.WaitFor;
  FThread.Free;

  FHttp.Free;

  inherited;
end;

procedure TWebUpdater.Abort;
begin
  if Assigned(FThread) then
    FThread.Terminate;
  ResetFileListCache;
end;

procedure TWebUpdater.BuildFileListCache;
var
  I: Integer;
  ChannelItem: TWebUpdateChannelItem;
  Item: TWebUpdateFileItem;
  FileItem: TFileItem;
  LocalSetup: TWebUpdateChannelSetup;
begin
  LoadChannels;

  for I := 0 to FChannels.Items.Count - 1 do begin
    ChannelItem := TWebUpdateChannelItem(FChannels.Items[I]);
    if SameText(ChannelItem.Name, ChannelName) then begin
      FChannelPath := ChannelItem.Name + PathDelim;
      LoadSetupFromFile(ChannelItem.FileName);
      Break;
    end;
  end;

  FTotalSize := 0;

  if FileExists(FLocalChannelFileName) then begin
    LocalSetup := TWebUpdateChannelSetup.Create;
    try
      LocalSetup.LoadFromFile(FLocalChannelFileName);

      // assume deletion of all files currently present
      for I := 0 to LocalSetup.Items.Count - 1 do begin
        Item := TWebUpdateFileItem(LocalSetup.Items[I]);
        FileItem := TFileItem.Create(Item.FileName, Item.MD5Hash, Item.FileSize,
          Item.Modified);
        FileItem.Action := faDelete;
        FFileItemListCache.Add(FileItem);
      end;
    finally
      LocalSetup.Free;
    end;
  end;

  // add all files (and eventually mark as
  for I := 0 to FNewSetup.Items.Count - 1 do begin
    Item := TWebUpdateFileItem(FNewSetup.Items[I]);

    // now check if file is already present (from local setup)
    FileItem := FFileItemListCache.LocateItemByFileName(Item.FileName);

    if Assigned(FileItem) then begin
      // check if file is marked for explicit deletion
      if Item.Action = iaDelete then begin
        FileItem.Action := faDelete;

        // set MD5 hash, size and modification date to 0 => always delete!
        FileItem.MD5Hash := '';
        FileItem.Modified := 0;
        FileItem.FileSize := 0;

        Continue;
      end;

      // check if file is (supposed to be) identical to previous version
      if (FileItem.Modified = Item.Modified) and
        (FileItem.FileSize = Item.FileSize) and
        (FileItem.MD5Hash = Item.MD5Hash)
      then begin
        FileItem.Action := faVerify;
      end else begin
        // set action to 'change' and update properties
        FileItem.Action := faChange;
        FileItem.MD5Hash := Item.MD5Hash;
        FileItem.Modified := Item.Modified;
        FileItem.FileSize := Item.FileSize;
      end;
    end else begin
      FileItem := TFileItem.Create(Item.FileName, Item.MD5Hash, Item.FileSize,
        Item.Modified);
      FFileItemListCache.Add(FileItem);

      // check if the item action is to delete the file
      if Item.Action = iaDelete then begin
        FileItem.Action := faDelete;
        Continue;
      end;
    end;

    // inc total file size (if item is about to be added
    if Item.Action <> iaDelete then
      FTotalSize := FTotalSize + Item.FileSize;
  end;
end;

procedure TWebUpdater.DoneEventHandler(Sender: TObject);
begin
  FNewSetup.SaveToFile(FLocalChannelFileName);

  FThread := nil;
  if Assigned(FOnDone) then begin
    FOnDone(Sender);
  end;
end;

procedure TWebUpdater.FileChangedEventHandler(Sender: TObject;
  const FileName: TFileName);
begin
  if Assigned(OnFileNameProgress) then
    OnFileNameProgress(Sender, FileName);
end;

procedure TWebUpdater.SetBaseURL(Value: string);
begin
  if not (Value[Length(Value)] = '/') then begin
    Value := Value + '/';
  end;
  if FBaseURL <> Value then begin
    FBaseURL := Value;
    ResetFileListCache;
  end;
end;

procedure TWebUpdater.SetChannelName(const Value: string);
begin
  if FChannelName <> Value then begin
    FChannelName := Value;
    ResetFileListCache;
  end;
end;

procedure TWebUpdater.SetChannelsFileName(const Value: TFileName);
begin
  if FChannelsFileName <> Value then begin
    FChannelsFileName := Value;
    ResetFileListCache;
  end;
end;

procedure TWebUpdater.SetLocalChannelFileName(const Value: TFileName);
begin
  if FLocalChannelFileName <> Value then begin
    FLocalChannelFileName := Value;
    ResetFileListCache;
  end;
end;

procedure TWebUpdater.GetChannelNames(const ChannelNames: TStringList);
var
  I: Integer;
  Item: TWebUpdateChannelItem;
begin
  // load channels setup from URI
  LoadChannels;

  // get channel names
  ChannelNames.Clear;

  for I := 0 to Channels.Items.Count - 1 do begin
    Item := TWebUpdateChannelItem(Channels.Items[I]);
    ChannelNames.Add(Item.Name);
  end;
end;

function TWebUpdater.GetFileItemList: TFileItemList;
begin
  if Assigned(FFileItemListCache) then begin
    Result := FFileItemListCache;
    Exit;
  end;

  FFileItemListCache := TFileItemList.Create;
  BuildFileListCache;
  Result := FFileItemListCache;
end;

function TWebUpdater.GetLocalChannelFileName: TFileName;
begin
  Result := FLocalChannelFileName;
  if IsRelativePath(Result) then
    Result := ExtractFilePath(ParamStr(0)) + Result;
end;

function TWebUpdater.GetMainAppFileName: TFileName;
begin
  Result := '';
  if FNewSetup.AppName <> '' then begin
    Result := WebToLocalFileName(FNewSetup.AppName);
    Result := ExtractFilePath(FLocalChannelFileName) + Result;
  end;
end;

function TWebUpdater.GetTotalSize: Int64;
begin
  GetFileItemList;
  Result := FTotalSize;
end;

procedure TWebUpdater.PerformWebUpdate;
begin
  // eventually kill thread
  if Assigned(FThread) then begin
    FThread.Terminate;
    FThread.WaitFor;
    FThread.Free;
  end;

  FThread := TUpdaterThread.Create(FileItemList);

  // specify event handlers
  FThread.OnProgress := ProgressEventHandler;
  FThread.OnFileNameProgress := FileChangedEventHandler;
  FThread.OnDone := DoneEventHandler;
  FThread.OnError := ErrorHandler;

  FThread.BasePath := FBaseURL + FChannelPath;
  FThread.LocalPath := ExtractFilePath(FLocalChannelFileName);

  FThread.Suspended := False;
end;

procedure TWebUpdater.ErrorHandler(Sender: TObject;
  ErrorType: TWebUpdateErrorType; const FileName: TFileName; var Ignore: Boolean);
begin
  // event redirection
  if Assigned(FOnError) then
    FOnError(Sender, ErrorType, FileName, Ignore);
end;

procedure TWebUpdater.ProgressEventHandler(Sender: TObject; Progress,
  ByteCount: Integer; PassedTime: TDateTime);
var
  TotalTime: TDateTime;
begin
  Inc(FCurrentSize, ByteCount);
  
  TotalTime := PassedTime * FTotalSize / FCurrentSize;

  // event redirection
  if Assigned(OnProgress) then
    OnProgress(Sender, Progress, ByteCount, TotalTime - PassedTime);
end;

procedure TWebUpdater.ResetFileListCache;
begin
  FreeAndNil(FFileItemListCache);
end;

procedure TWebUpdater.LoadChannels;
var
  Text: string;
  Success: Boolean;
begin
  if not FChannelsLoaded then begin

    FChannelsLoaded := True;

    try
      FHttp.Get(BaseURL + ChannelsFileName, Text);
      Success := Text <> '';
    except
      Success := False;
    end;

    if not Success then begin
      raise EHttpDownload.CreateFmt('Error downloading from URL %s', [BaseURL + ChannelsFileName]);
    end;

    FChannels.LoadFromString(Text);
  end;
end;

procedure TWebUpdater.LoadSetupFromFile(const FileName: TFileName);
var
  Text: string;
  Success: Boolean;
begin
  try
    FHttp.Get(FBaseURL + FileName, Text);
    Success := Text <> '';
  except
    Success := False;
  end;

  if not Success then begin
    raise EHttpDownload.CreateFmt('Error downloading from URL %s', [FBaseURL + FileName]);
  end;

  FNewSetup.LoadFromString(Text);
end;

end.
