# AALC2201 — Phase 1: Knowledge-Grounded Runtime Semantic Analysis

The local ASAP Knowledge Base has been implemented successfully.

The existing system includes:

- 678 raw Markdown documents.
- 2,389 semantic sections.
- 2,995 structured symbols.
- 1,434 release changes.
- 302 SQL tables/views and 13,064 columns.
- Exact symbol lookup and SQLite FTS5.
- Source/section/line provenance.
- Incremental indexing.
- AALC-specific knowledge integration.
- Existing A/B/C/D semantic readiness classification.

The Knowledge Base infrastructure is now established.

**Do not rebuild, duplicate, or reorganize the Knowledge Base unless a specific defect is discovered.**

## Primary Objective

Advance the project to **Phase 1: AALC2201 Runtime Semantic Analysis and Calculation Dependency Discovery**.

The objective is to understand how the original ASAP calculations work before attempting to reproduce them in native Excel.

ASAP scripts depend on host-provided IronPython objects, runtime state, execution lifecycle, and external data.

Do not assume that executing the original scripts in standalone Python will reproduce ASAP behavior.

Do not build a complete ASAP runtime emulator.

## 1. Knowledge Base Quality Gate

Review the existing ingestion and coverage reports.

Investigate:

- The 59 incomplete Markdown documents.
- Any missing or truncated Function Signatures.
- Potentially lost code examples.
- The 2 unresolved AALC2201 candidate symbols.
- Accuracy of the existing source references.

Prioritize documentation actually referenced by AALC2201.

Do not repeat the full ingestion pipeline without evidence of a problem.

Distinguish source incompleteness from extraction errors and harmless Markdown formatting differences.

## 2. Analyze Actual AALC2201 Scripts

Read all available authorized scripts under:

`deals/AALC2201/asap_scripts/`

Preserve the original scripts unchanged.

Build a complete static inventory of:

- Functions and classes.
- ASAP host-provided objects.
- Method calls and property access.
- Inputs and outputs.
- Field assignments.
- Mutations and side effects.
- Conditional branches.
- Loops and execution order.
- Collection operations.
- Date and period logic.
- Historical state dependencies.
- Index and rate lookup operations.
- External and SQL data dependencies.

Do not rely only on lexical keyword matching.

Support the syntax actually present in the scripts. Where parsing is incomplete, retain exact source locations and report the limitation.

## 3. Resolve ASAP Runtime Semantics

For every ASAP-specific symbol:

1. Perform exact Knowledge Base lookup.
2. Retrieve the corresponding Scripting Manual definition.
3. Check applicable Release Changes.
4. Retrieve relevant User Manual behavior when necessary.
5. Check SQL Server metadata where relevant.
6. Identify required runtime inputs.
7. Establish documented output and side-effect behavior.
8. Identify remaining unknowns.

Every runtime contract must include source references.

Do not infer method behavior solely from naming conventions.

If documentation is insufficient, report UNKNOWN.

## 4. Build Calculation Dependency Graph

For every calculated output field, build a dependency chain:

Output Field
→ ASAP Source Expression
→ Intermediate Calculations
→ Runtime Operations
→ Required Input Fields
→ Historical / Period Dependencies
→ SQL / CSV Mappings
→ Knowledge Evidence

Preserve:

- Execution order.
- Intermediate field mutations.
- Transaction processing sequence.
- Conditional logic.
- Portfolio calculation dependencies.
- Historical carryforward.
- Runtime initialization requirements.

Detect and report unresolved dependencies and potential cycles.

Do not silently simplify sequential or stateful calculations into independent formulas.

## 5. Input Sufficiency Assessment

Compare the required input fields and runtime values against the available AALC2201 run inputs.

Identify missing:

- Setup fields.
- Periodic fields.
- Transaction data.
- Payment inputs.
- Critical dates.
- Index values.
- Prior-period values.
- Runtime-computed intermediate states.

Distinguish actual missing inputs from fields whose semantics are still unknown.

Do not use independently exported ASAP SQL benchmark outputs as substitute inputs.

## 6. Calculation Readiness

Classify every identified calculated output field using the existing project model:

A — Semantics and Excel translation understood; inputs available.

B — As above, requiring a documented runtime mapping.

C — Semantics understood, but required data missing.

D — Unresolved runtime semantics or uncertain Excel equivalence.

Apply D > C > B > A.

Do not automatically classify a field as A or B merely because a matching ASAP API was found in the Knowledge Base.

For every classification, provide the supporting evidence and remaining gaps.

## 7. Deliverables

Generate private, local-only reports:

- `runtime_dependency_inventory.csv`
- `runtime_contracts.json`
- `field_lineage.csv`
- `calculation_dependency_graph.json`
- `required_inputs.json`
- `missing_inputs.csv`
- `semantic_gaps.md`
- `calculation_coverage.csv`
- `phase1_assessment.md`

Store real deal-specific reports under the existing ignored directory:

`runs/AALC2201/2026-10/reports/`

Do not commit confidential source-derived reports to Git.

Use synthetic fixtures for automated tests.

## 8. Verification

Verify:

- Coverage of all available source files.
- Coverage of calculated output assignments.
- Preservation of source line references.
- Accurate linking to Knowledge Base sources.
- Explicit handling of unresolved runtime semantics.
- Correct separation of semantic, data, and Excel translation gaps.

Run relevant existing tests.

Do not claim runtime validation unless actual tests have been executed in an authorized ASAP environment.

## 9. Execution Boundaries

Do not:

- Modify original ASAP scripts.
- Rebuild the entire Knowledge Base.
- Generate Excel formulas.
- Create output workbooks.
- Execute production SQL queries.
- Invent missing API semantics.
- Commit or push confidential artifacts.
- Proceed to Phase 2 automatically.

Complete Phase 1 only.

If the actual AALC2201 source scripts or required local inputs are unavailable, identify the missing files and stop rather than fabricating an analysis.

At completion, report:

1. Number of source files analyzed.
2. Number of calculated output fields discovered.
3. Number of resolved and unresolved runtime symbols.
4. Number of semantic, data, and translation gaps.
5. A/B/C/D field distribution.
6. Main calculation dependencies.
7. Evidence quality and knowledge coverage.
8. Readiness for Excel Formula Generation.

Respond in Chinese, retaining technical English terms.
