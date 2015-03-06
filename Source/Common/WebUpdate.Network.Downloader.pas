unit WebUpdate.Network.Downloader;

interface

uses
  Classes;

type
  TDownloaderProgress = procedure(
    ASender: TObject;
    const AWorkCount: Integer;
    const AContentLength: Integer;
    const AEncoding: string
  ) of object;

  TDownloader = class
  protected
    FOnProgress: TDownloaderProgress;
  public
    constructor Create(const AOnProgress: TDownloaderProgress = nil);
  public
    function Get(const AUrl: string; AResp: TStream): Integer; overload; virtual; abstract;
    function Get(const AUrl: string; out AText: string): Integer; overload; virtual; abstract;
    procedure Disconnect; virtual; abstract;
  end;

implementation

constructor TDownloader.Create(const AOnProgress: TDownloaderProgress);
begin
  inherited Create;
  FOnProgress := AOnProgress;
end;

end.
