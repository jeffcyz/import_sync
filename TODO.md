ASAP2 Parameter Management — Business Scenarios and Expected Handling

Purpose

This document illustrates how an ASAP2 deal script may receive, derive, transform, reuse, or override input values across Global Functions, runtime objects, and class instances. Each scenario includes an illustrative code example, what an analyst should see, and the expected business handling.

Scope: Requirements and expected user experience, illustrated with Python/ASAP2-style snippets. This is not an implementation specification.

Important distinctions:

• Existing ASAP2 capabilities referenced here: gf Global Function calls, deal and deal.setup, deal.periodics[period], payment_inputs[name].InputValue, deal.get_index_value(), symbols[period] in supported scripts, periodic calculation data, and Global Function debugging.
• Proposed capabilities, not confirmed as existing ASAP2 APIs: the Deal Settings table accessed as deal.params["MaxRate"], parameter discovery, cross-function comparison, analyst confirmation, source-to-result lineage, and impact reporting.
• Illustrative functions: Fa, Fb, CalculateCoupon, ValidateCoupon, RateManager, and similar custom names are examples, not documented ASAP2 built-ins. Rates, balances, and thresholds below are hypothetical.
• Terminology: configured value means a maintained business setting; received value means what a particular function call receives; effective value means what the function ultimately uses. These values may legitimately differ.

1. Summary of the Four Categories

|Category                      |Main question                                                         |Typical owner                        |Required management                                                   |
|------------------------------|----------------------------------------------------------------------|-------------------------------------|----------------------------------------------------------------------|
|**1. Configurable Inputs**    |What must an analyst set or approve for this deal?                    |Deal setup / analyst                 |Maintain values, scope, confirmation, and copy behavior               |
|**2. System / Runtime Inputs**|What does ASAP2 supply at the relevant processing step?               |Existing system and periodic workflow|Identify exact source, deal, bond/asset, period, and availability     |
|**3. Derived Inputs**         |Where was this value calculated, and where does it go next?           |Calculations and Global Functions    |Trace upstream inputs, transformations, and downstream consumers      |
|**4. Function / Class State** |What does this specific function call or object instance actually use?|Function logic / runtime state       |Distinguish defaults, explicit arguments, overrides, and state changes|

Fundamental business rule: Two parameters named MaxRate are not automatically the same parameter. Conversely, two different function arguments may legitimately reference one shared Deal Settings value. A difference is an error only when the applicable business rule requires the values to agree.

────────

2. Category 1 — Configurable Inputs

Values that the business intends to maintain at deal setup, typically with analyst confirmation. They should not be confused with every local variable or Global Function argument found in code.

C1. One deal-level setting used by one function

Business situation: An RMBS deal has a contractual coupon cap of 5%.

# Proposed Deal Settings value:
# MaxRate = 5.0, unit = percent

coupon_cap = deal.params["MaxRate"]
result = gf.Fa(MaxRate=coupon_cap)

Expected handling:

• Show one MaxRate row in Deal Settings with value 5.0, unit percent, and analyst confirmation.
• Show Fa.MaxRate as a consumer of that row.
• Flag a missing value or incompatible type before setup validation completes.

C2. Two functions share the same setting

Business situation: Both coupon calculation and coupon validation must use the same contractual cap.

max_rate = deal.params["MaxRate"]  # 5.0

coupon = gf.Fa(MaxRate=max_rate)
check = gf.Fb(MaxRate=max_rate)

Expected handling:

• Maintain one Deal Settings value, not separate Fa.MaxRate and Fb.MaxRate configuration rows.
• Show two usage records: Fa.MaxRate <- deal.params["MaxRate"] and Fb.MaxRate <- deal.params["MaxRate"].
• If the analyst changes MaxRate, list both functions as potentially affected.

C3. Same parameter name, intentionally different business meanings

Business situation: Fa.MaxRate is a bond coupon cap; Fb.MaxRate is a separate index-rate cap.

# Two distinct approved business settings:
# CouponMaxRate = 5.0%
# IndexMaxRate  = 7.0%

gf.Fa(MaxRate=deal.params["CouponMaxRate"])
gf.Fb(MaxRate=deal.params["IndexMaxRate"])

Expected handling:

• Display both underlying business settings and their distinct purposes.
• Compare the two MaxRate arguments without merging them by name.
• Mark the relationship INDEPENDENT; different values are permitted.
• Do not force the design to use function-specific parameter keys if general-purpose business names are clearer.

C4. Same business rule, inconsistent input sources

Business situation: Both functions should use the deal cap, but one call hardcodes a different value.

# Deal Settings: MaxRate = 5.0%

gf.Fa(MaxRate=deal.params["MaxRate"])
gf.Fb(MaxRate=7.0)  # Different source and value

Expected handling:

• Display Fa: source = Deal Settings, received value = 5.0%.
• Display Fb: source = hardcoded literal, received value = 7.0%.
• If the two are declared MUST_MATCH, flag a configuration inconsistency.
• Provide the exact script/function usage and the value requiring review; do not silently replace 7.0.

C5. Different bond-level limits within one deal

Business situation: Senior and subordinate tranches have different contractual caps.

# Proposed general-purpose Deal Settings keys:
# A1MaxRate = 5.0%
# B1MaxRate = 6.0%

gf.Fa(bond=bonds["A1"], MaxRate=deal.params["A1MaxRate"])
gf.Fa(bond=bonds["B1"], MaxRate=deal.params["B1MaxRate"])

Expected handling:

• Keep the settings separate by bond/class applicability.
• Show that the same Global Function is invoked twice with different bond and parameter bindings.
• Compare them as different scope, not as conflicting deal-wide values.
• Identify which bonds are covered and whether any required class lacks a cap.

C6. Time-dependent deal configuration

Business situation: A cap changes from 5% to 6% beginning with payment period 25.

# Proposed Deal Settings:
# InitialMaxRate = 5.0
# StepUpMaxRate  = 6.0
# StepUpPeriod   = 25

if period < deal.params["StepUpPeriod"]:
    max_rate = deal.params["InitialMaxRate"]
else:
    max_rate = deal.params["StepUpMaxRate"]

gf.Fa(MaxRate=max_rate)

Expected handling:

• Confirm all three settings and the contractual effective-period rule.
• Display the applicable value for the selected period, not only the two stored values.
• Show that period 24 and period 25 legitimately use different caps.
• Flag missing step-up settings before they are needed by the applicable workflow.

C7. Missing, unconfirmed, or invalid deal settings

Business situation: The script references MaxRate, but setup is incomplete.

# A required configured value is referenced by a function:
gf.Fa(MaxRate=deal.params["MaxRate"])

Expected handling:

• Distinguish MISSING (no configured entry), UNCONFIRMED (value exists, analyst has not approved), and INVALID (wrong type/unit/range).
• Do not treat 0 or False as missing solely because they are falsy.
• Allow analysts to review the affected consumers before confirming the setting.
• Apply agreed blocking/warning rules rather than treating every finding as a fatal error.

C8. Copy Deal Info to a new deal

Business situation: Deal B is created from Deal A, which has MaxRate = 5.0%.

# Illustrative data after a Copy Deal Info operation:
# Deal A: deal.params["MaxRate"] = 5.0
# Deal B: deal.params["MaxRate"] = 5.0  (copied value)

Expected handling:

• Include the proposed Parameters table in Copy Deal Info.
• Preserve parameter name, value, type, unit, scope, and applicable effective-period rules.
• Clearly identify copied/inherited values in Deal B.
• Require a new analyst confirmation for Deal B; do not automatically carry over Deal A’s approval.

────────

3. Category 2 — System / Runtime Inputs

Values already supplied by ASAP2 deal, setup, bond, collateral, market, or periodic-processing objects. The management task is to verify source, scope, timing, and availability, not to add every field to Deal Settings.

S1. Read-only deal metadata

Business situation: The script applies rules based on the deal’s first payment date and shelf.

first_pay_date = deal.FirstPayDate
shelf_name = deal.Shelf

# Illustrative rule, not an ASAP2 built-in:
result = gf.Fa(first_pay_date=first_pay_date, shelf=shelf_name)

Expected handling:

• Classify both inputs as ASAP2 Deal Fields, not deal.params.
• Show their source as deal.FirstPayDate and deal.Shelf.
• Trace which function consumes them; direct any corrections to the established Deal Setup process.

S2. Deal setup versus periodic data

Business situation: A validation compares original balance to the current outstanding balance.

original_balance = deal.setup.OrigBal
current_balance = deal.periodics[period].EndSchBal

check = gf.Fa(
    original_balance=original_balance,
    current_balance=current_balance
)

Expected handling:

• Identify Deal Setup and Deal Periodic as different source categories.
• Preserve the selected period for EndSchBal.
• Avoid creating editable Deal Settings duplicates of existing system fields.

S3. Current versus prior-period values

Business situation: A balance-roll validation needs data from periods 64 and 65.

prior_end_balance = deal.periodics[period - 1].EndSchBal
current_end_balance = deal.periodics[period].EndSchBal

gf.Fa(
    prior_balance=prior_end_balance,
    current_balance=current_end_balance
)

Expected handling:

• Display EndSchBal / Period 64 and EndSchBal / Period 65 as separate source records.
• Clearly identify relative-period references (period - 1 versus period).
• Do not flag different balances as a parameter conflict simply because the field name matches.

S4. Required payment input is missing

Business situation: An analyst has not populated a required payment input for the current payment date.

# Documented ASAP2-style object access:
amount = payment_inputs["PayInNumR"].InputValue

# Illustrative consuming function:
gf.Fa(payment_amount=amount)

Expected handling:

• Classify the value as a Payment Input, not a new deal-level configuration parameter.
• Show the payment date and whether the input is required.
• Flag None when the required input is unavailable at the relevant processing step.
• Keep this as a period-readiness check even when deal setup was validated earlier.

Source nuance: ASAP2 documents that missing non-required Payment Inputs can default to 0, False, or None, while missing required inputs can return None and block Generate Bond Payment. The result depends on processing step and field type.

S5. Optional payment input legitimately defaults to zero

Business situation: No optional expense adjustment was submitted this month.

optional_amount = payment_inputs["PayInNum"].InputValue

gf.Fa(expense_adjustment=optional_amount)

Expected handling:

• Show 0 as a legitimate system-provided default when the input definition permits it.
• Differentiate DEFAULT_APPLIED from MISSING_REQUIRED.
• Do not create false errors for valid zero-valued inputs.

S6. Same index, different source selection

Business situation: Two functions obtain SOFR using different sourcing rules.

rate_deal = deal.get_index_value("SOFR", deal_level=True)
rate_global = deal.get_index_value("SOFR", deal_level=False)

gf.Fa(index_rate=rate_deal)
gf.Fb(index_rate=rate_global)

Expected handling:

• Show SOFR / Deal-level source for Fa and SOFR / Global-level source for Fb.
• Display the index date and payment-date context when available.
• Highlight differences in sourcing configuration without assuming that different rates are errors.
• Note that deal_level=False is the documented default of deal.get_index_value().

S7. Currency conversion depends on direction and scope

Business situation: Two functions request the same currency conversion but with different flags.

rate_a = deal.get_currency_conversion_rate(
    "USD_EUR", deal_level=True, is_src_to_dest=True
)
rate_b = deal.get_currency_conversion_rate(
    "USD_EUR", deal_level=False, is_src_to_dest=False
)

gf.Fa(fx_rate=rate_a)
gf.Fb(fx_rate=rate_b)

Expected handling:

• Display both source scope (deal/global) and conversion direction.
• Treat different results as expected unless their specified business relationship requires a match.
• Do not infer that matching conversion names imply identical inputs.

────────

4. Category 3 — Derived Inputs

Values produced by calculations, Global Functions, waterfall logic, or stored calculation outputs. They should generally be traceable rather than maintained manually.

D1. Simple rate conversion

Business situation: Deal Settings stores a percentage as 5.0, while a function requires decimal-rate units.

max_rate_percent = deal.params["MaxRate"]  # 5.0
max_rate_decimal = max_rate_percent / 100.0  # 0.05

gf.Fa(max_rate=max_rate_decimal)

Expected handling:

• Show configured value 5.0 percent and derived value 0.05 decimal separately.
• Record the conversion rather than reporting a value mismatch.
• Flag a unit mismatch if a consumer expects percent but receives decimal (or vice versa).

D2. Same source, different approved transformations

Business situation: Two functions apply different contractual adjustments to the same cap.

cap = deal.params["MaxRate"]  # 5.0%

coupon_cap = cap
elevated_threshold = cap + 1.0

gf.Fa(MaxRate=coupon_cap)       # 5.0%
gf.Fb(MaxRate=elevated_threshold)  # 6.0%

Expected handling:

• Display one source feeding two derived branches.
• Explain Fb’s +1 percentage-point adjustment.
• Do not flag a conflict if the different transformations are approved business rules.

D3. One Global Function’s output becomes another’s input

Business situation: Coupon validation relies on a calculated rather than manually entered coupon.

coupon = gf.CalculateCoupon(
    index_rate=deal.get_index_value("SOFR"),
    spread=deal.params["Spread"]
)

result = gf.ValidateCoupon(
    coupon=coupon,
    MaxRate=deal.params["MaxRate"]
)

Expected handling:

• Show two upstream inputs for CalculateCoupon: index source and spread setting.
• Show CalculateCoupon.output -> ValidateCoupon.coupon.
• Treat coupon as DERIVED, not a missing Deal Settings field.

D4. Nested Global Functions across several levels

Business situation: A top-level validation uses nested functions to calculate its threshold.

# Illustrative custom Global Functions:
def Fc(spread):
    return spread + 0.25

def Fb(spread):
    return gf.Fc(spread=spread)

def Fa(spread):
    return gf.Fb(spread=spread)

# In a deal script:
threshold = gf.Fa(spread=deal.params["Spread"])

Expected handling:

• Show the complete dependency path Spread -> Fa -> Fb -> Fc -> threshold.
• Surface required external inputs discovered within nested functions.
• Count the shared source only once in the analyst-managed inventory, but preserve each function binding.
• Distinguish a detected recursive-call cycle from a proven runtime failure.

D5. Actual ASAP2 cumulative loss calculation

Business situation: A Global Function computes cumulative realized loss using historical and current subpool data. The following follows the example in the ASAP manual.

def agg_cumm_real_loss(subpool):
    prior = (
        subpool.periodics[period - 1].CumRealLoss
        if period > 1 else 0
    )
    current = subpool.periodics[period]
    return (
        prior
        + current.RealLossTotal
        + current.TrailingRealLoss
        + current.Other24
    )

# In the deal script:
subpool = groups[1].subpools[0]
loss = gf["agg_cumm_real_loss"](subpool)

Expected handling:

• Show the prior-period CumRealLoss and all three current-period source fields.
• Show the cumulative loss as DERIVED from those fields.
• Record the subpool, period, and function version.
• Do not require an analyst to maintain loss as a Deal Settings parameter.

D6. Waterfall variable consumed by validation/reporting

Business situation: A waterfall creates a value that is later read by an eligible downstream script.

# Waterfall script:
CalculatedAvailableFunds = 1000000

# Bond Validation or Reporting script (where symbols are supported):
amount = symbols[period]["CalculatedAvailableFunds"]
result = gf.Fa(available_funds=amount)

Expected handling:

• Show Waterfall / CalculatedAvailableFunds as the origin.
• Show symbols[period] as the downstream access path.
• Include period and script-stage context.
• Avoid treating CalculatedAvailableFunds as a setup parameter.

D7. Persisted calculation output read in a later script

Business situation: A periodic calculation is saved and later used by reporting.

# Periodic calculation writes a named result using ASAP2's
# documented write_calc_data capability (arguments omitted here).

# Later, a reporting script reads stored calculation records:
for item in deal.periodics[period].get_calc_datas():
    if item.CalcName == "RateTest":
        result = item.CalcValues

Expected handling:

• Show the calculation name, period, and stored output as the data source.
• Where available, identify which upstream calculation wrote the record.
• Distinguish stored output from a value newly calculated in the current function invocation.

D8. Return value is produced but not assigned

Business situation: A function computes an updated available amount, but the script does not retain it.

available_funds = 100.0

gf.Fa(available_funds=available_funds)  # Returned value ignored

gf.Fb(available_funds=available_funds)  # Still receives 100.0

Expected handling:

• Show that Fa was called but its return was not bound to the later input.
• Highlight a POTENTIALLY_UNUSED_RETURN for review when the result is expected to be used.
• Do not assume that calling a function automatically updates a local numeric variable.

────────

5. Category 4 — Function / Class State

Values associated with individual function calls, defaults, internal assignments, class instances, and conditional behavior. The key business question is: What did this specific consumer actually use?

F1. Default parameter is used

Business situation: The script does not supply MaxRate; the function uses its own default.

def Fa(MaxRate=5.0):
    return MaxRate

result = gf.Fa()  # Effective input = 5.0

Expected handling:

• Display Fa.MaxRate: default = 5.0, explicit argument = none, received value = 5.0.
• Mark DEFAULT_USED; do not describe the value as coming from Deal Settings.
• Identify the function version that defines the default.

F2. Explicit argument overrides the function default

Business situation: Fa defaults to 5%, but the deal script explicitly sends 7%.

def Fa(MaxRate=5.0):
    return MaxRate

result = gf.Fa(MaxRate=7.0)

Expected handling:

• Show default = 5.0, received = 7.0, effective = 7.0.
• Identify source = explicit literal, not a changed function default.
• A default/actual difference is informational unless a business rule prohibits the override.

F3. Function reassigns a local parameter

Business situation: A function receives a rate of 5%, then changes the local variable before a check.

def Fa(MaxRate):
    received = MaxRate       # 5.0
    MaxRate = MaxRate + 1.0  # 6.0
    return MaxRate

result = gf.Fa(MaxRate=5.0)

Expected handling:

• Show received value = 5.0 and effective value = 6.0.
• Classify the change as LOCAL_TRANSFORMATION.
• Do not claim that the original Deal Settings value was modified.

F4. Conditional override

Business situation: A trigger event causes a special cap to apply.

def Fa(MaxRate, trigger_active):
    if trigger_active:
        MaxRate = 7.0
    return MaxRate

result = gf.Fa(MaxRate=5.0, trigger_active=True)

Expected handling:

• Show configured/received value = 5.0 and observed effective value = 7.0 for this invocation.
• Show the condition (trigger_active=True) that selected the alternate value.
• Review whether the alternate value is contractually authorized.
• When only source analysis is available, display conditional possibilities rather than a fabricated actual value.

F5. Different class instances hold different values

Business situation: Two rate managers apply different caps to different tranches.

class RateManager(object):
    def __init__(self, MaxRate):
        self.MaxRate = MaxRate

    def cap(self, rate):
        return min(rate, self.MaxRate)

senior = RateManager(5.0)
subordinate = RateManager(7.0)

senior_rate = senior.cap(6.0)         # 5.0
subordinate_rate = subordinate.cap(6.0)  # 6.0

Expected handling:

• Distinguish senior.MaxRate from subordinate.MaxRate.
• Show each instance’s business scope and initialization source.
• Do not treat instance-level differences as conflicts without a matching requirement.

F6. An existing class instance changes state

Business situation: The same rate manager changes its cap between calculations.

manager = RateManager(5.0)
first_result = manager.cap(6.0)  # 5.0

manager.MaxRate = 7.0
second_result = manager.cap(6.0) # 6.0

Expected handling:

• Show state before and after the assignment where observed.
• Distinguish the first and second consumer results.
• Flag an unexpected state change for business review.
• Do not attribute the change to Deal Settings unless that source was actually updated.

F7. Same function called twice with different bindings

Business situation: The same validation is used for two bond classes.

gf.Fa(MaxRate=5.0, bond=bonds["A1"])
gf.Fa(MaxRate=7.0, bond=bonds["B1"])

Expected handling:

• Show two distinct calls, even though both invoke Fa.
• Include bond, script location, parameter values, and any available execution context.
• Do not collapse both entries into a single Fa.MaxRate value.

F8. Same function, different approved/debug versions

Business situation: The approved Global Function defaults to 5%, while a temporary debug copy uses 6%.

# Illustrative difference between two versions:
# Approved Fa v1: def Fa(MaxRate=5.0): ...
# Debug copy:    def Fa(MaxRate=6.0): ...

result = gf.Fa()  # Depends on the selected execution version

Expected handling:

• Show which function version was selected for the analysis or execution.
• Keep approved and debug results separate.
• Re-review implicit defaults when the applicable approved version changes.
• Never merge debug observations into production evidence without an explicit distinction.

Source nuance: ASAP2’s documented Global Function Debugging creates a temporary editable copy from the latest approved version in the deal-script context and distinguishes debug workflow steps.

F9. Dynamic call selected from a validation portfolio

Business situation: A portfolio manager selects which registered Global Functions to run.

# Illustrative custom registry, not an ASAP2 built-in:
registry = {
    "coupon_check": "Fa",
    "balance_check": "Fb"
}

for key in ["coupon_check", "balance_check"]:
    function_name = registry[key]
    function = getattr(gf, function_name)
    result = function()

Expected handling:

• Show the portfolio/registry selection that led to each Function Call.
• List the resolved functions when the registry mapping is available.
• If a runtime-selected function cannot be determined, mark UNRESOLVED_DYNAMIC_CALL rather than MISSING_PARAMETER.

F10. A parameter is received but not used

Business situation: Fa receives 5%, but its calculation uses a separate fixed value.

def Fa(MaxRate):
    internal_cap = 7.0
    return internal_cap

result = gf.Fa(MaxRate=5.0)

Expected handling:

• Show Fa.MaxRate was supplied but did not influence the returned value in the examined path.
• Flag POTENTIALLY_UNUSED_ARGUMENT for review.
• Do not automatically conclude a business error: the parameter may be used in another conditional path.

────────

6. Cross-Category Examples: End-to-End Business Review

Example A. Comparing Fa(MaxRate) and Fb(MaxRate)

# Proposed Deal Settings:
# MaxRate       = 5.0%
# IndexMaxRate  = 7.0%

gf.Fa(MaxRate=deal.params["MaxRate"])
gf.Fb(MaxRate=deal.params["IndexMaxRate"])

|Comparison field         |Fa.MaxRate              |Fb.MaxRate                   |
|-------------------------|------------------------|-----------------------------|
|Parameter name           |MaxRate                 |MaxRate                      |
|Source                   |`deal.params["MaxRate"]`|`deal.params["IndexMaxRate"]`|
|Configured/received value|5.0%                    |7.0%                         |
|Business purpose         |Coupon cap              |Index cap                    |
|Required relationship    |Independent             |Independent                  |
|Expected status          |Valid                   |Valid                        |

Required business outcome: A user can compare the two bindings side by side and see why they differ. The system does not infer an error from the common parameter name.

Example B. One source, different effective values

cap = deal.params["MaxRate"]  # 5.0%

gf.Fa(MaxRate=cap)
gf.Fb(MaxRate=cap + 1.0)

|Comparison field|Fa.MaxRate  |Fb.MaxRate                     |
|----------------|------------|-------------------------------|
|Shared source   |Deal MaxRate|Deal MaxRate                   |
|Source value    |5.0%        |5.0%                           |
|Transformation  |None        |+1 percentage point            |
|Received value  |5.0%        |6.0%                           |
|Expected status |Valid       |Valid if adjustment is approved|

Required business outcome: Preserve one configured source while showing two distinct downstream transformations.

Example C. Cross-function mismatch requiring review

# Contractual business rule: both checks MUST use the deal cap.

gf.Fa(MaxRate=deal.params["MaxRate"])  # 5.0%
gf.Fb(MaxRate=7.0)                     # 7.0%

Required business outcome: Flag MUST_MATCH_VIOLATION, identify both bindings and source paths, and direct the analyst to the inconsistent call/configuration. The system must not silently harmonize values.

Example D. Setup complete, current-period input missing

# A configured deal assumption exists:
max_rate = deal.params["MaxRate"]

# A required value for the current payment date is absent:
payment_adjustment = payment_inputs["PayInNumR"].InputValue

gf.Fa(MaxRate=max_rate, adjustment=payment_adjustment)

Required business outcome: Report deal configuration as confirmed but current-period readiness as incomplete. Setup approval must not be presented as proof that every future payment date has complete payment inputs.

Example E. Nested calculation feeds reporting and validation

# Illustrative custom functions:
coupon = gf.CalculateCoupon(
    index_rate=deal.get_index_value("SOFR"),
    spread=deal.params["Spread"]
)

validation_result = gf.ValidateCoupon(
    coupon=coupon,
    MaxRate=deal.params["MaxRate"]
)

Expected dependency view:

SOFR index (ASAP2 runtime) ------+
                                 +--> CalculateCoupon --> coupon --> ValidateCoupon
Spread (Deal Settings) ----------+                               ^
                                                                 |
MaxRate (Deal Settings) ------------------------------------------+

Required business outcome: The analyst confirms Spread and MaxRate; the system traces SOFR and calculated coupon without asking the analyst to enter those derived/runtime values into Deal Settings.

────────

7. Expected User Views and Review Outcomes

A. Deal Settings — Configurable Inputs

The analyst should see only values that the business has chosen to manage as deal configuration.

|Parameter   |Value|Unit   |Applicability|Analyst confirmed?|Used by           |
|------------|----:|-------|-------------|------------------|------------------|
|MaxRate     |5.0  |percent|Deal-wide    |Yes               |Fa, Fb            |
|IndexMaxRate|7.0  |percent|Index checks |Yes               |Fb                |
|A1MaxRate   |5.0  |percent|Bond A1      |Yes               |Fa / A1 call      |
|StepUpPeriod|25   |period |Deal-wide    |No                |Coupon calculation|

Requirements: Copy Deal Info must copy these entries as appropriate, but the target deal’s analyst confirmations should be reset or require fresh approval. Each value should show where it is used and which business rule governs it.

B. Dependency Explorer — All Inputs

Show discovered inputs without implying that all are editable Deal Settings parameters.

|Example input      |Category            |Source                      |Expected review              |
|-------------------|--------------------|----------------------------|-----------------------------|
|MaxRate            |Configurable        |Deal Settings               |Configured? Confirmed?       |
|FirstPayDate       |Runtime             |Deal                        |Correct deal?                |
|EndSchBal          |Runtime             |Deal periodic / period      |Correct period? Available?   |
|PayInNumR          |Runtime             |Payment Input / payment date|Required? Missing?           |
|coupon             |Derived             |CalculateCoupon output      |Upstream dependency complete?|
|RateManager.MaxRate|Function/Class State|Object instance             |Initial value? Mutation?     |

C. Cross-Function Parameter Comparison

The user should be able to select a parameter name (for example, MaxRate) and inspect every matching function definition, call site, and runtime binding independently.

At minimum, display:

|Field                    |Why it matters                                                       |
|-------------------------|---------------------------------------------------------------------|
|Function and version     |Identifies which rule defines the parameter                          |
|Call site and context    |Separates repeated calls and different bonds/periods                 |
|Formal parameter name    |Shows the receiving function’s argument                              |
|Default value            |Detects implicit defaults                                            |
|Bound source             |Distinguishes deal config, runtime field, literal, and derived output|
|Received value           |Shows the value handed into that invocation                          |
|Effective value, if known|Shows local adjustment or override                                   |
|Business relationship    |`INDEPENDENT`, `MUST_MATCH`, `DERIVED_FROM`, or `UNKNOWN`            |
|Review outcome           |`VALID`, `REVIEW`, `MISSING`, `UNCONFIRMED`, or `UNRESOLVED`         |

D. Pre-Validation Review

Proposed user entry point: A Pre-Validation action next to Run Setup, also available as an automatic component of Setup Validation.

Proposed report groupings:

1. Deal Settings configurations: present, missing, invalid, or unconfirmed.
2. System/runtime inputs: source, scope, requiredness, and current-period availability.
3. Derived inputs: upstream function/output lineage and unresolved dependencies.
4. Function/class state: default-versus-actual binding, overrides, repeated calls, and version differences.

Outcome principles:

• Different values are not automatically errors.
• A missing required configuration is distinct from an unresolved dynamic function call.
• A legitimate zero/default is distinct from a missing value.
• Full dependency discovery belongs primarily to setup/changed-code review; period-specific required inputs still need checks at the appropriate periodic processing step.
• Blocking or warning behavior should follow agreed business severity rules; the existing ASAP2 validation mechanism supports deal-level severity thresholds.

────────

8. Source Reference and Assumptions

Primary internal source: ASAP_KNOWLEDGE_CONTEXT_20261025(3).md.

Relevant sections consolidated in that file:

• ASAP_SCRIPTING_MANUAL — PythonScript Objects and Access, deal, periodics, payment_inputs, Symbol Objects, get_index_value, get_currency_conversion_rate, get_calc_datas, raise_error, and Global Function Debugging.
• ASAP_USER_MANUAL — Global Functions, To Use global functions, Payment Input History, and Deal Copy/Duplicate.

Important: Source documentation confirms the object names and behaviors cited above, but does not establish the proposed deal.params interface, a universal parameter dependency scanner, or automatic effective-value comparison as existing ASAP2 features. Those are requirements discussed for future enhancement. Source examples have been simplified for clarity; illustrative business scenarios should not be treated as verified deal-specific rules.