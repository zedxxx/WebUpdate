program SimpleServer;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SynCommons,
  SynLog,
  Simple.HTTP.Server in 'Simple.HTTP.Server.pas',
  Simple.FTP.Server in 'Simple.FTP.Server.pas',
  Server.CmdLine.Processor in 'Server.CmdLine.Processor.pas',
  ArgumentParser in '..\..\Utils\ArgumentParser.pas';

procedure Main(var AParams: TParams);
var
  VFtpServer: TFtpServer;
  VHttpServer: THttpServer;
begin
  TSynLog.Add.Log(sllInfo, StringToUTF8('SimpleServer started'));
  TSynLog.Add.Log(sllInfo, StringToUTF8('Root path: ' + AParams.RootPath));
  
  if not ForceDirectories(AParams.RootPath) then begin
    RaiseLastOSError;
  end;

  if AParams.FtpServ then begin
    VFtpServer := TFtpServer.Create(AParams.RootPath, AParams.FtpPort);
  end else begin
    VFtpServer := nil;
  end;
  try
    if AParams.HttpServ then begin
      VHttpServer := THttpServer.Create(AParams.RootPath, AParams.HttpPort);
    end else begin
      VHttpServer := nil;
    end;
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

var
  VParams: TParams;
begin
  try
    with TSynLog.Family do begin
      Level := LOG_VERBOSE;
      EchoToConsole := LOG_VERBOSE;
      NoFile := True;
      WithUnitName := True; // you must set Detailed Map File generation in proj options
    end;
    if ReadParameters(VParams) then begin
      Main(VParams);
    end else begin
      Writeln(GetHelpText(ExtractFileName(ParamStr(0))));
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
