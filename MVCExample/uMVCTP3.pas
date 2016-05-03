unit uMVCTP3;

{$I Synopse.inc} // define HASINLINE WITHLOG USETHREADPOOL ONLYUSEHTTPSOCKET
interface
 uses
  SysUtils,
  Variants,
  Contnrs,
  SynLog,
  SynCommons,
  mORMot,
  mORMotMVC,
  RESTModel,
  SynDB, 
  uRestSErver,
  BasicTypes,
  CustomModels;
  

type

   /// session information which will be stored on client side within a cookie
  // - TMVCSessionWithCookies is able to store any record on the client side,
  // as optimized base64 encoded binary data, without any storage on the server
  // - before Delphi 2010, TTextWriter.RegisterCustomJSONSerializerFromText() is
  // called in initialization block below, to allow proper JSON serialization
  // as needed for fields injection into the Mustache rendering data context
  
  TCookieData = packed record
    LoginName: RawUTF8;
    UserID: cardinal;
    EmpresaID: Cardinal;
    Produtor:Cardinal;
    UserRights: TSQLEmpresaRights;    
  end;


 ITP3 = interface(IMVCApplication)
  ['{14194C01-40D5-4F4D-B0D7-AAEC3122A9EF}']
    function Login( const LogonName,PlainPassword: RawUTF8): TMVCAction;
    function Logout: TMVCAction;
    procedure CotacaoView(Calculo, CalcN:Integer; out CalculoItem: variant);
  end;


 TTP3Application = class( TMVCApplication, ITP3)
  private
    /// Execucoes remotas de um interface registrada para RESTfull
    FServiceRemoteSQL :TServiceRemoteSQL;
    /// Permite executar consultas ao banco
    function ExecSql(const SQL: RawUTF8): RawUTF8;
    protected      
      /// Menu geral em cache
      FMenuResult: ILockedDocVariant;
      fMainInfo: variant;
      FProps: TSQLDBConnectionProperties;      
      procedure FlushAnyCache; override;
      function GetViewInfo(MethodIndex: integer): variant; override;
      /// Renderizar menu inicial deixando em cache com threadsafe
      function MenuPrincipal:Variant; 
      //Retornar a pagina inicial: Login ?
      class procedure GotoDefault(var Action: TMVCAction;  Status: cardinal=HTML_TEMPORARYREDIRECT);    
      //Listagem de cotacoes.
      
    public
      
      //Pagina com erro padrao.
      procedure Error(var Msg: RawUTF8; var Scope: variant);

      //Configuracao inicial da aplicacao
      procedure Start(aServer: TSQLRestServer); reintroduce;
      //Pagina inicial: Propriedades globais, caches e Expressions Helps
      procedure Default(var Scope: variant);

      //listagem de cotacoes
//      procedure Cotacoes(var Scope: variant);

      //carregamento de cotacoes
      procedure CotacaoView(Calculo, CalcN:Integer; out CalculoItem: variant);

      {ToDO: login e carregamento de caches e menus, permissoes etc}
      function Login( const LogonName,PlainPassword: RawUTF8): TMVCAction;
      {ToDo: limpeza de caches e sessoes. Encerramentos}
      function Logout: TMVCAction;       
   
  end;
  
implementation

uses
  SynCrossPlatformJSON, System.Classes, System.IOUtils;

{ TTP3Application }

function TTP3Application.ExecSql(const SQL: RawUTF8): RawUTF8;
begin
  Result:= FProps.ExecuteInlined(SQL, true).FetchAllAsJSON(true);
end;

procedure TTP3Application.FlushAnyCache;
begin
  inherited FlushAnyCache; // call fMainRunner.NotifyContentChanged
  FMenuResult.Clear;
end;

function TTP3Application.GetViewInfo(MethodIndex: integer): variant;
begin
  //Pegar contexto e escopo atual enviado pelo metodo
  result := inherited GetViewInfo(MethodIndex);
  //adicionar computacoes ja persistidas ao resultado do metodo
  _ObjAddProps([
    'Empresa',fMainInfo, //alguma informação global do aplicativo
    'session',CurrentSession.CheckAndRetrieveInfo(TypeInfo(TCookieData))   //dados de sessao no coockie
//  ,  'menu', MenuPrincipal //menu ja renderizado
    ] ,result); //adicionar ao resultado
  if not FMenuResult.AddExistingProp('menu', result) then
  begin
    FMenuResult.AddNewProp('menu',MenuPrincipal , result);
  end;
  
end;

function TTP3Application.MenuPrincipal: Variant;
const
  fFileMenuJs: string = 'Views\'+STATIC_URI+'\menu.js';
var
  TryCustomVariants: PDocVariantOptions;
  varDoc : Variant;
begin    
  varDoc := _JSON(TFile.ReadAllText(ExtractFilePath(ParamStr(0)) +  fFileMenuJs, TEncoding.UTF8)); 
  if not FMenuResult.AddExistingProp('menu', varDoc) then
  begin
     FMenuResult.AddNewProp('menu',varDoc , varDoc);
  end;
  Result:= FMenuResult.Value['menu'];//.ToJSON(true); 
end;

class procedure TTP3Application.GotoDefault(var Action: TMVCAction;
  Status: cardinal);
begin
  Action.ReturnedStatus := Status;
  Action.RedirectToMethodName := 'Default';
  Action.RedirectToMethodParameters := '';
end;

procedure TTP3Application.Error(var Msg: RawUTF8; var Scope: variant);
begin
  Scope := _ObjFast(['Error',Msg]);
  Exit;
end;

procedure TTP3Application.Start(aServer: TSQLRestServer);
begin
  FProps := TSQLRestServerTel(aServer).Props;
  FMenuResult  := TLockedDocVariant.Create;
  inherited Start(aServer,TypeInfo(ITP3));
  fMainRunner := TMVCRunOnRestServer.Create(Self).
    SetCache('Default',cacheRootIfNoSession,15);
    
//    .SetCache('ArticleView',cacheWithParametersIfNoSession,60).
//    SetCache('AuthorView',cacheWithParametersIgnoringSession,60);
//   (TMVCRunOnRestServer(fMainRunner).Views as TMVCViewsMustache).
//    RegisterExpressionHelpers(['MonthToText'],[MonthToText]).
//    RegisterExpressionHelpers(['TagToText'],[TagToText]);
//
 // (TMVCRunOnRestServer(fMainRunner).Views as TMVCViewsMustache);

end;

procedure TTP3Application.Default(var Scope: variant);
var   
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
    if (CurrentSession.CheckAndRetrieveInfo(SessionInfo) <= 0) then 
    begin
      actLogin.RedirectToMethodName := 'Default';
      GotoView(actLogin, 'Default',[],HTML_BADREQUEST);
      exit;
    end;        
  end;
  GotoView(actLogin, 'CotacaoView',['Scope', Scope],HTML_SUCCESS);

end;

function TTP3Application.Login(const LogonName,
  PlainPassword: RawUTF8): TMVCAction;
var 
  SessionInfo: TCookieData;
  Rows: ISQLDBRows;
  DataResult, DefaultParams,Users,Scope,Calcul, MenuVar :Variant;
  oProps : TSQLDBConnectionProperties;
begin
  

  try
    if (CurrentSession.CheckAndRetrieve <> 0) or (FProps = nil)then 
    begin
      GotoError(result,HTML_BADREQUEST);
      exit;
    end;  
    SetVariantNull(Scope);
    oProps := TSQLDBConnectionProperties.CreateFromFile('localDBEmpresa.json');
    
    
    Rows := oProps.Execute('select * from Empresa.usuario where Apelido=? limit 1', [LogonName], @DataResult, True) ;
    
    
    if (Rows = nil) or (not Rows.Step)then
    begin
      GotoView(result,'Error', ['sErrorInvalidLogin'],HTML_NONAUTHORIZEDINFO);
      //GotoView(result,'Default',['ID',0, 'Scope', null],HTML_SUCCESS) ; 
    end
    else
    begin       
      Users := Rows.FetchAllAsJSON(True);
      Scope := _ObjFast(['Users',Users]);    
      
      DataResult :=  Rows.RowData;
      SessionInfo.LoginName := DataResult.Apelido;
      SessionInfo.UserID := DataResult.Usuario_ID;
      SessionInfo.EmpresaID := DataResult.Empresa;
      SessionInfo.Produtor  := DataResult.Produtor;
      //SessionInfo.UserRights := ;
      CurrentSession.Initialize(@SessionInfo,TypeInfo(TCookieData));
      Calcul := ExecSql('SELECT * FROM tabela_item limit 1');
      MenuVar := MenuPrincipal;
      DefaultParams := _ObjFast(['Calcul',Calcul]);
      GotoView(result,'CotacaoView',['DefaultParams',DefaultParams, 'MenuVar', MenuVar, 'Calculo', 1, 'CalcN', 1272],HTML_SUCCESS) ;    
    end;     
  finally
    oProps.Free;
  end;
    
    
end;

function TTP3Application.Logout: TMVCAction;
begin
  CurrentSession.Finalize;
  GotoDefault(result);
end;


procedure TTP3Application.CotacaoView(Calculo, CalcN:Integer; out CalculoItem: variant);
var
  vCalculoItem: Variant ;
  actCalculo : TMVCAction;  
begin        

    SetVariantNull(CalculoItem);
    _Json(FProps.Execute('SELECT * FROM CALCULO LIMIT 100' {WHERE CALC_N = ? AND CALC_IT = ? LIMIT 1', [CalcN, Calculo]}, []).FetchAllAsJSON(True)
                          , CalculoItem
                        , []);
    //Objeto renderizado no escopo
    //CalculoItem.Calculo := Calculo; //:= _ObjFast(['vCalculoItem',vCalculoItem, 'Calculo', Calculo,'CalcN', CAlcN]);
    //CalculoItem.CalcN := CalcN;
    // Poderia redirecionar para a view passando os dados no Scope
    //GotoView(actCalculo, 'Calculo',['Scope', CalculoItem],HTML_SUCCESS);     
     // ! aView.RegisterExpressionHelpersForTables(aServer,[TSQLMyRecord]);
    // then use the following Mustache tag
    // ! {{#TSQLMyRecord MyRecordID}} ... {{/TSQLMyRecord MyRecordID}}
    
    Exit;  
end;


{$ifndef ISDELPHI2010}
class procedure TTP3Application.GotoCotacoes(var Action: TMVCAction;
  Status: cardinal);
begin
  Action.ReturnedStatus := Status;
  Action.RedirectToMethodName := 'Cotacoes';
  Action.RedirectToMethodParameters := '';
end;

procedure TTP3Application.Cotacoes(var Scope: variant);
begin

end;

initialization
  TTextWriter.RegisterCustomJSONSerializerFromTextSimpleType(TypeInfo(TSQLRecordDefaultParams));
  TTextWriter.RegisterCustomJSONSerializerFromTextSimpleType(TypeInfo(TSQLAuthorRights));
  TTextWriter.RegisterCustomJSONSerializerFromText(TypeInfo(TCookieData),
    'AuthorName RawUTF8 AuthorID cardinal AuthorRights TSQLAuthorRights');
{$endif}

end.
