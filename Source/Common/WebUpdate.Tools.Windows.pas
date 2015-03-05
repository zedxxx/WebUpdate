unit WebUpdate.Tools.Windows;

interface

procedure KillProcess(ProcessID: Integer);
function GetProcessIDForExecutable(const ExecutableFileName: string): Cardinal;
function GetProcessIDForWindow(const Caption: string): Cardinal;

function CloseApplication(const AExeName: string; const AWindowCaption: string;
  const ADelay: Integer; const AForceKill: Boolean = True): Boolean;

implementation

uses
  Windows,
  SysUtils,
  TlHelp32;

procedure KillProcess(ProcessID: Integer);
var
  ProcessHandle: THandle;
  ExitCode: Integer;
begin
  ProcessHandle := OpenProcess(PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION
    or PROCESS_VM_WRITE or PROCESS_VM_READ or PROCESS_TERMINATE, False,
    ProcessID);

  if ProcessHandle > 0 then
  try
    ExitCode := 0;
    GetExitCodeProcess(ProcessHandle, DWORD(ExitCode));
    TerminateProcess(ProcessHandle, ExitCode);
  finally
    CloseHandle(ProcessHandle);
  end;
end;

function GetProcessIDForExecutable(const ExecutableFileName: string): Cardinal;
var
  ContinueLoop: Boolean;
  SnapshotHandle: THandle;
  ProcessEntry32: TProcessEntry32;
  Found: Boolean;
begin
  ProcessEntry32.dwSize := SizeOf(TProcessEntry32);
  Found := False;

  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if SnapshotHandle > 0 then
  try
    ContinueLoop := Process32First(SnapshotHandle, ProcessEntry32);
    while Integer(ContinueLoop) <> 0 do begin
      if SameText(ExtractFileName(ProcessEntry32.szExeFile), ExecutableFileName) then begin
        Found := True;
        Break;
      end;
      ContinueLoop := Process32Next(SnapshotHandle, ProcessEntry32);
    end;
    if not Found then begin
      Result := 0;
      Exit;
    end;
  finally
    CloseHandle(SnapshotHandle);
  end;

  Result := ProcessEntry32.th32ProcessID;
end;

function GetProcessIDForWindow(const Caption: string): Cardinal;
var
  WinHwnd: HWND;
begin
  Result := 0;

  WinHwnd := FindWindow(nil, PChar(Caption));
  if not IsWindow(WinHwnd) then begin
    Exit;
  end;

  GetWindowThreadProcessID(WinHwnd, @Result);
end;

function CloseApplication(const AExeName: string; const AWindowCaption: string;
  const ADelay: Integer; const AForceKill: Boolean = True): Boolean;
var
  ProcessID: Integer;
  Counter: Integer;
begin
  Counter := 0;
  repeat
    ProcessID := 0;

    if AExeName <> '' then begin
      ProcessID := GetProcessIDForExecutable(AExeName)
    end else if AWindowCaption <> '' then begin
      ProcessID := GetProcessIDForWindow(AWindowCaption);
    end;

    if ProcessID = 0 then begin
      Result := True;
      Exit;
    end;

    Sleep(1 + ADelay);
    Inc(Counter);
  until Counter >= 10;

  if AForceKill then begin
    KillProcess(ProcessID);
    Result := True;
  end else begin
    Result := False;
  end;
end;

end.
