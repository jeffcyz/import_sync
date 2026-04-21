from asap2_obj import bonds, period, fs
from ironpython_validation_helpers import ValidationHelperApi


VALIDATION_METADATA = {
    "script_name_display": "ValidateNextIndexRate",
    "function_key": "validate_next_index_rate",
    "focus": "Periodic",
    "asset": "All",
    "type": "Bond",
    "threshold": 4,
    "severity": "ERROR",
    "issue_code": "NEXT_INDEX_RATE_MISSING",
    "description": "Next Index Rate",
    "explanation": "Floating-rate bonds must have a populated, non-zero Next Index Rate.",
    "impact": "Coupon calculations and downstream interest validations may be incorrect.",
    "action": "Review the source rate feed and populate the bond's Next Index Rate.",
    "attribute_name": "NextIndexRate",
}

def validate_next_index_rate(
    bds,
    p: int = None,
    return_results: bool = False,
    interrupt_after_scan: bool = True,
):
    """
    Purpose:
    ----
        Validates that the Next Index Rate is populated for bonds with an interest type of 'Floating'.

    Returns:
    ----
        bool or list:
            Returns True if all validation checks pass.
            Returns False if any validation check fails.
            Returns structured validation results when return_results=True.

    Raises:
    ----
        ValueError: If return_results=True and interrupt_after_scan=True.
        ValueError: If interrupt_after_scan=True and any validation check fails.
    """
    results = scan_next_index_rate(bds, p=p)
    return ValidationHelperApi(
        operation="finalize_scan",
        results=results,
        return_results=return_results,
        interrupt_after_scan=interrupt_after_scan,
        error_prefix="ValidateNextIndexRate failed after scan",
        identifier_key="bond_name",
        identifier_label="bonds",
    )


def _resolve_host_target(bond_object, bond_periodic):
    if hasattr(bond_periodic, "raise_error"):
        return bond_periodic
    if hasattr(bond_object, "raise_error"):
        return bond_object
    return None


def _is_missing_next_index_rate(value):
    if value is None:
        return True
    if isinstance(value, str):
        normalized = value.strip()
        return normalized in ("", "0", "0.0")
    if isinstance(value, bool):
        return False
    return value == 0


def scan_next_index_rate(bds, p: int = None):
    """
    Scans floating-rate bonds and returns structured validation results.
    """
    resolved_period = period if p is None else p
    results = []

    for bd in bds:
        bn = bd.name
        bond_setup = bonds[bn].setup
        bp = bonds[bn].periodics[resolved_period]

        if bond_setup.IntType != "Floating":
            continue

        next_index_rate = bp.NextIndexRate
        actual_value = "None (null)" if next_index_rate is None else next_index_rate
        result = ValidationHelperApi(
            operation="emit",
            metadata=VALIDATION_METADATA,
            passed=not _is_missing_next_index_rate(next_index_rate),
            issue="Next Index shows no value for floating bond",
            expected="Non-zero Next Index Rate",
            actual=actual_value,
            context={
                "bond_name": bn,
                "period": resolved_period,
                "field_name": "NextIndexRate",
                "interest_type": bond_setup.IntType,
            },
            host_target=_resolve_host_target(bd, bp),
            attribute_name="NextIndexRate",
            message="Next Index shows no value",
            expected_value="Non-zero Next Index Rate",
            actual_value=actual_value,
        )
        results.append(result)

    return results

if __name__ == "__main__":
    fs.output(validate_next_index_rate(bonds, period - 1))
