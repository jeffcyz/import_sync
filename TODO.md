
import argparse
import ctypes
import time
from datetime import datetime
from pathlib import Path

import win32com.client as win32


# ============================================================
# 1. CONFIGURATION
# ============================================================

# Citi labels — transcribed from the supplied VBA screenshot.
CITI_LABELS = {
    "Public": "d291669d-c62a-41f9-9790-e463798003d8",
    "Internal": "dd181445-6ec4-4473-9810-00785f082df0",
    "Internal PII": "d4763801-a845-4ca5-827b-408ff682eaab",
    "Confidential": "0133068c-5f3b-4062-adca-9b17e9c90306",
    "Confidential PII": "ef691c43-652c-4966-abd9-c2d7e9f82ab4",
    "Sensitive PII": "011939e9-cdc1-48bb-82e6-5abf0874d347",
    "Restricted": "e4757149-730e-4418-8a27-ea34a98d08dc",
}

# Automatically use Internal for new synthetic test workbooks.
DEFAULT_LABEL = "Internal"
DEFAULT_LABEL_ID = CITI_LABELS[DEFAULT_LABEL]

# Excel Binary Workbook (*.xlsb)
XL_EXCEL12 = 50

DOWNLOADS = Path.home() / "Downloads"


# ============================================================
# 2. WINDOWS SHORT DATE FORMAT
# ============================================================

def get_short_date_format():
    """Read Windows regional Short Date settings."""

    buffer = ctypes.create_unicode_buffer(128)

    result = ctypes.windll.kernel32.GetLocaleInfoW(
        0x0400,  # LOCALE_USER_DEFAULT
        0x001F,  # LOCALE_SSHORTDATE
        buffer,
        len(buffer),
    )

    if result == 0:
        raise ctypes.WinError()

    # Common Windows month notation -> Excel notation.
    return buffer.value.replace("M", "m")


# ============================================================
# 3. SENSITIVITY LABEL HELPERS
# ============================================================

def get_workbook_label(wb):
    """Read an existing Excel sensitivity label."""

    info = wb.SensitivityLabel.GetLabel()

    if info is None:
        return None

    label_id = str(info.LabelId or "").strip()

    if not label_id:
        return None

    return {
        "id": label_id,
        "name": str(info.LabelName or ""),
    }


def apply_internal_label(wb):
    """
    Apply Internal automatically to an unlabeled workbook.

    Preserve any different existing label.
    Never overwrite or downgrade an existing classification.
    """

    existing = get_workbook_label(wb)

    if existing:
        if existing["id"].lower() == DEFAULT_LABEL_ID.lower():
            print("Internal label already present.")
            return

        raise RuntimeError(
            "Workbook already has a different sensitivity label: "
            f"{existing['name']}. Automatic relabeling is blocked."
        )

    print("Applying Internal Sensitivity Label...")

    sensitivity = wb.SensitivityLabel

    info = sensitivity.CreateLabelInfo()

    # Mirrors the supplied VBA implementation.
    info.AssignmentMethod = 1
    info.Justification = ""
    info.IsEnabled = True
    info.LabelId = DEFAULT_LABEL_ID
    info.LabelName = DEFAULT_LABEL
    info.SiteId = ""
    info.SetDate = datetime.now()

    context = win32.Dispatch("Scripting.Dictionary")

    sensitivity.SetLabel(info, context)

    # Allow a short time for Office to update its label state.
    for _ in range(15):
        applied = get_workbook_label(wb)

        if (
            applied
            and applied["id"].lower() == DEFAULT_LABEL_ID.lower()
        ):
            print("Internal label confirmed.")
            return

        time.sleep(0.2)

    raise RuntimeError(
        "Excel did not confirm the Internal sensitivity label. "
        "Check the tenant label ID, SiteId requirements, "
        "and corporate labeling policy."
    )


# ============================================================
# 4. GENERATE TEST WORKBOOK
# ============================================================

def populate_workbook(wb):

    while wb.Worksheets.Count < 3:
        wb.Worksheets.Add(
            After=wb.Worksheets(wb.Worksheets.Count)
        )

    source = wb.Worksheets(1)
    calc = wb.Worksheets(2)
    comparison = wb.Worksheets(3)

    source.Name = "Source"
    calc.Name = "Calculation"
    comparison.Name = "Comparison"

    # Capture default widths for verification.
    original_widths = {
        sheet.Name: sheet.Columns("A").ColumnWidth
        for sheet in (source, calc, comparison)
    }

    # Built-in Excel Comma Style number format.
    comma_format = wb.Styles("Comma").NumberFormat

    # Local Windows Short Date.
    date_format = get_short_date_format()

    # --------------------------------------------------------
    # SOURCE
    # --------------------------------------------------------

    headers = [
        "AssetName",
        "PaymentDate",
        "Principal",
        "LateCharges",
        "Rate",
        "Days",
        "ASAP_Other58",
    ]

    for col, title in enumerate(headers, 1):
        source.Cells(1, col).Value = title

    sample_data = [
        ("Asset001", 1234567.89, 1200.50, 0.065, 30, 600.25),
        ("Asset002", 2500000.00, 300.00, 0.075, 31, 150.00),
        ("Asset003", 875432.10, 75.80, 0.055, 29, 37.90),
    ]

    for row, data in enumerate(sample_data, start=2):

        name, principal, charges, rate, days, benchmark = data

        source.Cells(row, 1).Value = name
        source.Cells(row, 2).Value = datetime(2026, 10, 15)
        source.Cells(row, 3).Value = principal
        source.Cells(row, 4).Value = charges
        source.Cells(row, 5).Value = rate
        source.Cells(row, 6).Value = days
        source.Cells(row, 7).Value = benchmark

    source.Range("B2:B4").NumberFormat = date_format

    for address in ("C2:D4", "G2:G4"):
        source.Range(address).NumberFormat = comma_format

    # Rate and Days remain General.

    # --------------------------------------------------------
    # CALCULATION
    # --------------------------------------------------------

    calc_headers = [
        "AssetName",
        "Other58_Excel",
        "Principal",
        "Rate",
        "Days",
        "Accrual",
    ]

    for col, title in enumerate(calc_headers, 1):
        calc.Cells(1, col).Value = title

    for row in range(2, 5):

        calc.Cells(row, 1).Formula = f"=Source!A{row}"

        # Other58 = LateCharges / 2
        # INDEX/MATCH exact matching.
        calc.Cells(row, 2).Formula = (
            "=INDEX(Source!$D$2:$D$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))/2"
        )

        calc.Cells(row, 3).Formula = (
            "=INDEX(Source!$C$2:$C$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        calc.Cells(row, 4).Formula = (
            "=INDEX(Source!$E$2:$E$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        calc.Cells(row, 5).Formula = (
            "=INDEX(Source!$F$2:$F$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        # Actual/360 example.
        calc.Cells(row, 6).Formula = (
            f"=C{row}*D{row}*E{row}/360"
        )

    calc.Range("B2:C4").NumberFormat = comma_format
    calc.Range("F2:F4").NumberFormat = comma_format

    # D/E: General.

    # --------------------------------------------------------
    # COMPARISON
    # --------------------------------------------------------

    comp_headers = [
        "AssetName",
        "Excel",
        "ASAP SQL",
        "Difference",
    ]

    for col, title in enumerate(comp_headers, 1):
        comparison.Cells(1, col).Value = title

    for row in range(2, 5):

        comparison.Cells(row, 1).Formula = (
            f"=Calculation!A{row}"
        )

        comparison.Cells(row, 2).Formula = (
            "=INDEX(Calculation!$B$2:$B$4,"
            f"MATCH(A{row},Calculation!$A$2:$A$4,0))"
        )

        comparison.Cells(row, 3).Formula = (
            "=INDEX(Source!$G$2:$G$4,"
            f"MATCH(A{row},Source!$A$2:$A$4,0))"
        )

        comparison.Cells(row, 4).Formula = (
            f"=B{row}-C{row}"
        )

    comparison.Range("B2:D4").NumberFormat = comma_format

    # Verify that all default column widths remain unchanged.
    for sheet in (source, calc, comparison):
        assert (
            sheet.Columns("A").ColumnWidth
            == original_widths[sheet.Name]
        ), f"Column width changed on {sheet.Name}"

    return {
        "comma": comma_format,
        "date": date_format,
        "widths": original_widths,
    }


# ============================================================
# 5. CREATE, SAVE, AND REOPEN XLSB
# ============================================================

def test_create(excel):

    DOWNLOADS.mkdir(parents=True, exist_ok=True)

    output = DOWNLOADS / (
        "ASAP_Excel_Format_Test_"
        f"{datetime.now():%Y%m%d_%H%M%S}.xlsb"
    )

    wb = excel.Workbooks.Add()

    try:
        print("\nCreating workbook...")

        # Apply Internal before writing/saving.
        apply_internal_label(wb)

        formats = populate_workbook(wb)

        excel.CalculateFullRebuild()

        wb.SaveAs(
            Filename=str(output),
            FileFormat=XL_EXCEL12,
        )

        if wb.FileFormat != XL_EXCEL12:
            raise RuntimeError("Workbook was not saved as XLSB.")

        if not output.is_file():
            raise RuntimeError("Expected XLSB output was not found.")

        print("\n--- CREATED WORKBOOK ---")
        print("File:", output)
        print("FileFormat:", wb.FileFormat)
        print("Label:", get_workbook_label(wb))
        print("Comma Format:", formats["comma"])
        print("Short Date:", formats["date"])

    finally:
        wb.Close(SaveChanges=False)

    # --------------------------------------------------------
    # REOPEN TO VERIFY PERSISTED LABEL AND FORMULAS
    # --------------------------------------------------------

    print("\nReopening generated XLSB...")

    reopened = excel.Workbooks.Open(
        Filename=str(output),
        UpdateLinks=0,
        ReadOnly=True,
    )

    try:
        label = get_workbook_label(reopened)

        if (
            not label
            or label["id"].lower() != DEFAULT_LABEL_ID.lower()
        ):
            raise RuntimeError(
                "The saved XLSB did not retain the Internal label."
            )

        if reopened.FileFormat != XL_EXCEL12:
            raise RuntimeError("Reopened file format is not XLSB.")

        source = reopened.Worksheets("Source")
        calc = reopened.Worksheets("Calculation")
        comparison = reopened.Worksheets("Comparison")

        print("\n--- FORMAT VERIFICATION ---")
        print("Date:", source.Range("B2").NumberFormat)
        print("Money:", source.Range("C2").NumberFormat)
        print("Rate:", source.Range("E2").NumberFormat)
        print("Days:", source.Range("F2").NumberFormat)
        print("Column Width:", source.Columns("A").ColumnWidth)

        print("\n--- FORMULA VERIFICATION ---")
        print("Formula:", calc.Range("B2").Formula)
        print("Excel Value:", calc.Range("B2").Value)

        for row in range(2, 5):
            asset = comparison.Cells(row, 1).Value
            excel_value = comparison.Cells(row, 2).Value
            asap_value = comparison.Cells(row, 3).Value
            difference = comparison.Cells(row, 4).Value

            print(
                asset,
                "| Excel:", excel_value,
                "| ASAP:", asap_value,
                "| Difference:", difference,
            )

            if not isinstance(difference, (int, float)):
                raise RuntimeError(
                    f"Invalid difference for row {row}: {difference!r}"
                )

            if abs(difference) > 1e-8:
                raise RuntimeError(
                    f"Comparison mismatch at row {row}: {difference}"
                )

        print("\nSUCCESS: Internal Label + XLSB + Formats + Formulas")

    finally:
        reopened.Close(SaveChanges=False)

    print("\nOutput:", output)


# ============================================================
# 6. OPEN EXISTING WORKBOOK TEST
# ============================================================

def test_open(excel, file_path):

    path = Path(file_path).expanduser().resolve()

    if not path.is_file():
        raise FileNotFoundError(path)

    wb = excel.Workbooks.Open(
        Filename=str(path),
        UpdateLinks=0,
        ReadOnly=True,
    )

    try:
        label = get_workbook_label(wb)

        if label:
            print("\nExisting Label:", label["name"])

            if label["id"].lower() != DEFAULT_LABEL_ID.lower():
                print(
                    "Existing label is not Internal. "
                    "Preserving the original classification."
                )

        else:
            print("No existing label confirmed.")
            print("Applying Internal in this read-only test session.")

            # In-memory only; original workbook is not saved.
            apply_internal_label(wb)

        print("Workbook:", wb.Name)
        print("Worksheets:", wb.Worksheets.Count)
        print("Current Label:", get_workbook_label(wb))

    finally:
        wb.Close(SaveChanges=False)

    print("\nRead-only opening test completed.")


# ============================================================
# 7. MAIN
# ============================================================

def main():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--mode",
        choices=["create", "open"],
        default="create",
    )

    parser.add_argument(
        "--path",
        help="Existing Excel workbook for open mode",
    )

    args = parser.parse_args()

    if args.mode == "open" and not args.path:
        parser.error("--path is required for open mode")

    excel = win32.DispatchEx("Excel.Application")

    # Visible for any Citi policy or Excel security prompts.
    excel.Visible = True
    excel.DisplayAlerts = True

    try:
        if args.mode == "create":
            test_create(excel)
        else:
            test_open(excel, args.path)

    finally:
        excel.Quit()


if __name__ == "__main__":
    main()
