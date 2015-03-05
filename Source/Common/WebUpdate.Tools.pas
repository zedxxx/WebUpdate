unit WebUpdate.Tools;

interface

uses
  Types,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils,
  Classes,
  SynCommons;

type
  TCollectFileProgressEvent = procedure(const Directory: string; var SkipScan: Boolean) of object;

procedure CollectFiles(
  const ADirectory: string;
  const AMask: string;
  const AList: TStrings;
  const ARecurseSubdirectories: Boolean = False;
  const AOnProgress: TCollectFileProgressEvent = nil
);

{$IFDEF MSWINDOWS}
function FileTimeToDateTime(Time: TFileTime): TDateTime;
{$ENDIF}

function MD5(const FileName: TFileName): string; overload;
function MD5(AStream: TMemoryStream): string; overload;
function MD5(AStream: TStream): string; overload;

function WebToLocalFileName(const WebFileName: TFileName): TFileName; inline;
function LocalToWebFileName(const LocalFileName: TFileName): TFileName; inline;

function IsRelativePath(const Path: string): Boolean;
function SplitString(const S, Delimiters: string): Types.TStringDynArray;

function CopyFile(const Source, Target: TFileName; FailIfExists: Boolean = True): Boolean;

implementation

uses
  Masks,
  SynCrypto;

{$IFDEF MSWINDOWS}
function FileTimeToDateTime(Time: TFileTime): TDateTime;

  function InternalEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond,
    AMilliSecond: Word): TDateTime;
  var
    LTime: TDateTime;
    Success: Boolean;
  begin
    Result := 0;
    Success := TryEncodeDate(AYear, AMonth, ADay, Result);
    if Success then
    begin
      Success := TryEncodeTime(AHour, AMinute, ASecond, AMilliSecond, LTime);
      if Success then
        if Result >= 0 then
          Result := Result + LTime
        else
          Result := Result - LTime
    end;
  end;

var
  LFileTime: TFileTime;
  SysTime: TSystemTime;
begin
  Result := 0;
  FileTimeToLocalFileTime(Time, LFileTime);

  if FileTimeToSystemTime(LFileTime, SysTime) then
    with SysTime do
    begin
      Result := InternalEncodeDateTime(wYear, wMonth, wDay, wHour, wMinute,
        wSecond, wMilliseconds);
    end;
end;
{$ENDIF}

function MD5(AStream: TMemoryStream): string;
var
  VResult: RawUTF8;
begin
  VResult := MD5DigestToString(MD5Buf(AStream.Memory^, AStream.Size));
  Result := UTF8ToString(VResult);
end;

function MD5(AStream: TStream): string;
var
  VStream: TMemoryStream;
begin
  if AStream is TMemoryStream then begin
    Result := MD5(AStream as TMemoryStream);
  end else begin
    VStream := TMemoryStream.Create;
    try
      VStream.LoadFromStream(AStream);
      Result := MD5(VStream);
    finally
      VStream.Free;
    end;
  end;
end;

function MD5(const FileName: TFileName): string;
var
  VStream: TMemoryStream;
begin
  VStream := TMemoryStream.Create;
  try
    VStream.LoadFromFile(FileName);
    Result := MD5(VStream);
  finally
    VStream.Free;
  end;
end;

function WebToLocalFileName(const WebFileName: TFileName): TFileName; inline;
begin
  Result := StringReplace(WebFileName, '/', '\', [rfReplaceAll]);
end;

function LocalToWebFileName(const LocalFileName: TFileName): TFileName; inline;
begin
  Result := StringReplace(LocalFileName, '\', '/', [rfReplaceAll]);
end;

// from SysUtils.pas Delphi XE2
function IsRelativePath(const Path: string): Boolean;
var
  L: Integer;
begin
  L := Length(Path);
  Result := (L > 0) and (Path[1] <> PathDelim)
    {$IFDEF MSWINDOWS}and (L > 1) and (Path[2] <> ':'){$ENDIF MSWINDOWS};
end;

// from SysUtils.pas Delphi XE2
function FindDelimiter(const Delimiters, S: string; StartIdx: Integer = 1): Integer;
var
  Stop: Boolean;
  Len: Integer;
begin
  Result := 0;

  Len := Length(S);
  Stop := False;
  while (not Stop) and (StartIdx <= Len) do
    if IsDelimiter(Delimiters, S, StartIdx) then
    begin
      Result := StartIdx;
      Stop := True;
    end
    else
      Inc(StartIdx);
end;

// from StrUtils Delphi XE2
function SplitString(const S, Delimiters: string): Types.TStringDynArray;
var
  StartIdx: Integer;
  FoundIdx: Integer;
  SplitPoints: Integer;
  CurrentSplit: Integer;
  i: Integer;
begin
  Result := nil;

  if S <> '' then
  begin
    { Determine the length of the resulting array }
    SplitPoints := 0;
    for i := 1 to Length(S) do
      if IsDelimiter(Delimiters, S, i) then
        Inc(SplitPoints);

    SetLength(Result, SplitPoints + 1);

    { Split the string and fill the resulting array }
    StartIdx := 1;
    CurrentSplit := 0;
    repeat
      FoundIdx := FindDelimiter(Delimiters, S, StartIdx);
      if FoundIdx <> 0 then
      begin
        Result[CurrentSplit] := Copy(S, StartIdx, FoundIdx - StartIdx);
        Inc(CurrentSplit);
        StartIdx := FoundIdx + 1;
      end;
    until CurrentSplit = SplitPoints;

    // copy the remaining part in case the string does not end in a delimiter
    Result[SplitPoints] := Copy(S, StartIdx, Length(S) - StartIdx + 1);
  end;
end;

function CopyFile(const Source, Target: TFileName; FailIfExists: Boolean = True): Boolean;
begin
  Result := SynCommons.CopyFile(Source, Target, FailIfExists);
end;

procedure CollectFilesEx(
  const ADirectory: string;
  const AMask: TMask;
  const AList: TStrings;
  const ARecurseSubdirectories: Boolean;
  const AOnProgress: TCollectFileProgressEvent
);
const
  cFileMask = '*.*';
var
  VRec: TSearchRec;
  VDir: string;
  VSkipDir: Boolean;
begin
  VDir := IncludeTrailingPathDelimiter(ADirectory);

  if Assigned(AOnProgress) then begin
    AOnProgress(VDir, VSkipDir);
    if VSkipDir then begin
      Exit;
    end;
  end;

  if FindFirst(VDir + cFileMask, faAnyFile - faDirectory, VRec) = 0 then begin
    try
      repeat
        if AMask.Matches(VRec.Name) then begin
          AList.Add(VDir + VRec.Name);
        end;
      until FindNext(VRec) <> 0;
    finally
      FindClose(VRec);
    end;
  end;

  if ARecurseSubdirectories then begin
    if FindFirst(VDir + cFileMask, faDirectory, VRec) = 0 then begin
      try
        repeat
          if ((VRec.Attr and faDirectory) <> 0) and (VRec.Name <> '.') and (VRec.Name <> '..') then begin
            // recursion
            CollectFilesEx(VDir + VRec.Name, AMask, AList, ARecurseSubdirectories, AOnProgress);
          end;
        until FindNext(VRec) <> 0;
      finally
        FindClose(VRec);
      end;
    end;
  end;
end;

procedure CollectFiles(
  const ADirectory: string;
  const AMask: string;
  const AList: TStrings;
  const ARecurseSubdirectories: Boolean = False;
  const AOnProgress: TCollectFileProgressEvent = nil
);
var
  VMask: TMask;
begin
  VMask := TMask.Create(AMask);
  try
    CollectFilesEx(ADirectory, VMask, AList, ARecurseSubdirectories, AOnProgress);
  finally
    VMask.Free;
  end;
end;

end.
