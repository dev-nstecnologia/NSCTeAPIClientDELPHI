object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'frmPrincipal'
  ClientHeight = 609
  ClientWidth = 580
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel
    Left = 360
    Top = 8
    Width = 38
    Height = 16
    Caption = 'CNPJ:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object labelTokenEnviar: TLabel
    Left = 8
    Top = 8
    Width = 64
    Height = 16
    Caption = 'Salvar em:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object txtCNPJ: TEdit
    Left = 400
    Top = 8
    Width = 154
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object txtCaminhoSalvar: TEdit
    Left = 75
    Top = 8
    Width = 269
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Text = '.\Notas\'
  end
  object pgControl: TPageControl
    Left = 8
    Top = 47
    Width = 561
    Height = 561
    ActivePage = formEmissao
    Align = alCustom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    object formEmissao: TTabSheet
      Caption = 'Emiss'#227'o S'#237'ncrona'
      object Label1: TLabel
        Left = 16
        Top = 15
        Width = 61
        Height = 16
        Caption = 'Conteudo:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label2: TLabel
        Left = 339
        Top = 15
        Width = 111
        Height = 16
        Caption = 'Tipo de Conteudo:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label3: TLabel
        Left = 16
        Top = 204
        Width = 119
        Height = 16
        Caption = 'Tipo de Download*:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label4: TLabel
        Left = 158
        Top = 241
        Width = 372
        Height = 16
        Caption = '* X - XML; J - JSON; P - PDF; XP - XML e PDF; JP - JSON e PDF'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label5: TLabel
        Left = 239
        Top = 204
        Width = 110
        Height = 16
        Caption = 'Tipo de Ambiente:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label7: TLabel
        Left = 15
        Top = 241
        Width = 49
        Height = 16
        Caption = 'Modelo:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object btnEnviar: TButton
        Left = 21
        Top = 277
        Width = 516
        Height = 28
        Caption = 'Enviar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnEnviarClick
      end
      object memoConteudoEnviar: TMemo
        Left = 21
        Top = 37
        Width = 511
        Height = 153
        ScrollBars = ssBoth
        TabOrder = 1
      end
      object cbTpConteudo: TComboBox
        Left = 456
        Top = 3
        Width = 76
        Height = 28
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 2
        Text = 'txt'
        Items.Strings = (
          'txt'
          'xml'
          'json')
      end
      object chkExibir: TCheckBox
        Left = 421
        Top = 205
        Width = 111
        Height = 17
        Caption = 'Exibir em tela?'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
      end
      object GroupBox4: TGroupBox
        Left = 3
        Top = 311
        Width = 544
        Height = 212
        Caption = 'Retorno API'
        TabOrder = 4
        object memoRetorno: TMemo
          Left = 12
          Top = 24
          Width = 517
          Height = 177
          TabOrder = 0
        end
      end
      object cbTpDown: TComboBox
        Left = 141
        Top = 199
        Width = 52
        Height = 28
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 5
        Text = 'XP'
        Items.Strings = (
          'XP'
          'JP'
          'J'
          'P'
          'X')
      end
      object cbTpAmb: TComboBox
        Left = 355
        Top = 199
        Width = 46
        Height = 28
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 6
        Text = '2'
        Items.Strings = (
          '2'
          '1')
      end
      object cbModelo: TComboBox
        Left = 70
        Top = 236
        Width = 52
        Height = 28
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 7
        Text = '57'
        Items.Strings = (
          '57'
          '67')
      end
    end
  end
end
