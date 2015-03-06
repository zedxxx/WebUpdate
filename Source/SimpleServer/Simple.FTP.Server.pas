unit Simple.FTP.Server;

interface

uses
  Windows,
  SysUtils,
  Classes,
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
    procedure OnUserLogin(ASender: TIdFTPServerContext; const AUsername, APassword: string; var AAuthenticated: Boolean);
    procedure OnRemoveDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
    procedure OnMakeDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
    procedure OnRetrieveFile(ASender: TIdFTPServerContext; const AFileName: string; var VStream: TStream);
    procedure OnGetFileSize(ASender: TIdFTPServerContext; const AFilename: string; var VFileSize: Int64);
    procedure OnStoreFile(ASender: TIdFTPServerContext; const AFileName: string; AAppend: Boolean; var VStream: TStream);
    procedure OnListDirectory(ASender: TIdFTPServerContext; const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd, ASwitches: string);
    procedure OnDeleteFile(ASender: TIdFTPServerContext; const APathName: string);
    procedure OnChangeDirectory(ASender: TIdFTPServerContext; var VDirectory: string);
  public
    constructor Create(
      const ARootPath: TFileName;
      const APortNumber: Integer
    );
    destructor Destroy; override;
  end;

implementation

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
    
    {
    ExceptionReply.Code := '500';
    ExceptionReply.Text.Add('Unknown Internal Error');

    Greeting.Code := '220';
    Greeting.Text.Add('Indy FTP Server ready.');

    HelpReply.Text.Add('Help follows');

    MaxConnectionReply.Code := '300';
    MaxConnectionReply.Text.Add('Too many connections. Try again later.');

    ReplyUnknownCommand.Code := '500';
    ReplyUnknownCommand.Text.Add('Syntax error, command unrecognized.');

    AllowAnonymousLogin := True;
    AnonymousAccounts.Add('anonymous');
    AnonymousAccounts.Add('ftp');
    AnonymousAccounts.Add('guest');
    AnonymousPassStrictCheck := False;

    SystemType := 'WIN32';

    MLSDFacts := [];

    ReplyUnknownSITCommand.Code := '500';
    ReplyUnknownSITCommand.Text.Add('Invalid SITE command.');
    }

    OnChangeDirectory := Self.OnChangeDirectory;
    OnGetFileSize := Self.OnGetFileSize;
    OnUserLogin := Self.OnUserLogin;
    OnListDirectory := Self.OnListDirectory;
    OnDeleteFile := Self.OnDeleteFile;
    OnRetrieveFile := Self.OnRetrieveFile;
    OnStoreFile := Self.OnStoreFile;
    OnMakeDirectory := Self.OnMakeDirectory;
    OnRemoveDirectory := Self.OnRemoveDirectory;

    Active := True;
  end;

  Writeln('[INFO] FTP server: ftp://127.0.0.1:' + IntToStr(APortNumber) + '/');
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
  DeleteFile(ReplaceChars(FRootPath + ASender.CurrentDir + PathDelim + APathName));
end;

procedure TFtpServer.OnListDirectory(ASender: TIdFTPServerContext;
  const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd,
  ASwitches: string);
var
  LFTPItem: TIdFTPListItem;
  SR: TSearchRec;
begin
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
begin
  if not Aappend then
    VStream := TFileStream.Create(ReplaceChars(FRootPath + AFilename), fmCreate)
  else
    VStream := TFileStream.Create(ReplaceChars(FRootPath + AFilename), fmOpenWrite);
end;

procedure TFtpServer.OnGetFileSize(ASender: TIdFTPServerContext;
  const AFilename: string; var VFileSize: Int64);
var
  LFile : string;
begin
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
  VStream := TFileStream.Create(ReplaceChars(FRootPath+AFilename),fmOpenRead);
end;

procedure TFtpServer.OnMakeDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
begin
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
  LFile := ReplaceChars(FRootPath + VDirectory);
  FullRemoveDir(LFile, True);
end;

procedure TFtpServer.OnUserLogin(ASender: TIdFTPServerContext;
  const AUsername, APassword: string; var AAuthenticated: Boolean);
begin
  // We just set AAuthenticated to true so any username / password is accepted
  // You should check them here - AUsername and APassword
  AAuthenticated := True;
end;

end.
