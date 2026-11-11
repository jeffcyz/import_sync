# SEC EDGAR — Integrate Windows Truststore and Validate First Real-Data Sample

The previous diagnostics have successfully established secure connectivity to both SEC endpoints through our corporate Kerberos proxy.

Verified results:

- `data.sec.gov`: HTTP 200, validated SEC JSON.
- `www.sec.gov`: HTTP 200, validated SEC JSON.
- Kerberos proxy authentication works after the proxy manager refresh fix.
- Effective proxy: `webproxy.wlb2.nam.nsroot.net:8080`.
- TLS verification remains enabled.
- Windows native certificate trust works when `truststore.inject_into_ssl()` is executed at process startup.
- No insecure TLS fallback is required.
- The previous full suite reported 642 passing tests.
- Stage 1 and Stage 2 business logic remain unchanged.

The successful truststore injection was performed only at runtime. It has not yet been integrated into the repository.

## Objective

Make the verified Windows certificate trust configuration a supported, reproducible application feature, and then perform the first controlled real-data validation of Stage 1 and Stage 2.

Do not rewrite the existing pipeline.

## Task 1 — Integrate Windows Native Truststore

Inspect the existing application startup sequence:

- `sec_notes/__main__.py`
- CLI initialization
- Configuration loading
- `proxy_auth.py`
- `sec_client.py`

Implement native Windows certificate trust support using the already validated `truststore` package.

Requirements:

1. Initialize truststore early enough that Requests and urllib3 use the native certificate store.
2. Do not inject global SSL changes from reusable library modules at import time.
3. Prefer initialization at the actual CLI application entry point.
4. Preserve existing Kerberos proxy behavior.
5. Preserve TLS certificate verification.
6. Do not enable `verify=False`.
7. Do not modify system certificates.
8. Avoid unnecessary dependencies or architectural changes.
9. Ensure the solution works on subsequent normal CLI launches without custom `python -c` startup commands.
10. Do not install packages without checking the current environment and applicable corporate policies.

Provide a clear TLS configuration preference, for example:

- `windows`: Native Windows trust store
- `pem`: Explicit approved CA bundle
- `default`: Standard Python Requests trust configuration

Use descriptive option names consistent with the existing CLI.

Handle unsupported Python versions or missing truststore dependencies with clear errors.

Check that Python 3.10+ is available before relying on truststore.

Ensure explicit PEM configuration continues to work.

Keep the transport independent of Stage 1 and Stage 2 business logic.

## Task 2 — Validate Normal CLI Connectivity

After implementation, run the application's standard connectivity command with Windows native trust enabled.

Do not use a custom one-line Python bootstrap.

Do not use `--insecure-tls`.

Confirm both SEC endpoints return:

- HTTP 200
- Valid expected SEC JSON
- TLS verification enabled
- Correct corporate proxy
- No 407
- No direct fallback

Use no more than two requests and no retries.

Do not print Kerberos tokens or sensitive headers.

Ensure the application's diagnostic report clearly records the selected trust mode.

## Task 3 — Audit the Original 13 Issuer CIKs

The original source script contains 13 issuer groups.

Preserve these 13 groups.

Use official SEC entity metadata to check whether the configured CIKs correspond to the intended legal issuer entities.

Identify:

- Correct mappings
- Mismatched mappings
- Potentially incomplete subsidiary coverage
- Unverified entities
- Potential duplicate group associations

Do not automatically invent additional issuers or silently replace CIKs.

Generate a concise issuer mapping validation report.

If additional legal issuing entities are identified, propose evidence-backed changes separately and clearly distinguish confirmed facts from candidates.

## Task 4 — Controlled Real Stage 1 Sample

After secure connectivity works through the normal CLI, run a bounded Citigroup sample.

Study period:

- October 1–31, 2026
- Date basis: SEC Filing Date
- Issuer Group: Citigroup

Use the existing sample mode and isolated sample output directories.

Initially limit the sample to:

- Maximum 30 SEC requests
- Maximum 5 filing documents

Do not allow unrestricted collection.

Validate the following behavior against actual SEC sources:

1. Filing index retrieval
2. Date filtering
3. Form filtering
4. Primary document retrieval
5. Structured-note classification
6. Preliminary versus Final identification
7. Amendment handling
8. CUSIP extraction
9. Issuance matching
10. Duplicate detection
11. Unique issuance counting
12. CSV export
13. Source URL traceability

The sample limits mean these results must not be reported as complete October 2026 market statistics.

For each sampled record, retain source-backed evidence and record any uncertainty.

Do not claim successful classification solely because a CSV was generated.

## Task 5 — Controlled Real Stage 2 Sample

Use the Stage 1 sample snapshot.

Do not restart discovery.

Test actual Principal Amount extraction against the available sample Final Pricing Supplements.

Verify:

- Aggregate Principal Amount
- Per-note denomination safeguards
- CUSIP-to-amount association
- Preliminary versus final notional
- Multi-tranche handling where applicable
- Duplicate notional prevention
- Amount source evidence
- Currency
- Validation status

If the first five documents do not contain adequate final pricing information, report that limitation rather than expanding the request budget automatically.

Do not fabricate amounts.

## Task 6 — Regression Tests

Run focused tests for the new truststore initialization.

Verify:

- Windows trust mode
- PEM mode
- Default CA mode
- Unsupported Python behavior
- Missing truststore dependency
- Kerberos proxy compatibility
- No insecure fallback
- No unexpected SSL global changes during ordinary module import

Then run the complete existing test suite.

Preserve all Stage 1 and Stage 2 interfaces and schemas.

## Task 7 — Update Documentation

Update README and configuration examples.

Provide normal PowerShell commands for:

1. Secure connectivity validation.
2. Single-issuer Stage 1 sample.
3. Single-issuer Stage 2 sample.
4. Issuer mapping validation.
5. Full Stage 1 execution.
6. Full Stage 2 execution.

Full-run commands are for future use only.

Do not execute full collection automatically.

Do not hardcode example contact identities such as Jordan Lee or Jeff Chen as the actual SEC operator. Use the genuine configured operator name and email supplied locally.

## Required Final Report

At completion, report:

1. Files changed.
2. How native Windows trust is initialized.
3. Whether normal CLI connectivity succeeds.
4. Actual SEC endpoint responses.
5. Test results.
6. Status of the 13 issuer mappings.
7. Number of real sample filings retrieved.
8. Number of documents classified.
9. Number of confirmed unique issuances.
10. Number of unresolved classifications.
11. Number of validated principal amounts.
12. Whether Stage 1 and Stage 2 sample CSV files were generated.
13. Any remaining blockers.
14. Exact commands for the next validation step.

Preserve all SEC Fair Access controls and corporate network policies.

Do not run full-window collection automatically.

**Success criteria: the normal CLI securely accesses SEC through the Citi Kerberos proxy, and a bounded real-data sample demonstrates the Stage 1 and Stage 2 processing paths with source-backed audit evidence.**
