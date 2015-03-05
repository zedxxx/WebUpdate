unit WebUpdate.JSON.Project;

interface

uses
  SysUtils,
  WebUpdate.JSON.Serializer;

{$METHODINFO ON}

type
  TWebUpdateProject = class(TJsonSerializer)
  type
    TFTPOptions = class
    private
      FPassword: string;
      FUsername: string;
      FServer: string;
    public
      constructor Create;
    published
      property Server: string read FServer write FServer;
      property Username: string read FUsername write FUsername;
      property Password: string read FPassword write FPassword;
    end;

    TCopyOptions = class
    private
      FPath: string;
      FEnabled: Boolean;
    public
      constructor Create;
    published
      property Path: string read FPath write FPath;
      property Enabled: Boolean read FEnabled write FEnabled;
    end;
  private
    FApplicationName: string;
    FAutoAddNewFiles: Boolean;
    FAutoCopyUpload: Boolean;
    FBaseDirectory: string;
    FChannelsFilename: string;
    FCopyOptions: TCopyOptions;
    FCurrentChannel: string;
    FFtpOptions: TFTPOptions;
    FUseMD5: Boolean;
    FLocalPath: string;
    function GetFullChannelsFilename: string;
    function GetBasePath: string;
    function GetChannelsPath: string;
    procedure SetLocalPath(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    property BasePath: string read GetBasePath;
    property ChannelsPath: string read GetChannelsPath;
    property FullChannelsFilename: string read GetFullChannelsFilename;
    property LocalPath: string read FLocalPath write SetLocalPath;
  published
    property AutoCopyUpload: Boolean read FAutoCopyUpload write FAutoCopyUpload;
    property AutoAddNewFiles: Boolean read FAutoAddNewFiles write FAutoAddNewFiles;
    property ApplicationName: string read FApplicationName write FApplicationName;
    property BaseDirectory: string read FBaseDirectory write FBaseDirectory;
    property ChannelsFilename: string read FChannelsFilename write FChannelsFilename;
    property ChannelName: string read FCurrentChannel write FCurrentChannel;
    property UseMD5: Boolean read FUseMD5 write FUseMD5;
    property FTP: TFTPOptions read FFtpOptions;
    property Copy: TCopyOptions read FCopyOptions;
  end;

implementation

uses
  WebUpdate.Tools;

{ TWebUpdateProject.TFTPOptions }

constructor TWebUpdateProject.TFTPOptions.Create;
begin
  inherited Create;
  FServer := '';
  FUsername := '';
  FPassword := '';
end;

{ TWebUpdateProject.TCopyOptions }

constructor TWebUpdateProject.TCopyOptions.Create;
begin
  inherited Create;
  FPath := '';
  FEnabled := False;
end;

{ TWebUpdateProject }

constructor TWebUpdateProject.Create;
begin
  inherited Create;
  FFtpOptions := TFTPOptions.Create;
  FCopyOptions := TCopyOptions.Create;
  FCurrentChannel := 'Nightly';
  FLocalPath := '';
end;

destructor TWebUpdateProject.Destroy;
begin
  FCopyOptions.Free;
  FFtpOptions.Free;
  inherited;
end;

procedure TWebUpdateProject.SetLocalPath(const AValue: string);
begin
  FLocalPath := IncludeTrailingPathDelimiter(AValue);
end;

function TWebUpdateProject.GetBasePath: string;
begin
  if FBaseDirectory = '' then begin
    Result := FLocalPath;
  end else begin
    Result := IncludeTrailingPathDelimiter(FBaseDirectory);
    if IsRelativePath(Result) then begin
      Result := FLocalPath + Result;
    end;
  end;
end;

function TWebUpdateProject.GetChannelsPath: string;
begin
  Result := GetFullChannelsFilename;
  if Result = '' then begin
    Result := FLocalPath;
  end else begin
    Result := ExtractFilePath(Result);
    if IsRelativePath(Result) then begin
      Result := FLocalPath + Result;
    end;
  end;
end;

function TWebUpdateProject.GetFullChannelsFilename: string;
begin
  if FChannelsFilename <> '' then begin
    if FBaseDirectory <> '' then begin
      Result := IncludeTrailingPathDelimiter(FBaseDirectory) + FChannelsFilename;
    end else begin
      Result := FLocalPath + FChannelsFilename;
    end;
  end else begin
    Result := '';
  end;
end;

initialization
  TJSONSerializer.RegisterClassForJSON(TWebUpdateProject.TFTPOptions);
  TJSONSerializer.RegisterClassForJSON(TWebUpdateProject.TCopyOptions);
  TJSONSerializer.RegisterClassForJSON(TWebUpdateProject);

end.
