# AutoColor on Entry

This Excel add-in applies finance-modeling font colors when cell contents are entered or changed.

## Install on a new computer

Requires desktop Excel on Windows. The compiled add-in is ready to use; no source build is required.

1. Download [AutoColorOnEntry.xlam](https://github.com/jeffcyz/import_sync/raw/refs/heads/main/AutoColorOnEntry.xlam) and save it locally.
2. Close all Excel windows.
3. If Windows marks the downloaded file as blocked, right-click the trusted `.xlam` file, open **Properties**, select **Unblock**, and choose **Apply**. For a ZIP download, unblock the ZIP before extracting it.
4. Copy `AutoColorOnEntry.xlam` to `%APPDATA%\Microsoft\AddIns`.
5. In Excel, open **File > Options > Add-ins**, choose **Excel Add-ins** under **Manage**, and select **Go**.
6. Choose **Browse**, select the `.xlam` file, and check **AutoColorOnEntry**.
7. Enable **Developer** under **File > Options > Customize Ribbon**.
8. Exit Excel completely and reopen it. The controls appear under **Developer > AutoColor**.

Use Excel's Add-ins dialog to load the file. A downloaded `.xlam` cannot be opened in Protected View. Running this add-in does not require **Trust access to the VBA project object model**; only rebuilding and instrumented source tests require that setting. Organization macro policies may require deployment by IT.

For an existing model, choose **Enable and Scan** to turn AutoColor on for that workbook and recolor its existing content. To update an installed copy, close Excel and replace its `.xlam` file with the latest download.

## Default and scope

- AutoColor is **OFF** for every workbook whenever Excel starts.
- `Ctrl+Shift+A` toggles AutoColor only for the active workbook.
- Enabling one workbook does not enable any other open workbook.
- The setting is intentionally session-only. Reopening Excel returns every workbook to OFF.
- Disabling AutoColor stops future recoloring; it does not undo colors already applied.

## Public macros

| Macro | Purpose |
|---|---|
| `ToggleAutoColorForCurrentWorkbook` | Toggle the active workbook ON/OFF |
| `EnableAutoColorForCurrentWorkbook` | Enable the active workbook |
| `DisableAutoColorForCurrentWorkbook` | Disable the active workbook |
| `ShowAutoColorStatus` | Show the active workbook's state |
| `AutoColorIsEnabledForCurrentWorkbook` | Read-only state query for automation/testing |
| `AutoColorCurrentWorkbookName` | Read-only active-workbook query for automation/testing |
| `EnableAndScanCurrentWorkbook` | Enable and recolor cells containing values or formulas |
| `ScanCurrentSelection` | Recolor non-empty selected cells without changing ON/OFF state |
| `ScanCurrentSheet` | Recolor cells containing values or formulas on the active sheet |
| `ScanCurrentWorkbook` | Recolor cells containing values or formulas across the active workbook |

## Developer tab

The add-in adds an `AutoColor` group to Excel's built-in Developer tab:

| Control | Action |
|---|---|
| **Current Workbook** | Turn automatic coloring on or off for the active workbook only. |
| **Enable and Scan** | Enable the active workbook and recolor its existing content. |
| **Scan Existing Content > Entire Workbook** | Recolor cells containing values or formulas on every worksheet. |
| **Scan Existing Content > Current Worksheet** | Recolor cells containing values or formulas on the active worksheet. |
| **Scan Existing Content > Selected Range** | Recolor cells containing values or formulas within the selection. |
| **Status** | Show whether AutoColor is on or off for the active workbook. |

The three **Scan Existing Content** commands do not change the workbook's ON/OFF state. Blank cells and cells containing only leftover formatting are excluded from manual scans.

## Classification colors

| Cell/formula type | Color |
|---|---|
| Numeric hardcode | Blue |
| Normal formula | Black |
| Cross-sheet link | Green |
| External-workbook link | Purple - RGB(112, 48, 160), #7030A0 |
| Formula with embedded hardcode | Magenta |
| Hyperlink | Orange |
| External-data formula | Cyan |

The classifier evaluates formulas in this order: hyperlink, external data, partial input, external workbook, worksheet link, normal formula.

## Safety and behavior

- Add-ins, `PERSONAL.XLSB`, read-only files, CSV, and text files are excluded.
- Changes of up to 10,000 cells are processed immediately.
- Larger changes are split into background batches instead of being silently skipped.
- Manual scans count and process only cells containing constants or formulas. Blank cells and cells containing only leftover formatting are excluded, including gaps between populated cells. Formulas that return an empty string still count as formulas.
- There is no application-imposed limit on the total number of scanned or queued cells. Requests continue in background batches until the queue is empty. The 10,000-cell immediate threshold, 250,000-cell job size, and 2,500-cell processing batches control responsiveness, not how many cells can be scanned. Manual scans still exclude blank and formatting-only cells.
- Automatic change events still process cleared cells so deleting a number or formula can remove its managed font color.
- When a colored number or formula is replaced by blank/text, managed palette colors are reset to Automatic to avoid stale blue/green/purple formatting.
- Conditional formatting can visually override direct font colors.
- VBA formatting changes can clear Excel's native Undo history; this is an Excel/VBA limitation.
- The add-in uses Windows `VBScript.RegExp` and is intended for desktop Excel on Windows.

## Source files

- `src/CAppEvents.cls`: Excel application event sink.
- `src/CColorJob.cls`: background queue item.
- `src/modAutoColor.bas`: lifecycle, per-workbook state, scanner, queue, classifier, and colors.
- `src/ThisWorkbook.txt`: reliable workbook-open and add-in-install startup events injected during the build.
- `ribbon/customUI.xml`: custom `AutoColor` group added to Excel's built-in Developer tab.
- `build/Build-AutoColorAddin.ps1`: optional local builder when Excel permits programmatic VBA-project access.
- `install/Install-AutoColorAddin.ps1`: copies the verified build to the current user's Excel AddIns folder and registers it for startup.
- `test/Test-AutoColorAddin.ps1`: disposable two-workbook integration test for scope, colors, stale-color cleanup, and queued edits.
- `test/Test-ContentOnlyScans.ps1`: sparse-sheet and selection regression tests for content-only counts, formatting-only blanks, multi-area queues, and deletion cleanup.
- `test/Test-UnlimitedScans.ps1`: verifies admission of more than 2,000,000 populated cells through sheet, selection, workbook, automatic-change, and cumulative queue paths, while retaining bounded jobs.

## Validation

The current compiled build passed 46 Windows Excel integration and regression checks: 14 core checks, 24 content-only and batch-completion checks, and 8 unlimited-queue checks. Coverage includes per-workbook OFF/ON state, the updated purple, sparse sheets, noncontiguous selections, empty-result formulas, completion through the last column of multi-column batches, cleanup after deletion, and queueing more than 2,000,000 genuinely populated cells. Large admission tests inspect queue coverage and cancel their test queues without waiting for millions of cells to be recolored.
