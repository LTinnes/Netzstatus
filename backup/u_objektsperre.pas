unit u_objektsperre;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type TObjektSperre = class
  private
     objsperre: TRTLCriticalSection;
  public
     procedure Benutzen;
     procedure Freigeben;

end;





implementation

procedure TObjektSperre.Benutzen;
begin
  EnterCriticalSection(objsperre);
end;

procedure TObjektSperre.Freigeben;
begin
  LeaveCriticalSection(objsperre);
end;

end.

