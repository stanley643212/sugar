unit sugar.sqlitehelper;

{Reusable myDB Module for SQLite}
{Author: Stanley Stephen}
{stanley.stephen@gmail.com}
{-- July 2021}



{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Dialogs,
    SQLDBLib, SQLDB, sqlite3dyn, SQLite3Conn, fpjson,
    fgl;

const
    DEFAULT_DB_FILE = 'myDB.db';
    SEQUENCE_TABLE = '_seq';

    MIN_SQLITE_BIG_INT = -9223372036854775808;
    NUM_FLAGS = 100;
    {The number of values we want to use as flags that should not be used as ID values}

    {Default ID starts from this value }
    ID_START = MIN_SQLITE_BIG_INT + NUM_FLAGS;

    {FLAGS to denote SQL search status etc}
    ID_NOT_ASSIGNED = MIN_SQLITE_BIG_INT;
    ID_NOT_FOUND    = MIN_SQLITE_BIG_INT + 1;

type

    { TSQLiteDBModule }
    TScriptFunc = function: string;
    TScriptMethod = function: string of object;

    TDBOpenState = (
        dbopenForbidden,// Could not open the DB
        dbopenLocked,
        // Could not open because it has been locked by another process
        dbopenReadOnly,
        // Open the DB in Read only mode. This is good if it is already open with dbopenShared
        dbopenShared,
        // Open the DB in Write mode but allow other connections to read
        dbopenExclusive // Open the DB in exclusive mode. Do not allow reads
        );

    TDBStoreType = (
        dstFile,
        dtsMemory
        );

    { TSQLiteDBModuleList }

    TSQLiteDBModule = class(TDataModule)
        libloader: TSQLDBLibraryLoader;
        myDB: TSQLite3Connection;
        transaction: TSQLTransaction;
        qUpdateID: TSQLQuery;
        qGetNewID: TSQLQuery;
        procedure DataModuleCreate(Sender: TObject);
    private
        FDbFile: string;
        FDbFolder: string;
        myinitScriptFunc: TScriptFunc;
        myupgradeScript: TScriptFunc;
        myuseSequences: boolean;
        myDbOpenState: TDBOpenState;
        myDBStoreType: TDbStoreType;
        procedure SetDbFile(const _DbFile: string);
        procedure SetDbFolder(const _DbFolder: string);
        procedure SetinitScriptFunc(const _value: TScriptFunc);
        procedure SetupgradeScript(const _value: TScriptFunc);
        procedure setuseSequences(const _useSequences: boolean);
    public
        constructor Create; overload;// So that we can use this with hash lists;
        destructor Destroy; override;

        {Creates the db file if it doesn't exist}
        function getSQLite3LibraryPath(): string;
        function getDBFileName(): string;

        // FileDB
        function openDB(_dbFile: string; _dbFolder: string = '';
            _openState: TDBOpenState = dbopenExclusive): boolean;

        // Uses the current database confifguration values to initialize the db file.
        // call OpenDB() to use custom values;
        function initDB(_openState: TDBOpenState = dbopenExclusive): boolean;

        //Memory only DB
        function openMemDB(_dbFile: string;
            _openState: TDBOpenState = dbopenExclusive): boolean;
        function initMemDB(_openState: TDBOpenState = dbopenExclusive): boolean;

        procedure doUpgradeDB;
        function dropDB: boolean;
        procedure makeDatabase;

        function runScript(_script: string; _terminator: string = ''): boolean;

        function DB: TSQLConnection;
        function isTransactionActive: boolean;

        {starts a transaction. If a previous transaction is active, it sleeps and tries again.}
        function startTransaction: boolean;
        {starts a transaction only when no transaction is active}
        function safeStartTransaction: boolean;
        function commit: boolean;
        {Commits but does not close the transaction. You can do more commits to the same transaction}
        function commitRetaining: boolean;
        function rollback: boolean;
        function rollbackRetaining: boolean;
        function endTransaction: boolean;
        function newQuery: TSQLQuery; overload;
        function newQuery(_sql: string): TSQLQuery; overload;
        function newScript(const _terminator : char = ';'): TSQLScript; overload;
        function newScript(_sql: string; const _terminator : char = ';'): TSQLScript; overload;

        {Returns pointer to DB, sets it to active if not already}
        function DbActive: TSQLConnection;
        function newIDFor(_tableName: string): int64;

        function getSequenceTableCreateScript: string; virtual;
        function getSequenceUpsertScript: string; virtual;
        function getSequenceSelectScript: string; virtual;

        function getDBInitScript: string; virtual;
        function getDBUpgradeScript: string; virtual;

        {These set of functions check if records exist where a column has a particular value}
        function qExists(_tbl: string; _key: string): TSQLQuery;
        function exists(_tbl: string; _key: string; _value: string): boolean; overload;
        function exists(_tbl: string; _key: string; _value: int64): boolean; overload;
        function exists(_tbl: string; _key: string; _value: boolean): boolean; overload;
        function exists(_tbl: string; _key: string; _value: double): boolean; overload;
        function exists(_tbl: string; _where: string): boolean;

        {Update a value in a table}
        function qPut(_tbl: string; _id: int64; _fld: string;
            _idFieldName: string = 'rid'): TSQLQuery;
        function put(_tbl: string; _id: int64; _fld: string; _value: string): boolean; overload;
        function put(_tbl: string; _id: int64; _fld: string; _value: int64): boolean; overload;
        function put(_tbl: string; _id: int64; _fld: string; _value: boolean): boolean; overload;
        function put(_tbl: string; _id: int64; _fld: string; _value: double): boolean; overload;
        {Send multiple values as a json object. Parses the object, updates the table}
        function put(_tbl: string; _id: int64; _json: TJSONObject): boolean; overload;

        function qDelete(_tbl: string; _id: int64; _idFieldName: string = 'rid'): TSQLQuery;
        function Delete(_tbl: string; _id: int64): boolean;

        {Reads a value from a table}
        function qselect(_tbl: string; _id: int64; _fld: string;
            _idFieldName: string = 'rid'): TSQLQuery;
        function select_str(_tbl: string; _id: int64; _fld: string): string;
        function select_int(_tbl: string; _id: int64; _fld: string): int64;
        function select_bool(_tbl: string; _id: int64; _fld: string): boolean;
        function select_real(_tbl: string; _id: int64; _fld: string): double;

        {Returns the last inserted id by calling select last_insert_rowid();}
        function getSQLiteLastID(): int64;

        // function execSQL(_sql: string): integer; //
        // Executes a fully formed SQL statement (not select)
        // Returns an integer:
        //        0: Could not initialize or start
        //        1: Successful
        //       -1: There was an exception
        // Additionally, the out parameter _err contains the exception text.
        function execSQL(_sql: string; out _err: string): integer; overload;
        function execSQL(_sql: string): integer; overload;
        function execSQL(var _qry: TSQLQuery; out _err: string): integer;
            overload; // Does not free _qry
        function execSQL(var _qry: TSQLQuery): integer; overload; // Does not free _qry

    public
    type

        { TDBStore }

        TDBStore = class
        protected
            tbl: string;
            dm: TSQLiteDBModule;
            function getTableCreateScript(_kvTable: string): string; virtual;
            function noInitException: Exception; virtual;
        public
            // Returns the exception message that is raised when the DBStore is not initialized;
            function noInitExceptionMsg: string; virtual;
            constructor Create(_tbl: string; _dm: TSQLiteDBModule); virtual;
            function makeTable(_tbl: string): integer; virtual;

            function exists(_key: string): boolean;
            function findKeysFor(_val: string; _limit: integer = 0): TStringArray; virtual;
            function findFirstKeyFor(_val: string): string; virtual;
            function renKey(_oldKey: string; _newKey: string): integer; virtual;
            function del(_key: string): integer; virtual;
            function deleteStore: integer; virtual;
            function Clear: integer; virtual;

        end;

        { TDBKeyValueStore }
        { FIELDS
            k char(256)
            v text
        }
        TDBKeyValueStore = class(TDBStore)
        protected
            function getTableCreateScript(_kvTable: string): string; override;
        public
            constructor Create(_tbl: string; _dm: TSQLiteDBModule); override;
            function get(_key: string): string;
            function put(_key: string; _val: string): integer; // Return -2 if tbl is empty

            function findKeysFor(_val: string; _limit: integer = 0): TStringArray; override;
            function findFirstKeyFor(_val: string): string; override;
        end;


        { TDBKJSONStore }
        { FIELDS
            k char(256)
            v text
        }
        TDBKJSONStore = class(TDBStore)
        protected
            function getTableCreateScript(_kvTable: string): string; override;
        public
            constructor Create(_tbl: string; _dm: TSQLiteDBModule); override;
            function get(_key: string): string;
            function put(_key: string; _val: string): integer; // Return -2 if tbl is empty

            {Find for complete JSON Doc}
            function findKeysFor(_val: TJSONData): TStringArray; reintroduce;
            function findFirstKeyFor(_val: TJSONData): string; reintroduce;

            { Find for path/value }
            function findKeysFor(_path: string; _val: TJSONData): TStringArray; overload;
            function findFirstKeyFor(_path: string; _val: TJSONData): string; overload;

        end;

    public
        //KV Tables
        function kv(_tbl: string): TSQLiteDBModule.TDBKeyValueStore;
    public
        property DbFile: string read FDbFile write SetDbFile;
        property DbFolder: string read FDbFolder write SetDbFolder;
        property useSequences: boolean read myuseSequences write setuseSequences;
        property initScriptFunc: TScriptFunc read myinitScriptFunc write SetinitScriptFunc;
        property upgradeScript: TScriptFunc read myupgradeScript write SetupgradeScript;
        property openMode: TDBOpenState read myDbOpenState;
    end;

{ function sqliteDB(): V2
    This function instantiates a TDBModule object with the parameters supplied, ready for use.
    Internally, this unit maintains a hash list of the instantiated TDBModules and returns the object
    referred to by _dbFile (name). This way you can connect to multiple SQLite DB files by just calling
    DbModule(_file).

    NOTE: _dbFile parameter has a default value. So calling the function without any parameters
    returns an object that is instantiated to use a efault DB file in the folder where the exe is stored.
}
function sqliteDB(const _dbFile: string = DEFAULT_DB_FILE;
    const _dbFolder: string = '';
    constref _initScriptFunc: TScriptFunc = nil;
    constref _upgradeScriptFunc: TScriptFunc = nil;
    const _openState: TDBOpenState = dbopenExclusive): TSQLiteDBModule;

function sqliteMemDB(const _dbfile: string; // alias
    constref _initScriptFunc: TScriptFunc = nil;
    constref _upgradeScriptFunc: TScriptFunc = nil): TSQLiteDBModule;


function sqliteDBFree(const _dbFile: string): boolean;

function genInsertSQL(const _table: string; _fieldList: TStringArray; const _conflictFields: TStringArray; _onConflictDo: string = 'NOTHING'): string;
function genSelectSQL(const _table: string; _data: TJSONObject; _key : string; _ignore: array of string): string;

function prepInsertQuery(constref _qry: TSQLQuery;
                const _table: string;
                const _fieldList: TStringArray;
                constref _data: TJSONObject;
                const _conflictFields: TStringArray;
                _onConflictDo: string = 'NOTHING'): TSQLQuery;


implementation

{$R *.lfm}

uses
    sugar.utils, sugar.logger, sugar.collections;

type
    TDBModuleListBase = specialize GenericHashObjectList<TSQLiteDBModule>;

    TDBModuleList = class(TDBModuleListBase)

    end;

var
    myDBModules: TDBModuleList;

function newSqliteDB(_dbFile: string; _dbFolder: string;
    _initScriptFunc: TScriptFunc; _upgradeScriptFunc: TScriptFunc): TSQLiteDBModule;
begin
    Result := TSQLiteDBModule.Create(nil);
    Result.DbFile   := _dbFile;

    ForceDirectories(_dbFolder);
    Result.DbFolder := _dbFolder;

    Result.initScriptFunc := _initScriptFunc;
    Result.upgradeScript := _upgradeScriptFunc;
end;

function sqliteDB(const _dbFile: string; const _dbFolder: string; constref
	_initScriptFunc: TScriptFunc; constref _upgradeScriptFunc: TScriptFunc;
	const _openState: TDBOpenState): TSQLiteDBModule;
begin
    Result := myDBModules.find(_dbFile);
    if not Assigned(Result) then
    begin
        Result := newSqliteDB(_dbFile, _dbFolder, _initScriptFunc, _upgradeScriptFunc);
        Result.initDB(_openState);
        myDBModules.add(_dbfile, Result);
    end;

    if Result.openMode < dbopenReadOnly then
        raise Exception.Create('It looks like Database "%s" could not be opened. Please check ');

end;

function sqliteMemDB(const _dbfile: string; constref _initScriptFunc: TScriptFunc;
    constref _upgradeScriptFunc: TScriptFunc): TSQLiteDBModule;
begin
    Result := myDBModules.find(_dbFile);
    if not assigned(Result) then
    begin
        Result := TSQLiteDBModule.Create(nil);
        Result.DbFolder := '';
        Result.initScriptFunc := _initScriptFunc;
        Result.upgradeScript := _upgradeScriptFunc;
        if Result.openMemDB(_dbFile) then myDBModules.Add(_dbFile, Result)
        else
        begin
            Result.Free;
            raise Exception.Create(Format('sqliteMemDB:: memDB for "%s" failed.',
                [_dbFile]));
        end;
    end;
end;

function sqliteDBFree(const _dbFile: string): boolean;
begin
    Result := myDBModules.Delete(_dbFile);
end;

function genInsertSQL(const _table: string; _fieldList: TStringArray;
	const _conflictFields: TStringArray; _onConflictDo: string): string;
const
    __insertTemplate = 'INSERT INTO %0:s (%1:s) VALUES (%2:s) %3:s';
    __onConflictTemplate = 'ON CONFLICT (%s) DO %s';
var
    _fields, _params, _onConflict, _name: string;
	i: Integer;
    _addComma : boolean = false;
	_genOnConflictUpdate: Boolean = false;

begin
    if _table = '' then raise Exception.Create('genInsertChangesSQL:: table name is required.');
    if length(_conflictFields) > 0 then begin
        if _onConflictDo = '' then raise Exception.Create('genInsertChangesSQL:: ON CONFLICT DO must be specified when conflict fields are given');
        case _onConflictDo of
            'UPDATE' : begin
                _genOnConflictUpdate := true;
                _onConflictDo := 'UPDATE SET ';
			end
			else _onConflict := Format(__onConflictTemplate, [getDelimitedString(_conflictFields), _onConflictDo]);
        end;

	end
    else
        _onConflict := '';

    Result  := '';
    _fields := '';
    _params := '';

    for _name in _fieldList do begin
        if _addComma then begin
            _fields := _fields + ', ';
            _params := _params + ', ';
            if _genOnConflictUpdate then
                _onConflictDo := _onConflictDo + ', ';
		end
        else
            _addComma := true;

        _fields := _fields + _name;
        _params := _params + ':' + _name;
        if _genOnConflictUpdate then begin
            _onConflictDo := _onConflictDo + _name + ' = excluded.' + _name;
        end;
	end;

    if _genOnConflictUpdate then
        _onConflict := Format(__onConflictTemplate, [getDelimitedString(_conflictFields), _onConflictDo]);
    Result := Format(__insertTemplate, [_table, _fields, _params, _onConflict]);

end;

function genSelectSQL(const _table: string; _data: TJSONObject; _key: string;
	_ignore: array of string): string;
const
    Q = 'SELECT %s FROM %s ';
    W = 'WHERE %s';
var
    _fields: string = '';
    _addComma: boolean = false;
    _ignoreIndex: TJSONObject;
	ig, _field: String;
    i: integer;

    function shouldIgnore(_f: string): boolean;
    begin
        Result := _ignoreIndex.IndexOfName(lowercase(_f)) <> -1;
	end;

begin
    _ignoreIndex := TJSONObject.Create();
    try
        // Prepare _ignore index
	    for ig in _ignore do
            _ignoreIndex.strings[lowercase(ig)] := ig;

	    for i := 0 to pred (_data.count) do begin
	        _field := _data.Names[i];
            if shouldIgnore(_field) then continue;
            if _addComma then
                _fields := _fields + ', '
            else
                _addComma := true;
            _fields := _fields + _field;
		end;

	finally
        _ignoreIndex.Free;
	end;

    Result := Format(Q, [_fields, _table]);

    if _key <> '' then
        Result := Result + Format(W, [_key]);
end;

function prepInsertQuery(constref _qry: TSQLQuery; const _table: string; const _fieldList: TStringArray;
	constref _data: TJSONObject; const _conflictFields: TStringArray;
	_onConflictDo: string): TSQLQuery;
var
	i: Integer;
	_field: String;
	_dataObj: TJSONData;
begin
    if not assigned(_qry) then raise Exception.Create('prepInsertQuery:: query object is nil');
    _qry.SQL.Text:= genInsertSQL(_table, _fieldList, _conflictFields, _onConflictDo);
    i := 0;
    for _field in _fieldList do begin
        _dataObj := _data.Find(_field);
        if not assigned(_dataObj) then
            _qry.Params[i].Clear
        else case _dataObj.JSONType of
        	jtUnknown:  _qry.Params[i].Clear;
            jtNumber:   _qry.Params[i].AsLargeInt:= _dataObj.AsInt64;
            jtString:   _qry.Params[i].AsString:= _dataObj.AsString;
            jtBoolean:  _qry.Params[i].AsBoolean:= _dataObj.AsBoolean;
            jtNull:     _qry.Params[i].Clear;
            jtArray:    _qry.Params[i].AsString := _dataObj.AsJSON;
            jtObject:   _qry.Params[i].AsString := _dataObj.AsJSON;
        end;
        inc(i);
	end;
    Result := _qry;
end;

{ TSQLiteDBModule.TDBKJSONStore }

function TSQLiteDBModule.TDBKJSONStore.getTableCreateScript(_kvTable: string): string;
begin

end;

constructor TSQLiteDBModule.TDBKJSONStore.Create(_tbl: string; _dm: TSQLiteDBModule);
begin
    inherited Create(_tbl, _dm);
end;

function TSQLiteDBModule.TDBKJSONStore.get(_key: string): string;
begin

end;

function TSQLiteDBModule.TDBKJSONStore.put(_key: string; _val: string): integer;
begin

end;

function TSQLiteDBModule.TDBKJSONStore.findKeysFor(_val: TJSONData): TStringArray;
begin

end;

function TSQLiteDBModule.TDBKJSONStore.findFirstKeyFor(_val: TJSONData): string;
begin

end;

function TSQLiteDBModule.TDBKJSONStore.findKeysFor(_path: string;
    _val: TJSONData): TStringArray;
begin

end;

function TSQLiteDBModule.TDBKJSONStore.findFirstKeyFor(_path: string;
    _val: TJSONData): string;
begin

end;

{ TSQLiteDBModule.TDBStore }

function TSQLiteDBModule.TDBStore.getTableCreateScript(_kvTable: string): string;
begin
    Result := '';
end;

function TSQLiteDBModule.TDBStore.noInitException: Exception;
begin
    Result := Exception.Create(noInitExceptionMsg());
end;

function TSQLiteDBModule.TDBStore.noInitExceptionMsg: string;
begin
    Result := ClassName + ' is not initialized';
end;

constructor TSQLiteDBModule.TDBStore.Create(_tbl: string; _dm: TSQLiteDBModule);
begin
    inherited Create;
    dm := _dm;
    if not _tbl.IsEmpty then makeTable(_tbl);
end;

function TSQLiteDBModule.TDBStore.makeTable(_tbl: string): integer;
begin
    Result := dm.execSQL(getTableCreateScript(_tbl));
    case Result of
        -1, 0: tbl := '';
        1    : tbl := _tbl;
    end;
end;

function TSQLiteDBModule.TDBStore.exists(_key: string): boolean;
begin
    if tbl.isEmpty then
    begin
        Result := False;
        raise noInitException;
    end;
    Result := dm.Exists(tbl, format('k = "%s"', [_key]));
end;

function TSQLiteDBModule.TDBStore.findKeysFor(_val: string;
    _limit: integer): TStringArray;
begin
    Result := [];
end;

function TSQLiteDBModule.TDBStore.findFirstKeyFor(_val: string): string;
begin
    Result := '';
end;

function TSQLiteDBModule.TDBStore.renKey(_oldKey: string; _newKey: string): integer;
const
    Q = 'UPDATE %0:s SET k = :newkey WHERE k= :oldkey; ';
var
    _qry: TSQLQuery;
begin
    if tbl.isEmpty then
    begin
        Result := -2;
        raise noInitException;
    end;

    Result := 0;
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl]);
        _qry.params[0].AsString := _newKey;
        _qry.params[1].AsString := _oldKey;
        Result := dm.execSQL(_qry);
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.TDBStore.del(_key: string): integer;
const
    Q = 'DELETE FROM %0:s WHERE k= :key;';
var
    _qry: TSQLQuery;
begin
    if tbl.isEmpty then
    begin
        Result := -2;
        raise noInitException;
    end;

    Result := 0;
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl]);
        _qry.Params[0].AsString := _key;
        Result := dm.execSQL(_qry);
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.TDBStore.deleteStore: integer;
const
    Q = 'DROP TABLE IF EXISTS %0:s;';
var
    _qry: TSQLQuery;
begin
    if tbl.isEmpty then
    begin
        Result := -2;
        raise noInitException;
    end;
    Result := 0;
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl]);
        Result := dm.execSQL(_qry);
        tbl := '';
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.TDBStore.Clear: integer;
const
    Q = 'DELETE FROM %0:s;';
var
    _qry: TSQLQuery;
begin
    if tbl.isEmpty then
    begin
        Result := -2;
        raise noInitException;
    end;

    Result := 0;
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl]);
        Result := dm.execSQL(_qry);
        tbl := '';
    finally
        _qry.Free;
    end;
end;

{ TSQLiteDBModule.TDBKeyValueStore }



function TSQLiteDBModule.TDBKeyValueStore.getTableCreateScript(_kvTable: string): string;
const
    Q = 'CREATE TABLE IF NOT EXISTS %0:s ( ' + sLinebreak +
        '	 k char(256) primary key,' + sLinebreak + '	 v text ' +
        sLinebreak + ');' + sLinebreak + ' ' + sLinebreak +
        'CREATE INDEX IF NOT EXISTS %0:s_v ON %0:s (v);' + sLinebreak;
begin
    Result := Format(Q, [_kvTable]);
end;


constructor TSQLiteDBModule.TDBKeyValueStore.Create(_tbl: string; _dm: TSQLiteDBModule);
begin
    inherited Create(_tbl, _dm);
end;

function TSQLiteDBModule.TDBKeyValueStore.get(_key: string): string;
const
    Q = 'SELECT v from %s WHERE k = "%s"';
var
    _qry: TSQLQuery;
begin
    if tbl.IsEmpty then
    begin
        Result := 'Empty';
        raise noInitException;
    end;
    Result := '';
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl, _key]);
        _qry.Open;
        _qry.First;
        if not _qry.Fields[0].IsNull then
            Result := _qry.Fields[0].AsString;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.TDBKeyValueStore.put(_key: string; _val: string): integer;
const
    Q = 'INSERT INTO %0:s (k,v) VALUES (:k, :v) ON CONFLICT (k) DO UPDATE SET v = excluded.v WHERE k=excluded.k;';
var
    _qry: TSQLQuery;
begin
    if tbl.IsEmpty then
    begin
        Result := -2;
        raise noInitException;
    end;

    Result := 0;
    _qry := dm.newQuery();
    try
        _qry.SQL.Text := Format(Q, [tbl]);
        _qry.ParamByName('k').AsString := _key;
        _qry.ParamByName('v').AsString := _val;
        Result := dm.execSQL(_qry);
    finally
        _qry.Free;
    end;
end;



function TSQLiteDBModule.TDBKeyValueStore.findKeysFor(_val: string;
    _limit: integer): TStringArray;
const
    Q = 'SELECT k from %s WHERE v = :val ORDER BY K ASC %s';
var
    _qry: TSQLQuery;
    _i: integer;
    _result: string = '';
    _comma: string = '';
    _addComma: boolean = False;
    _limStr: string = '';
begin
    if tbl.isEmpty then
    begin
        SetLength(Result, 0);
        raise noInitException;
    end;


    _qry := dm.newQuery();
    try
        if _limit > 0 then _limStr := Format(' LIMIT %d ', [_limit]);

        _qry.SQL.Text := Format(Q, [tbl, _limStr]);
        _qry.Params[0].AsString := _val;
        _qry.Open;

        SetLength(Result, _qry.RowsAffected);

        _qry.First;
        _i := 0;

        while not _qry.EOF do
        begin
            if not _qry.Fields[0].IsNull then
            begin
                _result := _result + _comma + _qry.Fields[0].AsString;
                Inc(_i);
            end;
            _qry.Next;

            if not _addComma then
            begin
                _comma := ',';
                _addComma := True;
            end;
        end;

        Result := _result.split(_comma);
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.TDBKeyValueStore.findFirstKeyFor(_val: string): string;
var
    _keys: TStringArray;
begin
    Result := '';
    _keys := findKeysFor(_val, 1);
    if Length(_keys) > 0 then Result := _keys[0];
end;


{ TSQLiteDBModule }

procedure TSQLiteDBModule.DataModuleCreate(Sender: TObject);
begin
    {$IFDEF WINDOWS}
    libLoader.ConnectionType := 'SQLite3';
    libLoader.LibraryName := getSQLite3LibraryPath();
    libLoader.Enabled := True;
    {$ENDIF}

    {$IF defined(UNIX)}
    {TODO}
    libLoader.ConnectionType := 'SQLite3';
    libLoader.LibraryName := getSQLite3LibraryPath();
    libLoader.Enabled := True;
    {$ENDIF}

    {$IF defined(DARWIN)}
    {TODO}
    libLoader.ConnectionType := 'SQLite3';
    libLoader.LibraryName := getSQLite3LibraryPath();
    libLoader.Enabled := True;
    {$ENDIF}

    useSequences := True;
    qUpdateID.SQL.Text := getSequenceUpsertScript();
    qGetNewID.SQL.Text := getSequenceSelectScript();
    myDbOpenState := dbopenExclusive;
end;

procedure TSQLiteDBModule.SetDbFile(const _DbFile: string);
begin
    if FDbFile = _DbFile then    Exit;
    if not DB.Connected then
        FDbFile := _DbFile
    else
        raise Exception.Create(Format(
            'Database "%s" is currently open. You change DbFile value after the connection is closed.',
            [getDBFileName()]));
end;

procedure TSQLiteDBModule.SetDbFolder(const _DbFolder: string);
begin
    if FDbFolder = _DbFolder then Exit;
    if not DB.Connected then
        FDbFolder := _DbFolder
    else
        raise Exception.Create(Format(
            'Database "%s" is currently open. You change DbFolder value after the connection is closed.',
            [getDBFileName()]));
end;

function TSQLiteDBModule.getSQLite3LibraryPath(): string;
begin
    {$IFDEF windows}
    Result := ExpandFileName(sqlite3dyn.SQLiteDefaultLibrary);
    {$ELSE}

    {$ELSEIFDEF UNIX}
    Result := ExpandFileName(sqlite3dyn.SQLiteDefaultLibrary);
    if not fileExists(Result) then
        Result := sqlite3dyn.SQLiteDefaultLibrary;
    {$ELSEIFDEF DARWIN}

    {$ENDIF}

end;

function TSQLiteDBModule.getDBFileName(): string;
begin
    if DbFile.IsEmpty then DbFile := DEFAULT_DB_FILE;
    if DbFolder.IsEmpty then DbFolder := ExpandFileName('');
    Result := appendPath([dbFolder, DbFile]);
end;

procedure TSQLiteDBModule.SetinitScriptFunc(const _value: TScriptFunc);
begin
    if myinitScriptFunc = _value then Exit;
    myinitScriptFunc := _value;
end;

procedure TSQLiteDBModule.SetupgradeScript(const _value: TScriptFunc);
begin
    if myupgradeScript = _value then Exit;
    myupgradeScript := _value;
end;

procedure TSQLiteDBModule.setuseSequences(const _useSequences: boolean);
begin
    if myuseSequences = _useSequences then Exit;
    myuseSequences := _useSequences;
end;

constructor TSQLiteDBModule.Create;
begin
    Create(nil);
end;

destructor TSQLiteDBModule.Destroy;
begin
    if isTransactionActive then begin
        try
            commit;
		except
            rollback;
		end;
		endTransaction;
	end;
	inherited Destroy;
end;

function TSQLiteDBModule.initDB(_openState: TDBOpenState): boolean;
var
    _DBInitScript: string;

    function isExclusive(_db: TSQLConnection): boolean;
    const
        Q = 'PRAGMA locking_mode';
        _EXCLUSIVE = 'exclusive';
    var
        _qry: TSQLQuery;
    begin
        _qry := newQuery;
        try
            _qry.SQL.Text := Q;
            _qry.Open;
            _qry.First;
            if not _qry.Fields[0].IsNull then
                Result := lowercase(_qry.Fields[0].AsString) = _EXCLUSIVE
            else
                Result := True; // assume exclusive because cannot open
        finally
            _qry.Free;
        end;
    end;

    procedure openReadOnly;
    begin
        if startTransaction then
        begin
            (*
              These settings allow the SQLite3 database to finish writing faster.
              See https://www.sqlite.org/pragma.html#pragma_synchronous
              Stanley.
              *)

            {This is necessary workaround. https://wiki.freepascal.org/SQLite search for "Pragma and Vacuum" }
            myDB.ExecuteDirect('END TRANSACTION;');

            {Allow OS to handle writing. Simplifies commit}
            myDB.ExecuteDirect('PRAGMA query_only = 1;');

            {Exclusive File lock}
            myDB.ExecuteDirect('PRAGMA locking_mode = ''NORMAL'';');

            {Write Ahead //Log}
            myDB.ExecuteDirect('PRAGMA journal_mode = ''WAL'';');

           {Busy timeout}
            myDB.ExecuteDirect('PRAGMA busy_timeout = 5000;');

            {Lazarus workaround for executing PRAGMA. Done.}
            myDB.ExecuteDirect('BEGIN TRANSACTION;');
            endTransaction;
        end;
    end;

    procedure openShared;
    begin
        if startTransaction then
        begin
                     (*
            These settings allow the SQLite3 database to finish writing faster.
            See https://www.sqlite.org/pragma.html#pragma_synchronous
            Stanley.
            *)

            {This is necessary workaround. https://wiki.freepascal.org/SQLite search for "Pragma and Vacuum" }
            myDB.ExecuteDirect('END TRANSACTION;');

            {Allow OS to handle writing. Simplifies commit}
            myDB.ExecuteDirect('PRAGMA synchronous = 1;');

            {Exclusive File lock}
            myDB.ExecuteDirect('PRAGMA locking_mode = ''NORMAL'';');

            {Write Ahead //Log}
            myDB.ExecuteDirect('PRAGMA journal_mode = ''WAL'';');

            {Busy timeout}
            myDB.ExecuteDirect('PRAGMA busy_timeout = 5000;');


            {Lazarus workaround for executing PRAGMA. Done.}
            myDB.ExecuteDirect('BEGIN TRANSACTION;');

            endTransaction;

            doUpgradeDB;
        end;

    end;

    procedure openExclusive;
    begin
        if startTransaction then
        begin
                     (*
            These settings allow the SQLite3 database to finish writing faster.
            See https://www.sqlite.org/pragma.html#pragma_synchronous
            Stanley.
            *)

            {This is necessary workaround. https://wiki.freepascal.org/SQLite search for "Pragma and Vacuum" }
            myDB.ExecuteDirect('END TRANSACTION;');

            {Allow OS to handle writing. Simplifies commit}
            myDB.ExecuteDirect('PRAGMA synchronous = 1;');

            {Exclusive File lock}
            myDB.ExecuteDirect('PRAGMA locking_mode = ''EXCLUSIVE'';');

            {Write Ahead //Log}
            myDB.ExecuteDirect('PRAGMA journal_mode = ''WAL'';');


            myDB.ExecuteDirect('BEGIN TRANSACTION;');
            {Lazarus workaround for executing PRAGMA. Done.}
            endTransaction;
            doUpgradeDB;
        end;
    end;

begin

    Result := True;
    myDbOpenState := _openState;

    if myDB.Connected then myDB.Connected := False;

    myDB.DatabaseName := getDBFileName();        {Gets the file name that was set}

    { Does the DB File exist? }
    if not fileExists(myDB.DatabaseName) then
    begin
        { Make the DB File }
        myDB.CreateDB;
        _DBInitScript := getDBInitScript();
        if not _DBInitScript.isEmpty then
            Result := runScript(_DBInitScript);
    end;

    { Connect to the DB }
    if Result then
    begin
        try
            DbActive;
        except
            if isExclusive(myDB) then
                myDbOpenState := dbopenLocked // The database is locked so we cannot open it
            //else
            //    myDbOpenState := dbopenForbidden;
        end;

        case myDbOpenState of
            dbopenForbidden : ;
            dbopenLocked    : ;
            dbopenReadOnly  : openReadOnly;
            dbopenShared    : openShared;
            dbopenExclusive : openExclusive;
        end;
    end;
end;

function TSQLiteDBModule.openMemDB(_dbFile: string; _openState: TDBOpenState): boolean;
begin
    {This section is duplicated in OpenDB()}
    DbFile := _dbFile;
    DbFolder := '';

    if isTransactionActive then
    begin
        myDB.EndTransaction;
        myDB.CloseDataSets;
    end;
    {duplicate end}
    Result := initMemDB(_openState);
end;

function TSQLiteDBModule.initMemDB(_openState: TDBOpenState): boolean;
var
    _DBInitScript: string;
begin
    Result := False;
    myDbOpenState := _openState;
    if myDB.Connected then myDB.Connected := False;
    with myDB do
    begin
        OpenFlags := [sofReadWrite, sofCreate, sofURI];
        DatabaseName := format('file:%s?mode=memory', [DbFile]);
    end;

    _DBInitScript := getDBInitScript();

    if not _DBInitScript.isEmpty then
        Result := runScript(_DBInitScript);

end;

procedure TSQLiteDBModule.doUpgradeDB;
begin

end;

function TSQLiteDBModule.dropDB: boolean;
begin
    if DB.Connected then
    begin
        if isTransactionActive then
            endTransaction;
        DB.Close();
    end;
    Result := DeleteFile(getDBFileName());
end;

procedure TSQLiteDBModule.makeDatabase;
var
    _shouldInitDB: boolean = True;
    mr: TModalResult;
begin
    if FileExists(getDBFileName()) then
        //mr := MessageDlg('Question', 'Do you want to delete the existing DB file?',
        //     mtConfirmation, [mbYes, mbNo], 0);
        //if mr = mrYes then
        //     _shouldInitDB := dropDB
        //else
        //     _shouldInitDB := False;
    ;

    if _shouldInitDB then
        initDB;
end;

function TSQLiteDBModule.openDB(_dbFile: string; _dbFolder: string;
    _openState: TDBOpenState): boolean;
begin
    DbFile := _dbFile;
    DbFolder := _dbFolder;
    if isTransactionActive then
    begin
        DB.EndTransaction;
        DB.CloseDataSets;
    end;

    Result := initDB(_openState);
end;

function TSQLiteDBModule.runScript(_script: string; _terminator: string
	): boolean;
var
    scripts: TSQLScript;
begin
    if _script.isEmpty then
    begin
        Result := False;
        exit;
    end;
    saveFileContent('create.sql', _script);
    scripts := TSQLScript.Create(myDB);
    scripts.DataBase := myDB;
    scripts.Transaction := transaction;

    if _terminator <> '' then begin
        scripts.Terminator  := _terminator;
        scripts.UseSetTerm  := true;
    end;

    try
        myDB.Open;
        if startTransaction then
            scripts.Script.add(_script);
        try
            try
                scripts.Execute;
                commit;
                Result := True;
            except
                on E: Exception do
                begin
                    Log('TSQLiteDBModule.runScript() Exception. %s' +
                        sLineBreak + 'SQL Script:' + sLineBreak +
                        '%s', [E.Message, _script]);
                    Result := False;
                end;
            end;
        finally
            endTransaction;
        end;
    finally
        scripts.Free;
    end;
end;

function TSQLiteDBModule.DB: TSQLConnection;
begin
    Result := myDB;
end;


function TSQLiteDBModule.isTransactionActive: boolean;
begin
    Result := myDB.Transaction.Active;
end;

function TSQLiteDBModule.startTransaction: boolean;
const
    NUM_TRIES = 3;
var
    _attempt: byte = 0;
begin
    Result := False;
    while (not Result) and (_attempt < NUM_TRIES) do
    begin
        try
            DbActive.StartTransaction;
            Result := True;
        except
            Result := False;
        end;
        if not Result then
        begin
            Inc(_attempt);
            sleep(570);
        end;
    end;
end;


function TSQLiteDBModule.safeStartTransaction: boolean;
begin
    Result := True;
    if not isTransactionActive then
        Result := startTransaction;
end;

function TSQLiteDBModule.commit: boolean;
begin
    try
        myDB.Transaction.Commit;
        Result := True;
    except
        Result := False;
    end;
end;

function TSQLiteDBModule.commitRetaining: boolean;
begin
    try
        myDB.Transaction.CommitRetaining;
        Result := True;
    except
        Result := False;
    end;

end;

function TSQLiteDBModule.rollback: boolean;
begin
    try
        myDB.Transaction.RollbackRetaining;
        Result := True;
    except
        Result := False;
    end;
end;

function TSQLiteDBModule.rollbackRetaining: boolean;
begin
    try
        myDB.Transaction.RollbackRetaining;
        Result := True;
    except
        Result := False;
    end;
end;

function TSQLiteDBModule.endTransaction: boolean;
begin
    try
        myDB.Transaction.EndTransaction;
        Result := True;
    except
        Result := False;
    end;
end;

function TSQLiteDBModule.newQuery: TSQLQuery;
begin
    Result := TSQLQuery.Create(myDB);
    Result.DataBase := TSQLConnection(myDB);
    Result.Transaction := transaction;
end;

function TSQLiteDBModule.newQuery(_sql: string): TSQLQuery;
begin
    Result := newQuery();
    Result.SQL.Text := _sql;
end;

function TSQLiteDBModule.newScript(const _terminator: char): TSQLScript;
begin
    Result := TSQLScript.Create(myDB);
    Result.DataBase := TSQLConnection(myDB);
    Result.Transaction := transaction;
    if Result.Terminator = '' then begin
        Result.Terminator  := _terminator;
        Result.UseSetTerm  := true;
	end;
end;

function TSQLiteDBModule.newScript(_sql: string; const _terminator: char
	): TSQLScript;
begin
    Result := newScript(_terminator);
    Result.Script.Text:=_sql;
end;


function TSQLiteDBModule.DbActive: TSQLConnection;
begin
    Result := Db;
    if not Result.Connected then
    try
        Result.Connected := True;
    except
        raise;
    end;
end;

function TSQLiteDBModule.newIDFor(_tableName: string): int64;
var
    _useNewTransaction: boolean;
begin

    Result := ID_NOT_ASSIGNED;
    _useNewTransaction := not isTransactionActive;

    if _useNewTransaction then
        startTransaction;

    //Log('DM0001[D]=='+_prof.time('Transaction started'));
    qUpdateID.Params[0].AsString := _tableName;
    qUpdateID.Params[1].AsLargeInt := ID_START;
    try
        try
            qUpdateID.ExecSQL;
            if _useNewTransaction then
                commitRetaining;

            qGetNewID.Params[0].AsString := _tableName;
            qGetNewID.Open;

            {There is only one columm}
            Result := qGetNewID.Fields[0].AsLargeInt;
            qGetNewID.Close;

        except
            if _useNewTransaction then
                rollback;

            raise;
        end;

    finally
        if _useNewTransaction then
            endTransaction;
    end;
end;

function TSQLiteDBModule.getSequenceTableCreateScript: string;
begin
    Result := format('CREATE TABLE IF NOT EXISTS %s (' + sLinebreak +
        '   name CHAR(127) UNIQUE,' + sLinebreak + '  curr_id BIGINT' +
        sLinebreak + ');', [SEQUENCE_TABLE]);
end;

function TSQLiteDBModule.getSequenceUpsertScript: string;
begin
    Result := format('INSERT INTO %s ' + sLinebreak + '(name, curr_id) ' +
        sLinebreak + 'VALUES (:name, :start_id) ' + sLinebreak +
        'ON CONFLICT (name) DO UPDATE ' + sLinebreak + 'set curr_id = curr_id + 1;',
        [SEQUENCE_TABLE]);

end;

function TSQLiteDBModule.getSequenceSelectScript: string;
begin
    Result := format('SELECT CAST(curr_id as BIGINT) as ID from %s WHERE name = :name',
        [SEQUENCE_TABLE]);
end;


function TSQLiteDBModule.getDBInitScript: string;
begin
    Result := getSequenceTableCreateScript() + sLineBreak;
    if assigned(myinitScriptFunc) then
        Result := Result + initScriptFunc();
end;

function TSQLiteDBModule.getDBUpgradeScript: string;
begin
    if assigned(myupgradeScript) then
        Result := myupgradeScript()
    else
        Result := '';
end;

function TSQLiteDBModule.qExists(_tbl: string; _key: string): TSQLQuery;
begin
    Result := newQuery;
    with Result do
        SQL.Text := Format('select true from %0:s WHERE %1:s = :%1:s LIMIT 1', [_tbl, _key]);
end;

function TSQLiteDBModule.exists(_tbl: string; _key: string; _value: string): boolean;
begin
    with qExists(_tbl, _key) do
    begin
        Params[0].AsString := _value;
        try
            Open;
            First;
            if not ((BOF = EOF)) then
            begin
                if Fields[0].isNull then
                    Result := False
                else
                    Result := True;
            end
            else
                Result := False;
        except
            Result := False;
        end;
        Free;
    end;
end;

function TSQLiteDBModule.exists(_tbl: string; _key: string; _value: int64): boolean;
begin
    with qExists(_tbl, _key) do
    begin
        Params[0].AsLargeInt := _value;
        try
            Open;
            First;
            if not ((BOF = EOF)) then
            begin
                if Fields[0].isNull then
                    Result := False
                else
                    Result := True;
            end
            else
                Result := False;
        except
            Result := False;
        end;
        Free;
    end;
end;

function TSQLiteDBModule.exists(_tbl: string; _key: string; _value: boolean): boolean;
begin
    with qExists(_tbl, _key) do
    begin
        Params[0].AsBoolean := _value;
        try
            Open;
            First;
            if not ((BOF = EOF)) then
            begin
                if Fields[0].isNull then
                    Result := False
                else
                    Result := True;
            end
            else
                Result := False;
        except
            Result := False;
        end;
        Free;
    end;
end;

function TSQLiteDBModule.exists(_tbl: string; _key: string; _value: double): boolean;
begin
    with qExists(_tbl, _key) do
    begin
        Params[0].AsFloat := _value;
        try
            Open;
            First;
            if not ((BOF = EOF)) then
            begin
                if Fields[0].isNull then
                    Result := False
                else
                    Result := True;
            end
            else
                Result := False;
        except
            Result := False;
        end;
        Free;
    end;
end;

function TSQLiteDBModule.exists(_tbl: string; _where: string): boolean;
begin
    with newQuery do
    begin
        SQL.Text := Format('select true from %0:s WHERE %1:s;', [_tbl, _where]);
        try
            Open;
            First;
            if not ((BOF = EOF)) then
                Result := not Fields[0].isNull
            else
                Result := False;
        except
            Result := False;
        end;
        Free;
    end;
end;

function TSQLiteDBModule.qPut(_tbl: string; _id: int64; _fld: string;
    _idFieldName: string): TSQLQuery;
begin
    Result := newQuery;
    Result.SQL.Text := format('UPDATE %0:s SET %1:s=:%1:s WHERE %2:s=:%2:s',
        [_tbl, _fld, _idFieldName]);
    Result.Params[1].AsLargeInt := _id;
end;

function TSQLiteDBModule.put(_tbl: string; _id: int64; _fld: string;
    _value: string): boolean;
var
    _qry: TSQLQuery;
begin
    _qry := qPut(_tbl, _id, _fld);
    try
        _qry.params[0].AsString := _value;
        try
            safeStartTransaction;
            _qry.ExecSQL;
            Result := True;
            commitRetaining;
        except
            rollbackRetaining;
            Result := False;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.put(_tbl: string; _id: int64; _fld: string;
    _value: int64): boolean;
var
    _qry: TSQLQuery;
begin
    _qry := qPut(_tbl, _id, _fld);
    try
        _qry.params[0].AsLargeInt := _value;
        try
            safeStartTransaction;
            _qry.ExecSQL;
            Result := True;
            commitRetaining;
        except
            rollbackRetaining;
            Result := False;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.put(_tbl: string; _id: int64; _fld: string;
    _value: boolean): boolean;
var
    _qry: TSQLQuery;
begin
    _qry := qPut(_tbl, _id, _fld);
    try
        _qry.params[0].AsBoolean := _value;
        try
            safeStartTransaction;
            _qry.ExecSQL;
            Result := True;
            commitRetaining;
        except
            rollbackRetaining;
            Result := False;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.put(_tbl: string; _id: int64; _fld: string;
    _value: double): boolean;
var
    _qry: TSQLQuery;
begin
    _qry := qPut(_tbl, _id, _fld);
    try
        _qry.params[0].AsFloat := _value;
        try
            safeStartTransaction;
            _qry.ExecSQL;
            Result := True;
            commitRetaining;
        except
            rollbackRetaining;
            Result := False;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.put(_tbl: string; _id: int64; _json: TJSONObject): boolean;
begin
    trip('Not implemented');
    Result := False;
end;

function TSQLiteDBModule.qDelete(_tbl: string; _id: int64;
    _idFieldName: string): TSQLQuery;
begin
    Result := newQuery;
    Result.SQL.Text := format('DELETE FROM %0:s WHERE %1:s=:%1:s',
        [_tbl, _idFieldName, _idFieldName]);
    Result.params[0].AsLargeInt := _id;
end;

function TSQLiteDBModule.Delete(_tbl: string; _id: int64): boolean;
var
    _qry: TSQLQuery;
begin
    _qry := qDeletE(_tbl, _id);
    try
        safeStartTransaction;
        _qry.ExecSQL;
        Result := True;
        commitRetaining;
    except
        rollbackRetaining;
        Result := False;
    end;
end;

function TSQLiteDBModule.qselect(_tbl: string; _id: int64; _fld: string;
    _idFieldName: string): TSQLQuery;
begin
    Result := newQuery;
    Result.SQL.Text := format('SELECT %s FROM %s WHERE %s=:%s LIMIT 1',
        [_fld, _tbl, _idFieldName, _idFieldName]);
    Result.params[0].AsLargeInt := _id;
end;

function TSQLiteDBModule.select_str(_tbl: string; _id: int64; _fld: string): string;
var
    _qry: TSQLQuery;
begin
    Result := '';
    _qry := qSelect(_tbl, _id, _fld);
    try
        _qry.Open;
        {while loop serves as if statement. Only one record. }
        while not _qry.EOF do
        begin
            Result := _qry.Fields[0].AsString;
            _qry.Next;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.select_int(_tbl: string; _id: int64; _fld: string): int64;
var
    _qry: TSQLQuery;
begin
    Result := 0;
    _qry := qSelect(_tbl, _id, _fld);
    try
        _qry.Open;
        {while loop serves as if statement. Only one record. }
        while not _qry.EOF do
        begin
            Result := _qry.Fields[0].AsLargeInt;
            _qry.Next;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.select_bool(_tbl: string; _id: int64; _fld: string): boolean;
var
    _qry: TSQLQuery;
begin
    Result := False;
    _qry := qSelect(_tbl, _id, _fld);
    try
        _qry.Open;
        {while loop serves as if statement. Only one record. }
        while not _qry.EOF do
        begin
            Result := _qry.Fields[0].AsBoolean;
            _qry.Next;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.select_real(_tbl: string; _id: int64; _fld: string): double;
var
    _qry: TSQLQuery;
begin
    Result := 0;
    _qry := qSelect(_tbl, _id, _fld);
    try
        _qry.Open;
        {while loop serves as if statement. Only one record. }
        while not _qry.EOF do
        begin
            Result := _qry.Fields[0].AsFloat;
            _qry.Next;
        end;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.getSQLiteLastID(): int64;
const
    Q = 'select last_insert_rowid()';
var
    _qry: TSQLQuery;
begin
    _qry := newQuery();
    try
        _qry.SQL.Text := Q;
        _qry.Open;
        Result := _qry.Fields[0].AsLargeInt;
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.execSQL(_sql: string; out _err: string): integer;
var
    _qry: TSQLQuery;
begin
    Result := 0;
    _qry := newQuery();
    try
        _qry.SQL.Text := _sql;
        Result := execSQL(_qry, _err);
    finally
        _qry.Free;
    end;
end;

function TSQLiteDBModule.execSQL(_sql: string): integer;
var
    _err: string;
begin
    // Swallow _err;
    Result := execSQL(_sql, _err);
end;

function TSQLiteDBModule.execSQL(var _qry: TSQLQuery; out _err: string): integer;
begin
    Result := 0;
    if safeStartTransaction then
    try
        _qry.ExecSQL;
        commit;
        Result := 1;
    except
        on E: Exception do
        begin
            Result := -1;
            _err := E.ToString;
            rollback;
        end;
    end;

end;

function TSQLiteDBModule.execSQL(var _qry: TSQLQuery): integer;
var
    _err: string;
begin
    // Swallow _err;
    Result := execSQL(_qry, _err);
end;


function TSQLiteDBModule.kv(_tbl: string): TSQLiteDBModule.TDBKeyValueStore;
begin
    Result := TSQLiteDBModule.TDBKeyValueStore.Create(_tbl, self);
end;

initialization
    RegisterClass(TSQLiteDBModule);
    myDBModules := TDBModuleList.Create();

finalization
    myDBModules.Free;
end.
