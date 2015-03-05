program Updater;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ArgumentParser in '..\..\Utils\ArgumentParser.pas',
  WebUpdate.JSON.Channel in '..\Common\WebUpdate.JSON.Channel.pas',
  WebUpdate.JSON.Channels in '..\Common\WebUpdate.JSON.Channels.pas',
  WebUpdate.JSON.Serializer in '..\Common\WebUpdate.JSON.Serializer.pas',
  WebUpdate.Tools in '..\Common\WebUpdate.Tools.pas',
  WebUpdate.Tools.Windows in '..\Common\WebUpdate.Tools.Windows.pas',
  WebUpdate.Classes.Updater in '..\Common\WebUpdate.Classes.Updater.pas',
  WebUpdate.Classes.FileItem in '..\Common\WebUpdate.Classes.FileItem.pas',
  WebUpdate.Classes.UpdaterThread in '..\Common\WebUpdate.Classes.UpdaterThread.pas',
  WebUpdate.Network.Downloader in '..\Common\WebUpdate.Network.Downloader.pas',
  WebUpdate.Network.DownloaderFactory in '..\Common\WebUpdate.Network.DownloaderFactory.pas',
  WebUpdate.Network.DownloaderIndy in '..\Common\WebUpdate.Network.DownloaderIndy.pas',
  Updater.CmdLine.Processor in 'Updater.CmdLine.Processor.pas';

resourcestring
  rsNoURLSpecified = 'Error: No URL specified!';
  rsNoChannelsDefinitionSpecified = 'Error: No file name for channels definition specified!';

procedure WriteUsage;
begin
  Writeln(GetHelpText(ExtractFileName(ParamStr(0))));
end;

procedure Main;
var
  VWebUpdater: TWebUpdater;
  VDelay: Integer;
  VAppExecutable: string;
  VAppWindowCaption: string;
begin
  VWebUpdater := TWebUpdater.Create;
  try
    if not ScanParameters(VWebUpdater, VAppExecutable, VAppWindowCaption, VDelay) then begin
      WriteUsage;
      Halt(101);
    end;

    if VWebUpdater.BaseURL = '' then begin
      WriteLn(rsNoURLSpecified);
      WriteLn('');
      WriteUsage;
      Halt(102);
    end;

    if VWebUpdater.ChannelsFileName = '' then begin
      WriteLn(rsNoChannelsDefinitionSpecified);
      WriteLn('');
      WriteUsage;
      Halt(103);
    end;

    if (VAppExecutable <> '') or (VAppWindowCaption <> '') then begin
      Sleep(1 + VDelay);
      CloseApplication(VAppExecutable, VAppWindowCaption, VDelay);
    end;

    VWebUpdater.PerformWebUpdate;

  finally
    VWebUpdater.Free;
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
