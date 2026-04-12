unit sugar.ddlmodel;

{$mode objfpc}{$H+}
{$MODESWITCH TYPEHELPERS}

interface

uses
    Classes, SysUtils, sugar.ddldatatypes, sugar.querybuilder, sugar.collections,
    sugar.utils, fpjson, sugar.jsonlib;

const
    COMMA = ', ';
    JSON_F = '"%s" : "%s"';
    JSON_D = '"%s" : "%d"';
    IDField = 'rid';
    TABLE_M2M_PREFIX = 'join_';

    NAME_SEPARATOR  = '_';
    SHORT_CODE_SIZE = 32;
    SHORT_TEXT_SIZE = 64;
    TEXT_SIZE       = 1024;

    // {$DEFINE NOINDENT}

    {$IFDEF NOINDENT}
    DEFAULT_INDENT = '';
    ENDLINE = '';

    {$ELSE}
    DEFAULT_INDENT = '   ';
    ENDLINE = sLineBreak;
    {$ENDIF}

type
    TargetDBS = (PostgresDB, SQLiteDB);

const
    SCHEMA_SUPPORTED_DB = [PostgresDB];

type

    TDefinitionActions = (actNone, actNew, actEdit, actDelete, actRender);
    TIndexCollation    = (icNone, icBinary, icNoCase, icRtrim); {SQLite. Add more if needed}

    { DDL }

    { DDLBase }

    DDLBase = class
    private
        FName: string;
        FDescription: string;
        FComment: string;
    public
        shouldRender: boolean;
        constructor Create; virtual; overload;
        constructor Create(_name: string); virtual; overload;
        function Name(_value: string): DDLBase; overload; virtual;
        function Name: string; overload;
        function Description(_value: string): DDLBase; overload; virtual;
        function Description: string; overload;
        function Comment(_value: string): DDLBase; overload; virtual;
        function Comment: string; virtual; overload;

        function getCreateSQL(indent: string = ''): string; virtual; abstract;
        function getUpdateSQL(indent: string = ''): string; virtual; abstract;
        function getDeleteSQL(indent: string = ''): string; virtual; abstract;
        function getJSON(indent: string = ''): string; virtual; abstract;
        function BuildFromJSON(_json: string): boolean; virtual; abstract;
    end;

    DDLBaseClass = class of DDLBase;

    { DDLList }

    generic DDLList<gDDL> = class(DDLBase)
    protected
        type
        TDDLObjectList = specialize GenericHashObjectList<gDDL>;
    private
        myList: TDDLObjectList;
        act: TDefinitionActions;
        function GetMembers(index: integer): gDDL;

    protected

        procedure Reset;

    public
        constructor Create(_name: string); override;
        destructor Destroy; override;
        function exists(_name: string): boolean;
        function find(_name: string): integer; // returns index of the item
        function findObj(_name: string): gDDL; // if found, returns the object
        function get(index: integer): gDDL; overload;
        function get(_name: string): gDDL; overload;
        function add(_name: string; _member: gDDL): gDDL; virtual;
        function addNew(_name: string): gDDL;
        function memberNames: string; virtual;// comma separated
        function changeName(const _member: gDDL; const _newName: string ): gDDL;

        //  Initialization
        procedure InitDataTypes; virtual;

        // Actions
        function getSQL(_for: TDefinitionActions): string;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;

        function Count: integer;
        property Items[index: integer]: gDDL read GetMembers;
    end;



    //Forward Declarations

    DScript = class;   {of DDLBase}
    DField = class;    {of DDLBase}
    DTable = class;    {collection of fields}
    DView = class;     {collection of fields}
    DSchema = class;   {collection of tables}
    DDatabase = class; {collection of schema}

    DTables = specialize GenericHashObjectList<DTable>;
    DFields = specialize GenericHashObjectList<DField>;


    _DTablesBase = specialize DDLList<DField>;
    _DSchemaBase = specialize DDLList<DTable>;
    _DDatabaseBase = specialize DDLList<DSchema>;
    _DScriptsBase = specialize DDLList<DScript>;

    DScripts = class(_DScriptsBase);

    { DDatabase colleciton of Schema}
    DDatabase = class(_DDatabaseBase)
    public
        constructor Create(_name: string); override;
        function Schema(_name: string): DSchema;

        function getSQL(_for: TDefinitionActions = actNew): string;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;
    end;

    { DSchema }
    DSchema = class(_DSchemaBase)
    private
        myPreScripts: DScripts;
        FDatabase: DDatabase;
        myScripts: DScripts;
        renderedTables : DTables; {needs to be a global variable}
        renderText: string;
		function isTableRendered(_table: DTable): boolean;
		function renderTableCreateSQL(constref _table: DTable; indent: string): string;
    public
        {Adds or Gets a database}
        function Database(_value: DDatabase): DSchema; overload; virtual;
        function Database: DDatabase; overload; virtual;


        {Adds or gets a table}
        function Table(_name: string): DTable; virtual;

        {Adds or gets a view}
        function View(_name: string): DView; virtual;

        {Adds or gets a script that is put in at the beginning}
        function PreScript(_name: string): DScript; virtual;

        {Adds or gets a script}
        function Script(_name: string): DScript; virtual;

        function Join(_linked_tables: array of DTable;
            _name: string = ''): DTable; virtual;

        function getSQL(_for: TDefinitionActions = actNew): string;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;

        constructor Create(_name: string = ''); override;
        destructor Destroy; override;
    end;

    DIndexType = (idxNormal, idxUnique);
    { DIndexTypeHelper }
    DIndexTypeHelper = type helper for DIndexType
        function toString: string;
    end;


    { DTable }
    DTable = class(_DTablesBase)
	protected
        myJournalEnabled: boolean;
        myDraftEditsEnabled: boolean;
        myArchiveEnabled: boolean;
        myDropBeforeCreate: boolean;
        FSchema: DSchema; {That owns this table}
        FPrimaryKeys: TStringList;
        FRefTables: TStringList;
        FForeignKeys: TList;
        FEnumFields: TList;

        {hash lists}
        FPrimaryKeyList: DFields;
        FForeignKeyFields: DFields;
        FEnumFieldList : DFields;
        FFullTextSearchFields: DFields;

        FRefTableList: DTables;

        function getField(_name: string): DField;
        function getEnumField(_name: string): DField;
        function getCreateIndexCmd(var _index_name: string;
            const _template: string; const _fields: array of string;
            const _unique: string = ''; const _collation: TIndexCollation = icNone;  _order: string = ''): string;
        function getSQLFor(qb: RbQueryBuilderBase): string;
        procedure setEnableJournal(const _EnableJournal: boolean);
        procedure setDraftEditsEnabled(const _DraftEditsOn: boolean);
        procedure setArchiveEnabled(const _ArchiveEnabled: boolean);
		procedure setDropBeforeCreate(const _DropBeforeCreate: boolean);
    public
        constructor Create(_name: string); override;
        destructor Destroy; override;

        property EnableJournal: boolean read myJournalEnabled   write setEnableJournal;
        property DraftEditsOn: boolean read myDraftEditsEnabled write setDraftEditsEnabled;
        property ArchiveEnabled: boolean read myArchiveEnabled  write setArchiveEnabled;
        property DropBeforeCreate: boolean read myDropBeforeCreate write setDropBeforeCreate;

        function memberNames(const _show: DFieldTypes = [ftPrimaryKey, ftForeignKey, ftData]): string; reintroduce;

        function FullName: string; overload;

        function schema(_value: DSchema): DTable; overload; virtual;
        function schema: DSchema; overload; virtual;

        function PK(_name: string): DField; overload;
        function PK: TStringList; overload; virtual;

        function References: TStringList; virtual;

        {## NUMERIC FIELDS ##}
        function Number(_name: string; _size: dword = 0): DField; virtual;
        function Decimal(_name: string; _size: dword= 0; _precision: dword = 0): DField; virtual;
        function Money(_name: string; _size: dword= 0;_precision: dword = 0): DField; virtual;

        function IntField(_name: string): DField; virtual;
        function bigIntField(_name: string): DField; virtual;
        function uIntField(_name: string): DField; virtual;
        function uBigIntField(_name: string): DField; virtual;

        {## TEXT FIELDS ##}
        function textcode(_name: string; _size: dword = SHORT_CODE_SIZE): DField;
        function shortText(_name: string; _size: word = SHORT_TEXT_SIZE):DField; virtual;
        function Text(_name: string; _size: dword = TEXT_SIZE): DField; virtual;
        function longText(_name: string):DField; virtual;
        function wideStr(_name: string): DField; virtual;

        {## DATE FIELDS ##}
        function Date(_name: string): DField; virtual;
        function Time(_name: string): DField; virtual;
        function Timestamp(_name: string): DField; virtual;

        {## BOOLEAN FIELD #}
        function Bool(_name: string): DField; virtual;

        {## ENUM FIELDS ##}
        {stores enum values in a separate enum table}
        function Enum(_name: string): DField; virtual; overload;
        function Enum(_field: DField): DField; virtual; overload;


        {## OTHER FIELDS ##}
        function Blob(_name: string): DField; virtual;
        function Vector(_name: string): DField; virtual; // array field
        function JSON(_name: string): DField; virtual;
        function JSONObject(_name: string): DField; virtual;
        function JSONArray(_name: string): DField; virtual;
        function JSMap(_name: string): DField; virtual;

        {stores a calculated field. Not generated for SQL}
        function calculated(_name: string): DField;

        {## FIELD OBJECT ##}
        function addField(_field: DField): DField;

        {## INDICES ##}
        function hashedIndex(_fields: array of DField; _name: string = ''): DTable;
            virtual; overload;
        function hashedIndex(_fields: array of string; _name: string = ''): DTable;
            virtual; overload;

        function btIndex(_fields: array of DField; _indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation = icNone; _order: string = ''): DTable; virtual; overload;
        function btIndex(_fields: array of string; _indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation = icNone; _order: string = ''): DTable; virtual; overload;

        {Inserts a FK reference}
        function Lookup(_table: DTable; _localFieldName: string = ''): DField; virtual;

        {Indicates that the value stored in the table is selected from a list
        of values from list table. Note that the new field name will be
        sourcetable_fieldname. You can change it with a chained called to Name()}
        function ListFrom(const _listFields: array of DField;
            const _store: DField): DField; virtual; overload;
        function ListFrom(const _table: DTable; _listFields: string;
            const _store: string = IDField; _delim: string=COMMA): DField;virtual; overload;

        {Creates a addNew table that fulfills many-to-one relationship with this table}
        function addMany(_name: string): DTable; virtual; overload;
        {Adds the given table as a detail table}
        function addMany(_table: DTable): DTable; virtual; overload;

        // Copy fields from another table
        function copyFrom(_source: DTable): DTable; virtual;
        function getSQL(_for: TDefinitionActions): string;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getAlterTableSQL(indent: string = ''): string;

        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;

        {Fetch fields by index or name}
        function field(const _index: integer): DField; overload;
        function field(const _name: string): DField; overload;

        {specifies the fields on which the model can perform a full text search.
        Internally, a long text field is created and populated with a concatenation of
        the given fields. Full text searches are do on the contents of this field..}
        function ftsFields(const _fields: array of string): DTable; overload;
        function ftsFields(const _fields: string; _delim: string = COMMA): DTable; overload;
        function ftsFields: DFields;

        {Returns a JSON Object with the fields defined in the model definition}
        function defaultRow: TDynaJSONObject;

        {does the field exist}
        function fieldExists(_name: string): boolean;
    end;

    { DView }
    DView = class(DTable)

    private
        function PK(_name: string): DField; overload;
        function PK: TStringList; overload; override;

        function References: TStringList; override;

        function Number(_name: string; _size: dword = 0): DField; override;
        function Decimal(_name: string; _size: dword = 0;
            _precision: dword = 0): DField; override;
        function textcode(_name: string; _size: dword=SHORT_CODE_SIZE): DField;
        function shortText(_name: string; _size: word=SHORT_TEXT_SIZE): DField; override;
        function Text(_name: string; _size: dword = TEXT_SIZE): DField; override;
        function longText(_name: string): DField; override;
        function Date(_name: string): DField; override;
        function Time(_name: string): DField; override;
        function Timestamp(_name: string): DField; override;
        function Bool(_name: string): DField; override;
        function Enum(_name: string): DField; override;
        function Blob(_name: string): DField; override;
        function Vector(_name: string): DField; override; // array getField
        function JSON(_name: string): DField; override;
        function Lookup(_table: DTable; _fields: string = ''): DField; override;
        function hashedIndex(_fields: array of DField; _name: string = ''): DTable;
            override; overload;
        function hashedIndex(_fields: array of string; _name: string = ''): DTable;
            override; overload;

        function btIndex(_fields: array of DField; _indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation = icNone;  _order: string = ''): DTable; override; overload;
        function btIndex(_fields: array of string; _indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation = icNone;  _order: string = ''): DTable; override; overload;

        {Creates a addNew table that fulfills many-to-one relationship with this table}
        function addMany(_name: string): DTable; override; overload;
        function addMany(_table: DTable): DTable; override; overload;
        function copyFrom(_table: DTable): DTable; override;
        // Copy fields copyFrom another table

    private
        myViewDefinition: string;
    public
        function ViewDefinition(_ViewDefinition: string): DView; overload;
        function ViewDefinition: string; overload;

    public
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;
    end;

    { DField }

    DField = class(DDLBase)
    private
        FTable: DTable;
        FFieldtype: DFieldType;
        FDatatype: DDataType;
        FFieldRelation: DModelLinkType;
        FDataTypeCategory: DDataTypeCategory;

        FSize: word;
        FPrecision: word;
        FDefaultValue: string;
        FIsNull: boolean;
        FIsUnique: boolean;
        FReferenceTable: string;
        FReferenceField: string;
        FStoredField: DField;
        FListFields: DFields;
        myHint: string;
        myCaption: string;
        {stores enum values or other options for that datatype}
        FChooseFrom: TStringArray;
        {cascade update and deletes}
        myCascadeUpdates: boolean;
        myCascadeDeletes: boolean;

    protected
        function getDataTypeName: string; virtual;

    public
        function referredName: string; // Returns table_name
        function fullName: string;// Returns "table.name"

        function Name(_value: string): DDLBase; overload; override;

        function Caption(_Caption: string): DField;
        function Caption: string; overload;
        function Hint(_Hint: string): DField;
        function Hint: string; overload;


        function Table(_value: DTable): DField; virtual; overload;
        function Table: DTable; virtual; overload;

        function FieldType(_value: DFieldType): DField; virtual; overload;
        function FieldType: DFieldType; virtual; overload;

        function DataType(_value: DDataType; _chooseFrom: TStringArray = nil): DField;
            virtual; overload;
        function DataType: DDataType; virtual; overload;

        function DataTypeCategory(_value: DDataTypeCategory): DField; overload;
        function DataTypeCategory: DDataTypeCategory; overload;

        function RelationType(_value: DModelLinkType): DField;
        function RelationType: DModelLinkType;

        function Size(_value: word): DField; virtual; overload;
        function Size: word; virtual; overload;

        function Precision(_value: word): DField; virtual; overload;
        function Precision: word; virtual; overload;

        function DefaultValue(_value: string): DField; virtual; overload;
        function DefaultValue: string; virtual; overload;

        function Null: DField; virtual;
        function NotNull: DField; virtual;
        function IsNull: boolean; virtual;
        function required(const _value: boolean = True): DField;

        function unique(const _value: boolean): DField; virtual; overload;
        function unique: DField; virtual; overload;
        function notUnique: DField; virtual;
        function isUnique: boolean;

        {redefined here for chaining}
        function Comment(_value: string): DDLBase; overload; override;

        {## FOREIGN KEY REFERENCES ##}
        function ReferenceTable(_name: string): DField; virtual; overload;
        function ReferenceTable: string; virtual; overload;
        function ReferenceField(_name: string): DField; virtual; overload;
        function ReferenceField: string; virtual; overload;

        function cascadeUpdates(_set:boolean = true): DField;
        function cascadeDeletes(_set:boolean = true): DField;
        function shouldCascadeUpdates: boolean;
        function shouldCascadeDeletes: boolean;


        function chooseFrom(_choosefrom: TStringArray): DField; virtual; overload;
        function chooseFrom(_choosefrom: array of string): DField; virtual; overload;
        function chooseFrom(const _choosefrom: string; const _delim: string=COMMA): DField;
			  virtual; overload;
        function chooseFrom: TStringArray; virtual; overload;

        {## STORE VALUE FROM DATA LISTED FROM ANOTHER TABLE ##}
        {Adds a reference to a table. Indicates the the values stored are
        listed from the given table }
        function listFrom: DFields; virtual; overload;
        function storedField: DField;

        {Definition to build the query to list the records that will be
        used for selection}

        {Specify the FieldObjects for listing and storing}
        function listFrom(const _listFields: array of DField;
            const _store: DField): DField; virtual; overload;

        {table name, array of field names}
        function listFrom(const _table: DTable; const _listFields: array of string;
                const _stored: string = IDField): DField; virtual; overload;

        {table name, delimited string of field names}
        function listFrom(const _table: DTable; const _listFields: string;
              const _store: string = IDField;
			  const _delim: string = COMMA): DField; virtual; overload;


        function hashedIndex(_name: string = ''): DField; virtual;
        function btIndex(_indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation=icNone; _order: string = ''): DField; virtual;
        function btIndexDesc(_indexType: DIndexType = idxNormal;
            _name: string = ''; _collation: TIndexCollation=icNone; _order: string = 'DESC'): DField; virtual;

        constructor Create(_name: string); override;
        destructor Destroy; override;

        function BuildFromJSON(_json: string): boolean; override;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;

        function getJSON(indent: string = ''): string; override;

        function isText: boolean;
        function isWideString: boolean;
        function isNumber: boolean;
        function isFloat: boolean;
        function isDate: boolean;
        function isBoolean: boolean;
        function isBinary: boolean;
        function isStruct: boolean;
        function isPointer: boolean;
        function isEnum: boolean;
        function isJSON: boolean;
        function isJSONArray: boolean;
        function isJSONObject: boolean;
        function isListedFromTable: boolean;

    end;

    { DScript }
    DScript = class(DDLBase)
    private
        myCode: TStringList;
    public
        function code: string;
        function add(_code: string): DScript;
        procedure Clear;
        constructor Create(_name: string = ''); override;
        destructor Destroy; override;

        function getSQL(_for: TDefinitionActions): string;
        function getCreateSQL(indent: string = ''): string; override;
        function getUpdateSQL(indent: string = ''): string; override;
        function getDeleteSQL(indent: string = ''): string; override;
        function getJSON(indent: string = ''): string; override;
        function BuildFromJSON(_json: string): boolean; override;
    end;

procedure setTargetDB(_targetDB: TargetDBS);
function getTargetDB: TargetDBS;
function getTargetDBName: string;

{convenience function}
function createTableSQL(const _tableDef: DTable): string;

implementation

const
    CREATE  = 'CREATE';
    UPDATE  = 'UPDATE';
    Delete  = 'DELETE';
    DROP    = 'DROP';
    ALTER   = 'ALTER';
    DATABASE = 'DATABASE';
    SCHEMA  = 'SCHEMA';
    TABLE   = 'TABLE';
    VIEW    = 'VIEW';
    PRIMARY_KEY = 'PRIMARY KEY';
    INSERT  = 'INSERT';
    INTO    = 'INTO';
    VALUES  = 'VALUES';
    SELECT  = 'SELECT';
    STAR    = '*';
    FROM    = 'FROM';
    INDEX   = 'INDEX';
    USE     = 'USE';
    CASCADE = 'CASCADE';

    CREATE_DB   = Create + ' ' + DATABASE + ' %s;';
    DROP_DB     = DROP = ' ' + DATABASE + ' %s;';
    USE_DB      = USE + ' ' + DATABASE;

    CREATE_SCHEMA = Create + ' ' + SCHEMA + ' %s;';
    DROP_SCHEMA   = DROP + ' ' + SCHEMA + ' %s;';

    CREATE_TBL              = Create + ' ' + TABLE + ' %s (';
    CREATE_TBL_IF_NOT_EXISTS= Create + ' ' + TABLE + ' IF NOT EXISTS %s (';
    DROP_TBL                = DROP + ' ' + TABLE + ' IF EXISTS %s;';
    DROP_TBL_CASCADE        = DROP + ' ' + TABLE + ' IF EXISTS %s ' + CASCADE + ';';
    ALTER_TBL               = ALTER + ' ' + TABLE + ' %s ';
    ADD_COLUMN              = 'ADD COLUMN %s';


    PRIMARY_KEY_DEF     = 'PRIMARY KEY (%s)';
    FOREIGN_KEY_DEF     = 'FOREIGN KEY (%s) REFERENCES %s (%s)';
    DEFAULT_ID_FIELD    = IDField;

var
    TARGETDB: TargetDBS = SQLiteDB;
    TARGETDBNAMES: array[TargetDBS] of string = ('Postgres', 'SQLite');

procedure setTargetDB(_targetDB: TargetDBS);
begin
    TARGETDB := _targetDB;
end;

function getTargetDB: TargetDBS;
begin
    Result := TARGETDB;
end;

function getTargetDBName: string;
begin
    Result := TARGETDBNAMES[TARGETDB];
end;

function createTableSQL(const _tableDef: DTable): string;
begin
    Result := _tableDef.getCreateSQL('');
end;

{ DView }

function DView.PK(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('PK: Not allowed in an SQL view');
end;

function DView.PK: TStringList;
begin
    Result := inherited PK;
end;

function DView.References: TStringList;
begin
    Result := inherited References;
    // raise Exception.Create('References: Not allowed in an SQL view');
end;

function DView.Number(_name: string; _size: dword): DField;
begin
    Result := nil;
    raise Exception.Create('Int: Not allowed in an SQL view');

end;

function DView.Decimal(_name: string; _size: dword; _precision: dword): DField;
begin
    Result := nil;
    raise Exception.Create('Decimal: Not allowed in an SQL view');
end;

function DView.textcode(_name: string; _size: dword): DField;
begin
    Result := nil;
    raise Exception.Create('textcode: Not allowed in an SQL view');
end;

function DView.shortText(_name: string; _size: word): DField;
begin
    Result := nil;
    raise Exception.Create('shortText: Not allowed in an SQL view');
end;

function DView.Text(_name: string; _size: dword): DField;
begin
    Result :=  nil;
    raise Exception.Create('Text: Not allowed in an SQL view');
end;

function DView.longText(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('shortText: Not allowed in an SQL view');
end;

function DView.Date(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Date: Not allowed in an SQL view');
end;

function DView.Time(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Time: Not allowed in an SQL view');
end;

function DView.Timestamp(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Timestamp: Not allowed in an SQL view');
end;

function DView.Bool(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Bool: Not allowed in an SQL view');
end;

function DView.Enum(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Enum: Not allowed in an SQL view');
end;

function DView.Blob(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Blob: Not allowed in an SQL view');
end;

function DView.Vector(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('Vector: Not allowed in an SQL view');
end;

function DView.JSON(_name: string): DField;
begin
    Result := nil;
    raise Exception.Create('JSON: Not allowed in an SQL view');
end;

function DView.Lookup(_table: DTable; _fields: string): DField;
begin
    Result := nil;
    raise Exception.Create('Lookup: Not allowed in an SQL view');
end;

function DView.hashedIndex(_fields: array of DField; _name: string): DTable;
begin
    Result := self;
    raise Exception.Create('hashedIndex: Not allowed in an SQL view');
end;

function DView.hashedIndex(_fields: array of string; _name: string): DTable;
begin
    Result := self;
    raise Exception.Create('hashedIndex: Not allowed in an SQL view');
end;

function DView.btIndex(_fields: array of DField; _indexType: DIndexType;
    _name: string; _collation: TIndexCollation = icNone;  _order: string = ''): DTable;
begin
    Result := self;
    raise Exception.Create('btIndex: Not allowed in an SQL view');

end;

function DView.btIndex(_fields: array of string; _indexType: DIndexType;
    _name: string; _collation: TIndexCollation = icNone;  _order: string = ''): DTable;
begin
    Result := self;
    raise Exception.Create('btIndex: Not allowed in an SQL view');

end;

function DView.addMany(_name: string): DTable;
begin
    Result := self;
    raise Exception.Create('addMany: Not allowed in an SQL view');
end;

function DView.addMany(_table: DTable): DTable;
begin
    Result := self;
    raise Exception.Create('addMany: Not allowed in an SQL view');
end;

function DView.copyFrom(_table: DTable): DTable;
begin
    Result := self;
    raise Exception.Create('copyFrom: Not allowed in an SQL view');

end;

function DView.ViewDefinition(_ViewDefinition: string): DView;
begin
    myViewDefinition := _ViewDefinition;
    Result := self;
end;

function DView.ViewDefinition: string;
begin
    Result := myViewDefinition;
end;

function DView.getCreateSQL(indent: string): string;
begin
    Result := indent + format('CREATE VIEW IF NOT EXISTS %s AS %s;',
        [FullName, myViewDefinition]) + ENDLINE;
end;

function DView.getUpdateSQL(indent: string): string;
begin
    Result := '';
end;

function DView.getDeleteSQL(indent: string): string;
begin
    Result := Format('DROP VIEW %s', [Name]);
end;

function DView.getJSON(indent: string): string;
begin
    Result := inherited getJSON(indent);
end;

function DView.BuildFromJSON(_json: string): boolean;
begin
    Result := inherited BuildFromJSON(_json);
end;


{ DIndexTypeHelper }

function DIndexTypeHelper.toString: string;
begin
    case self of
        idxNormal: Result := '';
        idxUnique: Result := 'unique';
    end;
end;

{ DScript }

function DScript.code: string;
begin
    Result := myCode.Text;
end;

function DScript.add(_code: string): DScript;
begin
    myCode.Add(_code);
    Result := self;
end;

procedure DScript.Clear;
begin
    myCode.Clear;
end;

constructor DScript.Create(_name: string);
begin
    inherited Create(_name);
    myCode := TStringList.Create;
end;

destructor DScript.Destroy;
begin
    FreeAndNil(myCode);
    inherited Destroy;
end;

function DScript.getSQL(_for: TDefinitionActions): string;
begin
    Result := getCreateSQL('');
end;

function DScript.getCreateSQL(indent: string): string;
var
    i: integer;
begin
    Result := '';
    for i := 0 to myCode.Count - 1 do
    begin
        Result := Result + indent + myCode.Strings[i] + ENDLINE;
    end;
end;

function DScript.getUpdateSQL(indent: string): string;
begin
    Result := 'UpdateSQL for DScript not implemented';
end;

function DScript.getDeleteSQL(indent: string): string;
begin
    Result := 'DeleteSQL for DScript not implemented';
end;

function DScript.getJSON(indent: string): string;
begin
    Result := 'getJSON for Script not implemented';
end;

function DScript.BuildFromJSON(_json: string): boolean;
begin
    Result := False;
end;


{ DDLBase }

constructor DDLBase.Create;
begin
    inherited;
    shouldRender := True;
end;

constructor DDLBase.Create(_name: string);
begin
    Create;
    FName := _name;
end;

function DDLBase.Name(_value: string): DDLBase;
begin
    FName := _value;
    Result := Self;
end;

function DDLBase.Name: string;
begin
    Result := FName;
end;

function DDLBase.Description(_value: string): DDLBase;
begin
    FDescription := _value.Replace(sLineBreak, ' ');
    Result := self;
end;

function DDLBase.Description: string;
begin
    Result := FDescription;
end;

function DDLBase.Comment(_value: string): DDLBase;
begin
    FComment := _value;
    Result := self;
end;

function DDLBase.Comment: string;
begin
    Result := FComment;
end;

{ DSql }

function DDLList.GetMembers(index: integer): gDDL;
begin
    // Result := Gen(FList.Items[index]);
    Result := myList.Items[index];
end;

function DDLList.add(_name: string; _member: gDDL): gDDL;
begin
    myList.add(_name, _member);
    Result := _member;
end;


procedure DDLList.Reset;
begin
    act := actNone;
end;

function DDLList.getCreateSQL(indent: string): string;
var
    i: integer;
    _name: string;
    _obj: DDLBase;
begin
    Result := '';
    indent := indent + DEFAULT_INDENT;
    for i := 0 to myList.Count - 1 do
    begin
        _name := myList.Names[i];
        _obj := myList.Items[i];
        Result := Result + Format('%s/**** %s ****/%s',
            [indent, _name, ENDLINE]);
        Result := Result + _obj.getCreateSQL(indent);
    end;
    Result := Result + ENDLINE;
end;

function DDLList.getUpdateSQL(indent: string): string;
begin
    Result := 'DDL UPDATE SQL';
end;

function DDLList.getDeleteSQL(indent: string): string;
begin
    Result := 'DDL DELETE SQL';
end;

function DDLList.Count: integer;
begin
    Result := myList.Count;
end;


function DDLList.BuildFromJSON(_json: string): boolean;
begin
    Result := False;
    {Not implemented}
end;

constructor DDLList.Create(_name: string);
begin
    inherited Create(_name);
    myList := TDDLObjectList.Create;
end;

destructor DDLList.Destroy;
begin
    myList.Free;
    inherited Destroy;
end;

function DDLList.exists(_name: string): boolean;
begin
    Result:= Assigned(findObj(_name));
end;

function DDLList.get(index: integer): gDDL;
begin
    Result := nil;
    if (index >= 0) and (index <= Count) then
        Result := myList.Items[index];
end;

function DDLList.find(_name: string): integer;{returns index of the object}
begin
    Result := myList.FindIndexOf(_name);
end;

function DDLList.findObj(_name: string): gDDL;
begin
    Result:= myList.find(_name);
end;

function DDLList.get(_name: string): gDDL;
begin
    Result := findObj(_name);
    if not Assigned(Result) then
        Result := addNew(_name);
end;

function DDLList.addNew(_name: string): gDDL;
begin
    Result := gDDL.Create(_name);
    Add(_name, Result);
end;

function DDLList.memberNames: string;
begin
    Result := myList.getNames();
end;

function DDLList.changeName(const _member: gDDL; const _newName: string): gDDL;
var
    i: integer;
    _oldName: string;
begin
    i := myList.IndexOf(_member);
    if i>-1 then
    begin
        Result:= myList.Items[i];
        _oldName:= myList.Names[i];
        myList.Rename(_oldName, _newName);
	end;
end;

function DDLList.getJSON(indent: string): string;
var
    i: shortint;
    s: string;
    org_indent: string;
    indent0, indent1, indent2, indent3, indent4: string;
    addComma: boolean = False;
begin
    indent0 := indent;
    indent1 := indent0 + DEFAULT_INDENT;
    indent2 := indent1 + DEFAULT_INDENT;
    indent3 := indent2 + DEFAULT_INDENT;
    indent4 := indent3 + DEFAULT_INDENT;

    // LEVEL 0
    Result := Format('%s{%s', [indent0, ENDLINE]);

    //LEVEL 1
    Result := Result + Format('%s"%s" : "%s",%s',
        [indent1, 'ddl_object', ClassName, ENDLINE]);
    Result := Result + indent1 + Format(JSON_F, ['name', Name]) + COMMA + ENDLINE;
    Result := Result + indent1 + '"members" : {' + ENDLINE;

    for i := 0 to Count - 1 do
    begin
        // LEVEL 2
        s := indent2 + Format('"%d" : ', [i]) + ENDLINE;
        // LEVEL 3
        s := s + myList.Items[i].getJSON(indent3);
        //LEVEL 2
        if addComma then
            Result := Result + COMMA
        else
            addComma := True;
        Result := Result + s + ENDLINE;
    end;
    // LEVEL 1
    Result := Result + indent1 + '}' + ENDLINE;
    // LEVEL 0
    Result := Result + indent0 + '}';
end;

procedure DDLList.InitDataTypes;
begin

end;

function DDLList.getSQL(_for: TDefinitionActions): string;
begin
    Result := 'DDL GETSQL';
    case _for of
        TDefinitionActions.actNone: Result := '';
        TDefinitionActions.actNew: Result := getCreateSQL;
        TDefinitionActions.actEdit: Result := getUpdateSQL;
        TDefinitionActions.actDelete: Result := getDeleteSQL;
    end;
end;

constructor DDatabase.Create(_name: string);
begin
    inherited Create(_name);
    shouldRender := False; {Don't render create database by default}
end;

function DDatabase.Schema(_name: string): DSchema;
begin
    Result := get(_name);
    if (not Assigned(Result.Database)) then
        Result.Database(Self);
end;

function DDatabase.getSQL(_for: TDefinitionActions): string;
begin
    case _for of
        actNone: Result := '';
        actNew: Result := getCreateSQL();
        actEdit: Result := getUpdateSQL();
        actDelete: Result := getDeleteSQL();
        actRender: Result := '';
    end;
end;

function DDatabase.getCreateSQL(indent: string): string;
var
    i: shortint;
    s: DSchema;
    q: string;
begin
    Result := indent + Format('/* ### Create DB for %s ### /*',  [TARGETDBNAMES[TARGETDB]]) + ENDLINE;

    if shouldRender then
        Result := Result + indent + Format(CREATE_DB, [Name]) + ENDLINE;


    for i := 0 to Count - 1 do
    begin
        try
        s := myList.Items[i];
        Result := Result + s.getCreateSQL(indent + DEFAULT_INDENT);
		except
          on e: Exception do
            // log('DDatabase.getCreateSQL error: ' + e.message);
            ;
		end;
	end;
end;

function DDatabase.getUpdateSQL(indent: string): string;
begin
    Result := '';
end;

function DDatabase.getDeleteSQL(indent: string): string;
begin
    Result := '';
end;

function DDatabase.getJSON(indent: string): string;
begin
    Result := inherited getJSON(indent);
end;

function DDatabase.BuildFromJSON(_json: string): boolean;
begin
    Result := inherited BuildFromJSON(_json);
end;

function DSchema.Database(_value: DDatabase): DSchema;
begin
    if (FDatabase <> _value) then
        FDatabase := _value;
    Result := Self;
end;

function DSchema.Database: DDatabase;
begin
    Result := FDatabase;
end;

{ DSchema }
function DSchema.Table(_name: string): DTable;
begin
    Result := get(_name);
    if Assigned(Result) then
        Result.schema(Self);
end;

function DSchema.View(_name: string): DView;
begin
    Result := DView.Create(_name);
    Result.schema(self);
    Add(_name, Result);
end;

function DSchema.PreScript(_name: string): DScript;
begin
    Result := myPreScripts.get(_name);
end;

function DSchema.Script(_name: string): DScript;
begin
    Result := myScripts.get(_name);
end;

function DSchema.Join(_linked_tables: array of DTable; _name: string): DTable;
var
    _link_tables_count: shortint;
    i: shortint;
    use_generated_name: boolean = False;
begin
    if _name.Length > 0 then
    begin
        {find or create a table with the given name}
        Result := get(_name);
    end
    else
    begin
        {generate a table automatically}
        use_generated_name := True;

        {default this will be assigned below}
        Result := DTable.Create('').schema(Self);
    end;

    _link_tables_count := High(_linked_tables);
    for i := 0 to _link_tables_count do
    begin
        if use_generated_name then
        begin
            if (i = 0) then
                Result.Name(TABLE_M2M_PREFIX) {Default prefix for many to many tables}
            else
                Result.Name(Result.Name + NAME_SEPARATOR);
            Result.Name(Result.Name + _linked_tables[i].Name);
        end;
        {After getting the table name, perform look up}
        Result.Lookup(_linked_tables[i]);
    end;
    {If this is a newly created table then add to the list}
    if use_generated_name then
    begin
        Add(Result.Name, Result);
    end;
end;

function DSchema.getSQL(_for: TDefinitionActions): string;
begin
    case _for of
        actNone: Result := '';
        actNew: Result := getCreateSQL();
        actEdit: Result := getUpdateSQL();
        actDelete: Result := getDeleteSQL();
        actRender: Result := 'Not implemented';
    end;
end;

function DSchema.isTableRendered(_table: DTable): boolean;
begin
    Result := False;
    if Assigned(_table) then
        Result := Assigned(renderedTables.find(_table.Name));
end;


function DSchema.renderTableCreateSQL(constref _table: DTable; indent: string): string;
var
    refTable: DTable;
    refTableName: string;
begin
    Result := '';
    // Render any referenced tables before the current table
    for refTableName in _table.References do
    begin
	      refTable:= myList.find(refTableName);
	      //write('References: searching for ', refTable.Name);
	      if not isTableRendered(refTable) then
	      begin
	          //write(': not rendered ', refTable.Name);
	          Result := Result + renderTableCreateSQL(refTable, indent); {recursive}
              renderedTables.add(refTable.Name, refTable);
	          //write(' ...done ');
		  end;
	      //else
          ;
	      //write(': already rendered');
	      //writeln('');
	end;

    if not isTableRendered(_table) then
    begin
        //write('Rendering: current table ', _table.Name);
        Result := Result + _table.getCreateSQL(indent);
        renderedTables.add(_table.Name, _table);
        //write(' ...done ');
	end
    else
        ;//write(': Already rendered.');
end;

function DSchema.getCreateSQL(indent: string): string;
var
    i: shortint;
    currTable: DTable;
    refTable: DTable;
    refTableName: string;
begin
    Result := '';
    {THIS IS A GLOBAL VARIABLE USED by renderTableCreateSQL()- -- have to refactor!!!}
    renderedTables:= DTables.Create(false); {don't auto free objects}

    if myPreScripts.Count > 0 then
    begin
        Result := Result + indent + '/* -- Initialization Scripts -- */' + ENDLINE;
        Result := Result + myPreScripts.getCreateSQL(indent);
    end;

    if shouldRender then
        Result := Result + indent + Format(CREATE_SCHEMA, [Name]) + ENDLINE;

    for i := 0 to Count - 1 do
    begin
        currTable := myList.Items[i];
        //writeln('');
        //writeln('### -- Working: current table ', currTable.Name,' -- ##');
        Result := Result + renderTableCreateSQL(currTable, indent + DEFAULT_INDENT);
	end;

    if myScripts.Count > 0 then
    begin
        Result := Result + indent + '/* -- After Scripts -- */' + ENDLINE;
        Result := Result + myScripts.getCreateSQL(indent);
    end;


    renderedTables.Free; {objects are not freed}
end;

function DSchema.getUpdateSQL(indent: string): string;
begin
    Result := ''; // No update command for schema
    Result := Format(DROP_SCHEMA, [Name]);
end;

function DSchema.getDeleteSQL(indent: string): string;
begin
    Result := Format(DROP_SCHEMA, [Name]);
end;

function DSchema.getJSON(indent: string): string;
begin
    Result := inherited getJSON(indent);
end;

function DSchema.BuildFromJSON(_json: string): boolean;
begin
    Result := inherited BuildFromJSON(_json);
end;

constructor DSchema.Create(_name: string);
begin
    inherited Create(_name);
    shouldRender := (TARGETDB = PostgresDB);

    myScripts := DScripts.Create(_name);
    myPreScripts := DScripts.Create(_name);
end;

destructor DSchema.Destroy;
begin
    FreeAndNil(myScripts);
    FreeAndNil(myPreScripts);
    inherited Destroy;
end;

procedure DTable.setDropBeforeCreate(const _DropBeforeCreate: boolean);
begin
	if myDropBeforeCreate=_DropBeforeCreate then Exit;
	myDropBeforeCreate:=_DropBeforeCreate;
end;

function DTable.getField(_name: string): DField;
begin
    Result := get(_name);
    if not Assigned(Result.Table) then
        Result.Table(self);
end;

function DTable.getEnumField(_name: string): DField;
begin
    Result := Number(_name).DataTypeCategory(dtcEnum);
    FEnumFields.Add(Result);
    FEnumFieldList.add(_name, Result);
end;

constructor DTable.Create(_name: string);
begin
    inherited Create(_name);
    FPrimaryKeys := TStringList.Create;
    FRefTables := TStringList.Create;
    FForeignKeys := TList.Create;
    FEnumFields := TList.Create;

    {Transitioning to using hash object list. TODO}
    FPrimaryKeyList   := DFields.Create(false);
    FForeignKeyFields := DFields.Create(false);
    FRefTableList     := DTables.Create(false);
    FEnumFieldList    := DFields.Create(false);
    FFullTextSearchFields := DFields.Create(false);

    myJournalEnabled    := True;
    myDraftEditsEnabled := True;
    myArchiveEnabled    := True;
    myDropBeforeCreate  := False;

    PK(DEFAULT_ID_FIELD); // create a default Primary Key
end;

destructor DTable.Destroy;
begin
    FreeAndNil(FForeignKeys);   // only contains pointers so don't free them here.
    FreeAndNil(FPrimaryKeys);   // The Items will be freed when the inherited
    FreeAndNil(FRefTables);     // destructor is called
    FreeAndNil(FEnumFields);
    FreeAndNil(FFullTextSearchFields);

    FPrimaryKeyList.Free;
    FForeignKeyFields.Free;
    FRefTableList.Free;
    FEnumFieldList.Free;

    inherited Destroy;
end;

function DTable.memberNames(const _show: DFieldTypes): string;
var
    i: integer;
    _addDelim: boolean = False;
begin
    Result := '';
    for i := 0 to Count - 1 do
    begin
        if (Items[i].FieldType in _show) then
        begin
            if _addDelim then
                Result := Result + COMMA
            else
                _addDelim := True;
            Result := Result + Items[i].Name;
        end;
    end;
end;

function DTable.FullName: string;
var
    s: string = '';
begin
    if TARGETDB in SCHEMA_SUPPORTED_DB then
    begin
        if Assigned(schema) then
            s := schema.Name;
        if s <> '' then
            s := s + '.';
        Result := Format('%s%s', [s, Self.FName]);
    end
    else
        {Don't return Schema if this is not supported}
        Result := Name;

end;

function DTable.schema(_value: DSchema): DTable;
begin
    if (FSchema <> _value) then
        FSchema := _value;
    Result := Self;
end;

function DTable.schema: DSchema;
begin
    Result := FSchema;
end;

{By default creates an auto-increment field}
function DTable.PK(_name: string): DField;
begin
    Result := getField(_name).FieldType(ftPrimaryKey).Datatype(dtBigSerial);
    FPrimaryKeys.Add(Result.Name);
    FPrimaryKeyList.Add(_name, Result);
end;

function DTable.PK: TStringList;
begin
    Result := FPrimaryKeys;
end;

function DTable.References: TStringList;
begin
    Result := FRefTables;
end;

function DTable.Number(_name: string; _size: dword): DField;
begin
    Result := getField(_name)
             .FieldType(DFieldType.ftData)
             .Size(_size)
             .Precision(0);

    if _size = 0 then
        Result.Datatype(DDataType.dtBigInt)
    else
        Result.Datatype(DDataType.dtNumeric)
end;

function DTable.Decimal(_name: string; _size: dword; _precision: dword): DField;
begin
    Result := getField(_name)
              .FieldType(DFieldType.ftData)
              .Size(_size)
              .Precision(_precision);

    if _precision = 0 then
        Result.Datatype(DDataType.dtReal)
    else
        Result.Datatype(DDataType.dtNumeric);

end;

function DTable.Money(_name: string; _size: dword; _precision: dword): DField;
begin
    Result := getField(_name)
              .FieldType(DFieldType.ftData)
              .Size(_size)
              .Precision(_precision);

    Result.DataType(DDataType.dtMoney);
end;

function DTable.IntField(_name: string): DField;
begin
	 Result := getField(_name)
	          .FieldType(DFieldType.ftData)
	          .Datatype(DDataType.dtInteger);
end;

function DTable.bigIntField(_name: string): DField;
begin
Result := getField(_name)
         .FieldType(DFieldType.ftData)
         .Datatype(DDataType.dtBigInt);
end;

function DTable.uIntField(_name: string): DField;
begin
	 Result := getField(_name)
	          .FieldType(DFieldType.ftData)
	          .Datatype(DDataType.dtWord);
end;

function DTable.uBigIntField(_name: string): DField;
begin
Result := getField(_name)
         .FieldType(DFieldType.ftData)
         .Datatype(DDataType.dtQWord);
end;

function DTable.textcode(_name: string; _size: dword): DField;
begin
    Result := shortText(_name, _size);
end;

function DTable.shortText(_name: string; _size: word): DField;
begin
    Result := getField(_name).DataType(DDataType.dtString).FieldType(DFieldType.ftData).Size(_size);
end;

function DTable.Text(_name: string; _size: dword): DField;
begin
    Result := getField(_name).DataType(DDataType.dtVarchar)
        .FieldType(DFieldType.ftData).Size(_size);
end;

function DTable.longText(_name: string): DField;
begin
    Result := getField(_name).DataType(DDataType.dtText)
        .FieldType(DFieldType.ftData);
end;

function DTable.wideStr(_name: string): DField;
begin
    Result := getField(_name).DataType(DDataType.dtWideString)
        .FieldType(DFieldType.ftData);
end;

function DTable.Date(_name: string): DField;
begin
    Result := getField(_name).DataType(dtDate).FieldType(DFieldType.ftData);
end;

function DTable.Time(_name: string): DField;
begin
    Result := getField(_name).DataType(dtTime).FieldType(DFieldType.ftData);
end;

function DTable.Timestamp(_name: string): DField;
begin
    Result := getField(_name).DataType(dtDateTime).FieldType(DFieldType.ftData);
end;

function DTable.Bool(_name: string): DField;
begin
    Result := getField(_name).DataType(dtBoolean).FieldType(DFieldType.ftData);
end;

function DTable.Enum(_name: string): DField;
begin
    {This stores the enum as a lookup into the enum table}
    Result := getEnumField(_name);
end;

function DTable.Enum(_field: DField): DField;
begin
    addField(_field);
    FEnumFields.Add(_field);
    FEnumFieldList.add(_field.Name, _field);
    Result:= _field;
end;

function DTable.Blob(_name: string): DField;
begin
    Result := getField(_name).DataType(dtBinary).FieldType(DFieldType.ftData);
end;

function DTable.Vector(_name: string): DField;
begin
    Result := getField(_name).FieldType(DFieldType.ftData);
end;

function DTable.JSON(_name: string): DField;
begin
    Result := getField(_name).DataType(dtJSON).FieldType(DFieldType.ftData);
end;

function DTable.JSONObject(_name: string): DField;
begin
    Result := getField(_name).DataType(dtJSONObject).FieldType(DFieldType.ftData);
end;

function DTable.JSONArray(_name: string): DField;
begin
    Result := getField(_name).DataType(dtJSONArray).FieldType(DFieldType.ftData);
end;

function DTable.JSMap(_name: string): DField;
begin
    Result := getField(_name).DataType(dtJSONArray).FieldType(DFieldType.ftData);
end;

function DTable.calculated(_name: string): DField;
begin
    Result := getField(_name);
    Result.FieldType(ftCalculated);
    Result.DataType(dtString);
end;

function DTable.addField(_field: DField): DField;
begin
    Result := _field;
    if Assigned(Result) then
    begin
        if find(_field.Name) < 0 then
        begin
            add(_field.Name, _field);
            _field.Table(self);
		end
		else
            trip('DTable.addField(). Field is already added: '+ _field.Name)
    end
    else
        trip('DTable.addField(DField): Field Object is null in ' + FullName );
end;


{!! Need to refactor this to handle more than 1 PK}
function DTable.Lookup(_table: DTable; _localFieldName: string): DField;
var
    _field_name: string = '';
    keys: TStringList;
    i: integer;
    ref_field: DField;
    lookup_field: DField;
begin
    lookup_field := nil;

    {Get the list of primary keys from the lookup table}
    keys := _table.PK;
    if (keys.Count = 0) then
    begin
        raise Exception.Create(Format('%s: No primary keys defined.',
            [_table.FullName]));
    end;

    {All is well. Primary keys are available}
    if keys.Count > 0 then
    begin
        {Loop through the primary keys}
        for i := 0 to keys.Count - 1 do
        begin
            {get the referenced getField copyFrom the table to lookup}
            ref_field := _table.getField(keys.Strings[i]);

            {name of the local field}
            if _localFieldName.isEmpty then
                _localFieldName:= Format('%s%s%s', [_table.Name, NAME_SEPARATOR, ref_field.Name]);

            {create the foreign key (lookup)}
            lookup_field := getField(_localFieldName);

            {fill in fieldType, referenceTable and referenceField}
            lookup_field.FieldType(DFieldType.ftForeignKey)
                .ReferenceTable(_table.FullName)
                .ReferenceField(ref_field.Name);

            {if the reference getField is autoincemented, then set FK to integer}
            if ref_field.DataType in [dtSerial, dtBigSerial] then
                lookup_field.DataType(dtBigInt)
            else
                lookup_field.DataType(ref_field.DataType);

            FForeignKeys.Add(lookup_field); // add a reference to this list
            FForeignKeyFields.Add(lookup_field.Name, lookup_field);
            lookup_field.cascadeUpdates;
        end;
        {Add to list of foreign keys}
        FRefTables.Add(_table.Name);
        FRefTableList.Add(_table.Name, _table);
    end;
    Result := lookup_field;
end;

function DTable.ListFrom(const _listFields: array of DField;
	  const _store: DField): DField;
begin
    Result:= addNew(_store.referredName);
    Result.ListFrom(_listFields, _store);
end;

function DTable.ListFrom(const _table: DTable; _listFields: string;
	  const _store: string; _delim: string): DField;
begin
    Result := addNew(_table.Name + '_' +_store);
    Result.listFrom(_table, _listFields, _store);
end;

function DTable.getCreateIndexCmd(var _index_name: string;
	const _template: string; const _fields: array of string;
	const _unique: string; const _collation: TIndexCollation; _order: string
	): string;
var
    _tmp_index_name: string = '';
    _index_fields: string = '';
    _field: string;
    bAddSeparator: boolean = false;
begin
    Result := '';

    {exit if there are no fields}
    if Length(_fields) = 0 then exit;

    for _field in _fields do
    begin

        if bAddSeparator then { check for appending separator}
        begin
            _tmp_index_name := _tmp_index_name + NAME_SEPARATOR;
            _index_fields := _index_fields + COMMA;
        end
        else
            bAddSeparator:= true;

        _tmp_index_name := _tmp_index_name + _field;
        _index_fields := _index_fields + _field;
    end;

    case TARGETDB of
        PostgresDB: ;
        SQLiteDB: begin
              case _collation of
                  icNone: ;
                  icBinary: _index_fields := _index_fields + ' COLLATE BINARY' ;
                  icNoCase: _index_fields := _index_fields + ' COLLATE NOCASE' ;
                  icRtrim:  _index_fields := _index_fields + ' COLLATE RTRIM' ;
              end;
		end;
    end;

    {Return the index name}
    if _index_name.IsEmpty then
        _index_name := Format('idx_%s_%s', [{table} Self.Name, _tmp_index_name]);

    Result := Format(_template, [_unique, _index_name, Self.FullName, _index_fields, _order]);
end;

function DTable.hashedIndex(_fields: array of DField; _name: string): DTable;
var
    _str_fields: array of string;
    i: integer;
    _count: integer;
begin
    Result := Self;
    _count := High(_fields);
    {exit if there are no _fields}
    if _count < 0 then
        exit;

    {copy the array}
    SetLength(_str_fields, _count + 1);
    for i := 0 to _count do
    begin
        _str_fields[i] := _fields[i].Name;
    end;

    {Add the index command to script}
    Result := hashedIndex(_str_fields, _name);
end;

function DTable.hashedIndex(_fields: array of string; _name: string): DTable;
const
    idxTemplate = 'CREATE %s INDEX IF NOT EXISTS %s ON %s USING HASH (%s);';
var
    _cmd: string = '';
begin
    Result := Self;
    {exit if the target db is SQLite because it does not support hashed index}
    if TARGETDB = SQLiteDB then
        exit;

    _cmd := getCreateIndexCmd(_name, idxTemplate, _fields);
    {add index command to the script}
    Schema.Script(_name).add(_cmd);
end;


function DTable.btIndex(_fields: array of DField; _indexType: DIndexType;
	_name: string; _collation: TIndexCollation; _order: string): DTable;
var
    _str_fields: array of string;
    i: integer;
    _count: integer;
begin
    Result := self;

    _count := High(_fields);
    if _count < 0 then
        exit;

    SetLength(_str_fields, _count + 1);
    for i := 0 to _count do
    begin
        _str_fields[i] := _fields[i].Name;
    end;
    btIndex(_str_fields, _indexType, _name, _collation, _order);
end;

function DTable.btIndex(_fields: array of string; _indexType: DIndexType;
	_name: string; _collation: TIndexCollation; _order: string = ''): DTable;
const
    idxTemplate = 'CREATE %s INDEX IF NOT EXISTS %s ON %s (%s %s);';
var
    _cmd: string = '';
begin
    Result := Self;
    _cmd := getCreateIndexCmd(_name, idxTemplate, _fields, _indexType.toString, _collation, _order);
    Schema.Script(_name).add(_cmd);
end;

function DTable.addMany(_name: string): DTable;
begin
    Result := Schema.Table(_name);
    if Assigned(Result) then
        Result.Lookup(Self);
end;

function DTable.addMany(_table: DTable): DTable;
begin
    Result := _table;
    if assigned(_table) then
        _table.Lookup(Self);
end;

function DTable.copyFrom(_source: DTable): DTable;
var
    _field: DField;
    _newField: DField;
    i: shortint;
    _references: TStringList;
begin
    {TODO: Copy indices}
    if _source.Count > 0 then
    begin
        for i := 0 to _source.Count - 1 do
        begin
            _field := _source.Items[i];
            if _field.FieldType in [ftPrimaryKey, ftForeignKey] then
                continue;

            // Copy ftData fields
            _newField := DField.Create(_field.Name);
            with _newField do
            begin
                FieldType(_field.FieldType);
                DataType(_field.DataType);
                DefaultValue(_field.DefaultValue);
                Comment(_field.Comment);
                Description(_field.Description);
                Hint(_field.Hint);
                Caption(_field.Caption);
                if not _field.IsNull then
                    NotNull;
                Size(_field.Size);
            end;
            _newField.Table(Self);
            Add(_newField.Name, _newField);
        end;
    end;

    // Copy Foreign Keys
    _references := _source.References;
    if _references.Count > 0 then
        for i := 0 to _references.Count - 1 do
        begin
            Lookup(Schema.Table(_references.Strings[i]));
        end;
    Result := Self;
end;

function DTable.getSQL(_for: TDefinitionActions): string;
begin
    Result := 'Not implemented';
end;

function DTable.getCreateSQL(indent: string): string;
var
    i: shortint;
    fk: DField;
    addComma: boolean = False;
    _sql: string;
begin
try
    {CREATE TABLE}
    // Writeln('-- starting on ', FullName);
    Result := indent + '/* ### ' + UpperCase(FullName) + ' ### */' + ENDLINE;

    if DropBeforeCreate then
    begin
        {Drop the table before creating it}
	    case TargetDB of
	        PostgresDB: Result := Result + indent + Format(DROP_TBL_CASCADE, [FullName]) + ENDLINE;
	          SQLiteDB: Result := Result + indent + Format(DROP_TBL, [FullName]) + ENDLINE;
	    end;
        {Create the table }
        Result := Result + indent + Format(CREATE_TBL, [FullName]) + ENDLINE;
	end
    else
        {Create the table if not exists}
        Result := Result + indent + Format(CREATE_TBL_IF_NOT_EXISTS, [FullName]) + ENDLINE;

    {CREATE FIELDS}
    for i := 0 to Count - 1 do
    begin
        _sql:= myList.Items[i].getCreateSQL(indent + DEFAULT_INDENT);
        if _sql.IsEmpty then
            continue {skip}
		else
        begin
            if addComma then
                Result := Result + COMMA + ENDLINE
            else
                addComma := True;
            Result := Result + _sql;
		end;
	end;

    {PRIMARY KEY}
    if PK.Count > 0 then
    begin
        {because autoincrement is embedded into the
         dtSerial statement for SQLite}
        if TARGETDB <> SQLiteDB then
        begin
            if addComma then
                Result := Result + COMMA + ENDLINE;

            Result := Result + indent + DEFAULT_INDENT +
                Format(PRIMARY_KEY_DEF, [PK.CommaText]);
		end;
	end;


    {FOREIGN KEY}
    if References.Count > 0 then
    begin
        if addComma then
            Result := Result + COMMA + ENDLINE;

        addComma := false; {initialize before next loop}
        for i := 0 to FForeignKeys.Count - 1 do
        begin
            if addComma then
                Result := Result + COMMA + ENDLINE
            else
                addComma := true;

            fk := DField(FForeignKeys.Items[i]);
            Result :=   Result + indent + DEFAULT_INDENT +
                        Format(FOREIGN_KEY_DEF,[
                            fk.Name,
                            fk.ReferenceTable,
                            fk.ReferenceField
                        ]);

            if fk.shouldCascadeDeletes then
                Result:= Result + ' ON DELETE CASCADE';

            if fk.shouldCascadeUpdates then
                Result:= Result + ' ON UPDATE CASCADE';

        end;
    end;

    Result := Result + ');' + ENDLINE + ENDLINE;
    // Writeln('Generated ', FullName);
except
    on E:Exception do
    begin
        // log('DTable.getCreateSQL error: %s', [E.Message]);
	end;
end;
end;

{Auto free the querybuilder object}
function DTable.getSQLFor(qb: RbQueryBuilderBase): string;
var
    _names: TStringList;
    _columns: TStringList;
    i: integer;
begin
    with qb do
    begin
        _names := TStringList.Create;
        _columns := TStringList.Create;

        _names.Add(Name);
        {table name};
        for i := 0 to Count - 1 do
        begin
            columns.Add(Items[i].Name);
        end;

        tables(_names);
        columns(_columns);

        {Update SQL}
        Result := sql;

        _columns.Free;
        _names.Free;
        Free;
    end;

end;

procedure DTable.setArchiveEnabled(const _ArchiveEnabled: boolean);
begin
    if myArchiveEnabled = _ArchiveEnabled then
        Exit;
    myArchiveEnabled := _ArchiveEnabled;
end;

procedure DTable.setDraftEditsEnabled(const _DraftEditsOn: boolean);
begin
    if myDraftEditsEnabled = _DraftEditsOn then
        Exit;
    myDraftEditsEnabled := _DraftEditsOn;
end;

procedure DTable.setEnableJournal(const _EnableJournal: boolean);
begin
    if myJournalEnabled = _EnableJournal then
        Exit;
    myJournalEnabled := _EnableJournal;
end;

function DTable.getUpdateSQL(indent: string): string;
begin
    Result := getSQLFor(RbUpdateQueryBuilder.Create);
end;

function DTable.getDeleteSQL(indent: string): string;
begin
    Result := getSQLFor(RbDeleteQueryBuilder.Create);
end;

function DTable.getAlterTableSQL(indent: string): string;
begin
    Result := indent + '/* ### ' + 'ALTER TABLE ' + UpperCase(FullName) + ' ### */' + ENDLINE;



end;

function DTable.getJSON(indent: string): string;
begin
    Result := inherited getJSON(indent);
end;

function DTable.BuildFromJSON(_json: string): boolean;
begin
    Result := inherited BuildFromJSON(_json);
end;

function DTable.field(const _index: integer): DField;
begin
    Result := nil;
    if (_index > -1) and (_index < Count) then
        Result := myList.Items[_index];
end;

function DTable.field(const _name: string): DField;
begin
    Result := field(find(_name));
end;

function DTable.ftsFields(const _fields: array of string): DTable;
var
    _name: string;
begin
    Result:= Self;
    for _name in _fields do
        FFullTextSearchFields.add(_name, field(_name));

end;

function DTable.ftsFields(const _fields: string; _delim: string): DTable;
begin
    Result:= ftsFields(toStringArray(_fields, _delim));
end;

function DTable.ftsFields: DFields;
begin
    Result:= FFullTextSearchFields;
end;

function DTable.defaultRow: TDynaJSONObject;
var
	i: Integer;
	_fld: DField;
    function defaultValue_str: string;
    begin
        Result:= _fld.DefaultValue;
	end;

    function defaultValue_int: LongInt;
    begin
        Result:= 0;
        if not _fld.DefaultValue.IsEmpty then
            try
                Result:= strToInt(_fld.DefaultValue);
			except
                ; {do nothing}
			end;
	end;

    function defaultValue_int64: Int64;
    begin
	    Result:= 0;
	    if not _fld.DefaultValue.IsEmpty then
	        try
	            Result:= StrToInt64(_fld.DefaultValue);
			except
	            ; {do nothing}
			end;
	end;

    function defaultValue_real : double;
    begin
	    Result:= 0;
	    if not _fld.DefaultValue.IsEmpty then
	        try
	            Result:= StrToFloat(_fld.DefaultValue);
			except
	            ; {do nothing}
			end;

	end;

    function defaultValue_bool : boolean;
    begin
	    Result:= false;
	    if not _fld.DefaultValue.IsEmpty then
	        try
	            Result:= StrToBool(_fld.DefaultValue);
			except
	            ; {do nothing}
			end;

	end;

    function defaultValue_jsonArray: TJSONArray;
    var
        done: boolean = false;
    begin
        if not _fld.DefaultValue.isEmpty then
        begin
            try
                Result:= fpjson.GetJSON(_fld.DefaultValue, true) as TJSONArray;
                done:= true;
			except
                ; // do default
			end;
		end;

        if not done then
            Result:= TJSONArray.Create;
	end;

    function defaultValue_jsonObject: TJSONObject;
    var
        done: boolean = false;
    begin
        if not _fld.DefaultValue.isEmpty then
        begin
            try
                Result:= fpjson.GetJSON(_fld.DefaultValue, true) as TJSONObject;
                done:= true;
			except
                ; // do default
			end;
		end;

        if not done then
            Result:= TJSONObject.Create;
    end;

    function defaultValue_jsMap: TJSONObject;
    var
        done: boolean = false;
    begin
        if not _fld.DefaultValue.isEmpty then
        begin
            try
                Result:= fpjson.GetJSON(_fld.DefaultValue, true) as TJSONObject;
                done:= true;
			except
                ; // do default
			end;
		end;

        if not done then
            Result:= TJSONObject.Create;
    end;

begin
    Result:= TDynaJSONObject.Create;
    for i:= 0 to Pred(Count) do
    begin
        _fld:= field(i);
        // log('DTable.newRowJSONObject() table= "%s" field="%s"',[name, _fld.Name]);
        case _fld.DataType of
            dtUnknown:
              Result.Add(_fld.Name, 'unknown');

            dtBit, dtInteger, dtSmallInt:
              Result.Add(_fld.Name, defaultValue_int);

            dtBigInt:
                Result.Add(_fld.Name, TJSONInt64Number.Create(defaultValue_int64));

            dtWord, dtDWord, dtQWord:
              Result.Add(_fld.Name, TJSONQWordNumber.Create(defaultValue_int64));

            dtReal, dtSingle, dtDouble, dtNumeric, dtMoney:
              Result.Add(_fld.Name,TJSONFormatedFloat.Create(defaultValue_real));

            dtChar, dtVarchar, dtString, dtText:
              Result.Add(_fld.Name, defaultValue_str);

            dtWideString:
              Result.Add(_fld.Name, TJSONUnicodeStringType(defaultValue_str));

            dtDate, dtTime, dtDateTime, dtTimestamp:
              Result.Add(_fld.Name, htmlDateTime(0));

            dtBoolean:
              Result.Add(_fld.Name, defaultValue_bool);

            dtEnum:
              Result.Add(_fld.Name, defaultValue_str);

            dtJSON:
              Result.Add(_fld.Name, defaultValue_str);

            dtJSONObject:
              Result.Add(_fld.Name, defaultValue_jsonObject);

            dtJSONArray:
              Result.Add(_fld.Name, defaultValue_jsonArray);

            dtJSMap:
              Result.Add(_fld.Name, defaultValue_jsMap);

            dtJSONB:
              Result.Add(_fld.Name, defaultValue_str);

            dtBinary:
              Result.Add(_fld.Name, 'binary');

            dtSerial, dtBigSerial:
              Result.Add(_fld.Name, defaultValue_int);

            dtUUID, dtXML:
              Result.Add(_fld.Name, 'uuid/xml');

            dtClass, dtObject, dtRecord:
              Result.Add(_fld.Name, TJSONObject.Create);

            dtInterface:
              Result.Add(_fld.Name, 'interface');

            dtPointer:
              Result.Add(_fld.Name, TJSONInt64Number.Create(0));

            dtMethodPointer:
              Result.Add(_fld.Name, TJSONInt64Number.Create(0));

            dtCustom:
              Result.Add(_fld.Name, 'custom_field');
        end;
	end;
    // log('Done -> newRowJSONObject()');
end;

function DTable.fieldExists(_name: string): boolean;
begin
    Result:= find(_name) >= 0;
end;


{ DField }

function DField.BuildFromJSON(_json: string): boolean;
begin
    Result := False;
end;

function DField.getJSON(indent: string): string;
var
    indent0: string;
    indent1: string;
    indent2: string;
begin
    indent0 := indent;
    indent1 := indent0 + DEFAULT_INDENT;
    indent2 := indent1 + DEFAULT_INDENT;

    indent := indent0;
    Result := indent + '{' + ENDLINE;

    indent := indent1;
    Result := Result + indent + Format('"%s" : "%s",',
        ['ddl_object', ClassName]) + ENDLINE;
    Result := Result + indent + '"properties" : {' + ENDLINE;

    indent := indent2;
    Result := Result + indent + Format(JSON_F, ['name', Name]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['comment', Comment]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['hint', Hint]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['description', Description]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['caption', Caption]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['field_type', 'TODO']);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['data_type', 'TODO']);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_D, ['size', Size]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['default_value', DefaultValue]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['is_null', 'TODO']);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['reference_table', ReferenceTable]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['reference_field', ReferenceField]);
    Result := Result + COMMA + ENDLINE;

    Result := Result + indent + Format(JSON_F, ['table', Table.FullName]);

    indent := indent1;
    Result := Result + ENDLINE + indent + '}';

    indent := indent0;
    Result := Result + ENDLINE + indent + '}';
end;

function DField.isText: boolean;
begin
    Result := DataType in [dtChar, dtVarchar, dtString, dtText];
end;

function DField.isWideString: boolean;
begin
    Result := DataType in [dtWideString];
end;

function DField.isNumber: boolean;
begin
    Result := DataType in [dtBit, dtInteger, dtSmallInt,
        dtBigInt, dtWord, dtDWord, dtQWord, dtReal, dtSingle,
        dtDouble, dtNumeric, dtMoney, dtSerial, dtBigSerial];
end;

function DField.isFloat: boolean;
begin
    Result := DataType in [dtReal, dtSingle, dtDouble, dtNumeric, dtMoney];
end;

function DField.isDate: boolean;
begin
    Result := DataType in [dtDate, dtTime, dtDateTime, dtTimestamp];
end;

function DField.isBoolean: boolean;
begin
    Result := (DataType = dtBoolean);
end;

function DField.isBinary: boolean;
begin
    Result := DataType in [dtJSONB, dtBinary, dtCustom];
end;

function DField.isStruct: boolean;
begin
    Result := DataType in [dtClass, dtObject, dtRecord, dtInterface];
end;

function DField.isPointer: boolean;
begin
    Result := DataType in [dtPointer, dtMethodPointer];
end;

function DField.getDataTypeName: string;
var
    datatypes: DDataTypes;
begin
    case TARGETDB of
        PostgresDB: datatypes := data_types_postgres;
        SQLiteDB: datatypes := data_types_sqlite;
    end;
    Result := Format(datatypes[DataType], [Size, Precision]);
end;

function DField.referredName: string;
begin
    Result := Table.Name + '_' + Name;
end;

function DField.fullName: string;
begin
    Result := Table.FullName + '.' + Name;
end;

function DField.Name(_value: string): DDLBase;
begin
	Result:=inherited Name(_value);
    if Assigned(FTable) then
        FTable.changeName(self, _value);
end;

function DField.Caption(_Caption: string): DField;
begin
    myCaption := _caption;
    Result := self;
end;

function DField.Caption: string;
begin
    Result := myCaption;
end;

function DField.Hint(_Hint: string): DField;
begin
    myHint := _hint;
    Result := self;
end;

function DField.Hint: string;
begin
    Result := myHint;
end;

function DField.isEnum: boolean;
begin
    Result := (FDataTypeCategory = dtcEnum);
end;

function DField.isJSON: boolean;
begin
    Result := DataType in [dtJSON, dtJSONArray, dtJSONObject, dtJSONB];
end;

function DField.isJSONArray: boolean;
begin
    Result := DataType in [dtJSONArray];
end;

function DField.isJSONObject: boolean;
begin
    Result := DataType in [dtJSONObject, dtJSMap];
end;

function DField.isListedFromTable: boolean;
begin
    Result:= (FDataTypeCategory = dtcListedFrom);
end;

function DField.Table(_value: DTable): DField;
begin
    if (FTable <> _value) then
        FTable := _value;
    Result := Self;
end;

function DField.Table: DTable;
begin
    Result := FTable;
end;

function DField.FieldType(_value: DFieldType): DField;
begin
    FFieldType := _value;
    Result := Self;
end;

function DField.FieldType: DFieldType;
begin
    Result := FFieldType;
end;

function DField.DataType(_value: DDataType; _chooseFrom: TStringArray): DField;
begin
    Result := Self;

    FDataType := _value;
    FChooseFrom := _chooseFrom;
    if isNumber then   FDataTypeCategory:= dtcNumeric
    else if isText then FDataTypeCategory := dtcText
    else if isBoolean then FDataTypeCategory := dtcBoolean
    else if isDate then FDataTypeCategory := dtcDate
    else if isBinary then FDataTypeCategory:= dtcBinary
    else if isPointer then FDataTypeCategory := dtcPointer
    else if isStruct then FDataTypeCategory := dtcStruct
    else FDataTypeCategory := dtcUndefined;
end;

function DField.DataType: DDataType;
begin
    Result := FDataType;
end;

function DField.DataTypeCategory(_value: DDataTypeCategory): DField;
begin
    FDataTypeCategory:=_value;
    Result := self;
end;

function DField.DataTypeCategory: DDataTypeCategory;
begin
    Result := FDataTypeCategory;
end;

function DField.RelationType(_value: DModelLinkType): DField;
begin
    FFieldRelation:= _value;
    Result:= self;
end;

function DField.RelationType: DModelLinkType;
begin
    Result := FFieldRelation;
end;

function DField.Size(_value: word): DField;
begin
    FSize := _value;
    Result := Self;
end;

function DField.Size: word;
begin
    Result := FSize;
end;

function DField.Precision(_value: word): DField;
begin
    FPrecision:=_value;
    Result:= self;
end;

function DField.Precision: word;
begin
    Result:= FPrecision;
end;

function DField.DefaultValue(_value: string): DField;
begin
    FDefaultValue := _value;
    Result := Self;
end;

function DField.DefaultValue: string;
begin
    Result := FDefaultValue;
end;

function DField.Null: DField;
begin
    FIsNull := True;
    Result := Self;
end;

function DField.NotNull: DField;
begin
    FIsNull := False;
    Result := Self;
end;

function DField.ReferenceTable(_name: string): DField;
begin
    FReferenceTable := _name;
    Result := Self;
end;

function DField.ReferenceTable: string;
begin
    Result := FReferenceTable;
end;

function DField.ReferenceField(_name: string): DField;
begin
    FReferenceField := _name;
    Result := Self;
end;

function DField.ReferenceField: string;
begin
    Result := FReferenceField;
end;

function DField.cascadeUpdates(_set: boolean): DField;
begin
    myCascadeUpdates:=_set;
    Result:= self;
end;

function DField.cascadeDeletes(_set: boolean): DField;
begin
    myCascadeDeletes:=_set;
    Result:= self;
end;

function DField.shouldCascadeUpdates: boolean;
begin
    Result:= myCascadeUpdates;
end;

function DField.shouldCascadeDeletes: boolean;
begin
    Result:= myCascadeDeletes;
end;

function DField.chooseFrom(_choosefrom: TStringArray): DField;
begin
    FChooseFrom := _choosefrom;
    Result := Self;
end;

function DField.chooseFrom(_choosefrom: array of string): DField;
begin
    copyStringArray(_chooseFrom, FChooseFrom);
    Result := self;
end;

function DField.chooseFrom(const _choosefrom: string; const _delim: string
	): DField;
begin
    Result := chooseFrom(toStringArray(_choosefrom))
end;

function DField.listFrom(const _listFields: array of DField;
	const _store: DField): DField;
var
    _field: DField;
begin
    DataTypeCategory(dtcListedFrom);
    FListFields.Clear;
    for _field in _listFields do
    begin
        FListFields.add(_field.Name, _field);
    end;
    FStoredField:= _store;
    Result := Self;
end;

function DField.listFrom(const _table: DTable;
	const _listFields: array of string; const _stored: string): DField;
var
    _field: string;
    _fldObj: DField;
begin
    FListFields.Clear;
    for _field in _listFields do
    begin
        _fldObj := _table.findObj(_field);
        if Assigned(_fldObj) then
            FListFields.add(_fldObj.Name, _fldObj);
	end;
    FStoredField:=_table.findObj(_stored);
    Result := Self;
end;

function DField.listFrom(const _table: DTable; const _listFields: string;
	const _store: string; const _delim: string): DField;
begin
    Result := listFrom(_table, toStringArray(_listFields,_delim), _store);
end;

function DField.chooseFrom: TStringArray;
begin
    Result := FChooseFrom;
end;

function DField.listFrom: DFields;
begin
    Result := FListFields;
end;

function DField.storedField: DField;
begin
    Result:= FStoredField;
end;

function DField.hashedIndex(_name: string): DField;
begin
    Result := self;
    Table.hashedIndex([Self], _name);
end;

function DField.btIndex(_indexType: DIndexType; _name: string;
	_collation: TIndexCollation; _order: string = ''): DField;
begin
    Result := Self;
    Table.btIndex([Self], _indexType, _name, _collation, _order);
end;

function DField.btIndexDesc(_indexType: DIndexType; _name: string;
	_collation: TIndexCollation; _order: string): DField;
begin
    Result := btIndex(_indexType, _name, _collation, _order);
end;

function DField.IsNull: boolean;
begin
    Result := FIsNull;
end;

function DField.required(const _value: boolean): DField;
begin
    case _value of
         True: Result := NotNull;
        False: Result := Null;
    end;
end;

function DField.unique(const _value: boolean): DField;
begin
    Result := Self;
    FIsUnique:= _value;
end;

function DField.unique: DField;
begin
    Result := unique(true);
end;

function DField.notUnique: DField;
begin
    Result := unique(false);
end;

function DField.isUnique: boolean;
begin
    Result := FIsUnique;
end;

function DField.Comment(_value: string): DDLBase;
begin
    inherited Comment(_value);
    Result := self;
end;

constructor DField.Create(_name: string);
begin
    inherited Create;
    Name(_name);
    Null;
    FieldType(ftData);
    DataType(dtInteger);
    Size(0);
    DefaultValue('');
    FListFields := DFields.Create(false); {Don't free the objects}
    myCascadeUpdates:= false;
    myCascadeDeletes:= false;
end;

destructor DField.Destroy;
begin
    FListFields.Free;
	inherited Destroy;
end;

function DField.getCreateSQL(indent: string): string;
begin
    Result := '';
    {Only render fields that are not calculated or undefined}
    if not (FieldType in [ftCalculated, ftUndefined]) then
    begin
        Result := indent + Format('%s %s', [Name, getDataTypeName]);

        if FIsUnique then
            Result := Result + ' UNIQUE';

        if not FIsNull then
            Result := Result + ' NOT NULL';

        if not DefaultValue.IsEmpty then
            Result := Result + ' DEFAULT ' + QUOTE_CHAR + DefaultValue + QUOTE_CHAR;
	end;
end;

function DField.getUpdateSQL(indent: string): string;
begin
    Result := 'FIELD UPDATESQL';
end;

function DField.getDeleteSQL(indent: string): string;
begin
    Result := 'FIELD DELETESQL';
end;

end.
