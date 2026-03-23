unit u_MJSON;

{
################################################################################
 Extreme thin
            Minimalistic JavaScript Object Notation implementation
################################################################################
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

type TProtocolItem = record
  name: string;
  value: string;
end;

type TMJSON_PARSE = class
  public
    constructor create(mjson:string);
    function getValueFromName(in_name:string):string;
    function isValid():boolean;
  private
    entrys: array of TProtocolItem;
    valid: boolean;
    function buildProtocollItemfromLine(line:string):TProtocolItem;
    function isValidInformation(mjson:string):boolean;
    function isAttack(line:string):boolean;
end;

type TMJSON_GEN = class
  public
    constructor create();
    function generate():string;
    procedure addItem(in_name:string;in_value:string);
  private
    entrys: array of TProtocolItem;
end;



implementation

constructor TMJSON_GEN.create();
begin
  SetLength(entrys,0);
end;

function TMJSON_GEN.generate():string;
var
  i : integer;
begin
   result := '{';

   for i := Low(entrys) to High(entrys) do
   begin
     result := result + '"' + entrys[i].name + '":"'+ entrys[i].value + '";';
   end;

   result := result + '}';

end;

procedure TMJSON_GEN.addItem(in_name:string;in_value:string);
begin
    if (in_name <> '') and (in_value <> '') and
       (PosEx('"',in_name)=0) and (PosEx('"',in_value)=0) then
    begin
      SetLength(entrys,Length(entrys)+1);
      entrys[High(entrys)].name:=in_name;
      entrys[High(entrys)].value:=in_value;
    end;
end;

function TMJSON_PARSE.buildProtocollItemfromLine(line:string):TProtocolItem;
var
  strarr : TStringArray;
  i,j: integer;
begin

  if PosEx(':',line) = 0 then
  begin
    writeln('error: missing deliminator at line: '+line);
    result.name:='';
    result.value:='';
    exit;
  end;

  writeln('splitting line: '+line);
  strarr := line.Split('"');

  j := 0;

  for i := LOW(strarr) to HIGH(strarr) do
  begin
    if j = 1 then
    begin
      result.name:=strarr[i];
    end;
    if j = 3 then
    begin
      result.value:=strarr[i];
      exit;
    end;
    Inc(j);
  end;

end;

constructor TMJSON_PARSE.create(mjson:string);
var
  this_mjson: string;
  strarr : TStringArray;
  i,pos1,pos2,neue_laenge: integer;
begin
  valid := isValidInformation(mjson);

  if valid then
  begin
      pos1 := PosEx('{' , mjson );
      pos2 := PosEx('}' , mjson );

      neue_laenge :=  pos2 - pos1 - 1;
      this_mjson := Copy(mjson,pos1+1,neue_laenge);

      strarr := this_mjson.Split(';');

      SetLength(entrys,0);

      for i := LOW(strarr) to HIGH(strarr)+1 do
      begin
           SetLength(entrys,Length(entrys)+1);
           //writeln('buildProtocollItemfromLine: '+strarr[i]);
           entrys[High(entrys)] := buildProtocollItemfromline(strarr[i]);
      end;

  end;

end;

function TMJSON_PARSE.getValueFromName(in_name:string):string;
var
  i: integer;
begin
  result := '';
  for i := Low(entrys) to High(entrys) do
  begin
    if entrys[i].name = in_name then
    begin
        result := entrys[i].value;
        exit;
    end;
  end;

end;

function TMJSON_PARSE.isValid():boolean;
begin
    result := valid;
end;

function TMJSON_PARSE.isAttack(line:string):boolean;
var
  i,posi: integer;
  linecopy : string;
begin
  result := false;
  linecopy := line;
  i := 0;
  while PosEx('"',linecopy) <> 0 do
  begin
     Inc(i);
     posi := PosEx('"',linecopy);
     linecopy := copy ( linecopy , posi+1 , Length(linecopy) - posi);
  end;
  if i <> 4 then
  begin
      result := true;
  end;
end;

function TMJSON_PARSE.isValidInformation(mjson:string):boolean;
var
  this_mjson: string;
  strarr : TStringArray;
  i,pos1,pos2,neue_laenge: integer;
begin
  result := true;
  pos1 := PosEx('{' , mjson );
  pos2 := PosEx('}' , mjson );

  if (pos1 = 0) or (pos2 = 0) then
  begin
    result := false;
    exit;
  end;

  neue_laenge :=  pos2 - pos1 - 1;
  this_mjson := Copy(mjson,pos1+1,neue_laenge);

  strarr := this_mjson.Split(';');

  for i := LOW(strarr) to HIGH(strarr)-1 do
  begin
    if isAttack(strarr[i]) then
    begin
      result := false;
      exit;
    end;

    if (buildProtocollItemfromline(strarr[i]).name = '') and
       (buildProtocollItemfromline(strarr[i]).value = '') then
    begin
      result := false;
      exit;
    end;

  end;

end;

end.

