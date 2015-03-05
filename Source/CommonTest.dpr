program CommonTest;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  WebUpdate.JSON.Channel in 'Common\WebUpdate.JSON.Channel.pas',
  WebUpdate.JSON.Channels in 'Common\WebUpdate.JSON.Channels.pas',
  WebUpdate.JSON.Project in 'Common\WebUpdate.JSON.Project.pas',
  WebUpdate.JSON.Serializer in 'Common\WebUpdate.JSON.Serializer.pas',
  WebUpdate.Classes.FileItem in 'Common\WebUpdate.Classes.FileItem.pas',
  WebUpdate.Classes.UpdaterThread in 'Common\WebUpdate.Classes.UpdaterThread.pas',
  WebUpdate.Classes.Updater in 'Common\WebUpdate.Classes.Updater.pas',
  WebUpdate.Classes.WebUpdate in 'Common\WebUpdate.Classes.WebUpdate.pas',
  WebUpdate.Network.DownloaderIndy in 'Common\WebUpdate.Network.DownloaderIndy.pas',
  WebUpdate.Network.Downloader in 'Common\WebUpdate.Network.Downloader.pas',
  WebUpdate.Network.DownloaderFactory in 'Common\WebUpdate.Network.DownloaderFactory.pas',
  WebUpdate.Tools in 'Common\WebUpdate.Tools.pas';

procedure TestChannel(const AFileName: string);
var
  I: Integer;
  VItem: TWebUpdateFileItem;
  VItemTest: TWebUpdateFileItem;
  VChannel: TWebUpdateChannelSetup;
  VChannelTest: TWebUpdateChannelSetup;
  VDate: TDateTime;
begin
  VDate := Now;

  VChannel := TWebUpdateChannelSetup.Create;
  try
    VItem := TWebUpdateFileItem.Create;
    with VItem do begin
      FileName := 'FileNameField_1';
      FileSize := 1024;
      Modified := VDate;
      MD5Hash := 'abdbdbbdbbsb';
      Action := iaAdd;
    end;
    VChannel.Items.Add(VItem);

    VItem := TWebUpdateFileItem.Create;
    with VItem do begin
      FileName := 'c:\Новая папка\Файл с именем на кириллице.ext';
      FileSize := 1024*10;
      Modified := VDate;
      MD5Hash := 'eeeeffffbbdbbsb';
      Action := iaDelete;
    end;
    VChannel.Items.Add(VItem);

    VChannel.Modified := VDate;
    VChannel.AppName := 'CommonTest';
    VChannel.ChannelName := 'TEST';

    VChannel.SaveToFile(AFileName);

    VChannelTest := TWebUpdateChannelSetup.Create;
    try
      VChannelTest.LoadFromFile(AFileName);

      Assert(VChannel.AppName = VChannelTest.AppName);
      Assert(VChannel.ChannelName = VChannelTest.ChannelName);
      //Assert(VChannel.Modified = VChannelTest.Modified);
      Assert(VChannel.Items.Count = VChannelTest.Items.Count);

      for I := 0 to VChannelTest.Items.Count - 1 do begin
        VItem := TWebUpdateFileItem(VChannel.Items[I]);
        VItemTest := TWebUpdateFileItem(VChannelTest.Items[I]);

        Assert(VItem.FileName = VItemTest.FileName);
        Assert(VItem.FileSize = VItemTest.FileSize);
        //Assert(VItem.Modified = VItemTest.Modified);
        Assert(VItem.MD5Hash = VItemTest.MD5Hash);
        Assert(VItem.Action = VItemTest.Action);
      end;
    finally
      FreeAndNil(VChannelTest);
    end;
  finally
    FreeAndNil(VChannel);
  end;
end;

procedure TestProject(const AFileName: string);
var
  VProj: TWebUpdateProject;
begin
  VProj := TWebUpdateProject.Create;
  try
    VProj.SaveToFile(AFileName);

    VProj.LoadFromFile(AFileName);
  finally
    VProj.Free;
  end;
end;

begin
  try
    TestChannel('Channel.json');
    TestProject('Project.json');
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
