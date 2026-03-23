unit u_hostwindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, u_nslookup;

type

  { TIPtoName }

  TIPtoName = class(TForm)
    BTN_BLOCKAL: TButton;
    ED_IP: TEdit;
    LBL_ipaddr: TLabel;
    CB_HOSTS: TListBox;
    procedure BTN_BLOCKALClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private

  public
    blockal: boolean;
    lookup: Tnslookup;
    procedure execforip(in_ip:string);
  end;

var
  IPtoName: TIPtoName;

implementation

{$R *.lfm}

{ TIPtoName }

procedure TIPtoName.execforip(in_ip:string);
var
  i: integer;
begin
  try
    ED_IP.Text:=in_ip;

    lookup.names.Clear;
    lookup.execute(in_ip);
    CB_HOSTS.Clear;
    for i:= 0 to lookup.names.count -1 do
    begin
      CB_HOSTS.AddItem(lookup.names.strings[i],self);
    end;
  except
    ShowMessage('Fehler: Konnte keine Namensauflösung durchführen.');
  end;

end;

procedure TIPtoName.BTN_BLOCKALClick(Sender: TObject);
begin
   blockal := true;
   self.Hide;
end;

procedure TIPtoName.FormCreate(Sender: TObject);
begin
    lookup := Tnslookup.create();
end;

procedure TIPtoName.FormDestroy(Sender: TObject);
begin
    lookup.Free;
end;

end.

