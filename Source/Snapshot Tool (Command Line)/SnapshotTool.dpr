program SnapshotTool;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ArgumentParser in '..\..\Utils\ArgumentParser.pas',
  WebUpdate.Admin.Actions in '..\Common\WebUpdate.Admin.Actions.pas',
  WebUpdate.Classes.WebUpdate in '..\Common\WebUpdate.Classes.WebUpdate.pas',
  WebUpdate.JSON.Channel in '..\Common\WebUpdate.JSON.Channel.pas',
  WebUpdate.JSON.Channels in '..\Common\WebUpdate.JSON.Channels.pas',
  WebUpdate.JSON.Project in '..\Common\WebUpdate.JSON.Project.pas',
  WebUpdate.JSON.Serializer in '..\Common\WebUpdate.JSON.Serializer.pas',
  WebUpdate.Tools in '..\Common\WebUpdate.Tools.pas';

type
  TWebUpdateCommand = (wuSnapshot, wuUpload, wuCopy);
  TWebUpdateCommands = set of TWebUpdateCommand;

function GetHelpText(const AppName: string): string;
const
  CR = #13#10;
begin
  Result :=
    'Usage:                                                                     ' + CR +
    '    ' + AppName + ' <Project.wup> Commands [Options]                       ' + CR +
                                                                                    CR +
    'Arguments:                                                                 ' + CR +
    '    <Project.wup>           Your project file name                         ' + CR +
                                                                                    CR +
    'Commands:                                                                  ' + CR +
    '    -h, --help              Print this help message and exit               ' + CR +
    '    -s, --snapshot          Take snapshot                                  ' + CR +
    '    -c, --copy              Copy to path                                   ' + CR +
    '    -u, --upload            Upload snapshot to server                      ' + CR +
                                                                                    CR +
    'Options:                                                                   ' + CR +
    '    --channel=<name>        default: "Nightly"                             ' + CR +
    '    --ftp-host=<host>       FTP host name, overrides project''s default    ' + CR +
    '    --ftp-user=<username>   FTP user name, overrides project''s default    ' + CR +
    '    --ftp-pass=<password>   FTP password, overrides project''s default     ' + CR +
    '    --copy-path=<path>      Path of snapshot copies                        ' + CR +
    '    --collect-files         Scan and add all new files                     ' + CR +
                                                                                    CR +
    'Example:                                                                   ' + CR +
    '    ' + AppName + ' MyProj.wup -scu --channel=Stable                       ' + CR +
                                                                                    CR;
end;

function ReadCmdLine(var AProject: TWebUpdateProject; var ACommands: TWebUpdateCommands): Boolean;
var
  VProj: TFileName;
  VParser: TArgumentParser;
  VParseResult: TParseResult;
begin
  Result := False;
  if ParamCount > 1 then begin
    VProj := ParamStr(1);
    
    if FileExists(VProj) then begin
      AProject.LoadFromFile(VProj);
    end else begin
      WriteLn('ERROR: File "' + VProj + '" does not exist!');
      WriteLn;
      Exit;
    end;

    VParser := TArgumentParser.Create;
    try
      VParser.AddArgument('--help');
      VParser.AddArgument('-h', 'help');

      VParser.AddArgument('--snapshot');
      VParser.AddArgument('-s', 'snapshot');

      VParser.AddArgument('--copy');
      VParser.AddArgument('-c', 'copy');

      VParser.AddArgument('--upload');
      VParser.AddArgument('-u', 'upload');

      VParser.AddArgument('--copy-path', saStore);
      VParser.AddArgument('--channel', saStore);
      VParser.AddArgument('--collect-files');

      VParseResult := VParser.ParseArgs;
      try
        if VParseResult.HasArgument('help') then begin
          Exit;
        end;
        if VParseResult.HasArgument('snapshot') then begin
          ACommands := ACommands + [wuSnapshot];
        end;
        if VParseResult.HasArgument('copy') then begin
          ACommands := ACommands + [wuCopy];
        end;
        if VParseResult.HasArgument('upload') then begin
          ACommands := ACommands + [wuUpload];
        end;
        if VParseResult.HasArgument('copy-path') then begin
          AProject.Copy.Path := VParseResult.GetValue('copy-path');
        end;
        if VParseResult.HasArgument('channel') then begin
          AProject.ChannelName := VParseResult.GetValue('channel');
        end;
        if VParseResult.HasArgument('collect-files') then begin
          AProject.AutoAddNewFiles := True;
        end;
        Result := (ACommands <> []);
      finally
        VParseResult.Free;
      end;
    finally
      VParser.Free;
    end;
  end;
end;

procedure Main;
var
  VProject: TWebUpdateProject;
  VCommands: TWebUpdateCommands;
begin
  VCommands := [];
  VProject := TWebUpdateProject.Create;
  try
    if not ReadCmdLine(VProject, VCommands) then begin
      Writeln(GetHelpText(ExtractFileName(ParamStr(0))));
      Exit;
    end;
    if VProject.AutoCopyUpload then begin
      if VProject.Copy.Enabled then begin
        VCommands := VCommands + [wuCopy];
      end;
      if VProject.FTP.Server <> '' then begin
        VCommands := VCommands + [wuUpload];
      end;
    end;
    if wuSnapshot in VCommands then begin
      TakeSnapshot(VProject);
    end;
    if wuCopy in VCommands then begin
      CopySnapshot(VProject);
    end;
    if wuUpload in VCommands then begin
      UploadSnapshot(VProject);
    end;
  finally
    VProject.Free;
  end;
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
