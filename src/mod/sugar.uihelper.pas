unit sugar.uihelper;
{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Controls, ComCtrls, ExtCtrls, StdCtrls, Graphics, Grids, Forms, Types ;

type
    EUIValidatorResult = (uivUnknown, uivOK, uivError, uivMissing, uivDefaultApplied);
    TUIValidator    = function:EUIValidatorResult of object;
    TArrayControl   = array of TControl;

    TUIState  = (uiDefault, uiHighlight, uiWarning, uiError, uiHover);

    { TOnHover }

    TOnHover = class(TPersistent, IFPObserver)
	private
        myDefaultColor: TColor;
		myOnHoverColor: TColor;
		procedure setonHoverColor(const _value: TColor);
		procedure setonHoverFont(const _value: TFont);
    protected
        myControl : TControl;
        prevOnMouseEnter: TNotifyEvent;
        prevOnMouseLeave: TNotifyEvent;
        myonHoverFont: TFont;
        myUseOnHoverFont: boolean;
        myDefaultFont : TFont;
        procedure assignPrevEventHandlers(_control: TControl);
    public
        procedure OnMouseEnter(Sender: TObject);
        procedure OnMouseLeave(Sender: TObject);
	public
		procedure FPOObservedChanged(ASender: TObject;
			Operation: TFPObservedOperation; Data: Pointer);
        destructor Destroy; override;
        constructor Create(_control: TControl); overload;

    public
        property onHoverFont: TFont read myonHoverFont write setonHoverFont;
        property onHoverColor: TColor read myonHoverColor write setonHoverColor;
    end;

	{ TOnAlign }

    TOnAlign = class(TPersistent, IFPObserver)
	private
		myprevParentResize: TNotifyEvent;
		mySize: currency;

		procedure setprevParentResize(const _value: TNotifyEvent);
		procedure setSize(const _value: currency);
	published
        parent: TControl;
        child : TControl;
        property prevParentResize: TNotifyEvent read myprevParentResize write setprevParentResize;
        property size: currency read mySize write setSize; // value less than 1 is treated as a percentage. values greater than one is treated as fixed size
        procedure OnResize(Sender: TObject); virtual;
        constructor Create(constref _child: TControl; _size: currency);
	public
		procedure FPOObservedChanged(ASender: TObject;
			Operation: TFPObservedOperation; Data: Pointer);
    end;

	{ TOnHAlign }

    TOnHAlign = class(TOnAlign)
        procedure OnResize(Sender: TObject); override;
    end;

	{ TOnVAlign }

    TOnVAlign = class(TOnAlign)
        procedure OnResize(Sender: TObject); override;
    end;


	{ TMouseWizard }
    // implements the mouse move handler. It moves the sender
    // when the user presses the keys/buttons defined in shiftState
    TMouseWizard = class
    private
		myenabled: boolean;
		myshiftState: TShiftState;
        myStarted: boolean;
        prevX, prevY: integer;
        currX, currY: integer;
		function getDeltaX: integer;
		function getDeltaY: integer;
		procedure setenabled(const _value: boolean);
		procedure setshiftState(const _value: TShiftState);
        function prep(Sender: TObject; Shift: TShiftState; X, Y: Integer): boolean; // Returns true if you can move the control
        function setCoordinates(X, Y: Integer): boolean;
        procedure moveControl(_control: TControl);
    public
        constructor Create;
        procedure reset;
        procedure Move (Sender: TObject; Shift: TShiftState; X, Y: Integer);
        procedure Move (_controls: TArrayControl; Shift: TShiftState; X, Y: Integer);
        property started: boolean read myStarted;
        property X: integer read currX;
        property Y: integer read currY;
        property deltaX : integer read getDeltaX;
        property deltaY : integer read getDeltaY;
        property enabled: boolean read myenabled write setenabled;
        property shiftState: TShiftState read myshiftState write setshiftState;
    end;

	{ TGlobalMouseWizard }
    {Works by following the mouse position across the whole desktop area.
     Not limited to the application screen. See mPoint()}
    TGlobalMouseWizard =  class
    protected
        form: TForm;
        prevMousePoint : TPoint;
        containerHOffset  : cardinal;
        containerVOffset  : cardinal;

    public
 	   function mPoint: TPoint;
 	   function mX: integer;
 	   function mY: integer;
       function deltaX: integer;
   	   function deltaY: integer;

 	   {These calculate the horizontal and vertical offset of the container }
       procedure reset;
       procedure initMouseDelta;

       function calcOffests(constref _container: TWinControl): TPoint;
 	   function calcHOffset(constref _container: TWinControl): integer;
 	   function calcVOffset(constref _container: TWinControl): integer;

       function move(constref _control: TControl; X: integer; Y: integer): TPoint;

    end;
    TOnCheckDragOver = procedure (Sender, Target: TTreeNode;  var Accept: Boolean; out _attachMode: TNodeAttachMode) of object;
    TOnNodeMoved = procedure (_sourceNode, _sourceParent, _destNode: TTreeNode; _attachMode: TNodeAttachMode) of object;
    {TTreeViewReorder}
    // Reorder items in a tree view by drag and drop
    TTreeViewReorder = class(TObject, IFPObserver)
    private
	    mydestNode: TTreeNode;
		mydragging: boolean;
		myOnCheckDragOver: TOnCheckDragOver;
		myOnNodeMoved: TOnNodeMoved;
		mysourceNode: TTreeNode;
        myTreeView: TTreeView;
        myOriginalTreeViewDragOver: TDragOverEvent;
        myOriginalTreeViewEndDrag: TEndDragEvent;
        myOriginalTreeViewSelectionChanged: TNotifyEvent;
	    procedure SetdestNode(const _value: TTreeNode);
	    procedure Setdragging(const _value: boolean);
		procedure setOnCheckDragOver(const _value: TOnCheckDragOver);
		procedure setOnNodeMoved(const _value: TOnNodeMoved);
	    procedure SetsourceNode(const _value: TTreeNode);
    protected
	   	procedure FPOObservedChanged(ASender: TObject;
	   		Operation: TFPObservedOperation; Data: Pointer);
        procedure OnDragOver(Sender, Source: TObject; X, Y: Integer;
      			State: TDragState; var Accept: Boolean);
        procedure OnEndDrag(Sender, Target: TObject; X, Y: Integer);
        procedure OnSelectionChanged(Sender: TObject);
    public
        constructor Create(constref _treeview: TTreeView);
        destructor Destroy; override;
        procedure releaseTreeView;

    protected
        property treeView: TTreeView read myTreeView;
        property dragging: boolean read mydragging write Setdragging;
        property sourceNode: TTreeNode read mysourceNode write SetsourceNode;
        property destNode: TTreeNode read mydestNode write SetdestNode;
    public
         property OnCheckDragOver: TOnCheckDragOver read myOnCheckDragOver write setOnCheckDragOver;
         property OnNodeMoved: TOnNodeMoved read myOnNodeMoved write setOnNodeMoved;

    end;

    // Sets the font color depending on the UIState
    procedure uiState(_c: TControl; _s: TUIState; _hint: string = '');
    procedure uiState(_arrc: array of TControl; _s: TUIState; _hint: string = '');


    procedure setHover(constref _lbl: TLabel; constref _hoverFont: TFont = nil; _hoverColor:TColor = clHighlight); overload;
    procedure setHover(constref _pnl: TPanel; constref _hoverFont: TFont = nil; _hoverColor:TColor = clHighlight); overload;
    procedure uiShake(constref _c: TControl);

    // extracts a real value from the edit box. if it is not a real value, it returns the default value
    function realVal(constref _c: TWinControl; const _default: real = 0.0): real;
    function intVal (constref _c: TWinControl; const _default: integer = 0): integer;

    // Converts and sets values to the edit control
    procedure setVal(constref _c: TWinControl; const _value: integer); overload;
    procedure setVal(constref _c: TWinControl; const _value: double); overload;
    procedure setVal(constref _c: TWinControl; const _value: double; _format: TFormatSettings); overload;
    function  numAsStr(const _val: integer): string; overload;
    function  numAsStr(const _val: double; _precision: word = 2): string; overload;
    function  numAsStr(const _val: double; _format: TFormatSettings): string; overload;


    // Visual indication of the control when it enters;
    procedure onControlFocus(Sender:TObject);
    procedure onControlExit(Sender: TObject);

    // Only permits valid float value input
    procedure KeyDownFloatValues(Sender: TObject; var Key: Word; Shift: TShiftState);

    function gridSort(constref sg: TStringGrid; _cols: array of integer; _order: TSortOrder = soAscending): TStringGrid;
    procedure resizeGridCols(constref _grid: TStringGrid; _arrWidths: array of byte);  overload; // resizes the grid according to the percentages in the array

    function getCurrentWord(_memo: TMemo): string;
    procedure positionAbove(constref _anchor: TControl; constref _child: TControl);
    procedure positionBelow(constref _anchor: TControl; constref _child: TControl);

    {Aligns the _control in its parent as a percentage of the parent's width when the size value is less than 1.
    When the value is greater than 1, then it the size is fixed to the value supplied }
    procedure alignVCenter(constref _child: TControl; _height: currency = 0.7); // Aligns the panel to the center of the container. Preserves the width of the panel
    procedure alignHCenter(constref _child: TControl; _width: currency = 0.7); // Aligns the panel to the center of the container. Preserves the width of the panel
    procedure alignCenter(constref _child: TControl; _width: currency = 0.7; _height: currency = 0.7);  // Aligns the panel to the center of the container. Preserves the width of the panel

    function enableReorder(constref _treeView: TTreeView): TTreeViewReorder;

//type
//    {Fields}
//    TUIField = class
//     published
//        property control          : TWinControl;
//        property captionControl   : TLabel;
//        property Name: string;  // Name of the field
//        property Value: variant read getValue write setValue;       // Stored value
//        property uiValue: variant read getUIValue write setUIValue; // Value in the UI Component
//        property Caption: TCaption read getCaption write setCaption;
//     public
//        function undo: boolean;
//        function redo: boolean;
//        function historyVal(_hist: integer): variant;
//        function historyCount: integer;
//        function commit: boolean;
//        function rollback: boolean;
//     end;
//
//    generic TUIControlField<TC: TControl> = class(TUIField)
//	end;

    {Make the hint visible programatically}
    procedure activateHint(_ctr: TControl);

    {TStringGrid export functions}
    //function gridHeaderToCSV(_grid: TStringGrid; _delimiter: string = ','): string;
    function gridToCSV(_grid: TStringGrid; _delimiter: string = ','): string;
    function gridToKV(_grid: TStringGrid; _delimiter: string = '='; _keyCol: integer = 0; _valCol: integer = 1): string;
    function setRowCount(constref _stringGrid: TStringGrid; const _rowCount: integer): TStringGrid;
    procedure gridColumnAutosize(constref _grid: TStringGrid);


    {Returns the height of the window bar}
    function windowBarHeight(_form: TForm) : integer;

    {Creates a placeholder for the control. Primarily to take up the place of the control. It makes a copy of the
     controls dimensions and alignment}
    function makeProxy (_ctr: TControl): TLabel;
    function makeBitmap(_ctr: TControl): TBitmap;

    function isParent(_container: TControl; _control: TControl): Boolean;

    function textPadding(constref _canvas: TCanvas): TSize;
    function calcTextHeight(_canvas: TCanvas; const _s: string; _wrapWidth: Integer): Integer;

    {Resizes the grid row to create text-wrapping effect.
     Call this in TStringGrid.OnPrepareCanvas.
     This is most efficiet if it is called once per row, (not for every column)}
    function gridRowTextWarp(constref sg: TStringGrid; const aCol, aRow: integer; _padding: integer = 12): integer; // returns the row height that was set;

    {FROM: https://forum.lazarus.freepascal.org/index.php?topic=50167.0}
    function lighten(AColorA: TColor; APercent: Int16): TColor;
    function combineColors(AColorA, AColorB: TColor; APercent: UInt16): TColor;
    procedure combineImages(AImageA, AImageB, AImageDest: TPortableNetworkGraphic; ALevel, AScale: UInt8);




implementation
uses
    LCLType, LCLIntf, sugar.utils, sugar.collections, sugar.sort, Math, sugar.logger;


function newHoverHandler(constref _control: TControl; constref _hoverFont: TFont; _hoverColor: TColor): TOnHover;
begin
    Result := TOnHover.Create(_control);
    if assigned(_hoverFont) then
        Result.onHoverFont.Assign(_hoverFont);
    Result.onHoverColor:= _hoverColor;
end;

procedure setHover(constref _lbl: TLabel; constref _hoverFont: TFont;
	_hoverColor: TColor);
var
	_hoverHandler: TOnHover;
begin
    _hoverHandler     := newHoverHandler(TControl(_lbl), _hoverFont, _hoverColor);
    _lbl.OnMouseEnter := @_hoverHandler.OnMouseEnter;
    _lbl.OnMouseLeave := @_hoverHandler.OnMouseLeave;
end;

procedure setHover(constref _pnl: TPanel; constref _hoverFont: TFont;
	_hoverColor: TColor);
var
	_hoverHandler: TOnHover;
begin
    _hoverHandler     := newHoverHandler(TControl(_pnl), _hoverFont, _hoverColor);
    _pnl.OnMouseEnter := @_hoverHandler.OnMouseEnter;
    _pnl.OnMouseLeave := @_hoverHandler.OnMouseLeave;
end;

procedure uiShake(constref _c: TControl);
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

procedure TOnHover.setonHoverColor(const _value: TColor);
begin
	if myonHoverColor=_value then Exit;
	myonHoverColor:=_value;
end;

procedure TOnHover.setonHoverFont(const _value: TFont);
begin

    if assigned(_value) then begin
        myOnHoverFont.Assign(_value);
        myUseOnHoverFont := true;
	end
    else
        myUseOnHoverFont := false;

end;

procedure TOnHover.assignPrevEventHandlers(_control: TControl);
begin
    if (_control is TLabel) then
    begin
        prevOnMouseEnter:= TLabel(_control).OnMouseEnter;
        prevOnMouseLeave:= TLabel(_control).OnMouseLeave;
        exit;
	end;

    if  (_control is TPanel) then begin
        prevOnMouseEnter:= TPanel(_control).OnMouseEnter;
        prevOnMouseLeave:= TPanel(_control).OnMouseLeave;
        exit;
    end;

    if  (_control is TEdit) then begin
        prevOnMouseEnter:= TEdit(_control).OnMouseEnter;
        prevOnMouseLeave:= TEdit(_control).OnMouseLeave;
        exit;
    end;

end;

procedure TOnHover.OnMouseEnter(Sender: TObject);
var
	_lbl: TLabel;
    _pnl: TPanel;
    _hoverFont : TFont;
begin

    {Initialize the CURRENT font settings}
    myDefaultColor := myControl.Color;
    myDefaultFont.Assign(myControl.Font);

    _hoverFont := TFont.Create;
    try
	    case myUseOnHoverFont of
	    	True    : begin
	            _hoverFont.Assign(myonHoverFont);
			end;

	        False   : begin
	            _hoverFont.Assign(myDefaultFont);
	            _hoverFont.Color := myonHoverColor;
	            _hoverFont.Style := myOnHoverFont.Style + [fsUnderline];
			end;
	    end;

	    if Sender is TPanel then
	    begin
	        _pnl := Sender as TPanel;
	        _pnl.Color:= myOnHoverColor;
		end
	    else if Sender is TLabel then begin
	        _lbl := Sender as TLabel;
	        _lbl.Font.Assign(_hoverFont);
		end;

	    if Sender is TControl then begin
            TControl(Sender).Cursor:= crHandPoint;
		end;

	    if assigned(prevOnMouseEnter) then prevOnMouseEnter(Sender);

	finally
        _hoverFont.Free;
	end;



end;

procedure TOnHover.OnMouseLeave(Sender: TObject);
var
	_lbl: TLabel;
    _pnl: TPanel;
begin
    if Sender is TPanel then
    begin
        _pnl := Sender as TPanel;
        _pnl.Color:= myDefaultColor;
	end
    else if Sender is TLabel then
    begin
        _lbl := Sender as TLabel;
        _lbl.Font.Assign(myDefaultFont);
	end;

    if Sender is TControl then begin
	    with Sender as TControl do begin
	        Cursor     := crDefault;
		end;
	end;

    if assigned(prevOnMouseLeave) then prevOnMouseLeave(Sender);
end;

procedure TOnHover.FPOObservedChanged(ASender: TObject;
	Operation: TFPObservedOperation; Data: Pointer);
begin
    case Operation of
    	ooChange: ;
        ooFree: Free;
        ooAddItem: ;
        ooDeleteItem: ;
        ooCustom: ;
    end;
end;

destructor TOnHover.Destroy;
begin
    myDefaultFont.Free;
    myOnHoverFont.Free;
	inherited Destroy;
end;

constructor TOnHover.Create(_control: TControl);
begin
    inherited Create;
    myControl     := _control;
    myDefaultFont := TFont.Create;
    myOnHoverFont := TFont.Create;
    myonHoverColor:= clHighlight;
    myUseOnHoverFont := false;

    assignPrevEventHandlers(_control);
    myDefaultFont.Assign(_control.Font);
    myOnHoverFont.Assign(_control.Font);

    _control.FPOAttachObserver(self);
end;


{ TOnAlign }

procedure TOnAlign.setprevParentResize(const _value: TNotifyEvent);
begin
	if myprevParentResize=_value then Exit;
	myprevParentResize:=_value;
end;

procedure TOnAlign.setSize(const _value: currency);
begin
	if mySize=_value then Exit;
	mySize:=_value;
end;


procedure TOnAlign.OnResize(Sender: TObject);
begin
    try
    if assigned(prevParentResize) then
        prevParentResize(parent);

	except
        On E: Exception do begin
            Log('TOnAlign.OnResize:: Exception -> %s', [E.Message]);
		end;
	end;
end;


constructor TOnAlign.Create(constref _child: TControl; _size: currency);
begin
    inherited Create;

    child           := nil;
    parent          := nil;
    prevParentResize:= nil;

    if not assigned(_child) then begin
        Trip(ClassName + '.Create() --> child not assigned!!!');
    end;

    if not assigned(_child.parent) then begin
        Trip(ClassName + '.Create() --> exit parent not assigned!!!');
    end;

    child := _child;
    child.FPOAttachObserver(Self);
    size:= _size;

    if assigned(child.Parent) then begin
        parent := child.Parent;
        if assigned(parent) then begin
            if Assigned(parent.OnResize) then begin
                prevParentResize := parent.OnResize
		    end
            else
                prevParentResize := nil;

            parent.OnResize  := @OnResize;
            parent.OnResize(parent); // init
        end
		else
            prevParentResize := nil;
    end
	else
        parent := nil;

    Log2('TOnAlign.Create() done');

end;

procedure TOnAlign.FPOObservedChanged(ASender: TObject;
	Operation: TFPObservedOperation; Data: Pointer);
begin
    case Operation of
    	ooChange: ;
        ooFree: begin
            log2('TOnAlign.FPOObservedChanged -- ooFree');
            if assigned(parent) then
                if parent.OnResize = @OnResize then
                    parent.OnResize := prevParentResize;
            Free; // Destroy this object
		end;
        ooAddItem: ;
        ooDeleteItem: ;
        ooCustom: ;
    end;
end;

{ TOnHAlign }

procedure TOnHAlign.OnResize(Sender: TObject);
var
	_width: Integer;
begin
    inherited;
    if not (assigned(child) and assigned(parent)) then exit;

    if (size <= 0) or (Parent.Width <= 0) then
        Exit;

    if size > 1 then
        _width := Min(Round(size), Parent.Width)
    else
        _width := Floor(Parent.Width * size);

    if child.Align in [alNone, alCustom] then  begin
	    Child.Width := _width;
	    Child.Left  := (Parent.Width - Child.Width) div 2;
	    Child.Invalidate;
	end
    else begin
        Child.BorderSpacing.Left  := (Parent.Width - _width) div 2;
        Child.BorderSpacing.Right := Child.BorderSpacing.Left;
        Child.Invalidate;
	end;
end;

{ TOnVAlign }


procedure TOnVAlign.OnResize(Sender: TObject);
var
	_height: Integer;
begin
    inherited;
    if not (assigned(child) and assigned(parent)) then exit;

    // Validate inputs
    if (size <= 0) or (Parent.Height <= 0) then
        Exit;

    if size > 1 then
        _height := Min(Round(size), Parent.Height)
    else
        _height := Floor(Parent.Height * size);

    if child.Align in [alNone, alCustom] then  begin
        Child.Height := _height;
        Child.Top    := (Parent.Height - Child.Height) div 2;
        Child.Invalidate;
	end
    else begin
        Child.BorderSpacing.Top     := (Parent.Height- _height) div 2;
        Child.BorderSpacing.Bottom  := Child.BorderSpacing.Top;
        Child.Invalidate;
	end;
end;

{ TMouseWizard }

function TMouseWizard.getDeltaX: integer;
begin
    Result := currX - prevX;
end;

function TMouseWizard.getDeltaY: integer;
begin
    Result := currY - prevY;
end;

procedure TMouseWizard.setenabled(const _value: boolean);
begin
	if myenabled=_value then Exit;
	myenabled:=_value;
end;

procedure TMouseWizard.setshiftState(const _value: TShiftState);
begin
	if myshiftState=_value then Exit;
	myshiftState:=_value;
end;

function TMouseWizard.prep(Sender: TObject; Shift: TShiftState; X, Y: Integer
	): boolean;
begin
    Result := false;

    if not enabled then exit;

    if not (shiftState = Shift) then begin
        reset;
        exit;
	end;

    if Sender is TControl then begin
        Result := setCoordinates(X, Y);
	end;

end;

function TMouseWizard.setCoordinates(X, Y: Integer): boolean;
begin
    if not started then
    begin
    	prevX := X;
        prevY := Y;
        myStarted := true;
	end;
    currX := X;
    currY := Y;

    Result := started;

end;

procedure TMouseWizard.moveControl(_control: TControl);
begin
    with _control do begin
        if Align <> alNone then exit; // You can't move something that is aligned.
        Top  := Top  + deltaY;
	    Left := Left + deltaX;
	end;
end;

constructor TMouseWizard.Create;
begin
    currX:= 0; currY:= 0;
    prevX:= 0; prevY:= 0;
    shiftState := [ssLeft]; // Default behaviour. Moves when you hold down the left mouse button
    reset;
end;

procedure TMouseWizard.reset;
begin
    if myStarted then
        myStarted := false;
end;

procedure TMouseWizard.Move(Sender: TObject; Shift: TShiftState; X,
	Y: Integer);
begin
    if prep(sender, shift, x, y) then
        moveControl(TControl(Sender));
end;

procedure TMouseWizard.Move(_controls: TArrayControl; Shift: TShiftState; X,
	Y: Integer);
var
	ctrl: TControl;
begin
    if Length(_controls) = 0 then exit;

    for ctrl in _controls do begin
        if prep(ctrl, shift, x, y) then
            moveControl(ctrl);
	end;
end;

{ TGlobalMouseWizard }

function TGlobalMouseWizard.deltaX: integer;
var
    _currPoint : TPoint;
begin
    _currPoint := mPoint;
    Result := _currPoint.x - prevMousePoint.X; // determines whether it moved left or right
    prevMousePoint:= _currPoint;
end;

function TGlobalMouseWizard.deltaY: integer;
var
    _currPoint : TPoint;
begin
    _currPoint := mPoint;
    Result := _currPoint.Y - prevMousePoint.Y; // determines if it moved up or down
    prevMousePoint:= _currPoint;
end;

procedure TGlobalMouseWizard.initMouseDelta;
begin
    prevMousePoint := mPoint; // stores the current mouse posioint
end;

function TGlobalMouseWizard.calcOffests(constref _container: TWinControl
	): TPoint;
begin
    containerHOffset  := calcHOffset(_container);
    containerVOffset  := calcVOffset(_container);
    Result := point(containerHOffset, containerVOffset);
end;

function TGlobalMouseWizard.mPoint: TPoint;
begin
    Result := Controls.Mouse.CursorPos;
end;

function TGlobalMouseWizard.mX: integer;
begin
    Result := Controls.Mouse.CursorPos.X;
end;

function TGlobalMouseWizard.mY: integer;
begin
    Result := Controls.Mouse.CursorPos.Y;
end;

function TGlobalMouseWizard.calcHOffset(constref _container: TWinControl
	): integer;
var
    _parent: TControl;
    _continue : boolean =  true;
begin
    Result  := _container.Left - (_container.BorderSpacing.Around + _container.BorderSpacing.Left);
    _parent := _container.Parent;
    while _continue do begin
        _continue := assigned(_parent);
        if _continue then begin
            _continue := (_parent is TForm);
            if _continue then begin
                // any additional adjustments
                if not assigned(form) then begin
                    form := TForm(_parent);
                    _continue := false;
				end;
			end;
            Result := Result - (_parent.Left + _parent.BorderSpacing.Around + _parent.BorderSpacing.Left);
            _parent := _parent.Parent;
		end;
	end;
end;

function TGlobalMouseWizard.calcVOffset(constref _container: TWinControl
	): integer;
var
    _parent: TControl;
    _continue: boolean =  true;
begin
    Result  := _container.Top - (_container.BorderSpacing.Around + _container.BorderSpacing.Top);
    _parent := _container.Parent;

    while _continue do begin
        _continue := assigned(_parent);
        if _continue then begin
            _continue := (_parent is TForm);
            if _continue then begin
                if not assigned(form) then begin
                    form := TForm(_parent);
                    _continue := false;
				end;
				Result := Result +  windowBarHeight(TForm(_parent));
			end;
            Result := Result + _parent.Top - (_parent.BorderSpacing.Around + _parent.BorderSpacing.Top);
            _parent := _parent.Parent;
		end;
	end;
end;

function TGlobalMouseWizard.move(constref _control: TControl; X: integer;
	Y: integer): TPoint;
var
    _newX, _newY: integer;
begin
    _newX := mX - containerHOffset;
    _newY := mY - containerVOffset;

    log(
    'TGlobalMouseWizard'                            + sLineBreak +
    '              move(x,y): (%d, %d):: '          + sLineBreak +
    '                 mx, my: (%d, %d) '            + sLineBreak +
    '           offset(h, v): (h: %d, v: %d) '      + sLineBreak +
    '     control(left, top): (left: %d, top: %d). '+ sLineBreak +
    '     NewPos(newX, newY): (%d, %d)',

                             [X, Y,
                             mx, my,
                             containerHOffset, containerVOffset,
                             _control.left, _control.top,
                             _newX, _newY]);
    log('');
    //_control.Left := _newX + 10;
    _control.Top  := _newY + 10;  {spacing below the cursor};
end;

procedure TGlobalMouseWizard.reset;
begin
    prevMousePoint    := Point(-99999, 99999);
    containerHOffset  := 0;
    containerVOffset  := 0;
end;

{ TTreeViewReorder }

procedure TTreeViewReorder.SetdestNode(const _value: TTreeNode);
begin
	if mydestNode=_value then Exit;
	mydestNode:=_value;
end;

procedure TTreeViewReorder.Setdragging(const _value: boolean);
begin
	if mydragging=_value then Exit;
	mydragging:=_value;
end;

procedure TTreeViewReorder.setOnCheckDragOver(const _value: TOnCheckDragOver);
begin
	if myOnCheckDragOver=_value then Exit;
	myOnCheckDragOver:=_value;
end;

procedure TTreeViewReorder.setOnNodeMoved(const _value: TOnNodeMoved);
begin
	if myOnNodeMoved=_value then Exit;
	myOnNodeMoved:=_value;
end;

procedure TTreeViewReorder.SetsourceNode(const _value: TTreeNode);
begin
	if mysourceNode=_value then Exit;
	mysourceNode:=_value;
end;

procedure TTreeViewReorder.FPOObservedChanged(ASender: TObject;
	Operation: TFPObservedOperation; Data: Pointer);
begin
    case Operation of
    	ooChange    : ;
        ooFree      : Free;
        ooAddItem   : ;
        ooDeleteItem: ;
        ooCustom    : ;
    end;
end;

procedure TTreeViewReorder.OnDragOver(Sender, Source: TObject; X, Y: Integer;
	State: TDragState; var Accept: Boolean);
 var
     _attachMode: TNodeAttachMode;
	 _sourceParent: TTreeNode;
begin
    if assigned(myOriginalTreeViewDragOver) then
        myOriginalTreeViewDragOver(Sender, Source, X, Y, State, Accept);

    if not Accept then exit; // If the original event rejects the drag over then respect that

    if not dragging then dragging := true;

    if not assigned(sourceNode) then sourceNode := TreeView.Selected;

    if not assigned(sourceNode) then begin // if source still not available
        dragging    := false;
        sourceNode  := nil;
        destNode    := nil;
        exit;
    end;

    destNode   := TreeView.GetNodeAt(X,Y);
    if assigned(destNode) then begin
        if ptrInt(destNode) <> ptrInt(sourceNode) then  begin

            if assigned(OnCheckDragOver) then
                OnCheckDragOver(sourceNode, destNode, Accept, _attachMode);

            if Accept then begin
                _sourceParent := sourceNode.Parent;  // parent before it was moved
                sourceNode.MoveTo(destNode, _attachMode);
                if assigned(OnNodeMoved) then
                    OnNodeMoved(sourceNode, _sourceParent, destNode, _attachMode);
			end;
		end;
	end;

end;

procedure TTreeViewReorder.OnEndDrag(Sender, Target: TObject; X, Y: Integer);
begin
    if dragging then begin
        dragging  := false;
        sourceNode:= nil;
        destNode  := nil;
    end;
    if assigned(myOriginalTreeViewEndDrag) then
        myOriginalTreeViewEndDrag(Sender, Target, X, Y);
end;

procedure TTreeViewReorder.OnSelectionChanged(Sender: TObject);
begin
    sourceNode := TreeView.selected;
    if assigned(myOriginalTreeViewSelectionChanged) then
        myOriginalTreeViewSelectionChanged(Sender);
end;

constructor TTreeViewReorder.Create(constref _treeview: TTreeView);
begin
    inherited Create;
    myTreeView := _treeview;
    myTreeView.FPOAttachObserver(self);

    myOriginalTreeViewDragOver:= TreeView.OnDragOver;
    myOriginalTreeViewEndDrag:= TreeView.OnEndDrag;
    myOriginalTreeViewSelectionChanged:= TreeView.OnSelectionChanged;

    TreeView.OnDragOver := @OnDragOver;
    TreeView.OnEndDrag  := @OnEndDrag;
    TreeView.OnSelectionChanged := @OnSelectionChanged;
    TreeView.DragMode := dmAutomatic;
end;

destructor TTreeViewReorder.Destroy;
begin
    releaseTreeView;
	inherited Destroy;
end;

procedure TTreeViewReorder.releaseTreeView;
begin
    TreeView.OnDragOver := myOriginalTreeViewDragOver;
    TreeView.OnEndDrag  := myOriginalTreeViewEndDrag;
    TreeView.OnSelectionChanged := myOriginalTreeViewSelectionChanged;
    myTreeView := nil;
end;

procedure uiState(_c: TControl; _s: TUIState; _hint: string);
begin
    //_c.Font.Style := _c.Font.Style - [fsBold];
    case _s of
    	uiDefault:   begin
            _c.Font.Color   := clDefault;
            if _c is TLabel then
                _c.color := clNone
            else
                _c.color := clDefault;
		end;

		uiHighlight: begin
            _c.Font.Color:= clHighlightText;

            if _c is TLabel then
                _c.color        := clNone
            else
                _c.color := clHighlight;
        end;

        uiWarning:   begin
            _c.Font.Color:= clPurple;
            if _c is TLabel then
                _c.color        := clNone
            else
                _c.color := clInfoBk;
		end;

		uiError:    begin
            _c.Font.Color := clRed;
            _c.Font.Style := _c.Font.Style; // + [fsBold];
            if _c is TLabel then
                _c.color        := clNone
            else
                _c.color := clInfoBk;
		end;
	end;
    _c.Hint:= _hint;
    _c.ShowHint:= not _hint.IsEmpty;
    _c.Invalidate;
end;

procedure uiState(_arrc: array of TControl; _s: TUIState; _hint: string);
var
	_c: TControl;
begin
    for _c in _arrc do begin
        uiState(_c, _s, _hint);
	end;
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
	    end
    else
        Result:= _default;
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
	    end
    else
        Result:= _default;

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

function numAsStr(const _val: double; _precision: word): string;
begin
    try
        Result:= format('%.*f', [_precision, _val]);
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

procedure KeyDownFloatValues(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if key in [
            VK_RETURN,
            VK_0..VK_9,
            VK_NUMPAD0..VK_NUMPAD9,
            VK_SUBTRACT,
            VK_OEM_PERIOD,
            VK_OEM_COMMA,
            VK_BACK,
            VK_DELETE,
            VK_LEFT,
            VK_RIGHT,
            VK_END,
            VK_HOME,
            VK_TAB
            ] then

            // Do nothing

    else
        Key := 0;

end;

type

    TListOfTStringsBase = specialize GenericHashObjectList<TStrings>;
    TListOfTStrings = class (TListOfTStringsBase)
    end;



function gridSort(constref sg: TStringGrid; _cols: array of integer; _order: TSortOrder = soAscending): TStringGrid;
const
  TERM_DELIM = '|';
  DELIM = '•';
var
    _rows   : TListOfTStrings;     // Maps of sort-term to STring Grid row object. This is used to reconstruct the sorted string grid.
	_r, _col: Integer;
    _sorted : TStringArray;
	_term, s: String;
    _delta  : integer;

begin
    Result := sg;

    if sg.FixedRows = sg.RowCount then exit; // No rows to sort.

    _rows   := TListOfTStrings.Create(true);

    try

        {EXTRACT ROWS (strings + objects) FROM THE GRID AS A LIST OF DELIMITED VALUE STRINGS}
        for _r := sg.FixedRows to pred(sg.RowCount) do
        begin
            _term := '';

            for _col in _cols do begin
                if not InRange(_col, 0, pred(sg.ColCount)) then continue;
                if not _term.isEmpty then _term := _term + TERM_DELIM;
                _term := _term + sg.Cells[_col, _r];
			end;
            // Append row number to the
			_term := Format('%s' + TERM_DELIM + '%d',[_term, _r]);
            _rows.add(_term, clone(sg.rows[_r]));
		end;

        _sorted := sortList(_rows.getNames(DELIM), DELIM);

        case _order of
            soAscending:  begin
                _r := sg.FixedRows;
                _delta := 1;
            end;
            soDescending: begin
                _r := pred(sg.RowCount);
                _delta := -1;
            end;
        end;

        sg.BeginUpdate;
        for s in _sorted do
        begin
            sg.Rows[_r].AddStrings(_rows.get(s), true); // This adds the objects as well
            _r := _r + _delta; {increments or decrements depending on sorting order}
		end;
        sg.EndUpdate;

	finally
        _rows.Free;
	end;
end;

procedure resizeGridCols(constref _grid: TStringGrid; _arrWidths: array of byte
	);
const
  __GRID_BUFFER = 4;
var
    _colCount: byte;
	_col: TGridColumn;
	_width, _i: Integer;
begin
    _colCount := Min(Length(_arrWidths), _grid.ColCount); // To loop over only the colums that are available.
    _width := _grid.Width - __GRID_BUFFER - GetSystemMetrics(SM_CXVSCROLL); // to prevent the scroll bar from showing;
    for _i := 0 to pred(_colCount) do begin
        //_col := _grid.Columns.Items[_i];
        //_col.Width:= trunc(_width * (_arrWidths[_i]/100));
        _grid.ColWidths[_i] := trunc(_width * (_arrWidths[_i]/100));
	end;
end;

function getCurrentWord(_memo: TMemo): string;
var
	_line, _col: LongInt;
    _startPos, _endPos: sizeInt;
begin
    _line  := _memo.CaretPos.Y;
    _col   := succ(_memo.CaretPos.X);
    Result := strBetween(_memo.Lines.Strings[_line], _col, __WHITESPACE, __WHITESPACE, _startPos, _endPos);
end;

procedure positionAbove(constref _anchor: TControl; constref _child: TControl);
var
	_t, _anchorTop: Integer;
begin
    _anchorTop := Min(0, _anchor.Top - _anchor.BorderSpacing.Around - _anchor.BorderSpacing.Top);
    if _anchorTop = 0 then begin
        _child.Top  := _child.BorderSpacing.Around + _child.BorderSpacing.Top;
        _anchor.Top := _anchor.BorderSpacing.Around + _anchor.BorderSpacing.Top + 1;
	end
    else begin
        _t := _anchor.Top;
        _anchor.Top := _t + 1;
        _child.Top  := _t;
	end;

    _child.Left  := _anchor.Left;
    _child.Width := _anchor.Width;

    if assigned(_child.Parent) then
        _child.Height:= _child.Parent.Height - _child.Top;

end;

procedure positionBelow(constref _anchor: TControl; constref _child: TControl);
begin
    _child.Top   := _anchor.Top + _anchor.Height + _child.BorderSpacing.Around + _child.BorderSpacing.Top;
    _child.Left  := _anchor.Left;
    _child.Width := _anchor.Width;

    if assigned(_child.Parent) then
        _child.Height:= _child.Parent.Height - _child.Top;
end;



procedure alignVCenter(constref _child: TControl; _height: currency);
begin
    TOnVAlign.Create(_child, _height);
end;

procedure alignHCenter(constref _child: TControl; _width: currency);
begin
    TOnHAlign.Create(_child, _width);
end;

procedure alignCenter(constref _child: TControl; _width: currency;
	_height: currency);
begin
    TOnVAlign.Create(_child, _width);
    TOnHAlign.Create(_child, _height);
end;

function enableReorder(constref _treeView: TTreeView): TTreeViewReorder;
begin
    Result := TTreeViewReorder.Create(_treeView); // Will automatically free :: IFPObserver
end;


procedure activateHint(_ctr: TControl);
var
    _point: TPoint;
begin
    if _ctr.ShowHint then begin
        _point.x := _ctr.left;
        _point.y := _ctr.top;
        Application.ActivateHint(_point);
    end;
end;

function gridHeaderToCSV(_grid: TStringGrid; _delimiter: string): string;
begin

end;

function gridToCSV(_grid: TStringGrid; _delimiter: string = ','): string;
var
	r: Integer;
    function rowAsCSV(_row: integer): string;
	var
		_c: Integer;
    begin
        _c := 0;
        if _c < _grid.ColCount then
            Result := _grid.Cells[_c, _row];

        for _c := 1 to pred(_grid.ColCount) do begin
            Result := Result + _delimiter + _grid.Cells[_c, _row];
		end;
	end;

begin
    Result := '';

    // first row
    r := 0;
    if r < _grid.RowCount then
        Result := rowAsCSV(r);

    for r := 1 to pred(_grid.RowCount) do begin
        Result := Result
                    + sLineBreak
                    + rowAsCSV(r);
	end;
end;

function gridToKV(_grid: TStringGrid; _delimiter: string = '='; _keyCol: integer = 0; _valCol: integer = 1): string;
const
    __F = '%s %s %s';
var
	r: Integer;
begin
    Result := '';
    if _grid.ColCount < 2 then exit;
    if _keyCol > _grid.ColCount then exit;
    if _valCol > _grid.ColCount then exit;

    // first row
    r := 0;
    if r < _grid.RowCount then
        Result := format(__F ,[_grid.Cells[_keyCol, r], _delimiter, _grid.Cells[_valCol, r]]);

    for r := 1 to pred(_grid.RowCount) do begin
        Result := Result
                    + sLineBreak
                    + format(__F ,[Trim(_grid.Cells[_keyCol, r]), _delimiter, Trim(_grid.Cells[_valCol, r])]);
	end;
end;

function setRowCount(constref _stringGrid: TStringGrid; const _rowCount: integer
	): TStringGrid;
begin
    Result := _stringGrid;
    _stringGrid.RowCount := _rowCount;
    _stringGrid.Height :=   (succ(_rowCount) * _stringGrid.DefaultRowHeight);
end;

procedure gridColumnAutosize(constref _grid: TStringGrid);
var
	i: Integer;
begin
    for i := 0 to pred(_grid.ColCount) do begin
        _grid.AutoSizeColumn(i);
        _grid.Columns.Items[i].Width:= _grid.Columns.Items[i].Width + 10;
	end;
end;

function windowBarHeight(_form: TForm): integer;
{https://www.tweaking4all.com/forum/delphi-lazarus-free-pascal/lazarus-pascal-determine-titlebar-height-crossplatform-quick-and-easy/}
var
  global_pos : TPoint;
begin
    global_pos := _form.ClientToScreen(Point (1,1));
    Result     := global_pos.Y - _form.Top;
end;

function makeProxy (_ctr: TControl): TLabel;
begin
    Result := TLabel.Create(Application);
    Result.Name     := '';
    Result.Alignment:= taCenter;
    Result.Caption  := '';
    Result.Layout   := tlCenter;
    Result.AutoSize := false;
    Result.Top      := Max(0, _ctr.Top-1);
    Result.Left     := _ctr.Left;
    Result.Height   := _ctr.Height;
    Result.Width    := _ctr.Width;
    Result.Align    := _ctr.Align;
end;

function makeBitmap(_ctr: TControl): TBitmap;
begin
    Result := TBitmap.Create;
    Result.Width  := _ctr.Width;
    Result.Height := _ctr.Height;

    if _ctr is TWinControl then
      (_ctr as TWinControl).PaintTo(Result.Canvas,0,0)
    else if _ctr is TGraphicControl then begin
        ; //_pnl := TPnl
	end;
end;

function isParent(_container: TControl; _control: TControl): Boolean;
const
    MAX_ITERATIONS = 30;
var
  i : integer = 0;
begin
    Result := false;
    while not Result and (i < MAX_ITERATIONS) do begin
        if not (assigned(_control) and assigned(_container)) then break;
        Result   := _container = _control.parent;
        _control := _control.Parent;
        inc(i);
	end;
end;

function textPadding(constref _canvas: TCanvas): TSize;
var
    LineH: Integer;
begin
      Result := _canvas.TextExtent('Hg');    // current DPI + current font
      Result.cy := Max(2, Result.cy div 6);  // ~16% of line height
      Result.cx := Max(2, Result.cx div 6);  // ~16% of line width
      // use PadY for vertical padding; for horizontal you can use LineH div 6 too
end;

function calcTextHeight(_canvas: TCanvas; const _s: string; _wrapWidth: Integer): Integer;
var
  _r :TRect;
  _flags: Longint;
begin
{
When you call DrawText() with the DT_CALCRECT flag, Windows/LCL does not paint anything.
Instead, it just measures how much space the text would take and updates the rectangle
you passed in (R).

So:
Flags := DT_WORDBREAK or DT_CALCRECT;
DrawText(Canvas.Handle, PChar(S), Length(S), R, Flags);


With DT_CALCRECT → no pixels are drawn, only R.Bottom/R.Right are adjusted.

Without DT_CALCRECT → actual painting happens into the canvas.

That’s why the height-calculation trick is safe inside OnPrepareCanvas:
it doesn’t interfere with the grid’s own painting cycle.

⚠️ Caveat for Lazarus: On GTK/Qt backends, the LCL implements DrawText itself
(not always the WinAPI call). But it mimics the Windows behavior: if DT_CALCRECT is present,
it only computes the bounding rect, not draw. So you won’t get phantom text painting.

}
  // Large bottom bound so DrawText can expand during DT_CALCRECT.
    _r := Rect(0, 0, Max(0, _wrapWidth), 100000);
    _flags := DT_WORDBREAK or DT_EDITCONTROL or DT_NOPREFIX or DT_CALCRECT;
    DrawText(_canvas.Handle, PChar(_s), Length(_s), _r, _flags);
    Result := _r.Bottom - _r.Top + textPadding(_canvas).cY;
end;

function gridRowTextWarp(constref sg: TStringGrid; const aCol, aRow: integer; _padding: integer): integer;
var
	_textStyle: TTextStyle;
	_cellText: String;
begin
    _textStyle := sg.Canvas.TextStyle;
    _cellText  := sg.Cells[aCol, aRow];
    if _cellText = '' then _cellText := 'Hg';// to simulate default row height
    _textStyle.SingleLine := false;
    _textStyle.Wordbreak  := true;
    sg.Canvas.TextStyle := _textStyle;
    Result := _padding + calcTextHeight(sg.Canvas,  _celltext, sg.ColWidths[ACol]);
    sg.RowHeights[aRow] := Result;
end;

function lighten(AColorA: TColor; APercent: Int16): TColor;
var
  ColorA, ColorDest: TRGBTriple;
begin
    try
	    RedGreenBlue(AColorA, ColorA.rgbtRed, ColorA.rgbtGreen, ColorA.rgbtBlue);
	    ColorDest.rgbtRed   := Max(0, Min(255, Round(ColorA.rgbtRed   + ColorA.rgbtRed   * 0.001 * APercent)));
	    ColorDest.rgbtGreen := Max(0, Min(255, Round(ColorA.rgbtGreen + ColorA.rgbtGreen * 0.001 * APercent)));
	    ColorDest.rgbtBlue  := Max(0, Min(255, Round(ColorA.rgbtBlue  + ColorA.rgbtBlue  * 0.001 * APercent)));
	    Result := RGBToColor(ColorDest.rgbtRed, ColorDest.rgbtGreen, ColorDest.rgbtBlue);

	except
        Result := clDefault;
	end;
end;


function CombineColors(AColorA, AColorB: TColor; APercent: UInt16): TColor;
var
  ColorA, ColorB, ColorDest: TRGBTriple;
begin
  RedGreenBlue(AColorA, ColorA.rgbtRed, ColorA.rgbtGreen, ColorA.rgbtBlue);
  RedGreenBlue(AColorB, ColorB.rgbtRed, ColorB.rgbtGreen, ColorB.rgbtBlue);

  ColorDest.rgbtRed   := Max(0, Min(255, Round(ColorA.rgbtRed   + (ColorB.rgbtRed - ColorA.rgbtRed)     * 0.001 * APercent)));
  ColorDest.rgbtGreen := Max(0, Min(255, Round(ColorA.rgbtGreen + (ColorB.rgbtGreen - ColorA.rgbtGreen) * 0.001 * APercent)));
  ColorDest.rgbtBlue  := Max(0, Min(255, Round(ColorA.rgbtBlue  + (ColorB.rgbtBlue - ColorA.rgbtBlue)   * 0.001 * APercent)));

  Result := RGBToColor(ColorDest.rgbtRed, ColorDest.rgbtGreen, ColorDest.rgbtBlue);
end;



procedure combineImages(AImageA, AImageB, AImageDest: TPortableNetworkGraphic; ALevel, AScale: UInt8);
type
  PPNGPixel = ^TPNGPixel;
  TPNGPixel = record B, G, R, A: UInt8; end;
type
  PPNGLine = ^TPNGLine;
  TPNGLine = array [UInt16] of TPNGPixel;
var
  LineA, LineB, LineDest: PPNGLine;
  PixelA, PixelB, PixelDest: PPNGPixel;
var
  LineIndex, PixelIndex: Integer;
begin
  AImageDest.BeginUpdate();
  try
    for LineIndex := 0 to AImageA.Height - 1 do
    begin
      LineA := AImageA.ScanLine[LineIndex];
      LineB := AImageB.ScanLine[LineIndex];
      LineDest := AImageDest.ScanLine[LineIndex];

      for PixelIndex := 0 to AImageA.Width - 1 do
      begin
        PixelA := @LineA^[PixelIndex];
        PixelB := @LineB^[PixelIndex];
        PixelDest := @LineDest^[PixelIndex];

        PixelDest^.R := Round(PixelA^.R + (PixelB^.R - PixelA^.R) / AScale * ALevel);
        PixelDest^.G := Round(PixelA^.G + (PixelB^.G - PixelA^.G) / AScale * ALevel);
        PixelDest^.B := Round(PixelA^.B + (PixelB^.B - PixelA^.B) / AScale * ALevel);
      end;
    end;
  finally
    AImageDest.EndUpdate();
  end;
end;

initialization
;

finalization
;

end.

