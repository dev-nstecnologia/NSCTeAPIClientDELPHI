# NSCTeAPIClientDELPHI

Esta página apresenta trechos de códigos de um módulo em DELPHI 10 que foi desenvolvido para consumir as funcionalidades da NS CT-e API.

-------

## Primeiros passos:

### Integrando ao sistema:

Para utilizar as funções de comunicação com a API, você precisa realizar os seguintes passos:

1. Extraia o conteúdo da pasta compactada que você baixou;
2. Copie para a pasta da sua aplicação a classe **CTeAPI.pas**, que esta na pasta raiz;
3. Abra o seu projeto e importe a pasta copiada.
4. A aplicação utiliza as bibliotecas **Indy 10** e **System.JSON** para realizar a comunicação com a API e fazer a manipulação de dados JSON, respectivamente. As referências já estão referenciadas na classe.

**OBS.:** Caso ocorra erro ao compilar o projeto(Could Not Load SSL Library), pode significar que o mesmo não possua, em sua pasta Debug, duas dlls essenciais para a execução do código. Veja mais informações de como resolver o problema em um post do blog: [Erro de SSL](https://nstecnologia.com.br/blog/could-not-load-ssl-library/)

**Pronto!** Agora, você já pode consumir a NS CT-e API através do seu sistema. Todas as funcionalidades de comunicação foram implementadas na classe CTeAPI.pas. Confira abaixo sobre realizar uma emissão completa.

------

## Emissão Sincrona:

### Realizando uma Emissão:

Para realizar uma emissão completa, você poderá utilizar a função emitirCTeSincrono do módulo CTeAPI. Veja abaixo sobre os parâmetros necessários, e um exemplo de chamada do método.

##### Parâmetros:

**ATENÇÃO:** o **token** também é um parâmetro necessário e você deve primeiramente defini-lo no módulo CTeAPI.pas. Ele é uma constante do módulo. 

Parametros     | Descrição
:-------------:|:-----------
conteudo       | Conteúdo de emissão do documento.
tpConteudo     | Tipo de conteúdo que está sendo enviado. Valores possíveis: json, xml, txt
CNPJ           | CNPJ do emitente do documento.
tpDown         | Tipo de arquivos a serem baixados.Valores possíveis: <ul> <li>**X** - XML</li> <li>**J** - JSON</li> <li>**P** - PDF</li> <li>**XP** - XML e PDF</li> <li>**JP** - JSON e PDF</li> </ul> 
tpAmb          | Ambiente onde foi autorizado o documento.Valores possíveis:<ul> <li>1 - produção</li> <li>2 - homologação</li> </ul>
caminho        | Caminho onde devem ser salvos os documentos baixados.
exibeNaTela    | Se for baixado, exibir o PDF na tela após a autorização.Valores possíveis: <ul> <li>**True** - será exibido</li> <li>**False** - não será exibido</li> </ul> 

##### Exemplo de chamada:

Após ter todos os parâmetros listados acima, você deverá fazer a chamada da função. Veja o código de exemplo abaixo:
           
    retorno := emitirCTeSincrono(conteudo, tpConteudo, CNPJ, tpDown, tpAmb, modelo, caminho, exibeNaTela);
    ShowMessage(retorno);
    
A função **emitirCTeSincrono** fará o envio, a consulta e download do documento, utilizando as funções emitirCTe, consultarStatusProcessamento e downloadCTeESalvar, presentes no módulo CTeAPI.pas. Por isso, o retorno será um JSON com os principais campos retornados pelos métodos citados anteriormente. No exemplo abaixo, veja como tratar o retorno da função emitirCTeSincrono:

##### Exemplo de tratamento de retorno:

O JSON retornado pelo método terá os seguintes campos: statusEnvio, statusConsulta, statusDownload, cStat, chCTe, nProt, motivo, nsNRec, erros. Veja o exemplo abaixo:

    {
        "statusEnvio": "200",
        "statusConsulta": "200",
        "statusDownload": "200",
        "cStat": "100",
        "chCTe": "43181007364617000135550000000119741004621864",
        "nProt": "143180007036833",
        "motivo": "Autorizado o uso da CT-e",
        "nsNRec": "313022",
        "erros": ""
    }
      
Confira um código para tratamento do retorno, no qual pegará as informações dispostas no JSON de Retorno disponibilizado:

	retorno := emitirCTeSincrono(conteudoEnviar, 'json', '11111111111111', 'XP', '2', '57', 'C:\Documentos', True);
 
    jsonRetorno := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(retorno), 0) as TJSONObject;
	statusEnvio := jsonRetorno.GetValue('statusEnvio').Value;
	statusConsulta := jsonRetorno.GetValue('statusConsulta').Value;
    statusDownload := jsonRetorno.GetValue('statusDownload').Value;
    cStat := jsonRetorno.GetValue('cStat').Value;
    chCTe := jsonRetorno.GetValue('chCTe').Value;
    nProt := jsonRetorno.GetValue('nProt').Value;
    motivo := jsonRetorno.GetValue('motivo').Value;
	nsNRec := jsonRetorno.GetValue('nsNRec').Value;
    erros := jsonRetorno.GetValue('erros').Value;
    // Testa se houve sucesso na emissão
    if ((statusEnvio = '200') Or (statusEnvio = '-6')) then
    begin
		if(statusConsulta = '200')	
		begin
      		if (cStat = '100') then
      		begin
        		ShowMessage(motivo);
        		if (statusDownload <> '200') then
        		begin
          			// Aqui você pode realizar um tratamento em caso de erro no download
        		end
      		end
      		else
      		begin
        		ShowMessage(motivo);
      		end
		end
		else
		begin
			ShowMessage(motivo + #13 + erros);
		end
    end
    else
    begin
      ShowMessage(motivo + #13 + erros);
    end;

-----

## Demais Funcionalidades:

No módulo NFeAPI, você pode encontrar também as seguintes funcionalidades:

NOME                     | FINALIDADE             | DOCUMENTAÇÂO CONFLUENCE
:-----------------------:|:----------------------:|:-----------------------
**enviaConteudoParaAPI** | Função genérica que envia um conteúdo para API. Requisições do tipo POST.|
**emitirCTe** | Envia um CT-e para processamento.|[Emitir CT-e](https://confluence.ns.eti.br/pages/viewpage.action?pageId=20611437#Emiss%C3%A3oCT-e3.00API-Emiss%C3%A3odeCT-e).
**consultarStatusProcessamento** | Consulta o status de processamento de um CT-e.| [Status de Processamento do CT-e](https://confluence.ns.eti.br/pages/viewpage.action?pageId=20611437#Emiss%C3%A3oCT-e3.00API-StatusdeProcessamentodoCT-e).
**downloadCTe** | Baixa documentos de emissão de um CT-e autorizado. | [Download do CT-e](https://confluence.ns.eti.br/pages/viewpage.action?pageId=20611437#Emiss%C3%A3oCT-e3.00API-DownloaddoCT-e)
**downloadCTeESalvar** | Baixa documentos de emissão de um CT-e autorizado e salva-os em um diretório. | Por utilizar o método downloadCTe, a documentação é a mesma. 
**downloadEventoCTe** | Baixa documentos de evento de um CT-e autorizado | [Download de Evento de CT-e](https://confluence.ns.eti.br/display/PUB/Download+de+Evento+na+NS+CT-e+API).
**downloadEventoCTeESalvar** | Baixa documentos de evento de um CT-e autorizado e salva-os em um diretório. | Por utilizar o método downloadEventoCTe, a documentação é a mesma.
**cancelarCTe** | Realiza o cancelamento de um CT-e. | [Cancelamento de CT-e](https://confluence.ns.eti.br/display/PUB/Cancelamento+CT-e+API).
**corrigirCTe** | Realiza a CC-e de um CT-e. | [Carta de Correção de CT-e](https://confluence.ns.eti.br/pages/viewpage.action?pageId=13861593).
**consultarCadastroContribuinte** | Consulta o cadastro de um contribuinte. | [Consulta Cadastro de Contribuinte](https://confluence.ns.eti.br/display/PUB/Consulta+Cadastro+de+Contribuinte+na+CT-e+API).
**consultarSituacao** | Consulta a situação de um CT-e na Sefaz. | [Consulta Situação de CT-e](https://confluence.ns.eti.br/pages/viewpage.action?pageId=13861595).
**inutilizar** | Inutiliza numerações de CT-e. | [Inutilização de Numeração](https://confluence.ns.eti.br/pages/viewpage.action?pageId=13861597).
**listarNSNRecs** | Lista os nsNRec vinculados a um CT-e. | [Lista de NSNRecs vinculados a um CT-e](https://confluence.ns.eti.br/display/PUB/Lista+de+NSNRecs+vinculados+a+um+CT-e+na+NS+CT-e+API).
**salvarXML** | Salva um XML em um diretório. | 
**salvarJSON** | Salva um JSON em um diretório. |
**salvarPDF** |	Salva um PDF em um diretório. | 
**gravaLinhaLog** | Grava uma linha de texto no arquivo de log. | 



![Ns](https://nstecnologia.com.br/blog/wp-content/uploads/2018/11/ns%C2%B4tecnologia.png) | Obrigado pela atenção!
