unit CTeAPI;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, IdHTTP, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack,
  IdSSL, IdSSLOpenSSL, ShellApi, IdCoderMIME, EncdDecd;

// Assinatura das fun��es
function enviaConteudoParaAPI(conteudoEnviar, url, tpConteudo: String): String;
function emitirCTeSincrono(conteudo, tpConteudo, CNPJ, tpDown,
  tpAmb, modelo, caminho: String; exibeNaTela: boolean = false): String;
function emitirCTe(conteudo, tpConteudo, modelo: String): String;
function consultarStatusProcessamento(CNPJ, nsNRec, tpAmb: String): String;
function downloadCTe(chCTe, tpDown, tpAmb: String): String;
function downloadEventoCTe(chCTe, tpDown, tpAmb, tpEvento,
  nSeqEvento: String): String;
function downloadCTeESalvar(chCTe, tpDown, tpAmb: String;
  caminho: String = ''; exibeNaTela: boolean = false): String;
function downloadEventoCTeESalvar(chCTe, tpDown, tpAmb, tpEvento,
  nSeqEvento: String; caminho: String = '';
  exibeNaTela: boolean = false): String;
function cancelarCTe(chCTe, tpAmb, dhEvento, nProt, xJust, tpDown,
  caminho: String; exibeNaTela: boolean = false): String;
function corrigirCTe(chCTe, tpAmb, dhEvento, nSeqEvento, grupoAlterado, campoAlterado,
  valorAlterado, nroItemAlterado, tpDown, caminho: String; exibeNaTela: boolean = false): String;
function consultarCadastroContribuinte(CNPJCont, UF, documentoConsulta, tpConsulta:String): String;
function consultarSituacao(licencaCNPJ, chCTe, tpAmb:String): String;
function inutilizar(cUF, tpAmb, ano, CNPJ, modelo, serie, nCTIni,
 nCTFin, xJust:String): String;
function listarNSNRecs(chCTe:String): String;
function salvarXML(xml, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
function salvarJSON(json, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
function salvarPDF(pdf, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
procedure gravaLinhaLog(conteudo: String);

implementation

uses
  System.json;

var
  token: String = 'SEU_TOKEN';

  // Fun��o gen�rica de envio para um url, contendo o token no header
function enviaConteudoParaAPI(conteudoEnviar, url, tpConteudo: String): String;
var
  retorno: String;
  conteudo: TStringStream;
  HTTP: TIdHTTP; // Dispon�vel na aba 'Indy Servers'
  IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
  // Disponivel na aba Indy I/O Handlers
begin
  conteudo := TStringStream.Create(conteudoEnviar, TEncoding.UTF8);
  HTTP := TIdHTTP.Create(nil);
  try
    if tpConteudo = 'txt' then // Informa que vai mandar um TXT
    begin
      HTTP.Request.ContentType := 'text/plain;charset=utf-8';
    end
    else if tpConteudo = 'xml' then // Se for XML
    begin
      HTTP.Request.ContentType := 'application/xml;charset=utf-8';
    end
    else // JSON
    begin
      HTTP.Request.ContentType := 'application/json;charset=utf-8';
    end;

    // Abre SSL
    IdSSLIOHandlerSocketOpenSSL1 := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    HTTP.IOHandler := IdSSLIOHandlerSocketOpenSSL1;

    // Avisa o uso de UTF-8
    HTTP.Request.ContentEncoding := 'UTF-8';

    // Adiciona o token ao header
    HTTP.Request.CustomHeaders.Values['X-AUTH-TOKEN'] := token;
    // Result := conteudo.ToString;
    // Faz o envio por POST do json para a url
    try
      retorno := HTTP.Post(url, conteudo);

    except
      on E: EIdHTTPProtocolException do
        retorno := E.ErrorMessage;
      on E: Exception do
        retorno := E.Message;
    end;

  finally
    conteudo.Free();
    HTTP.Free();
  end;

  // Devolve o json de retorno da API
  Result := retorno;
end;

// Esta fun��o emite uma CT-e de forma s�ncrona, fazendo o envio, a consulta e o download da nota
function emitirCTeSincrono(conteudo, tpConteudo, CNPJ, tpDown, tpAmb, modelo,
 caminho: String; exibeNaTela: boolean = false): String;
var
  retorno, resposta: String;
  motivo, nsNRec: String;
  statusEnvio, statusConsulta, statusDownload: String;
  erros: TJSONValue;
  chCTe, cStat, nProt: String;
  jsonRetorno, jsonAux: TJSONObject;
  aux: String;
begin

  statusEnvio := '';
  statusConsulta := '';
  statusDownload := '';
  motivo := '';
  nsNRec := '';
  erros := TJSONString.Create('');
  chCTe := '';
  cStat := '';
  nProt := '';

  gravaLinhaLog('[EMISSAO_SINCRONA_INICIO]');

  resposta := emitirCTe(conteudo, tpConteudo, modelo);
  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  statusEnvio := jsonRetorno.GetValue('status').Value;

  if (statusEnvio = '200') or (statusEnvio = '-6') then
  begin
    nsNRec := jsonRetorno.GetValue('nsNRec').Value;

    sleep(500);

    resposta := consultarStatusProcessamento(CNPJ, nsNRec, tpAmb);
    jsonRetorno := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(resposta), 0) as TJSONObject;
    statusConsulta := jsonRetorno.GetValue('status').Value;

    if (statusConsulta = '200') then
    begin

      cStat := jsonRetorno.GetValue('cStat').Value;

      if (cStat = '100') or (cStat = '150') then
      begin

        chCTe := jsonRetorno.GetValue('chCTe').Value;
        nProt := jsonRetorno.GetValue('nProt').Value;
        motivo := jsonRetorno.GetValue('xMotivo').Value;

        resposta := downloadCTeESalvar(chCTe, tpDown, tpAmb, caminho,
          exibeNaTela);
        jsonRetorno := TJSONObject.ParseJSONValue
          (TEncoding.ASCII.GetBytes(resposta), 0) as TJSONObject;
        statusDownload := jsonRetorno.GetValue('status').Value;

        if (statusDownload <> '200') then
        begin
          motivo := jsonRetorno.GetValue('motivo').Value;
        end;

      end
      else
      begin
        motivo := jsonRetorno.GetValue('xMotivo').Value;
      end;

    end
    else
    begin
      motivo := jsonRetorno.GetValue('motivo').Value;
      erros := jsonRetorno.Get('erros').JsonValue;
    end;

  end

  else if (statusEnvio = '-7') then
  begin
    nsNRec := jsonRetorno.GetValue('nsNRec').Value;
    motivo := jsonRetorno.GetValue('motivo').Value;
  end

  else if (statusEnvio = '-4') then
  begin
    motivo := jsonRetorno.GetValue('motivo').Value;
    try
      erros := jsonRetorno.Get('erros').JsonValue;
    except
    end;
  end

  else
  begin
    try
      motivo := jsonRetorno.GetValue('motivo').Value;
    except
      motivo := jsonRetorno.ToString;
    end;
  end;

  retorno := '{';
  retorno := retorno + '"statusEnvio": "'       + statusEnvio + '",';
  retorno := retorno + '"statusConsulta": "'    + statusConsulta + '",';
  retorno := retorno + '"statusDownload": "'    + statusDownload + '",';
  retorno := retorno + '"cStat": "'             + cStat  + '",';
  retorno := retorno + '"chCTe": "'             + chCTe  + '",';
  retorno := retorno + '"nProt": "'             + nProt  + '",';
  retorno := retorno + '"motivo": "'            + motivo + '",';
  retorno := retorno + '"nsNRec": "'            + nsNRec + '",';
  retorno := retorno + '"erros": '              + erros.ToString;
  retorno := retorno + '}';

  gravaLinhaLog('[JSON_RETORNO]');
  gravaLinhaLog(retorno);
  gravaLinhaLog('[EMISSAO_SINCRONA_INICIO]');
  gravaLinhaLog('');

  Result := retorno;
end;

// Emitir CT-e
function emitirCTe(conteudo, tpConteudo, modelo: String): String;
var
  url, resposta: String;
begin
  if (modelo = '57')then
  begin
   url := 'https://cte.ns.eti.br/cte/issue';
  end
  else
  begin
   url := 'https://cte.ns.eti.br/cte/issueos';
  end;


  gravaLinhaLog('[ENVIO_DADOS]');
  gravaLinhaLog(conteudo);

  resposta := enviaConteudoParaAPI(conteudo, url, tpConteudo);

  gravaLinhaLog('[ENVIO_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

// Consultar Status de Processamento
function consultarStatusProcessamento(CNPJ, nsNRec, tpAmb: String): String;
var
  json: String;
  url, resposta: String;
begin

  json := '{' +
              '"CNPJ": "'         + CNPJ   + '",' +
              '"nsNRec": "'       + nsNRec + '",' +
              '"tpAmb": "'        + tpAmb  + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/issueStatus';

  gravaLinhaLog('[CONSULTA_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CONSULTA_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

// Download da CT-e
function downloadCTe(chCTe, tpDown, tpAmb: String): String;
var
  json: String;
  url, resposta, status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"chCTe": "'        + chCTe  + '",' +
              '"tpDown": "'       + tpDown + '",' +
              '"tpAmb": "'        + tpAmb  + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/get';

  gravaLinhaLog('[DOWNLOAD_CTE_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  if (status <> '200') then
  begin
    gravaLinhaLog('[DOWNLOAD_CTE_RESPOSTA]');
    gravaLinhaLog(resposta);
  end
  else
  begin
    gravaLinhaLog('[DOWNLOAD_CTE_STATUS]');
    gravaLinhaLog(status);
  end;

  Result := resposta;
end;

// Download da CT-e e Salvar
function downloadCTeESalvar(chCTe, tpDown, tpAmb: String;
  caminho: String = ''; exibeNaTela: boolean = false): String;
var
  xml, json, pdf: String;
  status, resposta: String;
  jsonRetorno: TJSONObject;
begin

  resposta := downloadCTe(chCTe, tpDown, tpAmb);
  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  // Se o retorno da API for positivo, salva o que foi solicitado
  if status = '200' then
  begin
    if not DirectoryExists(caminho) then
      CreateDir(caminho);

    // Checa se deve baixar XML
    if Pos('X', tpDown) <> 0 then
    begin
      xml := jsonRetorno.GetValue('xml').Value;
      salvarXML(xml, caminho, chCTe);
    end;

    // Checa se deve baixar JSON
    if Pos('J', tpDown) <> 0 then
    begin
      if Pos('X', tpDown) = 0 then
      begin
        json := jsonRetorno.GetValue('cteProc').ToString;
        salvarJSON(json, caminho, chCTe);
      end;
    end;

    // Checa se deve baixar PDF
    if Pos('P', tpDown) <> 0 then
    begin
      pdf := jsonRetorno.GetValue('pdf').Value;
      salvarPDF(pdf, caminho, chCTe);

      if exibeNaTela then
        ShellExecute(0, nil, PChar(caminho + chCTe + '-procCTe.pdf'), nil, nil,
          SW_SHOWNORMAL);
    end;

  end
  else
  begin
    Showmessage('Ocorreu um erro, veja o Retorno da API para mais informa��es');
  end;

  Result := resposta;
end;

// Download do Evento da CT-e
function downloadEventoCTe(chCTe, tpDown, tpAmb, tpEvento,
  nSeqEvento: String): String;
var
  json: String;
  url, resposta, status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"chCTe": "'      + chCTe      + '",' +
              '"tpAmb": "'      + tpAmb      + '",' +
              '"tpDown": "'     + tpDown     + '",' +
              '"tpEvento": "'   + tpEvento   + '",' +
              '"nSeqEvento": "' + nSeqEvento + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/get/event/300';

  gravaLinhaLog('[DOWNLOAD_EVENTO_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');
  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  if (status <> '200') then
  begin
    gravaLinhaLog('[DOWNLOAD_EVENTO_RESPOSTA]');
    gravaLinhaLog(resposta);
  end
  else
  begin
    gravaLinhaLog('[DOWNLOAD_EVENTO_STATUS]');
    gravaLinhaLog(status);
  end;

  Result := resposta;
end;

// Download do Evento da CT-e e Salvar
function downloadEventoCTeESalvar(chCTe, tpDown, tpAmb, tpEvento,
  nSeqEvento: String; caminho: String = '';
  exibeNaTela: boolean = false): String;
var
  xml, json, pdf: String;
  status, resposta, tpEventoSalvar: String;
  jsonRetorno: TJSONObject;
begin

  resposta := downloadEventoCTe(chCTe, tpDown, tpAmb, tpEvento,
    nSeqEvento);
  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  // Se o retorno da API for positivo, salva o que foi solicitado
  if (status = '200') then
  begin

    // Checa qual o tipo de evento para salvar no nome do arquivo
    if (tpEvento.ToUpper = 'CANC') then
    begin
       tpEventoSalvar := '110111';
    end
    else
    begin
       tpEventoSalvar := '110110';
    end;

    // Checa se deve baixar XML
    if Pos('X', tpDown) <> 0 then
    begin
      xml := jsonRetorno.GetValue('xml').Value;
      salvarXML(xml, caminho, chCTe, tpEventoSalvar, nSeqEvento)
    end;

    // Checa se deve baixar JSON
    if Pos('J', tpDown) <> 0 then
    begin
      if Pos('X', tpDown) = 0 then
      begin
        json := jsonRetorno.GetValue('json').ToString;
        salvarJSON(json, caminho, chCTe, tpEventoSalvar, nSeqEvento);
      end;
    end;

    // Checa se deve baixar PDF
    if Pos('P', tpDown) <> 0 then
    begin
      pdf := jsonRetorno.GetValue('pdf').Value;
      salvarPDF(pdf, caminho, chCTe, tpEventoSalvar, nSeqEvento);
      if exibeNaTela then
        ShellExecute(0, nil, PChar(caminho + tpEventoSalvar + chCTe + nSeqEvento + '-procCTe.pdf'),
        nil, nil, SW_SHOWNORMAL);
    end;

  end
  else
  begin
    Showmessage('Ocorreu um erro, veja o Retorno da API para mais informa��es');
  end;

  Result := resposta;
end;

// Realizar o cancelamento da BP-e
function cancelarCTe(chCTe, tpAmb, dhEvento, nProt, xJust, tpDown,
  caminho: String; exibeNaTela: boolean = false): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"chCTe": "'        + chCTe    + '",' +
              '"tpAmb": "'        + tpAmb    + '",' +
              '"dhEvento": "'     + dhEvento + '",' +
              '"nProt": "'        + nProt    + '",' +
              '"xJust": "'        + xJust    + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/cancel/300';

  gravaLinhaLog('[CANCELAMENTO_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CANCELAMENTO_RESPOSTA]');
  gravaLinhaLog(resposta);

  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  if (status = '200') then
  begin
    respostaDownload := downloadEventoCTeESalvar(chCTe, tpDown, tpAmb,
      'CANC', '1', caminho, exibeNaTela);

    jsonRetorno := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(respostaDownload), 0) as TJSONObject;
    status := jsonRetorno.GetValue('status').Value;

    if (status <> '200') then
    begin
      ShowMessage('Ocorreu um erro ao fazer o download. Verifique os logs.')
    end;

  end;

  Result := resposta;
end;

// Realizar o evento de Nao Embarque da BP-e
function corrigirCTe(chCTe, tpAmb, dhEvento, nSeqEvento, grupoAlterado, campoAlterado,
valorAlterado, nroItemAlterado, tpDown, caminho: String; exibeNaTela: boolean = false): String;
var
  json: String;
  url, resposta, respostaDownload, infCorrecao: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  infCorrecao := '{' +
              '"grupoAlterado": "'     + grupoAlterado   + '",' +
              '"campoAlterado": "'     + campoAlterado   + '",' +
              '"valorAlterado": "'     + valorAlterado   + '",' +
              '"nroItemAlterado": "'   + nroItemAlterado + '"'  +
          '}';

  json := '{' +
            '"chCTe": "'        + chCTe       + '",' +
            '"tpAmb": "'        + tpAmb       + '",' +
            '"dhEvento": "'     + dhEvento    + '",' +
            '"nSeqEvento": "'   + nSeqEvento  + '",' +
            '"infCorrecao": "'  + infCorrecao + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/cce';

  gravaLinhaLog('[CCE_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CEE_RESPOSTA]');
  gravaLinhaLog(resposta);

  jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(resposta),
    0) as TJSONObject;
  status := jsonRetorno.GetValue('status').Value;

  if (status = '200') then
  begin
    respostaDownload := downloadEventoCTeESalvar(chCTe, tpDown, tpAmb,
      'CCE', nSeqEvento, caminho, exibeNaTela);

    jsonRetorno := TJSONObject.ParseJSONValue
      (TEncoding.ASCII.GetBytes(respostaDownload), 0) as TJSONObject;
    status := jsonRetorno.GetValue('status').Value;

    if (status <> '200') then
    begin
      ShowMessage('Ocorreu um erro ao fazer o download. Verifique os logs.')
    end;
  end;

  Result := resposta;
end;

function consultarCadastroContribuinte(CNPJCont, UF, documentoConsulta, tpConsulta:String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"CNPJCont": "'             + CNPJCont           + '",' +
              '"UF": "'                   + UF                 + '",' +
              '"' + tpConsulta + '": "'   + documentoConsulta  + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/util/conscad';

  gravaLinhaLog ('[CONSULTA_CADASTRO_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CONSULTA_CADASTRO_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

function consultarSituacao(licencaCNPJ, chCTe, tpAmb:String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"chCTe": "'        + chCTe        + '",' +
              '"licencaCnpj": "'  + licencaCNPJ  + '",' +
              '"tpAmb": "'        + tpAmb        + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/stats/300';

  gravaLinhaLog ('[CONSULTA_SITUACAO_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CONSULTA_SITUACAO_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

function inutilizar(cUF, tpAmb, ano, CNPJ, modelo, serie, nCTIni,
 nCTFin, xJust:String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"cUF": "'     + cUF     + '",' +
              '"ano": "'     + ano     + '",' +
              '"CNPJ": "'    + CNPJ    + '",' +
              '"mod": "'     + modelo  + '",' +
              '"serie": "'   + serie   + '",' +
              '"nCTIni": "'  + nCTIni  + '",' +
              '"nCTFin": "'  + nCTFin  + '",' +
              '"xJust": "'   + xJust   + '",' +
              '"tpAmb": "'   + tpAmb   + '"'  +
          '}';

  url := 'https://cte.ns.eti.br/cte/inut';

  gravaLinhaLog ('[INUTILIZACAO_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[INUTILIZACAO_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

function listarNSNRecs(chCTe:String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
begin

  json := '{' +
              '"chCTe": "'        + chCTe        + '"' +
          '}';

  url := 'https://cte.ns.eti.br/util/list/nsnrecs';

  gravaLinhaLog ('[LISTAR_NSNRECS_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[LISTAR_NSNRECS_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

// Fun��o para salvar o XML de retorno
function salvarXML(xml, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  arquivo: TextFile;
  conteudoSalvar, localParaSalvar: String;
begin
  // Seta o caminho para o arquivo XML
  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.xml';

  // Associa o arquivo ao caminho
  AssignFile(arquivo, localParaSalvar);
  // Abre para escrita o arquivo
  Rewrite(arquivo);

  // Copia o retorno
  conteudoSalvar := xml;
  // Ajeita o XML retirando as barras antes das aspas duplas
  conteudoSalvar := StringReplace(conteudoSalvar, '\"', '"',
    [rfReplaceAll, rfIgnoreCase]);

  // Escreve o retorno no arquivo
  Writeln(arquivo, conteudoSalvar);

  // Fecha o arquivo
  CloseFile(arquivo);
end;

// Fun��o para salvar o JSON de retorno
function salvarJSON(json, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  arquivo: TextFile;
  conteudoSalvar, localParaSalvar: String;
begin
  // Seta o caminho para o arquivo JSON
  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.json';

  // Associa o arquivo ao caminho
  AssignFile(arquivo, localParaSalvar);
  // Abre para escrita o arquivo
  Rewrite(arquivo);

  // Copia o retorno
  conteudoSalvar := json;

  // Escreve o retorno no arquivo
  Writeln(arquivo, conteudoSalvar);

  // Fecha o arquivo
  CloseFile(arquivo);
end;

// Fun��o para salvar o PDF de retorno
function salvarPDF(pdf, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  conteudoSalvar, localParaSalvar: String;
  base64decodificado: TStringStream;
  arquivo: TFileStream;
begin
  /// /Seta o caminho para o arquivo PDF
  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.pdf';

  // Copia e cria uma TString com o base64
  conteudoSalvar := pdf;
  base64decodificado := TStringStream.Create(conteudoSalvar);

  // Cria o arquivo .pdf e decodifica o base64 para o arquivo
  try
    arquivo := TFileStream.Create(localParaSalvar, fmCreate);
    try
      DecodeStream(base64decodificado, arquivo);
    finally
      arquivo.Free;
    end;
  finally
    base64decodificado.Free;
  end;
end;

// Grava uma linha no log
procedure gravaLinhaLog(conteudo: String);
var
  caminhoEXE, nomeArquivo, data: String;
  log: TextFile;
begin
  // Pega o caminho do execut�vel
  caminhoEXE := ExtractFilePath(GetCurrentDir);
  caminhoEXE := caminhoEXE + 'log\';

  // Pega a data atual
  data := DateToStr(Date);

  // Ajeita o XML retirando as barras antes das aspas duplas
  data := StringReplace(data, '/', '', [rfReplaceAll, rfIgnoreCase]);

  nomeArquivo := caminhoEXE + data;

  // Se diret�rio \log n�o existe, � criado
  if not DirectoryExists(caminhoEXE) then
    CreateDir(caminhoEXE);

  AssignFile(log, nomeArquivo + '.txt');
{$I-}
  Reset(log);
{$I+}
  if (IOResult <> 0) then
    Rewrite(log) { arquivo n�o existe e ser� criado }
  else
  begin
    CloseFile(log);
    Append(log); { o arquivo existe e ser� aberto para sa�das adicionais }
  end;

  Writeln(log, DateTimeToStr(Now) + ' - ' + conteudo);

  CloseFile(log);
end;

end.


