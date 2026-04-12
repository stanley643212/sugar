unit sugar.inifiles;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, PropertyStorage, IniFiles, fgl;

type

    TSugarIniFile = class;

	{ TSugarIniSection }

    TSugarIniSection = class
	private
		mysection: string;
		function getBoolValue(_name: string): boolean;
		function getDateTimeValue(_name: string): TDateTime;
		function getDateValue(_name: string): TDateTime;
		function getDecValue(_name: string): extended;
		function getMyInifile: string;
		function getNumValue(_name: string): Int64;
		function getraw: string;
		function getTextValue(_name: string): string;
		function getTimeValue(_name: string): TDateTime;
		procedure setBoolValue(_name: string; const _value: boolean);
		procedure setDateTimeValue(_name: string; const _value: TDateTime);
		procedure setDateValue(_name: string; const _value: TDateTime);
		procedure setDecValue(_name: string; const _value: extended);
		procedure setNumValue(_name: string; const _value: Int64);
		procedure setRaw(const _value: string);
		procedure setsection(const _value: string);
		procedure setTextValue(_name: string; const _value: string);
		procedure setTimeValue(_name: string; const _value: TDateTime);
    protected
        mySugarIniFile: TSugarIniFile;

    public
        constructor Create(_iniFile: TSugarIniFile; _section: string = '');
        destructor Destroy; override;
        property iniFile: string read getMyInifile;
        property section: string read mysection write setsection;
        property text    [_name: string]: string read getTextValue write setTextValue;
        property num     [_name: string]: Int64 read getNumValue write setNumValue;
        property decimal [_name: string]: extended read getDecValue write setDecValue;
        property bool    [_name: string]: boolean read getBoolValue write setBoolValue;
        property date    [_name: string]: TDateTime read getDateValue write setDateValue;
        property time    [_name: string]: TDateTime read getTimeValue write setTimeValue;
        property dateTime[_name: string]: TDateTime read getDateTimeValue write setDateTimeValue;
        property raw: string read getraw write setRaw; // Raw text below the section
	end;

    TSugarIniSectionList = class(specialize TFPGMapObject<string, TSugarIniSection>);

    { TSugarIniFile }

    TSugarIniFile = class(TIniFile)
	private
		function getBoolValue(_section: string; _name: string): boolean;
		function getDateTimeValue(_section: string; _name: string): TDateTime;
		function getDateValue(_section: string; _name: string): TDateTime;
		function getDecValue(_section: string; _name: string): extended;
		function getNumValue(_section: string; _name: string): Int64;
		function getraw: string;
		function getSection(_section: string): TSugarIniSection;
		function getTextValue(const _section: string; const _name: string): string;
		function getTimeValue(_section: string; _name: string): TDateTime;
		procedure setBoolValue(_section: string; _name: string;
			const _value: boolean);
		procedure setDateTimeValue(_section: string; _name: string;
			const _value: TDateTime);
		procedure setDateValue(_section: string; _name: string;
			const _value: TDateTime);
		procedure setDecValue(_section: string; _name: string;
			const _value: extended);
		procedure setNumValue(_section: string; _name: string;
			const _value: Int64);
		procedure setRaw(const _value: string);
		procedure setTextValue(const _section: string; const _name: string; const _value: string
			);
		procedure setTimeValue(_section: string; _name: string;
			const _value: TDateTime);
    public
        constructor Create(const AFileName: string; AOptions: TIniFileoptions=[ifoStripComments,
            ifoStripInvalid, ifoEscapeLineFeeds, ifoWriteStringBoolean]); overload; override;
        property text    [_section: string; _name: string]: string read getTextValue write setTextValue;
        property num     [_section: string; _name: string]: Int64 read getNumValue write setNumValue;
        property decimal [_section: string; _name: string]: extended read getDecValue write setDecValue;
        property bool    [_section: string; _name: string]: boolean read getBoolValue write setBoolValue;
        property date    [_section: string; _name: string]: TDateTime read getDateValue write setDateValue;
        property time    [_section: string; _name: string]: TDateTime read getTimeValue write setTimeValue;
        property dateTime[_section: string; _name: string]: TDateTime read getDateTimeValue write setDateTimeValue;
        property section[_section: string]:TSugarIniSection read getSection;
        property raw: string read getraw write setRaw; // Raw text below the section

	end;


implementation


{ TSugarIniFile }

function TSugarIniFile.getBoolValue(_section: string; _name: string): boolean;
begin
    Result := ReadBool(_section, _name, false);
end;

function TSugarIniFile.getDateTimeValue(_section: string; _name: string
	): TDateTime;
begin
    Result := ReadDateTime(_section, _name, 0);
end;

function TSugarIniFile.getDateValue(_section: string; _name: string): TDateTime;
begin
    Result := ReadDate(_section, _name, 0);
end;

function TSugarIniFile.getDecValue(_section: string; _name: string): extended;
begin
    Result := ReadFloat(_section, _name, 0.0);
end;

function TSugarIniFile.getNumValue(_section: string; _name: string): Int64;
begin
    Result := ReadInt64(_section, _name, 0);
end;

function TSugarIniFile.getraw: string;
begin

end;

function TSugarIniFile.getSection(_section: string): TSugarIniSection;
begin

end;

function TSugarIniFile.getTextValue(const _section: string; const _name: string
	): string;
begin
    Result := ReadString(_section, _name, '');
end;

function TSugarIniFile.getTimeValue(_section: string; _name: string): TDateTime;
begin
    Result := ReadTime(_section, _name, 0);
end;

procedure TSugarIniFile.setBoolValue(_section: string; _name: string;
	const _value: boolean);
begin
    WriteBool(_section, _name, _value);
end;

procedure TSugarIniFile.setDateTimeValue(_section: string; _name: string;
	const _value: TDateTime);
begin
    WriteDateTime(_section, _name, _value);
end;

procedure TSugarIniFile.setDateValue(_section: string; _name: string;
	const _value: TDateTime);
begin
    WriteDate(_section, _name, _value);
end;

procedure TSugarIniFile.setDecValue(_section: string; _name: string;
	const _value: extended);
begin
    WriteFloat(_section, _name, _value);
end;

procedure TSugarIniFile.setNumValue(_section: string; _name: string;
	const _value: Int64);
begin
    WriteInt64(_section, _name, _value);
end;

procedure TSugarIniFile.setRaw(const _value: string);
begin

end;

procedure TSugarIniFile.setTextValue(const _section: string; const _name: string;
	const _value: string);
begin
    WriteString(_section, _name, _value);
end;

procedure TSugarIniFile.setTimeValue(_section: string; _name: string;
	const _value: TDateTime);
begin
    WriteTime(_section, _name, _value);
end;

constructor TSugarIniFile.Create(const AFileName: string;
	AOptions: TIniFileoptions);
begin
	inherited Create(AFileName, AOptions);
    BoolTrueStrings  := ['true','yes','1'];
    BoolFalseStrings := ['false','no','0'];
end;

{ TSugarIniSection }

function TSugarIniSection.getBoolValue(_name: string): boolean;
begin
    Result := mySugarIniFile.bool[section, _name];
end;

function TSugarIniSection.getDateTimeValue(_name: string): TDateTime;
begin
    Result := mySugarIniFile.DateTime[section, _name];
end;

function TSugarIniSection.getDateValue(_name: string): TDateTime;
begin
    Result := mySugarIniFile.Date[section, _name];
end;

function TSugarIniSection.getDecValue(_name: string): extended;
begin
    Result := mySugarIniFile.decimal[section, _name];
end;

function TSugarIniSection.getMyInifile: string;
begin
    Result := mySugarIniFile.FileName;
end;

function TSugarIniSection.getNumValue(_name: string): Int64;
begin
    Result := mySugarIniFile.num[section, _name];
end;

function TSugarIniSection.getraw: string;
begin

end;

function TSugarIniSection.getTextValue(_name: string): string;
begin
    Result := mySugarIniFile.text[section, _name];
end;

function TSugarIniSection.getTimeValue(_name: string): TDateTime;
begin
    Result := mySugarIniFile.time[section, _name];
end;

procedure TSugarIniSection.setBoolValue(_name: string; const _value: boolean);
begin
    mySugarIniFile.bool[section, _name] := _value;
end;

procedure TSugarIniSection.setDateTimeValue(_name: string; const _value: TDateTime
	);
begin
    mySugarIniFile.datetime[section, _name] := _value;
end;

procedure TSugarIniSection.setDateValue(_name: string; const _value: TDateTime);
begin
    mySugarIniFile.date[section, _name] := _value;
end;

procedure TSugarIniSection.setDecValue(_name: string; const _value: extended);
begin
    mySugarIniFile.Decimal[section, _name] := _value;
end;

procedure TSugarIniSection.setNumValue(_name: string; const _value: Int64);
begin
    mySugarIniFile.Num[section, _name] := _value;
end;

procedure TSugarIniSection.setRaw(const _value: string);
begin

end;

procedure TSugarIniSection.setsection(const _value: string);
begin
	if mysection=_value then Exit;
	mysection:=_value;
end;

procedure TSugarIniSection.setTextValue(_name: string; const _value: string);
begin
    mySugarIniFile.text[section, _name] := _value;
end;

procedure TSugarIniSection.setTimeValue(_name: string; const _value: TDateTime);
begin
    mySugarIniFile.Time[section, _name] := _value;
end;

constructor TSugarIniSection.Create(_iniFile: TSugarIniFile; _section: string);
begin
    inherited Create;
    mySugarIniFile   := _iniFile;
    mysection       := _section;
end;

destructor TSugarIniSection.Destroy;
begin
    mySugarIniFile.Free;
	inherited Destroy;
end;


end.

