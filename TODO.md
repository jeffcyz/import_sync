# SEC EDGAR Structured Notes Market Intelligence
## Copilot Master Implementation Prompt v3.0
### Two-Stage Extraction, Corporate Kerberos Proxy, Issuance Reconciliation, and Dollar Notional Validation

## 0. ROLE, CONTEXT, AND MISSION

You are a senior Python engineer and financial-data architect specializing in:

- SEC EDGAR APIs and filing documents
- US structured notes and structured products
- Financial issuance analytics
- Enterprise HTTP networking and Kerberos proxy authentication
- Python data extraction and ETL
- Financial data reconciliation and auditability
- Large-volume document processing
- Reproducible research pipelines

I am conducting a structured notes market analysis comparing Citigroup against competing issuers.

I currently have **one existing Python script open in my VS Code workspace**. It was originally prepared to extract SEC structured notes data.

That script is the only existing implementation and project context.

Assume:

- No prior Copilot conversation history.
- No existing repository architecture beyond what is currently present.
- No existing database or external knowledge base.
- No previously implemented SEC client or parser.
- No pre-existing test infrastructure unless discovered in the workspace.

Your assignment is to inspect that script and turn it into a reliable, maintainable, auditable Python project.

**Do not stop at a design document. Implement the actual functionality.**

The resulting system must support two stages.

### Stage 1 — Structured Notes Issuance Identification

Retrieve SEC filing metadata, identify actual structured-note filings, classify preliminary/final/amended documents, reconcile filings belonging to the same issuance, eliminate double counting, and generate a validated unique issuance dataset.

### Stage 2 — Dollar Notional Extraction

Extend Stage 1 by extracting actual issued principal amounts from SEC Pricing Supplements, validating them against the underlying documents, and generating a reliable dollar-notional issuance dataset.

Both stages must use SEC Filing Date for monthly reporting.

Both stages must generate compact CSV outputs suitable for uploading into Stylus.

The primary objective is trustworthy competitor league-table data, not merely successful downloading of filings.

---

# 1. FIXED BUSINESS REQUIREMENTS

## 1.1 Research period

The study period is fixed:

```text
START_DATE = 2025-01-01
END_DATE   = 2026-10-31
```

The dataset must cover exactly 22 calendar months.

Reporting must use:

**SEC Filing Date**

Do not substitute:

- Pricing Date
- Trade Date
- Issue Date
- Settlement Date
- Maturity Date

These secondary dates may be extracted for identification, classification, and reconciliation but must not determine the reporting month.

For every countable issuance event, use the SEC Filing Date of the selected representative filing.

Preserve all related filing dates for auditability.

The reporting cutoff is inclusive through October 31, 2026.

Do not silently include November 2026 filings or use post-cutoff filing information to change the historical results. If later filings are consulted in a separately enabled retrospective mode, preserve that distinction and do not silently change the original as-of reporting basis.

## 1.2 Issuer universe

The existing Python script contains exactly 13 issuer groups:

1. Citigroup
2. JPMorgan
3. Goldman Sachs
4. Morgan Stanley
5. Bank of America
6. Wells Fargo
7. Barclays
8. UBS
9. HSBC
10. RBC
11. TD
12. CIBC
13. Scotiabank

Do not automatically increase this number to 15.

A separate research description mentioned 15 issuers, but the existing source script specifies 13. The additional two were never identified.

Preserve the existing `ISSUER_CIKS` dictionary as the starting configuration.

However, an issuer group may operate through multiple legal issuing entities.

Implement a configurable mapping between:

```text
issuer_group
issuer_legal_entity
filing_cik
primary_issuer_cik
guarantor
```

Use official SEC entity information to validate CIK mappings.

Where appropriate, support multiple confirmed legal-entity CIKs within an issuer group.

Do not invent or silently replace CIKs.

Do not treat the parent company's CIK as automatically representing all issuance subsidiaries.

Record evidence for issuer mappings and flag unverified associations.

Prevent duplicate counting across related filing entities.

## 1.3 Market universe

The initial SEC forms to screen are:

```text
424B2
FWP
```

These are screening candidates, not proof that a filing is a structured note or a final issuance.

The system must distinguish ordinary registered debt securities from eligible structured notes.

Implement configurable form coverage and conservative product classification.

The intended universe is SEC-observable registered structured-note issuance.

Do not claim coverage of unregistered, private-placement, or otherwise non-EDGAR-observable issuance.

---

# 2. CRITICAL: CORPORATE PROXY AND KERBEROS AUTHENTICATION

This section contains an actual proxy implementation previously used successfully in my Citi corporate environment.

**Treat this code as the primary technical reference for the SEC HTTP transport layer.**

Do not replace it with a generic unauthenticated proxy implementation.

Do not assume simply setting `HTTP_PROXY` or `HTTPS_PROXY` is sufficient.

## 2.1 Verified corporate network information

Previously working proxy:

```text
HTTP:
http://webproxy.wlb2.nam.nsroot.net:8080

HTTPS:
http://webproxy.wlb2.nam.nsroot.net:8080
```

Previously working libraries and mechanisms:

```text
requests
requests_kerberos
urllib3
requests.Session
requests.adapters.HTTPAdapter
HTTPKerberosAuth
Proxy-Authorization
```

The proxy uses Kerberos authentication.

The successful implementation relied on overriding the `proxy_headers()` method in a custom Requests HTTPAdapter.

## 2.2 Actual previously working Python proxy code

The following code is taken directly from the relevant proxy portion of my previous working Python request implementation.

It was originally used to access a BNY API in the same corporate network.

**Use this as the reference implementation.**

```python
import requests

from requests_kerberos import HTTPKerberosAuth
from urllib3.util import parse_url


proxies = {
    'http': 'http://webproxy.wlb2.nam.nsroot.net:8080',
    'https': 'http://webproxy.wlb2.nam.nsroot.net:8080'
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

        headers['Proxy-Authorization'] = negotiate_details

        return headers


session = requests.Session()

session.proxies = proxies

session.verify = False

session.mount(
    'https://',
    HTTPAdapterWithProxyKerberosAuth()
)
```

The original implementation also used:

```python
requests.packages.urllib3.disable_warnings()
```

And performed requests through the configured session:

```python
response = session.get(
    request_url,
    headers=headers
)

response.raise_for_status()
```

The original function contained a reusable session-return mechanism:

```python
if return_session:
    return session
```

This allowed the configured session to be reused by other functions.

### Important interpretation

The code above demonstrates the previously functioning authentication mechanism.

The following are essential:

1. `requests.Session()`
2. `session.proxies`
3. Custom `HTTPAdapterWithProxyKerberosAuth`
4. Overridden `proxy_headers()`
5. `HTTPKerberosAuth()`
6. `generate_request_header()`
7. `parse_url(proxy).host`
8. `is_preemptive=True`
9. `Proxy-Authorization`
10. Mounting the custom adapter for HTTPS traffic

Preserve these mechanisms unless actual compatibility testing identifies a necessary change.

Do not silently substitute another authentication mechanism.

If the installed versions of Requests, urllib3, or requests-kerberos require adjustments, document the incompatibility and make the smallest appropriate change while preserving Kerberos proxy authentication.

Do not assume that a successful adapter initialization proves working network authentication.

Actual HTTPS requests must be tested.

## 2.3 TLS certificate verification

The original working script used:

```python
session.verify = False
```

It also disabled urllib3 certificate warnings.

This is part of the original environment history, not a mandatory production security setting.

The new project must:

1. Prefer proper TLS verification.
2. Support an approved corporate CA bundle.
3. Support `REQUESTS_CA_BUNDLE` or an equivalent configuration.
4. Diagnose certificate verification failures clearly.
5. Never disable TLS verification silently.
6. Keep any insecure diagnostic mode explicitly opt-in and disabled by default.
7. Display a warning whenever insecure diagnostic mode is selected.
8. Avoid suppressing unrelated security warnings.

A corporate certificate problem should be distinguished from a Kerberos authentication failure.

The application must never quietly enable `verify=False` merely to make an HTTPS request succeed.

Use corporate-approved security settings and comply with applicable enterprise policies.

## 2.4 Do not copy BNY-specific business headers

The previous BNY implementation contained:

- BNY-specific cookies
- Browser User-Agent values
- BNY Referer
- ADRUM headers
- Browser-only fetch headers
- BNY API URL parameters
- BNY-specific JSON decoding

These are not part of the proxy authentication mechanism.

Do not copy them into the SEC client.

Do not retain or log those cookies.

The SEC application must use its own SEC-compliant headers.

At a minimum:

```python
headers = {
    "User-Agent": SEC_USER_AGENT,
    "Accept": "application/json"
}
```

Set an appropriate Accept header for HTML filings separately.

Use a configurable, real, identifying contact name and email in `SEC_USER_AGENT`.

Do not reuse a fictitious or placeholder contact identity for live collection.

## 2.5 Centralize the session

Create a reusable session factory, for example:

```text
create_sec_session()
```

And an HTTP client abstraction, for example:

```text
SecEdgarClient
```

The client must use the corporate proxy session for:

- Main SEC Submissions JSON
- Historical paginated JSON
- SEC filing documents
- Filing exhibits
- Any other SEC HTTPS request

Do not leave standalone `requests.get()` calls scattered across the codebase.

Do not automatically switch to direct internet access if the configured corporate proxy fails.

Be aware that Requests proxy settings can be affected by environment variables.

Inspect and control proxy precedence so that the intended proxy is used consistently.

Keep Kerberos credentials and generated authentication tokens out of logs.

## 2.6 SEC connectivity tests

Create a dedicated mode:

```text
connectivity
```

It must test both:

```text
https://data.sec.gov
https://www.sec.gov
```

Use legitimate lightweight SEC endpoints, not just a TCP connectivity check.

For example, request valid SEC Submissions JSON for a configured CIK and validate the response structure.

Check:

- HTTP status code
- Content-Type
- JSON validity
- Expected CIK information
- Kerberos proxy authentication
- Certificate verification
- Response duration
- Whether the body is actually SEC data
- Whether the corporate proxy returns an interception or error page

Provide specific diagnostics for:

```text
407 Proxy Authentication Required
403 Forbidden
429 Too Many Requests
SSL Certificate Verification Error
Connection Timeout
Invalid JSON
Unexpected HTML Response
```

A `200 OK` response containing a proxy-generated HTML page must not be treated as successful SEC JSON retrieval.

If live connectivity fails, do not automatically proceed with bulk downloads.

Instead, finish the offline implementation and tests and report the exact blocker.

---

# 3. SEC EDGAR HTTP REQUEST MANAGEMENT

Implement a centralized request manager around the verified proxy-compatible session.

Official references:

```text
https://www.sec.gov/search-filings/edgar-application-programming-interfaces
https://www.sec.gov/about/webmaster-frequently-asked-questions
```

Follow the SEC's published Fair Access guidance.

## 3.1 Rate limiting

The SEC publishes a maximum automated access rate of 10 requests per second.

Do not design the system to operate continuously at that maximum.

Use an initially conservative configurable default of approximately:

```text
2 requests per second
```

Because the corporate proxy may use shared egress IP addresses, do not assume that all available SEC request capacity belongs to this application.

Implement:

- Centralized request throttling
- Low default concurrency
- HTTP timeout settings
- Bounded retries
- Exponential backoff
- Appropriate randomized retry delays
- Support for Retry-After
- Respect for SEC access-denied responses
- Error categorization

Never attempt to bypass SEC rate limits through proxy rotation or changing identities.

## 3.2 Resilience

The pipeline must tolerate interruptions.

Implement:

- Incremental processing
- Request-level checkpoints
- Document-level checkpoints
- Download status tracking
- Failure logs
- Retry queues
- Resume support
- Cached response reuse
- Idempotent processing
- Atomic output writes

A failure after processing thousands of filings must not require starting the entire collection again.

Differentiate temporary network failures from permanent data-quality failures.

---

# 4. PROJECT ARCHITECTURE

Keep the implementation small and maintainable.

Do not build an unnecessarily complex application framework.

Suggested structure:

```text
sec-structured-notes/
|
|-- config/
|   |-- settings.example.yaml
|   |-- issuer_mapping.yaml
|
|-- src/
|   |-- sec_client.py
|   |-- proxy_auth.py
|   |-- filing_index.py
|   |-- document_fetcher.py
|   |-- filing_classifier.py
|   |-- issuance_matcher.py
|   |-- notional_parser.py
|   |-- validator.py
|   |-- exporter.py
|   |-- cli.py
|
|-- tests/
|   |-- fixtures/
|   |-- test_proxy.py
|   |-- test_sec_client.py
|   |-- test_classifier.py
|   |-- test_deduplication.py
|   |-- test_notional.py
|   |-- test_export.py
|
|-- data/
|   |-- cache/
|   |-- state/
|   |-- output/
|   |-- reports/
|
|-- requirements.txt
|-- README.md
|-- .gitignore
```

This structure is illustrative, not mandatory.

Do not add empty placeholder modules merely to match the example.

Use clear module responsibilities and minimize unnecessary dependencies.

A lightweight local SQLite database is acceptable for persistent processing state, filing relationships, and checkpoint management.

Raw cached data and output files should be excluded from Git unless explicitly required.

---

# 5. STAGE 1 — FILING INDEX DISCOVERY

## 5.1 Objective

Fetch filing metadata for all configured legal-entity CIKs across the 22-month period.

Use the official SEC Submissions API.

Example endpoint:

```text
https://data.sec.gov/submissions/CIK##########.json
```

Support:

- Recent submissions
- Paginated historical submissions
- Filing Date filtering
- Form Type filtering
- Primary Document retrieval metadata
- Accession Number preservation
- Document URL construction
- Duplicate accession reconciliation

## 5.2 Historical pagination

The SEC Submissions JSON may reference historical files through:

```text
filings.files
```

Retrieve relevant historical pages where necessary.

Use available pagination metadata to avoid downloading irrelevant historical pages whenever possible.

Do not assume that the main recent filings block covers the full requested period.

Do not assume that all historical filings are returned in a single API response.

## 5.3 Mandatory original metadata

Preserve at least:

```text
issuer_group
issuer_legal_entity
cik
filing_date
form_type
accession_number
primary_document
primary_document_description
acceptance_datetime
sec_url
source_json_url
```

Preserve additional useful SEC metadata where available.

Keep the initial raw filing inventory before classification and deduplication.

The raw inventory must be recoverable for auditing.

## 5.4 Filing-level deduplication

Reconcile duplicate retrievals of the same accession.

Use SEC accession identifiers and filer relationships appropriately.

A duplicated retrieval should not become two filings.

However, records from different accession numbers must not be merged merely because they share a CUSIP or document name.

Never merge missing-CUSIP filings based only on null values.

---

# 6. STAGE 1 — STRUCTURED NOTES CLASSIFICATION

The original script only filters SEC forms.

That is insufficient for the intended league table.

**Stage 1 must identify structured-note issuance events, not merely count SEC filing submissions.**

This requires selective inspection of actual filing documents.

Stage 1 is therefore a classified-filing pipeline rather than a strictly index-only pull.

## 6.1 Selective document retrieval

Retrieve the relevant primary document or supporting SEC document when classification requires it.

Avoid indiscriminate downloading of all large filing content.

Prioritize documents using:

- SEC Form Type
- Primary Document Description
- Document title
- Structured-note product terms
- Preliminary/final indicators
- Amendment relationships
- Available document metadata

Use deterministic, explainable classification rules.

Retain the source URL and evidence supporting each classification.

## 6.2 Classification categories

Implement at least:

```text
FINAL
PRELIMINARY
AMENDED_PRELIMINARY
AMENDED_FINAL
FWP_ONLY
NON_STRUCTURED
DUPLICATE
REVIEW_REQUIRED
```

Make the classifications mutually understandable and document their definitions.

A 424B2 filing is not automatically FINAL.

A FWP filing is not automatically a separate issuance.

A document identified as Preliminary must not be counted as a confirmed issuance merely because it has a CUSIP.

## 6.3 Structured-note product identification

Implement conservative recognition of common structured-note categories, including where supported by filing evidence:

- Equity-linked notes
- Index-linked notes
- Interest-rate-linked notes
- Credit-linked structured notes
- Commodity-linked notes
- Currency-linked notes
- Autocallable notes
- Contingent coupon notes
- Buffered notes
- Barrier notes
- Other structured debt instruments

Do not treat all registered debt securities as structured notes.

Do not automatically exclude an unusual eligible instrument solely because its title differs from a familiar template.

Support issuer-specific classification rules where justified.

Preserve:

```text
product_category
filing_classification
classification_rule
classification_confidence
classification_evidence
review_reason
```

Confidence must represent transparent rule-based evidence quality.

Do not invent statistically calibrated probabilities.

---

# 7. STAGE 1 — ISSUANCE-LEVEL DEDUPLICATION

This is a critical business requirement.

We need two separate quantities:

```text
Raw Filing Count
Unique Structured Notes Issuance Count
```

They are not interchangeable.

## 7.1 Identify the economic issuance

Use combinations of:

```text
Issuer Legal Entity
CUSIP
Pricing Date
Issue Date
Product Name
Series
Tranche
Security Identifiers
Accession Relationships
Final/Preliminary Relationships
```

An issuance may have multiple associated filings.

One filing may also contain multiple instruments.

Design the data model to support many-to-many filing/instrument relationships where required.

## 7.2 Mandatory deduplication rules

1. Preliminary and final filings for the same issuance must not be counted separately.

2. Multiple amended preliminary filings generally represent the same prospective issuance.

3. A FWP and Final Pricing Supplement for the same security must not automatically become separate issuances.

4. Multiple final filings must be reconciled using actual document relationships and security identifiers.

5. Missing CUSIPs must not cause unrelated filings to merge.

6. One filing containing multiple CUSIPs may represent multiple issuance events.

7. The same CUSIP may be used in distinct reopening or additional-issuance events.

8. Multiple related legal entities must not inflate group-level issuance counts.

9. Uncertain matches must be flagged for review rather than forcibly merged.

10. Maintain an explicit filing-to-issuance relationship table.

## 7.3 Deterministic issuance IDs

Generate a stable:

```text
issuance_id
```

The identifier must be reproducible from source-backed information.

Never generate a shared issuance identifier using null CUSIPs or other missing fields as if they were meaningful matching keys.

Ambiguous records may receive temporary internal identifiers but must remain marked unresolved.

## 7.4 Representative filing

For each confirmed issuance, select an appropriate representative filing.

Prefer a source-backed final filing that confirms the issuance.

Use the representative filing's SEC Filing Date for the reporting month.

Do not silently use Pricing Date or Settlement Date.

Preserve:

```text
representative_accession_number
representative_filing_date
related_accessions
issuance_id
```

Where the representative filing is uncertain, flag the record for review.

For filings near month or study-period boundaries, preserve the exact filing relationships and cutoff treatment.

Do not silently count a preliminary October filing as a confirmed October issuance because the final document was filed in November.

## 7.5 Counting flags

Provide:

```text
raw_filing_count_flag
unique_issuance_count_flag
include_in_stage1
duplicate_of
review_reason
```

Each original filing may contribute at most once to raw filing count within its proper reporting scope.

Each confirmed issuance event may contribute at most once to unique issuance count.

Do not allow one issuance with multiple related filing records to inflate the result.

Do not treat uncertain records as confirmed issuance events.

---

# 8. STAGE 1 CSV OUTPUT

Produce:

```text
structured_notes_stage1_202501_202610.csv
```

This should be the main Stage 1 file uploaded to Stylus.

Include sufficient information to calculate:

- Monthly Raw Filing Count
- Monthly Structured-Note Candidate Count
- Monthly Confirmed Unique Issuance Count
- Monthly Preliminary Filing Count
- Monthly Duplicate Filing Count
- Monthly Excluded Non-Structured Filing Count
- Monthly Review-Required Count
- Issuer-Level Classification Coverage
- Issuer-Level Reconciliation Statistics

Preserve source-level detail and counting flags.

Do not pre-aggregate away all SEC accession information.

Ensure each counted filing and issuance can be traced back to its source.

### Important distinction

If a large number of filings remain unresolved, do not call the confirmed issuance count a complete census.

Provide coverage metrics and unresolved counts.

The Stage 1 CSV must remain usable even if Stage 2 is not executed.

---

# 9. STAGE 2 — DOLLAR NOTIONAL EXTRACTION

Stage 2 must build on the completed Stage 1 dataset.

Do not restart the whole discovery process unnecessarily.

Do not duplicate downloads already completed and cached.

## 9.1 Main objective

Extract actual structured-note issuance amounts from relevant SEC documents.

The resulting Stage 2 dataset must support a Dollar Notional League Table.

## 9.2 Supported source documents

Inspect relevant:

- Final Pricing Supplements
- Relevant HTML filing documents
- Structured HTML tables
- Supporting exhibits
- Other public SEC filing formats when practical

Use structured parsing where possible.

Prefer HTML-aware parsing, for example BeautifulSoup or pandas HTML table processing where appropriate.

Avoid relying exclusively on raw HTML regex matching.

Use targeted issuer-specific parsing rules where needed.

## 9.3 Amount terminology

Support extraction of:

```text
Aggregate Principal Amount
Aggregate Principal Amount of Notes
Principal Amount of Notes Offered
Total Principal Amount
Total Amount Issued
Number of Notes
Denomination per Note
```

And issuer-specific variations.

Distinguish carefully between:

- Actual final issuance amount
- Note denomination
- Number of notes
- Preliminary offering amount
- Maximum offering amount
- Program or shelf amount
- Outstanding principal
- Aggregate amount across multiple securities
- Incremental amount for a reopening

### Critical example

If a Pricing Supplement says:

```text
Principal Amount per Note: $1,000
Number of Notes: 25,000
Aggregate Principal Amount: $25,000,000
```

The issuance notional is:

```text
$25,000,000
```

Not:

```text
$1,000
```

Never confuse per-note denominations with total issuance.

If the aggregate amount is absent but a supported calculation from final, clearly identified note quantity and denomination is available, record the calculation method and source evidence.

Do not invent a quantity or infer issuance size from unsupported assumptions.

## 9.4 Final versus preliminary amounts

Prefer amounts supported by final pricing documentation.

Do not treat indicative or preliminary notional as verified issuance.

If only preliminary amounts exist, mark the amount unresolved.

Do not assign zero merely because final notional is unavailable.

## 9.5 Multiple CUSIPs and tranches

One SEC document may contain several securities.

Support separate issuance-event and tranche-level records where necessary.

Do not assign an entire multi-tranche aggregate amount to each CUSIP.

Where allocation cannot be determined, flag for review.

## 9.6 Reopenings and additional issuances

Distinct additional issuance events must be handled carefully.

If a note is reopened or additional notes are issued under an existing CUSIP, do not automatically discard the additional issuance merely because the CUSIP already exists.

Distinguish:

```text
Original Issuance
Additional Issuance
Reopening
Amendment
Duplicate Filing
```

Record incremental notional where reliable source evidence supports it.

Never count the same principal amount twice.

## 9.7 Currency

Preserve:

```text
principal_amount_original
currency
principal_amount_usd
fx_method
fx_rate_date
currency_validation_status
```

Do not assume every note is USD-denominated.

Do not silently convert foreign-currency amounts.

Use only a documented, explicitly enabled FX methodology if conversion is required.

Otherwise, keep non-USD issuance separate and exclude it from confirmed USD notional totals.

Use Decimal arithmetic for monetary values.

---

# 10. STAGE 2 — NOTIONAL VALIDATION

Implement a transparent validation framework.

Supported statuses:

```text
VALIDATED
REVIEW_REQUIRED
EXCLUDED
NOT_AVAILABLE
```

## 10.1 Required validation checks

Confirm:

1. The source document belongs to the correct issuer.

2. The filing corresponds to the correct issuance.

3. The amount represents an actual issued or confirmed aggregate principal.

4. The amount is not a per-note denomination.

5. The amount is not an unrelated program or shelf size.

6. Multiple monetary values within a document have been distinguished.

7. Currency is known.

8. The source is final or otherwise sufficient to confirm issuance.

9. Reopenings and additional issues are correctly identified.

10. Multiple filings do not duplicate the same notional.

11. Multi-tranche amounts are not incorrectly allocated.

12. The amount is reproducible from cited source evidence.

If validation fails or information is insufficient, mark the record for review.

Do not silently force a number into the final total.

## 10.2 Audit evidence

Preserve:

```text
amount_source_url
amount_source_accession
amount_source_document
amount_raw_text
amount_extraction_rule
principal_amount_original
currency
principal_amount_usd
amount_validation_status
review_reason
```

Store large source excerpts locally where necessary rather than inflating the Stylus CSV.

Use compact evidence references in the export.

## 10.3 Notional counting flag

Provide:

```text
notional_count_flag
```

Each confirmed economic issuance event should contribute its validated incremental amount exactly once.

If multiple records refer to the same amount, only the appropriate counting record should contribute to the aggregate.

Unresolved amounts must not become confirmed totals.

---

# 11. STAGE 2 CSV OUTPUT

Produce:

```text
structured_notes_stage2_202501_202610.csv
```

The Stage 2 CSV should enrich the Stage 1 dataset with notional-related information.

Preserve the same issuer universe and research period.

Do not unexpectedly change the classification or counting logic between stages.

Recommended fields include:

```text
issuer_group
issuer_legal_entity
cik
filing_date
filing_month
form_type
accession_number
sec_url
product_name
product_category
cusip
pricing_date
issue_date
issuance_id
representative_accession_number
filing_classification
classification_rule
classification_confidence
duplicate_of
raw_filing_count_flag
unique_issuance_count_flag
include_in_stage1
principal_amount_original
currency
principal_amount_usd
amount_type
amount_source_url
amount_extraction_rule
amount_validation_status
notional_count_flag
include_in_stage2
review_reason
```

You may extend this schema where necessary.

Maintain clear definitions for all count flags.

Avoid unnecessary duplicate columns or large free-text blobs.

The output must allow Stylus to calculate:

- Monthly Issuer Notional
- Monthly Market Share
- Issuer Rankings
- Issuance Count
- Average Validated Notional per Issuance
- Notional Coverage
- Missing/Unresolved Amount Counts

Do not present incomplete verified-notional totals as complete market issuance volume without qualification.

---

# 12. DATA STORAGE, CACHE, AND RESUME

Stage 2 could require substantial SEC document retrieval.

A previous high-level estimate suggested potentially 10–40 GB of raw HTML, but that figure has not been empirically validated.

Do not treat it as a proven requirement.

Design for efficient incremental processing.

## 12.1 Local storage

Use an organized local structure for:

```text
cache
state
output
reports
logs
```

Use SQLite or a comparable lightweight state store where beneficial.

Avoid holding all downloaded HTML documents in memory simultaneously.

## 12.2 Cache behavior

Cache downloaded SEC metadata and source files.

Use stable source identifiers.

Avoid downloading the same document multiple times.

Support:

- Cache reuse
- Incremental updates
- Disk usage reporting
- Configurable cache retention
- Optional cache cleanup
- Controlled reprocessing
- Resume after interruption

Do not delete raw files or audit evidence required for an in-progress validation run without appropriate confirmation or a documented retention policy.

## 12.3 Execution determinism

The same source data and configuration should produce identical classifications, issuance IDs, count flags, and financial totals.

Maintain execution metadata, including:

```text
run_id
run_timestamp
configuration_version
classifier_version
parser_version
source_cutoff
```

Avoid nondeterministic output ordering.

---

# 13. MONTHLY RECONCILIATION

Provide a local reconciliation report for every issuer and every month in the 22-month period.

Include months with no confirmed activity.

## Stage 1 metrics

```text
raw_filing_count
structured_candidate_count
confirmed_unique_issuance_count
preliminary_count
duplicate_count
non_structured_count
review_required_count
classification_coverage
```

## Stage 2 metrics

```text
validated_issuance_count
validated_usd_notional
missing_notional_count
review_required_notional_count
excluded_notional_count
non_usd_issuance_count
notional_validation_coverage
```

## Reconciliation requirements

Provide a documented bridge from:

```text
Raw SEC Filings
       |
       v
Relevant Filing Candidates
       |
       v
Classified Structured Notes
       |
       v
Unique Issuance Events
       |
       v
Validated Dollar Notional
```

Each reduction or exclusion must have an explicit reason.

Prevent double counting when one filing contains multiple instruments or multiple filings correspond to the same issuance.

Never interpret failed retrievals as zero activity.

If data collection is incomplete, flag the relevant issuer-month as incomplete.

---

# 14. AUTOMATED TESTING

Implement tests using `pytest`.

All core logic must be testable without live SEC network access.

Create representative local fixtures.

Do not require the corporate proxy or Kerberos credentials to run offline unit tests.

## 14.1 Proxy and HTTP tests

Test:

- Proxy settings
- Session configuration
- Adapter mounting
- Kerberos authentication initialization
- Proxy header behavior using safe mocks
- HTTP 407
- HTTP 403
- HTTP 429
- TLS verification failures
- Timeouts
- Retry logic
- Checkpoint recovery
- Unexpected HTML responses

Never include live Kerberos tickets or secrets in tests.

## 14.2 SEC metadata tests

Test:

- Recent Submissions JSON
- Historical pagination
- Empty filing lists
- Missing optional fields
- Incorrect or invalid dates
- Duplicate accession records
- Start and end date boundaries
- Multiple legal-entity mappings

## 14.3 Classification tests

Test:

- Final 424B2
- Preliminary 424B2
- Amended Preliminary
- Amended Final
- FWP linked to Final
- Non-structured 424B2
- Uncertain filing
- Incorrectly identified product title

## 14.4 Deduplication tests

Test:

- Same CUSIP with Preliminary and Final
- Multiple amendments
- Multiple CUSIPs within one document
- Same CUSIP with separate additional issuance
- Missing CUSIP
- Multiple legal entities
- Cross-month filing relationships
- Final filing outside the reporting cutoff
- Conflicting identification evidence

## 14.5 Notional tests

Test:

- $1,000 denomination versus $25 million total
- Multiple amounts in a document
- HTML tables
- Missing notional
- Preliminary-only amount
- Multiple tranches
- Non-USD instruments
- Reopenings
- Conflicting final amounts
- Duplicated amounts from related filings

## 14.6 Output tests

Test:

- CSV schema
- Required fields
- Stable issuance IDs
- Stable count flags
- Monthly aggregation
- Exact date boundaries
- Deterministic output
- Missing-value handling
- No double-counted issuance notional

Create one end-to-end fixture that produces both Stage 1 and Stage 2 output.

Do not claim tests passed unless they actually executed.

---

# 15. COMMAND-LINE INTERFACE

Provide a simple CLI.

Suggested modes:

```text
connectivity
index
classify
notional
validate
export
all
```

Example usage should be documented in README using the actual implemented CLI syntax.

Support configuration for:

- Selected Issuer Groups
- Date Range
- Sample Mode
- Maximum Number of Documents
- Resume Mode
- Force Refresh
- Output Directory
- Cache Directory
- Proxy Configuration
- SEC User-Agent
- CA Certificate Bundle
- TLS Diagnostic Mode
- Logging Level

The default research window must remain:

```text
2025-01-01 through 2026-10-31
```

Use explicit full-run commands.

Do not start an unrestricted full historical download simply because the application is executed with no arguments.

Before a full run, display:

```text
Issuer Group Count
Legal Entity / CIK Count
Date Range
Selected Forms
Current Cache Coverage
Planned Stage
Output Directory
Known Request Estimates
```

Do not present unmeasured runtime estimates as guaranteed.

---

# 16. IMPLEMENTATION SEQUENCE

Implement the project in the following order.

## Phase A — Existing script inspection

1. Inspect the currently open Python source file.
2. Identify the current SEC extraction functionality.
3. Identify its CIK configuration.
4. Identify date filtering and pagination behavior.
5. Identify document download and parsing logic.
6. Identify current CSV outputs and deduplication assumptions.
7. Preserve a recoverable copy of the original script.
8. Document the main defects and planned improvements.

Do not unnecessarily delete useful existing logic.

## Phase B — Corporate Proxy integration

1. Implement the reusable SEC HTTP session.
2. Use the actual Kerberos proxy reference code provided in Section 2.
3. Preserve the working custom adapter approach.
4. Add configurable SEC headers.
5. Add corporate CA bundle support.
6. Add timeout, retry, and rate limiting.
7. Add diagnostic error handling.
8. Implement connectivity mode.
9. Run offline HTTP tests.
10. If available and authorized, run a limited live SEC connectivity test.

The successful BNY implementation is evidence that this authentication approach worked in the earlier environment.

It is not proof that the SEC endpoints are currently reachable.

## Phase C — Stage 1 implementation

1. Implement Submissions API retrieval.
2. Implement historical pagination.
3. Validate CIK assignments.
4. Build the raw filing inventory.
5. Apply exact date and form filters.
6. Implement selective document retrieval.
7. Implement Structured Notes classification.
8. Implement Preliminary/Final/Amendment relationships.
9. Implement unique issuance matching.
10. Implement safe deduplication.
11. Implement count flags.
12. Generate the Stage 1 CSV.
13. Generate monthly reconciliation.
14. Run all Stage 1 tests.

## Phase D — Stage 2 implementation

1. Reuse Stage 1 records and cached documents.
2. Implement final pricing document retrieval.
3. Implement HTML-aware extraction.
4. Implement issuer-specific parsing rules.
5. Extract principal amount and currency.
6. Reconcile multiple amounts.
7. Handle multiple tranches.
8. Handle reopenings.
9. Validate actual issuance notional.
10. Implement notional count flags.
11. Generate the Stage 2 CSV.
12. Generate notional reconciliation.
13. Run all Stage 2 tests.

## Phase E — Controlled integration validation

After completing offline tests:

1. Test SEC connectivity.
2. Select one issuer and one month.
3. Retrieve actual SEC filings within a bounded request budget.
4. Validate classification against real documents.
5. Validate unique issuance counting.
6. Validate several principal amounts against source documents.
7. Review discrepancies.
8. Correct rules and rerun affected tests.

Do not automatically launch the full 13-issuer / 22-month collection.

## Phase F — Complete implementation and handoff

Produce:

```text
README.md
requirements.txt
Example configuration
Issuer mapping
Stage 1 implementation
Stage 2 implementation
CLI
Automated tests
CSV schemas
Reconciliation methodology
Proxy troubleshooting instructions
Known limitations
```

Use a modest dependency set.

Prefer compatibility with the existing local Python environment.

If Python 3.8 compatibility is required, identify any required adjustments; otherwise prefer a currently supported Python version.

---

# 17. DATA-INTEGRITY RULES

The following are non-negotiable.

1. Never fabricate filing data.
2. Never fabricate CUSIPs.
3. Never fabricate principal amounts.
4. Never treat all 424B2 filings as valid structured-note issuances.
5. Never treat all FWPs as separate issuances.
6. Never collapse all missing-CUSIP records.
7. Never assume one CUSIP always means one issuance event.
8. Never assume one filing contains only one security.
9. Never infer actual issuance size from typical denominations.
10. Never treat preliminary amounts as validated notional.
11. Never double-count final and amended filings.
12. Never double-count issuances across legal entities.
13. Never silently replace missing financial values with zero.
14. Never convert non-USD amounts without a defined FX methodology.
15. Never remove source lineage from analytical records.
16. Never classify uncertain cases as validated simply to produce complete totals.
17. Never change SEC Filing Date as the reporting basis.
18. Never add unidentified issuers to the original universe.
19. Never claim that all US structured-note issuance is captured by EDGAR.
20. Never report successful connectivity or tests without executing them.

Preserve unresolved cases and quantify their effect on data coverage.

Accuracy and traceability are more important than producing apparently complete output.

---

# 18. EXPECTED FINAL DELIVERABLES

The final project must provide:

### Deliverable A — Working Python SEC EDGAR extractor

Includes:

- Corporate Kerberos Proxy support
- SEC API access
- HTTP request management
- Historical pagination
- Classification
- Issuance reconciliation
- Notional extraction
- Data validation
- Checkpointing
- Resume
- CLI

### Deliverable B — Stage 1 CSV

```text
structured_notes_stage1_202501_202610.csv
```

Contains source-backed filing classification and unique issuance counting.

### Deliverable C — Stage 2 CSV

```text
structured_notes_stage2_202501_202610.csv
```

Contains validated structured-note issuance amounts and associated evidence.

### Deliverable D — Reconciliation reports

Provide monthly issuer-level bridges between:

```text
Raw Filings
Structured Note Candidates
Confirmed Unique Issuances
Validated Notional
```

### Deliverable E — Automated tests

All relevant tests must be executable locally.

Report actual test results and limitations.

### Deliverable F — Documentation

Document:

- Windows/VS Code setup
- Installation of required Python libraries
- Citi proxy configuration
- Kerberos authentication
- Corporate CA configuration
- SEC User-Agent configuration
- Connectivity testing
- Stage 1 execution
- Stage 2 execution
- Resume after interruption
- CSV field definitions
- Classification rules
- Deduplication rules
- Financial validation rules
- Known data limitations

---

# 19. FINAL EXECUTION INSTRUCTIONS

You are operating in VS Code Copilot Agent Mode.

Begin by inspecting the existing Python file.

Then implement the complete project, starting with the verified proxy/Kerberos transport mechanism supplied in this prompt.

Do not ask for the original BNY source file; the required proxy implementation is included above.

Do not copy unrelated BNY headers or cookies.

Do not substitute a generic authentication method without technical justification.

Implement both stages.

Work incrementally and run automated tests after each major component.

Keep project files small, organized, and maintainable.

Avoid creating excessive reports, duplicated documentation, or unnecessary dependencies.

Do not silently launch an unrestricted production data collection.

If SEC connectivity is unavailable, complete the implementation and offline tests, then document the blocker and provide the exact local command for the connectivity test.

If actual SEC sample documents are accessible, validate the parser against them.

Do not present fixture-generated data as real SEC output.

**Continue implementation until both Stage 1 and Stage 2 code, tests, CLI, configuration, and documentation are complete, or until a concrete environment blocker prevents further work.**

At the end, provide a concise handoff covering:

1. Files created or modified.
2. Verified proxy integration status.
3. Test execution results.
4. Stage 1 functionality.
5. Stage 2 functionality.
6. Actual sample-run results, if available.
7. Remaining limitations.
8. Exact commands to run connectivity, a small sample, Stage 1, and Stage 2.

The final system must deliver a defensible SEC EDGAR Structured Notes market-intelligence dataset that can support competitor issuance-count and dollar-notional league tables.

**Correctness, reproducibility, source evidence, and auditability take priority over apparent completeness.**
