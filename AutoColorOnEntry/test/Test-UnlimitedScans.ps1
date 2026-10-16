param(
    [string]$AddinPath = (Join-Path $PSScriptRoot '..\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'
$testPath = Join-Path ([IO.Path]::GetTempPath()) (
    'AutoColorUnlimitedTest-{0}.xlam' -f [guid]::NewGuid().ToString('N')
)
$excel = $null
$addin = $null
$workbook = $null
$first = $null
$second = $null
$module = $null

# These helpers exist only in the disposable test copy. All admission paths use
# the production macros, with real populated ranges rather than inflated counters.
$testCode = @'
Private Sub TestClearPendingQueue()
    If gQueueScheduled Then
        Application.OnTime EarliestTime:=gQueueRunAt, Procedure:=QualifiedMacroName("ProcessAutoColorQueue"), Schedule:=False
    End If
    gQueueScheduled = False
    Set gColorQueue = New Collection
End Sub

Public Function TestUnlimitedAdmission() As String
    Dim wb As Workbook
    Dim first As Worksheet
    Dim second As Worksheet
    Dim job As CColorJob
    Dim jobRange As Range
    Dim firstTailIncluded As Boolean
    Dim secondTailIncluded As Boolean
    Dim boundedJobs As Boolean
    Dim report As String

    On Error GoTo Failed
    InitializeAutoColorAddin
    Set wb = ActiveWorkbook
    Set first = wb.Worksheets("FirstLargeSheet")
    Set second = wb.Worksheets("SecondLargeSheet")
    TestClearPendingQueue

    first.Activate
    ScanCurrentSheet
    report = "Worksheet=" & CStr(QueuedCellCount()) & vbCrLf
    TestClearPendingQueue

    first.Range("A1:C700000").Select
    ScanCurrentSelection
    report = report & "Selection=" & CStr(QueuedCellCount()) & vbCrLf
    TestClearPendingQueue

    EnableAutoColorForCurrentWorkbook
    HandleApplicationSheetChange first, first.Range("A1:C700000")
    report = report & "AutomaticChange=" & CStr(QueuedCellCount()) & vbCrLf
    DisableAutoColorForCurrentWorkbook
    TestClearPendingQueue

    first.Range("A1:B600001").Select
    ScanCurrentSelection
    second.Activate
    second.Range("A1:B600001").Select
    ScanCurrentSelection
    report = report & "Cumulative=" & CStr(QueuedCellCount()) & vbCrLf
    TestClearPendingQueue

    ScanCurrentWorkbook
    report = report & "Workbook=" & CStr(QueuedCellCount()) & vbCrLf
    report = report & "WorkbookQueued=" & CStr(InStr(1, CStr(Application.StatusBar), "scan queued", vbTextCompare) > 0) & vbCrLf
    boundedJobs = True
    For Each job In gColorQueue
        If job.TotalCells > AUTO_COLOR_JOB_MAX_CELLS Then boundedJobs = False
        Set jobRange = wb.Worksheets(job.WorksheetName).Range(job.TargetAddress)
        If job.WorksheetName = first.Name Then
            If Not Application.Intersect(jobRange, first.Range("C700000")) Is Nothing Then firstTailIncluded = True
        ElseIf job.WorksheetName = second.Name Then
            If Not Application.Intersect(jobRange, second.Range("B600001")) Is Nothing Then secondTailIncluded = True
        End If
    Next job
    report = report & "BothTailsIncluded=" & CStr(firstTailIncluded And secondTailIncluded) & vbCrLf
    report = report & "BoundedJobs=" & CStr(boundedJobs)
    TestClearPendingQueue
    TestUnlimitedAdmission = report
    Exit Function

Failed:
    report = "ERROR: " & Err.Description
    On Error Resume Next
    TestClearPendingQueue
    TestUnlimitedAdmission = report
End Function
'@

try {
    Copy-Item -LiteralPath ([IO.Path]::GetFullPath($AddinPath)) -Destination $testPath
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $true
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $false
    $excel.AutomationSecurity = 1
    $addin = $excel.Workbooks.Open($testPath)
    $module = $addin.VBProject.VBComponents.Item('modAutoColor').CodeModule
    $module.AddFromString($testCode)
    $prefix = "'$($addin.Name)'!"
    $excel.Run($prefix + 'Auto_Open')

    $workbook = $excel.Workbooks.Add(-4167)
    $first = $workbook.Worksheets.Item(1)
    $first.Name = 'FirstLargeSheet'
    $second = $workbook.Worksheets.Add()
    $second.Name = 'SecondLargeSheet'
    $first.Range('A1:C700000').Value2 = 5
    $second.Range('A1:B600001').Value2 = 6
    $null = $workbook.Windows.Item(1).Activate()
    $excel.EnableEvents = $true

    # One macro captures all queue snapshots before Excel can run OnTime jobs.
    $report = [string]$excel.Run($prefix + 'TestUnlimitedAdmission')
    if ($report.StartsWith('ERROR:')) { throw $report }
    $actual = @{}
    foreach ($line in ($report -split '\r?\n')) {
        $pair = $line -split '=', 2
        if ($pair.Count -eq 2) { $actual[$pair[0]] = $pair[1] }
    }
    $checks = @(
        @{ Name = 'Worksheet scan accepts 2.1 million populated cells'; Key = 'Worksheet'; Expected = '2100000' }
        @{ Name = 'Selection scan accepts 2.1 million populated cells'; Key = 'Selection'; Expected = '2100000' }
        @{ Name = 'Automatic changes accept 2.1 million cells'; Key = 'AutomaticChange'; Expected = '2100000' }
        @{ Name = 'Separate requests can accumulate above two million'; Key = 'Cumulative'; Expected = '2400004' }
        @{ Name = 'Entire workbook queues all 3.3 million populated cells'; Key = 'Workbook'; Expected = '3300002' }
        @{ Name = 'Both worksheet tails remain in the queue'; Key = 'BothTailsIncluded'; Expected = 'True' }
        @{ Name = 'Individual jobs remain bounded for responsiveness'; Key = 'BoundedJobs'; Expected = 'True' }
        @{ Name = 'Workbook status reports the complete scan was queued'; Key = 'WorkbookQueued'; Expected = 'True' }
    )
    $results = @(foreach ($check in $checks) {
        [pscustomobject]@{
            Test = $check.Name
            Passed = ($actual[$check.Key] -eq $check.Expected)
            Actual = $actual[$check.Key]
            Expected = $check.Expected
        }
    })
    $results | Format-Table -AutoSize | Out-String | Write-Output
    if (@($results | Where-Object { -not $_.Passed }).Count -gt 0) {
        throw 'Unlimited scan admission tests failed.'
    }
}
finally {
    if ($excel -and $addin) { try { $excel.Run($prefix + 'Auto_Close') } catch {} }
    if ($workbook) { try { $workbook.Close($false) } catch {} }
    if ($addin) { try { $addin.Close($false) } catch {} }
    if ($excel) { try { $excel.Quit() } catch {} }
    foreach ($item in @($module, $second, $first, $workbook, $addin, $excel)) {
        if ($item -and [Runtime.InteropServices.Marshal]::IsComObject($item)) {
            try { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($item) } catch {}
        }
    }
    $item = $null
    $module = $null
    $second = $null
    $first = $null
    $workbook = $null
    $addin = $null
    $excel = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($testPath.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $testPath -ErrorAction SilentlyContinue
    }
}
