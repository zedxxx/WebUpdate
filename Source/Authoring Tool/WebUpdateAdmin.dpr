program WebUpdateAdmin;

uses
  Forms,
  WebUpdate.Classes.WebUpdate in '..\Common\WebUpdate.Classes.WebUpdate.pas',
  WebUpdate.GUI.About in 'WebUpdate.GUI.About.pas' {frmAbout},
  WebUpdate.GUI.Main in 'WebUpdate.GUI.Main.pas' {frmMain},
  WebUpdate.GUI.Options in 'WebUpdate.GUI.Options.pas' {frmOptions},
  WebUpdate.JSON.Channel in '..\Common\WebUpdate.JSON.Channel.pas',
  WebUpdate.JSON.Channels in '..\Common\WebUpdate.JSON.Channels.pas',
  WebUpdate.JSON.Preferences in 'WebUpdate.JSON.Preferences.pas',
  WebUpdate.JSON.Project in '..\Common\WebUpdate.JSON.Project.pas',
  WebUpdate.JSON.Serializer in '..\Common\WebUpdate.JSON.Serializer.pas',
  WebUpdate.Tools in '..\Common\WebUpdate.Tools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

