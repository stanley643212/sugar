unit assets;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, sugar.htmlbuilder;

function BulmaCSS: THtmlStyleSheetLink;
function FontAwesome5JS: THtmlScript;
function JQueryJS: THTMLScript;
function JQueryMigrateJS: THTMLScript;
function SemanticUIJS: THTMLScript;
function SemanticCSS: THtmlLink;
function BootstrapCSS: THtmlStyleSheetLink;
function PopperJS: THtmlScript;
function BootstrapJS: THtmlScript;


implementation

function BulmaCSS: THtmlStyleSheetLink;
begin
    Result := THtmlStyleSheetLink.Create;
    Result.href := 'https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css';
end;


function FontAwesome5JS: THtmlScript;
begin
    Result := THTMLScript.Create;
    Result.setSrc('https://use.fontawesome.com/releases/v5.3.1/js/all.js');
    Result.setAttrFlag('defer');
end;


function JQueryJS: THTMLScript;
begin
    Result := THtmlScript.Create;
    Result.setSrc('https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min.js');
    Result.setAttr('crossorigin', 'anonymous');
    Result.setAttrFlag('defer');
end;

function JQueryMigrateJS: THTMLScript;
begin
    Result := THtmlScript.Create;
    Result.setSrc('https://cdnjs.cloudflare.com/ajax/libs/jquery-migrate/3.3.1/jquery-migrate.min.js');
    Result.setAttr('crossorigin', 'anonymous');
    Result.setAttrFlag('defer');
end;

function SemanticUIJS: THTMLScript;
begin
    Result := THtmlScript.Create;
    Result .setSrc('https://cdnjs.cloudflare.com/ajax/libs/fomantic-ui/2.8.7/semantic.min.js');
    Result.setAttrFlag('defer');
end;

function SemanticCSS: THtmlLink;
begin
    Result := THtmlLink.Create;
    with Result do
    begin
        rel := 'stylesheet';
        _type := 'text/css';
        href := 'https://cdnjs.cloudflare.com/ajax/libs/fomantic-ui/2.8.7/semantic.min.css';
    end;
end;

function BootstrapCSS: THtmlStyleSheetLink;
begin
    Result := THtmlStyleSheetLink.Create;
    Result.href :=
        'https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css';
    Result.setAttr('integrity',
        'sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T');
    Result.setAttr('crossorigin', 'anonymous');
end;

function PopperJS: THtmlScript;
begin
    Result := THTMLScript.Create;
    Result.setSrc('https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js');
    Result.setAttr('integrity',
        'sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1');
    Result.setAttr('crossorigin', 'anonymous');
    Result.setAttrFlag('defer');
end;

function BootstrapJS: THtmlScript;
begin
    Result := THTMLScript.Create;
    Result.setSrc('https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js');
    Result.setAttr('integrity',
        'sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM');
    Result.setAttr('crossorigin', 'anonymous');
    Result.setAttrFlag('defer');
end;

end.

