VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CAppEvents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public WithEvents App As Application
Attribute App.VB_VarHelpID = -1

Private Sub App_SheetChange(ByVal Sh As Object, ByVal Target As Range)
    HandleApplicationSheetChange Sh, Target
End Sub

Private Sub App_WorkbookActivate(ByVal Wb As Workbook)
    HandleWorkbookActivate Wb
End Sub

Private Sub App_WorkbookBeforeClose(ByVal Wb As Workbook, Cancel As Boolean)
    HandleWorkbookBeforeClose Wb
End Sub
