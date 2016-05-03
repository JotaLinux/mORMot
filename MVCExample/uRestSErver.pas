unit uRestSErver;

interface
uses
  mORMot,
  mORMotSQLite3,
  mORMotDB,
  SynDB,
  RESTModel,
  FireDAC.Phys.MySQL,
  SynCommons
  ;
  
type
  TSQLRestServerTel = class(TSQLRestServerDB)
  private
    fProps: TSQLDBConnectionProperties;
    FDPhysMySQLDriverLink: TFDPhysMySQLDriverLink;
    fMyFileCache: string;
  public
    property Props:TSQLDBConnectionProperties read fProps write fProps;
    //procedure Html(Ctxt: TSQLRestServerURIContext);
    constructor Create(Props: TSQLDBConnectionProperties; 
                                     aModel:TSQLModel);
    destructor Destroy; override;
  end;

implementation

uses
  uMVCTP3, System.SysUtils;
 {TSQLRestServerTel }

constructor TSQLRestServerTel.Create(Props: TSQLDBConnectionProperties; 
                                     aModel:TSQLModel);
begin
  FDPhysMySQLDriverLink:= TFDPhysMySQLDriverLink.Create(Nil);  
  inherited Create(aModel,':memory:',false);  
  AuthenticationRegister(TSQLRestServerAuthenticationNone {TSQLRestServerAuthenticationDefault});
  fProps := Props;
  VirtualTableExternalRegisterAll(aModel,Props);
  InitializeEngine;  
  CreateMissingTables(ExeVersion.Version.Version32);
  // optionally execute all PostgreSQL requests in a single thread
  AcquireExecutionMode[execORMGet]   := amBackgroundORMSharedThread;
  AcquireExecutionMode[execORMWrite] := amBackgroundORMSharedThread;  
  /// Registrando interfaces proprias :
  /// http://localhost:8092/Empresa/acessorios/5
  /// http://localhost:8092/Empresa/Calculo.Add/2/2
  /// http://localhost:8092/Empresa/Calculo.Add?n1=2&n2=2
  //sicClientDriven
//  ServiceRegister(TServiceRemoteSQL,[TypeInfo(ITP3)],sicClientDriven);
  //.SetOptions([],[optExecInMainThread,optFreeInMainThread]);
  RootRedirectGet := 'Empresa/Default';  
  
  
end;

destructor TSQLRestServerTel.Destroy;
begin
  FDPhysMySQLDriverLink.Free;
  inherited;
end; 
//procedure TSQLRestServerTel.Html(Ctxt: TSQLRestServerURIContext);
//begin
//   if fMyFileCache = '' then 
//    fMyFileCache := StringFromFile(ChangeFileExt(paramstr(0),'.html')); 
//   Ctxt.Returns(fMyFileCache,HTML_SUCCESS,HTML_CONTENT_TYPE_HEADER,true);
//   //Ctxt.ReturnFileFromFolder('C:\Projects\RESTfulORMServer\Views');
//end;

end.
