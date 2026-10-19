
Continue the AALC2201 ASAP Calculation Replica project.

IMPORTANT CLARIFICATION OF THE CALCULATION OBJECTIVE

I will provide two periods of AssetPeriodic data:

- October 2026 = current period
- September 2026 = period - 1

Both AssetPeriodic datasets contain POST-ASAP-calculation values.

The September completed values may be used as historical
inputs where the original script explicitly references
period - 1 or an equivalent verified historical state.

However, October script-generated field values must
NEVER be reused as calculation inputs for reconstructing
those same October fields.

Our goal is to independently reconstruct EVERY field
written by the original ASAP periodic calculation script
using an Excel-native formula dependency chain.

October post-run values are available for benchmarking,
not for seeding the October calculation chain.

TASK: REFINE PHASE 1 BEFORE EXCEL IMPLEMENTATION

1. Identify the complete write-set of the original
   AALC2201 periodic calculation script.

2. Identify all source fields read by the script,
   including implicit runtime dependencies.

3. For every October AssetPeriodic field, distinguish:

   A. Script-written calculated output

   B. External/source input not written by this script

   C. Historical state explicitly read from period - 1

   D. Pre-script or intermediate state whose origin
      is not yet confirmed

4. Treat the complete October post-run AssetPeriodic
   table as a mixed dataset containing both legitimate
   source inputs and final calculated outputs.

5. Do not allow October script-written final values
   to feed any Excel reconstructed calculation.

6. For every October script-written field, build a
   formula lineage tracing back exclusively to:
   - Legitimate current-period source inputs
   - Verified runtime inputs
   - Current-period reconstructed Excel intermediates
   - Legitimate September historical values
   - Explicit constants or parameters in the script

7. Preserve the exact sequence of assignments.

   An individual output field may be initialized,
   incremented, modified, overwritten or conditionally
   assigned multiple times.

   Model each necessary intermediate state explicitly.

8. Detect READ-BEFORE-WRITE dependencies.

   If a field is read before being initialized in
   the visible script, identify its actual pre-script
   value source.

   Never use its October post-run final value
   as an initialization shortcut.

   Never assume zero initialization without evidence.

9. Preserve:
   - Transaction aggregation
   - Transaction ordering when relevant
   - Asset collection membership
   - Portfolio aggregation
   - Waterfall stages
   - Sequential mutations
   - Conditional branches
   - Exceptions
   - Prior-period carryforward
   - Historical rewrite behavior

10. Build a stage-aware dependency graph.

    For each assignment, identify the version of
    every upstream field actually being read.

    Do not collapse multiple sequential writes into
    a single field-level dependency if doing so
    changes execution semantics.

11. Separate the three types of October values:
    - Original post-run source snapshot
    - Independently reconstructed Excel values
    - ASAP SQL benchmark values

12. Add a strict calculation-isolation validation:

    Changing October benchmark values must not
    change any reconstructed Excel calculation.

    Changing October post-run values of
    script-written fields must not change any
    reconstructed Excel calculation.

    Changing legitimate source inputs should
    propagate through the dependent Excel formulas.

    Changing September historical values should
    affect only the appropriate downstream
    carryforward calculations.

13. Update the field readiness analysis based on
    actual calculation prerequisites.

14. Identify the smallest complete dependency chain
    suitable for the first Excel prototype.

15. Produce:
    - script_write_set.csv
    - source_input_classification.csv
    - read_before_write_report.csv
    - ordered_calculation_stages.json
    - calculation_isolation_rules.md
    - updated_field_readiness.csv

16. Save deal-specific reports under the local,
    Git-ignored run reports directory.

17. Update the implementation plan and progress
    documentation.

Do not execute ASAP.
Do not generate the full Excel workbook yet.
Do not alter the original ASAP script.
Do not assume missing runtime semantics.

Stop after the updated dependency and input/output
isolation analysis.

Present the remaining blockers before Phase 2.
