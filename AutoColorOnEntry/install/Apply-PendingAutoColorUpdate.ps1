param(
    [Parameter(Mandatory = $true)]
    [string]$PendingPath,

    [string]$DestinationPath = (Join-Path $env:APPDATA 'Microsoft\AddIns\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'

$resolvedPending = [System.IO.Path]::GetFullPath($PendingPath)
$resolvedDestination = [System.IO.Path]::GetFullPath($DestinationPath)
$addinsRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $env:APPDATA 'Microsoft\AddIns')
) + [System.IO.Path]::DirectorySeparatorChar
$logDirectory = Join-Path $env:LOCALAPPDATA 'AutoColorOnEntry'
$logPath = Join-Path $logDirectory 'pending-update.log'

if (-not $resolvedDestination.StartsWith(
    $addinsRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw 'The update destination must be inside the current user Excel AddIns directory.'
}

if (-not (Test-Path -LiteralPath $logDirectory)) {
    $null = New-Item -ItemType Directory -Path $logDirectory
}

function Write-UpdateLog {
    param([string]$Message)

    Add-Content -LiteralPath $logPath -Value (
        '{0:u} {1}' -f (Get-Date), $Message
    )
}

Write-UpdateLog 'Waiting for Excel to exit before applying the pending English update.'

while (@(Get-Process -Name EXCEL -ErrorAction SilentlyContinue).Count -gt 0) {
    Start-Sleep -Seconds 2
}

try {
    if (-not (Test-Path -LiteralPath $resolvedPending)) {
        Write-UpdateLog 'The pending file no longer exists; no update was applied.'
        exit 0
    }

    if (Test-Path -LiteralPath $resolvedDestination) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        Copy-Item -LiteralPath $resolvedDestination `
            -Destination "$resolvedDestination.$timestamp.bak"
    }

    Copy-Item -LiteralPath $resolvedPending `
        -Destination $resolvedDestination `
        -Force
    Remove-Item -LiteralPath $resolvedPending

    Write-UpdateLog 'The English AutoColorOnEntry add-in was installed successfully.'
}
catch {
    Write-UpdateLog ('Update failed: ' + $_.Exception.Message)
    throw
}
