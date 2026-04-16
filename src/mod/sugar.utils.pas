unit sugar.utils;

{A subset of functions from rbutils. This is to remove dependencies.}

{********************************************************************}
{Uses the rhl package https://github.com/maciejkaczkowski/rhl}
{********************************************************************}

{$mode ObjFPC}{$H+}

interface

uses
     Classes, SysUtils, fpjson, fileinfo, sugar.collections, sugar.profiler;
type
    TArrInt   = array of Integer;
    TArrInt64 = array of int64;
    SChars    = set of char;
    TArrChars = array of wideChar;

const
      __ILLEGAL_CHARS             = [':', '/', '\', '?', '*', '<', '>', '|', '"'] ; // set
      __WHITESPACE_CHARS          = [#10, #13, ' ', ',', '.', ';', ':', '"', '''', '<', '>', '(', ')', '[', ']', '{', '}', '!'];
      __WHITESPACE : TStringArray = (#10, #13, ' ', ',', '.', ';', ':', '"', '''', '<', '>', '(', ')', '[', ']', '{', '}', '!'); // array

function appendPath(_paths: array of string; _delim: string = DirectorySeparator): string;
function appendURL(_paths: array of string): string;
function sanitizeFileName(_varName: string; _extension: string = '.txt'): string;

//function getFileContent(const AFileName: string; _touch: boolean = false; AEncoding: TEncoding=nil): string;
//function saveFileContent(const AFileName: string; const AContent: unicodestring; AEncoding: TEncoding = nil; const WriteBOM: Boolean = False): SizeInt;

function getFileContent(const FileName: string; _touch: boolean = false; Encoding: TEncoding=nil): string;
function saveFileContent(const FileName, Text: string; Encoding: TEncoding = nil): SizeInt;

procedure touch(const _fileName: string); // Creates an empty file

{returns the mime type for this file}
function getMimeTypeFor(_fileName: string): string;
function getMimeType(_extension: string): string;


{Data conversion functions}
function encodeURL(const _url: string): string;
function decodeURL(const _url: string): string;
function decodeURLEntities(const _url: string): string;

function makeStringArray(_strings: TStrings): TStringArray;
function stringFromArray(_arr: array of string): string;

function toStringList(const _source: string; _delim: string): TStrings;
function toStringArray(const _source: string; _delim: string = ','): TStringArray;
function stringArrayToJSON(const _source: TStringArray): TJSONArray;
function JSONToStringArray(const _source: TJSONArray): TStringArray;
function getPChar(const _text: string): PChar; {allocates memory, returns pChar}


{Hashing}
{algorithm: rhlPBKDF2}
{parameters: password, salt, number of iterations, total size of hash}
function genHash(p, s: ansistring; i: integer = 13; size: integer = 32): ansistring;
function genHashUTF8(p, s: ansistring; i: integer = 13; size: integer = 32): string;

{Key generation}
const
    KEYGEN_NUM = $01;
    KEYGEN_SMALL_LETTERS = $02;
    KEYGEN_CAP_LETTERS = $04;
    KEYGEN_ALPHANUM = $07;
    KEYGEN_ALL = $0f;

function genRandomKey(_size: word; _strength: byte = 2): ansistring;
//function genRandomKey(_size: word; _strength: byte = KEYGEN_ALPHANUM; _numpass: word = 3): ansistring;
function genPassword(_size: word = 12; _strength: word = 3): ansistring;
function genSalt(_size: word = 18; _strength: word = 4): ansistring;

{raise an exception}
procedure trip(const _msg: string);
procedure DoNothing; inline;

{Base64 encoding functions}
{Returns the content of a file as Base64 encoded string}
function FileToBase64(_fileName: string): string;
{Decodes a Base64 encoded string and saves it in a file}
procedure Base64ToFile(_b64String: string; _fileName: string);


{Copies the array and returns length}
function copyStringArray(const _source: array of string;
    var _dest: TStringArray): integer;
function copyVariantArray(const _source: array of variant;
    var _dest: TVariantArray): integer;
function copyStringToVariantArray(const _str: string; var _dest: TVariantArray): integer;
function getCommaSeparatedString(const _list: TStringArray): string;
function getCommaSeparatedString(const _list: TJSONArray): string;

function getDelimitedString(const _list: TStringArray; const _delim: string = ','): string; overload;
function getDelimitedString(const _list: TJSONArray; const _delim: string = ','): string; overload;
function getDelimitedString(const _list: TArrInt64; const _delim: string = ','): string; overload;

function strIn(const _source: string; const _set: TStringArray): boolean;
{Implements select a whole world from cursor position from a line
Extracts a string from  that lies between _prefix and _suffix.
It maybe possible to do this with regular expressions... need to check}
function strBetween(const _source: string; const _pos: integer; _prefix: TStringArray; _suffix: TStringArray; out _startPos: sizeInt; out _endPos: sizeInt): string;
function wordArray(const _source: string): TStringArray; // Returns an array of words

// Adds each item in _ar to _sl
procedure populateFromArray(_sl: TStrings; _ar: array of string);

type
    THtmlTimeMode = (useLocalTime, useUniversalTime);

{Check what Time mode is being used}
function htmlTimeMode: THtmlTimeMode;

{Forces the htmlDateTime function to use local time}
procedure htmlUseLocalTime;
{Forces the htmlDateTime function to use universal time}
procedure htmlUseUniversalTime;


function htmlDateTime: string;
function htmlDateTime(_tstamp: TDateTime): string;
function htmlDate: string;
function htmlDate(_date: TDateTime): string;
function htmlTime: string;
function htmlTime(_time: TDateTime): string;
function isoTime(_time:TDateTime): string;


function date(_isoDate: string): TDateTime; overload;
function time(_isoTime: string): TDateTime; overload;
function asMilliSeconds(_time: TDateTime): QWord;
function fromMilliSeconds(_ms: QWord): TDateTime;

{somehow autodetect if it is date time, date or time. ...}
function readHtmlDateTime(_htmlDate: string): TDateTime;

function numToText(const _num: integer): string;

{Data validation functions}
function isValidEmail(const _email: string): boolean;
function isValidDate(const _date: string): boolean;
function isValidDateTime(const _datetime: string): boolean;
function isDecimal(const _num: string): boolean;

{Checks if the passed jsonData is a valid number and returns it}
function asNumber(_j: TJSONData; _default: integer = 0) : integer;

{String manipulation}
{Searches for _word in _source and returns true or false}
function hasWord(_word: string; _source: string): boolean;
function paddedNum(const _num: word; const _padCount: word = 3): string;
function limitWords(_str: string; _limit: word): string;



{immediate if. If condition is true, returns first parameter else returns second}
function iif(_condition: boolean; _trueString: string; _falseString: string = ''): string;overload;
function iif(_condition: boolean; _trueVal: int64; _falseVal: int64 = 0): int64;overload;
function iif(_condition: boolean; _trueVal: double; _falseVal: double = 0): double;overload;
function iif(_condition: boolean; _trueVal: TDateTime; _falseVal: TDateTime = 0): TDateTime; overload;
function iif(_condition: boolean; _trueVal: TObject; _falseVal: TObject = nil): TObject; overload;
// If true, calls t_trueProc, If not calls falseProc with _sender. Returns the result of the boolean value.
function iif(_condition: boolean; _trueProc: TNotifyEvent; _falseProc: TNotifyEvent = nil; _sender: TObject=nil): boolean; overload;


{Data functions}

{Compares _prev and _current to see if the change is within plus or minus _tolerancePercentage
default tolerance is 10%}
function hasDataChanged(_prev: real; _current: real; _tolerancePercentage: real = 0.1): boolean;

function number(_s: string): integer;
function float(_s: string): extended;
function decimalFloat(_value: extended; _format: string = '###0.0##'): string; // always returns the float with a "." as the decimal separator

{initializes variables}
function initStr(const _val: string; _default: string): string;

{returns the float value formated as a date without separators}
function yyyymmdd(const _float: double): string; overload;
function yyyymmdd(const _dt: TDatetime): string; overload;

{increment a local variable -used for dynamic arrays}
function plus1(var i: integer): integer;
function profiler(const _name: string): TCodeProfiler;

// Get list of files
function getSubFolders(_dir: string; _recursive: boolean = true): TStrings;
function getFiles(_dir: string; _filter: string): TStrings;
function getFilePaths(_dir: string; _filterArr: TStringArray;_recursive: boolean = true): TStrings;


{*******************************************************************************}
// Convenience function to return the index, with boundary checking
// for a list of count values. Typical usage is the get the next index in
// in a list of _count items, if the deleted index is _curr.
// Call these functions AFTER the item is deleted, which means that _count
// is the new number of items in the modified lists.

//Usage:
//------
//    1. Get the index of the item from a list that you want to delete. Store this in _curr.
//    2. Delete the item from the list. (this changes the count)
//    3. Get the new count of the list and store in _count.
//    4. Call getNextCurrIndex(_curr, _count); This gives you the next valid, boundary-checked index to use in a for loop to re-index items
//
//Example:
//--------
//    _curr := myList.IndexOf(_obj);
//    myList.Delete(_curr);
//	 _count := myList.Count;
//	 _curr  := getNextIndex(_curr, _count);
//	 for c := _curr to pred(_count) do begin
//	     myList.Data[c].rank:= c;
//	 end;
{*******************************************************************************}
function getPrevIndex(const _curr, _count: integer) : integer;
function getNextIndex(const _curr, _count: integer) : integer;

// Convenient way to store an object address as a hex string
// to use for hash lists
function ObjAddressAsHex(constref _obj: TObject): string;
// Convert the string back to the object address.
function HexStrAsObj(_hex: string):  TObject;

{Clone functions}
function clone(constref _s: TStrings): TStrings;
function findIndex(constref _search: TStrings; constref _source: TStrings): TArrInt; overload;
function findIndex(const _search: TStringArray; constref _source: TStrings): TArrInt; overload;

function GetFileVersionInfo(const aExeFile: String): TFileVersionInfo;
function GetFileInfo(const aExeFile: String): TStrings;
function GetFileVersion(const aExeFile: String): String;
function GetApplicationVersionTitle(const aExeFile: String): String;


function loremIpsum(_len: Integer = 0): string;

function samestring(s1, s2: string): boolean;
function yesno(const _val: boolean): string;
function truefalse(const _val: boolean): string;
function sanitzeFileName(_varName: string; _extension: string): string;


function genUUID(const _nobrace: boolean = true): string;
function isValidURI(const _uri: string): boolean;
// Weak ETAG implementation.
// Returns W/"<size>-<epochseconds>"
function genFileETag(const _path: string): string;

function SecureEquals(const A, B: RawByteString): Boolean; inline;

function IsValidIPv4(const S: string): boolean;

implementation
uses
     URIParser,
     winpeimagereader, {need this for reading exe info}
     elfreader, {needed for reading ELF executables}
     machoreader, {needed for reading MACH-O executables}
     fpmimetypes, variants, strutils, jsonparser, FileUtil,
     LazFileUtils, jsonscanner, rhlSHA256, rhlCore, rhlTiger2, RegExpr,
     math, base64, LazStringUtils, DateUtils, sugar.logger, sugar.threadwriter, LazUTF8;

	{nsort, MarkdownUtils,}

var
	{No need to Free this because it points to the singleton in fpmimetypes}
    myMimeTypes: TFPMimeTypes = nil;

function appendPath(_paths: array of string; _delim: string): string;
var
    _i, _count: integer;
    _tmpPath: string;

    function otherSeparator: string;
    begin
        case _delim of
            '/': Result := '\';
            '\': Result := '/';
		end;
	end;

begin
    Result := '';
    _count := Length(_paths);

    for _i := 0 to pred(_count) do
    begin
        if (Result.Length > 0) and Result.EndsWith('/') or Result.EndsWith('\') then
            Result := Result.Remove(Result.Length - 1, 1);

        _tmpPath := _paths[_i];
        _tmpPath := _tmpPath.Replace(otherSeparator, _delim);

        if not _tmpPath.isEmpty then
        begin
	        if _i =  0 then
            begin
                {This is the first item.
                Check for drive letter in case of windows.
                Don't append the directory separator}
			end
            else begin
                if not (_tmpPath.StartsWith(_delim)) then
                _tmpPath := _delim + _tmpPath;
			end;

            Result := Result + _tmpPath;
	    end;

    end;
end;

function appendURL(_paths: array of string): string;
begin
    Result := appendPath(_paths, '/');
end;

function sanitizeFileName(_varName: string; _extension: string): string;
var
    i: integer;
    function sanitize(_fName: string): string;
    var
    	i: Integer;
    begin
        Result:= '';
        for i := 1 to _fName.Length do
        begin
            if (Ord(_fName[i]) > 32) and not (_fName[i] in __ILLEGAL_CHARS) then
                Result := Result + _fName[i];
    	end;
    end;

begin
    Result := sanitize(_varName);
    if _extension.IsEmpty then
        exit;

    {else}
    if not _extension.StartsWith('.') then
        Result := Result + '.';

    Result := Result + sanitize(_extension);
end;

//function getFileContent(const AFileName: string; _touch: boolean; AEncoding: TEncoding): string;
//var
//    fs: TFileStream;
//    ss: TStringStream;
//begin
//    Result := '';
//    if not FileExists(AFilename) then begin
//        if _touch then begin
//            SaveFileContent(AFileName, '');
//		end;
//        exit;
//	end;
//
//    if AEncoding = nil then AEncoding := TEncoding.UTF8;
//    fs := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
//    try
//        ss := TStringStream.Create('', AEncoding);
//        try
//            ss.CopyFrom(fs, 0);
//            Result := ss.DataString;
//        finally
//            ss.Free;
//        end;
//    finally
//        fs.Free;
//    end;
//end;

function getFileContent(const FileName: string; _touch: boolean; Encoding: TEncoding): string;
var
    Bytes: TBytes;
    FS: TFileStream;

begin
    Result := '';
    if not FileExists(FileName) then begin
        if _touch then begin
            SaveFileContent(FileName, '');
  	    end;
        exit;
    end;

    if Encoding = nil then
        Encoding := TEncoding.UTF8;
    FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
        SetLength(Bytes, FS.Size);
        FS.ReadBuffer(Bytes[0], Length(Bytes));
        Result := Encoding.GetString(Bytes);
    finally
        FS.Free;
    end;
end;


function saveFileContent(const FileName, Text: string; Encoding: TEncoding
	): SizeInt;
var
    FS: TFileStream;
    Bytes: TBytes;
begin
    if Encoding = nil then
        Encoding := TEncoding.UTF8;
    Bytes := Encoding.GetBytes(Text);
    FS := TFileStream.Create(FileName, fmCreate);
    try
        FS.WriteBuffer(Bytes[0], Length(Bytes));
        Result := Length(Bytes);
    finally
        FS.Free;
    end;
end;

//function saveFileContent(const AFileName: string;
//	const AContent: unicodestring; AEncoding: TEncoding; const WriteBOM: Boolean
//	): SizeInt;
//const
//    CHUNK = 4096;
//var
//    fs: TFileStream;
//    bytes, preamble: TBytes;
//    offset, count, total: SizeInt;
//begin
//    if AEncoding = nil then
//        AEncoding := TEncoding.UTF8;
//
//    if WriteBOM then
//        preamble := AEncoding.GetPreamble;
//
//    fs := TFileStream.Create(AFileName, fmCreate);
//    try
//        // write BOM if requested
//        if Length(preamble) > 0 then
//        begin
//            fs.WriteBuffer(preamble[0], Length(preamble));
//            Inc(total, Length(preamble));
//        end;
//
//        // materialize bytes *once*
//        bytes := AEncoding.GetBytes(AContent);
//        Result := Length(bytes);  // number of bytes to be written
//        if Result > 0 then
//          fs.WriteBuffer(bytes[0], Result);
//
//    finally
//        fs.Free;
//    end;
//    //TThreadFileWriter.put(_filename, _content);
//end;


procedure touch(const _fileName: string);
begin
    getFileContent(_fileName, true);
end;

function getMimeTypeFor(_fileName: string): string;
begin
    Result:= getMimeType(ExtractFileExt(_fileName));
end;

function getMimeType(_extension: string): string;
begin
    {This is to load mimetypes only once}
    if not Assigned(myMimeTypes) then
    begin
        {myMimeTypes does not need to be freed explicitly because
        it the object is created in fpmimetypes and is freed there.
        We are only using a pointer to the created object through the
        factory funciton MimeTypes()}
        myMimeTypes:= MimeTypes;

        {$IFDEF windows}
        myMimeTypes.LoadKnownTypes;
        {$ELSE}
        try
            myMimeTypes.LoadKnownTypes;
		except
            ;
		end;
		{$ENDIF}
	end;
    try
        Result:= myMimeTypes.GetMimeType(_extension);
	except
        Result:= '';
	end;
end;


function encodeURL(const _url: string): string;
var
    i: integer;
begin
    i := _url.Length;
    Result := '';
    while (i > 0) do
    begin
        case _url[i] of
            ' ', '"', '%', '!', '#', '$', '&',
            '''', '(', ')', '*', '+', ',', '/',
            '-', '.', '<', '>', '\', '^', '_', '`',
            '{', '|', '}', '~', ';', '=', '?',
            '[', ']':
                Result := '%' + Ord(_url[i]).ToHexString(2) + Result;
            #13: ; // Result := '%0A'+ Result;
            #10: Result := '%0A'+ Result;
            else
                Result := _url[i] + Result;
        end;
        Dec(i);
    end;
end;

function decodeURL(const _url: string): string;
const
    CODE_SIZE = 2;
var
    len, i, safeLim: integer;
    _code: string;
    safeToCheck: boolean;
    tmpStr: string;

begin
    Result := '';
    i := 1;
    len := _url.Length;
    safeLim := len - CODE_SIZE;
    while (i <= len) do
    begin
        safeToCheck := (i <= safeLim);
        tmpStr := _url[i];
        if (tmpStr = '%') and safeToCheck then
        begin
            tmpStr := char(StrToInt('$' + _url[i + 1] + _url[i + 2]));
            Inc(i, CODE_SIZE);
        end;
        Result := Result + tmpStr;
        Inc(i);
    end;
end;

function decodeURLEntities(const _url: string): string;
begin
    Result:= _url.Replace('&amp;', '&');
end;

function makeStringArray(_strings: TStrings): TStringArray;
var
    i: integer;
begin
    Result := [];
    SetLength(Result, _strings.Count);
    for i := 0 to _strings.Count - 1 do
        Result[i] := _strings[i];
end;

function stringFromArray(_arr: array of string): string;
var
    s: string;
begin
    Result := '';
    for s in _arr do
    begin
        if not Result.IsEmpty then
            Result := Result + ' ';
        Result := Result + s;
    end;
end;

function toStringList(const _source: string; _delim: string): TStrings;
var
    _array: TStringArray;
    _count, _i: integer;
begin
    Result := TStringList.Create;
    _array := _source.Split([_delim]);
    _count := length(_array);
    for _i := 0 to _count - 1 do
    begin
        Result.Add(Trim(_array[_i]));
    end;
    SetLength(_array, 0);
end;

function toStringArray(const _source: string; _delim: string): TStringArray;
var
    i: integer;
begin
    Result := [];
    if Trim(_source).isEmpty then
        setLength(Result, 0)
    else
    begin
        Result := _source.split(_delim);
        for i := 0 to High(Result) do
            Result[i] := Trim(Result[i]); {make sure that each item is trimmed}

	end;
end;

function stringArrayToJSON(const _source: TStringArray): TJSONArray;
var
	_val: String;
begin
    Result:= TJSONArray.Create;
    for _val in _source do
        Result.Add(_val);
end;

function JSONToStringArray(const _source: TJSONArray): TStringArray;
var
	_el: TJSONEnum;
begin
    Result := [];
    SetLength(Result, _source.count);
    for _el in _source do
    begin
        case _el.Value.JSONType of
        jtString, jtNumber, jtBoolean:
            Result[_el.KeyNum] := _el.Value.AsString;
        jtArray, jtObject:
            Result[_el.KeyNum] := _el.Value.AsJSON;
		end;

	end;
end;

function getPChar(const _text: string): PChar;
begin
    Result := nil;
    if not _text.isEmpty then
    begin
        Result := StrAlloc(Succ(_text.Length));
        StrPCopy(Result, _text);
    end;
end;


function genHash(p, s: ansistring; i: integer; size: integer): ansistring;
begin
    Result := rhlPBKDF2(p, s, i, size, TrhlSHA256);
end;

function genHashUTF8(p, s: ansistring; i: integer; size: integer): string;
begin
    Result := UTF8Encode(genHash(p, s, i, size));
end;

{
function genRandomKey(_size: word; _strength: byte)
Strength is a number between 0 - 5
    0 = numbers
    1 = include small letters
    2 = include capital letters
    3 = include weak special characters
    4 = inlude special characters that contain programming language symbols}
function genRandomKey(_size: word; _strength: byte): ansistring;
const
    keyNumbersLen = 10;
    keyNumbers = '0123456789';

    keyCapLettersLen = 26;
    keySmallLetters = 'abcdefghijklmnopqrstuvwxyz';

    keySmallLettersLen = 26;
    keyCapLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    keySpecialCharsLen = 8;
    keySpecialChars = '!$()@[~]';

    keySpecialChars2Len = 14;
    keySpecialChars2 = '^&*=+-_<>?:;|`';
var
    i: integer;
    x: integer;

    function randomIndex(_len: integer): byte;
    begin
        Result := random(_len) + 1; {to avoid zero}
        if Result > _len then
            Result := _len; {to limit exceeding length}
    end;

begin
    Result := '';
    {limit the value of strength}
    if (_strength > 5) then
        _strength := 3;

    for x := 1 to _size do
    begin

        {Simple algorithm.
            1) Randomly select between types of keys (decided by _strength)
            2) Generate a random number less than string length
            3) Return the character at that index.
        Repeat until size is reached}

        i := Random(_strength);
        case i of
            0:  Result := Result + keyNumbers[randomIndex(keyNumbersLen)];
            1:  Result := Result + keySmallLetters[randomIndex(keySmallLettersLen)];
            2:  Result := Result + keyCapLetters[randomIndex(keyCapLettersLen)];
            3:  Result := Result + keySpecialChars[randomIndex(keySpecialCharsLen)];
            4:  Result := Result + keySpecialChars2[randomIndex(keySpecialChars2Len)];
        end;
    end;
end;

function genPassword(_size: word; _strength: word): ansistring;
begin
    Result := genRandomKey(_size, _strength);
end;

function genSalt(_size: word; _strength: word): ansistring;
begin
    Result := genRandomKey(_size, _strength);
end;

procedure trip(const _msg: string);
begin
    raise Exception.Create(_msg);
end;

procedure DoNothing;
begin
  ; {Really. Do nothing.}
end;


function FileToBase64(_fileName: string): string;
var
  sourceStream: TFileStream;
  destStream: TStringStream;
  b64Encoder: TBase64EncodingStream;
begin
    try
        sourceStream:= TFileStream.Create(_fileName, fmOpenRead);
        destStream:= TStringStream.Create('');
        b64Encoder:= TBase64EncodingStream.Create(destStream);
        b64Encoder.CopyFrom(sourceStream, sourceStream.Size);
        Result:= destStream.DataString;
    finally
        b64Encoder.Free;
        destStream.Free;
        sourceStream.Free;
	end;
end;

procedure Base64ToFile(_b64String: string; _fileName: string);
var
  sourceStream: TStringStream;
  destStream: TFileStream;
  b64Decoder: TBase64DecodingStream;
begin
    try
        sourceStream:= TStringStream.Create(_b64String);
        destStream:= TFileStream.Create(_fileName, fmCreate or fmOpenWrite);
        b64Decoder:= TBase64DecodingStream.Create(sourceStream);
        destStream.CopyFrom(b64Decoder, b64Decoder.Size);
	finally
        b64Decoder.Free;
        destStream.Free;
        sourceStream.Free;
	end;
end;

function copyStringArray(const _source: array of string;
    var _dest: TStringArray): integer;
var
    i: integer;
begin
    Result := Length(_source); {return length of array}
    setLength(_dest, Result);
    for i := 0 to Result - 1 do
        _dest[i] := Trim(_source[i]);
end;

function copyVariantArray(const _source: array of variant;
    var _dest: TVariantArray): integer;
var
    i: integer;
begin
    Result := Length(_source); {return length of array}
    setLength(_dest, Result);
    for i := 0 to Result - 1 do
        _dest[i] := _source[i];

end;

function copyStringToVariantArray(const _str: string;
    var _dest: TVariantArray): integer;
var
    i: integer;
    len: integer;
    _sArray: TStringArray;
begin
    _sArray := _str.split(',');
    len := Length(_sArray);
    setLength(_dest, len);
    for i := 0 to len - 1 do
        _dest[i] := Trim(_sArray[i]);

    Result := len;
end;

function getCommaSeparatedString(const _list: TStringArray): string;
begin
    Result := getDelimitedString(_list, ',');
end;

function getCommaSeparatedString(const _list: TJSONArray): string;
begin
    Result:= getDelimitedString(_list, ',');
end;

function getDelimitedString(const _list: TStringArray; const _delim: string): string;
var
    _addComma: boolean;
    _item: string;
begin
    Result := '';
    _addComma := False;
    for _item in _list do
    begin
        if _addComma then
            Result := Result + _delim
        else
            _addComma := True;

        Result := Result + _item;
    end;
end;

function getDelimitedString(const _list: TJSONArray; const _delim: string
	): string;
var
	member: TJSONEnum;
    _addDelim: boolean = false;
begin
    Result:= '';
    for member in _list do
    begin
        if _addDelim then
            Result:= Result + _delim
        else
            _addDelim:= true;

        case member.Value.JSONType of
            jtUnknown, jtNull:
                ; {do nothing}

            jtNumber, jtString, jtBoolean:
                Result:= Result + member.value.AsString;

            jtArray, jtObject:
                Result:= Result + member.value.AsJSON;
        end;
	end;
end;

function getDelimitedString(const _list: TArrInt64; const _delim: string
	): string;
var
	_i: Int64;
begin
  Result := '';
  for _i in _list do begin
      if not Result.isEmpty then Result := Result + _delim;
      Result:= Result + IntToStr(_i);
  end;
end;

function strIn(const _source: string; const _set: TStringArray): boolean;
var
    _c: String;
begin
    Result := False;
    for _c in _set do begin
        Result := UTF8CompareStr(_source, _c) = 0;
        if Result then break;
  	end;
end;

function strBetween(const _source: string; const _pos: integer;
	_prefix: TStringArray; _suffix: TStringArray; out _startPos: sizeInt; out
	_endPos: sizeInt): string;
var
  _length,i: SizeInt;
begin
    _length := UTF8Length(_source);

    _startPos := _pos;
    _endPos   := _startPos;

    if (_startPos <= 0) or (_startPos > _length) then Exit('');

    while (_startPos >= 0) and not(strIn(UTF8Copy(_source,_startPos, 1), _prefix)) do dec(_startPos);
    while (_endPos <= _length) and not (strIn(UTF8Copy(_source,_endPos, 1),_suffix)) do Inc(_endPos);

    if _startPos <= 0 then _startPos := 1; // to fix empty space when selecting first word in string

    Result := UTF8Copy(_source,  _startPos, (_endPos - _startPos));

end;

function wordArray(const _source: string): TStringArray;
var
    _count, _startPos, _endPos: sizeInt;
    _length : sizeInt;

begin
    Result := [];
    _length := UTF8Length(_source);
    if _length = 0 then exit;

    _count    := 0;
    _startPos := 1;
    _endPos   := 1;

    SetLength(Result, _length);
    while (_endPos <= _length) do begin
        while (_startPos <= _length) and (strIn(UTF8Copy(_source,_startPos, 1), __WHITESPACE)) do inc(_startPos);

        _endPos := _startPos;
        while (_endPos <= _length) and not(strIn(UTF8Copy(_source,_endPos, 1), __WHITESPACE)) do inc(_endPos);

        if _endPos >= _startPos then begin
            Result[_count] := UTF8Copy(_source,  _startPos, (_endPos - _startPos));
            inc(_count);
		end;
        _startPos := _endPos;
	end;
    SetLength(Result, _count);
end;

procedure populateFromArray(_sl: TStrings; _ar: array of string);
var
	_s: String;
begin
    for _s in _ar do _sl.Add(_s);
end;


var
    myHtmlTimeMode: THtmlTimeMode;

function htmlTimeMode: THtmlTimeMode;
begin
    Result:= myHtmlTimeMode;
end;

procedure htmlUseLocalTime;
begin
    myHtmlTimeMode:= useLocalTime;
end;

procedure htmlUseUniversalTime;
begin
    myHtmlTimeMode:= useUniversalTime;
end;

function htmlDateTime: string;
begin
    Result := htmlDateTime(now);  // htmlDateTime(now);
end;

function htmlDateTime(_tstamp: TDateTime): string;
begin
    //Result := DateToISO8601(now, (htmlTimeMode = useUniversalTime));
    Result := htmlDate(_tstamp) + 'T' + htmlTime(_tstamp);
end;

function htmlDate: string;
begin
    Result := htmlDate(Now);
end;

function htmlDate(_date: TDateTime): string;
begin
    Result := FormatDateTime('yyyy-mm-dd', _date);
end;

function htmlTime: string;
begin
    Result := htmlTime(Now);
end;

function htmlTime(_time: TDateTime): string;
var
	h, m, s, ms: word;
begin
    case myHtmlTimeMode of
        useLocalTime:      begin
            DecodeTime(_time, h, m, s, ms);
            Result := Format('%.2d:%.2d:%.2d',[h,m,s]);  // FormatDateTime('HH:nn:ss', _time);    {Need to include timezone parsing}
		end;
		useUniversalTime:  begin
            //Result := FormatDateTime('HH:nn:ss GMT', LocalTimeToUniversal(_time));
            DecodeTime(LocalTimeToUniversal(_time), h, m, s, ms);
            Result := Format('%.2d:%.2d:%.2d GMT',[h,m,s]);
        end;
    end;
end;

function isoTime(_time: TDateTime): string;
begin
    Result:= htmlDateTime(_time);
    Result:= Result.Substring((Pos('T', Result)));
end;

function date(_isoDate: string): TDateTime;
var
    _parts: TStringArray;
    _dt: TStringArray;
    _tm: TDateTime;

    y: integer = 1900;
    m: integer = 1;
    d: integer = 1;
    h: integer = 0;
    n: integer = 0;
    s: integer = 0;
    ms: integer= 0;
begin
    _parts:= toStringArray(_isoDate, 'T');
    if length(_parts) >= 1 then
    begin
        _dt:= toStringArray(_parts[0], '-');
        if length(_parts) = 2 then
        begin
            {Get the time}
            _tm:= time(_parts[1]);
		end;

        if length(_dt) >= 3 then
        begin
            y:= number(_dt[0]);
            m:= number(_dt[1]);
            d:= number(_dt[2]);
		end;
	end;

    if TryEncodeDate(y, m, d, Result) then
        {Join the date and time together}
        Result:= ComposeDateTime(Result, _tm)
    else
        Result:= EncodeDateTime(1900, 1, 1, 0, 0, 0, 0);
end;

function time(_isoTime: string): TDateTime;
var
  h: integer = 0;
  n: integer = 0;
  s: integer = 0;
  ms: integer= 0;
  _tm: TStringArray;
begin
    _tm := toStringArray(_isoTime, ':');
    if length(_tm) >= 3 then
    begin
        h:= number(_tm[0]);
        n:= number(_tm[1]);
        s:= number(_tm[2]);
        if length(_tm) = 4 then ms := number(_tm[3]);
	end;

    if not TryEncodeTime(h, n, s, ms, Result) then
        Result:= EncodeTime(0,0,0,0);
end;

function asMilliSeconds(_time: TDateTime): QWord;
begin
    Result := Round(_time * 24 * 60 * 60 * 1000);
end;

function fromMilliSeconds(_ms: QWord): TDateTime;
begin
    Result := _ms / MSecsPerDay;  // MSecsPerDay = 86400000
end;


function readHtmlDateTime_not_used(_htmlDate: string): TDateTime;
begin
    TryISO8601ToDate(_htmlDate, Result, (htmlTimeMode = useUniversalTime));
end;

function readHtmlDateTime(_htmlDate: string): TDateTime;
{ I am keeping this because this I really enjoyed writing this little procedure }
type
    DecodeStage = (dcNone, dcYear, dcMonth, dcDay, dcHours, dcMinutes,
        dcSeconds, dcTimeZone);
var
    _stage: DecodeStage = dcNone;

    _endDelims: array[DecodeStage] of string = (
        {None}      '',
        {Year}      '-',
        {Month}     '-',
        {Date}      'T',
        {Hours}     ':',
        {Minutes}   ':',
        {Seconds}   'Z+-',
        {TimeZone}  '');

    Y, M, D, H, N, S, T: string;
    i, len: integer;
    c: char;
    proceed: boolean;

    function _isValid(_target: string): boolean;
    begin
        case _stage of
            dcNone:
            Result:= true;

            dcYear:
            Result := (Length(_target) < 5); {Year cannot be greater than 4}

            dcMonth, dcDay, dcHours, dcMinutes, dcSeconds:
            Result := (Length(_target) < 3);

            dcTimeZone:
            Result:= (Length(_target)<6); {+00:00}
        end;
    end;

    function _decodeChar(var _target: string; _c: char): boolean;
    begin
        Result:= true;
        if pos(_c,_endDelims[_stage]) > 0 then
            Inc(_stage)
        else
        begin
            _target := _target + _c;
            Result  := _isValid(_target);
        end;
    end;

begin
    Result := TDateTime(Math.MaxDouble); //( = NullDate. Repeating this here to avoid dependency on unit datetimectrls;)
    len := Length(_htmlDate);
    _stage := dcYear;

    for i := 1 to len do
    begin
        c := _htmlDate[i];
        case _stage of
            dcNone: ;
            dcYear:    proceed:= _decodeChar(Y, c);
            dcMonth:   proceed:= _decodeChar(M, c);
            dcDay:     proceed:= _decodeChar(D, c);
            dcHours:   proceed:= _decodeChar(H, c);
            dcMinutes: proceed:= _decodeChar(N, c);
            dcSeconds: proceed:= _decodeChar(S, c);
            dcTimeZone:proceed:= _decodeChar(T, c);
        end;

        if not proceed then break;
    end;

    if proceed then
    begin
        // writeln('Y=',Y, ' M=',M,' D=',D,' H=',H,' N=',N,' S=',S);
        if H.isEmpty then
            H := '00';
        if N.isEmpty then
            N := '00';
        if S.isEmpty then
            S := '00';
        if T.isEmpty then
           T:='+0:00';
        try
            Result:= EncodeDateTime(Y.toInteger, M.ToInteger, D.ToInteger, H.ToInteger, N.ToInteger, S.ToInteger, 0);
            if myHtmlTimeMode = useUniversalTime then
                Result := UniversalTimeToLocal(Result);
        except
            on E: Exception do Log('readHtmlDateTime():: ' + e.Message);
        end;
    end
    else
        Log('readHtmlDateTime():: Could not parse _htmlDate: ' + _htmlDate);
end;


function numToText(const _num: integer): string;
begin
    Result := '';
    case _num of
        0: Result := 'zero';
        1: Result := 'one';
        2: Result := 'two';
        3: Result := 'three';
        4: Result := 'four';
        5: Result := 'five';
        6: Result := 'six';
        7: Result := 'seven';
        8: Result := 'eight';
        9: Result := 'nine';
        10: Result := 'ten';
        11: Result := 'eleven';
        12: Result := 'twelve';
        13: Result := 'thirteen';
        14: Result := 'fourteen';
        15: Result := 'fifteen';
        16: Result := 'sixteen';
        17: Result := 'seventeen';
        18: Result := 'eighteen';
        19: Result := 'nineteen';
        20: Result := 'twenty';
    end;
end;

function isValidEmail(const _email: string): boolean;
begin
    with TRegExpr.Create('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$') do
    begin
        Result := Exec(_email);
        Free;
    end;
end;

function isValidDate(const _date: string): boolean;
begin
    Result := True;
    try
        StrToDate(_date);
    except
        Result := False;
    end;
end;

function isValidDateTime(const _datetime: string): boolean;
begin
    Result := True;
    try
        StrToDateTime(_datetime);
    except
        Result := False;
    end;
end;

function isDecimal(const _num: string): boolean;
begin
    if _num.isEmpty then
        Result:= false
    else
    begin
        Result:= isNumber(_num.Replace('.', '').Replace(DefaultFormatSettings.DecimalSeparator, ''));
	end;
end;

function asNumber(_j: TJSONData; _default: integer): integer;
begin
  if _j.JSONType = jtNumber then
  begin
      //Log('_j is a number');
      Result:= _j.asInteger
  end
  else
  begin
      if isDecimal(_j.asString) then
      begin
        //Log('_j is a string but is a number');
        Result:= strToInt(_j.asString);
	  end
	  else
      begin
          //Log('_j is is not a number so applying default');
          Result:=_default;
	  end;
  end;
end;

function hasWord(_word: string; _source: string): boolean;
begin
    with TRegExpr.Create('\b' + _word + '\b') do
    begin
        Result := Exec(_source);
        Free;
    end;
end;

function paddedNum(const _num: word; const _padCount: word = 3): string;
var
  _fmtStr: string;
begin
    Result:= AddChar('0',_num.ToString, _padCount);
end;

function limitWords(_str: string; _limit: word): string;
var
    wPos: DWord;
begin
    wPos:= Pred(WordPosition(_limit, _str,StdWordDelims));
    Result:= LeftStr(_str, wPos);
    if wPos<_str.Length then
        Result:= Result + '...';
end;

function iif(_condition: boolean; _trueString: string; _falseString: string): string;
begin
    if _condition then
        Result := _trueString
    else
        Result := _falseString;
end;

function iif(_condition: boolean; _trueVal: int64; _falseVal: int64): int64;
begin
    if _condition then
        Result := _trueVal
    else
        Result := _falseVal;
end;

function iif(_condition: boolean; _trueVal: double; _falseVal: double): double;
begin
    if _condition then
        Result := _trueVal
    else
        Result := _falseVal;

end;

function iif(_condition: boolean; _trueVal: TDateTime; _falseVal: TDateTime
	): TDateTime;
begin
    if _condition then
        Result := _trueVal
    else
        Result := _falseVal;
end;

function iif(_condition: boolean; _trueVal: TObject; _falseVal: TObject
	): TObject;
begin
    if _condition then
        Result := _trueVal
    else
        Result := _falseVal;
end;

function iif(_condition: boolean; _trueProc: TNotifyEvent;
	_falseProc: TNotifyEvent; _sender: TObject): boolean;
begin
    Result:= _condition;
    try
	    case Result of
	        True:   if assigned(_trueProc) then _trueProc(_sender);
	        False:  if assigned(_falseProc) then _falseProc(_sender);
	    end;

	except
        ; // suppress exception
	end;
end;



function hasDataChanged(_prev: real; _current: real;
	_tolerancePercentage: real): boolean;
var
    _diff: real;
    _tolerance: real;
    _changePercentage: real;
begin
    {Check if the percentage of change is within +/- tolerance}
    _diff:= _prev - _current;
    if isZero(_diff) then
        Result:= False
    else
    begin
        {Diff and _previous are not zero}
        _tolerance:= _prev * _tolerancePercentage;
        Result:= not InRange(_current, (_prev - _tolerance), (_prev + _tolerance));
	end;
end;

function number(_s: string): integer;
begin
    try
        Result:= strToInt(_s);
	except
        Result:= 0;
	end;
end;

function float(_s: string): extended;
begin
    try
        Result:= StrToFloat(_s);
	except
        Result:= 0;
	end;

end;

function decimalFloat(_value: extended; _format: string): string;
var
    _formatSettings: TFormatSettings;
begin
    _formatSettings := FormatSettings;
    _formatSettings.DecimalSeparator:='.';
    Result := FormatFloat(_format, _value, _formatSettings);
end;

function initStr(const _val: string; _default: string): string;
begin
    if _val.isEmpty then
        Result:= _default
    else
        Result:= _val;
end;

function yyyymmdd(const _float: double): string;
begin
    Result:= yyyymmdd(FloatToDateTime(_float));
end;

function yyyymmdd(const _dt: TDatetime): string;
var
    y, m, d : word;
begin
    try
        DecodeDate(_dt, y, m, d);
        Result := format('%4d%2d%2d',[y,m,d]);
	except
        Result:= '00000000';
	end;
end;

function plus1(var i: integer): integer;
begin
    // i := i + 1;
    Inc(i);
    Result := i;
end;

function profiler(const _name: string): TCodeProfiler;
begin
    Result := TCodeProfiler.Create(_name);
end;

function getSubFolders(_dir: string; _recursive: boolean): TStrings;
var
    fInfo: TSearchRec;
    found: boolean;
    _path, _filter: string;
    _tmpResult: TStrings;

    function isDirectory(_finfo: TSearchRec): boolean;
    begin
        Result := faDirectory = (_finfo.Attr and faDirectory);
    end;

begin
    Result := TStringList.Create;
    found := FindFirst(appendPath([_dir, '*.*']), faDirectory, fInfo) = 0;
    if found then begin
        repeat
            case FInfo.Name of
                '.', '..': continue;
			end;
			_path := _dir + {\}DirectorySeparator + FInfo.Name;
            if isDirectory(fInfo) then begin
                Result.Add(_path);
                if _recursive then begin
	                _tmpResult := getSubFolders(_path, _recursive);
	                Result.AddStrings(_tmpResult);
	                _tmpResult.Free;
				end;
			end;
		until FindNext(fInfo) <> 0;
	end;

end;


function getFiles(_dir: string; _filter: string): TStrings;
begin
    Result := getFilePaths(_dir, [_filter], false);
end;

function getFilePaths(_dir: string; _filterArr: TStringArray;
    _recursive: boolean = true): TStrings;
var
    fInfo: TSearchRec;
    found: boolean;
    _path, _filter: string;
    _tmpResult: TStrings;

    function isDirectory(_finfo: TSearchRec): boolean;
    begin
        Result := faDirectory = (_finfo.Attr and faDirectory);
    end;
begin
    Result := TStringList.Create;
    if _recursive then
    begin
        found := FindFirst(appendPath([_dir, '*.*']), faDirectory, fInfo) = 0;
        if found then begin
            repeat

                case FInfo.Name of
                    '.', '..': continue; // ignore folders
				end;

				_path := _dir + {\}DirectorySeparator + FInfo.Name;
	            if isDirectory(fInfo) then begin
	                _tmpResult := getFilePaths(_path, _filterArr, _recursive);
	                Result.AddStrings(_tmpResult);
	                _tmpResult.Free;
	            end;

			until FindNext(fInfo) <> 0;
		end;
    end;

    for _filter in _filterArr do
    begin
        _path := appendPath([_dir, _filter]);
        found := FindFirst(_path, faAnyFile, fInfo) = 0;
        if found then
        begin
            repeat
                _path := appendPath([_dir, FInfo.Name]);
                Result.Add(_path);
            until FindNext(fInfo) <> 0;
        end;
        FindClose(fInfo);
    end;
end;

function getPrevIndex(const _curr, _count: integer): integer;
begin
    Result:= -1;
    if _curr = 0 then
    begin
        if _count > 0 then
            Result := 0
	end
    else if _count > 0 then
        Result:= pred(_curr);
end;

function getNextIndex(const _curr, _count: integer): integer;
begin
     Result:= -1;
    if _curr = 0 then begin
        if _count > 0 then
            Result := 0

    end else if _curr = _count then
    begin
       Result := pred(_curr);

	end else if _count > _curr then
        Result:= _curr

end;

function ObjAddressAsHex(constref _obj: TObject): string;
begin
    Result :=  PtrUInt(_obj).ToHexString(16);
end;

function HexStrAsObj(_hex: string): TObject;
begin
    Result := TObject(PtrUInt(Hex2Dec64(_hex)));
end;

function clone(constref _s: TStrings): TStrings;
begin
    Result := TStringList.Create;
    Result.Assign(_s);
end;

function findIndex(constref _search: TStrings; constref _source: TStrings
	): TArrInt;
begin
    Result := findIndex(makeStringArray(_search), _source);
end;

function findIndex(const _search: TStringArray; constref _source: TStrings
	): TArrInt;
var
    _map: TStringIndexMap;
	i, c: Integer;
	_s: String;
begin
    Result := [];
    _map := TStringIndexMap.Create();
    try
        for i := 0 to pred(_source.Count) do begin
            _map.idx[_source.Strings[i]] := i;
    	end;

        SetLength(Result, Length(_search));
        c := 0;
        for _s in _search do begin
            i := _map.idx[_s];
            if  i <> NOINDEX then
                Result[c] := i;
            inc(c);
		end;

        setLength(Result, c);
	finally
        _map.Free;
	end;
end;

function GetFileVersionInfo(const aExeFile: String): TFileVersionInfo;
begin
    Result := TFileVersionInfo.Create(nil);
    Result.Enabled := true;
    if not FileExists(aExeFile) then begin
        Exit;
    end;
    Result.FileName:= aExeFile; // Because enabled is true, this will read the info.
end;

function GetFileVersion(const aExeFile: String): String;
var
	_fileInfo: TFileVersionInfo;
begin
    _fileInfo := GetFileVersionInfo(aExeFile);
    try
        Result := _fileInfo.VersionStrings.Values['FileVersion'];
    finally
        _fileInfo.Free;
    end;
end;

function GetApplicationVersionTitle(const aExeFile: String): String;
var
	v: TStrings;
begin
    v := getFileInfo(aExeFile);
    try
        Result := Format('%s :: %s', [v.Values['ProductName'], v.Values['FileVersion']])
	finally
        v.Free;
	end;
end;

function GetFileInfo(const aExeFile: String): TStrings;
var
	_fileInfo: TFileVersionInfo;
begin
    Result := TStringList.Create;
    _fileInfo := GetFileVersionInfo(aExeFile);
    try
        Result.Assign(_fileInfo.VersionStrings);

        // OTHER VALUES
        //    writeln('Company: ',          Result.VersionStrings.Values['CompanyName']);
        //    writeln('File description: ', Result.VersionStrings.Values['FileDescription']);
        //    writeln('File version: ',     Result.VersionStrings.Values['FileVersion']);
        //    writeln('Internal name: ',    Result.VersionStrings.Values['InternalName']);
        //    writeln('Legal copyright: ',  Result.VersionStrings.Values['LegalCopyright']);
        //    writeln('Original filename: ',Result.VersionStrings.Values['OriginalFilename']);
        //    writeln('Product name: ',     Result.VersionStrings.Values['ProductName']);
        //    writeln('Product version: ',  Result.VersionStrings.Values['ProductVersion']);

    finally
        _fileInfo.Free;
    end;
end;

function loremIpsum(_len: Integer): string;
const
    S = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Huius ego nunc auctoritatem sequens idem faciam. Duo Reges: constructio interrete. Primum Theophrasti, Strato, physicum se voluit; Bork Prave, nequiter, turpiter cenabat; Istic sum, inquit.'+ sLineBreak +
    ''+ sLineBreak +
    'Ut aliquid scire se gaudeant? Hoc sic expositum dissimile est superiori. Id enim natura desiderat. Quid autem habent admirationis, cum prope accesseris?'+ sLineBreak +
    ''+ sLineBreak +
    'Sed quae tandem ista ratio est? Cui Tubuli nomen odio non est? Cum praesertim illa perdiscere ludus esset. Quid autem habent admirationis, cum prope accesseris? Nam ista vestra: Si gravis, brevis; Bork'+ sLineBreak +
    ''+ sLineBreak +
    'Mihi quidem Antiochum, quem audis, satis belle videris attendere. Ut pulsi recurrant? Ille enim occurrentia nescio quae comminiscebatur;'+ sLineBreak +
    ''+ sLineBreak +
    'Quid ergo attinet gloriose loqui, nisi constanter loquare? Non laboro, inquit, de nomine. Quid dubitas igitur mutare principia naturae? Quae cum essent dicta, discessimus.'+ sLineBreak +
    ''+ sLineBreak +
    'At ille pellit, qui permulcet sensum voluptate. Illud non continuo, ut aeque incontentae. Quaerimus enim finem bonorum. Paria sunt igitur.'+ sLineBreak +
    ''+ sLineBreak +
    'Quid censes in Latino fore? Quae cum dixisset paulumque institisset, Quid est?'+ sLineBreak +
    ''+ sLineBreak +
    'Quis istum dolorem timet? Tum Torquatus: Prorsus, inquit, assentior; Minime vero istorum quidem, inquit. Que Manilium, ab iisque M. Esse enim quam vellet iniquus iustus poterat inpune. Age, inquies, ista parva sunt. Haec para/doca illi, nos admirabilia dicamus. Cupiditates non Epicuri divisione finiebat, sed sua satietate.'+ sLineBreak +
    ''+ sLineBreak +
    'Bork Illi enim inter se dissentiunt. Ut aliquid scire se gaudeant? At ille pellit, qui permulcet sensum voluptate.'+ sLineBreak +
    ''+ sLineBreak +
    'Istam voluptatem perpetuam quis potest praestare sapienti? Invidiosum nomen est, infame, suspectum. Utram tandem linguam nescio? Quamvis enim depravatae non sint, pravae tamen esse possunt. Quis Aristidem non mortuum diligit? Mihi enim satis est, ipsis non satis.';
begin
    if _len = 0 then
        Result := Copy(S, 0)
    else
        Result := Copy(S, 0, _len);
end;


function samestring(s1, s2: string): boolean;
var
    i: integer;
begin
    s1 := s1.Replace(sLineBreak, '');
    s2 := s2.Replace(sLineBreak, '');
    Result := s1.Length = s1.Length;
    if Result then
    begin
        for i := 1 to s1.Length do
        begin
            Result := s1[i] = s2[i];
            if not Result then
                break;
        end;
    end;
end;

function yesno(const _val: boolean): string;
begin
    case _val of
        True: Result := 'Yes';
        False: Result := 'No';
    end;
end;

function truefalse(const _val: boolean): string;
begin
    case _val of
        True: Result := 'True';
        False: Result := 'False';
    end;
end;

function sanitzeFileName(_varName: string; _extension: string): string;
var
    i: integer;
begin
    Result := '';
    {Replace invalid characters in one pass}
    for i := 1 to _varName.Length do
    begin
        case _varName[i] of
            ' ', ':', '.',
            DirectorySeparator: Result := Result + '-';
            else
                Result := Result + _varName[i];
        end;
    end;

    if _extension.IsEmpty then
        exit;

    {else}
    if not _extension.StartsWith('.') then
        Result := Result + '.';

    Result := Result + _extension;
end;

function genUUID(const _nobrace: boolean): string;
var
    G: TGUID;
	l: SizeInt;
begin
    if CreateGUID(G) = 0 then begin // S_OK
        Result := GUIDToString(G);
    end
    else
        raise Exception.Create('genUUID:: failed.');

    if _nobrace then begin
        l := Length(Result);
        if l > 0 then
            Result := copy(Result, 2, l-2);
    end;

end;

function isValidURI(const _uri: string): boolean;
begin
    try
        ParseURI(_uri);
        Result := True;
    except
        Result := False;
    end;
end;

function dateTimeToUnixSeconds(const DT: TDateTime): Int64;
begin
  Result := DateTimeToUnix(DT, False{InputIsUTC}); // since we pass UTC below
end;

function genFileETag(const _path: string): string;
var
  dtLocal, dtUTC: TDateTime;
  size64 : Int64;
  unixSec: Int64;
begin
  Result := '';
  if not FileExists(_path) then Exit;
  if not FileAge(_path, dtLocal) then Exit;

  dtUTC  := LocalTimeToUniversal(dtLocal);
  unixSec:= DateTimeToUnixSeconds(dtUTC);
  size64 := FileSizeUTF8(_path);
  Result := Format('W/"%d-%d"', [size64, unixSec]);
end;

function SecureEquals(const A, B: RawByteString): Boolean; inline;
var
  i: SizeInt; diff: Byte = 0;
begin
  if Length(A) <> Length(B) then exit(False);
  for i := 1 to Length(A) do
    diff := diff or (Byte(A[i]) xor Byte(B[i]));
  Result := diff = 0;
end;

function IsValidIPv4(const S: string): boolean;
var
    Parts: TStringList;
    I, N: integer;
    Part: string;
begin
    Result := False;

    Parts := TStringList.Create;
    try
        Parts.StrictDelimiter := True;
        Parts.Delimiter := '.';
        Parts.DelimitedText := S;

        if Parts.Count <> 4 then
            Exit;

        for I := 0 to 3 do
        begin
            Part := Parts[I];

            // Empty segment not allowed
            if Part = '' then
                Exit;

            // Only decimal integer allowed
            if not TryStrToInt(Part, N) then
                Exit;

            // Must be in IPv4 octet range
            if (N < 0) or (N > 255) then
                Exit;

            // Optional: reject leading zeros like 001
            if (Length(Part) > 1) and (Part[1] = '0') then
                Exit;
        end;

        Result := True;
    finally
        Parts.Free;
    end;
end;


initialization
    randomize;
     //InitCriticalSection(myFilerCriticalSection);
     //writeln('This Commander Riker @ TID = ', GetThreadID);
     //InitCriticalSection(myLockerCriticalSection);

finalization
    //TTextFiler.shutdown;
    //DoneCriticalSection(myFilerCriticalSection);
    // DoneCriticalSection(myLockerCriticalSection);
end.

