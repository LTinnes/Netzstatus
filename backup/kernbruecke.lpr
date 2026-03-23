program kernbruecke;

uses Classes, SysUtils, u_uebersetzung;

var
   links: TUebersetzungLinks;
   rechts: TUebersetzungRechts;
   i: integer;
begin
   try
   links := TUebersetzungLinks.create();
   writeln(links.ausgabe());
   rechts := TUebersetzungRechts.create(links.ausgabe);
   for i := 0 to rechts.count-1 do
     begin
        writeln('');
        writeln('### rechts Eintrag Nr.'+IntToStr(i)+' ###');
        writeln(rechts.items[i].cmdline);
        writeln(rechts.items[i].pid);
        writeln(rechts.items[i].protokoll);
        writeln(rechts.items[i].quellip);
        writeln(rechts.items[i].quellport);
        writeln(rechts.items[i].zielip);
        writeln(rechts.items[i].zielport);
        writeln(rechts.items[i].status);
        writeln('');
        writeln('### links Eintrag Nr.'+IntToStr(i)+' ###');
        writeln(links.snap.items[i].cmdline);
        writeln(links.snap.items[i].pid);
        writeln(links.snap.items[i].protokoll);
        writeln(links.snap.items[i].quellip);
        writeln(links.snap.items[i].quellport);
        writeln(links.snap.items[i].zielip);
        writeln(links.snap.items[i].zielport);
        writeln(links.snap.items[i].status);
     end;

   rechts.Free;
   links.Free;
   except
   end;
end.

