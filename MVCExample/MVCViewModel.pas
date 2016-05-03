/// ViewModel/Control interfaces for the MVCServer tabelaCom sample
unit MVCViewModel;
{$I Synopse.inc} // define HASINLINE WITHLOG USETHREADPOOL ONLYUSEHTTPSOCKET
interface
 uses
  SysUtils,
  Variants,
  SynCommons,
  mORMot,
  mORMotMVC,
  RESTModel,
  SynDB, 
  uRestSErver,
  BasicTypes,
  CustomModels;

type
  /// defines the main ViewModel/Controller commands of the web site
  // - typical URI are:
  // ! DefaultsParams/main/DefaultsParamsView?id=12 -> view one DefaultsParams
  // ! DefaultsParams/main/login?name=...&plainpassword=... -> log with credentials
  // ! DefaultsParams/main/DefaultsParamscommit -> DefaultsParams edition commit (ID=0 for new)
    IEmpresaApplication = interface(IMVCApplication)
   ['{339C4EAD-423D-43CE-8F10-AA8E12CCD1A4}'] 
    procedure DefaultParamsView( var ID: TID; out DefaultParams: variant  {TSQLRecordDefaultParams} );
    //function DefaultParamsMatch(const Match: RawUTF8): TMVCAction;
    procedure DefaultParamsEdit(var ID: TID; 
                                const Tipo: Integer;
                                const Resposta:RawUTF8;
                                const Valor:RawUTF8;
                                const Ordem:Integer;
                                const ValidationError: variant; 
                                out DefaultParams: TSQLRecordDefaultParams);
    procedure DefaultParams(var ID: TID; out Scope: variant);
    
    function DefaultParamsCommit(ID: TID;
                                  const Tipo: Integer;
                                  const Resposta:RawUTF8;
                                  const Valor:RawUTF8;
                                  const Ordem:Integer
                                  ): TMVCAction;
    
    function Login( const LogonName,PlainPassword: RawUTF8): TMVCAction;
    function Logout: TMVCAction;    
    
  end;


  /// implements the ViewModel/Controller of this tabelaCom web site
  TTelportApplication = class( TMVCApplication, IEmpresaApplication)
  private
    /// Execucoes remotas de um interface registrada para RESTfull
    FServiceRemoteSQL :TServiceRemoteSQL;
    /// Permite executar consultas ao banco
    function ExecSql(const SQL: RawUTF8): RawUTF8;
    protected      
      /// Default param
      fDefaultParamMainInfo: Variant;
      /// Menu geral em cache
      FMenuResult: ILockedDocVariant;
      fDefaultData: ILockedDocVariant;
      fHasFTS: boolean;
      FProps: TSQLDBConnectionProperties;
      
      procedure FlushAnyCache; override;
      function GetViewInfo(MethodIndex: integer): variant; override;
      /// Renderizar menu inicial deixando em cache com threadsafe
      function MenuPrincipal:Variant; 
      class procedure GotoDefault(var Action: TMVCAction;  Status: cardinal=HTML_TEMPORARYREDIRECT);    
    public
      procedure Error(var Msg: RawUTF8; var Scope: variant);
      procedure DefaultParams(var ID: TID; out Scope: variant);
      procedure Start(aServer: TSQLRestServer); reintroduce;
      procedure Default(var Scope: variant);
      procedure DefaultParamsView( var ID: TID; out DefaultParam: variant {TSQLRecordDefaultParams});
      procedure DefaultParamsEdit(var ID: TID; 
                                  const Tipo: Integer;
                                  const Resposta:RawUTF8;
                                  const Valor:RawUTF8;
                                  const Ordem:Integer;
                                  const ValidationError: variant; 
                                  out DefaultParams: TSQLRecordDefaultParams);
      function DefaultParamsCommit(ID: TID;
                                    const Tipo: Integer;
                                    const Resposta:RawUTF8;
                                    const Valor:RawUTF8;
                                    const Ordem:Integer
                                    ): TMVCAction;

      

       function Login( const LogonName,PlainPassword: RawUTF8): TMVCAction;
       function Logout: TMVCAction;       
   
  end;
  
implementation

uses
  SynCrossPlatformJSON, System.Classes;


const
  DefaultParam_FIELDS = 'RowID,Tipo,Resposta,Valor,Ordem,CreatedAt,ModifiedAt';
  DefaultParam_DEFAULT_LIMIT = ' limit 100';
  DefaultParam_DEFAULT_ORDER: RawUTF8 = 'order by Tipo,Resposta desc' + DefaultParam_DEFAULT_LIMIT;

resourcestring
  sErrorInvalidLogin = 'Wrong logging information';
  sErrorNeedValidAuthorSession = 'You need to be logged as a valid Author to perform this action';
  sErrorWriting = 'An error occured during saving the information to the database';

{ TTelportApplication }

procedure TTelportApplication.FlushAnyCache;
begin
  inherited FlushAnyCache; // call fMainRunner.NotifyContentChanged
  fDefaultData.Clear;

  FMenuResult.Clear;
end;

function TTelportApplication.GetViewInfo(MethodIndex: integer): variant;
begin
  result := inherited GetViewInfo(MethodIndex);
  _ObjAddProps(['DefaultParams',fDefaultParamMainInfo]
                ,result);
end;

procedure TTelportApplication.Start(aServer: TSQLRestServer);
begin 
  FProps := TSQLRestServerTel(aServer).Props;
  //Q := TQuery.Create(FProps.MainConnection);
  fDefaultData := TLockedDocVariant.Create;
  FMenuResult  := TLockedDocVariant.Create;
  inherited Start(aServer,TypeInfo(IEmpresaApplication));

  fMainRunner := TMVCRunOnRestServer.Create(Self, nil, 'Empresa').
    SetCache('Default',cacheRootWithSession,60).
    SetCache('DefaultParamsView',cacheWithParametersIfNoSession,60).
    SetCache('DefaultParamsView',cacheWithParametersIgnoringSession,60);

  //aServer.Cache.SetCache(TSQLRecordDefaultParams);
  //aServer.Cache.SetTimeOut(TSQLRecordDefaultParams,CACHE_TIMEOUT);  
  
//  with TSQLRecordDefaultParams.Create(RestModel,'') do
//  try
//    fDefaultParamMainInfo := GetSimpleFieldsAsDocVariant(false);
//  finally
//    Free;
//  end;   
end;

procedure TTelportApplication.Default(var Scope: variant);
var 
  scop: PDocVariantData;
  lastID: TID;
  tag: integer;  
  SessionLoged, Users: Variant;
  SessionInfo: ^TCookieData; 
  actLogin : TMVCAction; 
begin
  SessionLoged := CurrentSession.CheckAndRetrieveInfo(SessionInfo);
  if SessionLoged <> null then
  begin
  
  end
  else
  begin
    if (CurrentSession.CheckAndRetrieveInfo(SessionInfo) <> 0) then 
    begin
      actLogin.RedirectToMethodName := 'Default';
      GotoView(actLogin, 'Default',[],HTML_BADREQUEST);
      exit;
    end;  
    //scop := _Safe(Scope);    
    SetVariantNull(Scope);
    Users := FProps.Execute('select * from Empresa.usuario ', []) ;
    Scope := _ObjFast(['Users',Users]);
    Exit;                            
  end;
  
end;

procedure TTelportApplication.DefaultParamsView(var ID: TID;
  out DefaultParam: variant);
var  
  Defaults: variant;
begin
  if System.Variants.VarIsNull(Defaults) then
    raise EMVCApplication.CreateGotoError(HTML_NOTFOUND);
  SetVariantNull(DefaultParam);
  DefaultParam := _ObjFast(['DefaultParams',Defaults,'ID',ID]);
  Exit;        
end;

procedure TTelportApplication.DefaultParamsEdit(var ID: TID;
  const Tipo: Integer; const Resposta, Valor: RawUTF8; const Ordem: Integer;
  const ValidationError: variant; out DefaultParams: TSQLRecordDefaultParams);
var 
   ParamsID: PtrUInt;
begin
  if Tipo > 0 then
    DefaultParams.Tipo := Tipo;
  if Ordem > 0 then
    DefaultParams.Ordem := Ordem;
  
  if Resposta <> '' then
    DefaultParams.Resposta := Resposta;
  if Valor <> '' then
    DefaultParams.Valor := Valor;
end;

function TTelportApplication.DefaultParamsCommit(ID: TID; const Tipo: Integer;
  const Resposta, Valor: RawUTF8; const Ordem: Integer): TMVCAction;
var
  DefaultParamID: TID;
  DefaultParam: TSQLRecordDefaultParams;
  error:string;
  auto: IAutoFree;

  Y,M,D: word;
begin
  auto := TSQLRecordDefaultParams.AutoFree(DefaultParam, RestModel,ID);
  
  
  if DefaultParamID=0 then begin
    GotoError(result,0);
    exit;
  end;
  FlushAnyCache;
  DefaultParam.Tipo := Tipo;
  DefaultParam.Resposta := Resposta;
  DefaultParam.Valor := Valor;
  DefaultParam.Ordem := Ordem;
  
  if not DefaultParam.FilterAndValidate(RestModel,error) then
    GotoView(result,'DefaultParamEdit', ['ValidationError',error,
        'ID',ID,
        'Resposta',DefaultParam.Resposta,
        'Valor',DefaultParam.Valor,
        'Tipo',DefaultParam.Tipo,
        'Ordem',DefaultParam.Ordem],
        HTML_BADREQUEST) 

  else
    if DefaultParam.ID=0 then 
    begin
      DecodeDate(NowUTC,Y,M,D);
      
      DefaultParam.CreatedAt := integer(Y)*12+integer(M)-1; //TSQLRecordDefaultParams.;
      if RestModel.Add(DefaultParam,true)<>0 then
        
        GotoView(result,'DefaultParamView',['ID',DefaultParam.ID],HTML_SUCCESS) else
        GotoError(result,0);
    end 
    else
      RestModel.Update(DefaultParam); 
end;



procedure TTelportApplication.Error(var Msg: RawUTF8; var Scope: variant);
begin
  Scope := _ObjFast(['Error',Msg]);
  Exit;
end;

procedure TTelportApplication.DefaultParams(var ID: TID; out Scope: variant);
var
 table : TSQLTableJSON;
 Defaults: variant;
begin
  SetVariantNull(Scope);
  Defaults := ExecSql('select * from tabelaCom_item limit 1');
  
  Scope := _ObjFast(['DefaultParams',Defaults]);
  Exit;       

end;

function TTelportApplication.ExecSql(const SQL: RawUTF8): RawUTF8;
begin 
  Result := Self.FProps.ExecuteInlined(SQL, true).FetchAllAsJSON(true);  
end;


function TTelportApplication.Login(const LogonName,PlainPassword: RawUTF8): TMVCAction;
var 
  SessionInfo: TCookieData;
  Rows: ISQLDBRows;
  DataResult, DefaultParams,test :Variant;
begin  
  if (CurrentSession.CheckAndRetrieve <> 0) or (FProps = nil)then 
  begin
    GotoError(result,HTML_BADREQUEST);
    exit;
  end;  
  try      
    Rows := FProps.Execute('select * from Empresa.usuario where Apelido = ? limit 1', [LogonName]) ;
    
    if (Rows = nil) or (not Rows.Step)then
    begin
      GotoError(result,sErrorInvalidLogin);
    end
    else
    begin       
      DataResult :=  Rows.RowData;
      SessionInfo.LoginName := DataResult.Apelido;
      SessionInfo.UserID := DataResult.Usuario_ID;
      SessionInfo.EmpresaID := DataResult.Empresa;
      SessionInfo.Produtor  := DataResult.Produtor;
      //SessionInfo.UserRights := ;
      CurrentSession.Initialize(@SessionInfo,TypeInfo(TCookieData));
      test := ExecSql('SELECT * FROM tabelaCom_item limit 1');
      test := MenuPrincipal;
      DefaultParams := _ObjFast(['DefaultParams',test]);
      GotoDefault(result);
      
      
    end;     
  finally    
  end;

end;

function TTelportApplication.Logout: TMVCAction;
begin
  CurrentSession.Finalize;
  GotoDefault(result);
end;


function TTelportApplication.MenuPrincipal: Variant;
const
  fFileMenuJs: string = 'Views\'+STATIC_URI+'\menu.js';
var
  jsonByteStr: RawUTF8;
  TryCustomVariants: PDocVariantOptions;
begin       
  jsonByteStr := StringToJSON(UTF8FileToString(ExtractFilePath(ParamStr(0)) +  fFileMenuJs));
  Result:= VariantLoadJSON(jsonByteStr, TryCustomVariants);
end;

////



class procedure TTelportApplication.GotoDefault(var Action: TMVCAction;
  Status: cardinal);
begin
  Action.ReturnedStatus := Status;
  Action.RedirectToMethodName := 'CotacaoView';
  Action.RedirectToMethodParameters := '';
end;


{$ifndef ISDELPHI2010}
initialization
  TTextWriter.RegisterCustomJSONSerializerFromTextSimpleType(TypeInfo(TSQLRecordDefaultParams));
//  TTextWriter.RegisterCustomJSONSerializerFromTextSimpleType(TypeInfo(TSQLAuthorRights));
  TTextWriter.RegisterCustomJSONSerializerFromText(TypeInfo(TCookieData),
    'AuthorName RawUTF8 AuthorID cardinal AuthorRights TSQLAuthorRights');
{$endif}

end.
