program CTeAPIClientDelphi10_1;

uses
  Vcl.Forms,
  principal in 'principal.pas' {frmPrincipal},
  CTeAPI in 'CTeAPI.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
