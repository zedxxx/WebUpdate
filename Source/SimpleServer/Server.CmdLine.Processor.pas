unit Server.CmdLine.Processor;

interface

type
  TParams = record
    HttpServ: Boolean;
    HttpPort: Integer;
    FtpServ: Boolean;
    FtpPort: Integer;
    SlowDown: Boolean;
    RootPath: string;
  end;

function GetHelpText(const AppName: string): string;
function ReadParameters(var AParams: TParams): Boolean;

implementation

uses
  SysUtils,
  ArgumentParser;

const
  cDefFtpPort = 21;
  cDefHttpPort = 80;

function GetHelpText(const AppName: string): string;
const
  CR = #13#10;
begin
  Result :=
    'Usage:                                                                     ' + CR +
    '    ' + AppName + ' [Commands] [Options]                                   ' + CR +
                                                                                    CR +
    'Commands:                                                                  ' + CR +
    '    -h, --help              Print this help message and exit               ' + CR +
    '    --no-http               Disable HTTP server                            ' + CR +
    '    --no-ftp                Disable FTP server                             ' + CR +
    '    --no-slow-down          Disable slow network speed simulation          ' + CR +
    '                            (used for HTTP requests only)                  ' + CR +
    'Options:                                                                   ' + CR +
    '    --http-port=<port>      HTTP server port, default: 80                  ' + CR +
    '    --ftp-port=<port>       FTP server port, default: 21                   ' + CR +
    '    --root-path=<path>      Root path for HTTP and FTP servers             ' + CR +
                                                                                    CR +
    'Example:                                                                   ' + CR +
    '    ' + AppName + ' --no-ftp --no-slow-down --root-path=.\MyRootPath\      ' + CR +
                                                                                    CR;
end;

function ReadParameters(var AParams: TParams): Boolean;
var
  VParser: TArgumentParser;
  VParseResult: TParseResult;
begin
  AParams.HttpPort := cDefHttpPort;
  AParams.FtpPort := cDefFtpPort;
  AParams.RootPath := ExtractFilePath(ParamStr(0)) + 'Root' + PathDelim;

  VParser := TArgumentParser.Create;
  try
    VParser.AddArgument('--help');
    VParser.AddArgument('-h', 'help');

    VParser.AddArgument('--no-http', saBool);
    VParser.AddArgument('--no-ftp', saBool);
    VParser.AddArgument('--no-slow-down', saBool);

    VParser.AddArgument('--http-port', saStore);
    VParser.AddArgument('--ftp-port', saStore);
    VParser.AddArgument('--root-path', saStore);

    VParseResult := VParser.ParseArgs;
    try
      if VParseResult.HasArgument('help') then begin
        Result := False;
        Exit;
      end;

      AParams.HttpServ := not VParseResult.HasArgument('no-http');
      AParams.FtpServ := not VParseResult.HasArgument('no-ftp');
      AParams.SlowDown := not VParseResult.HasArgument('no-slow-down');

      if VParseResult.HasArgument('http-port') then begin
        AParams.HttpPort := StrToInt(VParseResult.GetValue('http-port'));
      end;
      if VParseResult.HasArgument('ftp-port') then begin
        AParams.FtpPort := StrToInt(VParseResult.GetValue('ftp-port'));
      end;
      if VParseResult.HasArgument('root-path') then begin
        AParams.RootPath := VParseResult.GetValue('root-path');
      end;
    finally
      VParseResult.Free;
    end;
  finally
    VParser.Free;
  end;

  Result := True;
end;

end.
