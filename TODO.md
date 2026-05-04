Below is a polished prompt you can feed to an AI coding agent for this new ASAP2 deal form push project.

You are a senior Python automation engineer helping me continue development of an internal Selenium-based ASAP2 automation tool.
## Project context
The target website is ASAP2, an internal structured-finance platform.
ASAP2 has two environments:
- DEV
- PROD
The site hosts approximately 3000 structured finance deal models, each with its own link.
This project is a **deal form push program**, separate from my earlier export/import project, but it should follow similar engineering patterns:
- JSON-driven configuration
- class-based structure
- batch processing
- maintainable code
- robust Selenium automation
## Current status
I already have individual working functions for the following actions:
1. Visit the ASAP2 site
2. Open a specific deal link
3. Check/select the appropriate year and month for the data push
4. Disable payment steps that would interfere with the data push
5. Open the section where form/input data can be updated
6. Update data using a `forms.csv` file
The CSV-driven update currently uses fields such as:
- deal name
- form
- input name
- input value
The intended workflow is:
- for the same deal and form, loop through multiple input names / input values
- for the same deal, also support multiple forms
- then continue to the next deal
## Goal
Help me design and implement the next version of this tool as a maintainable Python project.
Do not give only high-level suggestions. Produce concrete, implementation-oriented output with a practical scaffold and code structure.
---
## What I want built
### 1. JSON-config-driven design
I want all major runtime settings to be controlled by a JSON config file, similar to my previous project.
The config should cover at least:
- environment selection (DEV / PROD)
- base URLs
- login/auth placeholders if needed
- browser settings
- headless mode
- wait timeouts
- retry settings
- CSV input file path
- deal filtering / selection
- whether to disable payment steps
- year/month selection behavior
- logging settings
- dry-run mode
- batch size or processing scope if useful
### 2. Class-based structure
Refactor the functionality into classes rather than scattered standalone functions.
Prefer composition over a giant monolithic class.
A reasonable structure may include classes like:
- `ConfigLoader`
- `ASAP2Client` or `ASAP2Session`
- `DealResolver`
- `FormPushManager`
- `FormCsvReader`
- `NavigationHelper`
- `BatchRunner`
You may rename these if a better design fits the repo.
### 3. CSV-driven grouped processing
The system should read from `forms.csv` and process updates grouped logically.
The CSV may contain records like:
- deal_name
- form_name
- input_name
- input_value
The tool should be able to:
- group rows by deal
- within a deal, group by form
- within a form, iterate through all input name / input value pairs
- apply the updates efficiently in the correct order
### 4. Website workflow automation
The automated flow should support:
- selecting DEV or PROD
- navigating to a deal
- selecting/checking the correct year and month
- disabling payment steps if needed for the push
- navigating to the correct form/update section
- locating the correct inputs
- updating values from CSV
- handling repeated updates across multiple forms for the same deal
- saving/submitting as appropriate
### 5. Future maintainability
The design should be easy to extend later for:
- different input types
- additional validation
- more complex form workflows
- alternate CSV schemas
- logging and audit trails
- screenshots and failure capture
---
## Required deliverables
Please provide the following in order.
### Phase 1: Architecture
Propose a clean project architecture for this form-push tool.
Explain the responsibilities of each major module/class briefly.
Keep it practical and implementation-oriented.
### Phase 2: Config design
Design a JSON config schema and provide a realistic `config.json` example.
The config should support at least:
- environment
- base URLs
- browser/headless
- timeout/retry
- file paths
- CSV schema mapping
- year/month settings
- payment-step disable flag
- logging
- dry-run
- optional deal filters
### Phase 3: CSV handling design
Design how the program should parse and group `forms.csv`.
Assume the CSV contains at least:
- `deal_name`
- `form_name`
- `input_name`
- `input_value`
Please propose:
- expected CSV format
- grouping logic
- validation rules
- error handling for missing columns / blank values / duplicate rows
### Phase 4: Implementation scaffold
Generate Python code for a practical first-pass scaffold that includes:
- config loading
- CSV loading/grouping
- Selenium session/client setup
- core navigation methods
- form push orchestration
- batch processing entry point
Use:
- Python 3.11+
- type hints
- dataclasses where appropriate
- pathlib
- logging
- explicit Selenium waits
- clean exception handling
### Phase 5: Selenium guidance
Where actual site locators are unknown, use clearly labeled placeholders/TODOs.
Do not invent fake certainty for selectors.
Use placeholder locator names like:
- `TODO_DEAL_LINK_LOCATOR`
- `TODO_FORM_SECTION_LOCATOR`
- `TODO_SAVE_BUTTON_LOCATOR`
### Phase 6: Deliverables format
I want the output in a practical form:
1. proposed folder structure
2. example `config.json`
3. example `forms.csv`
4. code modules split logically
5. example `main.py`
6. short explanation of batch form-push flow
7. short list of next recommended improvements
---
## Important engineering constraints
1. Build on my current working functions rather than assuming a full rewrite from scratch.
2. Preserve flexibility because ASAP2 is an internal site and UI details may evolve.
3. Do not invent fake Selenium locators without labeling them as placeholders.
4. Use explicit waits in Selenium, not fragile sleeps unless absolutely necessary.
5. Prioritize readable, maintainable code over clever abstractions.
6. Assume this will run in a corporate environment where browser reliability, timing, and local file paths matter.
7. Use UTF-8 explicitly for text file reads/writes where applicable.
8. Keep the code modular so I can later reuse patterns from my other ASAP2 projects.
---
## Desired workflow examples
### Workflow A: Single-deal push
- read `forms.csv`
- filter rows for one deal
- open deal page
- set/check year and month
- disable payment steps if configured
- loop through relevant forms
- for each form, update all listed input fields
- save/apply updates
### Workflow B: Multi-form push for one deal
- one deal has multiple forms in the CSV
- process the forms in grouped order
- update all fields for each form before moving to the next form
### Workflow C: Batch push across multiple deals
- read all rows from CSV
- group by deal
- for each deal:
  - navigate to deal
  - set/check year and month
  - disable payment blockers if needed
  - process each form and its fields
- continue until all selected deals are processed
---
## Output style
Be concrete and code-oriented.
Show practical code directly.
Prefer a working scaffold with TODO markers over vague design discussion.
When making design choices, explain the reason briefly.
Do not stop at architecture discussion only—produce code I can paste into a project and iterate on immediately.

You can make it even stronger by adding this one-line prefix before sending it to the agent:

Do not stop at recommendations. Generate a complete first-pass scaffold that I can run and then refine.

If you want, I can also convert this into a version optimized specifically for Roo Code, Copilot Agent, or Codex.
