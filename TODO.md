
IMPORTANT CORRECTION TO THE PHASE 1 REFINEMENT:

The actual October and September datasets HAVE ALREADY
BEEN PROVIDED as Excel workbooks.

They are located at:

runs/AALC2201/2026-10/inputs/original/

I can see four Excel files in this directory:

1. Assets - AALC2201.xlsx
2. Asset Periodics - 2026-09-15...xlsx
3. Asset Periodics - 2026-10-15...xlsx
4. Asset Periodic Transaction - 20...xlsx

Use filesystem discovery to identify their exact names.

The previous Phase 1 report incorrectly characterized
these datasets as not yet provided.

They are PRESENT but have NOT BEEN INGESTED.

CURRENT TASK:
Phase 1.5B — Actual Excel Source Discovery and
Data Dependency Resolution.

Do not regenerate the existing static dependency graph
unless actual workbook schemas reveal a necessary change.

STEP 1 — VERIFY LOCAL FILES

- Confirm the actual workspace/repository root.
- Enumerate all Excel workbooks in inputs/original/.
- Report exact filenames, sizes, worksheet names,
  dimensions, headers and data types.
- Do not rely only on Git-tracked file discovery.
- Do not require manually converted CSV files.

STEP 2 — IDENTIFY SOURCE TABLE ROLES

Determine which workbook/worksheet corresponds to:

- AssetSetup
- September AssetPeriodic (period - 1)
- October AssetPeriodic (current period)
- AssetPeriodicTransaction
- AssetPeriodicLegacy, if applicable

Do not assume that each workbook contains only
one worksheet.

Use actual worksheet schemas and field names,
not filenames alone, to confirm table mapping.

STEP 3 — VALIDATE PERIOD MAPPING

Identify the current ASAP period number and the
previous period number.

The September and October dates in filenames
are candidate payment dates, not proof of the
ASAP period index.

Verify the mapping against available runtime inputs
and document any missing period information.

STEP 4 — VALIDATE SOURCE KEYS

Inspect actual data to determine:

- AssetId
- DealId
- AssetName
- PaymentDate
- Transaction identifiers
- Relevant composite keys

Verify uniqueness and referential relationships.

Do not assume AssetName is unique.

STEP 5 — CONNECT DATA TO THE EXISTING DEPENDENCY GRAPH

Read:
- script_write_set.csv
- source_input_classification.csv
- read_before_write_report.csv
- ordered_calculation_stages.json
- calculation_dependency_graph.json
- required_inputs.json
- missing_inputs.csv

For each dependency, determine whether its data
actually exists in the provided Excel workbooks.

Resolve previously reported data gaps using
actual worksheet columns.

Do not classify a field as missing merely because
it is not present as a CSV file.

STEP 6 — ENFORCE CALCULATION ISOLATION

The October AssetPeriodic values are post-ASAP-run.

For the 56 script-written fields:

- October final values are benchmarks only.
- Never use October final script-written values
  as inputs to reconstructed formulas.
- October non-script-written fields can be inputs
  when semantically valid.
- September completed values are permitted only
  for verified historical dependencies.

Detect and block output leakage.

For read-before-write fields, confirm whether the
necessary pre-script state exists separately.

Do not use October final values to fill missing
pre-script state.

STEP 7 — IMPLEMENT A REUSABLE EXCEL SOURCE LOADER

If the repository does not already support original
Excel workbook ingestion, implement the minimum
necessary read-only ingestion functionality.

Requirements:

- Support multiple XLSX workbooks.
- Support multiple worksheets per workbook.
- Use openpyxl or an appropriate Excel reader.
- Preserve original files without modification.
- Retain numeric precision, blank cells, dates,
  identifiers and source column names.
- Identify duplicate or missing keys.
- Do not convert to CSV unless required.
- Do not generate final Excel calculation formulas yet.

Design the loader so other AALC deals can reuse it.

STEP 8 — REFRESH ACTUAL DATA READINESS

Produce:

- workbook_inventory.csv
- worksheet_schema_inventory.csv
- source_table_mapping.json
- period_mapping_report.md
- asset_key_validation.csv
- input_dependency_coverage.csv
- revised_missing_inputs.csv
- updated_field_readiness.csv

Distinguish:

PRESENT_AND_VALIDATED
PRESENT_BUT_MAPPING_UNRESOLVED
ABSENT
NOT_APPLICABLE

STEP 9 — REPORT REMAINING BLOCKERS

After reading the actual Excel files, identify
which dependencies are still missing.

Specifically check:

- payment_inputs
- ASAP period number
- deal.critical_dates
- index observations
- pre-script initialization values
- runtime collection semantics
- transaction ordering

Do not assume these are present unless verified.

Run the appropriate automated tests.

Do not modify original Excel workbooks.
Do not modify original ASAP scripts.
Do not generate the final Excel workbook yet.

Stop after producing the revised data readiness report.
