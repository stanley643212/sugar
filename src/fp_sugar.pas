{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit fp_sugar;

{$warn 5023 off : no warning about unused units}
interface

uses
     sugar.http, sugar.utils, sugar.uihelper, sugar.collections, sugar.logger, 
     sugar.profiler, sugar.htmlbuilder, sugar.csshelper, sugar.htmlfactory, 
     sugar.textfiler, sugar.threadwriter, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('fp_sugar', @Register);
end.
