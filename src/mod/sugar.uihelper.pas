unit sugar.uihelper;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Graphics;
type

    TUIState  = (uiDefault, uiHighlight, uiWarning, uiError);
	{ TOnHover }

    TOnHover = class
        procedure OnMouseEnter(Sender: TObject);
        procedure OnMouseLeave(Sender: TObject);
    end;

    // Sets the font color depending on the UIState
    procedure uiState(_c: TControl; _s: TUIState; _hint: string = '');

    function onHover: TOnHover;
    procedure setHover(_lbl: TLabel);
    procedure uiShake(_c: TControl);

    procedure populateFromArray(_sl: TStrings;_ar: array of string);

    // extracts a real value from the edit box. if it is not a real value, it returns the default value
    function realVal(constref _c: TWinControl; const _default: real = 0.0): real;
    function intVal (constref _c: TWinControl; const _default: integer = 0): integer;

    // Converts and sets values to the edit control
    procedure setVal(constref _c: TWinControl; const _value: integer); overload;
    procedure setVal(constref _c: TWinControl; const _value: double); overload;
    procedure setVal(constref _c: TWinControl; const _value: double; _format: TFormatSettings); overload;
    function  numAsStr(const _val: integer): string;
    function  numAsStr(const _val: double): string;
    function  numAsStr(const _val: double; _format: TFormatSettings): string;


    // Visual indication of the control when it enters;
    procedure onControlFocus(Sender:TObject);
    procedure onControlExit(Sender: TObject);


implementation
uses
    Forms, sugar.utils;
var
  myOnHover: TOnHover;

function onHover: TOnHover;
begin
    Result:= myOnHover;
end;

procedure setHover(_lbl: TLabel);
begin
    _lbl.OnMouseEnter:= @onHover.OnMouseEnter;
    _lbl.OnMouseLeave:= @onHover.OnMouseLeave;
end;

procedure uiShake(_c: TControl);
const
  WAIT = 200;

var
  i: integer;
begin
    for i:= 0 to 14 do
    begin
        _c.Top := _c.Top + 3;
        Sleep(WAIT);
        Application.ProcessMessages;
        _c.Top := _c.Top - 3;
        Application.ProcessMessages;
    end;
    _c.Visible:= true;

end;

{ TOnHover }

procedure TOnHover.OnMouseEnter(Sender: TObject);
var
	_lbl: TLabel;
begin
    if Sender is TLabel then
    begin
        _lbl := Sender as TLabel;
        _lbl.Font.Style:= _lbl.Font.Style + [fsUnderline];
        _lbl.Font.Color:= clHighlight;
        _lbl.Cursor := crHandPoint;
	end;
end;

procedure TOnHover.OnMouseLeave(Sender: TObject);
var
	_lbl: TLabel;
begin
    if Sender is TLabel then
    begin
        _lbl := Sender as TLabel;
        _lbl.Font.Style:= _lbl.Font.Style - [fsUnderline];
        _lbl.Font.Color:= clDefault;
        _lbl.Cursor := crDefault;
	end;
end;

procedure uiState(_c: TControl; _s: TUIState; _hint: string);
begin

    _c.Font.Style := _c.Font.Style - [fsBold];

    case _s of
    	uiDefault:   begin
            _c.Font.Color   := clDefault;
            _c.color        := clDefault
		end;

		uiHighlight: begin
            _c.Font.Color:= clHighlightText;
            _c.color := clHighlight;
        end;

        uiWarning:   begin
            _c.Font.Color:= clPurple;
            _c.color := clInfoBk;

		end;

		uiError:    begin
            _c.Font.Color := clRed;
            _c.Font.Style := _c.Font.Style + [fsBold];
            _c.color := clInfoBk;
		end;
	end;

    _c.Hint:= _hint;
    _c.ShowHint:= not _hint.IsEmpty;
end;

procedure populateFromArray(_sl: TStrings;
	_ar: array of string);
var
	_s: String;
begin
    for _s in _ar do
        _sl.Add(_s);
end;

function realVal(constref _c: TWinControl; const _default: real): real;
var
    _val: string = '';
begin
    if (_c is TEdit) then
        _val := TEdit(_c).Text
    else if (_c is TComboBox) then
        _val := TComboBox(_c).Text;

    if not _val.isEmpty then
        try
            Result := StrToFloat(_val);
	    except
            Result:= _default;
	    end;
end;

function intVal(constref _c: TWinControl; const _default: integer): integer;
var
    _val: string = '';
begin
    if (_c is TEdit) then
        _val := TEdit(_c).Text
    else if (_c is TComboBox) then
        _val := TComboBox(_c).Text;

    if not _val.isEmpty then
        try
            Result := StrToInt(_val);
	    except
            Result:= _default;
	    end;

end;

procedure setVal(constref _c: TWinControl; const _value: integer);
begin
    if (_c is TEdit) then
        TEdit(_c).Text :=  numAsStr(_value)
    else if (_c is TComboBox) then
        TComboBox(_c).Text :=  numAsStr(_value)
    else
        trip(Format('setVal: %s not supported', [_c.ClassName]));

end;

procedure setVal(constref _c: TWinControl; const _value: double);
begin
    if (_c is TEdit) then
        TEdit(_c).Text :=  numAsStr(_value)
    else if (_c is TComboBox) then
        TComboBox(_c).Text :=  numAsStr(_value)
    else
        trip(Format('setVal: %s not supported', [_c.ClassName]));
end;

procedure setVal(constref _c: TWinControl; const _value: double;
	_format: TFormatSettings);
begin
    if (_c is TEdit) then
        TEdit(_c).Text :=  numAsStr(_value)
    else if (_c is TComboBox) then
        TComboBox(_c).Text :=  numAsStr(_value, _format)
    else
        trip(Format('setVal: %s not supported', [_c.ClassName]));
end;

function numAsStr(const _val: integer): string;
begin
    try
        Result:= _val.ToString;
	except
        Result := 'NAN';
	end;
end;

function numAsStr(const _val: double): string;
begin
    try
        Result:= _val.ToString;
	except
        Result := 'NAN';
	end;
end;

function numAsStr(const _val: double; _format: TFormatSettings): string;
begin
    try
        Result:= _val.ToString(_format);
	except
        Result := 'NAN';
	end;
end;


procedure onControlFocus(Sender: TObject);
begin
    if Sender is TFrame then
        TFrame(Sender).Color:= cl3DLight;
end;

procedure onControlExit(Sender: TObject);
begin
    if Sender is TFrame then
        TFrame(Sender).Color:= clDefault;
end;


initialization
    myOnHover := TOnHover.Create;

finalization
    myOnHover.Free;
end.

