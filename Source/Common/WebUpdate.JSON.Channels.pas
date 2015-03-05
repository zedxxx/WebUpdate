unit WebUpdate.JSON.Channels;

interface

uses
  SysUtils,
  Contnrs,
  WebUpdate.JSON.Serializer;

{$METHODINFO ON}

type
  TWebUpdateChannelItem = class
  private
    FName: string;
    FFileName: string;
    FModified: TDateTime;
    FMD5: string;
  published
    property Name: string read FName write FName;
    property FileName: string read FFileName write FFileName;
    property Modified: TDateTime read FModified write FModified;
    property MD5: string read FMD5 write FMD5;
  end;

  TWebUpdateChannelItems = class(TObjectList);

  TWebUpdateChannels = class(TJsonSerializer)
  private
    FItems: TWebUpdateChannelItems;
  protected
    procedure OnBeforeLoad; override;
  public
    constructor Create;
    destructor Destroy; override;
    function GetItemForChannel(const AChannelName: string): TWebUpdateChannelItem;
  published
    property Items: TWebUpdateChannelItems read FItems;
  end;

implementation

{ TWebUpdateChannels }

constructor TWebUpdateChannels.Create;
begin
  inherited Create(TWebUpdateChannelItem);
  FItems := TWebUpdateChannelItems.Create(True);
end;

destructor TWebUpdateChannels.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TWebUpdateChannels.OnBeforeLoad;
begin
  FItems.Clear;
end;

function TWebUpdateChannels.GetItemForChannel(
  const AChannelName: string
): TWebUpdateChannelItem;
var
  I: Integer;
  VItem: TWebUpdateChannelItem;
begin
  Result := nil;
  for I := 0 to FItems.Count - 1 do begin
    VItem := TWebUpdateChannelItem(FItems[I]);
    if SameText(VItem.Name, AChannelName) then begin
      Result := VItem;
      Exit;
    end;
  end;
end;

initialization
  TJSONSerializer.RegisterClassForJSON(TWebUpdateChannels);
  TJSONSerializer.RegisterClassForJSON(TWebUpdateChannelItem);

end.
