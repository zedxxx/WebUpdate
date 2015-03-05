unit WebUpdate.JSON.Preferences;

interface

uses
  SysUtils,
  WebUpdate.JSON.Serializer;

{$METHODINFO ON}

type
  TWebUpdatePreferences = class(TJsonSerializer)
  private
    FFileName: TFileName;
    FRecentProject: string;
    FTop: Integer;
    FLeft: Integer;
    FViewFiles: Boolean;
  public
    constructor Create(const FileName: TFileName);
    destructor Destroy; override;
  published
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property RecentProject: string read FRecentProject write FRecentProject;
    property ViewFiles: Boolean read FViewFiles write FViewFiles;
  end;

implementation

{ TWebUpdatePreferences }

constructor TWebUpdatePreferences.Create(const FileName: TFileName);
begin
  inherited Create;
  FLeft := 16;
  FTop := 16;
  FFileName := FileName;
  if FileExists(FFileName) then
    LoadFromFile(FFileName);
end;

destructor TWebUpdatePreferences.Destroy;
begin
  SaveToFile(FFileName);
  inherited Destroy;
end;

initialization
  TJSONSerializer.RegisterClassForJSON(TWebUpdatePreferences);

end.
