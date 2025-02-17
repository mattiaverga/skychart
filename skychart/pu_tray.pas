unit pu_tray;

{$mode objfpc}{$H+}

interface

uses
{$ifdef mswindows}
  Windows,
{$endif}
  u_help, u_translation, u_util, u_constant, u_projection, cu_planet,
  cu_database, Inifiles,
  Classes, SysUtils, FileUtil, LazUTF8, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ExtCtrls, StdCtrls, ComCtrls, ColorBox, Spin, dynlibs, Math, LCLProc;

type

  { Tf_tray }

  Tf_tray = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ColorBox1: TColorBox;
    ColorBox2: TColorBox;
    Imagetest: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    PageControl1: TPageControl;
    PopupMenu1: TPopupMenu;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    SpinEdit1: TSpinEdit;
    SysTray: TTrayIcon;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure IconSettingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure UpdateIcon(Sender: TObject);
  private
    { private declarations }
    icontype, icontextsize, iconinfo, iconaction: integer;
    clockposx, clockposy, calposx, calposy: integer;
    iconbg, icontext: TColor;
    bmp: TBitmap;
    language: string;
    WantClose: boolean;
    db: string;
    cdcdb: Tcdcdb;
    lasttxt1,lasttxt2: string;
    procedure TrayMsg(txt1, txt2, hint1: string);
    procedure UpdBmp(txt1, txt2: string; itype, isize: integer; ibg, ifg: TColor;
      ubmp: TBitmap);
    procedure UpdBmpTest(txt1, txt2: string);
    procedure GetAppdir;
    procedure GetLanguage;
    procedure SetLang;
    procedure SaveConfig;
    procedure LoadIcon;
    procedure ConnectDB;
    procedure LoadDeltaT;
    procedure LoadLeapseconds(CanUpdate: boolean=true);
  public
    { public declarations }
    procedure Init;
  end;

var
  f_tray: Tf_tray;

implementation

{$R *.lfm}

uses pu_clock, pu_calendar;

{ Tf_tray }

procedure Tf_tray.SetLang;
begin
  ldeg := #$C2#$B0;
  lmin := '''';
  lsec := '"';
  Caption := rsSkychartIcon;
  TabSheet1.Caption := rsAppearance;
  RadioGroup2.Caption := rsIconSize;
  Label1.Caption := rsBackground;
  Label2.Caption := rsText;
  Label3.Caption := rsTextSize;
  TabSheet2.Caption := rsClock;
  RadioGroup1.Caption := rsIconTime;
  RadioGroup1.Items[0] := rsLegal;
  RadioGroup1.Items[1] := rsUT;
  RadioGroup1.Items[2] := rsMeanLocal;
  RadioGroup1.Items[3] := rsTrueSolar;
  RadioGroup1.Items[4] := rsSideral;
  RadioGroup1.Items[5] := rsNone1;
  Button1.Caption := rsOK;
  Button2.Caption := rsCancel;
  MenuItem1.Caption := rsClock;
  MenuItem2.Caption := rsSkyCharts;
  MenuItem3.Caption := rsSetup;
  MenuItem4.Caption := rsCalendar;
  MenuItem5.Caption := rsClose;
  TabSheet3.Caption := rsAction;
  RadioGroup3.Caption := rsIconClickAct;
  RadioGroup3.Items[0] := rsClock;
  RadioGroup3.Items[1] := rsCalendar;
  RadioGroup3.Items[2] := rsSkyCharts;
  pla[1] := rsMercury;
  pla[2] := rsVenus;
  pla[4] := rsMars;
  pla[5] := rsJupiter;
  pla[6] := rsSaturn;
  pla[7] := rsUranus;
  pla[8] := rsNeptune;
  pla[9] := rsPluto;
  pla[10] := rsSun;
  pla[11] := rsMoon;
  pla[31] := rsSatRing;
  pla[32] := rsEarthShadow;
  u_help.SetLang;
end;

procedure Tf_tray.Init;
var
  inif: TMemIniFile;
  section: string;
begin
{$ifdef mswindows}
  iconaction := 0;
  icontype := 0;
  iconbg := clBtnFace;
  icontext := clBtnText;
  icontextsize := 7;
  iconinfo := 4;
  Radiogroup2.Enabled := False;
{$else}
  iconaction := 0;
  icontype := 1;
  iconbg := clBtnFace;
  icontext := clBtnText;
  icontextsize := 8;
  iconinfo := 4;
{$endif}
  f_clock.cfgsc := Tconf_skychart.Create;
  f_clock.planet := TPlanet.Create(self);
  f_clock.planet.SetDE(slash(appdir) + slash('data') + 'jpleph');
  f_clock.Font.Color := clRed;
  inif := TMeminifile.Create(configfile);
  try
    with inif do
    begin
      section := 'icon';
      iconaction := ReadInteger(section, 'Icon_action', iconaction);
      icontype := ReadInteger(section, 'Icon_type', icontype);
      iconbg := ReadInteger(section, 'Icon_bg', iconbg);
      icontext := ReadInteger(section, 'Icon_text', icontext);
      icontextsize := ReadInteger(section, 'Icon_textsize', icontextsize);
      iconinfo := ReadInteger(section, 'Icon_info', iconinfo);
      clockposx := ReadInteger(section, 'clockposx', -1);
      clockposy := ReadInteger(section, 'clockposy', -1);
      calposx := ReadInteger(section, 'calposx', -1);
      calposy := ReadInteger(section, 'calposy', -1);
      section := 'observatory';
      f_clock.cfgsc.ObsLatitude := ReadFloat(section, 'ObsLatitude', 0);
      f_clock.cfgsc.ObsLongitude := ReadFloat(section, 'ObsLongitude', 0);
      f_clock.cfgsc.ObsAltitude := ReadFloat(section, 'ObsAltitude', 0);
      f_clock.cfgsc.ObsTemperature := ReadFloat(section, 'ObsTemperature', 0);
      f_clock.cfgsc.ObsPressure := ReadFloat(section, 'ObsPressure', 0);
      f_clock.cfgsc.ObsName := Condutf8decode(ReadString(section, 'ObsName', ''));
      f_clock.cfgsc.ObsCountry := ReadString(section, 'ObsCountry', '');
      f_clock.cfgsc.ObsTZ := ReadString(section, 'ObsTZ', 'Etc/GMT');
      f_clock.cfgsc.countrytz := ReadBool(section, 'countrytz', False);
      f_clock.cfgsc.tz.Longitude:=f_clock.cfgsc.ObsLongitude;
      section := 'main';
      f_clock.Font.Color := ReadInteger(section, 'ClockColor', f_clock.Font.Color);
      db := ReadString(section, 'db', slash(privatedir) + StringReplace(
        defaultSqliteDB, '/', PathDelim, [rfReplaceAll]));
    end;
  finally
    inif.Free;
  end;
  Plan404 := nil;
  Plan404lib := LoadLibrary(lib404);
  if Plan404lib <> 0 then
  begin
    Plan404 := TPlan404(GetProcAddress(Plan404lib, 'Plan404'));
  end
  else
    MenuItem4.Enabled := False; // no calendar
  f_clock.cfgsc.tz.LoadZoneTab(ZoneDir + 'zone.tab');
  f_clock.cfgsc.tz.TimeZoneFile :=
    ZoneDir + StringReplace(f_clock.cfgsc.ObsTZ, '/', PathDelim, [rfReplaceAll]);
  f_clock.cfgsc.CalGraphHeight:=200;
  ConnectDB;
  LoadIcon;
  UpdateIcon(nil);
  LoadDeltaT;
  LoadLeapseconds(false);
  Timer1.Enabled := True;
  SysTray.Visible := True;
end;

procedure Tf_tray.SaveConfig;
var
  inif: TMemIniFile;
  section: string;
begin
  inif := TMeminifile.Create(configfile);
  try
    with inif do
    begin
      section := 'icon';
      WriteInteger(section, 'Icon_action', iconaction);
      WriteInteger(section, 'Icon_type', icontype);
      WriteInteger(section, 'Icon_bg', iconbg);
      WriteInteger(section, 'Icon_text', icontext);
      WriteInteger(section, 'Icon_textsize', icontextsize);
      WriteInteger(section, 'Icon_info', iconinfo);
      WriteInteger(section, 'clockposx', clockposx);
      WriteInteger(section, 'clockposy', clockposy);
      WriteInteger(section, 'calposx', calposx);
      WriteInteger(section, 'calposy', calposy);
      section := 'main';
      if f_clock <> nil then
        WriteInteger(section, 'ClockColor', f_clock.Font.Color);
      UpdateFile;
    end;
  finally
    inif.Free;
  end;
end;

procedure Tf_tray.UpdBmp(txt1, txt2: string; itype, isize: integer;
  ibg, ifg: TColor; ubmp: TBitmap);
var
  h, w, p1, p2, p3: integer;
  ts: TTextStyle;
begin
  ubmp.Canvas.Brush.Color := ibg;
  ubmp.Canvas.Brush.Style := bsSolid;
  ubmp.Canvas.Pen.Color := ibg;
  ubmp.Canvas.Pen.Mode := pmCopy;
  ubmp.Canvas.Rectangle(0, 0, ubmp.Width, ubmp.Height);
  ubmp.Canvas.Font.Color := ifg;
  ts.Opaque := False;
  ubmp.Canvas.TextStyle := ts;
  ubmp.Canvas.Brush.Style := bsClear;
  ubmp.Canvas.Pen.Mode := pmCopy;
  ubmp.Canvas.Font.Size := isize;
  h := ubmp.Canvas.TextHeight('0');
  w := ubmp.Canvas.TextWidth('00');
  case itype of
    0:
    begin
      p1 := (ubmp.Height - round(1.7 * h)) div 2;
      p2 := round(0.8 * h) + p1 - 1;
      p3 := (ubmp.Width - w) div 2;
      ubmp.Canvas.TextOut(p3, p1, txt1);
      ubmp.Canvas.TextOut(p3, p2, txt2);
    end;
    1:
    begin
      p1 := (ubmp.Height - round(1.7 * h)) div 2;
      p2 := round(0.8 * h) + p1;
      p3 := (ubmp.Width - w) div 2;
      ubmp.Canvas.TextOut(p3, p1, txt1);
      ubmp.Canvas.TextOut(p3, p2, txt2);
    end;
    2:
    begin
      p1 := (ubmp.Height - h) div 2;
      p3 := (ubmp.Width - round(2.5 * w)) div 2;
      ubmp.Canvas.TextOut(p3, p1, txt1 + ':' + txt2);
    end;
    3:
    begin
      p1 := (ubmp.Height - h) div 2;
      p3 := (ubmp.Width - round(2.5 * w)) div 2;
      ubmp.Canvas.TextOut(p3, p1, txt1 + ':' + txt2);
    end;
    4:
    begin
      p1 := (ubmp.Height - h) div 2;
      p3 := (ubmp.Width - round(2.5 * w)) div 2;
      ubmp.Canvas.TextOut(p3, p1, txt1 + ':' + txt2);
    end;

  end;
end;

procedure Tf_tray.UpdBmpTest(txt1, txt2: string);
begin
  case RadioGroup2.ItemIndex of
    0:
    begin
      imagetest.Width := 16;
      Imagetest.Height := 16;
    end;
    1:
    begin
      imagetest.Width := 22;
      Imagetest.Height := 22;
    end;
    2:
    begin
      imagetest.Width := 32;
      Imagetest.Height := 32;
    end;
    3:
    begin
      imagetest.Width := 64;
      Imagetest.Height := 32;
    end;
    4:
    begin
      imagetest.Width := 48;
      Imagetest.Height := 48;
    end;
  end;
  imagetest.Picture.Bitmap.Width := imagetest.Width;
  Imagetest.Picture.Bitmap.Height := Imagetest.Height;
  UpdBmp(txt1, txt2, RadioGroup2.ItemIndex, SpinEdit1.Value, ColorBox1.Selected,
    ColorBox2.Selected, Imagetest.Picture.Bitmap);
end;

procedure Tf_tray.TrayMsg(txt1, txt2, hint1: string);
begin
  if iconinfo <> 5 then
  begin
    if (txt1<>lasttxt1)or(txt2<>lasttxt2) then begin
      SysTray.Hide;
      LoadIcon;
      UpdBmp(txt1, txt2, icontype, icontextsize, iconbg, icontext, bmp);
      SysTray.Icon.Canvas.Draw(0,0,bmp);
      SysTray.Show;
      systray.InternalUpdate;
      lasttxt1:=txt1;
      lasttxt2:=txt2;
    end;
  end;
  Systray.Hint := hint1;
end;

procedure Tf_tray.Button1Click(Sender: TObject);
begin
  icontype := RadioGroup2.ItemIndex;
  iconbg := ColorBox1.Selected;
  icontext := ColorBox2.Selected;
  icontextsize := SpinEdit1.Value;
  iconinfo := RadioGroup1.ItemIndex;
  iconaction := RadioGroup3.ItemIndex;
  SaveConfig;
  Hide;
  LoadIcon;
  UpdateIcon(nil);
end;

procedure Tf_tray.Button2Click(Sender: TObject);
begin
  Hide;
end;

procedure Tf_tray.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if not WantClose then
    CloseAction := caHide
  else
    SaveConfig;
end;

procedure Tf_tray.IconSettingChange(Sender: TObject);
begin
  UpdBmpTest('22', '22');
end;

procedure Tf_tray.LoadIcon;
begin
  if iconinfo = 5 then
  begin
    SysTray.Icon.LoadFromLazarusResource('cdcmain');
  end
  else
  begin
    case icontype of
      0: SysTray.Icon.LoadFromLazarusResource('black16x16');
      1: SysTray.Icon.LoadFromLazarusResource('black22x22');
      2: SysTray.Icon.LoadFromLazarusResource('black32x32');
      3: SysTray.Icon.LoadFromLazarusResource('black32x64');
      4: SysTray.Icon.LoadFromLazarusResource('black48x48');
    end;
  end;
  bmp.Width := SysTray.Icon.Width;
  bmp.Height := SysTray.Icon.Height;
  case iconaction of
    0: SysTray.OnClick := @MenuItem1Click;
    1: SysTray.OnClick := @MenuItem4Click;
    2: SysTray.OnClick := @MenuItem2Click;
  end;
end;

procedure Tf_tray.FormCreate(Sender: TObject);
begin
{$ifdef mswindows}
  Application.UpdateFormatSettings := False;
{$endif}
  DefaultFormatSettings.DecimalSeparator := '.';
  DefaultFormatSettings.ThousandSeparator := ',';
  DefaultFormatSettings.DateSeparator := '/';
  DefaultFormatSettings.TimeSeparator := ':';
  WantClose := False;
  bmp := TBitmap.Create;
  SysTray.PopUpMenu := PopupMenu1;
  GetAppDir;
  GetLanguage;
  lang := u_translation.translate(language);
  SetLang;
end;

procedure Tf_tray.FormDestroy(Sender: TObject);
begin
  SysTray.Hide;
  bmp.Free;
end;

procedure Tf_tray.MenuItem1Click(Sender: TObject);
begin
  if f_clock.Visible then
  begin
    clockposx := f_clock.Left;
    clockposy := f_clock.Top;
    f_clock.Hide;
  end
  else
  begin
    UpdateIcon(nil);
    if (clockposx < 0) or (clockposy < 0) then
    begin
      clockposx := SysTray.GetPosition.X + SysTray.Icon.Width;
      clockposy := SysTray.GetPosition.Y;
    end;
    FormPos(f_clock, clockposx, clockposy);
    f_clock.Show;
  end;
end;

procedure Tf_tray.MenuItem2Click(Sender: TObject);
begin
  ExecNoWait(CdC + ' --unique');
end;

procedure Tf_tray.MenuItem3Click(Sender: TObject);
begin
  RadioGroup2.ItemIndex := icontype;
  ColorBox1.Selected := iconbg;
  ColorBox2.Selected := icontext;
  SpinEdit1.Value := icontextsize;
  RadioGroup1.ItemIndex := iconinfo;
  RadioGroup3.ItemIndex := iconaction;
  UpdBmptest('22', '22');
  FormPos(Self, SysTray.GetPosition.X, SysTray.GetPosition.Y);
  Show;
end;

procedure Tf_tray.MenuItem4Click(Sender: TObject);
var
  y, m, d: word;
  u, p, v1, v2, v3: double;
  se, ce: extended;
const
  ratio = 0.99664719;
  H0 = 6378140.0;
begin
  if f_calendar = nil then
  begin
    f_calendar := Tf_calendar.Create(self);
    f_calendar.planet := f_clock.planet;
    f_calendar.planet.SetDE(slash(appdir) + slash('data') + 'jpleph');
    f_calendar.cdb := cdcdb;
    f_calendar.eclipsepath := slash(appdir) + slash('data') + slash('eclipses');
    f_calendar.AzNorth := True;
  end;
  if f_calendar.Visible then
  begin
    calposx := f_calendar.Left;
    calposy := f_calendar.Top;
    f_calendar.Hide;
  end
  else
  begin
    f_calendar.config.Assign(f_clock.cfgsc);
    DecodeDate(Now, y, m, d);
    f_calendar.config.CurYear := y;
    f_calendar.config.CurMonth := m;
    f_calendar.config.CurDay := d;
    f_calendar.config.CurTime := frac(now) * 24;
    f_calendar.config.JDChart := jd(y, m, d, 0);
    f_calendar.config.Force_DT_UT := False;
    f_calendar.config.DT_UT := DTminusUT(y, m, d, f_calendar.config);
    f_calendar.config.CurJDUT := f_calendar.config.JDChart;
    f_calendar.config.CurJDTT := f_calendar.config.JDChart + f_calendar.config.DT_UT / 24;
    f_calendar.config.PlanetParalaxe := True;
    f_calendar.config.ApparentPos := True;
    f_calendar.config.ecl := ecliptic(f_calendar.config.JdChart);
    // nutation constant
    f_calendar.planet.nutation(f_calendar.config.JDChart, f_calendar.config.nutl,
      f_calendar.config.nuto);
    // ecliptic obliquity
    f_calendar.config.ecl := ecliptic(f_calendar.config.JdChart, f_calendar.config.nuto);
    // nutation matrix
    sincos(f_calendar.config.ecl, se, ce);
    f_calendar.config.NutMAT[1, 1] := 1;
    f_calendar.config.NutMAT[1, 2] := -ce * f_calendar.config.nutl;
    f_calendar.config.NutMAT[1, 3] := -se * f_calendar.config.nutl;
    f_calendar.config.NutMAT[2, 1] := ce * f_calendar.config.nutl;
    f_calendar.config.NutMAT[2, 2] := 1;
    f_calendar.config.NutMAT[2, 3] := -f_calendar.config.nuto;
    f_calendar.config.NutMAT[3, 1] := se * f_calendar.config.nutl;
    f_calendar.config.NutMAT[3, 2] := f_calendar.config.nuto;
    f_calendar.config.NutMAT[3, 3] := 1;
    // equation of the equinox
    f_calendar.config.eqeq := f_calendar.config.nutl * cos(f_calendar.config.ecl);
    // Sun geometric longitude eq. of date for aberration
    f_calendar.planet.sunecl(f_calendar.config.CurJDTT, f_calendar.config.sunl,
      f_calendar.config.sunb);
    PrecessionEcl(jd2000, f_calendar.config.CurJDUT, f_calendar.config.sunl,
      f_calendar.config.sunb);
    // aberration and light deflection constant
    f_calendar.planet.aberration(f_calendar.config.CurJDTT, f_calendar.config.abv,
      f_calendar.config.ehn, f_calendar.config.ab1, f_calendar.config.abe,
      f_calendar.config.abp, f_calendar.config.gr2e, f_calendar.config.abm,
      f_calendar.config.asl);
    // Earth barycentric position in parsec for parallax
    f_calendar.planet.Barycenter(f_calendar.config.CurJDTT, v1, v2, v3);
    f_calendar.config.EarthB[1] := -v1 * au2parsec;
    f_calendar.config.EarthB[2] := -v2 * au2parsec;
    f_calendar.config.EarthB[3] := -v3 * au2parsec;
    // observatory
    p := deg2rad * f_calendar.config.ObsLatitude;
    u := arctan(ratio * tan(p));
    f_calendar.config.ObsRoSinPhi := ratio * sin(u) + (f_calendar.config.ObsAltitude / H0) * sin(p);
    f_calendar.config.ObsRoCosPhi := cos(u) + (f_calendar.config.ObsAltitude / H0) * cos(p);
    f_calendar.config.ObsRefractionCor := 1;
    f_calendar.config.EquinoxName := rsDate;
    if (calposx < 0) or (calposy < 0) then
    begin
      calposx := SysTray.GetPosition.X + SysTray.Icon.Width;
      calposy := SysTray.GetPosition.Y;
    end;
    formpos(f_calendar, calposx, calposy);
    f_calendar.Show;
    f_calendar.bringtofront;
  end;
end;

procedure Tf_tray.MenuItem5Click(Sender: TObject);
begin
  WantClose := True;
  Close;
end;

procedure Tf_tray.UpdateIcon(Sender: TObject);
var
  buf1, buf2: string;
begin
  if not f_clock.Timer1.Enabled then
    f_clock.UpdateClock;
  case iconinfo of
    0:
    begin
      buf1 := f_clock.clock1.Caption;
      buf2 := f_clock.label1.Caption;
    end;
    1:
    begin
      buf1 := f_clock.clock2.Caption;
      buf2 := f_clock.label2.Caption;
    end;
    2:
    begin
      buf1 := f_clock.clock3.Caption;
      buf2 := f_clock.label3.Caption;
    end;
    3:
    begin
      buf1 := f_clock.clock4.Caption;
      buf2 := f_clock.label4.Caption;
    end;
    4:
    begin
      buf1 := f_clock.clock5.Caption;
      buf2 := f_clock.label5.Caption;
    end;
    5:
    begin
      buf1 := f_clock.clock5.Caption;
      buf2 := f_clock.label5.Caption;
    end;
    else
    begin
      buf1 := '';
      buf2 := '';
    end;
  end;
  TrayMsg(copy(buf1, 1, 2), copy(buf1, 4, 2), buf2 + blank + buf1);
  if (f_clock <> nil) and f_clock.Visible then
  begin
    clockposx := f_clock.Left;
    clockposy := f_clock.Top;
  end;
  if (f_calendar <> nil) and f_calendar.Visible then
  begin
    calposx := f_calendar.Left;
    calposy := f_calendar.Top;
  end;
end;

procedure Tf_tray.GetAppDir;
var
  inif: TMemIniFile;
  buf: string;
  startdir: string;
{$ifdef darwin}
  i: integer;
{$endif}
{$ifdef mswindows}
  PIDL: PItemIDList;
  Folder: array[0..MAX_PATH] of char;
const
  CSIDL_PERSONAL = $0005;   // My Documents
  CSIDL_APPDATA = $001a;   // <user name>\Application Data
  CSIDL_LOCAL_APPDATA = $001c;
  // <user name>\Local Settings\Applicaiton Data (non roaming)
{$endif}
begin
  startdir := ExtractFilePath(ParamStr(0));
{$ifdef darwin}
  appdir := getcurrentdir;
  if not DirectoryExists(slash(appdir) + slash('data') + slash('planet')) then
  begin
    appdir := ExtractFilePath(ParamStr(0));
    i := pos('.app/', appdir);
    if i > 0 then
    begin
      appdir := ExtractFilePath(copy(appdir, 1, i));
    end;
  end;
{$else}
  appdir := getcurrentdir;
{$ifdef trace_debug}
  debugln('appdir=' + appdir);
{$endif}
{$endif}
  privatedir := DefaultPrivateDir;
{$ifdef unix}
  appdir := expandfilename(appdir);
  privatedir := expandfilename(PrivateDir);
  configfile := expandfilename(Defaultconfigfile);
{$endif}
{$ifdef mswindows}
  SHGetSpecialFolderLocation(0, CSIDL_LOCAL_APPDATA, PIDL);
  SHGetPathFromIDList(PIDL, Folder);
  buf := WinCPToUTF8(Folder);
  buf := trim(buf);
  if buf = '' then
  begin  // old windows version
    SHGetSpecialFolderLocation(0, CSIDL_APPDATA, PIDL);
    SHGetPathFromIDList(PIDL, Folder);
    buf := trim(WinCPToUTF8(Folder));
  end;
  privatedir := slash(buf) + privatedir;
  configfile := slash(privatedir) + Defaultconfigfile;
{$endif}

  if fileexists(configfile) then
  begin
    inif := TMeminifile.Create(configfile);
    try
      buf := inif.ReadString('main', 'AppDir', appdir);
      if Directoryexists(buf) then
        appdir := buf;
      privatedir := inif.ReadString('main', 'PrivateDir', privatedir);
    finally
      inif.Free;
    end;
  end;
  Tempdir := slash(privatedir) + DefaultTmpDir;
  SatDir := slash(privatedir) + 'satellites';
  DBDir := slash(privatedir) + 'database';
  if not directoryexists(SatDir) then
    CreateDir(SatDir);
  if not directoryexists(SatDir) then
    forcedirectories(SatDir);
{$ifdef trace_debug}
  debugln('appdir=' + appdir);
{$endif}
  // Be sur the data directory exists
  if (not directoryexists(slash(appdir) + slash('data') + 'constellation')) then
  begin
    // try under the current directory
    buf := GetCurrentDir;
  {$ifdef trace_debug}
    debugln('Try ' + buf);
  {$endif}
    if (directoryexists(slash(buf) + slash('data') + 'constellation')) then
      appdir := buf
    else
    begin
      // try under the program directory
      buf := ExtractFilePath(ParamStr(0));
    {$ifdef trace_debug}
      debugln('Try ' + buf);
    {$endif}
      if (directoryexists(slash(buf) + slash('data') + 'constellation')) then
        appdir := buf
      else
      begin
        // try share directory under current location
        buf := ExpandFileName(slash(GetCurrentDir) + SharedDir);
          {$ifdef trace_debug}
        debugln('Try ' + buf);
          {$endif}
        if (directoryexists(slash(buf) + slash('data') + 'constellation')) then
          appdir := buf
        else
        begin
          // try share directory at the same location as the program
          buf := ExpandFileName(slash(ExtractFilePath(ParamStr(0))) + SharedDir);
            {$ifdef trace_debug}
          debugln('Try ' + buf);
            {$endif}
          if (directoryexists(slash(buf) + slash('data') + 'constellation')) then
            appdir := buf
          else
          begin
            MessageDlg('Could not found the application data directory.' +
              crlf + 'Please edit the file skychart.ini' + crlf
              + 'and indicate at the line Appdir= where you install the data.',
              mtError, [mbAbort], 0);
            Halt;
          end;
        end;
      end;
    end;
  end;
{$ifdef trace_debug}
  debugln('appdir=' + appdir);
  debugln('privatedir=' + privatedir);
{$endif}
{$ifdef mswindows}
  tracefile := slash(privatedir) + 'tray_' + tracefile;
{$endif}
  VarObs := slash(startdir) + DefaultVarObs;
  // varobs normally at same location as skychart
  if not FileExists(VarObs) then
    VarObs := DefaultVarObs; // if not try in $PATH
  CdC := slash(startdir) + DefaultCdC;
  if not FileExists(CdC) then
    CdC := DefaultCdC;
  helpdir := slash(appdir) + slash('doc');
  SampleDir := slash(appdir) + slash('data') + 'sample';
  // Be sure zoneinfo exists in standard location or in skychart directory
  ZoneDir := slash(appdir) + slash('data') + slash('zoneinfo');
{$ifdef trace_debug}
  debugln('ZoneDir=' + ZoneDir);
{$endif}
  buf := slash('') + slash('usr') + slash('share') + slash('zoneinfo');
{$ifdef trace_debug}
  debugln('Try ' + buf);
{$endif}
  if (FileExists(slash(buf) + 'zone.tab')) then
    ZoneDir := slash(buf)
  else
  begin
    buf := slash('') + slash('usr') + slash('lib') + slash('zoneinfo');
  {$ifdef trace_debug}
    debugln('Try ' + buf);
  {$endif}
    if (FileExists(slash(buf) + 'zone.tab')) then
      ZoneDir := slash(buf)
    else
    begin
      if (not FileExists(slash(ZoneDir) + 'zone.tab')) then
      begin
        MessageDlg('zoneinfo directory not found!' + crlf +
          'Please install the tzdata package.' + crlf +
          'If it is not installed at a standard location create a logical link zoneinfo in skychart data directory.',
          mtError, [mbAbort], 0);
        Halt;
      end;
    end;
  end;
{$ifdef trace_debug}
  debugln('ZoneDir=' + ZoneDir);
{$endif}
end;

procedure Tf_tray.GetLanguage;
var
  inif: TMemIniFile;
begin
  language := '';
  if fileexists(configfile) then
  begin
    inif := TMeminifile.Create(configfile);
    try
      language := inif.ReadString('main', 'language', '');
    finally
      inif.Free;
    end;
  end;
end;

procedure Tf_tray.ConnectDB;
begin
  try
    if  not Fileexists(db) then
    begin
      cdcdb := nil;
      exit;
    end;
    cdcdb := Tcdcdb.Create(self);
    if (cdcdb.ConnectDB(db) and cdcdb.CheckDB) then
    begin
         {$ifdef trace_debug}
      WriteTrace('DB connected');
         {$endif}
      cdcdb.OpenAsteroid;
      cdcdb.OpenAsteroidMagnitude;
    end
    else
    begin
      cdcdb.Free;
      cdcdb := nil;
    end;
  except
    cdcdb := nil;
  end;
end;

procedure Tf_tray.LoadDeltaT;
var
  f: textfile;
  i, n: integer;
  fname,dfn,buf: string;
  dat, del, err: single;
begin
  fname:=slash(privatedir)+'deltat.txt';
  if not FileExists(fname) then begin
    // try to copy distribution file
    dfn :=slash(appdir)+ slash('data')+ slash('deltat')+'deltat.txt';
    if FileExists(dfn) then
        CopyFile( dfn , fname);
  end;
  if not FileExists(fname) then
  begin
    numdeltat := 0;
    setlength(deltat, 0, 0);
    exit;
  end;
  Filemode := 0;
  assignfile(f, fname);
  try
    reset(f);
    n := 0;
    // first loop to get the size
    repeat
      readln(f, buf);
      Inc(n);
    until EOF(f);
    setlength(deltat, n, 3);
    // read the file now
    reset(f);
    for i := 0 to n - 1 do
    begin
      readln(f, dat, del, err);
      deltat[i,0]:=dat;
      deltat[i,1]:=del;
      deltat[i,2]:=err;
    end;
    numdeltat:=n;
  finally
    closefile(f);
  end;
end;

procedure Tf_tray.LoadLeapseconds(CanUpdate: boolean=true);
var
  f: textfile;
  i, n: integer;
  fname,dfn,buf: string;
  line: Tstringlist;
  dat, sec: double;
function toJD(ts:double):double;
begin
  result:=2400000.5+15020+(ts/secday);
end;
begin
  numleapseconds := 0;
  leapsecondexpires:=0;
  setlength(leapseconds, 0, 0);
  fname:=slash(privatedir)+'leap-seconds.list';
  if not FileExists(fname) then begin
    // try to copy distribution file
    dfn :=slash(appdir)+ slash('data')+ slash('deltat')+'leap-seconds.list';
    if FileExists(dfn) then
        CopyFile( dfn , fname);
  end;
  if not FileExists(fname) then
  begin
    exit;
  end;
  line:=Tstringlist.Create;
  Filemode := 0;
  assignfile(f, fname);
  try
    reset(f);
    n:=0;
    // first loop to get the size
    repeat
      readln(f, buf);
      Splitrec(buf,tab,line);
      if (line.Count>=2)and(StrToFloatDef(trim(line[0]),-1)>0) then
        Inc(n);
    until EOF(f);
    setlength(leapseconds, n, 2);
    // read the file now
    reset(f);
    i := 0;
    repeat
      readln(f, buf);
      Splitarg(buf,tab,line);
      if line.Count>=2 then begin
        if line[0]='#' then begin
          continue;
        end
        else if line[0]='#@' then begin
          dat:=StrToFloatDef(trim(line[1]),-1);
          if dat>0 then leapsecondexpires:=toJD(dat);
        end
        else begin
          dat:=StrToFloatDef(trim(line[0]),-1);
          sec:=StrToFloatDef(trim(line[1]),-1);
          if (i<n) and (dat>0) and (sec>0) then begin
            leapseconds[i,0]:=toJD(dat);
            leapseconds[i,1]:=sec;
            inc(i);
          end;
        end;
      end;
    until EOF(f);
    closefile(f);
    numleapseconds:=n;
{    if CanUpdate and (leapsecondexpires>0) and ((leapsecondexpires-DateTimetoJD(now))<30) then begin
      // expire in less than one month, refresh now
      if QuickDownload(URL_LEAPSECOND, fname, true) then begin
        LoadLeapseconds(false);
      end
    end;}
  finally
    line.free;
  end;
end;

initialization
  {$I blankicon.lrs}
  {$I cdcmain.lrs}
end.
