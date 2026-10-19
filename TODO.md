
Continue the AALC2201 ASAP Calculation Replica project.

Phase 1.5B has been completed successfully.

The actual September and October workbooks have been
ingested and validated.

CURRENT OBJECTIVE:
Prepare missing runtime inputs and implement the first
small, independently verifiable Excel formula prototype.

Do not repeat the full Phase 1 analysis.
Do not rebuild the ASAP Knowledge Base.
Do not attempt all 56 calculated fields yet.

PART 1 — RUNTIME INPUT DISCOVERY

Review:
- Existing Phase 1 and Phase 1.5 reports
- required_inputs.json
- revised_missing_inputs.csv
- ordered_calculation_stages.json
- Existing ASAP Knowledge Base
- Actual October and September Excel datasets

Determine the remaining required runtime inputs.

Prioritize:
1. Current ASAP period number
2. Previous ASAP period number
3. CollectionStart, CollectionEnd, PriorMonthBeg
4. Aggregate_Servicing_Fees.InputValue
5. h15tly index observations
6. Active asset membership
7. Transaction ordering
8. Reachable pre-script Other1 / Other3 dependencies

Retrieve available information from existing
documentation and authorized local inputs.

Do not invent unknown values.

Create a runtime input schema and an input template
under the October run directory.

Report only the values that genuinely require
manual input or an additional ASAP export.

PART 2 — FIRST EXCEL PROTOTYPE

Start with AssetPeriodic.Other58.

Source logic:
Other58 = LateCharges / 2

Preserve the original script's active-asset filtering
and execution conditions.

Use the actual October AssetPeriodic workbook
as the input source.

Use the October post-ASAP Other58 values strictly
as benchmarks.

Never reference October final Other58 values
in the reconstructed calculation.

Build a small workbook containing:

- October source data
- Asset calculation
- ASAP benchmark
- Comparison

Comparison should contain identity columns and:

Excel
ASAP SQL
Difference

Difference = Excel - ASAP SQL

FORMATTING REQUIREMENTS

- Use Excel COM on Windows.
- Create workbook with Workbooks.Add().
- Preserve local default Excel formatting.
- Never change column widths.
- Dates use Short Date.
- Monetary amounts use built-in Comma Style.
- All other values use General.
- Use INDEX/MATCH for cross-sheet lookups.
- No decorative formatting.

PART 3 — VALIDATION

1. Verify the Excel calculation contains native formulas.
2. Perform actual Excel recalculation.
3. Verify asset matching.
4. Compare calculated Other58 against ASAP output.
5. Perform calculation isolation tests:
   - Changing benchmark Other58 must not change
     reconstructed Other58.
   - Changing source LateCharges must change
     reconstructed Other58 appropriately.
6. Report all discrepancies.
7. Do not silently treat unmatched assets as zero.

IMPORTANT:

If active asset membership cannot be established,
do not fabricate a filter.

You may demonstrate an explicitly provisional
arithmetic formula on verified example rows, but
do not claim full ASAP equivalence.

Stop and report the minimum missing runtime evidence
needed to complete the prototype.

PART 4 — DELIVERABLES

- Runtime input template
- Remaining input requirements
- Other58 prototype Excel workbook, if supported
- Formula isolation test results
- SQL comparison results
- Updated progress.md
- Updated implementation_plan.md

Do not modify original source workbooks.
Do not modify original ASAP scripts.
Do not implement the remaining 55 fields yet.

Stop after this prototype and wait for my approval.
