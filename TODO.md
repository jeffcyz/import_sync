
from pathlib import Path
from datetime import datetime
import win32com.client as win32

# ============================================================
# Output location
# ============================================================

downloads = Path.home() / "Downloads"
downloads.mkdir(parents=True, exist_ok=True)

output_file = downloads / (
    f"ASAP_Excel_Format_Test_{datetime.now():%Y%m%d_%H%M%S}.xlsx"
)

# ============================================================
# Launch a separate Microsoft Excel instance
# ============================================================

excel = win32.DispatchEx("Excel.Application")
excel.Visible = False
excel.DisplayAlerts = False

workbook = None

try:
    # Use the locally installed Excel's New Workbook defaults
    workbook = excel.Workbooks.Add()
    sheet = workbook.Worksheets(1)
    sheet.Name = "FormatTest"

    # Record the default column width
    default_width = sheet.StandardWidth

    # ========================================================
    # Get BUILT-IN Excel formats
    # ========================================================

    # These are taken directly from local Excel cell styles.
    # Only apply NumberFormat, not the entire cell style.

    comma_format = workbook.Styles("Comma").NumberFormat
    short_date_format = workbook.Styles("Short Date").NumberFormat

    print("Built-in Comma Style:", comma_format)
    print("Built-in Short Date:", short_date_format)

    # ========================================================
    # Headers - no special formatting
    # ========================================================

    headers = [
        "AssetName",
        "PaymentDate",
        "Principal",
        "Interest",
        "Total",
        "Rate",
        "Days",
        "Accrual",
        "INDEX_MATCH",
        "Difference",
    ]

    for col, header in enumerate(headers, start=1):
        sheet.Cells(1, col).Value = header

    # ========================================================
    # Sample Data
    # ========================================================

    sample_data = [
        (
            "AALC2201-001",
            datetime(2026, 10, 15),
            1234567.89,
            1250.50,
            0.065,
            30,
        ),
        (
            "AALC2201-002",
            datetime(2026, 10, 16),
            2500000.00,
            2150.75,
            0.0725,
            31,
        ),
        (
            "AALC2201-003",
            datetime(2026, 10, 17),
            875432.10,
            950.25,
            0.0575,
            29,
        ),
    ]

    for row, data in enumerate(sample_data, start=2):

        name, payment_date, principal, interest, rate, days = data

        # Raw values
        sheet.Cells(row, 1).Value = name
        sheet.Cells(row, 2).Value = payment_date
        sheet.Cells(row, 3).Value = principal
        sheet.Cells(row, 4).Value = interest
        sheet.Cells(row, 6).Value = rate
        sheet.Cells(row, 7).Value = days

        # Formula: Total
        sheet.Cells(row, 5).Formula = f"=C{row}+D{row}"

        # Formula: Accrual using Actual/360
        sheet.Cells(row, 8).Formula = (
            f"=C{row}*F{row}*G{row}/360"
        )

        # Formula: INDEX + MATCH (exact match)
        sheet.Cells(row, 9).Formula = (
            f"=INDEX($E$2:$E$4,"
            f"MATCH(A{row},$A$2:$A$4,0))"
        )

        # Formula: Difference
        sheet.Cells(row, 10).Formula = f"=I{row}-E{row}"

    # ========================================================
    # Apply ONLY the requested number formats
    # ========================================================

    # Date -> Built-in Short Date
    sheet.Range("B2:B4").NumberFormat = short_date_format

    # Monetary fields -> Built-in Comma Style
    for address in ("C2:E4", "H2:J4"):
        sheet.Range(address).NumberFormat = comma_format

    # Everything else remains General.
    # No styles, font changes, colors, column widths,
    # borders, alignment or AutoFit are applied.

    # ========================================================
    # Recalculate and save
    # ========================================================

    excel.CalculateFullRebuild()

    workbook.SaveAs(
        str(output_file),
        FileFormat=51,  # .xlsx
    )

    # ========================================================
    # Verification
    # ========================================================

    print("\n--- FORMAT VERIFICATION ---")

    print("Default column width:", default_width)
    print("Current column A width:", sheet.Columns("A").ColumnWidth)

    print("Date format:", sheet.Range("B2").NumberFormat)
    print("Money format:", sheet.Range("C2").NumberFormat)
    print("Rate format:", sheet.Range("F2").NumberFormat)
    print("Days format:", sheet.Range("G2").NumberFormat)

    print("\n--- FORMULA VERIFICATION ---")

    for cell in ("E2", "H2", "I2", "J2"):
        print(
            cell,
            "Formula:", sheet.Range(cell).Formula,
            "Value:", sheet.Range(cell).Value,
        )

    print("\nWorkbook successfully created:")
    print(output_file)

finally:
    if workbook is not None:
        workbook.Close(SaveChanges=False)

    excel.Quit()
