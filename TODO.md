SEC EDGAR — Final Corporate CA Trust Resolution

The previous transport repair has succeeded in resolving the HTTP 407 proxy-authentication problem.

Both data.sec.gov and www.sec.gov now return HTTP 200 with validated JSON in bounded diagnostic mode using --insecure-tls.

The full suite reports 642 passing tests.

The only remaining production connectivity blocker is TLS certificate trust:

SSLError: self-signed certificate in certificate chain

Objective

Resolve the corporate CA trust issue without disabling TLS verification, altering the Kerberos proxy mechanism, or modifying Stage 1/Stage 2 business logic.

Step 1 — Inspect Windows Certificate Trust

We are running on a Citi-managed Windows workstation.

Determine whether the corporate root/intermediate CA used by HTTPS inspection is already trusted by Windows.

Inspect available certificate-store integration options without exporting private keys, installing unapproved certificates, or requiring administrative changes.

Determine whether the current Python environment can safely use the approved Windows certificate store through the truststore library or another supported approach.

Do not automatically install dependencies or modify system trust settings without authorization.

Step 2 — Investigate Requests CA Configuration

The previous diagnostics reported trust_env: false.

Verify whether this prevents the application from using REQUESTS_CA_BUNDLE.

Inspect the exact path by which the current --ca-bundle argument reaches requests.Session, the custom Kerberos HTTPAdapter, and urllib3.

Ensure that an explicitly supplied CA Bundle is actually used for certificate verification and is not overwritten by other session or request settings.

Preserve the existing proxy configuration and Kerberos behavior.

Step 3 — Compare Two Secure Solutions

Evaluate:

Option A: Windows native certificate store

Use an approved system-trust integration if supported by the installed Python and HTTP libraries.

Option B: Explicit corporate CA Bundle

Use an IT-approved PEM bundle through --ca-bundle.

Identify the smallest supported solution.

Prefer a configuration-based solution over unnecessary code changes.

Do not modify the system certificate store or disable TLS verification.

Step 4 — Perform Bounded Secure Connectivity Tests

Test both:

* https://data.sec.gov
* https://www.sec.gov

Requirements:

* verify=True or an explicitly approved CA Bundle
* Existing Kerberos proxy
* No direct internet fallback
* No --insecure-tls
* Valid SEC User-Agent
* Maximum two requests
* No retries

Confirm:

* HTTP 200
* Expected SEC response format
* Valid response content
* Certificate-chain validation
* No 407 error
* Effective proxy remains the approved Citi proxy

Step 5 — Preserve Existing Functionality

Do not modify:

* Filing discovery
* Classification
* Issuance deduplication
* Dollar-notional extraction
* CSV schemas
* Monthly reconciliation

Run focused transport tests for any changes and the full suite if code was modified.

Expected Handoff

Report:

1. Whether the corporate CA is already present in Windows.
2. Whether Requests is ignoring REQUESTS_CA_BUNDLE because trust_env is false.
3. Whether Windows native trust integration is compatible with the current Kerberos Adapter.
4. Whether an approved PEM CA Bundle is required.
5. Exact configuration changes, if any.
6. Actual secure connectivity test results.
7. Any remaining dependency on corporate IT.
8. The exact command for the next secure connectivity check.

Do not execute Stage 1 or Stage 2 bulk data collection.

Success means both SEC hosts are reachable through the Citi Kerberos proxy with certificate validation fully enabled.