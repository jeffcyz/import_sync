# Task: Implement VS Code Workspace Reorganization and Master Synchronization

## 1. Objective

Act as a Senior VS Code Workspace Architect.

Implement the previously analyzed Workspace Reorganization Plan for my existing `TOTAL` VS Code multi-root Workspace containing 29 project roots.

This is an **approved implementation task**, not another architecture assessment.

My objective is strictly **Workspace organization and synchronization**, NOT code migration, refactoring, or runtime validation.

The final architecture must contain:

- 8 specialized VS Code Workspaces for focused development.
- 1 permanent Master Workspace for global searching and cross-project GitHub Copilot analysis.
- 1 lightweight Python synchronization utility to automatically aggregate specialized Workspace project references into the Master Workspace.

All nine `.code-workspace` descriptor files and the synchronization utility must reside in:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces`

**This directory is mandatory. Do not create another Workspace configuration directory elsewhere.**

---

## 2. Final Directory Structure

Create the following structure:

```text
H:\Analytics\xChen\30-39 Projects\38 Workspaces\
│
├── 38-Master.code-workspace
│
├── ASAP2-Standards.code-workspace
├── ASAP2-Deals.code-workspace
├── ASAP2-AALC-Checker.code-workspace
├── ASAP2-Platform-Automation.code-workspace
├── ASAP2-Validation-Engineering.code-workspace
│
├── Data-ETL.code-workspace
├── Office-Reporting-Automation.code-workspace
├── Developer-Tools.code-workspace
│
└── sync_master_workspace.py
```

All project source directories must remain in their existing physical locations.

The `.code-workspace` files should reference those locations rather than moving or copying project contents.

Use relative paths wherever practical and valid. If a project is located on a different drive, use its existing absolute path.

---

## 3. Specialized Workspace Architecture

Implement exactly the following eight specialized Workspaces.

### Workspace 1: ASAP2-Standards

File: `ASAP2-Standards.code-workspace`

Include these 9 project roots:

1. `py-shared-functions`
2. `cutoff-gf`
3. `stop-advance`
4. `payrule-editor`
5. `payrule-testing`
6. `periodic-func-repo`
7. `batch-fix`
8. `strat-editor`
9. `remit-editor`

### Workspace 2: ASAP2-Deals

File: `ASAP2-Deals.code-workspace`

Include these 5 project roots:

1. `waterfall-harness`
2. `barc-maker`
3. `jpmm-training`
4. `cars-migration`
5. `sample-deals`

### Workspace 3: ASAP2-AALC-Checker

File: `ASAP2-AALC-Checker.code-workspace`

Include only:

1. `aalc-checker`

This project must remain independent from `ASAP2-Deals`.

### Workspace 4: ASAP2-Platform-Automation

File: `ASAP2-Platform-Automation.code-workspace`

Include these 2 project roots:

1. `dev-deals-import`
2. `asap2-live-tools`

### Workspace 5: ASAP2-Validation-Engineering

File: `ASAP2-Validation-Engineering.code-workspace`

Include these 2 project roots:

1. `validation-prompts`
2. `validation-platform`

### Workspace 6: Data-ETL

File: `Data-ETL.code-workspace`

Include these 3 project roots:

1. `bny-download`
2. `cmbs-data-room`
3. `oracle-loader`

### Workspace 7: Office-Reporting-Automation

File: `Office-Reporting-Automation.code-workspace`

Include these 3 project roots:

1. `vba-shared-functions`
2. `deal-dashboard`
3. `fees-invoice`

### Workspace 8: Developer-Tools

File: `Developer-Tools.code-workspace`

Include these 4 project roots:

1. `repo-code-images`
2. `sql-schema-ai-exporter`
3. `import-sync`
4. `setup-sandbox`

**Important:** These names are Workspace folder aliases from the previously completed project discovery.

Resolve each alias against its actual existing physical project path.

Do not assume that aliases match physical directory names.

The eight specialized Workspaces must collectively contain exactly 29 existing project roots, each assigned to exactly one specialized Workspace.

---

## 4. Master Workspace

Rename the existing:

`TOTAL.code-workspace`

to:

`38-Master.code-workspace`

Place the renamed descriptor in:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces`

Requirements:

1. Preserve all 29 original project roots.
2. Preserve all existing physical project paths.
3. Preserve useful existing Workspace settings where applicable.
4. Preserve project folder aliases wherever possible.
5. Make all 29 projects accessible through VS Code Explorer.
6. Enable global searching across all 29 project roots using VS Code Search.
7. Support cross-project GitHub Copilot analysis.
8. Do not duplicate project source directories.
9. Do not retain an unnecessary duplicate `TOTAL.code-workspace` after successful migration.

The Master Workspace must be maintained permanently.

It is not a temporary fallback.

If relocating the original descriptor changes the meaning of relative paths, correctly recalculate those paths.

Do not rename or relocate source project directories.

The Master Workspace and specialized Workspaces must reference the same underlying physical project files.

---

## 5. Automatic Master Workspace Synchronization

Create a Python script:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py`

### Purpose

The eight specialized Workspaces are the **single source of truth for project membership**.

The Master Workspace should automatically aggregate all project roots defined in those eight Workspaces.

When I add, remove, or reassign a project in a specialized Workspace, I should not need to manually edit `38-Master.code-workspace`.

### Functional Requirements

The script must:

1. Locate the eight specialized `.code-workspace` files in the same directory as the script.

2. Read the `folders` array from each specialized Workspace descriptor.

3. Resolve every folder reference to its actual physical directory.

4. Normalize paths to identify duplicate references reliably on Windows.

5. Collect all unique project roots.

6. Detect if the same physical project root is assigned to more than one specialized Workspace.

7. Report cross-Workspace duplicate assignments clearly instead of silently accepting them.

8. Generate or update the `folders` array in `38-Master.code-workspace`.

9. Preserve the existing Master Workspace's other configuration properties, including useful `settings`, `extensions`, and other workspace-level configuration.

10. Preserve each project's folder alias wherever possible.

11. Produce stable, deterministic ordering to avoid unnecessary file changes.

12. Validate the existence of all referenced project directories before updating the Master.

13. Support project additions, removals, and reassignment automatically.

14. Never modify the eight specialized Workspace descriptors.

15. Never modify any project source code, Git repositories, or physical project directories.

16. Do not overwrite the Master Workspace if a validation error would result in an incomplete or invalid project mapping.

17. Write updates safely using a temporary file and atomic replacement where possible.

Use only the Python standard library.

Use strict JSON for the resulting Workspace descriptors so the synchronization script can parse them without external dependencies.

If the existing `TOTAL.code-workspace` uses VS Code JSONC syntax (comments or trailing commas), safely preserve its configuration values during conversion. Do not silently discard settings or overwrite a descriptor that cannot be safely parsed.

### Command-Line Interface

Implement two modes.

**Sync Mode**

```powershell
python "H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py"
```

This should synchronize the Master Workspace with the eight specialized Workspaces.

**Check Mode**

```powershell
python "H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py" --check
```

This should:

- Check whether the Master Workspace matches the specialized Workspaces.
- Identify missing projects.
- Identify outdated project references.
- Identify duplicate assignments.
- Report whether synchronization is needed.
- Return a nonzero exit code when errors or synchronization differences exist.
- Make no file changes.

### Synchronization Output

Display a concise summary such as:

```text
Workspace Synchronization
-------------------------
Specialized Workspaces: 8
Total Project Roots: 29
Unique Project Roots: 29
Duplicate Assignments: 0
Missing Directories: 0
Master Workspace: 38-Master

Status: IN SYNC
```

When new projects are added, report which project references were added to the Master Workspace.

---

## 6. Convenient VS Code Synchronization

In addition to the Python script, provide a convenient way to trigger synchronization from within VS Code.

Preferred solution:

Create a VS Code Workspace Task named:

`Sync Master Workspace`

Configure it to invoke `sync_master_workspace.py`.

Prefer storing this task in `38-Master.code-workspace` using workspace-level tasks configuration, rather than adding files inside source project repositories.

The task should be accessible through:

`Terminal → Run Task → Sync Master Workspace`

Do not introduce file watchers, background services, scheduled jobs, or unnecessary dependencies.

It is sufficient that I can synchronize the Master using one VS Code task or one terminal command.

The script must remain usable independently of VS Code.

---

## 7. Scope Restrictions

### Allowed Operations

You may:

- Create the eight specialized `.code-workspace` files.
- Rename and relocate the existing `TOTAL.code-workspace` descriptor to `38-Master.code-workspace`.
- Create `sync_master_workspace.py`.
- Add the Workspace synchronization task.
- Inspect existing paths and Workspace configurations.
- Validate Workspace JSON syntax.
- Verify folder references and project counts.
- Run the Workspace synchronization script to initialize the Master.
- Run the synchronization script in check mode.

### Prohibited Operations

Do NOT:

- Move source project directories.
- Copy or duplicate project source files.
- Rename existing source project directories.
- Modify Python, SQL, IronPython, VBA, or other project source code.
- Change Git branches, remotes, histories, or repository boundaries.
- Merge or consolidate Git repositories.
- Perform source code refactoring.
- Consolidate shared libraries.
- Install Python packages.
- Configure Python environments or interpreters.
- Run unit tests or integration tests.
- Execute ASAP2 workflows.
- Test SQL Server or Oracle connections.
- Resolve historical versions of PayRules or General Functions.
- Perform unrelated architectural redesign.
- Create new project repositories.
- Modify credentials or sensitive configuration files.

Do not require any project to execute successfully inside its new Workspace.

This is a Workspace configuration task only.

---

## 8. Simplified Acceptance Criteria

The implementation is complete when all the following conditions are satisfied:

1. Exactly nine `.code-workspace` descriptor files exist in the specified directory.

2. The eight specialized Workspace descriptors match the approved project grouping.

3. All 29 original project roots appear exactly once across the eight specialized Workspaces.

4. `38-Master.code-workspace` references all 29 project roots.

5. Every referenced physical directory exists.

6. All Workspace descriptor files contain valid configurations and correct paths.

7. The Master synchronization script can aggregate the specialized Workspace configurations.

8. Running the synchronization script repeatedly without membership changes does not unnecessarily rewrite the Master.

9. The `--check` command reports that the Master is synchronized.

10. The VS Code synchronization task is available.

11. All original source code, Git repositories, and project directories remain unchanged.

12. The obsolete `TOTAL.code-workspace` descriptor has been replaced by `38-Master.code-workspace` without losing any project references.

Runtime validation is explicitly NOT required.

---

## 9. Execution Strategy

Proceed in the following order:

**Step 1 — Inspect Existing Configuration**

Locate the original `TOTAL.code-workspace` descriptor and recover its actual project paths and folder aliases.

Use the project mapping established during the previous discovery.

**Step 2 — Create Specialized Workspaces**

Create the eight specialized descriptors in the mandatory directory.

Ensure all 29 original project roots are accounted for.

**Step 3 — Create Master Workspace**

Safely relocate and rename the original `TOTAL` descriptor as `38-Master.code-workspace`, preserving its useful settings and recalculating any affected paths.

If a target descriptor already exists, inspect it and do not overwrite it blindly.

**Step 4 — Implement Synchronization**

Create `sync_master_workspace.py` with synchronization and check modes.

**Step 5 — Configure VS Code Task**

Add `Sync Master Workspace` as a convenient workspace-level task.

**Step 6 — Perform Configuration Verification**

Run the synchronization utility.

Verify project coverage, path validity, configuration syntax, and synchronization consistency.

Do not run application code or runtime tests.

**Step 7 — Report Results**

Provide a concise final report containing:

- Final Workspace directory tree.
- Project count for each Workspace.
- Total unique project count.
- Master synchronization status.
- Files created or renamed.
- Any unresolved configuration issues.
- Instructions for adding a new project and synchronizing Master.

---

## 10. Future Maintenance Rules

Going forward, apply the following maintenance model:

1. When adding a new development project, assign it to the appropriate specialized Workspace.
2. Run `Sync Master Workspace`.
3. The synchronization utility automatically adds the new project to `38-Master`.
4. When removing or reassigning a project, update its specialized Workspace membership and synchronize again.
5. Do not manually manage project membership in the Master Workspace.
6. Preserve existing project directories and independent Git repositories.

The eight specialized Workspace configurations are authoritative.

`38-Master.code-workspace` is the generated aggregate view for global searching and cross-project analysis.

---

## 11. Final Instruction

The architecture and naming conventions have already been approved.

**Proceed with implementation now.**

Do not restart planning or introduce unnecessary approval blockers.

Only stop and ask for clarification if an actual project path cannot be resolved unambiguously, an existing descriptor would be overwritten, or there is a concrete risk of losing existing Workspace configuration.

Do not perform source code migration, refactoring, or runtime testing.

Complete the Workspace organization and provide the final implementation summary.
