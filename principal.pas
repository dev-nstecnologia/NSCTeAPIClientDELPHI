unit principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TfrmPrincipal = class(TForm)
    Label6: TLabel;
    txtCNPJ: TEdit;
    txtCaminhoSalvar: TEdit;
    labelTokenEnviar: TLabel;
    pgControl: TPageControl;
    formEmissao: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    btnEnviar: TButton;
    memoConteudoEnviar: TMemo;
    cbTpConteudo: TComboBox;
    chkExibir: TCheckBox;
    GroupBox4: TGroupBox;
    memoRetorno: TMemo;
    cbTpDown: TComboBox;
    cbTpAmb: TComboBox;
    Label7: TLabel;
    cbModelo: TComboBox;
    procedure btnEnviarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses CTeAPI, System.json;

procedure TfrmPrincipal.btnEnviarClick(Sender: TObject);
var
  retorno: String;
  resposta: String;
  motivo, nsNRec, erros: String;
  statusEnvio, statusConsulta, statusDownload: String;
  chCTe, cStat, nProt: String;
  jsonRetorno: TJSONObject;
  aux: String;
begin
  // Valida se todos os campos foram preenchidos
  if ((txtCaminhoSalvar.Text <> '') and (txtCNPJ.Text <> '') and
    (memoConteudoEnviar.Text <> '')) then
  begin
    memoRetorno.Lines.Clear;
    retorno := emitirCTeSincrono(memoConteudoEnviar.Text,
      cbTpConteudo.Text, txtCNPJ.Text, cbTpDown.Text, cbTpAmb.Text,
      cbModelo.Text, txtCaminhoSalvar.Text, chkExibir.Checked);
    memoRetorno.Text := retorno;

    jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(retorno),
    0) as TJSONObject;
    statusEnvio := jsonRetorno.GetValue('statusEnvio').Value;
    statusConsulta := jsonRetorno.GetValue('statusConsulta').Value;
    statusDownload := jsonRetorno.GetValue('statusDownload').Value;
    motivo := jsonRetorno.GetValue('motivo').Value;
    nsNRec := jsonRetorno.GetValue('nsNRec').Value;
    erros := jsonRetorno.GetValue('erros').Value;
    chCTe := jsonRetorno.GetValue('chCTe').Value;
    cStat := jsonRetorno.GetValue('cStat').Value;
    nProt := jsonRetorno.GetValue('nProt').Value;
    if((statusEnvio = '200') or (statusEnvio = '-6'))then
    begin
      if (statusConsulta = '200') then
      begin
        Showmessage(motivo);
        if (cStat = '100') then
        begin
          if (statusDownload <> '200') then
          begin
            Showmessage('Ocorreu um erro no download');
          end;
        end;

      end
      else
      begin
          Showmessage(motivo + #13 + erros);
      end;
    end
    else
    begin
       Showmessage(motivo + #13 + erros);
    end;
  end
  else
  begin
    Showmessage('Todos os campos devem estar preenchidos');
  end;
end;


end.
