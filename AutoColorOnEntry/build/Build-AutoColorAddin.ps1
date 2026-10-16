param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\AutoColorOnEntry.xlam')
)

$ErrorActionPreference = 'Stop'

$sourceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\src'))
$ribbonRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\ribbon'))
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$importRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '.import'))
$excel = $null
$workbook = $null

try {
    if (-not (Test-Path -LiteralPath $importRoot)) {
        $null = New-Item -ItemType Directory -Path $importRoot
    }

    # The VBE importer expects exported class files to use Windows CRLF line
    # endings and an ANSI-compatible encoding. Source control keeps the files
    # as normal text; the normalized copies are build artifacts only.
    $windowsEncoding = [System.Text.Encoding]::GetEncoding(1252)

    foreach ($sourceName in @('CAppEvents.cls', 'CColorJob.cls', 'modAutoColor.bas')) {
        $sourcePath = Join-Path $sourceRoot $sourceName
        $importPath = Join-Path $importRoot $sourceName
        $sourceText = [System.IO.File]::ReadAllText($sourcePath)
        $sourceText = [System.Text.RegularExpressions.Regex]::Replace($sourceText, "\r?\n", "`r`n")
        [System.IO.File]::WriteAllText($importPath, $sourceText, $windowsEncoding)
    }

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $workbook = $excel.Workbooks.Add()

    try {
        $vbProject = $workbook.VBProject

        if ($null -eq $vbProject) {
            throw 'VBProject was not exposed by Excel.'
        }

        $null = $vbProject.VBComponents.Count
    }
    catch {
        throw @'
Excel blocked programmatic access to the VBA project.

Do not weaken Trust Center settings just to build this add-in. Import the three
files in src\ through the Visual Basic Editor instead, then save as an Excel
Add-In (*.xlam).
'@
    }

    $null = $vbProject.VBComponents.Import((Join-Path $importRoot 'CAppEvents.cls'))
    $null = $vbProject.VBComponents.Import((Join-Path $importRoot 'CColorJob.cls'))
    $null = $vbProject.VBComponents.Import((Join-Path $importRoot 'modAutoColor.bas'))

    $thisWorkbookSource = [System.IO.File]::ReadAllText((Join-Path $sourceRoot 'ThisWorkbook.txt'))
    $vbProject.VBComponents.Item('ThisWorkbook').CodeModule.AddFromString($thisWorkbookSource)

    if (Test-Path -LiteralPath $resolvedOutput) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = "$resolvedOutput.$timestamp.bak"
        Move-Item -LiteralPath $resolvedOutput -Destination $backupPath
    }

    # 55 = xlOpenXMLAddIn
    $workbook.SaveAs($resolvedOutput, 55)
    $workbook.Close($false)
    $workbook = $null

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::Open(
        $resolvedOutput,
        [System.IO.Compression.ZipArchiveMode]::Update
    )

    try {
        function Get-ZipEntryText {
            param(
                [System.IO.Compression.ZipArchive]$Archive,
                [string]$EntryName
            )

            $entry = $Archive.GetEntry($EntryName)
            if ($null -eq $entry) {
                throw "Required package entry was not found: $EntryName"
            }

            $reader = [System.IO.StreamReader]::new($entry.Open())
            try { return $reader.ReadToEnd() }
            finally { $reader.Dispose() }
        }

        function Set-ZipEntryText {
            param(
                [System.IO.Compression.ZipArchive]$Archive,
                [string]$EntryName,
                [string]$Text
            )

            $existing = $Archive.GetEntry($EntryName)
            if ($null -ne $existing) { $existing.Delete() }

            $entry = $Archive.CreateEntry(
                $EntryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
            $writer = [System.IO.StreamWriter]::new($entry.Open(), $utf8WithoutBom)

            try { $writer.Write($Text) }
            finally { $writer.Dispose() }
        }

        $relationships = Get-ZipEntryText $zip '_rels/.rels'

        if ($relationships -notmatch 'relationships/ui/extensibility') {
            $relationshipMarkup = '<Relationship Id="rIdAutoColorRibbon" ' +
                'Type="http://schemas.microsoft.com/office/2006/relationships/ui/extensibility" ' +
                'Target="/customUI/customUI.xml"/>'
            $relationships = $relationships.Replace(
                '</Relationships>',
                $relationshipMarkup + '</Relationships>'
            )
            Set-ZipEntryText $zip '_rels/.rels' $relationships
        }

        $ribbonXml = [System.IO.File]::ReadAllText(
            (Join-Path $ribbonRoot 'customUI.xml')
        )
        # RibbonX XML uses the package's existing application/xml default.
        Set-ZipEntryText $zip 'customUI/customUI.xml' $ribbonXml
    }
    finally {
        $zip.Dispose()
    }

    Write-Output $resolvedOutput
}
finally {
    if ($workbook -ne $null) {
        try { $workbook.Close($false) } catch { }
    }

    if ($excel -ne $null) {
        try { $excel.Quit() } catch { }
    }

    if ($workbook -ne $null) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($workbook)
    }

    if ($excel -ne $null) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel)
    }

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
