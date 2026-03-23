unit u_inodeliste;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type Tinodelist = class
  public
    constructor Create();
    function isinodeinlist(inode: string):boolean;
    function getthisinode(var inode:string):boolean;
    function getnext():Tinodelist;
    function countinodes():integer;
    function getset():boolean;
    procedure setnext(next: Tinodelist);
    procedure setthisinode(inode: string);
    procedure removeinodefromlist(inode:string);
    procedure removeme();
    procedure addinodetolist(inode:string);
  private
    this_next: Tinodelist;
    inode_set: boolean;
    this_inode: string;
    count: integer;
end;

implementation

constructor Tinodelist.Create();
begin
   this_next := nil;
   this_inode := '';
   inode_set := false;
   count := 0;
end;

function Tinodelist.getset():boolean;
begin
   result := inode_set;
end;

function Tinodelist.countinodes():integer;
begin
   result := count;
end;

function Tinodelist.isinodeinlist(inode: string):boolean;
var
  curr: Tinodelist;
  curr_inode : string;
begin
  curr_inode := '';
  result := false;
  curr := self;
  while curr <> nil do
  begin

    if curr.getthisinode(curr_inode) then
    begin
      //writeln(curr_inode);
       if curr_inode = inode then
       begin
          result := true;
       end;
    end;

    curr := curr.getnext();
  end;
end;

procedure Tinodelist.removeinodefromlist(inode:string);
var
  curr: Tinodelist;
  curr_inode : string;
begin
   curr_inode := '';
   curr := self;
     while curr <> nil do
     begin

       if curr.getthisinode(curr_inode) then
       begin
         //writeln(curr_inode);
          if curr_inode = inode then
          begin
             Dec(self.count);
             curr.removeme();
             if curr <> self then
             begin
                curr.Free;
             end;
          end;
       end;

       curr := curr.getnext();

     end;
end;

function Tinodelist.getthisinode(var inode:string):boolean;
begin
   result := inode_set;
   inode := this_inode;
end;

function Tinodelist.getnext():Tinodelist;
begin
  result := this_next;
end;

procedure Tinodelist.setnext(next: Tinodelist);
begin
   this_next := next;
end;

procedure Tinodelist.setthisinode(inode: string);
begin
   this_inode := inode;
   inode_set := true;
end;

procedure Tinodelist.removeme();
var
  proc_inode: string;
begin
   proc_inode := '';
   if this_next = nil then
   begin
      inode_set := false;
   end else
   begin
      if this_next.getthisinode(proc_inode) then
      begin
         this_inode := proc_inode;
         inode_set := true;
      end else
      begin
         inode_set := false;
      end;
      this_next := this_next.getnext();
   end;
end;

procedure Tinodelist.addinodetolist(inode:string);
var
  new_item: Tinodelist;
begin
   new_item := Tinodelist.Create();
   new_item.setthisinode(inode);
   new_item.setnext(this_next);
   this_next := new_item;
   Inc(self.count);
end;

end.

