/// minimal REST server for a list of Persons stored on PostgreSQL
program RESTserver;

// see http://synopse.info/forum/viewtopic.php?pid=10882#p10882

{$APPTYPE CONSOLE}
uses
  SysUtils,
  SynLog,
  mORMot,
  mORMotSQLite3,
  SynSQLite3Static,
  mORMotDB,
  mORMotHttpServer,
  SynDB,
  SynDBODBC,
  RESTModel,
  SynDBFireDAC,
  FireDAC.Phys.MySQL,
  mORMotMVC,
  SynCommons,
  BasicTypes,
  uRestSErver in 'uRestSErver.pas',
  CustomModels in 'CustomModels.pas',
  uMVCTP3 in 'uMVCTP3.pas';

var
  aModel: TSQLModel;  
  aRestServer :TSQLRestServerTel; 
  aApplication : TTP3Application;//TTelportApplication;
  aHttpServer: TSQLHttpServer;
//  SynConnectionDefinition :TSynConnectionDefinition;
  fConnProps, fConnProps2 : TSQLDBConnectionProperties;
begin
  // set logging abilities
  SQLite3Log.Family.Level := LOG_VERBOSE;
  SynDBLog.Family.Level := LOG_VERBOSE;
  SynDBLog.Family.PerThreadLog:= ptIdentifiedInOnFile;
  SQLite3Log.Family.EchoToConsole := LOG_VERBOSE;
  SQLite3Log.Family.PerThreadLog := ptIdentifiedInOnFile;
  
  try
    fConnProps:= TSQLDBConnectionProperties.CreateFromFile('localDBsettings.json');
  except   
    fConnProps:= TSQLDBFireDACConnectionProperties.Create('MySQL?Server=localhost;Port=3306','base1','root','senha');
    fConnProps.StoreVoidStringAsNull := True;
    fConnProps.LogSQLStatementOnException := True;
    fConnProps.DefinitionToFile('localDBsettings.json');
    
    fConnProps2:= TSQLDBFireDACConnectionProperties.Create('MySQL?Server=localhost;Port=3306','base2','root','senha');
    fConnProps2.StoreVoidStringAsNull := True;
    fConnProps2.LogSQLStatementOnException := True; 
    fConnProps2.DefinitionToFile('localDBSetings2.json');
    fConnProps2.ThreadSafeConnection.Disconnect;
    fConnProps2.Free;    
  end;
  
  try
    // get the shared data model
    aModel := InitDataModel;     
    try      
      try
        // create the main mORMot server
        aRestServer := TSQLRestServerTel.Create(fConnProps, aModel); // authentication=false
        aRestServer.ServiceRegister(TTP3Application,[TypeInfo(ITP3)],sicShared);
        try          
          // app MVC with mormot
          aApplication := TTP3Application.Create;//TTelportApplication.Create;
          aApplication.Start(aRestServer); 

         
                    
          //serve aRestServer data over HTTP
          aHttpServer := TSQLHttpServer.Create(SERVER_PORT,[aRestServer]{$ifndef ONLYUSEHTTPSOCKET},'+',useHttpApiRegisteringURI{$endif});          
//          aHttpServer.DomainHostRedirect('rest.empresa.com','empresa');// 'root' is current Model.Root 
//          aHttpServer.DomainHostRedirect('empresa.com','teleport/html');
          try
            aHttpServer.AccessControlAllowOrigin := '*'; // allow cross-site AJAX queries
            aHTTPServer.RootRedirectToURI('root/default');

            Writeln('Background server is running.'#10);
            Writeln('"MVC Empresa Default Params Server" iniciado na porta: ' +  SERVER_PORT + ' usando , ' + aHttpServer.HttpServer.ClassName);                                                                                            
            Writeln(#10'Voce pode checar em http://localhost:' + SERVER_PORT + '/root/mvc-info para testes');
            Writeln('ou apontar para  http://localhost:' + SERVER_PORT + 'para acessar a pagina do app.');
            Writeln(#10'Press [Enter] to close the server.'#10);
            Readln;
          finally
            aHttpServer.Free;
          end;
        finally
          aApplication.Free;
        end;
      finally
        aRestServer.Free;
      end;
    finally
      aModel.Free;
    end;
  finally
    fConnProps.Free;
  end;

end.


