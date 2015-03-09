program SimpleServer;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SynCommons,
  SynLog,
  Simple.HTTP.Server in 'Simple.HTTP.Server.pas',
  Simple.FTP.Server in 'Simple.FTP.Server.pas';

const
  cDefFtpPort = 21;
  cDefHttpPort = 80;

procedure Main;
var
  VRoot: TFileName;
  VFtpServer: TFtpServer;
  VHttpServer: THttpServer;
begin
  TSynLog.Add.Log(sllInfo, StringToUTF8('SimpleServer started'));

  VRoot := ExtractFilePath(ParamStr(0)) + 'SimpleServerRoot' + PathDelim;

  if not ForceDirectories(VRoot) then begin
    RaiseLastOSError;
  end;

  TSynLog.Add.Log(sllInfo, StringToUTF8('Root path: ' + VRoot));

  VFtpServer := TFtpServer.Create(VRoot, cDefFtpPort);
  try
    VHttpServer := THttpServer.Create(VRoot, cDefHttpPort);
    try
      TSynLog.Add.Log(sllInfo, StringToUTF8('Press [ENTER] to exit'));
      Readln;
    finally
      VHttpServer.Free;
    end;
  finally
    VFtpServer.Free;
  end;
end;

begin
  try
    with TSynLog.Family do begin
      Level := LOG_VERBOSE;
      EchoToConsole := LOG_VERBOSE;
      NoFile := True;
      WithUnitName := True; // you must set detailed Map file generation in proj options
    end;
    Main;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
