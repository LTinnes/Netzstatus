unit u_inodeprocess;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, BaseUnix;

function inodetocmdline(inode: string):string;

implementation

function pidtocmdline(in_spid: string):string;
var
  s : string;
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
       readln(fd,s);
       result := result + s;
    end;
    CloseFile(fd);
  except
    result := 'Kein Zugriff';
  end;
end;

function inodetocmdline(inode: string):string;
var
  Info,Info2: TSearchRec;
  Count,Count2: Longint;
  ln,spid,procpidfd,procpidfdsock: string;
  pid: integer;
  statinfo: stat;
begin
  result := 'Kein Zugriff';
  Count := 0;
  If FindFirst ('/proc/*',faDirectory,Info)=0 then
    begin
    Repeat
      Inc(Count);
      With Info do
        begin
        If (Attr and faDirectory) = faDirectory then
            spid := string(Name);
        end;

       try
         pid := StrToInt(spid);
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
                                result := pidtocmdline(spid);
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

end.

