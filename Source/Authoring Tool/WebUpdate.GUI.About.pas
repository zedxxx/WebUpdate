unit WebUpdate.GUI.About;

interface

uses
  Windows,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  Graphics;

type
  TfrmAbout = class(TForm)
    ImageHeader: TImage;
    LabelAnd: TLabel;
    LabelComma1: TLabel;
    LabelComma2: TLabel;
    LabelCopyright: TLabel;
    LabelDualLicenses: TLabel;
    LabelDWS: TLabel;
    LabelIndy: TLabel;
    LabelJEDI: TLabel;
    LabelSubTitle: TLabel;
    LabelTitle: TLabel;
    LabelVirtualTreeview: TLabel;
    MemoLGPL: TMemo;
    MemoMIT: TMemo;
    PanelHeader: TPanel;
    RadioButtonLicenseLGPL: TRadioButton;
    RadioButtonLicenseMIT: TRadioButton;
    procedure LabelDWSClick(Sender: TObject);
    procedure LabelIndyClick(Sender: TObject);
    procedure LabelJEDIClick(Sender: TObject);
    procedure LabelVirtualTreeviewClick(Sender: TObject);
    procedure RadioButtonLicenseLGPLClick(Sender: TObject);
    procedure RadioButtonLicenseMITClick(Sender: TObject);
  end;

implementation

{$R *.dfm}

uses
  ShellApi;

procedure OpenLink(const URL: string);
begin
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWDEFAULT)
end;

procedure TfrmAbout.LabelDWSClick(Sender: TObject);
begin
  OpenLink('http://www.delphitools.info/dwscript/');
end;

procedure TfrmAbout.LabelIndyClick(Sender: TObject);
begin
  OpenLink('http://www.indyproject.org/');
end;

procedure TfrmAbout.LabelJEDIClick(Sender: TObject);
begin
  OpenLink('http://www.delphi-jedi.org/');
end;

procedure TfrmAbout.LabelVirtualTreeviewClick(Sender: TObject);
begin
  OpenLink('http://www.jam-software.com/virtual-treeview/');
end;

procedure TfrmAbout.RadioButtonLicenseLGPLClick(Sender: TObject);
begin
  MemoLGPL.BringToFront;
end;

procedure TfrmAbout.RadioButtonLicenseMITClick(Sender: TObject);
begin
  MemoMIT.BringToFront;
end;

end.
