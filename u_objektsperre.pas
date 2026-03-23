unit u_objektsperre;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type TObjektSperre = class
  private
     objsperre: TRTLCriticalSection;
  protected
     procedure ObjektSperreInit;
  public
     procedure Benutzen;
     procedure Freigeben;

end;





implementation

procedure TObjektSperre.ObjektSperreInit;
begin
  InitCriticalSection(objsperre);
end;

procedure TObjektSperre.Benutzen;
begin
  EnterCriticalSection(objsperre);
end;

procedure TObjektSperre.Freigeben;
begin
  LeaveCriticalSection(objsperre);
end;

end.

