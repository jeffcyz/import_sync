# Role
Act as a Senior Software Architect and VS Code Workspace Organization Consultant.

I currently have a large VS Code multi-root workspace named `TOTAL`, containing numerous Python, SQL, ASAP 2.0 (IronPython), automation, validation, deal-specific scripting, and developer-tool projects.

Over time, unrelated projects, experimental code, shared functions, and different versions of similar tools have accumulated in this single workspace.

**My goal is to reorganize these projects into smaller, logically cohesive VS Code Workspaces, without unnecessarily merging independent Git repositories.**

## Phase 1 — Project Discovery

Inspect ALL accessible project roots in the current VS Code Workspace.

For each project, examine relevant evidence such as:

- Folder structure and filenames
- README and project documentation
- Main scripts, modules, classes, and functions
- Imports and dependencies
- Configuration files and test structure
- Git repository boundaries, where accessible
- Similarities with other projects
- Business purpose and intended workflow

Use an efficient inspection strategy: start with metadata and directory structures, then inspect representative source files as needed. Exclude generated files, binary outputs, virtual environments, and large datasets.

Do not read or reproduce credentials, connection strings, sensitive records, or confidential business data unnecessarily.

Create a Project Inventory that includes:

| Current Project | Primary Purpose | Functional Category | Related Projects | Git Status | Confidence |

Do not infer project functionality solely from its folder name. Mark ambiguous classifications as requiring further inspection.

## Phase 2 — Relationship and Dependency Analysis

Analyze the relationships between projects and identify:

1. Projects supporting the same business workflow.
2. Projects sharing common libraries, functions, or data structures.
3. Projects with overlapping or duplicated functionality.
4. Older versions or experimental derivatives of active projects.
5. Standalone utilities that should remain independently maintained.
6. Projects that should share a development workspace but not necessarily a Git repository.
7. Projects that should remain isolated due to differences in runtime, dependencies, confidentiality, or development lifecycle.

Pay special attention to ASAP validation, general functions (GF), deal scripting, PayRule, reporting, data pipelines, SQL utilities, developer automation, and AI-assisted development.

Distinguish confirmed relationships from plausible but unverified ones.

## Phase 3 — Workspace Architecture Proposal

Propose a practical, scalable grouping of the current projects into a smaller number of purpose-driven VS Code Workspaces.

**Do not assume a fixed number of Workspaces.** Determine the most suitable structure based on the actual findings.

Optimize for:

- High functional cohesion within each Workspace
- Low coupling between Workspaces
- Clear business and technical ownership
- Focused GitHub Copilot / Codex context
- Independent Git repository management
- Shared-code reuse without unnecessary duplication
- Ease of navigation and long-term maintainability
- Minimal disruption to currently working projects

Clearly differentiate:

- VS Code Workspace boundaries
- Git Repository boundaries
- Shared libraries and modules
- Deal-specific configurations
- Temporary experiments and archived projects

Do not recommend merging repositories merely because they belong to the same Workspace.

## Phase 4 — Proposed Organization

Provide the following deliverables:

### A. Recommended Workspace Groups
For each proposed Workspace, explain its scope, purpose, included projects, and why they belong together.

### B. Complete Project-to-Workspace Mapping
Map EVERY existing project root to a proposed Workspace, including ambiguous, duplicate, experimental, and archival candidates. No project should be omitted.

### C. Recommended Folder and Repository Structure
Provide a proposed directory tree, preserving existing Git repository identities wherever appropriate.

### D. Cross-Project Dependencies
Identify shared functions, reusable components, overlapping tools, and opportunities for consolidation. Separate confirmed duplication from suspected duplication.

### E. Migration Plan
Provide a staged, low-risk migration strategy, prioritizing changes that improve organization without modifying source code.

### F. Proposed VS Code Workspace Files
Show example `.code-workspace` configurations referencing the existing physical paths, so I can implement the grouping before physically moving any directories.

### G. Risks and Open Questions
Flag uncertain project classifications, Git risks, external dependencies, and items requiring my decision.

## Constraints

- **READ-ONLY ANALYSIS ONLY.**
- Do NOT move, rename, delete, or create project files.
- Do NOT modify Git repositories, branches, remotes, or histories.
- Do NOT install dependencies or execute project code.
- Do NOT implement any changes in this phase.
- Do NOT assume projects with similar names have identical functionality.
- Do NOT force unrelated projects into the same repository.
- If a project is inaccessible, explicitly identify the limitation.
- Do not expose proprietary code or confidential data in the analysis.

## Expected Output

Produce a detailed architecture assessment and an actionable reorganization plan.

Start with an executive summary and proposed Workspace grouping, followed by the complete project mapping and migration recommendations.

Conclude with your recommended architecture and the key decisions requiring my approval.

**Stop after presenting the plan. Wait for my explicit approval before making any changes.**
