unit Simple.FTP.Server;

interface

uses
  Windows,
  SysUtils,
  Classes,
  IdSys,
  IdObjs,
  IdFTPList,
  IdFTPServer,
  IdBaseComponent,
  IdFTPListOutput;

type
  TFtpServer = class
  private
    FServer: TIdFTPServer;
    FRootPath: TFileName;
  private
    function ReplaceChars(const APath: string): string;
    function GetSizeOfFile(const AFile: TFileName): Integer;
  private
    procedure OnStatus(ASender: TIdFTPServerContext; AStatusInfo: TIdStrings);
    procedure OnUserLogin(ASender: TIdFTPServerContext; const AUsername, APassword: string; var AAuthenticated: Boolean);
    procedure OnRemoveDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
    procedure OnMakeDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
    procedure OnRetrieveFile(ASender: TIdFTPServerContext; const AFileName: string; var VStream: TStream);
    procedure OnGetFileSize(ASender: TIdFTPServerContext; const AFilename: string; var VFileSize: Int64);
    procedure OnStoreFile(ASender: TIdFTPServerContext; const AFileName: string; AAppend: Boolean; var VStream: TStream);
    procedure OnListDirectory(ASender: TIdFTPServerContext; const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd, ASwitches: string);
    procedure OnDeleteFile(ASender: TIdFTPServerContext; const APathName: string);
    procedure OnChangeDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
    procedure OnSetModifiedTime(ASender: TIdFTPServerContext; const AFileName: string; var AFileTime: TIdDateTime);
  public
    constructor Create(
      const ARootPath: TFileName;
      const APortNumber: Integer
    );
    destructor Destroy; override;
  end;

implementation

uses
  SynLog,
  SynCommons;

{ TFtpServer }

constructor TFtpServer.Create(
  const ARootPath: TFileName;
  const APortNumber: Integer
);
begin
  inherited Create;

  FRootPath := IncludeTrailingPathDelimiter(ARootPath);

  FServer := TIdFTPServer.Create(nil);

  with FServer do begin
    DefaultPort := APortNumber;

    OnChangeDirectory := Self.OnChangeDirectory;
    OnGetFileSize := Self.OnGetFileSize;
    OnUserLogin := Self.OnUserLogin;
    OnListDirectory := Self.OnListDirectory;
    OnDeleteFile := Self.OnDeleteFile;
    OnRetrieveFile := Self.OnRetrieveFile;
    OnStoreFile := Self.OnStoreFile;
    OnMakeDirectory := Self.OnMakeDirectory;
    OnRemoveDirectory := Self.OnRemoveDirectory;
    OnSetModifiedTime := Self.OnSetModifiedTime;
    OnStat := Self.OnStatus;

    Active := True;
  end;

  TSynLog.Add.Log(sllInfo, StringToUTF8('Started FTP server on ftp://127.0.0.1:' + IntToStr(APortNumber) + '/'));
end;

destructor TFtpServer.Destroy;
begin
  FServer.Active := False;
  FServer.Free;
  inherited Destroy;
end;

function TFtpServer.ReplaceChars(const APath: string): string;
begin
  Result := StringReplace(APath, '/', '\', [rfReplaceAll]);
  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
end;

function TFtpServer.GetSizeOfFile(const AFile: TFileName): Integer;
var
  FStream : TFileStream;
begin
  try
    FStream := TFileStream.Create(AFile, fmOpenRead);
    try
      Result := FStream.Size;
    finally
      FreeAndNil(FStream);
    end;
  except
    Result := 0;
  end;
end;

procedure TFtpServer.OnStatus(ASender: TIdFTPServerContext; AStatusInfo: TIdStrings);
var
  VLines: RawUTF8;
begin
  VLines := StringToUTF8(AStatusInfo.Text);
  TSynLog.Add.LogLines(sllDebug, PUTF8Char(VLines));
end;

procedure TFtpServer.OnChangeDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
begin  
  if VDirectory = '../' then begin
    VDirectory := '/';
  end;
  ASender.CurrentDir := VDirectory;
end;

procedure TFtpServer.OnDeleteFile(ASender: TIdFTPServerContext;
  const APathName: string);
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp delete file: ' + APathName));
  if not DeleteFile(ReplaceChars(FRootPath + ASender.CurrentDir + PathDelim + APathName)) then begin
    RaiseLastOSError;
  end;
end;

procedure TFtpServer.OnListDirectory(ASender: TIdFTPServerContext;
  const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd,
  ASwitches: string);
var
  LFTPItem: TIdFTPListItem;
  SR: TSearchRec;
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp list dir: ' + APath));
  ADirectoryListing.DirFormat := doUnix;
  if FindFirst(ReplaceChars(FRootPath + APath + '\*.*'), faAnyFile, SR) = 0 then
  try
    repeat
      LFTPItem := ADirectoryListing.Add;
      LFTPItem.FileName := SR.Name;
      LFTPItem.Size := SR.Size;
      LFTPItem.ModifiedDate := FileDateToDateTime(SR.Time);
      if SR.Attr = faDirectory then begin
        LFTPItem.ItemType := ditDirectory;
      end else begin
        LFTPItem.ItemType := ditFile;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

procedure TFtpServer.OnStoreFile(ASender: TIdFTPServerContext;
  const AFileName: string; AAppend: Boolean; var VStream: TStream);
var
  VFileName: string;
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp store file: ' + AFileName));
  VFileName := ReplaceChars(FRootPath + AFilename);
  if not ForceDirectories(ExtractFilePath(VFileName)) then
    RaiseLastOSError;
  if not Aappend then
    VStream := TFileStream.Create(VFileName, fmCreate)
  else
    VStream := TFileStream.Create(VFileName, fmOpenReadWrite);
end;

procedure TFtpServer.OnGetFileSize(ASender: TIdFTPServerContext;
  const AFilename: string; var VFileSize: Int64);
var
  LFile : string;
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp get file size: ' + AFilename));
  LFile := ReplaceChars(FRootPath + AFilename);
  try
    if FileExists(LFile) then
      VFileSize :=  GetSizeOfFile(LFile)
    else
      VFileSize := 0;
  except
    VFileSize := 0;
  end;
end;

procedure TFtpServer.OnRetrieveFile(ASender: TIdFTPServerContext;
  const AFileName: string; var VStream: TStream);
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp retrieve file: ' + AFileName));
  VStream := TFileStream.Create(ReplaceChars(FRootPath+AFilename),fmOpenRead);
end;

procedure TFtpServer.OnMakeDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp make dir: ' + VDirectory));
  if not ForceDirectories(ReplaceChars(FRootPath + VDirectory)) then begin
    RaiseLastOSError;
  end;
end;

procedure TFtpServer.OnRemoveDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);

  function FullRemoveDir(Dir: string; StopIfNotAllDeleted: boolean): Boolean;
  var
    FN: string;
    SRec: TSearchRec;
  begin
    Result := False;
    if not DirectoryExists(Dir) then
      Exit;
    Result := True;
    Dir := IncludeTrailingPathDelimiter(Dir);
    if FindFirst(Dir + '*.*', faAnyFile, SRec) = 0 then
    try
      repeat
        FN := Dir + SRec.Name;
        if ((SRec.Attr and faDirectory) = faDirectory) then begin
          if (SRec.Name <> '') and (SRec.Name <> '.') and (SRec.Name <> '..') then begin
            Result := FullRemoveDir(FN, StopIfNotAllDeleted);
            if not Result and StopIfNotAllDeleted then
              Exit;
          end;
        end else begin
          Result := DeleteFile(FN);
          if not Result and StopIfNotAllDeleted then
            Exit;
        end;
      until FindNext(SRec) <> 0;
    finally
      FindClose(SRec);
    end;
    if not Result then
      Exit;
    if not RemoveDir(Dir) then
      Result := false;
  end;

var
  LFile : string;
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp remove dir: ' + VDirectory));
  LFile := ReplaceChars(FRootPath + VDirectory);
  FullRemoveDir(LFile, True);
end;

procedure TFtpServer.OnUserLogin(ASender: TIdFTPServerContext;
  const AUsername, APassword: string; var AAuthenticated: Boolean);
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp user login: ' + AUsername + '@' + APassword));
  AAuthenticated := True;
end;

procedure TFtpServer.OnSetModifiedTime(ASender: TIdFTPServerContext;
  const AFileName: string; var AFileTime: TIdDateTime);
var
  VFileName: string;
begin
  TSynLog.Add.Log(sllDebug, StringToUTF8('ftp set file date: ' + AFileName));
  VFileName := ReplaceChars(FRootPath + AFilename);
  if FileExists(VFileName) then begin
    if FileSetDate(VFileName, DateTimeToFileDate(AFileTime)) <> 0 then begin
      RaiseLastOSError;
    end;
  end;
end;

end.
