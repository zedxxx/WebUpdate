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
    procedure OnException(AContext:TIdContext; AException: Exception);
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
  Math,
  Classes;

type
  TSlowStream = class(TFileStream)
  private
    FSleep: Integer;
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    constructor Create(const AFileName: string; Mode: Word; Sleep: Integer);
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
    OnException := Self.OnException;
    Active := True;
  end;
  Writeln('[INFO] HTTP server: http://127.0.0.1:' + IntToStr(APortNumber) + '/');
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
  VFileName: TFileName;
  VFileSize: Integer;
  VBufferSize: Integer;
  VSleepInterval: Integer;
begin
  try
    Write(ARequestInfo.Command + ' - ' + ARequestInfo.Document);
    VFileName := ReplaceChars(FRootPath + ARequestInfo.Document);
    if FileExists(VFileName) then begin
      VFileSize := GetSizeOfFile(VFileName);
      Write(' - 200 OK - FileSize:' + IntToStr(VFileSize) + 'b');
      if FSlowDown then begin
        VBufferSize := AContext.Connection.IOHandler.SendBufferSize;
        VSleepInterval := CalcSleepInterval(VFileName, VFileSize, VBufferSize);
        Write(' - SlowDown [buf:' + IntToStr(VBufferSize) + 'b] [sleep:' + IntToStr(VSleepInterval) + 'ms]');
        AContext.Connection.IOHandler.SendBufferSize := VBufferSize;
        AResponseInfo.ContentStream := TSlowStream.Create(VFileName, fmOpenRead, VSleepInterval);
      end else begin
        AResponseInfo.ContentStream := TFileStream.Create(VFileName, fmOpenRead);
      end;
      Writeln;
    end else begin
      Writeln(' - 404 Not Found - ' + VFileName);
      Writeln;
      AResponseInfo.ResponseNo := 404;
      AResponseInfo.ContentText := '[' + Self.ClassName + '] File not found: ' + VFileName;
    end;
  except
    on E: Exception do
      OnException(AContext, E);
  end;
end;

procedure THttpServer.OnException(AContext:TIdContext; AException: Exception);
begin
  Writeln(AException.Message);
end;

function THttpServer.CalcSleepInterval(const AFile: TFileName;
  const AFileSize: Integer; var ABufSize: Integer): Integer;
begin
  if AFileSize > 0 then begin
    if ABufSize > AFileSize then begin
      ABufSize := 1024;
    end;
    Result := Ceil((10*1000) / (AFileSize / ABufSize));
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
