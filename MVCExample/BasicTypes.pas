unit BasicTypes;

interface

uses
  SynDB,
  SynDBFireDAC;

type
  {ToDo: Para uso futuro com outros drivers}
  TRemoteSQLEngine = ({rseOleDB, rseODBC, rseOracle, rseSQlite3, rseJet, rseMSSQL,} rseFiredac);  
  
  //Permissoes do crud e acesso as telas
  TSQLEmpresaRight = (canPost, canDelete, canAdministrate);
  TSQLEmpresaRights = set of TSQLEmpresaRight;

  
const // rseOleDB, rseODBC, rseOracle, rseSQlite3, rseJet, rseMSSQL , rseFiredac
  TYPES: array[TRemoteSQLEngine] of TSQLDBConnectionPropertiesClass = (
     {ToDo: Para uso futuro com outros drivers}
     (**
     TOleDBConnectionProperties, 
     TODBCConnectionProperties,
     TSQLDBOracleConnectionProperties, 
     TSQLDBSQLite3ConnectionProperties,
     {$ifdef WIN64}nil{$else}TOleDBJetConnectionProperties{$endif},
     TOleDBMSSQL2008ConnectionProperties, 
     **)
     TSQLDBFireDACConnectionProperties );
      
  
const
  SERVER_ROOT = 'Empresa';
  SERVER_PORT = '8092';
  SALT = 'mORMot';
  CACHE_TIMEOUT = 60000;

 

implementation

//uses
//  CustomModels;
  // customize RESTful URI parameters as expected by our ExtJS client 
  // aRestServer.URIPagingParameters.StartIndex := 'START=';
  // aRestServer.URIPagingParameters.Results := 'LIMIT=';
  // aRestServer.URIPagingParameters.SendTotalRowsCountFmt := ',"total":%';
  ///Q FODAAAAA        
  // create tables or fields if missing  



end.

