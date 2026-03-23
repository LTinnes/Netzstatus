unit u_nslookup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, StrUtils, Dialogs;

type Tnslookup = class
  public
    names: TStringList;
    constructor create();
    destructor release();
    procedure execute(ip:string);

end;

implementation

constructor Tnslookup.create();
begin
  names := TStringList.Create;
end;

destructor Tnslookup.release();
begin
  names.Free;
end;

procedure Tnslookup.execute(ip: string);
var
  i,j: integer;
  output: string;
  Strings: TStringList;
  Lines: TStringList;
  StrLength: integer;
  TemporalStr: string;
begin
  Strings := TStringList.create();
  if RunCommand('/usr/bin/nslookup '+ip, output ) then
  begin
     //names.Add(output);
     Assert(Assigned(Strings)) ;
     Strings.Clear;
     Strings.StrictDelimiter := true;
     Strings.Delimiter := #10;
     Strings.DelimitedText := output;
     for i := 0 to Strings.Count -1 do
     begin
       //ShowMessage(Strings[i]);
       if trim(Strings[i]) = '' then
       begin
          break;
       end;
       Lines := TStringList.Create;
       Assert(Assigned(Strings));
       Lines.Clear;
       Lines.StrictDelimiter := true;
       Lines.Delimiter := '=';
       Lines.DelimitedText:=Strings[i];
       for j := 0 to Lines.Count - 1 do
       begin
         if (j mod 2) <> 0 then
         begin
            //ShowMessage(Lines.Strings[j]);
            StrLength := Length(Lines.Strings[j]);
            if Lines.Strings[j][StrLength] = '.' then
            begin
               TemporalStr := Lines.Strings[j];
               delete(TemporalStr,StrLength,1);
               Lines.Strings[j] := trim(TemporalStr);
            end;
            names.Add(Lines.Strings[j]);
         end;
       end;
       Lines.Free;
     end;
     Strings.Free;
  end;
end;

end.

