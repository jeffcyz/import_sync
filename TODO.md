
import ctypes
from pathlib import Path
from datetime import datetime

import win32com.client as win32


# ============================================================
# 1. CONFIGURATION
# ============================================================

DOWNLOADS = Path.home() / "Downloads"
DOWNLOADS.mkdir(parents=True, exist_ok=True)

OUTPUT_FILE = DOWNLOADS / (
    f"ASAP_Excel_Format_Test_"
    f"{datetime.now():%Y%m%d_%H%M%S}.xlsb"
)

# Excel Binary Workbook
XL_EXCEL12 = 50


# ============================================================
# 2. WINDOWS LOCAL SHORT DATE FORMAT
# ============================================================

def get_short_date_format():
    """
    Read the Windows regional Short Date pattern.

    Examples:
        M/d/yyyy
        dd/MM/yyyy
        yyyy-MM-dd

    Translate Windows month tokens for Excel NumberFormat.
    """

    LOCALE_USER_DEFAULT = 0x0400
    LOCALE_SSHORTDATE = 0x001F

    buffer = ctypes.create_unicode_buffer(128)

    result = ctypes.windll.kernel32.GetLocaleInfoW(
        LOCALE_USER_DEFAULT,
        LOCALE_SSHORTDATE,
        buffer,
        len(buffer),
    )

    if result == 0:
        raise ctypes.WinError()

    # Windows uses M for month; Excel uses m.
    return buffer.value.replace("M", "m")


# ============================================================
# 3. LAUNCH EXCEL
# ============================================================

excel = win32.DispatchEx("Excel.Application")
excel.Visible = False
excel.DisplayAlerts = False

workbook = None

try:

    # Create a workbook using local Excel defaults
    workbook = excel.Workbooks.Add()

    # Ensure that at least 3 sheets exist
    while workbook.Worksheets.Count < 3:
        workbook.Worksheets.Add(
            After=workbook.Worksheets(
                workbook.Worksheets.Count
            )
        )

    source = workbook.Worksheets(1)
    calc = workbook.Worksheets(2)
    comparison = workbook.Worksheets(3)

    source.Name = "Source"
    calc.Name = "Calculation"
    comparison.Name = "Comparison"

    # Save original column width for verification
    default_width = source.Columns("A").ColumnWidth

    # ========================================================
    # 4. NUMBER FORMATS
    # ========================================================

    # Actual built-in Excel Comma Style number format
    comma_format = workbook.Styles("Comma").NumberFormat

    # Local Windows Short Date pattern
    date_format = get_short_date_format()

    print("Comma Style:", comma_format)
    print("Short Date:", date_format)

    # ========================================================
    # 5. SOURCE WORKSHEET
    # ========================================================

    headers = [
        "AssetName",
        "PaymentDate",
        "Principal",
        "LateCharges",
        "Rate",
        "Days",
        "ASAP_Other58",
    ]

    for col, header in enumerate(headers, 1):
        source.Cells(1, col).Value = header

    sample_data = [
        (
            "AALC2201-001",
            datetime(2026, 10, 15),
            1234567.89,
            1250.50,
            0.065,
            30,
            625.25,
        ),
        (
            "AALC2201-002",
            datetime(2026, 10, 15),
            2500000.00,
            0.00,
            0.0725,
            31,
            0.00,
        ),
        (
            "AALC2201-003",
            datetime(2026, 10, 15),
            875432.10,
            35.64,
            0.0575,
            29,
            17.82,
        ),
    ]

    for row, data in enumerate(sample_data, 2):
        for col, value in enumerate(data, 1):
            source.Cells(row, col).Value = value

    # Short Date
    source.Range("B2:B4").NumberFormat = date_format

    # Monetary values
    for address in ("C2:D4", "G2:G4"):
        source.Range(address).NumberFormat = comma_format

    # E and F retain General format

    # ========================================================
    # 6. CALCULATION WORKSHEET
    # ========================================================

    calc_headers = [
        "AssetName",
        "PaymentDate",
        "Principal",
        "LateCharges",
        "Other58_Excel",
        "Accrual",
        "Rate",
        "Days",
    ]

    for col, header in enumerate(calc_headers, 1):
        calc.Cells(1, col).Value = header

    for row in range(2, 5):

        calc.Cells(row, 1).Formula = f"=Source!A{row}"

        # INDEX MATCH - PaymentDate
        calc.Cells(row, 2).Formula = (
            f"=INDEX(Source!$B$2:$B$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # INDEX MATCH - Principal
        calc.Cells(row, 3).Formula = (
            f"=INDEX(Source!$C$2:$C$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # INDEX MATCH - LateCharges
        calc.Cells(row, 4).Formula = (
            f"=INDEX(Source!$D$2:$D$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # Actual Other58 calculation
        calc.Cells(row, 5).Formula = f"=D{row}/2"

        # INDEX MATCH - Rate
        calc.Cells(row, 7).Formula = (
            f"=INDEX(Source!$E$2:$E$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # INDEX MATCH - Days
        calc.Cells(row, 8).Formula = (
            f"=INDEX(Source!$F$2:$F$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # Actual/360 Accrual
        calc.Cells(row, 6).Formula = (
            f"=C{row}*G{row}*H{row}/360"
        )

    # Dates
    calc.Range("B2:B4").NumberFormat = date_format

    # Monetary fields
    calc.Range("C2:F4").NumberFormat = comma_format

    # Rate and Days remain General

    # ========================================================
    # 7. COMPARISON WORKSHEET
    # ========================================================

    comp_headers = [
        "AssetName",
        "Excel",
        "ASAP SQL",
        "Difference",
    ]

    for col, header in enumerate(comp_headers, 1):
        comparison.Cells(1, col).Value = header

    for row in range(2, 5):

        comparison.Cells(row, 1).Formula = (
            f"=Calculation!A{row}"
        )

        # Excel calculated Other58
        comparison.Cells(row, 2).Formula = (
            f"=INDEX(Calculation!$E$2:$E$4,"
            f"MATCH(A{row},Calculation!$A$2:$A$4,0))"
        )

        # Mock ASAP SQL benchmark
        comparison.Cells(row, 3).Formula = (
            f"=INDEX(Source!$G$2:$G$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # Difference = Excel - ASAP
        comparison.Cells(row, 4).Formula = (
            f"=B{row}-C{row}"
        )

    comparison.Range("B2:D4").NumberFormat = comma_format

    # ========================================================
    # 8. RECALCULATE
    # ========================================================

    excel.CalculateFullRebuild()

    # ========================================================
    # 9. SAVE AS XLSB
    # ========================================================

    workbook.SaveAs(
        Filename=str(OUTPUT_FILE),
        FileFormat=XL_EXCEL12,
    )

    # ========================================================
    # 10. VERIFY
    # ========================================================

    print("\n--- WORKBOOK VERIFICATION ---")

    print("Output:", OUTPUT_FILE)
    print("FileFormat:", workbook.FileFormat)
    print("Original Column Width:", default_width)
    print(
        "Current Column Width:",
        source.Columns("A").ColumnWidth,
    )

    print(
        "Date Format:",
        source.Range("B2").NumberFormat,
    )

    print(
        "Money Format:",
        source.Range("C2").NumberFormat,
    )

    print(
        "Rate Format:",
        source.Range("E2").NumberFormat,
    )

    print(
        "Days Format:",
        source.Range("F2").NumberFormat,
    )

    print("\n--- FORMULA VERIFICATION ---")

    for cell in ("C2", "D2", "E2", "F2"):
        print(
            "Calculation!" + cell,
            "Formula:",
            calc.Range(cell).Formula,
            "Value:",
            calc.Range(cell).Value,
        )

    print("\n--- COMPARISON ---")

    for row in range(2, 5):
        asset = comparison.Cells(row, 1).Value
        value_excel = comparison.Cells(row, 2).Value
        value_asap = comparison.Cells(row, 3).Value
        difference = comparison.Cells(row, 4).Value

        print(
            asset,
            "Excel:", value_excel,
            "ASAP:", value_asap,
            "Difference:", difference,
        )

    if workbook.FileFormat != XL_EXCEL12:
        raise RuntimeError("Workbook was not saved as XLSB.")

    if source.Columns("A").ColumnWidth != default_width:
        raise RuntimeError("Default column width was changed.")

    print("\nSUCCESS: XLSB workbook created.")

finally:

    if workbook is not None:
        workbook.Close(SaveChanges=False)

    excel.Quit()
