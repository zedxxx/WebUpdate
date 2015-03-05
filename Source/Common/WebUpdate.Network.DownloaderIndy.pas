unit WebUpdate.Network.DownloaderIndy;

interface

uses
  Classes,
  IdHTTP,
  IdComponent,
  WebUpdate.Network.Downloader;

type
  TDownloaderIndy = class(TDownloader)
  private
    FHttp: TIdHttp;
    procedure OnWorkEvent(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND}
    );
  public
    constructor Create(
      const AOpenSSLPath: string = '';
      const AOnProgress: TDownloaderProgress = nil
    );
    destructor Destroy; override;
  public
    function Get(const AUrl: string; AResp: TStream): Integer; overload; override;
    function Get(const AUrl: string; out AText: string): Integer; overload; override;
  end;

implementation

uses
  SysUtils,
  IdSSLOpenSSL;

constructor TDownloaderIndy.Create(
  const AOpenSSLPath: string;
  const AOnProgress: TDownloaderProgress
);
begin
  inherited Create(AOnProgress);

  FHttp := TIdHTTP.Create(nil);

  if AOpenSSLPath <> '' then begin
    if FileExists(AOpenSSLPath + 'ssleay32.dll') and FileExists(AOpenSSLPath + 'libeay32.dll') then begin
      FHttp.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    end;
  end;

  if Assigned(FOnProgress) then begin
    FHttp.OnWork := Self.OnWorkEvent;
  end;
end;

destructor TDownloaderIndy.Destroy;
begin
  FHttp.IOHandler.Free;
  FreeAndNil(FHttp);
end;

function TDownloaderIndy.Get(const AUrl: string; AResp: TStream): Integer;
begin
  FHttp.Get(AUrl, AResp);
  Result := FHttp.ResponseCode;
end;

function TDownloaderIndy.Get(const AUrl: string; out AText: string): Integer;
begin
  AText := FHttp.Get(AUrl);
  Result := FHttp.ResponseCode;
end;

procedure TDownloaderIndy.OnWorkEvent(
  ASender: TObject;
  AWorkMode: TWorkMode;
  AWorkCount: {$IF CompilerVersion > 21.0} Int64 {$ELSE} Integer {$IFEND}
);
begin
  FOnProgress(
    Self,
    AWorkCount,
    FHttp.Response.ContentLength,
    FHttp.Response.ContentEncoding
  );
end;

end.
