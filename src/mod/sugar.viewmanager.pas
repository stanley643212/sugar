unit sugar.viewmanager;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, ExtCtrls, fgl, generics.Collections;

type
    NViewAlias = string;

    // IMPORTANT: To disable reference counting
    //-------------------------------------------------------------
    {$interfaces corba}
    //-------------------------------------------------------------

    // IEmbeddableView
    // To embed frames or panels or other targets into a gui container
    // Gives the container a way to control the insertion and removal of
    // frames without being aware of the actual class implementation.
    // Views (Forms or Frames) must implement IEmbeddableView
    // In embed(), they must take care of the housekeeping.
    //      - Forms can decide which of its child controls
    //        should be inserted as a control in the _container

    IEmbeddableView = interface
        function viewKind: byte;                            // Return the ord value of the enum NViewKind
        procedure embed(constref _container: TWinControl);  // Implement how the embedding happens.
        function isEmbedded: boolean;                       // the logic that indicates whether the object currently embedded
        function canRemove: boolean;                        // help container decide when it is safe to remove the view
        procedure remove;                                   // remove all controls from the container that were inserted in embed()
        function destruct: boolean;                         // Cleanup and call the destructor.

        procedure setAlias(_nviewAlias: NViewAlias);
        function alias: NViewAlias;
    end;

    PEmbeddableView = ^IEmbeddableView;
    EEmbeddableException = class(Exception); // Raise this exception when you need to inform the host about errors during embedding or removing

    TFrameclass  = class of TFrame;
    TViewFactory = function: IEmbeddableView;

    NViewKind = (
        vkForm,
        vkFrame,
        vkPanel,
        vkScrollBox
        );

    { TViewReference }

    TViewReference = record
        alias: string;
        instance: IEmbeddableView;
        factory: TViewFactory;
        viewKind: NViewKind;
        formClass : TFormClass;
        frameClass: TFrameClass;
    end;

    PViewReference = ^TViewReference;

    TViewReferenceList = class(specialize TFPGList<PViewReference>);

    { View Dictionary References }
    TViewAliasRef = class(specialize TDictionary<NViewAlias, PViewReference>);
    TViewClassRef = class(specialize TDictionary<TClass, NViewAlias>);

    { TViewRegistry }
    TViewRegistry = class
    private
        myViewReferenceList: TViewReferenceList;
        myViewByAlias : TViewAliasRef;
        myViewByType  : TViewClassRef;
    public
        constructor Create;
        destructor Destroy; override;
        procedure OnAppDestroy(Sender: TObject);

        function newViewReference: PViewReference;

        procedure registerView(const _nview: NViewAlias; constref _class: TFormClass;
            constref _factory: TViewFactory); overload;

        procedure registerView(const _nview: NViewAlias; constref _class: TFrameClass;
            constref _factory: TViewFactory); overload;

        function getView(const _nview: NViewAlias;
            _singleton: boolean = True): IEmbeddableView; overload;

        function isRegistered(const _nview: NViewAlias): boolean; overload;

        function isRegistered(constref _class: TFormClass): boolean; overload;
        function isRegistered(constref _class: TFrameClass): boolean; overload;

        function unRegister(const _nview: NViewAlias): boolean; overload;
        function unRegister(constref _class: TFormClass): boolean; overload;
        function unRegister(constref _class: TFrameClass): boolean; overload;

    end;


procedure registerView(const _nview: NViewAlias; constref _view: TFrameClass;
    constref _factory: TViewFactory); overload;
procedure registerView(const _nview: NViewAlias; constref _view: TFormClass;
    constref _factory: TViewFactory); overload;

function getView(const _nviewAlias: NViewAlias; _singleton: boolean = True): IEmbeddableView; overload;

function isEmbeddableView(const _form: TForm)  : boolean; overload;
function isEmbeddableView(const _frame: TFrame): boolean; overload;

function getViewKind(const _form: TForm)  : byte; overload;
function getViewKind(const _frame: TFrame): byte; overload;


implementation

uses
    TypInfo, sugar.logger;

var
    viewRegistry: TViewRegistry;
    myCriticalSection: TRTLCriticalSection;

procedure registerView(const _nview: NViewAlias; constref _view: TFrameClass;
	constref _factory: TViewFactory);
begin
    viewRegistry.registerView(_nView, _view, _factory);
end;

procedure registerView(const _nview: NViewAlias; constref _view: TFormClass;
	constref _factory: TViewFactory);
begin
    viewRegistry.registerView(_nView, _view, _factory);
end;

function getView(const _nviewAlias: NViewAlias; _singleton: boolean
	): IEmbeddableView;
begin
    Result := viewRegistry.getView(_nviewAlias, _singleton);
end;


function isEmbeddableView(const _form: TForm): boolean;
begin
    Result := _form is IEmbeddableView;
end;

function isEmbeddableView(const _frame: TFrame): boolean;
begin
    Result := _frame is IEmbeddableView;
end;

function getViewKind(const _form: TForm): byte;
begin
    Result := ord(vkForm);
end;

function getViewKind(const _frame: TFrame): byte;
begin
    Result := ord(vkFrame);
end;

{ TViewRegistry }

constructor TViewRegistry.Create;
begin
    inherited;
    myViewReferenceList := TViewReferenceList.Create;
    myViewByAlias := TViewAliasRef.Create;
    myViewByType := TViewClassRef.Create;
end;

destructor TViewRegistry.Destroy;
var
    i: integer;
begin
    for i := 0 to pred(myViewReferenceList.Count) do
    begin
        try
            //if myViewReferenceList.Items[i]^.instance <> nil then
            //    myViewReferenceList.Items[i]^.instance.destruct;
        except
            On E: Exception do
                log('TViewRegistry.Destroy:: Exception : %s', [E.Message]);
        end;
        Dispose(myViewReferenceList.Items[i]);
    end;
    myViewReferenceList.Free;

    myViewByAlias.Free;
    myViewByType.Free;

    inherited Destroy;
end;

procedure TViewRegistry.OnAppDestroy(Sender: TObject);
begin
    Free;
end;

function TViewRegistry.newViewReference: PViewReference;
var
    _pviewRef: PViewReference;
begin
    New(Result);
    myViewReferenceList.add(Result);
    Result^.alias := '';
    Result^.factory := nil;
    Result^.formClass := nil;
    Result^.frameClass := nil;
    Result^.instance := nil;
    Result^.viewKind := vkForm;
end;

procedure TViewRegistry.registerView(const _nview: NViewAlias;
    constref _class: TFormClass; constref _factory: TViewFactory);
var
    _pViewRef: PViewReference;
begin
    EnterCriticalSection(myCriticalSection);
    try
        if not assigned(_factory) then
            raise Exception.Create(
                'registerView():: We need a valid view factory (TViewFactory) to register this view');

        if myViewByAlias.ContainsKey(_nview) then _pviewRef := myViewByAlias.Items[_nview]
        else
            _pviewRef := newViewReference;

        _pviewRef^.alias     := _nview;
        _pviewRef^.viewKind  := vkForm;
        _pviewRef^.formClass := _class;
        _pviewRef^.factory   := _factory;

        //myViewByAlias.AddOrSetValue(_nview, _pViewRef);
        myViewByAlias.AddOrSetValue(_nview, _pViewRef);
        myViewByType.AddOrSetValue(_class, _nView);


    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;

procedure TViewRegistry.registerView(const _nview: NViewAlias;
    constref _class: TFrameClass; constref _factory: TViewFactory);
var
    _pviewRef: PViewReference;
begin
    EnterCriticalSection(myCriticalSection);
    try
        if not assigned(_class) then
            raise Exception.Create(
                'registerView():: Missing Class: We need a valid view type class to register this view');

        if not assigned(_factory) then
            raise Exception.Create(
                'registerView():: Missing Factory: We need a valid view factory (TViewFactory) to register this view');

        if myViewByAlias.ContainsKey(_nview) then _pviewRef := myViewByAlias.Items[_nview]
        else
            _pviewRef := newViewReference;

        _pviewRef^.alias      := _nView;
        _pviewRef^.viewKind   := vkFrame;
        _pviewRef^.frameClass := _class;
        _pviewRef^.factory    := _factory;

        myViewByAlias.AddOrSetValue(_nview, _pviewRef);
        myViewByType.AddOrSetValue(_class, _nView);

    finally
        LeaveCriticalSection(myCriticalSection);
    end;

end;

function TViewRegistry.getView(const _nview: NViewAlias;
    _singleton: boolean): IEmbeddableView;
var
    _s: string = '';
    _viewRef: TViewReference;
    _pviewRef: PViewReference;
    _pView: PEmbeddableView;
begin
    EnterCriticalSection(myCriticalSection);
    try
        if not myViewByAlias.ContainsKey(_nview) then
        begin
            raise Exception.Create(
                'TViewRegistry.getView:: View ' + _nview + ' not registered'
            );
        end;

        case _singleton of
            True:
            begin
                _pviewRef := myViewByAlias.Items[_nView];
                if not assigned(_pviewRef^.instance) then
                begin
                    Result := _pviewRef^.factory();
                    _pviewRef^.instance := Result;
                end
                else
                    Result := _pviewRef^.instance;

            end;
            False: Result := myViewByAlias.Items[_nView]^.factory();
        end;

        if assigned(Result) then
            Result.setAlias(_nview);

    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;


function TViewRegistry.isRegistered(const _nview: NViewAlias): boolean;
begin
    EnterCriticalSection(myCriticalSection);
    try
        Result := myViewByAlias.ContainsKey(_nview)
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;


function TViewRegistry.isRegistered(constref _class: TFormClass): boolean;
begin
    EnterCriticalSection(myCriticalSection);
    try
        Result := myViewByType.ContainsKey(_class);
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;

function TViewRegistry.isRegistered(constref _class: TFrameClass): boolean;
begin
    EnterCriticalSection(myCriticalSection);
    try
        Result := myViewByType.ContainsKey(_class);
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;

function TViewRegistry.unRegister(const _nview: NViewAlias): boolean;
var
    _ref: TViewReference;
begin
    Result := False;
    EnterCriticalSection(myCriticalSection);
    try
        if myViewByAlias.ContainsKey(_nview) then
        begin
            _ref := myViewByAlias.Items[_nView]^;
            case _ref.viewKind of
                vkForm: myViewByType.Remove(_ref.formClass);
                vkFrame: myViewByType.Remove(_ref.frameClass);
            end;
            myViewByAlias.Remove(_nView);
        end;
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;


function TViewRegistry.unRegister(constref _class: TFormClass): boolean;
var
    _nview: NViewAlias;
    _ref: TViewReference;
begin
    Result := False;
    EnterCriticalSection(myCriticalSection);
    try
        if myViewByType.ContainsKey(_class) then
        begin
            _nview := myViewByType.Items[_class];
            _ref := myViewByAlias.Items[_nView]^;
            myViewByAlias.Remove(_nView);
            myViewByType.Remove(_class);
            Result := True;
        end;
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;

function TViewRegistry.unRegister(constref _class: TFrameClass): boolean;
var
    _nview: NViewAlias;
    _ref: TViewReference;
begin
    Result := False;
    EnterCriticalSection(myCriticalSection);
    try
        if myViewByType.ContainsKey(_class) then
        begin
            _nview := myViewByType.Items[_class];
            _ref := myViewByAlias.Items[_nView]^;
            myViewByAlias.Remove(_nView);
            myViewByType.Remove(_class);
            Result := True;
        end;
    finally
        LeaveCriticalSection(myCriticalSection);
    end;
end;

initialization
    InitCriticalSection(myCriticalSection);
    viewRegistry := TViewRegistry.Create;

finalization
    viewRegistry.Free;
    DoneCriticalSection(myCriticalSection);
end.
