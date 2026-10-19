# AALC Excel Calculation Replica — Build Local ASAP Knowledge Base

You are working inside the existing `asap-calc-replica` repository.

## Objective

Build a self-contained, project-specific ASAP Knowledge Base directly from the raw Markdown documents stored in this repository.

Do NOT depend on or reference the separate `ASAP-Agent` repository.

The purpose is to support reliable, specification-grounded development of native Excel calculation formulas that reproduce the observable behavior of ASAP calculation scripts.

## 1. Knowledge Sources

The following directories contain raw Markdown converted from original ASAP documentation:

- `knowledge/asap/raw/user_manual/`
- `knowledge/asap/raw/scripting_manual/`
- `knowledge/asap/raw/releases/`
- `knowledge/asap/raw/sql_server/`

These are the only documentation sources to ingest during this task.

They are raw source documents, NOT curated canonical specifications.

Preserve all original Markdown files unchanged.

Do not run OCR, retrieve external documentation, or attempt to synchronize with ASAP-Agent.

## 2. Initial Repository Audit

Inspect the existing AALC project before implementing anything.

Review:

- `AGENTS.md`
- `docs/architecture.md`
- `docs/knowledge_base_integration.md`
- `docs/calculation_coverage.md`
- `docs/runtime_dependency_inventory.md`
- `src/asap_calc_replica/runtime/`
- `src/asap_calc_replica/analysis/`
- `knowledge/`
- `deals/`
- `runs/`

Inventory all Markdown files under the four raw directories.

Report document counts, sizes, headings, tables, code blocks, and any unreadable or incomplete files.

Reuse existing modules and contracts whenever possible.

## 3. Knowledge Processing

Build a complete, persistent local Knowledge Base from these Markdown sources.

Implement:

### A. Source Registry

For each document, record:

- Unique source ID
- Knowledge domain
- Relative file path
- File hash (SHA-256)
- Document title
- Section headings
- Document version when explicitly available
- Processing status

### B. Structured Extraction

Extract documented information into appropriate records.

Scripting Manual:
- Objects
- Fields
- Functions and methods
- Signatures
- Parameters
- Data types
- Read/write restrictions
- Runtime behaviors
- Script contexts

User Manual:
- System functionality
- Workflows
- Configuration behavior
- Business rules

Releases:
- Release identifiers
- Version changes
- API additions
- Deprecated functionality
- Behavioral changes

SQL Server:
- Database and schema names
- Table names
- View names
- Column names
- Original column order when available

Never invent missing definitions, types, parameters, or SQL relationships.

### C. Knowledge Index

Implement:

- Exact symbol lookup
- SQLite FTS5 full-text retrieval
- Source and section references
- Document-domain filtering
- Version metadata filtering when supported
- Incremental reindexing

Use semantic document sections as retrieval units.

Do not split API signatures, code blocks, or tables into incomplete fragments.

Retain exact original Markdown as the source of truth.

## 4. AALC-Specific Knowledge Layer

Create AALC-specific structured knowledge separately from the raw ASAP documentation.

Focus on:

- ASAP Runtime Contracts
- Calculation Dependencies
- Field Lineage
- Execution Sequence
- Collection Semantics
- Period and Historical State
- SQL-to-ASAP Field Mappings
- Excel Translation Requirements

Every derived claim must cite its original Markdown source and relevant section.

Distinguish documented behavior from inference or runtime observations.

Do not assume that matching ASAP and SQL field names prove equivalent semantics.

## 5. Existing Calculation Architecture

Preserve the existing AALC multi-deal architecture.

Continue using the established calculation readiness categories:

A — Semantics understood, inputs available, Excel equivalence understood.

B — As above, but requires documented ASAP-to-Excel/SQL runtime mapping.

C — Semantics understood, required inputs missing.

D — Runtime semantics, side effects, or Excel equivalence unresolved.

Precedence: D > C > B > A.

ASAP IronPython scripts must not be assumed executable in standalone Python.

Do not build a full ASAP runtime emulator.

Do not use SQL benchmark outputs as missing formula inputs.

## 6. Codex Integration

Update the existing AGENTS.md to require Knowledge Base retrieval before ASAP-specific implementation.

Create or update a dedicated AALC Knowledge Lookup Skill.

Codex should:

1. Identify the relevant ASAP symbols and calculation dependencies.
2. Retrieve the corresponding local Markdown specifications.
3. Inspect relevant Release documentation.
4. Check SQL metadata where applicable.
5. Establish evidence-backed runtime contracts.
6. Report unresolved behaviors.
7. Only propose Excel translation when semantic requirements are sufficiently supported.

Never rely solely on conversational memory.

## 7. Development Tools

Implement reproducible Windows-compatible commands for:

- Building the Knowledge Base
- Rebuilding indexes incrementally
- Querying an ASAP object or function
- Searching the SQL schema
- Retrieving relevant Release changes
- Validating source coverage
- Reporting unresolved symbols

Prefer Python and SQLite already compatible with the existing project.

Use local paths only.

## 8. Security

The GitHub repository may be public.

Treat all raw Markdown, extracted internal knowledge, SQL metadata, and real deal information as confidential unless explicitly authorized.

Ensure all of these remain excluded from Git.

Before modifications, inspect .gitignore and existing tracked files.

Do not commit or push internal documentation, extracted knowledge, indexes, or reports.

Do not push any changes without my approval.

Do not send data to additional external services.

## 9. Required Tests

Implement synthetic tests for:

- Markdown ingestion
- Exact symbol retrieval
- Markdown table preservation
- Full-text search
- Source provenance
- Duplicate document detection
- Incremental indexing
- SQL table/view/column lookup
- Unknown API handling
- Release version filtering

Use only synthetic data in tracked test fixtures.

## 10. Deliverables

Establish a working local Knowledge Base within the existing AALC repository.

Provide:

- Complete source inventory
- Knowledge ingestion pipeline
- Structured symbol catalog
- SQLite search index
- Local query commands
- Codex Skill integration
- Source coverage and unresolved-item reports
- Test results
- Updated architecture documentation

Do not generate Excel formulas yet.

Do not modify calculation algorithms, Deal configurations, or run data.

Start by auditing the four raw Markdown directories.

If all sources are accessible, proceed with implementation.

At completion, demonstrate at least one documented ASAP API lookup, one SQL schema lookup, and one Release search using actual retrieved sources.

Report results in Chinese with English technical terminology.
