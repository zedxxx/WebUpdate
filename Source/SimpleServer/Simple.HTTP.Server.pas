unit Simple.HTTP.Server;

interface

uses
  SysUtils,
  IdContext,
  IdHTTPServer,
  IdCustomHTTPServer;

type
  THttpServer = class
  private
    FServer: TIdHTTPServer;
    FRootPath: TFileName;
    FSlowDown: Boolean;
    function ReplaceChars(const APath: string): string;
    function GetSizeOfFile(const AFile: TFileName): Integer;
    function CalcSleepInterval(const AFile: TFileName; const AFileSize: Integer; var ABufSize: Integer): Integer;
  private
    procedure OnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create(
      const ARootPath: TFileName;
      const APortNumber: Integer;
      const ASlowDown: Boolean = True
    );
    destructor Destroy; override;
  end;

implementation

uses
  Classes,
  SynLog,
  SynCommons;

type
  TSlowStream = class(TFileStream)
  private
    FSleep: Integer;
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    constructor Create(const AFileName: string; Mode: Word; Sleep: Integer);
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

{ THttpServer }

constructor THttpServer.Create(
  const ARootPath: TFileName;
  const APortNumber: Integer;
  const ASlowDown: Boolean
);
begin
  inherited Create;
  FRootPath := IncludeTrailingPathDelimiter(ARootPath);
  FSlowDown := ASlowDown;
  FServer := TIdHTTPServer.Create(nil);
  with FServer do begin
    DefaultPort := APortNumber;
    OnCommandGet := Self.OnCommandGet;
    Active := True;
  end;
  TSynLog.Add.Log(sllInfo, StringToUTF8('Started HTTP server on http://127.0.0.1:' + IntToStr(APortNumber) + '/'));
end;

destructor THttpServer.Destroy;
begin
  FServer.Active := False;
  FServer.Free;
  inherited Destroy;
end;

procedure THttpServer.OnCommandGet(
  AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo
);
var
  VLogMsg: string;
  VFileName: TFileName;
  VFileSize: Integer;
  VBufferSize: Integer;
  VSleepInterval: Integer;
begin
  TSynLog.Add.Log(sllHTTP, StringToUTF8(ARequestInfo.RawHTTPCommand));

  VFileName := ReplaceChars(FRootPath + ARequestInfo.Document);
  if FileExists(VFileName) then begin
    VFileSize := GetSizeOfFile(VFileName);

    VLogMsg := '200 (OK) ' + ARequestInfo.Document + ' ' + FormatByteSize(VFileSize);

    if FSlowDown then begin
      VBufferSize := AContext.Connection.IOHandler.SendBufferSize;
      VSleepInterval := CalcSleepInterval(VFileName, VFileSize, VBufferSize);

      VLogMsg := VLogMsg + ' SlowDown [buf:' + FormatByteSize(VBufferSize) +
        ' sleep:' + IntToStr(VSleepInterval) + 'ms]';

      AContext.Connection.IOHandler.SendBufferSize := VBufferSize;
      AResponseInfo.ContentStream := TSlowStream.Create(VFileName, fmOpenRead, VSleepInterval);
    end else begin
      AResponseInfo.ContentStream := TFileStream.Create(VFileName, fmOpenRead);
    end;
  end else begin
    VLogMsg := '404 (Not Found) ' + ARequestInfo.Document;

    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentText := '[' + Self.ClassName + '] 404 Not Found: ' + VFileName;
  end;

  TSynLog.Add.Log(sllHTTP, StringToUTF8(VLogMsg));
end;

function THttpServer.CalcSleepInterval(const AFile: TFileName;
  const AFileSize: Integer; var ABufSize: Integer): Integer;
begin
  if AFileSize > 0 then begin
    if ABufSize > AFileSize then begin
      ABufSize := 1024;
    end;
    Result := Round((10*1000) / (AFileSize / ABufSize));
    if Result > 1000 then begin
      Result := 1000;
    end;
  end else begin
    Result := 1;
  end;
end;

function THttpServer.ReplaceChars(const APath: string): string;
begin
  Result := StringReplace(APath, '/', '\', [rfReplaceAll]);
  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
end;

function THttpServer.GetSizeOfFile(const AFile: TFileName): Integer;
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

{ TSlowStream }

constructor TSlowStream.Create(const AFileName: string; Mode: Word; Sleep: Integer);
begin
  FSleep := Sleep;
  inherited Create(AFileName, Mode);
end;

function TSlowStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := inherited Read(Buffer, Count);
  if FSleep > 1 then begin
    Sleep(FSleep);
  end;
end;

end.
