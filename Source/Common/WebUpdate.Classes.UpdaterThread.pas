unit WebUpdate.Classes.UpdaterThread;

interface

uses
  Windows,
  Classes,
  SysUtils,
  WebUpdate.Classes.FileItem,
  WebUpdate.Network.Downloader,
  WebUpdate.Network.DownloaderFactory;

type
  TWebUpdateErrorType = (etDownload, etChecksum);

  TUpdaterThread = class(TThread)
  type
    TProgressEvent = procedure (Sender: TObject; Progress: Integer;
      ByteCount: Integer; ProgressTime: TDateTime) of object;
    TFileNameProgressEvent = procedure (Sender: TObject; const FileName: TFileName) of object;
    TErrorEvent = procedure (Sender: TObject; ErrorType: TWebUpdateErrorType;
      const FileName: TFileName; var Ignore: Boolean) of object;
  private
    FFiles: TFileItemList;
    FHttp: TDownloader;
    FLocalPath: string;
    FBasePath: string;
    FStartTimeStamp: TDateTime;
    FLastWorkCount: Integer;

    FCurrentWorkCount: Integer;
    FCurrentContentLength: Int64;
    FCurrentFileName: string;

    FOnFileNameProgress: TFileNameProgressEvent;
    FOnProgress: TProgressEvent;
    FOnDone: TNotifyEvent;
    FOnError: TErrorEvent;

    procedure CallOnProgress;
    procedure CallOnFileNameProgress;
    procedure CallOnDone;

    procedure HttpWork(
      ASender: TObject;
      const AWorkCount: Integer;
      const AContentLength: Integer;
      const AEncoding: string
    );
  protected
    procedure Execute; override;
  public
    constructor Create(const Files: TFileItemList); reintroduce;

    property Files: TFileItemList read FFiles;
    property BasePath: string read FBasePath write FBasePath;
    property LocalPath: string read FLocalPath write FLocalPath;

    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnFileNameProgress: TFileNameProgressEvent read FOnFileNameProgress write FOnFileNameProgress;
    property OnDone: TNotifyEvent read FOnDone write FOnDone;
    property OnError: TErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  WebUpdate.Tools;

{ TUpdaterThread }

constructor TUpdaterThread.Create(const Files: TFileItemList);
begin
  FFiles := Files;
  FLastWorkCount := 0;
  inherited Create(False);
end;

procedure TUpdaterThread.HttpWork(
  ASender: TObject;
  const AWorkCount: Integer;
  const AContentLength: Integer;
  const AEncoding: string
);
begin
  if not Assigned(FHttp) or not Assigned(FOnProgress) then begin
    Exit;
  end;

  FCurrentContentLength := AContentLength;

  if (Pos('chunked', LowerCase(AEncoding)) = 0) and (FCurrentContentLength > 0) then begin
    FCurrentWorkCount := AWorkCount;
    Synchronize(CallOnProgress);
    FLastWorkCount := AWorkCount;
  end;
end;

procedure TUpdaterThread.Execute;
var
  I: Integer;
  MS: TMemoryStream;
  Item: TFileItem;
  Hash: string;
  IgnoreError: Boolean;
  VFilePath: string;
begin
  if FLocalPath = '' then begin
    FLocalPath := ExtractFilePath(ParamStr(0));
  end;
  FStartTimeStamp := Now;
  FHttp := CreateDownloader(ExtractFilePath(ParamStr(0)), HttpWork);
  try
    MS := TMemoryStream.Create;
    try
      for I := 0 to FFiles.Count - 1 do begin
        FLastWorkCount := 0;

        Item := TFileItem(FFiles[I]);

        // eventually call 'file changed' event
        if Assigned(FOnFileNameProgress) then begin
          FCurrentFileName := Item.FileName;
          Synchronize(CallOnFileNameProgress);
        end;

        // eventually delete file and continue with next file
        if Item.Action = faDelete then begin
          DeleteFile(FLocalPath + Item.LocalFileName);
          Continue;
        end;

        // clear buffer / reset last work count
        MS.Clear;

        // check if terminated
        if Terminated then
          Exit;

        try
          // download file
          FHttp.Get(FBasePath + Item.FileName, MS);
        except
          IgnoreError := False;
          if Assigned(FOnError) then
            FOnError(Self, etDownload, FBasePath + Item.FileName, IgnoreError);
          if not IgnoreError then
            Exit;
        end;

        // check if terminated
        if Terminated then
          Exit;

        // eventually check MD5 hash
        if Item.MD5Hash <> '' then begin
          Hash := MD5(MS);
          if Hash <> Item.MD5Hash then begin
            IgnoreError := False;
            if Assigned(FOnError) then
              FOnError(Self, etChecksum, Item.FileName, IgnoreError);
            if not IgnoreError then
              Exit;
          end;
        end;

        // save downloaded file
        VFilePath := ExtractFilePath(FLocalPath + Item.LocalFileName);
        if VFilePath <> '' then begin
          ForceDirectories(VFilePath);
        end;
        MS.SaveToFile(FLocalPath + Item.LocalFileName);

        // eventually update modification date/time
        if Item.Modified > 0 then
          FileSetDate(FLocalPath + Item.LocalFileName, DateTimeToFileDate(Item.Modified));

        // check if terminated
        if Terminated then
          Exit;
      end;
    finally
      MS.Free;
    end;
  finally
    FreeAndNil(FHttp);
  end;

  // check if terminated
  if Terminated then
    Exit;

  // check if terminated
  if Terminated then
    Exit;

  // check if terminated
  if Terminated then
    Exit;

  // eventually call 'done' event
  if Assigned(FOnDone) then begin
    Synchronize(CallOnDone)
  end;
end;

procedure TUpdaterThread.CallOnProgress;
begin
  FOnProgress(Self, 100 * FLastWorkCount div FCurrentContentLength,
    FCurrentWorkCount - FLastWorkCount, Now - FStartTimeStamp);
end;

procedure TUpdaterThread.CallOnFileNameProgress;
begin
  FOnFileNameProgress(Self, FCurrentFileName);
end;

procedure TUpdaterThread.CallOnDone;
begin
  FOnDone(Self);
end;

end.
