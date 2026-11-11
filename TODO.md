# SEC EDGAR — Corporate Proxy Connectivity Diagnosis and Repair

You have completed the implementation of the two-stage SEC EDGAR Structured Notes extraction pipeline.

Your reported results are:

- 640 offline tests passed.
- Stage 1 and Stage 2 implemented.
- Compilation succeeded.
- No real SEC data collection was performed.
- `data.sec.gov` failed with a TLS verification/negotiation error.
- `www.sec.gov` failed with HTTP 407 Proxy Authentication Required.
- Original 13 issuer CIK mappings were preserved but not verified.

## Objective

Diagnose and resolve the SEC connectivity failures through the existing Citi corporate Kerberos proxy.

**Do not rebuild the project or rewrite the business logic.**

Focus on the actual HTTP transport implementation in:

- `proxy_auth.py`
- `sec_client.py`
- Related configuration and connectivity CLI code

Preserve all existing Stage 1 and Stage 2 implementation, tests, schemas, and output contracts.

## 1. Verify the actual working Kerberos reference

My previously working corporate Python configuration used the following implementation:

```python
import requests

from requests_kerberos import HTTPKerberosAuth
from urllib3.util import parse_url

proxies = {
    "http": "http://webproxy.wlb2.nam.nsroot.net:8080",
    "https": "http://webproxy.wlb2.nam.nsroot.net:8080",
}

class HTTPAdapterWithProxyKerberosAuth(
    requests.adapters.HTTPAdapter
):
    def proxy_headers(self, proxy):
        headers = {}
        auth = HTTPKerberosAuth()

        negotiate_details = auth.generate_request_header(
            None,
            parse_url(proxy).host,
            is_preemptive=True
        )

        headers["Proxy-Authorization"] = negotiate_details
        return headers

session = requests.Session()
session.proxies = proxies

session.mount(
    "https://",
    HTTPAdapterWithProxyKerberosAuth()
)
```

The original working implementation also used `session.verify = False`, but this must not become the production default.

Compare the current implementation against the exact reference above.

Inspect how the Kerberos token is generated, which SPN is used, how proxy headers are supplied to urllib3, and how the HTTPS CONNECT tunnel is established.

Do not assume that invoking `proxy_headers()` proves successful authentication.

## 2. Inspect actual dependency versions

Determine the installed versions of:

- Python
- requests
- urllib3
- requests-kerberos
- pyspnego, if installed
- Relevant Kerberos/SSPI dependencies

Check whether the current custom adapter behavior is compatible with these versions.

Inspect the implementation of `HTTPAdapter.proxy_manager_for()` and `proxy_headers()` rather than relying on assumptions.

Document any compatibility issue before changing behavior.

## 3. Diagnose effective proxy selection

Inspect whether `requests.Session.proxies` is being overridden by:

- HTTP_PROXY
- HTTPS_PROXY
- ALL_PROXY
- NO_PROXY
- Windows environment configuration
- Session-level settings
- Request-level arguments

Determine the effective proxy for each SEC request.

Confirm whether both SEC hosts use the intended corporate proxy.

Check whether `session.trust_env` changes proxy selection or CA bundle handling.

Do not blindly disable `trust_env`, because that can also affect `REQUESTS_CA_BUNDLE`.

Never fall back to unapproved direct internet access.

## 4. Diagnose HTTP 407

Investigate the following:

- Whether the CONNECT request reaches the correct proxy.
- Whether the custom adapter provides `Proxy-Authorization`.
- Whether the proxy advertises Negotiate or another authentication scheme.
- Whether Kerberos credentials are available in the Windows execution context.
- Whether the token is generated for the expected proxy host.
- Whether proxy authentication succeeds but is lost on another request or connection.
- Whether connection pooling or redirects affect proxy behavior.
- Whether proxy policy rejects the SEC destination.

Inspect response status and safe diagnostic headers, including `Proxy-Authenticate` if present.

Never print or store:

- Kerberos tokens
- Authorization headers
- Proxy-Authorization values
- Passwords
- Session cookies

If authentication cannot be established, report exactly where the negotiation fails and whether corporate IT assistance is required.

Do not create a workaround that bypasses corporate authentication or access controls.

## 5. Diagnose TLS verification and negotiation

Separate these failure categories:

- Proxy authentication failure
- Proxy CONNECT failure
- TLS handshake failure
- Certificate chain verification failure
- Hostname verification failure
- SEC HTTP response failure

Determine whether the error occurs before or after the CONNECT tunnel is established.

Inspect the Requests/urllib3 TLS configuration.

Report the current CA bundle configuration and whether `REQUESTS_CA_BUNDLE` is respected.

Determine whether the corporate network requires a corporate root/intermediate CA certificate.

Prefer an approved CA bundle and `verify=True`.

Do not permanently set `verify=False`.

Do not suppress certificate warnings to conceal a failed trust configuration.

If a necessary CA certificate is unavailable, report the certificate/trust requirement clearly rather than weakening the production configuration.

## 6. Provide safe diagnostic logging

Enhance connectivity mode with sanitized diagnostics, including:

- Target host
- Effective proxy hostname and port
- Python and HTTP library versions
- Adapter class used
- Whether Kerberos token generation was attempted
- Whether a proxy authentication challenge was received
- HTTP status code
- CONNECT/TLS failure category
- Certificate verification setting
- CA bundle path, when configured
- Request elapsed time
- Exception type and sanitized error summary

Do not log authentication secrets.

Avoid saving detailed sensitive environmental information by default.

## 7. Isolate the source of the problem

Perform bounded, approved connectivity tests.

First, test the existing proxy configuration independently of SEC business logic.

If an existing authorized corporate HTTPS endpoint from the previous working environment can be used safely, compare the behavior using the same Python environment and adapter.

Do not reproduce BNY cookies, authentication sessions, or business-specific headers.

Then test SEC endpoints separately:

```text
https://data.sec.gov
https://www.sec.gov
```

Use valid lightweight paths and the appropriate SEC User-Agent.

For each SEC host, perform no more than the configured small diagnostic request budget.

Do not initiate bulk downloading.

## 8. Repair only proven problems

After identifying the root cause, implement the smallest necessary change.

Preserve:

- Corporate Kerberos authentication
- Required proxy routing
- Approved TLS certificate validation
- SEC Fair Access compliance
- Existing retry behavior
- Existing API client interfaces
- Stage 1 and Stage 2 functionality

If the cause is outside the application's control, such as missing corporate credentials, absent corporate CA certificates, or denied proxy access to SEC domains, do not invent a software fix.

Report the precise environment dependency and the information needed from corporate IT.

## 9. Validate changes

Run the existing automated test suite.

Add focused regression tests for any newly discovered transport defect.

Verify that changes do not affect:

- Filing discovery
- Classification
- Issuance matching
- Deduplication
- Notional extraction
- Checkpointing
- CSV exports

If live SEC connectivity becomes available, run only the bounded connectivity smoke test.

Do not launch Stage 1 or Stage 2 bulk collection automatically.

## 10. Required handoff

Provide a concise report containing:

1. Root cause of the `data.sec.gov` failure.
2. Root cause of the `www.sec.gov` HTTP 407 failure.
3. Whether these failures share a common cause.
4. Effective proxy used by each request.
5. Kerberos authentication status.
6. TLS/certificate verification status.
7. Files modified and why.
8. Automated test results.
9. Actual live connectivity results.
10. Remaining blockers and exact next steps.

Distinguish verified findings from hypotheses.

If a live request has not returned a valid SEC response, do not claim connectivity is working.

**Success criteria: a valid, authenticated-through-proxy HTTPS response from both SEC hosts, with approved TLS validation and a usable SEC JSON response from data.sec.gov.**

Start by inspecting the current transport code and reproducing the two reported failures. Do not rewrite unrelated modules.
