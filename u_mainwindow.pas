unit u_mainwindow;

{$mode objfpc}{$H+}
// todo:
// Bugfix - Child Termination bei zweitem durchlauf / Client Freeze

interface

uses
  Classes, SysUtils, Forms, Controls, Process, Graphics, Dialogs, ComCtrls, Menus,
  ExtCtrls, StdCtrls, cthreads, BaseUnix, Unix, u_netzwerkinfo, u_hostwindow, u_pause;

type

  {TUpdateThread - Information Gathering Thread }

  TUpdateThread = class(TThread)
    protected
      procedure Execute;override;
    private
      //timetosleep: integer;


    public
      snapsection: TRTLCriticalSection;
      netzinfo: TNetzInfoSnap;
      //procedure setSleepTime(time: integer);
      procedure getSnap(var netzinfosnap:TNetzInfoSnap);
      constructor Create(CreateSuspended:boolean);
    end;

  { THauptform }

  THauptform = class(TForm)
    BTN_ReloadBlock: TButton;
    BTN_SaveBlock: TButton;
    BTN_pausebeenden: TButton;
    BTN_Anwenden: TButton;
    ED_WAITINTERVAL: TEdit;
    ED_MAXITERATION: TEdit;
    GroupBox1: TGroupBox;
    IconImgList: TImageList;
    Kontext: TPopupMenu;
    IPMemo: TMemo;
    AboutLabel: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    UpdateData: TTimer;
    VerlaufMemo: TMemo;
    MI_ProzessAbschalten: TMenuItem;
    MI_ZielUntersuchen: TMenuItem;
    PageControler: TPageControl;
    ConnectionTab: TTabSheet;
    BlockiertTab: TTabSheet;
    EinstellungenTab: TTabSheet;
    StatusBar: TStatusBar;
    TabSheet1: TTabSheet;
    Uebersicht: TListView;
    procedure BTN_AnwendenClick(Sender: TObject);
    procedure BTN_pausebeendenClick(Sender: TObject);
    procedure BTN_ReloadBlockClick(Sender: TObject);
    procedure BTN_SaveBlockClick(Sender: TObject);
    procedure ED_MAXITERATIONChange(Sender: TObject);
    procedure ED_WAITINTERVALChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MI_ProzessAbschaltenClick(Sender: TObject);
    procedure MI_ZielUntersuchenClick(Sender: TObject);
    procedure UpdateDataTimer(Sender: TObject);
  private
    pause:          TPause;
    updatethread:   TUpdateThread;
    statussection:  TRTLCriticalSection;
    refreshsection: TRTLCriticalSection;
    logsection:     TRTLCriticalSection;
    maxiteration:   Integer;
    waitintervall:  Integer;
    procedure AddToUebersicht(pid:string;cmdline:string;protok:string;status:string;zielip:string;zielport:string;quellip:string;quellport:string);
    procedure LoadDeniedHosts();
    procedure WriteDeniedHosts();
    procedure killpid(spid_tokill:string);
    procedure UpdateStatus(status:string);

  public
    iptonamewnd: TIPtoName;
    procedure RefreshUebersicht();
    procedure blockhosts();
    procedure Log(txtln:string);
  end;

var
  Hauptform: THauptform;

implementation

{$R *.lfm}

{ THauptform }

procedure TUpdateThread.getSnap(var netzinfosnap:TNetzInfoSnap);
begin
    EnterCriticalSection(self.snapsection);
    netzinfosnap := self.netzinfo;
    LeaveCriticalSection(self.snapsection);
end;

procedure TUpdateThread.Execute();
begin
  Hauptform.Log('UpdateThread.Execute(): Aufruf');
  EnterCriticalSection(self.snapsection);
  netzinfo := TNetzInfoSnap.create();
  LeaveCriticalSection(self.snapsection);

  EnterCriticalSection(self.snapsection);
  Hauptform.Log('NetzInfo ForkRun: Lade Daten von Kernel');
  netzinfo.ForkRun;
  //writeln('ForkRun Proc Ret');
  LeaveCriticalSection(self.snapsection);
  //writeln('ForkRun Critical Section Leave');
end;

{procedure TUpdateThread.setSleepTime(time: integer);
begin
  timetosleep := time;
end;}

constructor TUpdateThread.Create(CreateSuspended:boolean);
begin
  //timetosleep := 5000;
  self.netzinfo := nil;
  InitCriticalSection(self.snapsection);

  inherited Create(CreateSuspended);
end;

procedure THauptform.AddToUebersicht(pid:string;cmdline:string;protok:string;status:string;zielip:string;zielport:string;quellip:string;quellport:string);
var
  new_item: TListItem;
begin
  EnterCriticalSection(self.refreshsection);
  new_item := Uebersicht.Items.Add;
  new_item.Caption:=pid;
  new_item.SubItems.Add(cmdline);
  new_item.SubItems.Add(protok);
  new_item.SubItems.Add(status);
  new_item.SubItems.Add(zielip);
  new_item.SubItems.Add(zielport);
  new_item.SubItems.Add(quellip);
  new_item.SubItems.Add(quellport);
  LeaveCriticalSection(self.refreshsection);
end;


procedure THauptform.Log(txtln:string);
begin
   EnterCriticalSection(self.logsection);
   Hauptform.VerlaufMemo.Lines.Add(txtln);
   LeaveCriticalSection(self.logsection);
end;

procedure THauptform.RefreshUebersicht();
var
  i: integer;
  netzinfosnap: TNetzInfoSnap;
begin
  try
    Log('Aktualisieren ...');
    EnterCriticalSection(self.refreshsection);
    Uebersicht.Clear;
    LeaveCriticalSection(self.refreshsection);
    updatethread.getSnap(netzinfosnap);
    EnterCriticalSection(updatethread.snapsection);
    netzinfosnap.Benutzen;
    if netzinfosnap <> nil then
    begin
      for i := Low(netzinfosnap.items) to high(netzinfosnap.items) do
        begin
          AddToUebersicht( netzinfosnap.items[i].pid,
                           netzinfosnap.items[i].cmdline,
                           netzinfosnap.items[i].protokoll,
                           netzinfosnap.items[i].status,
                           netzinfosnap.items[i].zielip,
                           netzinfosnap.items[i].zielport,
                           netzinfosnap.items[i].quellip,
                           netzinfosnap.items[i].quellport);
        end;
    end;
    netzinfosnap.Freigeben;
    LeaveCriticalSection(updatethread.snapsection);
    Log('Aktualisiert.');
  except
     Log('RefreshUebersicht(): exception');
  end;
end;

procedure THauptform.FormCreate(Sender: TObject);
begin
   InitCriticalSection(self.statussection);
   InitCriticalSection(self.refreshsection);
   InitCriticalSection(self.logsection);
   self.UpdateData.Interval:=5000;
   self.VerlaufMemo.Clear;
   updatethread := TUpdateThread.create(true);
   iptonamewnd := TIPtoName.Create(self);
   self.maxiteration:=30;
   self.waitintervall:=5000;
   self.pause := TPause.create(30);
end;

//Schließen im Debugger funktioniert leider nicht aktuell
procedure THauptform.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  try
    self.UpdateData.Enabled:=false;
    self.UpdateData.Free;
    updatethread.Terminate;
    updatethread.Free;
    iptonamewnd.Destroy;
    iptonamewnd.Free;
  except
    // ...
    // Wird von dem unterliegenden System entfernt
  end;
end;

procedure THauptform.BTN_ReloadBlockClick(Sender: TObject);
begin
  LoadDeniedHosts();
end;

procedure THauptform.BTN_pausebeendenClick(Sender: TObject);
begin
  self.pause.reset;
end;

procedure THauptform.BTN_AnwendenClick(Sender: TObject);
var
  error:boolean;
begin
     error := false;
     try
        self.maxiteration := StrToInt(self.ED_MAXITERATION.Text);
     except
        error := true;
        Log('Maximale Durchläufe bis Pause konnte nicht geändert werden.');
     end;

     try
        self.waitintervall := StrToInt(self.ED_WAITINTERVAL.Text);
        self.UpdateData.Interval:=self.waitintervall;
     except
        error := true;
        Log('Warteintervall bis zum Nächsten Durchlauf konnte nicht geändert werden.');
     end;

     if error = false then
     begin
        Log('Einstellungen wurden übernommen.');
        BTN_Anwenden.Enabled:=false;
     end;

end;

procedure THauptform.BTN_SaveBlockClick(Sender: TObject);
begin
  WriteDeniedHosts();
end;

procedure THauptform.ED_MAXITERATIONChange(Sender: TObject);
begin
     BTN_Anwenden.Enabled:=true;
end;

procedure THauptform.ED_WAITINTERVALChange(Sender: TObject);
begin
     BTN_Anwenden.Enabled:=true;
end;

procedure THauptform.FormShow(Sender: TObject);
begin
   updatethread.Start;

   if fpgetuid() <> 0 then
   begin
     ShowMessage('Achtung: Netzstatus wird nicht priviligiert ausgeführt.');
   end;

   IPMemo.Clear;
   LoadDeniedHosts();
end;

procedure THauptform.MI_ProzessAbschaltenClick(Sender: TObject);
var
  i: integer;
  pid_tokill_tempora: string;
begin
  try
   EnterCriticalSection(self.refreshsection);
   for i := 0 to Uebersicht.Items.Count do
     begin
       if Uebersicht.Items[i].Focused then
       begin
            pid_tokill_tempora := Uebersicht.Items[i].Caption;
            killpid(pid_tokill_tempora);
            break;
       end;
     end;
   LeaveCriticalSection(self.refreshsection);
   except
      ShowMessage('Error: Bitte nochmal versuchen.');
   end;

end;

procedure THauptform.MI_ZielUntersuchenClick(Sender: TObject);
var
  ip_der_blockade: string;
  i: integer;
begin
  try
     if iptonamewnd.blockal=true then
     begin
          ShowMessage('Bitte nochmal versuchen.'+#10#13
                      +'Fehler: Fenster blockiert.' );
          exit; // nicht synchronisiert
     end;
  except
     exit;
  end;

  try
     EnterCriticalSection(self.refreshsection);
     for i := 0 to Uebersicht.Items.Count do
     begin
       if Uebersicht.Items[i].Selected then
       begin
         ip_der_blockade := Uebersicht.Items[i].SubItems[3];
         break;
       end;
     end;
     LeaveCriticalSection(self.refreshsection);
  except
     try
     ShowMessage('Bitte nochmal versuchen.'+#13#10
                 +'Fehler: Markiertes Element nicht gefunden.');
     exit;
     except
     exit;
     end;
     exit;
  end;
  iptonamewnd.execforip(ip_der_blockade);
  iptonamewnd.ShowModal;
end;

procedure THauptform.UpdateStatus(status:string);
begin
  EnterCriticalSection(statussection);
  Hauptform.StatusBar.SimpleText:=status;
  Hauptform.StatusBar.Update;
  LeaveCriticalSection(statussection);
end;

procedure THauptform.UpdateDataTimer(Sender: TObject);
begin

   if pause.pause() = false then
   begin
     pause.Inc;
     pause.update(self.maxiteration);

     Hauptform.UpdateStatus('Daten werden eingefügt...');
     Hauptform.RefreshUebersicht();

     //Callback: blockieren von hosts
     Hauptform.blockhosts();
     Hauptform.BTN_pausebeenden.Enabled:=false;
     Hauptform.UpdateStatus('Aktualisiert um '+FormatDateTime('dd.mm.yyyy hh:nn:ss',now));

     updatethread.Terminate;
     updatethread.Free;
     updatethread := TUpdateThread.create(true);
     updatethread.Start;


   end else
   begin

     Hauptform.UpdateStatus('Pause: Es wird nicht aktualisiert. Pause seit; '+FormatDateTime('dd.mm.yyyy hh:nn:ss',now));
     Hauptform.BTN_pausebeenden.Enabled:=true;
   end;
end;


procedure THauptform.LoadDeniedHosts();
var
  DeniedHostsFileContent: TStringList;
  i:integer;
begin
  DeniedHostsFileContent := TStringList.Create;
  try
     DeniedHostsFileContent.LoadFromFile('/etc/hosts.deny');
  except
     ShowMessage('Kein Zugriff auf /etc/hosts.deny');
  end;
  IPMemo.Clear;

  for i := 0 to DeniedHostsFileContent.Count-1 do
  begin
       IPMemo.Lines.Add(DeniedHostsFileContent.Strings[i]);
  end;

  DeniedHostsFileContent.Free;
end;

procedure THauptform.WriteDeniedHosts();
var
  DeniedHostsFileContent: TStringList;
  i:integer;
begin
  DeniedHostsFileContent := TStringList.Create;

  for i := 0 to IPMemo.Lines.Count -1 do
  begin
       DeniedHostsFileContent.Add(IPMemo.Lines.ValueFromIndex[i]);
  end;

  try
     DeniedHostsFileContent.SaveToFile('/etc/hosts.deny');
  except
     ShowMessage('Kein Zugriff auf /etc/hosts.deny');
  end;

  DeniedHostsFileContent.Free;
end;

procedure THauptform.killpid(spid_tokill:string);
var
  cmd:string;
begin
   cmd := 'xfce4-terminal -x kill -s SIGKILL '+ spid_tokill;
   ShowMessage(cmd);
   fpSystem(cmd);
end;

procedure THauptform.blockhosts();
var
  j: integer;
begin
  try
  if Hauptform.iptonamewnd.blockal and not Hauptform.iptonamewnd.Visible then
  begin
    Hauptform.iptonamewnd.blockal:=false;
    for j := 0 to iptonamewnd.lookup.names.Count -1 do
    begin
       IPMemo.Lines.Add(iptonamewnd.lookup.names.Strings[j]);
    end;
    Hauptform.WriteDeniedHosts();
  end;

  except
     Log('blockhosts laden exception.');
  end;
end;

end.

