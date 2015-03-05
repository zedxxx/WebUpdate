unit WebUpdate.Network.DownloaderFactory;

interface

uses
  WebUpdate.Network.Downloader;

function CreateDownloader(
  const AOnProgress: TDownloaderProgress = nil
): TDownloader; overload;

function CreateDownloader(
  const AOpenSSLPath: string = '';
  const AOnProgress: TDownloaderProgress = nil
): TDownloader; overload;

implementation

uses
  WebUpdate.Network.DownloaderIndy;

function CreateDownloader(
  const AOnProgress: TDownloaderProgress = nil
): TDownloader; overload;
begin
  // ToDo
  Result := nil;
  Assert(Result <> nil);
end;

function CreateDownloader(
  const AOpenSSLPath: string = '';
  const AOnProgress: TDownloaderProgress = nil
): TDownloader;
begin
  Result := TDownloaderIndy.Create(AOpenSSLPath, AOnProgress);
end;

end.
