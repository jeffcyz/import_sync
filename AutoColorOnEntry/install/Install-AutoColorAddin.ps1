param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '..\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'

$resolvedSource = [System.IO.Path]::GetFullPath($SourcePath)
$addinsDirectory = Join-Path $env:APPDATA 'Microsoft\AddIns'
$destination = Join-Path $addinsDirectory 'AutoColorOnEntry.xlam'
$excel = $null
$addin = $null

if (-not (Test-Path -LiteralPath $resolvedSource)) {
    throw "The built add-in was not found: $resolvedSource"
}

if (-not (Test-Path -LiteralPath $addinsDirectory)) {
    $null = New-Item -ItemType Directory -Path $addinsDirectory
}

if (Test-Path -LiteralPath $destination) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item -LiteralPath $destination -Destination "$destination.$timestamp.bak"
}

Copy-Item -LiteralPath $resolvedSource -Destination $destination -Force

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.AutomationSecurity = 1

    foreach ($candidate in $excel.AddIns) {
        if ([string]::Equals($candidate.FullName, $destination, [System.StringComparison]::OrdinalIgnoreCase)) {
            $addin = $candidate
            break
        }
    }

    if ($null -eq $addin) {
        $addin = $excel.AddIns.Add($destination, $false)
    }

    $addin.Installed = $true

    if (-not $addin.Installed) {
        throw 'Excel did not retain the add-in as installed.'
    }

    # Excel sometimes stores only the file name in OPEN/OPEN1. On this machine
    # that made Excel search the Documents folder even though Add-in Manager
    # displayed the correct checked item. Pin every matching entry to the full
    # installed path.
    $excelOptionsPath = 'HKCU:\Software\Microsoft\Office\16.0\Excel\Options'
    $excelOptions = Get-ItemProperty -Path $excelOptionsPath
    $matchingOpenValues = @(
        $excelOptions.PSObject.Properties |
            Where-Object {
                $_.Name -match '^OPEN\d*$' -and
                [string]$_.Value -match '(?i)AutoColorOnEntry\.xlam'
            }
    )

    if ($matchingOpenValues.Count -eq 0) {
        throw 'Excel did not create an OPEN registry entry for the add-in.'
    }

    foreach ($openValue in $matchingOpenValues) {
        Set-ItemProperty -Path $excelOptionsPath `
            -Name $openValue.Name `
            -Value ('"' + $destination + '"')
    }

    [pscustomobject]@{
        Name = $addin.Name
        FullName = $addin.FullName
        Installed = $addin.Installed
        StartupRegistration = $matchingOpenValues.Name -join ', '
    }
}
finally {
    if ($excel -ne $null) {
        try { $excel.Quit() } catch { }
    }

    if ($addin -ne $null) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($addin)
    }

    if ($excel -ne $null) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
    }

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
