unit RESTModel;

interface

uses
  SynCommons,
  mORMot,
  SynDB,
  SynDBDataset,  
  SynDBFireDAC,
  BasicTypes;

type
  TSQLRecordTimeStamped = class(TSQLRecord)
  private
    fCreatedAt: TCreateTime;
    fModifiedAt: TModTime;
  published
    property CreatedAt: TCreateTime read fCreatedAt write fCreatedAt;
    property ModifiedAt: TModTime read fModifiedAt write fModifiedAt;
  end;

  
  IRemoteSQL = interface(IInvokable)
    ['{9A60C8ED-CEB2-4E09-87D4-4A16F496E5FE}']
    function Execute(const aSQL: RawUTF8; aExpectResults, aExpanded: Boolean): RawJSON;
  end; 

  /// Permitir execucao de consultas
  TServiceRemoteSQL = class(TInterfacedObject, IRemoteSQL)
  protected
    fProps: TSQLDBConnectionProperties;    
  public
    destructor Destroy; override;    
  public // implements IRemoteSQL methods
    function Execute(const aSQL: RawUTF8; aExpectResults, aExpanded: Boolean): RawJSON;
  end;


  
implementation
uses
  SynCrtSock, System.SysUtils; // for DotClearFlatImport() below 

{ TServiceRemoteSQL }

destructor TServiceRemoteSQL.Destroy;
begin
  FreeAndNil(fProps);
  inherited;

end;

function TServiceRemoteSQL.Execute(const aSQL: RawUTF8; aExpectResults,
  aExpanded: Boolean): RawJSON;
var 
  res: ISQLDBRows;
  Qry : TQuery;
begin   
  Qry := TQuery.Create(fProps.NewConnection);
  Qry.SQL.Clear;
  Qry.SQL.Add('select * from tabela_item limit 1');
  Qry.Open;
  while not Qry.Eof do
  begin
  
    Qry.Next;
  end;
  Qry.Close;
  Qry.Free;

  if fProps=nil then
    raise Exception.Create('Connect call required before Execute');
  res := fProps.ExecuteInlined(aSQL,aExpectResults);
  if res=nil then
    result := '' else
    result := res.FetchAllAsJSON(aExpanded);
end;



end.
