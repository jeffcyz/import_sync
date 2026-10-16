Attribute VB_Name = "modAutoColor"
Option Explicit

'=====================================================================
' AutoColor on Entry
'
' Default state:
'   OFF for every workbook at every Excel startup.
'
' Enable scope:
'   Only the workbook that the user explicitly enables is monitored.
'   Other open workbooks remain OFF.
'
' Keyboard shortcut:
'   Ctrl+Shift+A toggles AutoColor for the active workbook.
'=====================================================================

Public gAppEvents As CAppEvents
Public gRibbonUI As Object

Private gEnabledWorkbooks As Collection
Private gColorQueue As Collection
Private gFormulaClassCache As Object
Private gQueueRunAt As Date
Private gQueueScheduled As Boolean
Private gProcessing As Boolean

Private Const AUTO_COLOR_MAX_IMMEDIATE_CELLS As Long = 10000
Private Const AUTO_COLOR_QUEUE_BATCH_SIZE As Long = 2500
Private Const AUTO_COLOR_JOB_MAX_CELLS As Long = 250000
Private Const AUTO_COLOR_MAX_TOTAL_QUEUE As Long = 2000000
Private Const AUTOCOLOR_TEXT_INPUTS As Boolean = False

Private Enum AutoColorClass
    accNone = 0
    accInput = 1
    accFormula = 2
    accWorksheetLink = 3
    accWorkbookLink = 4
    accPartialInput = 5
    accHyperlink = 6
    accExternalData = 7
End Enum

'=====================================================================
' Add-in lifecycle
'=====================================================================

Public Sub Auto_Open()
    InitializeAutoColorAddin
End Sub

Public Sub Auto_Close()
    On Error Resume Next

    Application.OnKey "^+a"

    If gQueueScheduled Then
        Application.OnTime _
            EarliestTime:=gQueueRunAt, _
            Procedure:=QualifiedMacroName("ProcessAutoColorQueue"), _
            Schedule:=False
    End If

    Set gAppEvents.App = Nothing
    Set gAppEvents = Nothing
    Set gEnabledWorkbooks = Nothing
    Set gColorQueue = Nothing
    Set gFormulaClassCache = Nothing

    gQueueScheduled = False
    gProcessing = False

    On Error GoTo 0
End Sub

Public Sub InitializeAutoColorAddin()
    On Error GoTo InitFailed

    If gEnabledWorkbooks Is Nothing Then
        Set gEnabledWorkbooks = New Collection
    End If

    If gColorQueue Is Nothing Then
        Set gColorQueue = New Collection
    End If

    If gFormulaClassCache Is Nothing Then
        Set gFormulaClassCache = CreateObject("Scripting.Dictionary")
        gFormulaClassCache.CompareMode = vbBinaryCompare
    End If

    If gAppEvents Is Nothing Then
        Set gAppEvents = New CAppEvents
        Set gAppEvents.App = Application
    End If

    Application.OnKey "^+a", QualifiedMacroName("ToggleAutoColorForCurrentWorkbook")
    Exit Sub

InitFailed:
    Application.StatusBar = "AutoColor add-in could not initialize: " & Err.Description
End Sub

'=====================================================================
' Developer-tab Ribbon callbacks
'=====================================================================

Public Sub RibbonOnLoad(ByVal ribbon As Object)
    Set gRibbonUI = ribbon
    InitializeAutoColorAddin
End Sub

Public Sub RibbonToggleAutoColor(ByVal control As Object, _
                                 ByVal pressed As Boolean)
    If pressed Then
        EnableAutoColorForCurrentWorkbook
    Else
        DisableAutoColorForCurrentWorkbook
    End If

    RefreshAutoColorRibbon
End Sub

Public Sub RibbonGetAutoColorPressed(ByVal control As Object, _
                                     ByRef returnedVal)
    On Error GoTo SafeExit

    returnedVal = False

    If ActiveWorkbook Is Nothing Then Exit Sub
    returnedVal = IsWorkbookEnabled(ActiveWorkbook)

SafeExit:
End Sub

Public Sub RibbonEnableAndScan(ByVal control As Object)
    EnableAndScanCurrentWorkbook
    RefreshAutoColorRibbon
End Sub

Public Sub RibbonScanWorkbook(ByVal control As Object)
    ScanCurrentWorkbook
End Sub

Public Sub RibbonScanSheet(ByVal control As Object)
    ScanCurrentSheet
End Sub

Public Sub RibbonScanSelection(ByVal control As Object)
    ScanCurrentSelection
End Sub

Public Sub RibbonShowStatus(ByVal control As Object)
    ShowAutoColorStatus
End Sub

Private Sub RefreshAutoColorRibbon()
    On Error Resume Next

    If Not gRibbonUI Is Nothing Then
        gRibbonUI.InvalidateControl "tglAutoColorCurrentWorkbook"
    End If

    On Error GoTo 0
End Sub

Private Function QualifiedMacroName(ByVal procedureName As String) As String
    QualifiedMacroName = "'" & Replace(ThisWorkbook.Name, "'", "''") & "'!" & procedureName
End Function

'=====================================================================
' Public workbook controls
'=====================================================================

Public Sub EnableAutoColorForCurrentWorkbook()
    Dim wb As Workbook

    InitializeAutoColorAddin
    Set wb = ActiveWorkbook

    If Not CanEnableWorkbook(wb, True) Then Exit Sub

    If Not IsWorkbookEnabled(wb) Then
        gEnabledWorkbooks.Add wb
    End If

    Application.StatusBar = "AutoColor: ON for " & wb.Name & _
                            " (all other workbooks keep their own OFF/ON state)"
    RefreshAutoColorRibbon
End Sub

Public Sub DisableAutoColorForCurrentWorkbook()
    Dim wb As Workbook

    InitializeAutoColorAddin
    Set wb = ActiveWorkbook

    If wb Is Nothing Then Exit Sub

    RemoveEnabledWorkbook wb
    CancelQueuedJobsForWorkbook wb

    Application.StatusBar = "AutoColor: OFF for " & wb.Name
    RefreshAutoColorRibbon
End Sub

Public Sub ToggleAutoColorForCurrentWorkbook()
    Dim wb As Workbook

    InitializeAutoColorAddin
    Set wb = ActiveWorkbook

    If Not CanEnableWorkbook(wb, True) Then Exit Sub

    If IsWorkbookEnabled(wb) Then
        DisableAutoColorForCurrentWorkbook
    Else
        EnableAutoColorForCurrentWorkbook
    End If
End Sub

Public Sub EnableAndScanCurrentWorkbook()
    EnableAutoColorForCurrentWorkbook

    If ActiveWorkbook Is Nothing Then Exit Sub
    If IsWorkbookEnabled(ActiveWorkbook) Then
        ScanCurrentWorkbook
    End If
End Sub

Public Sub ShowAutoColorStatus()
    Dim wb As Workbook
    Dim stateText As String

    InitializeAutoColorAddin
    Set wb = ActiveWorkbook

    If wb Is Nothing Then
        MsgBox "There is no active workbook.", vbInformation, "AutoColor"
        Exit Sub
    End If

    If IsWorkbookEnabled(wb) Then
        stateText = "ON"
    Else
        stateText = "OFF"
    End If

    MsgBox "AutoColor is " & stateText & " for:" & vbCrLf & _
           wb.Name & vbCrLf & vbCrLf & _
           "Ctrl+Shift+A toggles the active workbook." & vbCrLf & _
           "The default after starting Excel is OFF.", _
           vbInformation, "AutoColor status"
End Sub

Public Function AutoColorIsEnabledForCurrentWorkbook() As Boolean
    InitializeAutoColorAddin

    If ActiveWorkbook Is Nothing Then Exit Function
    AutoColorIsEnabledForCurrentWorkbook = IsWorkbookEnabled(ActiveWorkbook)
End Function

Public Function AutoColorCurrentWorkbookName() As String
    If ActiveWorkbook Is Nothing Then Exit Function
    AutoColorCurrentWorkbookName = ActiveWorkbook.Name
End Function

Public Function AutoColorRibbonIsLoaded() As Boolean
    AutoColorRibbonIsLoaded = Not (gRibbonUI Is Nothing)
End Function

'=====================================================================
' Manual catch-up scans
'=====================================================================

Public Sub ScanCurrentSelection()
    Dim target As Range

    InitializeAutoColorAddin

    If TypeName(Selection) <> "Range" Then
        MsgBox "Select one or more worksheet cells first.", vbInformation, "AutoColor"
        Exit Sub
    End If

    Set target = Selection
    QueueOrColorRange target, True, True
End Sub

Public Sub ScanCurrentSheet()
    InitializeAutoColorAddin

    If Not TypeOf ActiveSheet Is Excel.Worksheet Then
        MsgBox "Activate a worksheet first.", vbInformation, "AutoColor"
        Exit Sub
    End If

    QueueOrColorRange ActiveSheet.UsedRange, True, True
End Sub

Public Sub ScanCurrentWorkbook()
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim rejectedSheets As Long

    InitializeAutoColorAddin
    Set wb = ActiveWorkbook

    If Not CanEnableWorkbook(wb, True) Then Exit Sub

    For Each ws In wb.Worksheets
        If Not QueueOrColorRange(ws.UsedRange, True, True) Then
            rejectedSheets = rejectedSheets + 1
        End If
    Next ws

    If rejectedSheets > 0 Then
        Application.StatusBar = "AutoColor scan incomplete: " & _
                                CStr(rejectedSheets) & _
                                " worksheet(s) could not be processed or queued. Scan smaller ranges."
    ElseIf QueuedCellCount() > 0 Then
        Application.StatusBar = "AutoColor scan queued for " & wb.Name & _
                                " (non-empty cells only)"
    Else
        Application.StatusBar = "AutoColor scan finished for " & wb.Name & _
                                " (non-empty cells only)"
    End If
End Sub

Private Function NonEmptyCellsForScan(ByVal target As Range) As Range
    Dim scope As Range
    Dim area As Range
    Dim constants As Range
    Dim formulas As Range
    Dim matches As Range
    Dim result As Range

    ' Intersect first so whole-row/column selections do not expand the sheet.
    Set scope = Application.Intersect(target, target.Worksheet.UsedRange)
    If scope Is Nothing Then Exit Function

    For Each area In scope.Areas
        Set matches = Nothing

        ' SpecialCells on a single cell can search the entire UsedRange.
        If area.CountLarge = 1 Then
            If area.HasFormula Or Not IsEmpty(area.Value2) Then
                Set matches = area
            End If
        Else
            Set constants = ScanCellsOfType(area, xlCellTypeConstants)
            Set formulas = ScanCellsOfType(area, xlCellTypeFormulas)

            If constants Is Nothing Then
                Set matches = formulas
            ElseIf formulas Is Nothing Then
                Set matches = constants
            Else
                Set matches = Application.Union(constants, formulas)
            End If
        End If

        If Not matches Is Nothing Then
            If result Is Nothing Then
                Set result = matches
            Else
                Set result = Application.Union(result, matches)
            End If
        End If
    Next area

    ' Keep discontiguous cells discontiguous; their bounding rectangle includes blanks.
    Set NonEmptyCellsForScan = result
End Function

Private Function ScanCellsOfType(ByVal area As Range, _
                                 ByVal cellType As XlCellType) As Range
    Dim matches As Range
    Dim errorNumber As Long
    Dim errorDescription As String

    On Error GoTo NoMatches
    Set matches = area.SpecialCells(cellType)
    Set ScanCellsOfType = Application.Intersect(area, matches)
    Exit Function

NoMatches:
    errorNumber = Err.Number
    errorDescription = Err.Description
    ' Excel raises error 1004 when no cells of the requested type exist.
    If errorNumber <> 1004 Then
        Err.Raise errorNumber, "ScanCellsOfType", errorDescription
    End If
End Function

'=====================================================================
' Application event entry points
'=====================================================================

Public Sub HandleApplicationSheetChange(ByVal Sh As Object, ByVal Target As Range)
    Dim wb As Workbook

    On Error GoTo SafeExit

    If gProcessing Then Exit Sub
    If Target Is Nothing Then Exit Sub
    If Not TypeOf Sh Is Excel.Worksheet Then Exit Sub

    Set wb = Sh.Parent
    If Not IsWorkbookEnabled(wb) Then Exit Sub
    If Not CanEnableWorkbook(wb, False) Then Exit Sub

    QueueOrColorRange Target, False

SafeExit:
End Sub

Public Sub HandleWorkbookActivate(ByVal wb As Workbook)
    On Error Resume Next

    If IsWorkbookEnabled(wb) Then
        Application.StatusBar = "AutoColor: ON for " & wb.Name
    Else
        Application.StatusBar = "AutoColor: OFF for " & wb.Name
    End If

    RefreshAutoColorRibbon

    On Error GoTo 0
End Sub

Public Sub HandleWorkbookBeforeClose(ByVal wb As Workbook)
    On Error Resume Next
    RemoveEnabledWorkbook wb
    CancelQueuedJobsForWorkbook wb
    On Error GoTo 0
End Sub

'=====================================================================
' Workbook scope
'=====================================================================

Private Function CanEnableWorkbook(ByVal wb As Workbook, _
                                   ByVal showReason As Boolean) As Boolean
    Dim messageText As String
    Dim lowerName As String

    If wb Is Nothing Then
        messageText = "There is no active workbook."
        GoTo Rejected
    End If

    If wb Is ThisWorkbook Then
        messageText = "The AutoColor add-in itself cannot be enabled."
        GoTo Rejected
    End If

    If wb.IsAddin Then
        messageText = "Excel add-in workbooks are excluded."
        GoTo Rejected
    End If

    lowerName = LCase$(wb.Name)

    If lowerName = "personal.xlsb" Then
        messageText = "PERSONAL.XLSB is excluded."
        GoTo Rejected
    End If

    If EndsWith(lowerName, ".csv") Or _
       EndsWith(lowerName, ".txt") Or _
       EndsWith(lowerName, ".prn") Or _
       EndsWith(lowerName, ".dif") Or _
       EndsWith(lowerName, ".slk") Then
        messageText = "Text and CSV workbooks are excluded because they cannot save font colors."
        GoTo Rejected
    End If

    If wb.ReadOnly Then
        messageText = "This workbook is read-only, so AutoColor was not enabled."
        GoTo Rejected
    End If

    CanEnableWorkbook = True
    Exit Function

Rejected:
    CanEnableWorkbook = False

    If showReason Then
        MsgBox messageText, vbInformation, "AutoColor"
    End If
End Function

Private Function IsWorkbookEnabled(ByVal wb As Workbook) As Boolean
    Dim item As Object

    If wb Is Nothing Then Exit Function
    If gEnabledWorkbooks Is Nothing Then Exit Function

    For Each item In gEnabledWorkbooks
        If item Is wb Then
            IsWorkbookEnabled = True
            Exit Function
        End If
    Next item
End Function

Private Sub RemoveEnabledWorkbook(ByVal wb As Workbook)
    Dim i As Long
    Dim item As Object

    If wb Is Nothing Then Exit Sub
    If gEnabledWorkbooks Is Nothing Then Exit Sub

    For i = gEnabledWorkbooks.Count To 1 Step -1
        Set item = gEnabledWorkbooks(i)

        If item Is wb Then
            gEnabledWorkbooks.Remove i
        End If
    Next i
End Sub

Private Function EndsWith(ByVal valueText As String, ByVal suffix As String) As Boolean
    If Len(valueText) < Len(suffix) Then Exit Function
    EndsWith = (Right$(valueText, Len(suffix)) = suffix)
End Function

'=====================================================================
' Immediate work and background queue
'=====================================================================

Private Function QueueOrColorRange(ByVal target As Range, _
                                   ByVal userRequested As Boolean, _
                                   Optional ByVal nonEmptyOnly As Boolean = False) As Boolean
    On Error GoTo Failed

    If Not target Is Nothing Then
        If nonEmptyOnly Then Set target = NonEmptyCellsForScan(target)
    End If

    If target Is Nothing Then
        If userRequested Then Application.StatusBar = "AutoColor: no non-empty cells to scan."
        QueueOrColorRange = True
        Exit Function
    End If

    If target.CountLarge <= AUTO_COLOR_MAX_IMMEDIATE_CELLS Then
        AutoColorRange target

        If userRequested Then
            Application.StatusBar = "AutoColor finished: " & _
                                    Format$(target.CountLarge, "#,##0") & " cells"
        End If

        QueueOrColorRange = True
        Exit Function
    End If

    If target.CountLarge + QueuedCellCount() > AUTO_COLOR_MAX_TOTAL_QUEUE Then
        Application.StatusBar = "AutoColor queue limit reached; this range was not queued (" & _
                                Format$(target.CountLarge, "#,##0") & _
                                " cells). Scan a smaller selection."
        Exit Function
    End If

    AddRangeToQueue target
    ScheduleQueue

    Application.StatusBar = "AutoColor queued " & _
                            Format$(target.CountLarge, "#,##0") & " cells"
    QueueOrColorRange = True
    Exit Function

Failed:
    Application.StatusBar = "AutoColor could not process the range: " & Err.Description
End Function

Private Sub AddRangeToQueue(ByVal target As Range)
    Dim area As Range
    Dim chunk As Range
    Dim rowStart As Long
    Dim rowsThisJob As Long
    Dim rowsPerJob As Long

    If gColorQueue Is Nothing Then Set gColorQueue = New Collection

    For Each area In target.Areas
        rowsPerJob = AUTO_COLOR_JOB_MAX_CELLS \ area.Columns.CountLarge
        If rowsPerJob < 1 Then rowsPerJob = 1

        For rowStart = 1 To area.Rows.Count Step rowsPerJob
            rowsThisJob = rowsPerJob

            If rowStart + rowsThisJob - 1 > area.Rows.Count Then
                rowsThisJob = area.Rows.Count - rowStart + 1
            End If

            Set chunk = area.Rows(rowStart).Resize(rowsThisJob, area.Columns.Count)
            AddQueueJob chunk
        Next rowStart
    Next area
End Sub

Private Sub AddQueueJob(ByVal target As Range)
    Dim job As CColorJob
    Dim wb As Workbook
    Dim ws As Worksheet

    Set ws = target.Worksheet
    Set wb = ws.Parent
    Set job = New CColorJob

    job.WorkbookName = wb.Name
    job.WorkbookFullName = wb.FullName
    job.WorksheetName = ws.Name
    job.WorksheetIndex = ws.Index
    job.TargetAddress = target.Address(False, False, xlA1)
    job.NextCellIndex = 1
    job.TotalCells = CLng(target.CountLarge)

    gColorQueue.Add job
End Sub

Private Sub ScheduleQueue()
    If gQueueScheduled Then Exit Sub
    If gColorQueue Is Nothing Then Exit Sub
    If gColorQueue.Count = 0 Then Exit Sub

    gQueueRunAt = Now + TimeSerial(0, 0, 1)
    gQueueScheduled = True

    Application.OnTime _
        EarliestTime:=gQueueRunAt, _
        Procedure:=QualifiedMacroName("ProcessAutoColorQueue"), _
        Schedule:=True
End Sub

Public Sub ProcessAutoColorQueue()
    Dim job As CColorJob
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim target As Range
    Dim startIndex As Long
    Dim endIndex As Long

    Dim oldEvents As Boolean
    Dim oldScreenUpdating As Boolean
    Dim applicationStateCaptured As Boolean

    On Error GoTo CleanExit

    InitializeAutoColorAddin
    gQueueScheduled = False

    If gColorQueue Is Nothing Then Exit Sub
    If gColorQueue.Count = 0 Then Exit Sub

    Set job = gColorQueue(1)
    Set wb = FindQueuedWorkbook(job)

    If wb Is Nothing Then
        gColorQueue.Remove 1
        GoTo CleanExit
    End If

    Set ws = FindQueuedWorksheet(wb, job)

    If ws Is Nothing Then
        gColorQueue.Remove 1
        GoTo CleanExit
    End If

    Set target = ws.Range(job.TargetAddress)

    startIndex = job.NextCellIndex
    endIndex = startIndex + AUTO_COLOR_QUEUE_BATCH_SIZE - 1
    If endIndex > job.TotalCells Then endIndex = job.TotalCells

    oldEvents = Application.EnableEvents
    oldScreenUpdating = Application.ScreenUpdating
    applicationStateCaptured = True

    gProcessing = True
    Application.EnableEvents = False
    Application.ScreenUpdating = False

    AutoColorRangeSlice target, startIndex, endIndex
    job.NextCellIndex = endIndex + 1

    If job.NextCellIndex > job.TotalCells Then
        gColorQueue.Remove 1
    End If

    Application.StatusBar = "AutoColor background queue: " & _
                            Format$(QueuedCellCount(), "#,##0") & " cells remaining"

CleanExit:
    On Error Resume Next

    If applicationStateCaptured Then
        Application.EnableEvents = oldEvents
        Application.ScreenUpdating = oldScreenUpdating
    End If
    gProcessing = False

    If Not gColorQueue Is Nothing Then
        If gColorQueue.Count > 0 Then
            ScheduleQueue
        Else
            Application.StatusBar = "AutoColor background processing finished"
        End If
    End If

    On Error GoTo 0
End Sub

Private Function FindQueuedWorkbook(ByVal job As CColorJob) As Workbook
    Dim wb As Workbook

    For Each wb In Application.Workbooks
        If StrComp(wb.FullName, job.WorkbookFullName, vbTextCompare) = 0 Then
            Set FindQueuedWorkbook = wb
            Exit Function
        End If

        If StrComp(wb.Name, job.WorkbookName, vbTextCompare) = 0 Then
            Set FindQueuedWorkbook = wb
            Exit Function
        End If
    Next wb
End Function

Private Function FindQueuedWorksheet(ByVal wb As Workbook, _
                                     ByVal job As CColorJob) As Worksheet
    On Error Resume Next

    Set FindQueuedWorksheet = wb.Worksheets(job.WorksheetName)

    If FindQueuedWorksheet Is Nothing Then
        If job.WorksheetIndex >= 1 And job.WorksheetIndex <= wb.Worksheets.Count Then
            Set FindQueuedWorksheet = wb.Worksheets(job.WorksheetIndex)
        End If
    End If

    On Error GoTo 0
End Function

Private Function QueuedCellCount() As Double
    Dim job As CColorJob

    If gColorQueue Is Nothing Then Exit Function

    For Each job In gColorQueue
        QueuedCellCount = QueuedCellCount + _
                          (job.TotalCells - job.NextCellIndex + 1)
    Next job
End Function

Private Sub CancelQueuedJobsForWorkbook(ByVal wb As Workbook)
    Dim job As CColorJob
    Dim i As Long

    If wb Is Nothing Then Exit Sub
    If gColorQueue Is Nothing Then Exit Sub

    For i = gColorQueue.Count To 1 Step -1
        Set job = gColorQueue(i)

        If StrComp(job.WorkbookFullName, wb.FullName, vbTextCompare) = 0 Or _
           StrComp(job.WorkbookName, wb.Name, vbTextCompare) = 0 Then
            gColorQueue.Remove i
        End If
    Next i
End Sub

'=====================================================================
' Range processing
'=====================================================================

Private Sub AutoColorRange(ByVal target As Range)
    Dim cell As Range
    Dim oldEvents As Boolean
    Dim oldScreenUpdating As Boolean
    Dim applicationStateCaptured As Boolean

    On Error GoTo CleanExit

    oldEvents = Application.EnableEvents
    oldScreenUpdating = Application.ScreenUpdating
    applicationStateCaptured = True

    gProcessing = True
    Application.EnableEvents = False
    Application.ScreenUpdating = False

    For Each cell In target.Cells
        AutoColorCell cell
    Next cell

CleanExit:
    If applicationStateCaptured Then
        Application.EnableEvents = oldEvents
        Application.ScreenUpdating = oldScreenUpdating
    End If
    gProcessing = False
End Sub

Private Sub AutoColorRangeSlice(ByVal target As Range, _
                                ByVal startIndex As Long, _
                                ByVal endIndex As Long)
    Dim i As Long

    On Error GoTo SafeExit

    For i = startIndex To endIndex
        AutoColorCell target.Cells(i)
    Next i

SafeExit:
End Sub

Private Sub AutoColorCell(ByVal cell As Range)
    Dim value As Variant
    Dim classId As AutoColorClass

    On Error GoTo SafeExit

    If cell.MergeCells Then
        If cell.Address <> cell.MergeArea.Cells(1, 1).Address Then Exit Sub
    End If

    If cell.Hyperlinks.Count > 0 Then
        ApplyClassColor cell, accHyperlink
        Exit Sub
    End If

    If cell.HasFormula Then
        classId = ClassifyFormula(GetFormulaText(cell))
        ApplyClassColor cell, classId
        Exit Sub
    End If

    value = cell.Value2

    If IsEmpty(value) Or IsError(value) Then
        ResetManagedColor cell
        Exit Sub
    End If

    If IsNumeric(value) Then
        ApplyClassColor cell, accInput
        Exit Sub
    End If

    If AUTOCOLOR_TEXT_INPUTS Then
        If VarType(value) = vbString And Len(value) > 0 Then
            ApplyClassColor cell, accInput
            Exit Sub
        End If
    End If

    ResetManagedColor cell

SafeExit:
End Sub

Private Function GetFormulaText(ByVal cell As Range) As String
    On Error Resume Next

    GetFormulaText = CStr(CallByName(cell, "Formula2", VbGet))

    If Err.Number <> 0 Or Len(GetFormulaText) = 0 Then
        Err.Clear
        GetFormulaText = CStr(cell.Formula)
    End If

    On Error GoTo 0
End Function

'=====================================================================
' Formula classification
'=====================================================================

Private Function ClassifyFormula(ByVal formulaText As String) As AutoColorClass
    Dim cacheKey As String
    Dim classId As AutoColorClass

    cacheKey = formulaText

    If Not gFormulaClassCache Is Nothing Then
        If gFormulaClassCache.Exists(cacheKey) Then
            ClassifyFormula = gFormulaClassCache(cacheKey)
            Exit Function
        End If
    End If

    If IsHyperlinkFormula(formulaText) Then
        classId = accHyperlink
    ElseIf IsExternalDataFormula(formulaText) Then
        classId = accExternalData
    ElseIf HasPartialInput(formulaText) Then
        classId = accPartialInput
    ElseIf HasWorkbookLink(formulaText) Then
        classId = accWorkbookLink
    ElseIf HasWorksheetLink(formulaText) Then
        classId = accWorksheetLink
    Else
        classId = accFormula
    End If

    If Not gFormulaClassCache Is Nothing Then
        If gFormulaClassCache.Count > 50000 Then gFormulaClassCache.RemoveAll
        gFormulaClassCache(cacheKey) = CLng(classId)
    End If

    ClassifyFormula = classId
End Function

Private Function IsHyperlinkFormula(ByVal formulaText As String) As Boolean
    Static re As Object
    Dim s As String

    If re Is Nothing Then
        Set re = CreateObject("VBScript.RegExp")

        With re
            .Global = False
            .IgnoreCase = True
            .Pattern = "(^|[^A-Z0-9_.])(_XLFN\.)?HYPERLINK\s*\("
        End With
    End If

    s = RemoveQuotedStrings(formulaText)
    IsHyperlinkFormula = re.Test(s)
End Function

Private Function IsExternalDataFormula(ByVal formulaText As String) As Boolean
    Static re As Object
    Dim s As String

    If re Is Nothing Then
        Set re = CreateObject("VBScript.RegExp")

        With re
            .Global = False
            .IgnoreCase = True
            .Pattern = "(^|[^A-Z0-9_.])(_XLFN\.)?" & _
                       "(BDP|BDH|BDS|BQL|CIQ|CIQRANGE|FDS|FDSC|FDSR|" & _
                       "RDP\.DATA|RDP\.HISTORICALPRICING|TR)\s*\("
        End With
    End If

    s = RemoveQuotedStrings(formulaText)
    IsExternalDataFormula = re.Test(s)
End Function

Private Function HasPartialInput(ByVal formulaText As String) As Boolean
    Dim s As String
    Dim matches As Object
    Dim match As Object
    Dim numberText As String
    Dim numberValue As Double

    Static reQuotedSheet As Object
    Static reBracket As Object
    Static reSheet As Object
    Static reRowRange As Object
    Static reCell As Object
    Static reNumber As Object

    If reQuotedSheet Is Nothing Then
        Set reQuotedSheet = CreateRegex("'([^']|'')+'!", True)
        Set reBracket = CreateRegex("\[[^\]]*\]", True)
        Set reSheet = CreateRegex("([A-Z_][A-Z0-9_.]*)!", True)
        Set reRowRange = CreateRegex("(^|[^A-Z0-9_])\$?[0-9]+:\$?[0-9]+", True)
        Set reCell = CreateRegex("(^|[^A-Z0-9_])\$?[A-Z]{1,3}\$?[0-9]+", True)
        Set reNumber = CreateRegex( _
            "(^|[^A-Z0-9_])([0-9]+(\.[0-9]+)?([E][+-]?[0-9]+)?|\.[0-9]+)", _
            True)
    End If

    s = UCase$(formulaText)
    s = RemoveQuotedStrings(s)
    s = reQuotedSheet.Replace(s, "!")
    s = reBracket.Replace(s, "")
    s = reSheet.Replace(s, "!")
    s = reRowRange.Replace(s, "$1")
    s = reCell.Replace(s, "$1")

    Set matches = reNumber.Execute(s)

    For Each match In matches
        numberText = CStr(match.SubMatches(1))
        numberValue = Val(numberText)

        If Not IsIgnoredPartialInputNumber(numberValue) Then
            HasPartialInput = True
            Exit Function
        End If
    Next match
End Function

Private Function CreateRegex(ByVal patternText As String, _
                             ByVal isGlobal As Boolean) As Object
    Dim re As Object

    Set re = CreateObject("VBScript.RegExp")
    re.Global = isGlobal
    re.IgnoreCase = True
    re.Pattern = patternText

    Set CreateRegex = re
End Function

Private Function IsIgnoredPartialInputNumber(ByVal numberValue As Double) As Boolean
    Select Case numberValue
        Case 0, 1, 100, 1000, 1000000
            IsIgnoredPartialInputNumber = True
    End Select
End Function

Private Function HasWorkbookLink(ByVal formulaText As String) As Boolean
    Static re As Object
    Dim s As String

    If re Is Nothing Then
        Set re = CreateRegex("\[[^\]]+\][^!]*!", False)
    End If

    s = RemoveQuotedStrings(formulaText)
    HasWorkbookLink = re.Test(s)
End Function

Private Function HasWorksheetLink(ByVal formulaText As String) As Boolean
    Dim s As String

    s = RemoveQuotedStrings(formulaText)

    If Not HasWorkbookLink(s) Then
        HasWorksheetLink = (InStr(1, s, "!", vbTextCompare) > 0)
    End If
End Function

Private Function RemoveQuotedStrings(ByVal sourceText As String) As String
    Dim resultText As String
    Dim i As Long
    Dim character As String
    Dim insideQuote As Boolean

    i = 1

    Do While i <= Len(sourceText)
        character = Mid$(sourceText, i, 1)

        If character = """" Then
            If insideQuote And i < Len(sourceText) And _
               Mid$(sourceText, i + 1, 1) = """" Then
                i = i + 2
            Else
                insideQuote = Not insideQuote
                i = i + 1
            End If
        Else
            If Not insideQuote Then resultText = resultText & character
            i = i + 1
        End If
    Loop

    RemoveQuotedStrings = resultText
End Function

'=====================================================================
' Managed colors and stale-color cleanup
'=====================================================================

Private Sub ApplyClassColor(ByVal cell As Range, ByVal classId As AutoColorClass)
    Dim desiredColor As Long

    desiredColor = ColorForClass(classId)

    If cell.Font.Color <> desiredColor Then
        cell.Font.Color = desiredColor
    End If
End Sub

Private Function ColorForClass(ByVal classId As AutoColorClass) As Long
    Select Case classId
        Case accInput
            ColorForClass = RGB(0, 0, 255)
        Case accPartialInput
            ColorForClass = RGB(255, 0, 255)
        Case accFormula
            ColorForClass = RGB(0, 0, 0)
        Case accWorksheetLink
            ColorForClass = RGB(0, 128, 0)
        Case accWorkbookLink
            ColorForClass = RGB(112, 48, 160)
        Case accHyperlink
            ColorForClass = RGB(255, 165, 0)
        Case accExternalData
            ColorForClass = RGB(0, 176, 240)
        Case Else
            ColorForClass = RGB(0, 0, 0)
    End Select
End Function

Private Sub ResetManagedColor(ByVal cell As Range)
    Dim currentColor As Long

    On Error GoTo SafeExit

    currentColor = cell.Font.Color

    If IsManagedColor(currentColor) Then
        cell.Font.ColorIndex = xlColorIndexAutomatic
    End If

SafeExit:
End Sub

Private Function IsManagedColor(ByVal colorValue As Long) As Boolean
    ' Keep the previous purple in the cleanup palette for existing models.
    IsManagedColor = _
        colorValue = RGB(0, 0, 255) Or _
        colorValue = RGB(255, 0, 255) Or _
        colorValue = RGB(0, 0, 0) Or _
        colorValue = RGB(0, 128, 0) Or _
        colorValue = RGB(112, 48, 160) Or _
        colorValue = RGB(128, 0, 128) Or _
        colorValue = RGB(255, 165, 0) Or _
        colorValue = RGB(0, 176, 240)
End Function
