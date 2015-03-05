unit WebUpdate.Classes.FileItem;

interface

uses
  SysUtils,  
  Classes,
  Contnrs,
  WebUpdate.Tools;

type
  TFileAction = (faAdd, faChange, faDelete, faVerify);

  TFileItem = class(TObject)
  private
    FFileName: TFileName;
    FLocalFileName: TFileName;
    FMD5Hash: string;
    FAction: TFileAction;
    FModified: TDateTime;
    FFileSize: Integer;
    procedure SetFileName(const Value: TFileName);
  protected
    procedure UpdateLocalFileName; inline;
  public
    constructor Create(
      const FileName: TFileName;
      const MD5Hash: string = '';
      const FileSize: Integer = 0;
      const Modified: TDateTime = 0
    );
  public
    property FileName: TFileName read FFileName write SetFileName;
    property LocalFileName: TFileName read FLocalFileName;
    property MD5Hash: string read FMD5Hash write FMD5Hash;
    property Action: TFileAction read FAction write FAction;
    property Modified: TDateTime read FModified write FModified;
    property FileSize: Integer read FFileSize write FFileSize;
  end;

  TFileItemList = class(TObjectList)
  public
    function LocateItemByFileName(const FileName: TFileName): TFileItem;
  end;

implementation

{ TFileItem }

constructor TFileItem.Create(
  const FileName: TFileName;
  const MD5Hash: string = '';
  const FileSize: Integer = 0;
  const Modified: TDateTime = 0
);
begin
  FFileName := FileName;
  FMD5Hash := MD5Hash;
  FFileSize := FileSize;
  FModified := Modified;
  FAction := faAdd;
  UpdateLocalFileName;
end;

procedure TFileItem.SetFileName(const Value: TFileName);
begin
  if FFileName <> Value then begin
    FFileName := Value;
    UpdateLocalFileName;
  end;
end;

procedure TFileItem.UpdateLocalFileName;
begin
  FLocalFileName := WebToLocalFileName(FFileName);
end;

{ TFileItemList }

function TFileItemList.LocateItemByFileName(
  const FileName: TFileName
): TFileItem;
var
  I: Integer;
  VItem: TFileItem;
begin
  Result := nil;
  for I := 0 to Count - 1 do begin
    VItem := TFileItem(Items[I]);
    if SameText(VItem.FileName, FileName) then begin
      Result := VItem;
      Exit;
    end;
  end;
end;

end.
