param(
    [string]$AddinPath = (Join-Path $PSScriptRoot '..\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'

$resolvedAddin = [System.IO.Path]::GetFullPath($AddinPath)
$testAddinPath = Join-Path ([System.IO.Path]::GetTempPath()) `
    ("AutoColorOnEntryTest-{0}.xlam" -f [guid]::NewGuid().ToString('N'))
$excel = $null
$addin = $null
$workbookOne = $null
$workbookTwo = $null

$results = [System.Collections.Generic.List[object]]::new()

function Add-TestResult {
    param(
        [string]$Name,
        [bool]$Passed,
        $Actual,
        $Expected
    )

    $results.Add([pscustomobject]@{
        Test = $Name
        Passed = $Passed
        Actual = $Actual
        Expected = $Expected
    })
}

try {
    Copy-Item -LiteralPath $resolvedAddin -Destination $testAddinPath

    $excel = New-Object -ComObject Excel.Application
    # Workbook activation in an invisible Excel instance is unreliable when an
    # add-in workbook is also open. The real feature is interactive, so test it
    # with a visible disposable Excel instance.
    $excel.Visible = $true
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $true

    # 1 = msoAutomationSecurityLow. The file is built locally from the adjacent
    # reviewed source files and is opened only inside this disposable test instance.
    $excel.AutomationSecurity = 1

    $addin = $excel.Workbooks.Open($testAddinPath)
    $excel.Run("'$($addin.Name)'!Auto_Open")

    $workbookOne = $excel.Workbooks.Add()
    $sheetOne = $workbookOne.Worksheets.Item(1)
    $sheetOne.Name = 'Model'
    $sheetTwo = $workbookOne.Worksheets.Add()
    $sheetTwo.Name = 'Support'

    $workbookTwo = $excel.Workbooks.Add()
    $otherSheet = $workbookTwo.Worksheets.Item(1)

    $null = $workbookOne.Windows.Item(1).Activate()
    $activeName = $excel.Run("'$($addin.Name)'!AutoColorCurrentWorkbookName")
    Add-TestResult 'Test window activation targets workbook one' `
        ($activeName -eq $workbookOne.Name) $activeName $workbookOne.Name

    $defaultColorIndex = $sheetOne.Range('A1').Font.ColorIndex
    $sheetOne.Range('A1').Value2 = 123
    Add-TestResult 'Default state is OFF' `
        ($sheetOne.Range('A1').Font.ColorIndex -eq $defaultColorIndex) `
        $sheetOne.Range('A1').Font.ColorIndex $defaultColorIndex

    $excel.Run("'$($addin.Name)'!EnableAutoColorForCurrentWorkbook")
    $enabledState = $excel.Run("'$($addin.Name)'!AutoColorIsEnabledForCurrentWorkbook")
    Add-TestResult 'The active workbook reports ON after enabling' `
        ([bool]$enabledState) $enabledState $true

    $sheetOne.Range('A2').Value2 = 456
    Add-TestResult 'Numeric hardcode is blue after enabling workbook' `
        ($sheetOne.Range('A2').Font.Color -eq 16711680) `
        $sheetOne.Range('A2').Font.Color 16711680

    $sheetOne.Range('B1').Formula = '=A2*1.05'
    Add-TestResult 'Embedded hardcode formula is magenta' `
        ($sheetOne.Range('B1').Font.Color -eq 16711935) `
        $sheetOne.Range('B1').Font.Color 16711935

    $sheetOne.Range('B2').Formula = '=Support!A1'
    Add-TestResult 'Cross-sheet link is green' `
        ($sheetOne.Range('B2').Font.Color -eq 32768) `
        $sheetOne.Range('B2').Font.Color 32768

    $purple = 112 + 48 * 256 + 160 * 65536
    $sheetOne.Range('B3').Formula = "='[$($workbookTwo.Name)]$($otherSheet.Name)'!A1"
    Add-TestResult 'External-workbook link is RGB(112, 48, 160)' `
        ($sheetOne.Range('B3').Font.Color -eq $purple) `
        $sheetOne.Range('B3').Font.Color $purple

    $legacyPurple = 128 + 128 * 65536
    $sheetOne.Range('B3').Font.Color = $legacyPurple
    $null = $sheetOne.Activate()
    $excel.Run("'$($addin.Name)'!ScanCurrentSheet")
    Add-TestResult 'Scanning updates an existing external link to the new purple' `
        ($sheetOne.Range('B3').Font.Color -eq $purple) `
        $sheetOne.Range('B3').Font.Color $purple

    $sheetOne.Range('B3').Value2 = 'text'
    Add-TestResult 'Replacing a new-purple link with text clears managed color' `
        ($sheetOne.Range('B3').Font.ColorIndex -eq -4105) `
        $sheetOne.Range('B3').Font.ColorIndex -4105

    $sheetOne.Range('B4').Font.Color = $legacyPurple
    $sheetOne.Range('B4').Value2 = 'text'
    Add-TestResult 'Replacing legacy-purple content with text still clears managed color' `
        ($sheetOne.Range('B4').Font.ColorIndex -eq -4105) `
        $sheetOne.Range('B4').Font.ColorIndex -4105

    $sheetOne.Range('A2').Value2 = 'text'
    Add-TestResult 'Replacing a number with text clears managed color' `
        ($sheetOne.Range('A2').Font.ColorIndex -eq -4105) `
        $sheetOne.Range('A2').Font.ColorIndex -4105

    $null = $workbookTwo.Windows.Item(1).Activate()
    $otherState = $excel.Run("'$($addin.Name)'!AutoColorIsEnabledForCurrentWorkbook")
    Add-TestResult 'The second workbook reports OFF' `
        (-not [bool]$otherState) $otherState $false

    $otherDefaultColorIndex = $otherSheet.Range('A1').Font.ColorIndex
    $otherSheet.Range('A1').Value2 = 789
    Add-TestResult 'A different workbook remains OFF' `
        ($otherSheet.Range('A1').Font.ColorIndex -eq $otherDefaultColorIndex) `
        $otherSheet.Range('A1').Font.ColorIndex $otherDefaultColorIndex

    $null = $workbookOne.Windows.Item(1).Activate()
    $sheetOne.Range('C1:C10001').Value2 = 5

    # OnTime processes 2,500 cells per second in the background.
    Start-Sleep -Seconds 7

    Add-TestResult 'Large edits are processed by the background queue' `
        ($sheetOne.Range('C10001').Font.Color -eq 16711680) `
        $sheetOne.Range('C10001').Font.Color 16711680

    $failed = @($results | Where-Object { -not $_.Passed })
    $results | Format-Table -AutoSize | Out-String | Write-Output

    if ($failed.Count -gt 0) {
        throw "$($failed.Count) AutoColor test(s) failed."
    }
}
finally {
    if ($excel -ne $null -and $addin -ne $null) {
        try { $excel.Run("'$($addin.Name)'!Auto_Close") } catch { }
    }

    if ($workbookTwo -ne $null) {
        try { $workbookTwo.Close($false) } catch { }
    }

    if ($workbookOne -ne $null) {
        try { $workbookOne.Close($false) } catch { }
    }

    if ($addin -ne $null) {
        try { $addin.Close($false) } catch { }
    }

    if ($excel -ne $null) {
        try { $excel.Quit() } catch { }
    }

    foreach ($comObject in @($otherSheet, $sheetTwo, $sheetOne, $workbookTwo, $workbookOne, $addin, $excel)) {
        if ($null -ne $comObject) {
            try {
                [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
            }
            catch { }
        }
    }

    $comObject = $null
    $otherSheet = $null
    $sheetTwo = $null
    $sheetOne = $null
    $workbookTwo = $null
    $workbookOne = $null
    $addin = $null
    $excel = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    $resolvedTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $resolvedTestAddin = [System.IO.Path]::GetFullPath($testAddinPath)

    if ($resolvedTestAddin.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedTestAddin -ErrorAction SilentlyContinue
    }
}
