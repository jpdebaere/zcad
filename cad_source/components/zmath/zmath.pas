{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit zmath;

interface

uses
  geometry, zemathutils, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('zmath', @Register);
end.