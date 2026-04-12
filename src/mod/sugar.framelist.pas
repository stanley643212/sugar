unit sugar.framelist;

{$mode ObjFPC}{$H+}

// PURPOSE:
//      To programmatically embedd frames in forms using the "class name" of the frame.
//      You can list available frames, programmatically and intantiate the one that the use has selected.

// This unit allows you to create a frame that
// is defined in this application by giving the
// Classname of the frame. The frame object is owned by
// the application. If you want to free the object
// manually, then it will remove references to the
// frame object from the internal map.

// To use this, you must first register your frames
// 1. include this unit in the frame unit
// 2. call RegisterFrame(<Your Frame Class>), in the initialization section  (for simplicity)

// Later, when you want to insert the frame in your forms
// you can simply call as in the example
//     panel1.InsertControl(getFrame('TCustomerFrame', 'Ashley93');

// Note:
//      1. If the frame has been named Ashley93 at the time of creation, then that object will be returned.
//      2. if there is no frame object with the supplied name, a new one will bcreated and assigned the name you have given
//      3. If you CHANGE the name of the frame after you have retrieved it, the change will NOT be reflected.
//          You won't be able to retrieve that frame object anymore. If you call getFrame() with the new name,
//          a NEW frame object will be created.


interface

uses
    Classes, SysUtils, Forms, fgl;

type
    TFrameClass = class of TFrame;
    EFrameFactoryError = class(Exception);

    procedure RegisterFrame(constref _frameClass: TFrameClass; const _comment: string = '');
    procedure RegisterFrame(const _frameClasses: array of TFrameClass; const _comments: TStringArray);

    function newFrame(const _frameClass: string): TFrame; // This does not enter the object in the interal list.
    function getFrame(const _frameClass: string; _frameName: string = ''): TFrame;
    function getFrameComment(const _frameClass: string): string;
    function getRegisteredFrames: TStringArray;

implementation

type

    TFrameFactory = class;

    { TFrameMap }
    // Map of FrameName -> FrameObject

    // Design Note: This map should be created with FreeObjects = false.
    // Reason: You want to be able to automatically remove references to the frame
    // from this map when it is freed by the program (FPObservedChanged)
    // So, then it become necessary do that is to then also createFrame with Application object owner
    // so that any unfreed frames will be removed when the Application object is destroyed.


    TFrameMap = class(specialize TFPGMapObject<string, TFrame>, IFPObserver)
        FrameClass: TFrameClass;
        function Get(const _frameName: string): TFrame; overload;
        function createFrame(_frameName: string): TFrame;
	public
		procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; _data: Pointer);
 end;

	{ TRegisteredFrames }
    // Map of FrameClassName -> Map of Frames
    TRegisteredFrames = class(specialize TFPGMapObject<string, TFrameMap>)
        frameFactory: TFrameFactory;
        function Get(const _frameClass: string): TFrameMap; overload;
	end;


	{ TFrameFactory }

    TFrameFactory = class(specialize TFPGMap<string, TFrameClass>)
    public
        function defined(const _frameClass: string): boolean;
    public
        constructor Create; reintroduce;
        destructor Destroy; override;
    end;

    TStringMap = class(specialize TFPGMap<string, string>);

var
    myFrameDescriptions : TStringMap;
    myFrameFactory : TFrameFactory = nil;
    myFrames: TRegisteredFrames = nil;

procedure RegisterFrame(constref _frameClass: TFrameClass; const _comment: string);
var
	_i: Integer;
begin
    _i := myFrameFactory.IndexOf(_frameClass.ClassName);
    if _i = -1 then
        myFrameFactory.Add(_frameClass.ClassName, _frameClass);

    _i := myFrameDescriptions.IndexOf(_frameClass.ClassName);
    if _i = -1 then
        myFrameDescriptions.Add(_frameClass.ClassName, _comment);
end;

procedure RegisterFrame(const _frameClasses: array of TFrameClass;
	const _comments: TStringArray);
var
    _i : integer = 0;
	_fc: TFrameClass;

    function getComment(_j: integer): string;
    begin
        if _j < Length(_comments) then
            Result := _comments[_j]
        else
            Result := '';
    end;

begin
    for _fc in _frameClasses do begin
        RegisterFrame(_fc, getComment(_i));
        inc(_i);
    end;
end;

function newFrame(const _frameClass: string): TFrame;
begin
    try
        Result := myFrameFactory.KeyData[_frameClass].Create(Application);
        Result.Name := '_' + GetTickCount.ToString;
	except
        raise EFrameFactoryError.Create(Format('FrameClass "%s" is not registered',[_frameClass]));
	end;
end;

function getFrame(const _frameClass: string; _frameName: string): TFrame;
begin
    {This will throw and exception if _frameclass or _framename are not found}
    if _frameName.isEmpty then
        _frameName := '_' + GetTickCount.ToString;
    Result := myFrames.Get(_frameClass).Get(_frameName);
end;

function getFrameComment(const _frameClass: string): string;
begin
    try
        Result := myFrameDescriptions.KeyData[_frameClass];
	except
        Result := '';
	end;
end;

function getRegisteredFrames: TStringArray;
var
	_i: Integer;
begin
    Result := [];
    SetLength(Result, myFrameFactory.Count);
    for _i := 0 to pred(myFrameFactory.Count) do begin
        Result[_i] := myFrameFactory.Keys[_i];
	end;
end;


{ TRegisteredFrames }

function TRegisteredFrames.Get(const _frameClass: string): TFrameMap;
var
	_i: Integer;
	_frameList: TFrameMap;
	_frameClassRef: TFrameClass;

begin
    _i := IndexOf(_frameClass);
    if _i > -1 then
        Result := Data[_i]
    else begin
        if Assigned(frameFactory) then begin
            try
                _frameClassRef := frameFactory.KeyData[_frameClass];
                if assigned(_frameClassRef) then begin
                    Result := TFrameMap.Create(false);
                    Result.FrameClass := _frameClassRef;
                    add(_frameClass, Result);
				end;
            except
                raise EFrameFactoryError.Create(Format('FrameClass "%s" is not registered',[_frameClass]));
			end;
		end
        else
            raise EFrameFactoryError.Create('FrameFactory Not assigned');
	end;
end;

{ TFrameFactory }

function TFrameFactory.defined(const _frameClass: string): boolean;
begin
    Result := IndexOf(_frameClass) > -1;
end;


constructor TFrameFactory.Create;
begin
    inherited Create;
end;

destructor TFrameFactory.Destroy;
begin
	inherited Destroy;
end;

{ TFrameList }

function TFrameMap.Get(const _frameName: string): TFrame;
var
	_i: Integer;
begin
    _i := IndexOf(_frameName);
    if _i > -1 then begin
        Result := KeyData[_frameName];
	end
    else begin
        if Assigned(FrameClass) then begin
            Result := createFrame(_frameName);
            add(_frameName, Result);
		end
        else
            Raise EFrameFactoryError.Create('Frameclass is not assigned');
	end;
end;

function TFrameMap.createFrame(_frameName: string): TFrame;
begin
    Result      := FrameClass.Create(Application);
    Result.Name := _frameName;
    Result.FPOAttachObserver(Self);
end;

procedure TFrameMap.FPOObservedChanged(ASender: TObject;
	Operation: TFPObservedOperation; _data: Pointer);
begin
    if ASender is TFrame then begin
	    case Operation of
	    	ooChange: ;
	        ooFree: begin
	            Remove(TFrame(ASender).Name);
			end;
	        ooAddItem: ;
	        ooDeleteItem: ;
	        ooCustom: ;
	    end;

	end;
end;

procedure initThis;
begin
    if not assigned(myFrameFactory) then begin
        myFrameFactory := TFrameFactory.Create;
        myFrameFactory.Sorted :=  True;
	end;

    if not assigned(myFrames) then begin
        myFrames := TRegisteredFrames.Create(True);
        myFrames.sorted := true;
        myFrames.frameFactory := myFrameFactory;
    end;

    if not assigned(myFrameDescriptions) then begin
        myFrameDescriptions := TStringMap.Create;
	end;

end;

procedure finalizeThis;
begin
    myFrameFactory.Free;
    myFrames.Free;
    myFrameDescriptions.Free;
end;



initialization
    initThis;

finalization
    finalizeThis;
end.

