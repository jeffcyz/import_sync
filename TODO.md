# Task: Restore 38-Master Workspace Configuration from Existing Specialized Workspaces

## 1. Role and Objective

Act as a Senior VS Code Configuration and Python Development Environment Engineer.

I recently reorganized a large VS Code Workspace named `TOTAL` into eight specialized Workspaces and one permanent Master Workspace.

The reorganization was completed, but my `38-Master.code-workspace` appears to have lost important development environment configurations, particularly Python interpreter settings, Native Python REPL behavior, Jupyter Interactive Window settings, terminal initialization, and potentially other Workspace-specific preferences.

**Your task is to recover and restore the missing configurations in `38-Master` by inspecting my existing eight specialized Workspaces and the currently available VS Code configuration.**

This is a configuration recovery task, NOT another Workspace reorganization.

Do not recreate the Master or change project membership.

## 2. Workspace Locations

All nine Workspace descriptors are located at:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces`

### Target Workspace

`38-Master.code-workspace`

This is the ONLY Workspace descriptor you should modify.

### Reference Workspaces

Inspect all eight existing specialized Workspaces:

1. `ASAP2-Standards.code-workspace`
2. `ASAP2-Deals.code-workspace`
3. `ASAP2-AALC-Checker.code-workspace`
4. `ASAP2-Platform-Automation.code-workspace`
5. `ASAP2-Validation-Engineering.code-workspace`
6. `Data-ETL.code-workspace`
7. `Office-Reporting-Automation.code-workspace`
8. `Developer-Tools.code-workspace`

Treat these eight descriptors as read-only configuration references.

Compare their settings, tasks, extension configurations, and other relevant properties to identify what is missing from `38-Master`.

Do not assume that a setting found in one specialized Workspace should automatically apply to Master. Distinguish shared development preferences from project-specific settings.

## 3. Preserve Existing Master Configuration

Before modifying anything:

1. Read the entire existing `38-Master.code-workspace`.
2. Verify that it references all 29 original project roots.
3. Record its existing `settings`, `tasks`, `extensions`, and other top-level properties.
4. Create a timestamped backup of the Master descriptor outside the source repositories.
5. Preserve the existing 29 folder references and aliases exactly.
6. Preserve existing Master synchronization functionality.

Do not overwrite the Master descriptor with a copy of any specialized Workspace.

Perform a targeted recovery of missing or incorrect configuration only.

## 4. Configuration Discovery and Comparison

Inspect the eight specialized Workspace descriptors and identify their effective configuration sources, including where accessible:

- Workspace Settings
- User Settings
- Active VS Code Profile
- Keyboard shortcuts
- Python extension settings
- Jupyter extension settings
- Terminal configuration
- Workspace Tasks
- GitHub Copilot settings
- Extension-specific settings
- Editor layout preferences
- Extension recommendations

Build a comparison between `38-Master` and the specialized Workspaces.

Classify the results into:

A. Shared configurations missing from Master  
B. Shared configurations already present in Master  
C. Conflicting configurations requiring a decision  
D. Project-specific configurations that must NOT be copied  
E. User/Profile settings that already apply globally and should not be duplicated

Use the currently working specialized Workspace configurations as reference evidence.

Do not blindly merge all JSON settings.

## 5. Restore Python 3.14.4 Interpreter

My preferred Python interpreter is the existing CitiSoftware Python 3.14.4 installation.

A previously identified candidate location was:

`%LOCALAPPDATA%\CitiSoftware\CTC7013_PYTHON_3.14.4\python.exe`

Discover and verify the exact physical path.

Requirements:

1. Verify that the executable exists.
2. Verify it reports Python 3.14.4.
3. Inspect how working specialized Workspaces configure or select this interpreter.
4. Restore equivalent Python interpreter configuration in `38-Master`.
5. Use `python.defaultInterpreterPath` where appropriate and supported.
6. Check for existing interpreter selections that may override the default.
7. Preserve the installed Python 3.12 and Anaconda Python 3.7 environments.
8. Do not install Python or create virtual environments.
9. Do not modify system PATH or the CitiSoftware installation.

### Important Known Issue

Previously, selecting Python 3.14.4 produced:

`Failed to set interpreter path. Error: Unable to write into user settings.`

Do not repeatedly attempt to overwrite User Settings if this restriction remains.

Prefer restoring supported Workspace-level configuration when appropriate.

Do not modify VS Code internal extension databases or bypass corporate restrictions.

Verify that Master can actually use Python 3.14.4, rather than merely having the correct setting written.

## 6. Restore Native Python REPL

**I specifically use `Python: Start Native Python REPL`, not Terminal Python REPL.**

Restore the Native Python REPL behavior used in my existing development environment.

Requirements:

1. Native Python REPL opens as an EDITOR TAB.
2. It supports multiline editing and syntax highlighting.
3. It uses Python 3.14.4.
4. If an existing Native Python REPL is already available in the current VS Code window, reuse or reveal it instead of opening another one.
5. Do not create duplicate REPL editors unnecessarily.
6. Prefer restoring an existing REPL session where supported.
7. Do not start a terminal-based Python REPL.
8. Do not replace Native REPL with Jupyter Interactive Window.

Inspect whether the working specialized Workspaces use:

`python.REPL.sendToNativeREPL`

Preserve the supported configuration needed for sending code to Native REPL.

### Automatic Startup

My desired behavior is that opening `38-Master` automatically provides a Native Python REPL in the editor area if one does not already exist.

Investigate how this behavior is currently achieved in the specialized Workspaces.

Reuse the same supported mechanism if available.

Do not assume a normal `runOn: "folderOpen"` shell task can invoke a Python extension UI command.

If fully automatic Native REPL creation cannot be implemented through supported VS Code mechanisms, explain the limitation and preserve the closest reliable behavior.

Do not install extensions or introduce custom extensions without approval.

## 7. Restore Jupyter Interactive Window

I also use:

`Run in Interactive Window`

This is separate from Native Python REPL.

Restore the Jupyter configuration so that new Interactive Windows use the intended CitiSoftware Python 3.14.4 kernel wherever supported.

Requirements:

1. Prefer Python 3.14.4 as the Interactive Window kernel.
2. Verify that a compatible `ipykernel` is available.
3. Do not install or upgrade packages without approval.
4. Inspect existing Jupyter kernel preferences and selections.
5. Avoid accidentally selecting Python 3.12 or Anaconda Python 3.7.
6. Preserve intentionally selected kernels where appropriate.
7. Do not automatically launch a Jupyter kernel merely because the Workspace opens.
8. Initialize the kernel when Interactive Window is first used.

### Important

Python Interpreter selection, Native Python REPL, and Jupyter Interactive Window kernel selection are different mechanisms.

Ensure each is configured appropriately.

Do not assume `python.defaultInterpreterPath` alone guarantees the correct Interactive Window kernel.

## 8. Restore Editor Layout

My preferred VS Code editor layout is:

### Editor Group 1 — Source Code

Normal Python, SQL, JSON, and other source files.

### Editor Group 2 — Python Interactive Area

Contains two separate editor tabs:

- Native Python REPL
- Jupyter Interactive Window

Both must appear in the SAME editor group and share the same tab strip.

They must not replace each other.

Restore the appropriate supported Jupyter setting, investigating:

`jupyter.interactiveWindow.viewColumn`

My preference is:

`secondGroup`

Also inspect the installed extension's actual support and relevant creation-mode settings.

Requirements:

1. Native Python REPL should appear in Editor Group 2 where feasible.
2. Newly created Interactive Windows should also appear in Editor Group 2.
3. Do not create unnecessary additional editor groups.
4. Do not close or restart existing interactive sessions solely to change their visual placement.
5. Preserve the current editor layout where possible.
6. Do not claim persistent layout control beyond what VS Code supports.

## 9. Restore PowerShell Terminal

Unlike Python REPL, PowerShell should open in the integrated terminal panel.

Restore the existing automatic PowerShell startup behavior if present in the specialized Workspaces.

Requirements:

1. Provide a separate PowerShell integrated terminal.
2. Use the existing PowerShell installation and configuration.
3. Keep it interactive.
4. Avoid creating unnecessary duplicate terminals.
5. Preserve the existing terminal appearance and preferences.
6. Do not execute project-specific scripts automatically.
7. Do not change execution policy.
8. Do not launch a terminal-based Python REPL.

Inspect existing Workspace Tasks and restore the appropriate supported automatic startup task in Master.

Preserve unrelated Master tasks.

## 10. Restore GitHub Copilot Configuration

Inspect the specialized Workspaces and available VS Code User/Profile settings.

Restore applicable common Copilot behavior in Master, including:

- Copilot Chat configuration
- Agent Mode preferences
- Context and workspace search behavior
- Custom instructions references
- Model-related preferences where supported
- Terminal integration
- Tool permissions
- Confirmation behavior

Do not copy project-specific Copilot instructions into Master without evaluating their intended scope.

Do not reset Copilot.

Do not broaden tool permissions or bypass security protections.

Do not modify existing Copilot conversations.

## 11. Restore Editor, Extension, and UI Preferences

Compare the Master against working specialized Workspaces for:

- Python and Jupyter extension settings
- Default formatters
- Format on save
- Auto-save
- File associations
- Editor fonts and sizes
- Indentation
- Word wrap
- Theme
- Icon theme
- Explorer preferences
- Search preferences
- Terminal preferences
- Git preferences
- Language-specific configuration

Restore only shared, applicable settings that Master is missing.

### Profile and Keyboard Shortcuts

Keyboard shortcuts and installed extensions are generally controlled by the active VS Code Profile rather than individual `.code-workspace` descriptors.

Ensure `38-Master` uses the intended existing VS Code Profile where supported.

Do not create or reset Profiles.

Do not duplicate keyboard shortcut configuration into invalid Workspace settings.

If Profile association requires manual VS Code interaction, provide the exact instructions.

## 12. Preserve Master Synchronization

The Master Workspace is synchronized from the eight specialized Workspace descriptors by:

`H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py`

The specialized Workspaces are authoritative for project membership.

Master synchronization updates the Master `folders` array.

Preserve this architecture.

Requirements:

1. Keep all 29 project roots.
2. Preserve existing folder aliases.
3. Preserve the `Sync Master Workspace` task.
4. Preserve all restored Master settings and startup tasks when synchronization runs.
5. Do not modify the synchronization utility unless an actual defect affecting configuration preservation is discovered.
6. Do not change the eight specialized Workspace descriptors.

Run the existing read-only synchronization check:

```powershell
python "H:\Analytics\xChen\30-39 Projects\38 Workspaces\sync_master_workspace.py" --check
```

Use the verified Python executable if the `python` command resolves to the wrong interpreter.

The expected status is:

`IN SYNC`

If synchronization is already correct, do not unnecessarily rewrite Master.

## 13. Safety Constraints

### Allowed

- Inspect existing VS Code configurations.
- Compare the nine Workspace descriptors.
- Inspect relevant VS Code extension settings.
- Verify Python interpreter availability.
- Back up `38-Master.code-workspace`.
- Restore missing supported settings in Master.
- Restore supported Workspace tasks in Master.
- Validate the Master descriptor.
- Run minimal Python interpreter and synchronization checks.

### Prohibited

- Do not modify the eight specialized Workspace descriptors.
- Do not move, rename, or copy source project folders.
- Do not modify project source code.
- Do not modify Git repositories or histories.
- Do not install or remove Python packages.
- Do not install or remove VS Code extensions.
- Do not reset User Settings or Profiles.
- Do not overwrite keyboard shortcuts.
- Do not modify system environment variables.
- Do not bypass corporate permissions.
- Do not modify unrelated settings.
- Do not recreate all nine Workspaces.
- Do not perform application runtime tests.
- Do not run ASAP2 or database workflows.

**Only modify `38-Master.code-workspace` and create its configuration backup unless a separately approved repair is genuinely necessary.**

## 14. Execution Steps

### Phase 1 — Discovery

Read Master and all eight specialized Workspace descriptors.

Identify missing, conflicting, and shared configuration.

Inspect relevant current VS Code Profile settings where accessible.

### Phase 2 — Backup

Create a timestamped backup of the current Master descriptor.

### Phase 3 — Recovery

Restore the missing shared configuration to `38-Master` with minimal changes.

Prioritize:

1. Python 3.14.4 interpreter
2. Native Python REPL
3. Jupyter Interactive Window kernel
4. Editor Group layout
5. PowerShell startup
6. GitHub Copilot
7. Common editor and extension settings
8. Existing Master synchronization tasks

Do not overwrite correct existing settings.

### Phase 4 — Verification

Verify:

- Master still contains 29 project roots.
- Python 3.14.4 executable is valid.
- Native REPL configuration is restored.
- Interactive Window configuration is restored.
- Editor placement settings are appropriate.
- PowerShell startup task is preserved or restored.
- Copilot and common settings are preserved.
- Master synchronization remains intact.
- All configuration files remain valid.

Verify actual UI behavior where feasible; otherwise explicitly distinguish configuration validation from live behavior verification.

### Phase 5 — Report

Provide a concise report containing:

1. Root cause of missing Master settings, if established.
2. Configurations recovered from specialized Workspaces.
3. Python interpreter path and version.
4. Native REPL restoration status.
5. Jupyter Interactive Window status.
6. Editor layout configuration.
7. PowerShell task status.
8. Copilot/Profile consistency.
9. Master synchronization status.
10. Exact files changed.
11. Remaining manual VS Code actions, if necessary.

Include a before/after summary of the modified Master settings.

## 15. Definition of Done

The task is complete when:

- `38-Master` retains all original 29 project roots.
- Shared development settings have been restored where applicable.
- Python 3.14.4 is configured and verified.
- Native Python REPL remains editor-based, not terminal-based.
- Duplicate REPL instances are avoided where supported.
- Jupyter Interactive Window uses the intended kernel.
- Native REPL and Interactive Window use the same editor group where supported.
- PowerShell remains a separate terminal.
- Existing Copilot, extension, and keyboard shortcut preferences remain intact.
- Master synchronization continues working.
- No specialized Workspace or source project has been changed.
- Any unsupported automatic UI behavior is accurately documented.

## Final Instruction

**Use the existing eight specialized Workspaces as configuration references to recover my `38-Master` development environment.**

Do not redesign or rebuild the Workspace architecture.

Do not copy settings indiscriminately.

Preserve the existing Master folder membership, synchronization system, and Git repository boundaries.

Execute the recovery with minimal, reversible changes.

Only request clarification when conflicting configurations cannot be safely resolved or a change requires modifying protected User/Profile settings.

Proceed now.
