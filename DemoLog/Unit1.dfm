object Form1: TForm1
  Left = 235
  Top = 249
  Width = 655
  Height = 284
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnlogtext: TButton
    Left = 168
    Top = 208
    Width = 75
    Height = 25
    Caption = 'btnlogtext'
    TabOrder = 0
    OnClick = btnlogtextClick
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 647
    Height = 185
    Align = alTop
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Button1: TButton
    Left = 368
    Top = 208
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 2
    OnClick = Button1Click
  end
end
