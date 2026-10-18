# Task: Fix Python 3.14.4 Interpreter Configuration and Finalize VS Code Workspace Environment

## 0. Execution Priority

Act as a Senior VS Code Configuration Engineer, Python Environment Specialist, and Developer Workspace Architect.

This task has TWO major objectives, which must be performed in order:

**Priority 1 — Diagnose and repair my existing Python 3.14.4 interpreter configuration failure.**

**Priority 2 — Finalize and verify the previously implemented nine-Workspace architecture, ensuring all Workspaces use my existing VS Code development environment consistently.**

Do not restart completed work unnecessarily.

My Workspace reorganization has already been implemented, and the previous validation reported:

- 9 Workspace descriptors exist.
- 29 unique project roots are assigned.
- No duplicate assignments.
- No missing directories.
- `38-Master` is synchronized.
- No project source code or Git repositories were modified.

Preserve these results.

---

# PART I — PYTHON 3.14.4 INTERPRETER REPAIR

## 1. Current Problem

In my existing VS Code environment, I attempted to switch the Python interpreter to Python 3.14.4 using:

`Python: Select Interpreter`

VS Code recognizes the available Python 3.14.4 installation, but selecting it fails.

The displayed error is:

`Failed to set interpreter path. Error: Unable to write into user settings.`

The interpreter selection interface currently shows:

- A previously selected CitiSoftware Python 3.12 interpreter.
- A recommended CitiSoftware Python 3.14.4 interpreter.
- A global CitiSoftware Python 3.14.4 interpreter.
- A separate Anaconda base Python 3.7.3 environment.

The expected Python 3.14.4 installation appears under a path similar to:

`%LOCALAPPDATA%\CitiSoftware\CTC7013_PYTHON_3.14.4\python.exe`

Discover and verify the exact physical path rather than assuming it.

**My desired default Python version is 3.14.4, using the existing CitiSoftware installation.**

Do not install a new Python interpreter or replace the CitiSoftware distribution.

## 2. Diagnose the Root Cause First

Before changing any configuration, investigate why VS Code cannot write the selected interpreter setting.

Inspect the relevant configuration and environment:

1. Current VS Code executable and environment.
2. Active VS Code Profile.
3. Effective User Settings location.
4. Current Workspace Settings.
5. Existing Python extension settings.
6. `python.defaultInterpreterPath`.
7. Python interpreter selection state.
8. Current Python extension output and relevant error logs.
9. Whether User Settings or their parent directory are read-only.
10. Relevant Windows file permissions and ownership.
11. JSON/JSONC syntax validity of the settings file.
12. Conflicting settings or stale Python interpreter references.
13. Whether VS Code is using a custom user-data directory or managed corporate configuration.
14. Whether enterprise policy or administrative restrictions prevent writing to User Settings.

Also examine the complete error details, not just the truncated VS Code notification.

Distinguish a VS Code settings write failure from a Python executable or interpreter initialization failure.

Do not assume the Python 3.14.4 installation is corrupt merely because selecting it fails.

## 3. Verify the Existing Python 3.14.4 Installation

Locate the existing CitiSoftware Python 3.14.4 executable.

Verify:

- The executable exists.
- It can be launched.
- It reports Python 3.14.4.
- A basic interpreter command executes successfully.
- The interpreter can enter an interactive REPL.

Use only minimal, non-destructive commands.

For example, after resolving the actual path:

```powershell
& "<verified-python-3.14.4-path>" --version
```

Do not run project scripts.

Do not install packages.

Do not modify the Python installation.

Do not confuse the Anaconda Python 3.7.3 environment with the intended Python 3.14.4 installation.

## 4. Repair Strategy

Apply the least intrusive supported correction.

### Preferred Solution — Repair Existing User/Profile Configuration

If the problem is caused by a safely correctable configuration issue:

1. Identify the exact faulty setting or configuration.
2. Preserve the existing settings.
3. Back up any settings file before modifying it.
4. Correct the specific configuration problem.
5. Restore the ability to select Python interpreters normally.
6. Configure the existing CitiSoftware Python 3.14.4 as the desired default interpreter.
7. Preserve all unrelated Python, Copilot, extension, and editor settings.

Do not overwrite the entire settings file.

Do not reset my VS Code Profile.

Do not modify permissions broadly or weaken corporate security controls.

If the settings file is enterprise-managed, do not bypass management restrictions.

### Fallback Solution — Workspace-Level Interpreter Configuration

If User Settings cannot safely be modified, configure Python 3.14.4 at the Workspace level using supported VS Code and Python extension mechanisms.

Use the verified absolute Python 3.14.4 executable path.

Apply the correct default interpreter configuration to all nine Workspaces where appropriate.

Preserve existing project-specific interpreter settings and do not overwrite an intentionally different environment without identifying the conflict.

Be aware that `python.defaultInterpreterPath` may not override an interpreter already stored in Python extension Workspace state.

If necessary, use the supported Python extension commands to update or clear stale Workspace interpreter selection.

Do not directly manipulate undocumented extension storage or VS Code internal databases.

If manual VS Code UI selection is necessary, provide exact instructions.

### Important

Do not claim the problem is fixed merely because `python.defaultInterpreterPath` was written successfully.

The intended interpreter must actually be selectable and usable.

If the actual User Settings write failure remains unresolved, explicitly report it even if a Workspace-level workaround succeeds.

## 5. Python Interactive Window, REPL, and Kernel

My VS Code environment uses Python interactively.

Distinguish these three mechanisms:

1. Python interpreter selected by the Python extension.
2. Terminal-based Python REPL.
3. Python Interactive Window / Jupyter kernel selection.

Ensure that the terminal-based Python REPL uses Python 3.14.4.

Where an existing compatible kernel is available, allow the Python Interactive Window to use Python 3.14.4 as well.

Do not assume that selecting an interpreter automatically changes an already running Interactive Window kernel.

Do not install Jupyter, ipykernel, or any additional packages without my explicit approval.

If the Interactive Window needs additional packages that are not installed, report that separately without blocking the main interpreter repair.

## 6. Python Repair Acceptance Criteria

The Python repair is successful when:

1. The actual CitiSoftware Python 3.14.4 executable is identified.
2. The interpreter launches successfully.
3. Its reported version is Python 3.14.4.
4. VS Code can use it through a supported configuration mechanism.
5. A new integrated terminal Python REPL launches using Python 3.14.4.
6. The interpreter configuration persists appropriately when reopening the Workspace.
7. Existing Python installations and environments are preserved.
8. Other VS Code settings remain unchanged.
9. Any unresolved User Settings write restriction is explicitly documented.

**Complete this diagnosis and repair before proceeding to the Workspace environment review.**

---

# PART II — EXISTING WORKSPACE ARCHITECTURE

## 7. Mandatory Directory

All Workspace descriptors must be located at:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces`

The established structure is:

```text
38 Workspaces/
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

These files should already exist.

Inspect and preserve them.

Do not recreate or overwrite valid existing descriptors unnecessarily.

Do not create another Workspace directory.

## 8. Approved Project Membership

Preserve the following project assignments.

### ASAP2-Standards — 9 Projects

- py-shared-functions
- cutoff-gf
- stop-advance
- payrule-editor
- payrule-testing
- periodic-func-repo
- batch-fix
- strat-editor
- remit-editor

### ASAP2-Deals — 5 Projects

- waterfall-harness
- barc-maker
- jpmm-training
- cars-migration
- sample-deals

### ASAP2-AALC-Checker — 1 Project

- aalc-checker

### ASAP2-Platform-Automation — 2 Projects

- dev-deals-import
- asap2-live-tools

### ASAP2-Validation-Engineering — 2 Projects

- validation-prompts
- validation-platform

### Data-ETL — 3 Projects

- bny-download
- cmbs-data-room
- oracle-loader

### Office-Reporting-Automation — 3 Projects

- vba-shared-functions
- deal-dashboard
- fees-invoice

### Developer-Tools — 4 Projects

- repo-code-images
- sql-schema-ai-exporter
- import-sync
- setup-sandbox

These names are Workspace folder aliases.

Preserve the already resolved actual physical paths.

Do not rename source folders to match aliases.

All 29 projects should appear exactly once across the eight specialized Workspaces.

All 29 should also appear in `38-Master`.

---

# PART III — COMMON VS CODE ENVIRONMENT

## 9. Fundamental Requirement

**All nine Workspaces must provide the same general development environment as my current VS Code environment.**

The currently active VS Code Profile and its existing preferences are the reference.

Preserve and consistently apply:

- Keyboard shortcuts.
- Installed extensions.
- Extension configuration.
- GitHub Copilot settings.
- Python extension settings.
- Editor preferences.
- Terminal configuration.
- UI appearance.
- Git integration.
- Language-specific settings.
- Existing development conveniences.

However, do not blindly copy every setting into every `.code-workspace` file.

Use the appropriate VS Code configuration scope.

## 10. VS Code Profile

Identify the currently active VS Code Profile.

All nine Workspaces should use the same existing Profile where supported.

Do not create nine separate Profiles.

Do not reset or replace the current Profile.

If Workspace-to-Profile association requires a supported VS Code UI action, provide exact instructions rather than modifying undocumented internal VS Code state.

The shared Profile should provide common:

- Extensions.
- Personal settings.
- Keyboard shortcuts.
- Theme.
- Editor behavior.
- Copilot preferences.
- Terminal preferences.

## 11. Settings Scope and Precedence

Follow this configuration hierarchy:

| Configuration | Preferred Scope |
|---|---|
| Keyboard shortcuts | User / Profile |
| Installed extensions | User / Profile |
| General extension settings | User / Profile |
| Theme, fonts, editor preferences | User / Profile |
| General Copilot preferences | User / Profile |
| Python 3.14.4 default | User / Profile if safely writable; otherwise supported Workspace configuration |
| Workspace project membership | Individual .code-workspace |
| Terminal startup tasks | Individual .code-workspace |
| Master synchronization task | 38-Master |
| Project-specific settings | Existing relevant folder or Workspace |

Preserve the effective settings precedence.

Do not migrate settings to another scope without considering their impact.

Do not make unrelated global setting changes.

## 12. Keyboard Shortcuts

Preserve all existing keyboard shortcuts, including custom and extension-contributed shortcuts.

Do not attempt to insert unsupported keyboard shortcut definitions into `.code-workspace` files.

The goal is that switching between the nine Workspaces does not change my normal keyboard shortcuts.

## 13. Extensions

All nine Workspaces should have access to my existing installed extensions.

Preserve the current configuration of:

- GitHub Copilot.
- GitHub Copilot Chat.
- Python.
- Python Debugger.
- Pylance.
- SQL extensions.
- Git extensions.
- Other existing installed extensions.

Do not install, remove, disable, enable, or update extensions unless separately authorized.

Do not confuse Workspace extension recommendations with installed extensions.

Preserve existing extension settings and their appropriate scope.

## 14. GitHub Copilot

Preserve the current effective GitHub Copilot environment.

This includes, where configured and supported:

- Copilot Chat preferences.
- Agent Mode settings.
- Available model preferences.
- Agent instructions.
- Custom instructions and prompt references.
- Tool permissions.
- Confirmation requirements.
- Code search and context behavior.
- Terminal integration.

Do not copy project-specific instructions into unrelated Workspaces.

Do not broaden access to sensitive or proprietary materials.

The specialized Workspaces should provide focused project context.

`38-Master` should remain available for cross-project analysis and global searching.

Do not reset Copilot's existing settings.

## 15. Editor and UI Preferences

Preserve existing:

- Font family and size.
- Theme and icon theme.
- Auto-save preferences.
- Format-on-save behavior.
- Default formatters.
- File associations.
- Tab size and indentation.
- Word wrap.
- Explorer preferences.
- Search preferences.
- Terminal appearance.
- Git integration preferences.
- Language-specific settings.

Prefer shared User/Profile configuration over duplicating identical settings into nine descriptors.

Retain intentional Workspace-specific exceptions.

---

# PART IV — AUTOMATIC TERMINAL INITIALIZATION

## 16. Required Behavior

Whenever any of the nine Workspaces opens in VS Code, I want two independent integrated terminal sessions to become available.

### Terminal A — Python REPL

Name:

`Python REPL`

Requirements:

1. Use the existing CitiSoftware Python 3.14.4 interpreter after successful configuration.
2. Launch an interactive Python terminal.
3. Display the standard `>>>` prompt.
4. Remain available for manual Python commands.
5. Do not automatically execute project scripts.
6. Do not install packages.
7. Do not create virtual environments.
8. Do not use Python 3.7 or 3.12 accidentally because of PATH precedence.

Prefer an explicit verified Python 3.14.4 executable path when necessary for deterministic startup.

### Terminal B — PowerShell

Name:

`PowerShell`

Requirements:

1. Launch a separate interactive PowerShell terminal.
2. Use my existing PowerShell installation and configuration.
3. Remain open for manual commands.
4. Do not execute project-specific initialization scripts.
5. Do not change system environment variables or execution policy.

## 17. Automatic Startup Configuration

Use supported VS Code Workspace Tasks.

Where appropriate, configure:

```json
"runOptions": {
  "runOn": "folderOpen"
}
```

Requirements:

- Startup behavior must be available in all nine Workspaces.
- Python REPL and PowerShell must occupy separate terminal sessions.
- Do not overwrite or reuse the same terminal session for both.
- Preserve the VS Code editor focus where practical.
- Preserve existing terminal settings.
- Preserve existing Workspace tasks.
- Do not create files inside project source repositories.
- Avoid duplicate startup terminals where feasible.
- Account for VS Code terminal session restoration.
- Do not run application scripts.
- Do not launch Master synchronization automatically.

If interactive PowerShell or Python requires a particular task configuration to remain open, use an appropriate supported shell-task implementation.

Do not falsely report a running REPL if a task merely executed a command and exited.

If automatic startup requires Workspace Trust or automatic-task approval, explain the user action required.

Do not bypass security protections.

## 18. Terminal Startup Verification

Verify configuration separately from actual runtime behavior.

Where practical, confirm:

- Python REPL launches with Python 3.14.4.
- Python displays `>>>`.
- PowerShell launches separately.
- Neither terminal immediately exits.
- Existing manual terminals remain unaffected.
- Reopening the Workspace does not produce unnecessary duplicate sessions.

If actual UI startup cannot be observed, report it as configured but not yet visually verified.

---

# PART V — MASTER WORKSPACE SYNCHRONIZATION

## 19. Existing Synchronization Utility

The following utility should already exist:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py`

Preserve its existing implementation if it is functioning correctly.

The eight specialized Workspace descriptors are authoritative for project membership.

`38-Master` is the aggregate view.

## 20. Synchronization Requirements

The script must:

1. Read the `folders` arrays from all eight specialized descriptors.
2. Resolve referenced paths.
3. Normalize Windows paths.
4. Detect duplicate specialized Workspace assignments.
5. Verify project directories exist.
6. Aggregate all unique projects into `38-Master`.
7. Preserve folder aliases where possible.
8. Preserve Master settings, tasks, and extensions.
9. Preserve Python REPL and PowerShell startup tasks.
10. Preserve the manual synchronization task.
11. Support new, removed, and reassigned projects.
12. Avoid unnecessary file rewrites.
13. Produce deterministic output.
14. Prevent incomplete updates.
15. Never modify source repositories or specialized Workspace membership automatically.

Use Python standard library only.

## 21. Synchronization Commands

Normal synchronization:

```powershell
python "H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py"
```

Read-only check:

```powershell
python "H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py" --check
```

Once Python 3.14.4 has been verified, the utility may be invoked with its verified executable path when needed.

Do not change the script solely to require Python 3.14.4 unless there is a justified compatibility requirement.

The `--check` command must not modify files.

## 22. VS Code Sync Task

Preserve the existing task:

`Sync Master Workspace`

It should remain accessible from:

`Terminal → Run Task → Sync Master Workspace`

This task must be manually triggered.

Do not automatically invoke it whenever a Workspace opens.

---

# PART VI — IMPLEMENTATION SAFETY

## 23. Allowed Operations

You may:

- Inspect existing VS Code configuration.
- Inspect Python interpreter settings and logs.
- Verify installed Python executables.
- Safely repair relevant settings when permitted.
- Back up configuration files before changing them.
- Correct stale interpreter references.
- Apply supported Workspace-level interpreter settings.
- Update existing `.code-workspace` descriptors.
- Configure terminal startup tasks.
- Preserve and verify Master synchronization.
- Validate Workspace JSON and referenced paths.
- Run minimal Python version and REPL checks.
- Run synchronization and check commands.
- Verify configuration consistency.

## 24. Prohibited Operations

Do NOT:

- Move source project directories.
- Copy or duplicate source projects.
- Modify project business logic.
- Refactor Python, SQL, VBA, or IronPython source code.
- Merge or migrate Git repositories.
- Modify Git branches or remotes.
- Install or uninstall Python.
- Install Python packages.
- Create virtual environments.
- Modify CitiSoftware Python installation files.
- Reset my VS Code Profile.
- Reset keyboard shortcuts.
- Reset Copilot settings.
- Broadly change Windows permissions.
- Bypass corporate security policies.
- Change PowerShell execution policy.
- Modify system PATH.
- Perform application runtime tests.
- Execute ASAP2 business workflows.
- Test SQL Server or Oracle connections.
- Rebuild the already completed Workspace architecture unnecessarily.

Do not change files inside original source project directories.

---

# PART VII — EXECUTION SEQUENCE

## 25. Step 1 — Diagnose Python Failure

Start by reproducing or inspecting the complete Python interpreter selection error.

Determine why VS Code cannot write the selected interpreter path.

Inspect the settings scope and write restrictions.

Identify the root cause before making changes.

## 26. Step 2 — Fix Python 3.14.4

Verify the actual executable.

Apply the safest supported repair.

Prefer preserving the existing Profile and settings.

Use Workspace-level configuration if User Settings cannot be safely repaired.

Verify Python 3.14.4 can launch.

Report any unresolved settings restrictions.

## 27. Step 3 — Inspect Existing Nine Workspaces

Check the nine existing Workspace descriptors in the mandatory directory.

Confirm their project membership and paths.

Do not regenerate correct files.

Verify that Master synchronization remains intact.

## 28. Step 4 — Preserve Environment Consistency

Review Profile, keyboard shortcut, extension, Copilot, editor, Python, and terminal configuration.

Ensure the nine Workspaces use the same general development environment.

Apply only necessary changes.

Do not duplicate shared settings unnecessarily.

## 29. Step 5 — Configure Automatic Terminals

Ensure all nine Workspaces define the appropriate startup behavior.

The Python REPL must target the verified Python 3.14.4 interpreter.

PowerShell must remain a separate interactive terminal.

Preserve Master synchronization tasks.

## 30. Step 6 — Verify Workspace Synchronization

Run the existing synchronization check.

If necessary, synchronize Master.

Verify all 29 project roots remain correctly referenced.

Verify repeated synchronization does not unnecessarily rewrite the Master.

## 31. Step 7 — Final Report

Provide a concise report covering:

### A. Python 3.14.4 Repair

- Root cause of interpreter selection failure.
- Actual Python executable path.
- Verified Python version.
- Configuration changes made.
- Whether VS Code interpreter selection now works.
- Whether any User Settings write restriction remains.

### B. VS Code Environment

- Active Profile.
- Shared settings scope.
- Keyboard shortcut consistency.
- Extension consistency.
- Copilot configuration preservation.

### C. Workspace Status

- Nine Workspace descriptors.
- 29 unique project roots.
- Missing directories.
- Duplicate assignments.
- Master synchronization status.

### D. Terminal Startup

- Python REPL configuration.
- PowerShell configuration.
- Whether actual startup was verified.
- Any remaining Workspace Trust or automatic-task permissions.

### E. Files Changed

List the exact configuration files created or modified.

Do not include unrelated source files.

### F. Remaining Manual Actions

Provide only the essential VS Code UI actions still required.

---

# PART VIII — ACCEPTANCE CRITERIA

The task is complete when:

1. The existing Python 3.14.4 executable is verified.
2. Python 3.14.4 can be used through a supported VS Code configuration mechanism.
3. The Python interpreter write failure is repaired or its remaining restriction is clearly identified with a working Workspace-level alternative.
4. Existing Python environments are preserved.
5. The nine existing Workspace descriptors remain intact.
6. The eight specialized Workspaces collectively reference 29 unique projects.
7. `38-Master` references all 29 projects.
8. Master synchronization remains functional.
9. All nine Workspaces consistently use the existing VS Code Profile where supported.
10. Keyboard shortcuts, extensions, Copilot, and shared editor preferences remain intact.
11. Each Workspace has Python REPL and PowerShell startup configuration.
12. Python REPL uses Python 3.14.4.
13. No project source code, physical project directories, or Git repositories are changed.
14. Configuration changes and any unverified UI behavior are accurately reported.

Do not require unrelated runtime or business application tests.

---

# FINAL INSTRUCTION

**First fix the Python 3.14.4 interpreter selection problem in my existing VS Code environment.**

After the Python repair, finalize the nine existing Workspaces without rebuilding completed work.

Preserve my current VS Code Profile, keyboard shortcuts, extensions, GitHub Copilot settings, and editor preferences.

Ensure all nine Workspaces provide the same general development experience, including automatic Python 3.14.4 REPL and PowerShell startup.

Preserve the existing Master synchronization architecture.

Proceed with supported, low-risk configuration repairs and updates.

Only stop for clarification when a change would risk losing existing settings, require bypassing enterprise restrictions, or overwrite an intentionally different interpreter configuration.

Do not perform unrelated changes.
