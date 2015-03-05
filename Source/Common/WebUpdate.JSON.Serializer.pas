unit WebUpdate.JSON.Serializer;

interface

uses
  SysUtils,
  SynCommons,
  mORMot;

type
  EJsonSerializer = class(Exception);

  TJsonSerializer = class(TObject)
  private
    procedure LoadFromStringInternal(AJson: PUTF8Char);
  protected
    FOptions: TTextWriterWriteObjectOptions;
    FObjectListItemClass: TClass;
    procedure OnBeforeLoad; virtual;
    procedure OnBeforeSave; virtual;
  public
    constructor Create(const AItemsClass: TClass = nil);
  public
    procedure LoadFromString(const AText: string);
    function SaveToString: string;
    procedure LoadFromFile(const AFileName: TFileName);
    procedure SaveToFile(const AFileName: TFileName);
  public
    class procedure RegisterClassForJSON(AItemClass: TClass);
  end;

implementation

resourcestring
  rsInvalidJSON = '%s - Invalid JSON string';
  rsFileNameIsEmpty = '%s - FileName is empty';
  rsFileNotExists = '%s - File not exists: %s';
  rsFileIsEmpty = '%s - File is empty: %s';

{ TJsonSerializer }

constructor TJsonSerializer.Create(const AItemsClass: TClass);
begin
  inherited Create;
  FObjectListItemClass := AItemsClass;
  FOptions := [woHumanReadable, woStoreClassName];
end;

procedure TJsonSerializer.LoadFromStringInternal(AJson: PUTF8Char);
var
  VIsValidJson: Boolean;
begin
  OnBeforeLoad;
  JSONToObject(Self, AJson, VIsValidJson, FObjectListItemClass);
  if not VIsValidJson then begin
    raise EJsonSerializer.CreateFmt(rsInvalidJSON, [Self.ClassName]);
  end;
end;

procedure TJsonSerializer.LoadFromString(const AText: string);
var
  VJson: RawUTF8;
begin
  //SetString(VJson, PAnsiChar(AText), Length(AText));
  VJson := StringToUTF8(AText);
  LoadFromStringInternal(PUTF8Char(VJson));
end;

procedure TJsonSerializer.LoadFromFile(const AFileName: TFileName);
var
  VJson: RawUTF8;
begin
  if AFileName = '' then begin
    raise EJsonSerializer.CreateFmt(rsFileNameIsEmpty, [Self.ClassName]);
  end;
  if not FileExists(AFileName) then begin
    raise EJsonSerializer.CreateFmt(rsFileNotExists, [Self.ClassName, AFileName]);
  end;
  VJson := AnyTextFileToRawUTF8(AFileName, True);
  if VJson <> '' then begin
    LoadFromStringInternal(PUTF8Char(VJson));
  end else begin
    raise EJsonSerializer.CreateFmt(rsFileIsEmpty, [Self.ClassName, AFileName]);
  end;
end;

function TJsonSerializer.SaveToString: string;
begin
  OnBeforeSave;
  Result := UTF8ToString(ObjectToJson(Self, FOptions));
end;

procedure TJsonSerializer.SaveToFile(const AFileName: TFileName);
begin
  OnBeforeSave;
  ObjectToJSONFile(Self, AFileName, FOptions);
end;

class procedure TJsonSerializer.RegisterClassForJSON(AItemClass: TClass);
begin
  mORMot.TJSONSerializer.RegisterClassForJSON(AItemClass);
end;

procedure TJsonSerializer.OnBeforeLoad;
begin
  // virtual
end;

procedure TJsonSerializer.OnBeforeSave;
begin
  // virtual
end;

end.
