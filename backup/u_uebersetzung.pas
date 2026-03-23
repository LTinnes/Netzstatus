unit u_uebersetzung;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_mjson, u_netzwerkinfo, u_hexstring;

type TUebersetzungLinks = class
     private
       gen: TMJSON_GEN;
       procedure kodieren();
     public
       snap: TNetzInfoSnap;
       constructor create();
       destructor free();
       function ausgabe():string;
end;

type TUebersetzungRechts = class
     private
      parse: TMJSON_PARSE;
      itemparse: TMJSON_PARSE;
      procedure dekodieren();
     public
      valid: boolean;
      count: integer;
      items: array of TNetzInfoItem;
      constructor create(eingabe: string);
end;

implementation

constructor TUebersetzungRechts.create(eingabe: string);
begin
   SetLength(items,0);
   parse := TMJSON_PARSE.create(eingabe);
   count := 0;
   dekodieren();
end;

procedure TUebersetzungRechts.dekodieren();
var
  i: integer;
begin
   valid := true;
   if not parse.isValid() then
   begin
     valid := false;
   end;

   writeln('parse.getValueFromName[0]: '+parse.getValueFromName('0'));

   for i := 1 to StrToInt(parse.getValueFromName('0')) do
   begin
        itemparse := TMJSON_PARSE.create(HexToString(parse.getValueFromName(IntToStr(i))));
        writeln('aktuelles Element ('+IntToStr(i)+') kodiert: '+parse.getValueFromName(IntToStr(i)));
        if not itemparse.isValid() then
        begin
          valid := false;
        end;
        SetLength(items,Length(items)+1);
        Inc(count);
        items[HIGH(items)].cmdline:=HexToString(itemparse.getValueFromName('cmdline'));
        items[HIGH(items)].inode:=HexToString(itemparse.getValueFromName('inode'));
        items[HIGH(items)].pid:=HexToString(itemparse.getValueFromName('pid'));
        items[HIGH(items)].protokoll:=HexToString(itemparse.getValueFromName('protokoll'));
        items[HIGH(items)].quellip:=HexToString(itemparse.getValueFromName('quellip'));
        items[HIGH(items)].quellport:=HexToString(itemparse.getValueFromName('quellport'));
        items[HIGH(items)].status:=HexToString(itemparse.getValueFromName('status'));
        items[HIGH(items)].zielip:=HexToString(itemparse.getValueFromName('zielip'));
        items[HIGH(items)].zielport:=HexToString(itemparse.getValueFromName('zielport'));
        itemparse.Free;
   end;
end;

destructor TUebersetzungLinks.free();
begin
   gen.Free;
   snap.Free;
end;

function TUebersetzungLinks.ausgabe():string;
begin
  result := gen.generate();
end;

procedure TUebersetzungLinks.kodieren();
var
  i: integer;
  itemjson: TMJSON_GEN;
begin
   gen.addItem('0',IntToStr(snap.get_count()+1));
   for i := 1 to snap.get_count()+1 do
   begin
     itemjson := TMJSON_GEN.create();
     itemjson.addItem('cmdline',StringToHex(snap.items[i-1].cmdline));
     itemjson.addItem('inode',StringToHex(snap.items[i-1].inode));
     itemjson.addItem('pid',StringToHex(snap.items[i-1].pid));
     itemjson.addItem('protokoll',StringToHex(snap.items[i-1].protokoll));
     itemjson.addItem('quellip',StringToHex(snap.items[i-1].quellip));
     itemjson.addItem('quellport',StringToHex(snap.items[i-1].quellport));
     itemjson.addItem('status',StringToHex(snap.items[i-1].status));
     itemjson.addItem('zielip',StringToHex(snap.items[i-1].zielip));
     itemjson.addItem('zielport',StringToHex(snap.items[i-1].zielport));
     gen.addItem(IntToStr(i),StringToHex(itemjson.generate()));
     itemjson.Free;
   end;
end;

constructor TUebersetzungLinks.create();
begin
     gen := TMJSON_GEN.create();
     snap := TNetzInfoSnap.Create();
     snap.refresh;
     kodieren();
end;



end.

