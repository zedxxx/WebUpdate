unit Updater.CmdLine.Processor;

interface

uses
  WebUpdate.Classes.Updater;

function GetHelpText(const AppName: string): string;

function ScanParameters(
  const AWebUpdater: TWebUpdater;
  out AExeName: string;
  out AWindowCaption: string;
  out ADelay: Integer
): Boolean;

implementation

uses
  SysUtils,
  ArgumentParser;

function GetHelpText(const AppName: string): string;
const
  CR = #13#10;
begin
  Result :=
    'Usage:                                                                     ' + CR +
    '    ' + AppName + ' --url=<url> --channels-file=<file> [Commands] [Options]' + CR +
                                                                                    CR +
    'Commands:                                                                  ' + CR +
    '    -h, --help              Print this help message and exit               ' + CR +
                                                                                    CR +
    'Options:                                                                   ' + CR +
    '    --url=<url>             Base URL for JSON files                        ' + CR +
    '    --channel=<name>        Update Channel, default is "Stable"            ' + CR +
    '    --channels-file=<file>  Filename of channels definition file           ' + CR +
    '    --delay=<time>          Time in milliseconds before updating starts    ' + CR +
    '    --setup-file=<file>     Local filename of current setup                ' + CR +
    '    --app-exe-name=<name>   Name of main application executable            ' + CR +
    '    --app-caption=<caption> Caption of main application window             ' + CR +
                                                                                    CR +
    'Example:                                                                   ' + CR +
    '    ' + AppName + ' --url=http://test.com --channels-file=Channels.json    ' + CR +
                                                                                    CR;
end;

function ScanParameters(
  const AWebUpdater: TWebUpdater;
  out AExeName: string;
  out AWindowCaption: string;
  out ADelay: Integer
): Boolean;
var
  VParser: TArgumentParser;
  VParseResult: TParseResult;
begin
  AExeName := '';
  AWindowCaption := '';
  ADelay := 99;

  VParser := TArgumentParser.Create;
  try
    VParser.AddArgument('--help');
    VParser.AddArgument('-h', 'help');

    VParser.AddArgument('--url', saStore);
    VParser.AddArgument('--channel', saStore);
    VParser.AddArgument('--channels-file', saStore);
    VParser.AddArgument('--delay', saStore);
    VParser.AddArgument('--setup-file', saStore);
    VParser.AddArgument('--app-exe-name', saStore);
    VParser.AddArgument('--app-caption', saStore);

    VParseResult := VParser.ParseArgs;
    try
      if VParseResult.HasArgument('help') then begin
        Result := False;
        Exit;
      end;
      if VParseResult.HasArgument('url') then begin
        AWebUpdater.BaseURL := VParseResult.GetValue('url');
      end;
      if VParseResult.HasArgument('channel') then begin
        AWebUpdater.ChannelName := VParseResult.GetValue('channel');
      end;
      if VParseResult.HasArgument('channels-file') then begin
        AWebUpdater.ChannelsFileName := VParseResult.GetValue('channels-file');
      end;
      if VParseResult.HasArgument('delay') then begin
        ADelay := StrToIntDef(VParseResult.GetValue('delay'), ADelay);
      end;
      if VParseResult.HasArgument('setup-file') then begin
        AWebUpdater.LocalChannelFileName := VParseResult.GetValue('setup-file');
      end;
      if VParseResult.HasArgument('app-exe-name') then begin
        AExeName := VParseResult.GetValue('app-exe-name');
      end;
      if VParseResult.HasArgument('app-caption') then begin
        AWindowCaption := VParseResult.GetValue('app-caption');
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
