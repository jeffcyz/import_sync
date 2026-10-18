PART IV — NATIVE PYTHON REPL AND INTERACTIVE WINDOW LAYOUT

16. Critical Clarification: Native Python REPL, NOT Terminal REPL

My previous requirement for an automatically launched terminal-based Python REPL has changed.

I specifically want the VS Code command:

Python: Start Native Python REPL

This is the editor-based Native Python REPL provided by the Microsoft Python extension.

It supports syntax highlighting, IntelliSense, multiline input, and interactive Python execution.

It must open as an editor tab, NOT inside the integrated terminal.

Do not substitute any of the following:

* Python: Start Terminal REPL
* Running python.exe inside PowerShell
* A shell task that opens a Python terminal
* A Jupyter Interactive Window pretending to be Native REPL

The Native Python REPL and Jupyter Interactive Window must remain two separate editor tabs.

17. Automatic Native Python REPL Initialization

Apply this behavior to all nine Workspaces:

* 38-Master
* ASAP2-Standards
* ASAP2-Deals
* ASAP2-AALC-Checker
* ASAP2-Platform-Automation
* ASAP2-Validation-Engineering
* Data-ETL
* Office-Reporting-Automation
* Developer-Tools

Required Behavior

When a Workspace opens:

1. Check whether a Native Python REPL already exists in the current VS Code window.
2. If an existing Native Python REPL is available, reuse or reveal it.
3. Do NOT open another Native Python REPL.
4. If no Native Python REPL exists, launch Python: Start Native Python REPL.
5. Use the configured CitiSoftware Python 3.14.4 interpreter.
6. Keep the REPL open as an editor tab.
7. Preserve its interactive state whenever VS Code supports restoration.
8. Do not restart an existing REPL merely because the Workspace regains focus.
9. Do not create additional REPL sessions when switching between editor tabs.
10. Never confuse a Jupyter Interactive Window with an existing Native Python REPL.

Desired result: At most one Native Python REPL per VS Code Workspace window under normal operation.

Implementation Restrictions

Use supported VS Code commands and extension APIs.

The relevant built-in command is:

python.startNativeREPL

Verify that this command is registered and available in my installed Python extension.

Do not assume that VS Code Shell Tasks can directly invoke extension UI commands.

A runOn: "folderOpen" task that merely launches a Python process in a terminal does NOT satisfy this requirement.

First investigate whether editor restoration, built-in commands, or another supported lightweight mechanism can achieve the desired behavior.

Avoid installing additional extensions or developing a custom extension unless genuinely necessary and explicitly approved.

If fully automatic Native REPL initialization is not supported by my current VS Code configuration, preserve the best available native experience and explain the limitation.

Do not claim automatic startup has been implemented unless it actually works.

18. Native REPL Interpreter

The Native Python REPL must use my verified CitiSoftware Python 3.14.4 installation.

Requirements:

* Use the currently selected Python 3.14.4 interpreter.
* Do not accidentally use Python 3.12 or Anaconda Python 3.7.
* Do not create a new virtual environment.
* Do not install or modify Python packages.
* Preserve the existing Python extension configuration.
* Ensure interpreter changes are applied to newly started REPL sessions.
* Do not silently restart a running REPL to switch interpreters.

Where appropriate, enable the supported setting:

"python.REPL.sendToNativeREPL": true

This should direct Python Smart Send and Run Selection/Line commands to the Native REPL rather than a terminal.

Preserve my existing keyboard shortcuts unless a change is necessary and approved.

Do not interfere with the separate Run in Interactive Window command.

19. Editor Layout: Native REPL and Interactive Window

This is another high-priority requirement.

I want the Native Python REPL and newly opened Jupyter Interactive Windows to appear in the same editor group, meaning they share the same tab strip.

They must NOT share the same tab or replace each other.

Preferred Layout

Editor Group 1 — Source Code

Contains normal Python source files, SQL scripts, and other editor tabs.

Editor Group 2 — Python Interactive Area

Contains:

* Native Python REPL
* Python Interactive Window
* Additional Interactive Windows when explicitly created

Both REPL and Interactive Window should appear as separate tabs within Editor Group 2.

Required Behavior

1. Prefer placing the Native Python REPL in Editor Group 2.
2. When Run in Interactive Window creates an Interactive Window, place it in the same Editor Group 2.
3. Do not create an unnecessary third editor group.
4. Do not automatically split each new Interactive Window into another editor column.
5. Do not replace or close the Native Python REPL.
6. Do not unnecessarily rearrange my existing source code editor tabs.
7. Reuse the existing editor group where possible.
8. Preserve the established layout when reopening a Workspace, where supported.
9. If an Interactive Window already exists and is reusable, preserve its kernel and state.
10. Do not destroy or restart an existing REPL or Jupyter kernel solely to adjust editor placement.

Jupyter Settings

Inspect the installed Jupyter extension’s supported configuration.

In particular, evaluate:

jupyter.interactiveWindow.viewColumn

Its supported behavior may include:

* active
* beside
* secondGroup

My preferred layout is the second editor group.

Use secondGroup where supported and appropriate, and ensure the Native REPL is also located in that group.

However, do not assume that setting viewColumn alone controls every Interactive Window placement scenario.

Inspect actual behavior for windows created from Python source files.

Also inspect:

jupyter.interactiveWindow.creationMode

Preserve the existing creation mode unless a change is needed to achieve the requested behavior.

Do not unnecessarily force multiple Python files to share one Interactive Window or one kernel.

20. Separate PowerShell Terminal

Continue to automatically provide a clean PowerShell integrated terminal when opening each Workspace.

The PowerShell terminal must:

* Remain separate from the Native Python REPL.
* Appear in the integrated terminal panel.
* Stay interactive and ready for commands.
* Use my existing PowerShell configuration.
* Avoid unnecessary duplicate terminal sessions.
* Not automatically execute application scripts.

Use an automatic VS Code Task where appropriate for PowerShell startup.

The Native Python REPL must NOT be created using this terminal task.

21. Relationship Between Native REPL and Interactive Window

These components are separate execution environments:

1. Native Python REPL — Python extension.
2. Jupyter Interactive Window — Jupyter extension.
3. Integrated PowerShell Terminal — VS Code terminal.

They should use the intended Python 3.14.4 installation where Python execution is required, but they do not necessarily share Python variables, session state, or execution history.

Do not try to merge their execution processes.

The requirement to place Native REPL and Interactive Window in the same editor group concerns their visual layout, not shared execution state.

22. Existing Instance Detection and Session Restoration

Before opening a new Native REPL:

* Check whether an existing Native REPL editor is already available.
* Prefer restoring or revealing the existing instance.
* Do not duplicate the REPL merely because the Workspace has reopened or a command has been invoked again.
* Do not close existing REPL or Interactive Window tabs just to reconstruct the preferred layout.

If VS Code cannot reliably restore a Native REPL process after a full application restart, explain that limitation and initialize a new REPL only when necessary.

Do not claim that Python process state survives a VS Code restart unless that behavior is verified.

23. Verification

Verify the following in a representative Workspace and ensure consistent supported configuration across all nine:

Native REPL

1. Opening a Workspace provides or restores a Native Python REPL.
2. The Native REPL appears in the editor tab area, not the terminal.
3. It supports multiline editing and syntax highlighting.
4. It uses Python 3.14.4.
5. Opening or focusing the Workspace again does not create duplicate REPL editors.

Interactive Window

1. Run in Interactive Window works using the intended Python 3.14.4 kernel.
2. A newly created Interactive Window appears in the same editor group as Native REPL.
3. Native REPL and Interactive Window remain separate tabs.
4. No unnecessary extra editor columns are created.
5. Existing Interactive Window sessions are reused where appropriate.

PowerShell

1. A separate PowerShell terminal remains available.
2. PowerShell does not replace the Native REPL.
3. No terminal-based Python REPL is automatically launched.

Workspace Consistency

Apply the same intended behavior to all nine Workspace configurations.

Use User/Profile settings for shared behavior and Workspace-specific configuration only where necessary.

Do not modify source project files.

24. Acceptance Criteria

This part is complete when:

* Native Python REPL is used instead of Terminal Python REPL.
* Python 3.14.4 is the intended interpreter.
* A second Native REPL is not created when an existing instance can be reused.
* Native REPL and Jupyter Interactive Window appear in the same editor tab group.
* The two interfaces remain independent tabs and execution sessions.
* PowerShell remains available in the terminal panel.
* Existing shortcuts, extensions, Copilot settings, and Workspace configurations are preserved.
* Automatic behavior is verified rather than merely assumed.

If any exact behavior is impossible through supported VS Code settings or commands, report the limitation and the least intrusive alternative.

Do not introduce unsupported settings, hidden configuration changes, or additional extensions merely to claim completion.

Priority

This section supersedes all previous requirements for a terminal-based Python REPL.

Keep the approved nine-Workspace architecture and Master synchronization unchanged.