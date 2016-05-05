unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SynLog, SynCommons;

type
  TForm1 = class(TForm)
    btnlogtext: TButton;
    Memo1: TMemo;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnlogtextClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  protected
    SynLogFile : TSynLogFile;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
 //teste global
  TThreadLogger : TSynLogClass = TSynLog;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  //Self.SynLogFile := TSynLogFile.Create('.\MyLog.log');
  //Self.SynLogFile.EventText(0);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  //FreeAndNil(Self.SynLogFile);
end;

procedure TForm1.btnlogtextClick(Sender: TObject);
 var
   ILog: ISynLog;
   SynLogDB :TSynLog;
begin
  /// Reagrupar os logs em uma familia identificada pelo parametro
  // - Geralmente deve-se usar uma familia por aplicacao ou arquitetura.
  // - Inicialize a familia antes usando o codigo:
  SynLogDB := TSynLog.Create();

  with SynLogDB.Family do begin
    Level := LOG_VERBOSE;
    PerThreadLog := ptOneFilePerThread;
    DestinationPath := ExtractFilePath(paramstr(0)) ;
  end;
  //- Entao usar o Log normalemnte:
  ILog := SynLogDB.Enter(self,'btnlogtextClick');
  // faça algo ...
  ILog.Log(sllInfo,'method chamado btnlogtextClick');
  ILog.Log(sllMonitoring,'blabalbalbl');

  //ILog.LogLines();
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  log : ISynLog;
begin
    log := TThreadLogger.Enter(self);
    log.Log(sllInfo, 'teststtst');
    log := nil;
end;

end.
