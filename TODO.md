下面是一份可以直接给 Codex / Roo Code / Cursor Agent 使用的 **English-only agent prompt**。

````markdown
# Agent Prompt: Refactor ASAP2 Validation Toolkit into Portfolio-Based Functional Framework

You are working in an existing Python / IronPython-compatible repository for ASAP2 / Asset Securitization Analysis Pro validation scripts.

This repo is a half-finished validation framework. Its purpose is to turn many scattered deal/setup/periodic validation scripts into a maintainable, auditable, standardized validation toolkit.

## Current Repository Context

The project currently includes files such as:

- `validation_inventory.md`
  - Lists existing validation scripts under categories such as SetUp validation and Periodic validation.
  - Examples include deal name, primary analyst, state code, next index rate, bond balance vs collateral balance, scheduled balance rollover, fee vs actual, etc.

- `validation_function_contract.md`
  - Defines the standardized validation return contract.
  - Each validation should return a dictionary, not just True/False.
  - Standard fields include:
    - `status`
    - `passed`
    - `severity`
    - `threshold`
    - `issue_code`
    - `issue`
    - `explanation`
    - `impact`
    - `action`
    - `context`
    - `expected`
    - `actual`

- `validation_api.py`
- `ironpython_validation_helpers.py`
  - Existing helper/API layer.
  - Currently includes helper logic such as required checks, equality checks, tolerance checks, roll-forward checks, result summarization, and scan finalization.
  - This layer may currently be class-based or overly complex.

- Example validation scripts:
  - `validate_next_index_rate.py`
    - Scans floating-rate bonds and checks whether `NextIndexRate` is missing, blank, or zero.
  - `SetUpValidationStateCode.py`
    - Checks whether an asset setup `State` field is a valid US state or territory code.

The existing output can already produce detailed JSON like:

```json
{
  "should_interrupt": false,
  "success": false,
  "results": [
    {
      "explanation": "State code must be populated and must be a valid US state or territory code.",
      "actual": "NYC",
      "expected": "Valid US State Code (e.g., CA, NY, TX)",
      "script_name_display": "SetUpValidationStateCode",
      "status": "FAIL",
      "impact": "Invalid state values can break setup quality checks, mapping logic, and downstream reporting.",
      "issue": "State Code is not valid",
      "action": "Review the asset setup state value and replace it with a valid US state code.",
      "issue_code": "SETUP_STATE_CODE_INVALID",
      "function_key": "set_up_validation_state_code",
      "passed": false,
      "severity": "CRITICAL",
      "context": {
        "asset_name": "0000000430623073",
        "field_name": "State"
      }
    }
  ],
  "summary": {
    "by_severity": {
      "CRITICAL": 2
    },
    "highest_severity": "CRITICAL",
    "pass": 0,
    "fail": 2,
    "total": 2
  }
}
````

The current output is too verbose by default. The framework needs a cleaner default output and a clearer place to control interruption behavior.

---

# Primary Goal

Refactor and extend this repository into a clean, functional, portfolio-based validation framework.

The final design must allow me to combine arbitrary validation scripts into a configurable "validation portfolio", run the selected portfolio, receive standardized summary output, optionally receive full detail output, and centrally control whether the host system should interrupt/raise an error.

---

# Required Features

## 1. Validation Portfolio Support

Implement the concept of a `validation portfolio`.

A validation portfolio is a named group of validation scripts that can be run together.

Example use cases:

* A setup validation portfolio
* A periodic validation portfolio
* A deal onboarding validation portfolio
* A month-end validation portfolio
* A custom portfolio combining any selected validations

The portfolio layer should support:

* Portfolio name
* Portfolio description
* Ordered list of validation scripts
* Enable/disable individual validations
* Optional per-validation parameters
* Optional portfolio-level output mode
* Optional portfolio-level interruption policy

Use JSON configuration where appropriate.

Suggested config file:

```json
{
  "default_portfolio": "setup_quality",
  "portfolios": {
    "setup_quality": {
      "description": "Setup quality validation portfolio.",
      "output_mode": "summary",
      "interrupt_policy": {
        "enabled": true,
        "mode": "severity_at_or_above",
        "severity": "CRITICAL"
      },
      "validations": [
        {
          "name": "State Code Validation",
          "script": "SetUpValidationStateCode.py",
          "enabled": true,
          "validates": "Asset setup State field must contain a valid US state or territory code.",
          "params": {}
        },
        {
          "name": "Next Index Rate Validation",
          "script": "validate_next_index_rate.py",
          "enabled": true,
          "validates": "Floating-rate bonds must have a populated and non-zero NextIndexRate.",
          "params": {}
        }
      ]
    }
  }
}
```

You may adjust the exact config shape if needed, but keep it simple, readable, and IronPython-compatible.

---

## 2. Summary-First JSON Output

The default output must be summary-only.

By default, when a validation portfolio runs, the JSON should show only:

* Portfolio name
* Overall success/fail
* Whether the host should interrupt
* Portfolio-level summary
* Per-validation summary
* Validation name
* What the validation validates

Default output should NOT include every detailed failed record unless explicitly requested.

Default summary output should look similar to this:

```json
{
  "portfolio_name": "setup_quality",
  "success": false,
  "should_interrupt": true,
  "output_mode": "summary",
  "portfolio_summary": {
    "total_validations": 2,
    "passed_validations": 0,
    "failed_validations": 2,
    "total_records_checked": 125,
    "total_failures": 3,
    "highest_severity": "CRITICAL",
    "by_severity": {
      "CRITICAL": 3
    }
  },
  "validations": [
    {
      "validation_name": "State Code Validation",
      "script": "SetUpValidationStateCode.py",
      "validates": "Asset setup State field must contain a valid US state or territory code.",
      "success": false,
      "summary": {
        "pass": 0,
        "fail": 2,
        "total": 2,
        "highest_severity": "CRITICAL",
        "by_severity": {
          "CRITICAL": 2
        }
      }
    },
    {
      "validation_name": "Next Index Rate Validation",
      "script": "validate_next_index_rate.py",
      "validates": "Floating-rate bonds must have a populated and non-zero NextIndexRate.",
      "success": false,
      "summary": {
        "pass": 0,
        "fail": 1,
        "total": 1,
        "highest_severity": "HIGH",
        "by_severity": {
          "HIGH": 1
        }
      }
    }
  ]
}
```

A full-detail mode should still be available.

For example:

```json
{
  "output_mode": "full",
  "validations": [
    {
      "validation_name": "State Code Validation",
      "summary": {},
      "results": []
    }
  ]
}
```

Support at least these output modes:

* `summary`

  * Default.
  * Shows portfolio summary and each validation summary only.
* `full`

  * Shows summary plus all detailed validation result records.
* `compact`

  * Optional, if easy.
  * Shows only portfolio-level summary and failed validation names.

---

## 3. Centralize and Simplify Interruption Control

The framework currently has confusing or scattered control over:

* `should_interrupt`
* `return_results`
* `interrupt_after_scan`
* final message generation
* host-system error triggering

Refactor this so interruption behavior is controlled in exactly one place.

Preferred design:

* Individual validation scripts must never decide whether the host should interrupt.
* Individual validation scripts only return validation result dictionaries or lists of dictionaries.
* Portfolio runner collects results.
* Portfolio finalizer calculates:

  * `success`
  * `should_interrupt`
  * summary
  * display JSON
  * optional full log payload
* Only the portfolio finalizer should decide whether to raise/trigger interruption.

Create or refactor a function similar to:

```python
def finalize_portfolio_scan(portfolio_result, interrupt_policy=None, output_mode="summary", raise_on_interrupt=False):
    """
    Central place to:
    - summarize portfolio results
    - determine success/failure
    - determine should_interrupt
    - build display payload
    - optionally raise an exception for ASAP2 host interruption
    """
```

Interruption policy should be simple and explicit.

Suggested policy shape:

```json
{
  "enabled": true,
  "mode": "severity_at_or_above",
  "severity": "CRITICAL"
}
```

Support at least:

* `none`

  * Never interrupt.
* `any_fail`

  * Interrupt if any validation fails.
* `severity_at_or_above`

  * Interrupt if any failure has severity equal to or higher than configured severity.
* `fail_count_at_or_above`

  * Interrupt if total failure count is greater than or equal to configured count.

Default behavior:

* Output mode: `summary`
* Interrupt policy: interrupt on `CRITICAL` or worse
* Do not show full detailed result records by default

The host-facing final message should be concise, for example:

```text
2 validation errors raised, test failed, download log to view detail
```

The JSON payload should contain enough summary information to understand which validation failed.

---

## 4. Simplify the API Layer

Refactor `validation_api.py` and related helper modules into a simple functional API.

Important requirement:

* Do NOT use classes.
* Keep the API as plain functions.
* Avoid `ValidationHelperApi` class or class-based wrappers.
* Keep functions small, composable, and IronPython-compatible.

Suggested functional API:

```python
def make_result(status, passed, severity, issue_code, issue, explanation,
                impact=None, action=None, context=None, expected=None,
                actual=None, threshold=None, script_name_display=None,
                function_key=None):
    pass

def pass_result(...):
    pass

def fail_result(...):
    pass

def check_required(value, field_name=None, context=None, severity="HIGH", ...):
    pass

def check_equal(actual, expected, ...):
    pass

def check_within_tolerance(actual, expected, tolerance, ...):
    pass

def summarize_results(results):
    pass

def summarize_validation(validation_name, script, validates, results):
    pass

def summarize_portfolio(validation_outputs):
    pass

def determine_should_interrupt(summary, interrupt_policy):
    pass

def finalize_validation_scan(results, output_mode="summary"):
    pass

def finalize_portfolio_scan(portfolio_output, interrupt_policy=None, output_mode="summary", raise_on_interrupt=False):
    pass
```

Keep the API backward-compatible only if it is not too messy. If backward compatibility makes the design confusing, prefer the new clean functional API and update the example scripts accordingly.

Avoid unnecessary abstraction.

---

## 5. One Public Callable Function Per Validation Script

Enforce a simple convention:

Each validation script should expose only one external callable validation function.

Default rule:

* The first top-level public function in a validation script is the validation entrypoint.
* The portfolio runner should call only that first public function.
* Other helper functions inside that validation script should be treated as private implementation details.
* Private helper functions should be prefixed with `_`.

Example:

```python
def validate_state_code(runtime_context=None, params=None):
    """
    Public validation entrypoint.
    This should be the first top-level public function in the file.
    """
    pass


def _normalize_state(value):
    pass


def _is_valid_state_code(value):
    pass
```

Do not make portfolio config require a function name unless absolutely necessary.

Preferred config:

```json
{
  "script": "SetUpValidationStateCode.py"
}
```

Not preferred:

```json
{
  "script": "SetUpValidationStateCode.py",
  "function": "set_up_validation_state_code"
}
```

If needed, allow an optional `function` override, but the default should be first public function.

For source-order detection, do not rely on alphabetical introspection. Implement a robust helper that reads the script source and identifies the first top-level `def` that does not start with `_`.

---

## 6. Portfolio Runner

Create or refactor a portfolio runner module.

Suggested file:

* `validation_portfolio_runner.py`

It should provide plain functions such as:

```python
def load_portfolio_config(config_path):
    pass

def get_portfolio(config, portfolio_name=None):
    pass

def load_validation_entrypoint(script_path, function_name=None):
    pass

def run_validation_script(validation_config, runtime_context=None):
    pass

def run_validation_portfolio(portfolio_name=None, config_path=None, runtime_context=None,
                             output_mode=None, raise_on_interrupt=False):
    pass
```

The runner should:

1. Load portfolio config.
2. Resolve selected portfolio.
3. Iterate through enabled validations in order.
4. Load each validation script.
5. Detect the first public function unless an override is provided.
6. Call the validation function.
7. Normalize returned output into a list of standardized result dictionaries.
8. Summarize each validation.
9. Summarize the whole portfolio.
10. Finalize output using the centralized finalizer.
11. Return the payload.
12. Optionally raise an exception only at the finalizer layer if interruption is required.

The runner must be tolerant of validation function return shapes:

* Single dict
* List of dicts
* Dict containing `results`
* Empty result / None should be treated as pass only if explicitly intended by the validation design

If a validation script itself crashes, convert that exception into a standardized validation failure result with severity `CRITICAL`, issue code such as `VALIDATION_SCRIPT_RUNTIME_ERROR`, and include script name in context.

---

## 7. Keep IronPython / ASAP2 Host Compatibility

This repository is intended to run inside or near ASAP2 / Asset Securitization Analysis Pro, which may use IronPython.

Therefore:

* Avoid unnecessary third-party packages.
* Avoid modern Python features that may break IronPython.
* Avoid dataclasses.
* Avoid pydantic.
* Avoid type hints if they reduce compatibility.
* Avoid f-strings if IronPython 2.7 compatibility is required.
* Avoid pathlib if compatibility is uncertain.
* Use plain dict/list/string/number structures.
* Use standard library only where possible.
* Use `json` for serialization.
* Keep file paths simple and explicit.
* Do not introduce async code.

---

## 8. Documentation Updates

Update or create documentation explaining the new framework.

Required docs:

### `validation_portfolio_contract.md`

Explain:

* What a validation portfolio is
* Portfolio config format
* Validation entrypoint convention
* Output modes
* Interrupt policies
* Default behavior
* Example summary output
* Example full output

### Update `validation_function_contract.md`

Clarify:

* Individual validation functions return standardized result dicts or lists of dicts.
* Individual validation functions do not interrupt the host.
* Individual validation functions do not decide display output.
* Individual validation functions should not print final JSON.
* Portfolio finalizer controls summary/full display and interruption.

### Update `validation_inventory.md`

If needed, add columns or sections for:

* Script file
* Validation name
* What it validates
* Severity
* Portfolio membership
* Entrypoint function

---

## 9. Example Refactors

Refactor at least these scripts to demonstrate the new pattern:

* `SetUpValidationStateCode.py`
* `validate_next_index_rate.py`

Each should:

* Have one first public validation function
* Use the simplified functional API
* Return standardized result dict/list
* Not decide interruption
* Not print final host output directly
* Not use classes

---

## 10. Tests / Smoke Tests

Add simple tests or smoke scripts that can run outside ASAP2 using mocked data.

Suggested files:

* `tests/test_validation_api.py`
* `tests/test_validation_portfolio_runner.py`
* `examples/run_setup_quality_portfolio.py`

The smoke test should prove:

1. A portfolio can combine multiple validations.
2. Disabled validations are skipped.
3. Default output is summary-only.
4. Full output includes detailed result records.
5. `should_interrupt` is calculated centrally.
6. `severity_at_or_above` works.
7. `any_fail` works.
8. `none` works.
9. Script runtime exceptions are converted into standardized CRITICAL validation failures.
10. Only the first public function in a validation script is used by default.

---

# Important Design Constraints

Follow these constraints strictly:

1. Do not use classes.
2. Do not introduce unnecessary dependencies.
3. Do not over-engineer.
4. Preserve ASAP2 / IronPython host compatibility as much as possible.
5. Keep validation scripts small and readable.
6. Keep validation business logic separate from portfolio orchestration.
7. Keep interruption logic centralized.
8. Keep result display centralized.
9. Default output must be summary-only.
10. Full details should be available only when explicitly requested.
11. Each validation script should expose only its first public function as the callable entrypoint.
12. The portfolio runner should not require function names in config by default.
13. If existing behavior conflicts with this design, prefer this new design but document the change.

---

# Expected Deliverables

Implement the following:

1. A simplified functional `validation_api.py`.
2. A portfolio runner module, preferably `validation_portfolio_runner.py`.
3. A JSON portfolio config file, preferably `validation_portfolios.json`.
4. Refactored example validation scripts:

   * `SetUpValidationStateCode.py`
   * `validate_next_index_rate.py`
5. Centralized finalization logic:

   * Summary creation
   * Full output creation
   * `should_interrupt` calculation
   * Optional host exception raising
6. Updated documentation:

   * `validation_portfolio_contract.md`
   * Updated `validation_function_contract.md`
   * Updated `validation_inventory.md` if appropriate
7. Smoke tests or example scripts proving the framework works.

---

# Suggested Implementation Plan

Proceed in stages.

## Stage 1 — Inspect Existing Code

Read the current repository structure.

Identify:

* Current helper/API functions
* Current validation result schema
* Current interruption logic
* Current example validation scripts
* Places where output is printed or finalized
* Places where host interruption is triggered

Do not rewrite business validation logic yet.

## Stage 2 — Refactor API into Plain Functions

Simplify `validation_api.py`.

Remove or bypass class-based API design.

Create small functional helpers for:

* Creating pass/fail results
* Normalizing result lists
* Summarizing results
* Determining highest severity
* Determining interruption
* Finalizing validation scan
* Finalizing portfolio scan

Keep function names explicit and easy to read.

## Stage 3 — Build Portfolio Runner

Create `validation_portfolio_runner.py`.

Implement:

* Config loading
* Portfolio selection
* Validation script loading
* First-public-function detection
* Validation execution
* Exception-to-result conversion
* Per-validation summary
* Portfolio summary
* Finalization

## Stage 4 — Add Portfolio Config

Create `validation_portfolios.json`.

Include at least one example portfolio:

* `setup_quality`

Include the refactored state code validation and next index rate validation.

## Stage 5 — Refactor Example Validations

Refactor:

* `SetUpValidationStateCode.py`
* `validate_next_index_rate.py`

Ensure each has:

* First public validation function as entrypoint
* Private helpers prefixed with `_`
* No class
* No final print
* No interruption logic
* Standard result output

## Stage 6 — Add Examples and Tests

Add a runnable example or test using mocked data.

Demonstrate:

```python
from validation_portfolio_runner import run_validation_portfolio

payload = run_validation_portfolio(
    portfolio_name="setup_quality",
    config_path="validation_portfolios.json",
    runtime_context=mock_context,
    output_mode="summary",
    raise_on_interrupt=False
)

print(payload)
```

Also demonstrate:

```python
payload = run_validation_portfolio(
    portfolio_name="setup_quality",
    config_path="validation_portfolios.json",
    runtime_context=mock_context,
    output_mode="full",
    raise_on_interrupt=False
)
```

---

# Acceptance Criteria

The refactor is successful only if all of the following are true:

1. I can define a validation portfolio in JSON.
2. I can combine arbitrary validation scripts into one portfolio.
3. I can enable or disable validations in the portfolio config.
4. I can run a selected portfolio by name.
5. The default JSON output is summary-only.
6. The summary output includes each validation’s name and what it validates.
7. The detailed failed records are hidden by default.
8. Full details are available when `output_mode="full"`.
9. Interruption behavior is controlled centrally in one finalizer function.
10. Individual validation scripts do not control interruption.
11. Individual validation scripts do not print final output.
12. The API layer is functional, not class-based.
13. The framework does not require each validation function name to be listed in config.
14. By default, the first public function in each validation script is the external callable entrypoint.
15. Script runtime errors are converted into standardized CRITICAL validation results.
16. The code remains simple and compatible with ASAP2 / IronPython constraints.
17. The example state code validation and next index rate validation both work under the new structure.
18. There is at least one smoke test or example proving summary mode and full mode.

---

# Output Style for Your Work

When you finish, provide:

1. A concise summary of changed files.
2. The new recommended execution flow.
3. The exact command or script to run the smoke test.
4. Example summary JSON output.
5. Example full JSON output.
6. Any compatibility concerns for IronPython / ASAP2 host execution.

Do not stop after only planning. Implement the refactor directly.

```
```
