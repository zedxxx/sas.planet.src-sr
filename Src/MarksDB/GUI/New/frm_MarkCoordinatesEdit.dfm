object frmMarkCoordinatesEdit: TfrmMarkCoordinatesEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Add New Placemark'
  ClientHeight = 85
  ClientWidth = 321
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblCoords: TLabel
    Left = 8
    Top = 8
    Width = 106
    Height = 13
    Caption = 'Coordiantes (lat, lon):'
  end
  object edtCoords: TEdit
    Left = 8
    Top = 24
    Width = 306
    Height = 21
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object btnNext: TButton
    Left = 156
    Top = 54
    Width = 75
    Height = 25
    Caption = 'Next'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 237
    Top = 54
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
