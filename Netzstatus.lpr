program Netzstatus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, SysUtils, BaseUnix, u_mainwindow, u_netzwerkinfo, u_hostwindow,
  u_objektsperre, u_pause;

{$R *.res}

var
  netzinfosnap: TNetzInfoSnap;
  i: Integer;

begin

  if (ParamCount > 0) then
  begin

      try 
        if ParamStr(1) = '--print' then
        begin
          netzinfosnap := TNetzInfoSnap.create();
          netzinfosnap.refresh;
          netzinfosnap.Benutzen;

          netzinfosnap.printItemHeadline;
          for i := Low(netzinfosnap.items) to High(netzinfosnap.items) do
          begin
            netzinfosnap.printItem(netzinfosnap.items[i]);
          end;

          netzinfosnap.Freigeben;

          Application.Terminate;
          fpExit(0);

        end;

      except
      end;




       //writeln('child is running...');
       try
       netzinfosnap := TNetzInfoSnap.create();
       netzinfosnap.refresh;
       netzinfosnap.ForkChild(StrToInt(ParamStr(1)),StrToInt(ParamStr(2)));
       except
         writeln('child exception: refreshing');
       end;
       //writeln('child end-of-proc.');

  end else begin



  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(THauptform, Hauptform);
  Application.CreateForm(TIPtoName, IPtoName);
//Application.CreateForm(TForm1, Form1);
  Application.Run;

  end;
end.

