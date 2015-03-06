program SimpleServer;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Simple.HTTP.Server in 'Simple.HTTP.Server.pas',
  Simple.FTP.Server in 'Simple.FTP.Server.pas';

const
  cDefFtpPort = 21;
  cDefHttpPort = 80;

var
  VRoot: TFileName;
  VFtpServer: TFtpServer;
  VHttpServer: THttpServer;
begin
  try
    Writeln('SimpleServer started!');

    VRoot := ExtractFilePath(ParamStr(0)) + 'root' + PathDelim;

    if not ForceDirectories(VRoot) then begin
      RaiseLastOSError;
    end;

    Writeln('[INFO] Root path: ' + VRoot);

    VFtpServer := TFtpServer.Create(VRoot, cDefFtpPort);
    try
      VHttpServer := THttpServer.Create(VRoot, cDefHttpPort);
      try
        Writeln('[INFO] Press [ENTER] to exit');
        Readln;
      finally
        VHttpServer.Free;
      end;
    finally
      VFtpServer.Free;
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
