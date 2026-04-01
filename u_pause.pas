unit u_pause;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_objektsperre;

type
  TPause = class(TObjektSperre)

  public
    procedure Inc;
    procedure reset;
    function pause():boolean;
    constructor create(maxiteration:Integer);
  private
    counter,max: Integer;

end;


implementation


constructor TPause.create(maxiteration:Integer);
begin
     self.ObjektSperreInit;
     self.counter:=0;
     self.max := maxiteration;
end;


procedure TPause.Inc;
begin
   self.Benutzen;
   counter := counter + 1;
   self.Freigeben;
end;


function TPause.pause():boolean;
begin
   result := false;

   self.Benutzen;
   if counter >= max then
   begin
     result := true;
   end;
   self.Freigeben;


end;


procedure TPause.reset;
begin
   self.Benutzen;
   self.counter:=0;
   self.Freigeben;
end;





end.

