unit WebUpdate.Classes.WebUpdate;

interface

uses
  System.SysUtils, System.Classes, WebUpdate.JSON.Channels,
  WebUpdate.JSON.Channel;

type
  TWebUpdate = class
  private
    FAutoGet: Boolean;
    FBaseURL: string;
    FChannelName: string;
    FChannels: TWebUpdateChannels;
    FChannelsFile: TFileName;
    FDownloadUpdater: Boolean;
    FLastModified: TDateTime;
    FUpdaterFileName: TFileName;
    procedure SetChannelName(const Value: string);
  public
    constructor Create; overload;
    constructor Create(BaseURL: string; ChannelsFileName: TFileName = ''); overload;
    destructor Destroy; override;

    function CheckForUpdate: Boolean;
    procedure GetLocalChannelInformation;
    procedure GetChannelsInformationFromServer;
    procedure GetChannels(Channels: TStrings);
    procedure PerformUpdate;
    procedure PerformDownloadUpdater;

    property AutoGetLocalChannelInformation: Boolean read FAutoGet write FAutoGet;
    property BaseURL: string read FBaseURL write FBaseURL;
    property ChannelName: string read FChannelName write SetChannelName;
    property ChannelsFileName: TFileName read FChannelsFile write FChannelsFile;
    property LastModified: TDateTime read FLastModified;
    property DownloadUpdater: Boolean read FDownloadUpdater write FDownloadUpdater;
    property UpdaterFileName: TFileName read FUpdaterFileName write FUpdaterFileName;
  end;

implementation

uses
  System.StrUtils, WinApi.ShellApi, WinApi.Windows, Vcl.Forms, IdHTTP;

{ TWebUpdate }

constructor TWebUpdate.Create;
begin
  FAutoGet := False;
  FBaseURL := '';
  FChannelsFile := 'Channels.json';
  FChannelName := 'Stable';
  FChannels := TWebUpdateChannels.Create;
  FUpdaterFileName := 'UpdaterWizard.exe';
end;

constructor TWebUpdate.Create(BaseURL: string; ChannelsFileName: TFileName = '');
begin
  Create;
  FBaseURL := BaseURL;
  if ChannelsFileName <> '' then
    FChannelsFile := ChannelsFileName;
end;

destructor TWebUpdate.Destroy;
begin
  FChannels.Free;
  inherited;
end;

procedure TWebUpdate.PerformDownloadUpdater;
var
  Http: TIdHTTP;
  Text: string;
  Success: Boolean;
begin
  // get channels file (JSON) text
  if StartsText('http://', FBaseURL) or StartsText('https://', FBaseURL) then
  begin
    Http := TIdHTTP.Create(nil);
    try
      try
        // get text from URI
        Text := Http.Get(FBaseURL + FUpdaterFileName);

        // check if text is available (might need check for JSON format)
        Success := Text <> '';
      except
        Success := False;
      end;

      // ignore errors here!
      if not Success then
        Exit;
    finally
      Http.Free;
    end;
  end
  else
    raise Exception.Create('Protocol not supported');
end;

procedure TWebUpdate.GetChannelsInformationFromServer;
var
  Http: TIdHTTP;
  Text: string;
  Success: Boolean;
begin
  // get channels file (JSON) text
  if StartsText('http://', FBaseURL) or StartsText('https://', FBaseURL) then
  begin
    Http := TIdHTTP.Create(nil);
    try
      try
        // get text from URI
        Text := Http.Get(FBaseURL + FChannelsFile);

        // check if text is available (might need check for JSON format)
        Success := Text <> '';
      except
        Success := False;
      end;

      // ignore errors here!
      if not Success then
        Exit;
    finally
      Http.Free;
    end;
  end
  else
    raise Exception.Create('Protocol not supported');

  FChannels.LoadFromString(Text);
end;

procedure TWebUpdate.GetChannels(Channels: TStrings);
var
  Item: TWebUpdateChannelItem;
begin
  // first get channels information from server
  GetChannelsInformationFromServer;

  Channels.Clear;
  for Item in FChannels.Items do
    Channels.Add(Item.Name)
end;

procedure TWebUpdate.GetLocalChannelInformation;
var
  LocalPath: TFileName;
  LocalSetup: TWebUpdateChannelSetup;
begin
  // check if a local file is present otherwise exit
  LocalPath := ExtractFilePath(ParamStr(0));
  if not FileExists(LocalPath + 'WebUpdate.json') then
    Exit;

  LocalSetup := TWebUpdateChannelSetup.Create;
  try
    LocalSetup.LoadFromFile(LocalPath + 'WebUpdate.json');

    FChannelName := LocalSetup.ChannelName;
  finally
    LocalSetup.Free;
  end;
end;

function TWebUpdate.CheckForUpdate: Boolean;
var
  ChannelItem: TWebUpdateChannelItem;
begin
  Result := False;

  // eventually get information about local channel
  if FAutoGet then
    GetLocalChannelInformation;

  // locate local channel
  for ChannelItem in FChannels.Items do
    if ChannelItem.Name = FChannelName then
      if ChannelItem.Modified > FLastModified then
        Exit(True);
end;

procedure TWebUpdate.PerformUpdate;
var
  LocalPath: string;
  Parameters: string;
begin
  // eventually download updater
  if FDownloadUpdater then
    PerformDownloadUpdater;

  LocalPath := ExtractFilePath(ParamStr(0));
  if FileExists(LocalPath + FUpdaterFileName) then
  begin
    Parameters := '-u=' + BaseURL + ' -d=1000 -c=' + ChannelName;
    ShellExecute(Application.Handle, 'open', PChar(LocalPath + FUpdaterFileName),
      PChar(Parameters), PChar(LocalPath), SW_SHOW);
    Application.Terminate;
  end;
end;

procedure TWebUpdate.SetChannelName(const Value: string);
begin
  if FChannelName <> Value then
  begin
    FChannelName := Value;
    FLastModified := 0;
  end;
end;

end.
