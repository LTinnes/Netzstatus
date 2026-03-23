unit u_hostblock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type THostBlock = class
  public
    constructor create();
    function getContent: string;

implementation

end.

