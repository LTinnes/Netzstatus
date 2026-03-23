unit u_netzinfoioctl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseUnix, Sockets;

function gibEintrag():string;

implementation


function gibEintrag():string;
var
  str: string;
  ret,s: LongInt;
  buff: array[0..2048] of char;
begin

  s := fpSocket( AF_INET, SOCK_DGRAM, 0 );
  ret := FpIOCtl ( s , SIOCGIFCONF , @buff[0] );
  str := 'test';
  result := str;
end;

end.

