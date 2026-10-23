Task: Enrich Validation Master JSON with ASAP Runtime-Based Implementation Specifications

Objective

I have provided:

1. validation_master_flat.json — the existing Validation Master dataset.
2. ASAP User Manual — business and application documentation.
3. ASAP Scripting Manual — scripting, object model, and Runtime documentation.

Your task is to systematically analyze every validation rule in the JSON, identify its required data points and executable validation logic, and enrich the existing JSON with detailed, implementation-ready specifications grounded in the ASAP manuals.

The goal is to create a reusable technical specification that can later support implementing each validation function in the ASAP2 Runtime environment.

This is a specification-enrichment task, not a request to implement the validation functions themselves.

Use the provided manuals as the authoritative sources for ASAP Runtime behavior, supported objects, API calls, functions, and data-access methods.

1. Preserve the Existing Dataset

The JSON currently contains:

* 92 numbered validation records.
* 16 unnumbered continuation records.
* 108 total objects.
* 22 original business columns, plus metadata and development status fields.

Preserve:

* All existing records and their ordering.
* All original field names and values.
* record_id, parent_record_id, and row_type.
* development_status and any other existing progress metadata.
* Existing SCRIPT NAME, WARNING, THRESHOLD, and NOTES values.

Do not restructure or summarize the existing dataset.

Add exactly one new top-level property to each JSON object:

implementation_spec

This property should contain the structured implementation analysis described below.

The output must remain a top-level JSON array, with one object per original record.

2. Required Implementation Specification

For each validation record, populate the following structured information.

A. Identification and Execution Context

Identify:

* spec_status: documented, partially_documented, or unresolved.
* execution_stage: setup, periodic, payment, or unknown.
* evaluation_scope: deal, pool, bond, class, asset, loan, or another scope explicitly established by the documentation.
* runtime_context: the required ASAP Runtime environment or objects.
* prerequisites: conditions that must be satisfied before execution.

Distinguish the stage in which the validation should run from the stage in which its inputs originate.

Do not assume that a data point available during Setup is automatically available during a Periodic execution.

B. Required Data Points

Create required_data_points, an array containing every input necessary to implement the validation.

For each data point, include:

* business_name: human-readable business meaning.
* asap_field_name: exact ASAP field/parameter name, when documented.
* asap_runtime_symbol: exact documented Runtime object, property, or function.
* access_expression: exact Runtime access expression, if supported by the manuals.
* data_type: numeric, string, date, Boolean, collection, or unknown.
* entity_scope: deal, bond, loan, asset, etc.
* period: setup, current, previous, historical, or not applicable.
* data_origin: runtime, setup parameter, periodic input, derived calculation, external input, or unknown.
* required: whether the validation requires this data point.
* dependencies: other inputs needed to derive the value.
* source_references: relevant manual citations.
* availability_status: documented, inferred, or unresolved.

Separate directly available Runtime data from values that must be calculated.

For calculated values, explicitly identify all underlying data dependencies.

Do not invent Runtime symbols or assume Python attribute names based on business labels.

C. Runtime Data Acquisition

Create runtime_access_plan explaining:

1. Which Runtime objects or contexts are required.
2. How each data point is retrieved.
3. Whether collection iteration is required.
4. How Setup and Periodic information are accessed.
5. How prior-period information is retrieved when necessary.
6. Whether any additional parameters must be supplied by the host application.
7. Whether data access is supported by documented Runtime APIs.

Use documented method signatures and access patterns where available.

If a required operation is not documented, leave its access expression as null and describe the unresolved dependency.

Do not invent helper functions, APIs, or object methods and present them as existing ASAP capabilities.

D. Calculation Dependencies

Create calculation_plan containing an ordered sequence of calculation steps.

Each step should specify:

* step_id
* operation
* input_data_points
* expression
* output
* execution_scope
* source_references

Determine which intermediate values must be calculated before evaluating the validation.

Where multiple calculations share common dependencies, identify reusable intermediate results.

Identify recursive or circular dependencies rather than silently resolving them.

Favor efficient calculation design and reuse of existing Runtime values.

E. Validation Logic

Create validation_logic, containing one or more explicit conditions.

Each condition must include:

* condition_id
* business_rule
* input_references
* comparison_operator
* logical_expression
* evaluation_granularity
* pass_condition
* fail_condition
* failure_message
* comparison_tolerance
* missing_data_behavior
* source_references

Translate each original WARNING condition into a precise, logically equivalent expression.

Preserve the original failure message, including spelling and wording, in a dedicated field.

Do not silently change business rules.

For numeric comparisons, do not invent tolerances, rounding rules, or precision requirements.

If tolerance is not specified by the source material, use null and record an unresolved question.

Keep the existing THRESHOLD field unchanged. Do not assume that its numeric value represents a comparison tolerance, severity, or monetary threshold unless the source documentation establishes that meaning.

F. Validation Dependencies and Execution Requirements

Create:

* runtime_dependencies
* setup_dependencies
* periodic_dependencies
* previous_period_dependencies
* external_parameters

Identify which parameters are:

1. Available directly from ASAP Runtime.
2. Configured during Deal Setup.
3. Supplied during a Periodic run.
4. Derived from other calculations.
5. Missing or requiring clarification.

Do not default missing numeric inputs to zero.

Preserve unknown values as null.

Where applicable, identify prerequisite validation or calculation stages.

G. Source References and Unresolved Items

Every important Runtime claim must be supported by a source reference.

Use:

* Manual filename.
* Relevant chapter/section.
* Page number if available.
* A short identifying excerpt or heading.
* The specific claim supported by that reference.

Do not fabricate section numbers, page numbers, or citations.

If the provided context lacks reliable location information, identify the manual and distinctive heading or text instead.

Create:

* source_references
* assumptions
* unresolved_questions
* implementation_notes

Clearly distinguish:

* Explicit rules from the Validation Master.
* Documented ASAP Runtime capabilities.
* Technical inferences.
* Unresolved implementation decisions.

Manual documentation governs Runtime availability and behavior. The existing Validation Master governs the intended business validation.

If they conflict, flag the conflict rather than silently changing either source.

3. Special Handling of Continuation Rows

Unnumbered continuation rows may contain additional independent validation conditions.

Do not discard or merge them.

For each continuation row:

* Preserve its parent_record_id.
* Analyze its own WARNING, THRESHOLD, and other populated fields.
* Create its own implementation_spec.
* Identify shared dependencies with the parent validation.
* Avoid duplicating Runtime data acquisition unnecessarily.

For example:

* Record #20 contains multiple interest-payment validation conditions.
* Record #35 has a continuation row containing a separately named validation script: SetupValidationStateCode.

A separately named continuation rule must retain its own identity.

Where a main record and its continuation share implementation logic, indicate their relationship without altering the original row structure.

4. ASAP Runtime Accuracy Requirements

Prioritize correctness over completeness.

Do not use generic financial knowledge to invent ASAP implementation details.

Specifically:

* Do not guess Runtime object names.
* Do not fabricate field names.
* Do not invent function signatures.
* Do not assume that a value in a report corresponds directly to a Runtime-accessible field.
* Do not assume prior-period data is accessible without documentation.
* Do not confuse setup configuration with periodic runtime inputs.
* Do not infer business formulas solely from similar validation names.

For ambiguous rules, explain which details are missing.

Examples requiring special care:

* Bond and asset balance rollovers.
* Net rate and servicing fee calculations.
* Interest and principal payments.
* Deferred interest.
* Fee calculation versus reported amount.
* Interest Reserve Account.
* Percentage totals and tolerances.

For a rule with insufficient definition, such as a validation whose description explicitly requests further explanation, mark the specification as unresolved or partially_documented.

Do not manufacture a complete algorithm to make the dataset appear fully documented.

5. Development Architecture

The specifications should be compatible with an eventual shared ASAP2 Validation Function Library.

Favor:

* Reusable data acquisition patterns.
* Reusable calculation helpers.
* Explicit dependencies.
* Clear validation conditions.
* Consistent error handling.
* Separation of business rules from Runtime data access.
* Separation of Setup validation and Periodic validation execution.

Deal-specific Setup parameters should remain identifiable as deal-level configuration rather than being unnecessarily bound to global function parameters.

Keep the specifications compatible with calculation-driven development: focus on the calculations and Runtime dependencies necessary for correct implementation, without exhaustive runtime evidence verification or unrelated implementation work.

Do not change existing development statuses based on your analysis.

6. Processing Strategy

Process the entire dataset in manageable batches, approximately 10–15 numbered records at a time, including all associated continuation rows.

For each batch:

1. Read the validation requirements from JSON.
2. Identify relevant manual sections.
3. Extract documented Runtime data-access information.
4. Construct required data-point specifications.
5. Derive the validation calculation and comparison logic.
6. Record unresolved dependencies.
7. Add implementation_spec to each record.
8. Validate the enriched records.
9. Save the batch results before proceeding.

Reuse previously established, cited Runtime access patterns where applicable.

Do not repeat the same manual analysis unnecessarily.

Do not stop after a sample or the first batch unless execution is actually blocked.

Complete all 108 objects.

7. Required Output Files

Create:

validation_master_enriched.json

The complete original dataset with the new implementation_spec field.

validation_enrichment_report.json

A quality report containing:

* Total analyzed records.
* Records with fully documented specifications.
* Partially documented specifications.
* Unresolved specifications.
* Missing Runtime API mappings.
* Missing formulas or required parameters.
* Source coverage.
* Original JSON versus enriched JSON integrity checks.

Retain the original input JSON unchanged.

If the environment cannot directly create a downloadable JSON file, provide a deterministic script and complete structured output that can create the file locally. Do not claim that a file was created unless it actually exists.

8. Validation Requirements

Before finalizing:

1. Confirm all 108 original objects are present.
2. Confirm original record ordering is unchanged.
3. Confirm every original field and value is unchanged.
4. Confirm all original development_status values are preserved.
5. Confirm each object contains implementation_spec.
6. Confirm each required data point has an identifiable role and provenance.
7. Confirm all undocumented Runtime symbols remain null.
8. Confirm no business formulas, parameters, or API calls were invented.
9. Confirm the enriched JSON is valid and can be read back successfully.
10. Report incomplete and unresolved specifications explicitly.

Finally, provide the actual enriched JSON file and a concise summary of implementation readiness.

Success means a complete, traceable, Runtime-grounded technical specification for every validation rule—not merely a description of what each validation does.