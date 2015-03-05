unit WebUpdate.Admin.Actions;

interface

uses
  Windows,
  SysUtils,
  WebUpdate.JSON.Channel,
  WebUpdate.JSON.Channels,
  WebUpdate.JSON.Project,
  WebUpdate.JSON.Serializer,
  WebUpdate.Tools;

//type
  //TOnLogEvent = procedure()

procedure UploadSnapshot(AProject: TWebUpdateProject);
procedure CopySnapshot(AProject: TWebUpdateProject);
procedure TakeSnapshot(AProject: TWebUpdateProject);

implementation

procedure UploadSnapshot(AProject: TWebUpdateProject);
begin
//
end;

procedure CopySnapshot(AProject: TWebUpdateProject);
var
  I: Integer;
  VPath: string;
  VChannelName: string;
  VChannelSetup: TWebUpdateChannelSetup;
  VFileName: string;
  VFileItem: TWebUpdateFileItem;
  VRealFileName, VChannelFileName, VDestFileName: TFileName;
begin
  VPath := IncludeTrailingPathDelimiter(AProject.Copy.Path);
  if IsRelativePath(VPath) then
    VPath := AProject.BasePath + VPath;

  VChannelName := AProject.ChannelName;
  VChannelFileName := AProject.ChannelsPath + VChannelName + '.json';

  VChannelSetup := TWebUpdateChannelSetup.Create;
  try
    VChannelSetup.LoadFromFile(VChannelFileName);

    for I := 0 to VChannelSetup.Items.Count - 1 do begin
      VFileItem := TWebUpdateFileItem(VChannelSetup.Items[I]);

      VFileName := VFileItem.FileName;
      VRealFileName := AProject.BasePath + WebToLocalFileName(VFileName);

      VDestFileName := ExpandFileName(VPath + VChannelName + '\' + VFileName);
      if VFileItem.Action = iaDelete then begin
        if FileExists(VDestFileName) then begin
          DeleteFile(PChar(VDestFileName));
        end;
        Continue;
      end;

      if not ForceDirectories(ExtractFileDir(VDestFileName)) then begin
        RaiseLastOSError;
      end;

      WriteLn('Copying file ', VFileName, '...');
      CopyFile(VRealFileName, VDestFileName);

      // set file date/time according to the JSON file
      FileSetDate(VDestFileName, DateTimeToFileDate(VFileItem.Modified));
    end;

    // copy channel setup
    WriteLn('Copying channel setup...');
    VDestFileName := ExpandFileName(VPath + VChannelName + '.json');
    ForceDirectories(ExtractFileDir(VDestFileName));

    CopyFile(VChannelFileName, VDestFileName);

    // set file date/time according to the JSON file
    FileSetDate(VDestFileName, DateTimeToFileDate(VChannelSetup.Modified));
  finally
    VChannelSetup.Free;
  end;

  // copy channel file
  WriteLn('Copying channels list...');
  VDestFileName := ExpandFileName(VPath + ExtractFileName(AProject.ChannelsFilename));

  CopyFile(AProject.FullChannelsFilename, VDestFileName);
end;

procedure TakeSnapshot(AProject: TWebUpdateProject);
var
  I: Integer;
  Fad: TWin32FileAttributeData;
  LastModified: TDateTime;
  FileName: TFileName;
  VItemFileName: TFileName;
  Channels: TWebUpdateChannels;
  ChannelItem: TWebUpdateChannelItem;
  ChannelSetup: TWebUpdateChannelSetup;
  Item: TWebUpdateFileItem;
begin
  // update status
  WriteLn('Taking snapshot...');

  Channels := TWebUpdateChannels.Create;
  try
    // load
    Channels.LoadFromFile(AProject.FullChannelsFilename);
    ChannelItem := Channels.GetItemForChannel(AProject.ChannelName);

    // create selected channels
    ChannelSetup := TWebUpdateChannelSetup.Create;
    try
      // get filename for currently selected channel
      FileName := AProject.ChannelsPath + AProject.ChannelName + '.json';

      ChannelSetup.LoadFromFile(FileName);

      // store current channel name
      ChannelSetup.AppName := AProject.ApplicationName;
      ChannelSetup.ChannelName := AProject.ChannelName;
      LastModified := 0;
      for I := Pred(ChannelSetup.Items.Count) downto 0 do begin
        Item := TWebUpdateFileItem(ChannelSetup.Items[I]);

        VItemFileName := Item.FileName;

        if not FileExists(VItemFileName) then begin
          LastModified := Now;
          ChannelSetup.Items.Delete(I);
          Continue;
        end;

        // get file attribute
        if not GetFileAttributesEx(PChar(VItemFileName), GetFileExInfoStandard, @Fad) then
          RaiseLastOSError;

        // create (& update) file item
        Item.Modified := FileTimeToDateTime(Fad.ftLastWriteTime);
        Item.FileSize := Fad.nFileSizeLow;

        if AProject.UseMD5 then begin
          Item.MD5Hash := MD5(VItemFileName);
        end else begin
          Item.MD5Hash := '';
        end;

        if Item.Modified > LastModified then begin
          LastModified := Item.Modified;
        end;
      end;

      ChannelSetup.Modified := LastModified;
      ChannelItem.Modified := LastModified;

      // save channel setup
      ChannelSetup.SaveToFile(FileName);
    finally
      ChannelSetup.Free;
    end;

    // save channels to file
    Channels.SaveToFile(AProject.FullChannelsFilename);
  finally
    Channels.Free;
  end;
end;

end.
