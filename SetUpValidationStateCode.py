from asap2_obj import assets
from ironpython_validation_helpers import ValidationHelperApi


VALIDATION_METADATA = {
    "script_name_display": "SetUpValidationStateCode",
    "function_key": "set_up_validation_state_code",
    "focus": "SetUp",
    "asset": "All",
    "type": "Asset",
    "threshold": 5,
    "severity": "CRITICAL",
    "issue_code": "SETUP_STATE_CODE_INVALID",
    "description": "State Code",
    "explanation": "State code must be populated and must be a valid US state or territory code.",
    "impact": "Invalid state values can break setup quality checks, mapping logic, and downstream reporting.",
    "action": "Review the asset setup state value and replace it with a valid US state code.",
    "attribute_name": "State",
}


VALID_STATE_CODES = {
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    "DC", "PR", "VI", "GU", "AS", "MP",
}

MISSING_STATE_EXPECTED = "Valid US State Code"
INVALID_STATE_EXPECTED = "Valid US State Code (e.g., CA, NY, TX)"
INVALID_STATE_MESSAGE = "State Code is not valid"


def SetUpValidationStateCode(assets):
    """
    Validates that all assets in assetsetup have valid state codes and do not have blanks or nulls.
    If a validation fails, this function leverages the host system's existing asset.raise_error()
    behavior through ValidationHelperApi so we keep the native ASAP2 error experience.
    """
    for index, asset in enumerate(assets):
        state_code = asset.setup.State
        invalid_state_details = _get_invalid_state_details(state_code)
        if invalid_state_details:
            expected, actual = invalid_state_details
            _emit_invalid_state_code(
                asset=asset,
                asset_index=index,
                expected=expected,
                actual=actual,
            )
            return

    return


def _get_invalid_state_details(state_code):
    if state_code is None:
        return MISSING_STATE_EXPECTED, "None (null)"

    if isinstance(state_code, str):
        normalized = state_code.strip().upper()
        if not normalized:
            return MISSING_STATE_EXPECTED, "Blank/Empty"
        if normalized not in VALID_STATE_CODES:
            return INVALID_STATE_EXPECTED, state_code
        return None

    state_code_normalized = str(state_code).strip().upper()
    if state_code_normalized not in VALID_STATE_CODES:
        return INVALID_STATE_EXPECTED, state_code

    return None


def _emit_invalid_state_code(asset, asset_index, expected, actual):
    return ValidationHelperApi(
        operation="emit",
        metadata=VALIDATION_METADATA,
        passed=False,
        context={
            "asset_index": asset_index,
            "field_name": "State",
        },
        issue=INVALID_STATE_MESSAGE,
        expected=expected,
        actual=actual,
        host_target=asset,
        attribute_name="State",
        message=INVALID_STATE_MESSAGE,
        expected_value=expected,
        actual_value=actual,
    )


SetUpValidationStateCode(assets)
