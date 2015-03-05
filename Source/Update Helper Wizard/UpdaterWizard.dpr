program UpdaterWizard;

uses
  Forms,
  WebUpdate.Classes.Updater in '..\Common\WebUpdate.Classes.Updater.pas',
  WebUpdate.JSON.Serializer in '..\Common\WebUpdate.JSON.Serializer.pas',
  WebUpdate.JSON.Channel in '..\Common\WebUpdate.JSON.Channel.pas',
  WebUpdate.JSON.Channels in '..\Common\WebUpdate.JSON.Channels.pas',
  WebUpdate.GUI.Updater in 'WebUpdate.GUI.Updater.pas' {FormWebUpdate},
  WebUpdate.Tools in '..\Common\WebUpdate.Tools.pas',
  WebUpdate.Classes.FileItem in '..\Common\WebUpdate.Classes.FileItem.pas',
  WebUpdate.Classes.UpdaterThread in '..\Common\WebUpdate.Classes.UpdaterThread.pas',
  WebUpdate.Network.DownloaderIndy in '..\Common\WebUpdate.Network.DownloaderIndy.pas',
  WebUpdate.Network.Downloader in '..\Common\WebUpdate.Network.Downloader.pas',
  WebUpdate.Network.DownloaderFactory in '..\Common\WebUpdate.Network.DownloaderFactory.pas',
  WebUpdate.Tools.Windows in '..\Common\WebUpdate.Tools.Windows.pas',
  Updater.CmdLine.Processor in '..\Update Helper (Command-line)\Updater.CmdLine.Processor.pas',
  ArgumentParser in '..\..\Utils\ArgumentParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormWebUpdate, FormWebUpdate);
  Application.Run;
end.

