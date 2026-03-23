unit u_netzwerkinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, StrUtils, BaseUnix, Unix, Dialogs, u_objektsperre;

type
  TNetzInfoItem = record
      pid:       string;
      cmdline:   string;
      protokoll: string;
      status:    string;
      zielip:    string;
      zielport:  string;
      quellip:   string;
      quellport: string;
      inode:     string;
  end;

type
  TNetzInfoSnap = class(TObjektSperre)
    public
      items:array of TNetzInfoItem;
      constructor create();
      procedure refresh;
      procedure ForkRun();
      procedure ForkChild(cwPipe:cint;crPipe:cint);
      function get_count():integer;
    private
      count: integer;
      s: string;
      error: boolean;
      procedure GenerateItemIPv4(sprotocol:string);
      procedure GenerateItemIPv6(sprotocol:string);
      function Hex2IPv4(shex:string):string;
      function Hex2IPv6(shex:string):string;
      function pidtocmdline(in_spid: string):string;
      function inodetopid(inode: string):string;
      function FpReadT(PipeHandle: THandle; Buffer: Pointer; BufSize: LongInt): LongInt;

  end;


implementation


constructor TNetzInfoSnap.create();
begin
   self.ObjektSperreInit;
   error := false;
end;

function TNetzInfoSnap.pidtocmdline(in_spid: string):string;
var
  sln : string;
  fd: TextFile;
  path: string;
begin
  result := '';
  try
    path := '/proc/'+in_spid+'/cmdline';
    AssignFile(fd,path);
    Reset(fd);
    while not EOF(fd) do
    begin
       readln(fd,sln);
       result := result + sln;
    end;
    CloseFile(fd);
  except
    result := 'Kein Zugriff';
  end;
end;

function TNetzInfoSnap.inodetopid(inode: string):string;
var
  Info,Info2: TSearchRec;
  spid,procpidfd,procpidfdsock: string;
  //pid: integer;
  statinfo: stat;
begin
  result := 'Kein Zugriff';
  If FindFirst ('/proc/*',faDirectory,Info)=0 then
    begin
    Repeat
      With Info do
        begin
        If (Attr and faDirectory) = faDirectory then
            spid := string(Name);
        end;

       try
         //pid := StrToInt(spid);
         procpidfd := '/proc/' + spid + '/fd/';

         If FindFirst (procpidfd+'*',faSymLink,Info2)=0 then
         begin
         Repeat
               if Info2.Attr <> faDirectory then
               begin
                    procpidfdsock := procpidfd + Info2.Name;
                      if fpstat (ShortString(procpidfdsock),statinfo)<>0 then
                      begin
                           writeln('Fstat failed. file: '+procpidfdsock+' Error: ',fpgeterrno);
                      end else
                      begin
                           //writeln(procpidfdsock+' ['+spid+'] '+IntToStr(statinfo.st_ino)+ ' = '+ inode + ' ???');

                           if trim(IntToStr(statinfo.st_ino)) = trim(inode) then
                           begin
                                result := spid;
                                exit;
                           end;
                      end;
               end;
         Until FindNext(info2)<>0;
         end;
        FindClose(Info2);

       except
         //writeln('No valid PID');
       end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);

end;

function TNetzInfoSnap.Hex2IPv6(shex:string):string;
var
  block: string;
  i : integer;
  //sl: TStringList;
begin
  //sl := TStringList.Create;
  result := '';
  if Length(shex) <> 32 then
  begin
       result := 'ERROR';
  end else
  begin
     for i := 0 to 7 do
     begin
         block := shex[i*4+1];
         block := block + shex[i*4+2];
         block := block + shex[i*4+3];
         block := block + shex[i*4+4];
         if (block[1] = '0') and (block[2] = '0') and (block[3] = '0') then
         begin
              result := result + block[4];
         end else
         begin
            if (block[1] = '0') and (block[2] = '0') then
            begin
                result := result + block[3] + block[4];
            end else
            begin
               if block[1] = '0' then
               begin
                  result := result + block[2] + block[3] + block[4];
               end else
               begin
                  result := result + block;
               end;
            end;
         end;
         if i < 7 then
         begin
              result := result + ':';
         end;
     end;
  end;
  //result := shex;
end;

function TNetzInfoSnap.Hex2IPv4(shex:string):string;
var
  tmp: string;
begin
   if Length(shex) <> 8 then
   begin
   result := 'ERROR';
   end
   else
   begin
     result := '';
     tmp := shex[7] + shex[8];
     result := result + IntToStr(Hex2Dec(tmp));
     result := result + '.';
     tmp := shex[5] + shex[6];
     result := result + IntToStr(Hex2Dec(tmp));
     result := result + '.';
     tmp := shex[3] + shex[4];
     result := result + IntToStr(Hex2Dec(tmp));
     result := result + '.';
     tmp := shex[1] + shex[2];
     result := result + IntToStr(Hex2Dec(tmp));
   end;
end;

procedure TNetzInfoSnap.GenerateItemIPv6(sprotocol:string);
var
  i: integer;
  sl,sl2: TStringList;
  item: TNetzInfoItem;
begin
   //writeln('GEN: IPv6 call');
   // init item
   item.zielport:='';
   item.status:='';
   item.zielip:='';
   item.protokoll:=sprotocol;
   item.quellip:='';
   item.quellport:='';
   item.cmdline:='';
   item.pid := '';

   sl := TStringList.Create;
   sl.Delimiter:=' ';
   sl.DelimitedText:=s;
   for i :=0 to sl.Count-1 do
   begin
     //ShowMessage(IntToStr(i)+': '+sl[i]);
     if i = 1 then
     begin
       // local address
       //ShowMessage(sl[i]);
       sl2 := TStringList.Create;
       sl2.Delimiter := ':';
       sl2.DelimitedText := sl[i];
       item.quellip := sl2[0];
       item.quellport := sl2[1];
       sl2.Free;
       //ShowMessage(item.quellip);
       //ShowMessage(item.quellport);
     end;

     if i = 2 then
     begin
       // remote address
       sl2 := TStringList.Create;
       sl2.Delimiter := ':';
       sl2.DelimitedText := sl[i];
       item.zielip := sl2[0];
       item.zielport := sl2[1];
       sl2.Free;
       //item.zielip:=sl[i];
     end;

     if i = 3 then
     begin
       // state
       case IntToStr(Hex2Dec(sl[i])) of
       '0': item.status:='';
       '1': item.status:='ESTABLISHED';
       '2': item.status:='SYN_SENT';
       '3': item.status:='SYN_RECV';
       '4': item.status:='FIN_WAIT1';
       '5': item.status:='FIN_WAIT2';
       '6': item.status:='TIME_WAIT';
       '7': item.status:='CLOSE';
       '8': item.status:='CLOSE_WAIT';
       '9': item.status:='LAST_ACK';
       '10': item.status:='LISTEN';
       '11': item.status:='CLOSING';
       end;
     end;

     if i = 9 then
     begin
       // inode
       item.cmdline := pidtocmdline(inodetopid(sl[i]));
       item.pid:= inodetopid(sl[i]);
       item.inode:=sl[i];
     end;
   end;

   sl.Free;

   item.quellport:= IntToStr(Hex2Dec(item.quellport));
   item.zielport:= IntToStr(Hex2Dec(item.zielport));
   item.zielip:= Hex2IPv6(item.zielip);
   item.quellip:= Hex2IPv6(item.quellip);

   SetLength(items,Length(items)+1);
    try
   items[High(items)] := item;
    except

    end;
end;

procedure TNetzInfoSnap.GenerateItemIPv4(sprotocol:string);
var
  i: integer;
  sl,sl2: TStringList;
  item: TNetzInfoItem;
begin
   //writeln('GEN: IPv4 call.');
   // init item
   item.zielport:='';
   item.status:='';
   item.zielip:='';
   item.protokoll:=sprotocol;
   item.quellip:='';
   item.quellport:='';
   item.cmdline:='';
   item.pid := '';

   sl := TStringList.Create;
   sl.Delimiter:=' ';
   sl.DelimitedText:=s;
   for i :=0 to sl.Count-1 do
   begin
     //ShowMessage(IntToStr(i)+': '+sl[i]);
     if i = 1 then
     begin
       // local address
       sl2 := TStringList.Create;
       sl2.Delimiter := ':';
       sl2.DelimitedText := sl[i];
       item.quellip := sl2[0];
       item.quellport := sl2[1];
       sl2.Free;

     end;

     if i = 2 then
     begin
       // remote address
       sl2 := TStringList.Create;
       sl2.Delimiter := ':';
       sl2.DelimitedText := sl[i];
       item.zielip := sl2[0];
       item.zielport := sl2[1];
       sl2.Free;
       //item.zielip:=sl[i];

     end;

     if i = 3 then
     begin
       // state
       case IntToStr(Hex2Dec(sl[i])) of
       '0': item.status:='';
       '1': item.status:='ESTABLISHED';
       '2': item.status:='SYN_SENT';
       '3': item.status:='SYN_RECV';
       '4': item.status:='FIN_WAIT1';
       '5': item.status:='FIN_WAIT2';
       '6': item.status:='TIME_WAIT';
       '7': item.status:='CLOSE';
       '8': item.status:='CLOSE_WAIT';
       '9': item.status:='LAST_ACK';
       '10': item.status:='LISTEN';
       '11': item.status:='CLOSING';
       end;
     end;

     if i = 9 then
     begin
       // inode
       item.cmdline := pidtocmdline(inodetopid(sl[i]));
       item.pid:= inodetopid(sl[i]);
       item.inode:= sl[i];
     end;
   end;

   sl.Free;

   item.quellport:= IntToStr(Hex2Dec(item.quellport));
   item.zielport:= IntToStr(Hex2Dec(item.zielport));
   item.zielip:= Hex2IPv4(item.zielip);
   item.quellip:= Hex2IPv4(item.quellip);

   SetLength(items,Length(items)+1);
   writeln('items Length: '+IntToStr(Length(items)));

   items[High(items)] := item;

end;


procedure TNetzInfoSnap.ForkChild(cwPipe:cint;crPipe:cint);
var
  strlength,i : Integer;
begin
     fpWrite(cwPipe,count,SizeOf(count));
     writeln('ForkChild count: '+IntToStr(count));
     for i := LOW(items) to HIGH(items) do
     begin
          try
          //writeln('i:('+IntToStr(i)+') cmdline to return: '+items[i].cmdline);
          strlength := length(items[i].cmdline);
          fpWrite(cwPipe,strlength,SizeOf(count));
          fpWrite(cwPipe,items[i].cmdline[1],length(items[i].cmdline));
          strlength := length(items[i].inode);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].inode[1],length(items[i].inode));
          strlength := length(items[i].pid);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].pid[1],length(items[i].pid));
          strlength := length(items[i].protokoll);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].protokoll[1],length(items[i].protokoll));
          strlength := length(items[i].quellip);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].quellip[1],length(items[i].quellip));
          strlength := length(items[i].quellport);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].quellport[1],length(items[i].quellport));
          strlength := length(items[i].status);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].status[1],length(items[i].status));
          strlength := length(items[i].zielip);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].zielip[1],length(items[i].zielip));
          strlength := length(items[i].zielport);
          fpWrite(cwPipe,strlength,SizeOf(Integer));
          fpWrite(cwPipe,items[i].zielport[1],length(items[i].zielport));

          except
            writeln('Exception: Child IO Error');
          end;

     end;
     {
     recv := fpRead(crPipe,ret,SizeOf(Integer));
     if ret <> $DEAD then
     begin
          writeln('Error: $DEAD:'+IntToStr($DEAD)+' ret:'+IntToStr(ret)+' recv:'+IntToStr(recv));
     end;
     }
     fpClose(cwPipe);
     fpClose(crPipe);

end;

// Danke ChatGPT
// Hier wird noch ein Error Handling später implementiert bei Timeout
function TNetzInfoSnap.FpReadT(PipeHandle: THandle; Buffer: Pointer; BufSize: LongInt): LongInt;
var
  FDSet: TFDSet;
  TimeOut: TTimeVal;
  Ready: LongInt;
begin
  // Setze den Timeout (in Sekunden und Mikrosekunden)
  TimeOut.tv_sec := 3;
  TimeOut.tv_usec := 0;

  // Bereite das Set der File Deskriptoren vor
  fpFD_ZERO(FDSet);
  fpFD_SET(PipeHandle, FDSet);

  // Warte, ob die Pipe bereit ist, Daten zu lesen
  Ready := fpSelect(PipeHandle + 1, @FDSet, nil, nil, @TimeOut);

  if Ready = 0 then
  begin
     writeln('FpRead Timeout Reached!!!');
    // Timeout erreicht, keine Daten verfügbar
    Result := -1;  // Timeout
    Exit;
  end
  else if Ready < 0 then
  begin
    // Fehler bei fpSelect
    Result := -2;  // Fehler
    Exit;
  end
  else
  begin
    // Daten sind verfügbar, lese sie
    Result := fpRead(PipeHandle, Buffer^, BufSize);
  end;
end;

procedure TNetzInfoSnap.ForkRun();
var
    i,strlength: integer;
    buffer: array of char;
    pipe: array[0..1] of cint;
    proc: TProcess;
    output: string;
begin
   i := -1;

   if fpPipe(pipe) <> 0 then
   begin
        writeln('No pipe creation possible. Halt.');
        Halt;
   end;

   //writeln('spawning child...');

   proc := TProcess.Create(nil);
   try
     proc.Executable:=ParamStr(0);
     proc.Parameters.Add(IntToStr(pipe[1]));
     proc.Parameters.Add(IntToStr(pipe[0]));
     proc.Options := [];
     proc.Execute;
   finally

   end;


     //writeln('parent recieves ...');
     // parent recieves data

     fpRead(pipe[0],count,SizeOf(count));
     SetLength(items,count);
     writeln('count: '+IntToStr(count));
     //writeln('');

     //fpRead(pipe[0],items[0],count * SizeOf(TNetzInfoItem))));

     self.Benutzen;
     for i:=LOW(items) to HIGH(items)-1 do
     begin

          //writeln('I:'+IntToStr(i));

         if count > 0 then
         begin

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].cmdline := String(buffer);
           //writeln(items[i].cmdline);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].inode := String(buffer);
           //writeln(items[i].inode);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].pid := String(buffer);
           //writeln(items[i].pid);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].protokoll := String(buffer);
           //writeln(items[i].protokoll);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].quellip := String(buffer);
           //writeln(items[i].quellip);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].quellport := String(buffer);
           //writeln(items[i].quellport);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].status := String(buffer);
           //writeln(items[i].status);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].zielip := String(buffer);
           //writeln(items[i].zielip);

           FpReadT(pipe[0],@strlength,SizeOf(Integer));
           //writeln('strlen:'+IntToStr(strlength));
           SetLength(buffer,strlength+1);
           buffer[strlength] := Char($00);
           FpReadT(pipe[0],@buffer[0],strlength);
           items[i].zielport := String(buffer);
       end;
     end;

     self.Freigeben;
     fpClose(pipe[0]);
     fpClose(pipe[1]);


     if proc.Running then
     begin
          //writeln('forcing child termination...');
          if proc.Terminate(-1) = false then
          begin
               RunCommand('kill -s SIGKILL '+IntToStr(proc.ProcessID),output);
               writeln('SIGKILL Termination: '+output);
          end;
          Sleep(1000);
     end;
     //writeln('waiting for termination...');
     //FpWaitPid(forkpid,outstatus,0);
     proc.Free;
     //writeln('ForkRun end');





end;

procedure TNetzInfoSnap.refresh();
var
  i: integer;
  tcpip4sockets,tcpip6sockets: TextFile;
  udpip4sockets,udpip6sockets: TextFile;

begin
   SetLength(items,0);
   count := -1;
   i := -1;

     try
        AssignFile(tcpip4sockets,'/proc/net/tcp');
        reset(tcpip4sockets);
        while EOF(tcpip4sockets) = false do
        begin
          Inc(count);
          readln(tcpip4sockets,s);
          //writeln('s: '+s);
          if count > 0 then
          GenerateItemIPv4('TCP IPv4');
        end;
        CloseFile(tcpip4sockets);

        i := -1;
        AssignFile(udpip4sockets,'/proc/net/udp');
        reset(udpip4sockets);
        while EOF(udpip4sockets) = false do
        begin
          Inc(count);
          Inc(i);
          readln(udpip4sockets,s);
          //writeln('udpv4 s: '+s);
          if i > 0 then
          GenerateItemIPv4('UDP IPv4');
        end;
        CloseFile(udpip4sockets);
        i:= -1;
        AssignFile(tcpip6sockets,'/proc/net/tcp6');
        reset(tcpip6sockets);
        while EOF(tcpip6sockets) = false do
        begin
          Inc(i);
          readln(tcpip6sockets,s);
          //writeln('s: '+s);
          if i > 0 then
          begin
             Inc(count);
             GenerateItemIPv6('TCP IPv6');
          end;
        end;
        CloseFile(tcpip6sockets);

        i:= -1;
        AssignFile(udpip6sockets,'/proc/net/udp6');
        reset(udpip6sockets);
        while EOF(udpip6sockets) = false do
        begin
          Inc(i);
          readln(udpip6sockets,s);
          //writeln('s: '+s);
          if i > 0 then
          begin
             Inc(count);
             GenerateItemIPv6('UDP IPv6');
          end;
        end;
        CloseFile(udpip6sockets);
     except
       error := true;
       exit;
     end;

end;


function TNetzInfoSnap.get_count():integer;
begin
   result := count;
end;

end.

