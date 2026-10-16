param(
    [string]$AddinPath = (Join-Path $PSScriptRoot '..\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'
$testPath = Join-Path ([IO.Path]::GetTempPath()) (
    'AutoColorContentTest-{0}.xlam' -f [guid]::NewGuid().ToString('N')
)
$excel = $null
$addin = $null
$workbook = $null
$first = $null
$second = $null
$blank = $null
$module = $null
$results = [Collections.Generic.List[object]]::new()

function Assert-Result {
    param([string]$Name, $Actual, $Expected)
    $results.Add([pscustomobject]@{
        Test = $Name
        Passed = ($Actual -eq $Expected)
        Actual = $Actual
        Expected = $Expected
    })
}

# Instrument only a disposable copy. The shipped add-in exposes no test callbacks.
$testCode = @'
Public Function TestContentCount(ByVal sheetName As String, ByVal addressText As String) As Double
    Dim cells As Range
    Set cells = NonEmptyCellsForScan(ActiveWorkbook.Worksheets(sheetName).Range(addressText))
    If Not cells Is Nothing Then TestContentCount = cells.CountLarge
End Function

Public Function TestPendingCount() As Double
    TestPendingCount = QueuedCellCount()
End Function
'@

try {
    Copy-Item -LiteralPath ([IO.Path]::GetFullPath($AddinPath)) -Destination $testPath
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $true
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $true
    $excel.AutomationSecurity = 1
    $addin = $excel.Workbooks.Open($testPath)
    $module = $addin.VBProject.VBComponents.Item('modAutoColor').CodeModule
    $module.AddFromString($testCode)
    $prefix = "'$($addin.Name)'!"
    $excel.Run($prefix + 'Auto_Open')

    # xlWBATWorksheet ensures the workbook starts with exactly one worksheet.
    $workbook = $excel.Workbooks.Add(-4167)
    $first = $workbook.Worksheets.Item(1)
    $first.Name = 'SparseOne'
    $second = $workbook.Worksheets.Add()
    $second.Name = 'SparseTwo'
    $blank = $workbook.Worksheets.Add()
    $blank.Name = 'FormattingOnly'

    $purple = 112 + 48 * 256 + 160 * 65536
    $first.Range('A1').Value2 = 123
    $first.Range('A2').Value2 = 0
    $first.Range('A3').Value2 = 'text'
    $first.Range('A4').Value2 = $true
    $first.Range('A5').Formula = '=NA()'
    $first.Range('A6').Formula = '=""'
    $first.Range('C900000').Font.Color = $purple
    $second.Range('A1').Value2 = 456
    $second.Range('C900000').Font.Color = $purple
    $blank.Range('C900000').Font.Color = $purple
    $null = $workbook.Windows.Item(1).Activate()
    $null = $first.Activate()

    Assert-Result 'Regression fixture exceeds the old raw-cell limit' `
        ($first.UsedRange.CountLarge -gt 2000000) $true
    Assert-Result 'Sparse sheet counts only constants and formulas' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A1:C900000') 6
    Assert-Result 'Zero is included as content' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A2') 1
    Assert-Result 'Empty-result formula is included as content' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A6') 1
    Assert-Result 'Formatting-only sheet counts no cells' `
        $excel.Run($prefix + 'TestContentCount', 'FormattingOnly', 'A1:C900000') 0
    Assert-Result 'Single-cell selection cannot expand to other content' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A1') 1
    Assert-Result 'Single blank cell cannot expand to other content' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A20') 0
    Assert-Result 'Discontiguous selection excludes formatted blanks' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'A1,A6,C900000') 2

    $excel.Run($prefix + 'ScanCurrentWorkbook')
    Assert-Result 'Workbook scan processes the first sparse sheet' `
        $first.Range('A1').Font.Color 16711680
    Assert-Result 'Workbook scan also processes the later sparse sheet' `
        $second.Range('A1').Font.Color 16711680
    Assert-Result 'Workbook scan leaves blank residual formatting alone' `
        $first.Range('C900000').Font.Color $purple
    Assert-Result 'Sparse workbook finishes without a large background queue' `
        $excel.Run($prefix + 'TestPendingCount') 0
    Assert-Result 'Manual scan does not enable automatic coloring' `
        ([bool]$excel.Run($prefix + 'AutoColorIsEnabledForCurrentWorkbook')) $false

    $first.Range('A1').Font.Color = $purple
    $null = $first.Range('A20').Select()
    $excel.Run($prefix + 'ScanCurrentSelection')
    Assert-Result 'Scanning a blank selection cannot recolor outside it' `
        $first.Range('A1').Font.Color $purple
    $excel.Run($prefix + 'ScanCurrentSheet')
    Assert-Result 'Worksheet scan processes only its populated cells' `
        $first.Range('A1').Font.Color 16711680

    $null = $blank.Activate()
    $excel.Run($prefix + 'ScanCurrentSheet')
    Assert-Result 'Formatting-only worksheet reports nothing to scan' `
        ([string]$excel.StatusBar -like '*no non-empty cells*') $true

    $null = $first.Activate()
    $first.Range('D1:D5001').Value2 = 5
    $first.Range('F1:F5001').Value2 = 6
    $first.Range('E1:E5001').Font.Color = $purple
    Assert-Result 'Sparse queued scan counts both populated areas without the gap' `
        $excel.Run($prefix + 'TestContentCount', 'SparseOne', 'D1:F5001') 10002
    $null = $first.Range('D1:F5001').Select()
    $excel.Run($prefix + 'ScanCurrentSelection')
    $deadline = (Get-Date).AddSeconds(25)
    do {
        Start-Sleep -Seconds 1
        $remaining = [double]$excel.Run($prefix + 'TestPendingCount')
    } while ($remaining -gt 0 -and (Get-Date) -lt $deadline)
    Assert-Result 'Sparse multi-area queue completes' $remaining 0
    Assert-Result 'First populated area is fully recolored' `
        $first.Range('D1:D5001').Font.Color 16711680
    Assert-Result 'Later populated area is fully recolored' `
        $first.Range('F1:F5001').Font.Color 16711680
    Assert-Result 'Blank gap is excluded from recoloring' `
        $first.Range('E1:E5001').Font.Color $purple

    $first.Range('H1:J4000').Value2 = 7
    $null = $first.Range('H1:J4000').Select()
    $excel.Run($prefix + 'ScanCurrentSelection')
    $deadline = (Get-Date).AddSeconds(25)
    do {
        Start-Sleep -Seconds 1
        $remaining = [double]$excel.Run($prefix + 'TestPendingCount')
    } while ($remaining -gt 0 -and (Get-Date) -lt $deadline)
    Assert-Result 'Multi-column background scan colors its entire rectangle' `
        $first.Range('H1:J4000').Font.Color 16711680
    Assert-Result 'Multi-column background scan reaches the final cell' `
        $first.Range('J4000').Font.Color 16711680

    $excel.Run($prefix + 'EnableAutoColorForCurrentWorkbook')
    $first.Range('D1').ClearContents()
    Assert-Result 'Automatic deletion still clears stale managed colors' `
        $first.Range('D1').Font.ColorIndex -4105

    $results | Format-Table -AutoSize | Out-String | Write-Output
    if (@($results | Where-Object { -not $_.Passed }).Count -gt 0) {
        throw 'Content-only scan regression tests failed.'
    }
}
finally {
    if ($excel -and $addin) { try { $excel.Run($prefix + 'Auto_Close') } catch {} }
    if ($workbook) { try { $workbook.Close($false) } catch {} }
    if ($addin) { try { $addin.Close($false) } catch {} }
    if ($excel) { try { $excel.Quit() } catch {} }
    foreach ($item in @($module, $blank, $second, $first, $workbook, $addin, $excel)) {
        if ($item -and [Runtime.InteropServices.Marshal]::IsComObject($item)) {
            try { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($item) } catch {}
        }
    }
    $item = $null
    $module = $null
    $blank = $null
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
