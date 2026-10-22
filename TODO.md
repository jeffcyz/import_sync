Hi Dan,

I wanted to summarize the key takeaways from my discussion with Rani (PwC) and get your feedback on the proposed direction.

1. Deal-Level Input Management

We agreed on introducing a configurable, free-form table under Deal Settings to centrally organize deal setup parameters and other deal-specific input values, rather than managing them individually within scripts.

Importantly, this would be a general-purpose deal-level input management feature, not a parameter table strictly tied to Global Functions.

For example, defining `MaxRate = 5` in the table would allow both deal scripts and Global Functions to reference `deal.MaxRate` directly, eliminating repeated parameter passing or hardcoded assignments and improving consistency and maintainability.

Rani also encouraged keeping this module broadly named and extensible rather than limiting it to validation parameters, allowing it to support additional use cases in the future.

2. Parameter Pre-Validation

We discussed the parameter pre-validation step previously proposed by our team, which PwC confirmed is feasible. This would help identify missing or invalid parameters before they cause runtime failures.

From a system performance perspective, we agreed it would be more efficient to incorporate this into Setup Validation rather than repeatedly running the same checks during each periodic execution.

3. User-Defined Variables & Recursive Checks

I mentioned that user-defined values can be retrieved from Global Variables. PwC raised concerns about recursive references and dependencies and suggested handling those checks within the reporting functionality rather than individual Global Functions. I think this is a reasonable accommodation.

4. Validation Portfolio & Reporting Architecture

We also briefly discussed my ValidationEngine portfolio manager. We agreed that Global Functions should return structured results (dictionary/JSON) rather than using `print` or `fs.output` to write directly to the output stream.

A separate reporting layer would handle result aggregation, error summaries, severity levels, recommended actions, and message distribution.

One architectural question remains open: whether to continue managing validation portfolios through our custom Global Function class (`ValidationEngine`) or provide PwC with the requirements to implement this functionality natively within ASAP2.

I'd appreciate your direction on the topics above, along with any additional comments, requirements, or priorities you'd like us to consider as we move forward.

Thanks!
