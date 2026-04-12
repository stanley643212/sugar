unit sugar.logger;

{$mode objfpc}{$H+}

interface
uses
	 Classes, SysUtils;

type
	TLogLevel = (logNone, logInfo, logHints, logDebug, logExtra, logBroadcast);

 	{ TLogger }
 	TLogger = class
 	private
    	myLogFileName: string;
     	mynumberOfBackups: word;
     	myclearOnStart: boolean;
     	mylogEnabled: boolean;
     	myLogstr: string;
     	myLogWrite: string;
     	mylastWriteTime: QWord;
     	procedure setnumberOfBackups(const _numberOfBackups: word);
     	procedure setclearOnStart(const _clearOnStart: boolean);
     	procedure setlogEnabled(const _logEnabled: boolean);
     	procedure WriteLog(_logstring: string);
     	function shouldWrite(): boolean;

 	public
     	constructor Create(const _logfile: string = 'logger.log';_enabled: boolean = True; _clearonstart: boolean = True);
     	destructor Destroy; override;

     	function fileName: string; overload;
     	function fileName(_fname: string): string; overload;
     	function log(const _logstring: string): integer;
     	function Clear: boolean; // clears the current log;
     	function backup: boolean;
     	// create a backup of the current file. starts a new log
     	function wipeAll: integer; // returns the number of backups deleted

    public
     	property numberOfBackups: word read mynumberOfBackups write setnumberOfBackups;
     	property clearOnStart: boolean read myclearOnStart write setclearOnStart;
     	property logEnabled: boolean read mylogEnabled write setlogEnabled;
 	end;

    {Log file}
    procedure writeToLog(_logfilename: string; _logstr: string);
    procedure startLog(_filename: string = 'log.txt'; _logLevel: TLogLevel = logInfo; _shouldDisplayOnConsole: boolean = true);
    function isLogStarted: boolean;
    function getLogFileName: string;
    function getLogLevel: TLogLevel;
    procedure setLogLevel(_loglevel: TLogLevel);
    function getLogLevelName(_l: TLogLevel): string;
    procedure pauseLog;

    {logInfo}
    procedure log(const logtext: string; _loglevel: TLogLevel = logInfo); overload;
    procedure log(const _fmt: string; _variables: array of const; _loglevel: TLogLevel = logInfo); overload;

    {logHints}
    procedure log1(const logtext: string); overload;
    procedure log1(const _fmt: string; _variables: array of const); overload;

    {logDebug}
    procedure log2(const logtext: string); overload;
    procedure log2(const _fmt: string; _variables: array of const); overload;

    {logExtra}
    procedure log3(const logtext: string); overload;
    procedure log3(const _fmt: string; _variables: array of const); overload;

    procedure writeLog(_logfilename: string; _logstr: string);
    procedure freeLog;

implementation

var
	myLogger: TLogger;
    myLogLevel: TLogLevel = logNone;
    myShouldDisplayOnConsole: boolean = false;

    myLoggerCS: TRTLCriticalSection;


procedure startLog(_filename: string; _logLevel: TLogLevel;
	_shouldDisplayOnConsole: boolean);
begin
    if not Assigned(myLogger) then
        myLogger := TLogger.Create(ExpandFileName(_filename))
    else
        myLogger.fileName(_filename);

    myShouldDisplayOnConsole:= _shouldDisplayOnConsole;
    myLogLevel := _logLevel;
    myLogger.logEnabled := True;
end;

function isLogStarted: boolean;
begin
    Result:= Assigned(myLogger);
end;

function getLogFileName: string;
begin
    Result:= '';
    if isLogStarted then
        Result:= myLogger.fileName;
end;

function getLogLevel: TLogLevel;
begin
    Result:= myLogLevel;
end;

procedure setLogLevel(_loglevel: TLogLevel);
begin
    myLogLevel:= _loglevel;
end;

function getLogLevelName(_l: TLogLevel): string;
begin
    case _l of
        logNone:  Result:= 'No Log';
        logHints: Result:= 'Log Hints';
        logInfo:  Result:= 'Log Information';
        logDebug: Result:= 'Log Debug';
        logExtra: Result:= 'Log Extra Messages';
    end;
end;

procedure pauseLog;
begin
    myLogger.logEnabled := False;
end;

procedure log(const logtext: string; _loglevel: TLogLevel);
var
    bShouldLog: boolean;
begin
    bShouldLog:= _loglevel <= myLogLevel;
    if isLogStarted then
    begin
        if bShouldLog then
            myLogger.log(logtext);
    end;
    {$IFDEF LINUX}
    if bShouldLog and myShouldDisplayOnConsole then
        writeln(logtext);
    {$ENDIF}
end;

procedure log(const _fmt: string; _variables: array of const; _loglevel: TLogLevel);
begin
    Log(format(_fmt, _variables), _loglevel);
end;

procedure log1(const logtext: string);
begin
    log(logtext, logHints);
end;

procedure log1(const _fmt: string; _variables: array of const);
begin
    log(_fmt, _variables, logHints);
end;

procedure log2(const logtext: string);
begin
    log(logtext, logDebug);
end;

procedure log2(const _fmt: string; _variables: array of const);
begin
    log(_fmt, _variables, logDebug);
end;

procedure log3(const logtext: string);
begin
    log(logtext, logExtra);
end;

procedure log3(const _fmt: string; _variables: array of const);
begin
    log(_fmt, _variables, logExtra);
end;

procedure writeLog(_logfilename: string; _logstr: string);
begin
    try
        writeToLog(_logfilename, _logstr);
    except
        ; // don't react if logfile cannot be written.
    end;
end;

procedure freeLog;
begin
    if isLogStarted then
        FreeAndNil(myLogger);
end;


{ TLogger }

procedure TLogger.setclearOnStart(const _clearOnStart: boolean);
begin
    if myclearOnStart = _clearOnStart then
        Exit;
    myclearOnStart := _clearOnStart;
end;

procedure TLogger.setlogEnabled(const _logEnabled: boolean);
begin
    if mylogEnabled = _logEnabled then
        Exit;
    mylogEnabled := _logEnabled;
end;

procedure TLogger.WriteLog(_logstring: string);
begin
    writeToLog(myLogFileName, _logstring);
end;

procedure writeToLog(_logfilename: string; _logstr: string);
const
    MAX_ATTEMPTS = 7;
var
    logfile: Text;
	_ioResult: Word = 0;
    _writeAttempt : word = 1;
    _openAttempt: word = 1;
	s: String;
begin
    EnterCriticalSection(myLoggerCS);
    try
        repeat
            {$I-}
            {OPENT FILE}
	        AssignFile(logfile, _logfilename);
	        _ioResult := IOResult;
	        if _ioResult = 0 then begin // Assign file
                {WRITE FILE}
		        repeat
		            Append(logfile);
		            _ioResult := IOResult;
		            if _ioResult = 0 then begin
		                Writeln(logfile, _logstr)
		            end
		            else begin
		                inc(_writeAttempt);
		                if _writeAttempt > MAX_ATTEMPTS then
		                    _ioResult := 0; // Break the loop
		                //else
		                //    sleep(80);
					end;
				until _ioResult = 0;

                {CLOSE FILE}
		        repeat
		            CloseFile(logFile);
		            _ioResult := IOResult;
		            if _ioResult <> 0 then
		            begin
		                inc(_writeAttempt);
		                if _writeAttempt > MAX_ATTEMPTS then
		                    _ioResult := 0; // Break the loop
		                //else
		                //    sleep(80);
					end;
				until _ioResult = 0;

	        end
            else begin // Assign File was not successful
                inc (_openAttempt);
	            if _openAttempt > MAX_ATTEMPTS then
	                _ioResult := 0; // Break the loop
	            //else
	            //    sleep(80);
            end;
            {$I+}
        until _ioResult = 0;
	except
        on E:Exception do begin
            s := E.Message;
            sleep(10);
		end;
	end;
    LeaveCriticalSection(myLoggerCS);
end;

function TLogger.fileName: string;
begin
    Result:= myLogFileName;
end;

function TLogger.fileName(_fname: string): string;
begin
    myLogFileName:=_fname;
end;

procedure TLogger.setnumberOfBackups(const _numberOfBackups: word);
begin
    if mynumberOfBackups = _numberOfBackups then
        Exit;
    mynumberOfBackups := _numberOfBackups;
end;

constructor TLogger.Create(const _logfile: string; _enabled: boolean;
    _clearonstart: boolean);
var
    file_exists: boolean;
    logfile: Text;
begin
    inherited Create;
    myLogstr := '';
    myLogWrite := '';
    mylastWriteTime := 0;
    myLogFileName := _logfile;
    logEnabled := _enabled;
    clearOnStart := _clearonstart;

    //{Make sure the file exists}
    //AssignFile(logfile, myLogFileName);
    //try
    //      {$I-}
    //    Reset(logfile);{Open for reading}
    //    file_exists := (IOResult = 0);
    //    // Check if the logfile exists by looking at the IOResult
    //      {$I+}
    //
    //    if (not file_exists) or clearOnStart then
    //        ReWrite(logfile); {create a new empty file}
    //finally
    //    CloseFile(logfile);
    //end;

    if not FileExists(_logFile) or clearOnStart then
    begin
        try
            ForceDirectories(ExtractFileDir(_logFile));
            AssignFile(logfile, myLogFileName);
            ReWrite(logfile); {create a new empty file}
		finally
            CloseFile(logfile);
		end;
	end;

end;

destructor TLogger.Destroy;
begin
    {case that the APP is shutting down but
    a write may still be in progress because the the thread
    is waiting for the file lock to be released before writing.}
    Sleep(200);
    inherited Destroy;
end;

function TLogger.shouldWrite(): boolean;
const
    TIME_LIMIT = 200;
begin
    // Result := TIME_LIMIT <= (GetTickCount64 - mylastWriteTime);
    Result := False; // disable this threaded log feature
end;


function TLogger.log(const _logstring: string): integer;
begin

    Result := 1;
    // This logs a string into the log file.
    if myLogEnabled then
    begin
        writeToLog(fileName(), Format('%s:: %s', [FormatDateTime('hh:nn:ss:zzz', Now), _logstring]));
        //{$ELSE}
        //   TThreadFileWriter.add(myLogFileName, Format('%s:: %s', [FormatDateTime('hh:nn:ss:zzz', Now), _logstring]) + sLineBreak);
        //{$ENDIF}
    end;
end;

function TLogger.Clear: boolean;
begin
    {Empty the file}
    raise Exception.Create('Function not implemented');
end;

function TLogger.backup: boolean;
begin
    {Create a backup of the file}
    raise Exception.Create('Function not implemented');
end;

function TLogger.wipeAll: integer;
begin
    {Remove all backups of the file}
    raise Exception.Create('Function not implemented');
end;

initialization
    InitCriticalSection(myLoggerCS);
finalization
    freeLog;
    DoneCriticalSection(myLoggerCS);

end.

