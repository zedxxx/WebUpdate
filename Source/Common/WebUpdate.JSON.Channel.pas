unit WebUpdate.JSON.Channel;

interface

uses
  Classes,
  SysUtils,
  Contnrs,
  WebUpdate.JSON.Serializer;

{$METHODINFO ON}

type
  TWebUpdateFileAction = (iaAdd, iaDelete);

  TWebUpdateFileItem = class
  private
    FFileName: string;
    FFileSize: Integer;
    FModified: TDateTime;
    FMD5Hash: string;
    FAction: TWebUpdateFileAction;
  published
    property Action: TWebUpdateFileAction read FAction write FAction;
    property FileName: string read FFileName write FFileName;
    property FileSize: Integer read FFileSize write FFileSize;
    property Modified: TDateTime read FModified write FModified;
    property MD5Hash: string read FMD5Hash write FMD5Hash;
  end;

  TWebUpdateFileItems = class(TObjectList);

  TWebUpdateChannelSetup = class(TJsonSerializer)
  private
    FChannelName: string;
    FAppName: string;
    FModified: TDateTime;
    FItems: TWebUpdateFileItems;
  protected
    procedure OnBeforeLoad; override;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property AppName: string read FAppName write FAppName;
    property ChannelName: string read FChannelName write FChannelName;
    property Modified: TDateTime read FModified write FModified;
    property Items: TWebUpdateFileItems read FItems;
  end;

implementation

{ TWebUpdateChannelSetup }

constructor TWebUpdateChannelSetup.Create;
begin
  inherited Create(TWebUpdateFileItem);
  FItems := TWebUpdateFileItems.Create(True);
end;

destructor TWebUpdateChannelSetup.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TWebUpdateChannelSetup.OnBeforeLoad;
begin
  FItems.Clear;
end;

initialization
  TJSONSerializer.RegisterClassForJSON(TWebUpdateChannelSetup);
  TJSONSerializer.RegisterClassForJSON(TWebUpdateFileItem);

end.
