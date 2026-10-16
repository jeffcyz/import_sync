VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CColorJob"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public WorkbookName As String
Public WorkbookFullName As String
Public WorksheetName As String
Public WorksheetIndex As Long
Public TargetAddress As String
Public NextCellIndex As Long
Public TotalCells As Long
