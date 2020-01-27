unit CTeAPI;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, IdHTTP, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack,
  IdSSL, IdSSLOpenSSL, ShellApi, IdCoderMIME, EncdDecd;

// Assinatura das funções
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
function enviaEmailCTe(chCTe, email, enviaEmailDoc: String): String;
function comprovanteEntregaCTe(chCTe, tpAmb, dhEvento, nProt, nSeqEvento,
dhEntrega, nDoc, xNome, latitude, dhHashEntrega, longitude, hashEntrega,
chavesEntregues: String): String;
function cancelamentoCECTe(chCTe, tpAmb, dhEvento, nProt, nProtCE: String): String;
function salvarXML(xml, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
function salvarJSON(json, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
function salvarPDF(pdf, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
procedure gravaLinhaLog(conteudo: String);

implementation

uses
    System.json, StrUtils, System.Types;
var
  tempoEspera: Integer = 500;
  token: String = 'SEU_TOKEN';

// Função genérica de envio para um url, contendo o token no header
function enviaConteudoParaAPI(conteudoEnviar, url, tpConteudo: String): String;
var
  retorno: String;
  conteudo: TStringStream;
  HTTP: TIdHTTP; // Disponível na aba 'Indy Servers'
  IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
  // Disponivel na aba Indy I/O Handlers
begin
  conteudo := TStringStream.Create(conteudoEnviar, TEncoding.UTF8);
  HTTP := TIdHTTP.Create(nil);
  try
    if tpConteudo = 'txt' then
    begin
      HTTP.Request.ContentType := 'text/plain;charset=utf-8';
    end
    else if tpConteudo = 'xml' then
    begin
      HTTP.Request.ContentType := 'application/xml;charset=utf-8';
    end
    else
    begin
      HTTP.Request.ContentType := 'application/json;charset=utf-8';
    end;

    IdSSLIOHandlerSocketOpenSSL1 := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    HTTP.IOHandler := IdSSLIOHandlerSocketOpenSSL1;
    HTTP.Request.ContentEncoding := 'UTF-8';
    HTTP.Request.CustomHeaders.Values['X-AUTH-TOKEN'] := token;

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

  Result := retorno;
end;

// Esta função emite uma CT-e de forma síncrona, fazendo o envio, a consulta e o download da nota
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

    sleep(tempoEspera);

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

  if status = '200' then
  begin
    if not DirectoryExists(caminho) then
      CreateDir(caminho);

    if Pos('X', tpDown) <> 0 then
    begin
      xml := jsonRetorno.GetValue('xml').Value;
      salvarXML(xml, caminho, chCTe);
    end;

    if Pos('J', tpDown) <> 0 then
    begin
      if Pos('X', tpDown) = 0 then
      begin
        json := jsonRetorno.GetValue('cteProc').ToString;
        salvarJSON(json, caminho, chCTe);
      end;
    end;

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
    Showmessage('Ocorreu um erro, veja o Retorno da API para mais informações');
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

  if (status = '200') then
  begin

    if (tpEvento.ToUpper = 'CANC') then
    begin
       tpEventoSalvar := '110111';
    end
    else
    begin
       tpEventoSalvar := '110110';
    end;

    if Pos('X', tpDown) <> 0 then
    begin
      xml := jsonRetorno.GetValue('xml').Value;
      salvarXML(xml, caminho, chCTe, tpEventoSalvar, nSeqEvento)
    end;

    if Pos('J', tpDown) <> 0 then
    begin
      if Pos('X', tpDown) = 0 then
      begin
        json := jsonRetorno.GetValue('json').ToString;
        salvarJSON(json, caminho, chCTe, tpEventoSalvar, nSeqEvento);
      end;
    end;

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
    Showmessage('Ocorreu um erro, veja o Retorno da API para mais informações');
  end;

  Result := resposta;
end;

// Realizar o cancelamento da CT-e
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

// Realizar o evento de Nao Embarque da CT-e
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

// Consulta o cadastro do contribuinte de CT-e
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

// Consulta situação do CT-e
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

// Inutiliza uma numeração de CT-e
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

// Lista nsNRecs do CT-e
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

// Realiza o envio de e-mail de uma CT-e
function enviaEmailCTe(chNFe, email, enviaEmailDoc: String): String;
var
  quantidade, i: Integer;
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  emails: TStringDynArray;
  jsonRetorno: TJSONObject;
begin
  // Monta o Json
  json := '{' +
              '"chCTe": "'           + chCTe         + '",' +
              '"enviaEmailDoc": "'   + enviaEmailDoc + '",' +
              '"email": [';

  emails := SplitString(Trim(email), ',');
  quantidade := length(emails)-1;

  for i := 0 to quantidade do
  begin
     if (i = quantidade) then
     begin
        json := json + '"' + emails[i] + '"';
     end
     else
     begin
        json := json + '"' + emails[i] + '",';
     end;
  end;

  json := json + ']}';

  url := 'https://cte.ns.eti.br/util/resendemail';

  gravaLinhaLog('[ENVIO_EMAIL_DADOS]');
  gravaLinhaLog(json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[ENVIO_EMAIL_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

//  Realiza o comprovante de entrega de um CT-e
function comprovanteEntregaCTe(chCTe, tpAmb, dhEvento, nProt, nSeqEvento,
dhEntrega, nDoc, xNome, latitude, dhHashEntrega, longitude, hashEntrega,
chavesEntregues: String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
  quantidade, i: Integer;
  chaves: TStringDynArray;
begin
   if (longitude = '') and (latitude = '') then
   begin
     json := '{' +
              '"latitude": "'  + latitude  + '",' +
              '"longitude": "' + longitude + '",';
  end;

  if (chavesEntregues = '') then
   begin
      json := json + '"chavesEntregues": [';

      chaves := SplitString(Trim(chaves), ',');
      quantidade := length(chaves)-1;

      for i := 0 to quantidade do
      begin
         if (i = quantidade) then
         begin
            json := json + '"' + chaves[i] + '"';
         end
         else
         begin
            json := json + '"' + chaves[i] + '",';
         end;
      end;

      json := json + '],';
  end;

  json := json +
              '"chCTe": "'         + chCTe         + '",' +
              '"tpAmb": "'         + tpAmb         + '",' +
              '"dhEvento": "'      + dhEvento      + '",' +
              '"nProt": "'         + nProt         + '",' +
              '"nSeqEvento": "'    + nSeqEvento    + '",' +
              '"dhEntrega": "'     + dhEntrega     + '",' +
              '"nDoc": "'          + nDoc          + '",' +
              '"xNome": "'         + xNome         + '",' +
              '"hashEntrega": "'   + hashEntrega   + '",' +
              '"dhHashEntrega": "' + dhHashEntrega + '"}';

  url := 'https://cte.ns.eti.br/cte/compentrega';

  gravaLinhaLog ('[COMPROVANTE_ENTREGA_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[COMPROVANTE_ENTREGA_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

// Realiza o cancelamento do comprovante de entrega de um CT-e
function cancelamentoCECTe(chCTe, tpAmb, dhEvento, nProt, nProtCE: String): String;
var
  json: String;
  url, resposta, respostaDownload: String;
  status: String;
  jsonRetorno: TJSONObject;
  quantidade, i: Integer;
  chaves: TStringDynArray;
begin

  json := '{' +
              '"chCTe": "'    + chCTe    + '",' +
              '"tpAmb": "'    + tpAmb    + '",' +
              '"dhEvento": "' + dhEvento + '",' +
              '"nProt": "'    + nProt    + '",' +
              '"nProtCE": "'  + nProtCE  + '"}';

  url := 'https://cte.ns.eti.br/cte/compentregacanc';

  gravaLinhaLog ('[CANC_CE_DADOS]');
  gravaLinhaLog (json);

  resposta := enviaConteudoParaAPI(json, url, 'json');

  gravaLinhaLog('[CANC_CE_RESPOSTA]');
  gravaLinhaLog(resposta);

  Result := resposta;
end;

// Função para salvar o XML de retorno
function salvarXML(xml, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  arquivo: TextFile;
  conteudoSalvar, localParaSalvar: String;
begin

  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.xml';
  AssignFile(arquivo, localParaSalvar);
  Rewrite(arquivo);
  conteudoSalvar := xml;
  conteudoSalvar := StringReplace(conteudoSalvar, '\"', '"',
    [rfReplaceAll, rfIgnoreCase]);
  Writeln(arquivo, conteudoSalvar);
  CloseFile(arquivo);
end;

// Função para salvar o JSON de retorno
function salvarJSON(json, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  arquivo: TextFile;
  conteudoSalvar, localParaSalvar: String;
begin

  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.json';
  AssignFile(arquivo, localParaSalvar);
  Rewrite(arquivo);
  conteudoSalvar := json;
  Writeln(arquivo, conteudoSalvar);
  CloseFile(arquivo);
end;

// Função para salvar o PDF de retorno
function salvarPDF(pdf, caminho, chCTe: String; tpEvento: String = ''; nSeqEvento: String = ''): String;
var
  conteudoSalvar, localParaSalvar: String;
  base64decodificado: TStringStream;
  arquivo: TFileStream;
begin

  localParaSalvar := caminho + tpEvento + chCTe + nSeqEvento + '-procCTe.pdf';
  conteudoSalvar := pdf;
  base64decodificado := TStringStream.Create(conteudoSalvar);
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

  caminhoEXE := ExtractFilePath(GetCurrentDir);
  caminhoEXE := caminhoEXE + 'log\';
  data := DateToStr(Date);
  data := StringReplace(data, '/', '', [rfReplaceAll, rfIgnoreCase]);
  nomeArquivo := caminhoEXE + data;
  if not DirectoryExists(caminhoEXE) then
    CreateDir(caminhoEXE);

  AssignFile(log, nomeArquivo + '.txt');
{$I-}
  Reset(log);
{$I+}
  if (IOResult <> 0) then
    Rewrite(log) { arquivo não existe e será criado }
  else
  begin
    CloseFile(log);
    Append(log); { o arquivo existe e será aberto para saídas adicionais }
  end;

  Writeln(log, DateTimeToStr(Now) + ' - ' + conteudo);

  CloseFile(log);
end;

end.


