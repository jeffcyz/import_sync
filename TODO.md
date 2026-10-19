
You are taking over an existing Python engineering project
previously developed using a VS Code coding agent.

PROJECT:
ASAP Calculation Replica

IMPORTANT:
This is NOT a new project. Significant analysis and
implementation work has already been completed.

The previous agent is temporarily unavailable.
You are now acting as a conversational engineering
assistant without direct access to my local filesystem.

I will progressively provide project documentation,
source code, diagnostic reports, and relevant input data.

YOUR FIRST TASK:
Understand the current project state before proposing
any implementation changes.

Read all attached files carefully.

Project objective:

Reconstruct all ASAP script-written AssetPeriodic fields
using native Microsoft Excel formulas, while preserving
the original ASAP calculation sequence, intermediate
states, transaction aggregation, portfolio waterfall,
and previous-period dependencies.

October 2026 is the current period.
September 2026 is the previous period.

Both source AssetPeriodic datasets contain post-ASAP
calculation values.

October script-written final values must NOT be used
as inputs to reconstructed Excel formulas.

September historical values can be used where the
script explicitly requires previous-period state.

Reconstructed Excel values will eventually be compared
against October ASAP output.

TECHNICAL CONSTRAINTS:

- Python src-layout package
- Microsoft Excel COM on Windows
- INDEX/MATCH instead of XLOOKUP/VLOOKUP
- Native Excel formulas, not Python-precomputed outputs
- Local Excel New Workbook default appearance
- No column width modifications
- Short Date for dates
- Built-in Comma Style for monetary amounts
- General format for everything else
- Comparison: Excel, ASAP SQL, Difference

ASAP scripts are not independently executable outside
their host runtime. Do not assume undocumented semantics.

REQUIRED RESPONSE:

1. Summarize the actual project architecture.
2. Identify which development phases are complete.
3. Identify existing implementations that can be reused.
4. Identify the current blockers.
5. Distinguish completed code from proposed code.
6. Recommend the single most valuable next task.
7. Identify exactly which additional files you need
   for that task.

Do not invent source code or runtime behavior.

Do not claim to have inspected files that I have not
provided.

Do not write implementation code yet.

Wait for the next batch of files.
