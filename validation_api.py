import os


_HELPER_SOURCE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "ironpython_validation_helpers.txt",
)

import re


THRESHOLD_TO_SEVERITY = {
    1: "DEBUG",
    2: "INFO",
    3: "WARNING",
    4: "ERROR",
    5: "CRITICAL",
}

SEVERITY_RANK = {
    "DEBUG": 10,
    "INFO": 20,
    "WARNING": 30,
    "ERROR": 40,
    "CRITICAL": 50,
}

SEVERITY_TO_THRESHOLD = {
    "DEBUG": 1,
    "INFO": 2,
    "WARNING": 3,
    "ERROR": 4,
    "CRITICAL": 5,
}


def ValidationHelperApi(
    operation,
    script_name_display=None,
    metadata=None,
    runtime_context=None,
    context=None,
    logger=None,
    **kwargs
):
    # ASAP2 imported scripts should stay logger-free; callers can log returned payloads.
    _ = logger
    if operation == "summarize_results":
        return summarize_results(
            results=kwargs.get("results", []),
            minimum_severity=kwargs.get("minimum_severity"),
            include_results=kwargs.get("include_results", False),
        )

    if operation in ("build_log_entry", "format_log_entry"):
        return build_log_entry(kwargs.get("result"))

    prepared_metadata = prepare_metadata(script_name_display, metadata)
    merged_context = merge_contexts(runtime_context, context)

    if operation == "required":
        return check_required(
            metadata=prepared_metadata,
            value=kwargs.get("value"),
            field_name=kwargs.get("field_name"),
            context=merged_context,
            issue=kwargs.get("issue"),
            explanation=kwargs.get("explanation"),
            impact=kwargs.get("impact"),
            action=kwargs.get("action"),
            host_target=kwargs.get("host_target"),
            host_raise_method=kwargs.get("host_raise_method", "raise_error"),
            attribute_name=kwargs.get("attribute_name"),
            message=kwargs.get("message"),
            expected_value=kwargs.get("expected_value"),
            actual_value=kwargs.get("actual_value"),
        )

    if operation == "equal":
        return check_equal(
            metadata=prepared_metadata,
            actual=kwargs.get("actual"),
            expected=kwargs.get("expected"),
            field_name=kwargs.get("field_name"),
            context=merged_context,
            issue=kwargs.get("issue"),
            explanation=kwargs.get("explanation"),
            impact=kwargs.get("impact"),
            action=kwargs.get("action"),
            host_target=kwargs.get("host_target"),
            host_raise_method=kwargs.get("host_raise_method", "raise_error"),
            attribute_name=kwargs.get("attribute_name"),
            message=kwargs.get("message"),
            expected_value=kwargs.get("expected_value"),
            actual_value=kwargs.get("actual_value"),
        )

    if operation == "within_tolerance":
        return check_within_tolerance(
            metadata=prepared_metadata,
            actual=kwargs.get("actual"),
            expected=kwargs.get("expected"),
            tolerance=kwargs.get("tolerance"),
            field_name=kwargs.get("field_name"),
            context=merged_context,
            issue=kwargs.get("issue"),
            explanation=kwargs.get("explanation"),
            impact=kwargs.get("impact"),
            action=kwargs.get("action"),
            host_target=kwargs.get("host_target"),
            host_raise_method=kwargs.get("host_raise_method", "raise_error"),
            attribute_name=kwargs.get("attribute_name"),
            message=kwargs.get("message"),
            expected_value=kwargs.get("expected_value"),
            actual_value=kwargs.get("actual_value"),
        )

    if operation == "roll_forward":
        return check_roll_forward(
            metadata=prepared_metadata,
            beginning_balance=kwargs.get("beginning_balance"),
            activity_delta=kwargs.get("activity_delta"),
            ending_balance=kwargs.get("ending_balance"),
            field_name=kwargs.get("field_name"),
            tolerance=kwargs.get("tolerance", 0.0),
            context=merged_context,
            issue=kwargs.get("issue"),
            explanation=kwargs.get("explanation"),
            impact=kwargs.get("impact"),
            action=kwargs.get("action"),
            host_target=kwargs.get("host_target"),
            host_raise_method=kwargs.get("host_raise_method", "raise_error"),
            attribute_name=kwargs.get("attribute_name"),
            message=kwargs.get("message"),
            expected_value=kwargs.get("expected_value"),
            actual_value=kwargs.get("actual_value"),
        )

    if operation in ("emit", "emit_result"):
        return emit_result(
            metadata=prepared_metadata,
            passed=kwargs.get("passed"),
            issue=kwargs.get("issue"),
            explanation=kwargs.get("explanation"),
            impact=kwargs.get("impact"),
            action=kwargs.get("action"),
            context=merged_context,
            severity=kwargs.get("severity"),
            threshold=kwargs.get("threshold"),
            expected=kwargs.get("expected"),
            actual=kwargs.get("actual"),
            host_target=kwargs.get("host_target"),
            host_raise_method=kwargs.get("host_raise_method", "raise_error"),
            attribute_name=kwargs.get("attribute_name"),
            message=kwargs.get("message"),
            expected_value=kwargs.get("expected_value"),
            actual_value=kwargs.get("actual_value"),
        )

    raise ValueError("Unsupported helper operation: %s" % operation)


def normalize_key(text):
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", text or "")
    cleaned = re.sub(r"[^0-9A-Za-z]+", "_", text)
    cleaned = re.sub(r"_+", "_", cleaned).strip("_").lower()
    if cleaned and cleaned[0].isdigit():
        cleaned = "v_" + cleaned
    return cleaned


def coerce_int(value):
    try:
        if value in (None, ""):
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


def coerce_bool(value):
    if isinstance(value, bool):
        return value
    if value in (1, "1", "true", "TRUE", "True", "yes", "YES", "Yes"):
        return True
    if value in (0, "0", "false", "FALSE", "False", "no", "NO", "No"):
        return False
    return bool(value)


def threshold_to_severity(threshold, default="WARNING"):
    threshold = coerce_int(threshold)
    if threshold is None:
        return default
    return THRESHOLD_TO_SEVERITY.get(threshold, default)


def merge_contexts(runtime_context=None, context=None):
    merged = {}
    if runtime_context:
        merged.update(dict(runtime_context))
    if context:
        merged.update(dict(context))
    return merged


def prepare_metadata(script_name_display=None, metadata=None):
    prepared = dict(metadata or {})
    resolved_script_name = script_name_display or prepared.get("script_name_display")
    if not resolved_script_name:
        raise ValueError("script_name_display is required.")
    prepared["script_name_display"] = resolved_script_name
    prepared["function_key"] = prepared.get("function_key") or normalize_key(resolved_script_name)
    prepared["threshold"] = coerce_int(prepared.get("threshold"))
    prepared["severity"] = prepared.get("severity") or threshold_to_severity(prepared.get("threshold"))
    return prepared


def emit_result(
    metadata,
    passed,
    issue=None,
    explanation=None,
    impact=None,
    action=None,
    context=None,
    severity=None,
    threshold=None,
    expected=None,
    actual=None,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    prepared_metadata = prepare_metadata(metadata=metadata)
    passed = coerce_bool(passed)
    resolved_threshold = coerce_int(threshold)
    if resolved_threshold is None:
        resolved_threshold = prepared_metadata.get("threshold")

    if passed:
        resolved_severity = severity or "INFO"
        resolved_issue = issue
        resolved_explanation = explanation
        resolved_impact = impact
        resolved_action = action
    else:
        resolved_severity = severity or prepared_metadata.get("severity") or threshold_to_severity(resolved_threshold)
        resolved_issue = issue or prepared_metadata.get("issue")
        resolved_explanation = explanation or prepared_metadata.get("explanation")
        resolved_impact = impact or prepared_metadata.get("impact")
        resolved_action = action or prepared_metadata.get("action")

    result = {
        "script_name_display": prepared_metadata.get("script_name_display"),
        "function_key": prepared_metadata.get("function_key"),
        "status": "PASS" if passed else "FAIL",
        "passed": passed,
        "severity": resolved_severity,
        "threshold": resolved_threshold,
        "issue_code": prepared_metadata.get("issue_code"),
        "issue": resolved_issue,
        "explanation": resolved_explanation,
        "impact": resolved_impact,
        "action": resolved_action,
        "context": dict(context or {}),
        "metadata": prepared_metadata,
        "expected": expected,
        "actual": actual,
    }
    result.update(build_log_entry(result))
    emit_host_error(
        result,
        host_target=host_target,
        host_raise_method=host_raise_method,
        attribute_name=attribute_name,
        message=message,
        expected_value=expected_value,
        actual_value=actual_value,
    )
    return result


def check_required(
    metadata,
    value,
    field_name,
    context=None,
    issue=None,
    explanation=None,
    impact=None,
    action=None,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    passed = value not in (None, "", [])
    merged_context = dict(context or {})
    merged_context.setdefault("field_name", field_name)
    if not passed:
        issue = issue or "%s is missing" % field_name
    else:
        issue = None
        explanation = None
        impact = None
        action = None
    return emit_result(
        metadata=metadata,
        passed=passed,
        issue=issue,
        explanation=explanation,
        impact=impact,
        action=action,
        context=merged_context,
        actual=value,
        host_target=host_target,
        host_raise_method=host_raise_method,
        attribute_name=attribute_name,
        message=message,
        expected_value=expected_value,
        actual_value=actual_value,
    )


def check_equal(
    metadata,
    actual,
    expected,
    field_name,
    context=None,
    issue=None,
    explanation=None,
    impact=None,
    action=None,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    passed = actual == expected
    merged_context = dict(context or {})
    merged_context["field_name"] = field_name
    if not passed:
        issue = issue or "%s does not match expected value" % field_name
    else:
        issue = None
        explanation = None
        impact = None
        action = None
    return emit_result(
        metadata=metadata,
        passed=passed,
        issue=issue,
        explanation=explanation,
        impact=impact,
        action=action,
        context=merged_context,
        expected=expected,
        actual=actual,
        host_target=host_target,
        host_raise_method=host_raise_method,
        attribute_name=attribute_name,
        message=message,
        expected_value=expected_value,
        actual_value=actual_value,
    )


def check_within_tolerance(
    metadata,
    actual,
    expected,
    tolerance,
    field_name,
    context=None,
    issue=None,
    explanation=None,
    impact=None,
    action=None,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    difference = None
    passed = False
    tolerance = 0.0 if tolerance is None else tolerance
    try:
        difference = abs(actual - expected)
        passed = difference <= tolerance
    except TypeError:
        passed = False
    merged_context = dict(context or {})
    merged_context["field_name"] = field_name
    merged_context["tolerance"] = tolerance
    merged_context["difference"] = difference
    if not passed:
        issue = issue or "%s is outside tolerance" % field_name
    else:
        issue = None
        explanation = None
        impact = None
        action = None
    return emit_result(
        metadata=metadata,
        passed=passed,
        issue=issue,
        explanation=explanation,
        impact=impact,
        action=action,
        context=merged_context,
        expected=expected,
        actual=actual,
        host_target=host_target,
        host_raise_method=host_raise_method,
        attribute_name=attribute_name,
        message=message,
        expected_value=expected_value,
        actual_value=actual_value,
    )


def check_roll_forward(
    metadata,
    beginning_balance,
    activity_delta,
    ending_balance,
    field_name,
    tolerance=0.0,
    context=None,
    issue=None,
    explanation=None,
    impact=None,
    action=None,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    expected_ending_balance = None
    difference = None
    passed = False
    try:
        expected_ending_balance = beginning_balance + activity_delta
        difference = ending_balance - expected_ending_balance
        passed = abs(difference) <= tolerance
    except TypeError:
        passed = False

    merged_context = dict(context or {})
    merged_context["field_name"] = field_name
    merged_context["beginning_balance"] = beginning_balance
    merged_context["activity_delta"] = activity_delta
    merged_context["computed_expected_ending_balance"] = expected_ending_balance
    merged_context["difference"] = difference
    merged_context["tolerance"] = tolerance

    if not passed:
        issue = issue or "%s roll-forward does not reconcile" % field_name
    else:
        issue = None
        explanation = None
        impact = None
        action = None

    return emit_result(
        metadata=metadata,
        passed=passed,
        issue=issue,
        explanation=explanation,
        impact=impact,
        action=action,
        context=merged_context,
        expected=expected_ending_balance,
        actual=ending_balance,
        host_target=host_target,
        host_raise_method=host_raise_method,
        attribute_name=attribute_name,
        message=message,
        expected_value=expected_value,
        actual_value=actual_value,
    )


def result_to_log_message(result):
    normalized = coerce_result_item(result)
    parts = [
        "[%s]" % normalized.get("status"),
        "[%s]" % normalized.get("severity"),
        "[%s]" % normalized.get("script_name_display"),
    ]
    if normalized.get("issue_code"):
        parts.append("issue_code=%s" % normalized.get("issue_code"))
    if normalized.get("issue"):
        parts.append("issue=%s" % normalized.get("issue"))
    if normalized.get("explanation"):
        parts.append("explanation=%s" % normalized.get("explanation"))
    if normalized.get("impact"):
        parts.append("impact=%s" % normalized.get("impact"))
    if normalized.get("action"):
        parts.append("action=%s" % normalized.get("action"))
    if normalized.get("expected") is not None:
        parts.append("expected=%s" % normalized.get("expected"))
    if normalized.get("actual") is not None:
        parts.append("actual=%s" % normalized.get("actual"))
    if normalized.get("context"):
        parts.append("context=%s" % normalized.get("context"))
    return " ".join(parts)


def resolve_log_level_name(result):
    normalized = coerce_result_item(result)
    if normalized.get("passed"):
        return "INFO"
    severity = str(normalized.get("severity") or "WARNING").upper()
    if severity in SEVERITY_RANK:
        return severity
    return "WARNING"


def build_log_entry(result):
    normalized = coerce_result_item(result)
    log_level_name = resolve_log_level_name(normalized)
    return {
        "log_level_name": log_level_name,
        "log_method_name": log_level_name.lower(),
        "log_message": result_to_log_message(normalized),
    }


def resolve_numeric_severity(result):
    normalized = coerce_result_item(result)
    threshold = coerce_int(normalized.get("threshold"))
    if threshold is not None:
        return threshold
    severity = str(normalized.get("severity") or "WARNING").upper()
    return SEVERITY_TO_THRESHOLD.get(severity, 3)


def emit_host_error(
    result,
    host_target=None,
    host_raise_method="raise_error",
    attribute_name=None,
    message=None,
    expected_value=None,
    actual_value=None,
):
    normalized = coerce_result_item(result)
    if not host_target:
        return normalized
    if normalized.get("passed"):
        return normalized

    if not hasattr(host_target, host_raise_method):
        raise AttributeError("Host target does not expose method %s" % host_raise_method)

    attribute_name = attribute_name or normalized.get("metadata", {}).get("attribute_name") or normalized.get("context", {}).get("field_name")
    message = message or normalized.get("issue") or normalized.get("metadata", {}).get("description") or normalized.get("script_name_display")
    if expected_value is None:
        expected_value = normalized.get("expected")
    if actual_value is None:
        actual_value = normalized.get("actual")

    getattr(host_target, host_raise_method)(
        severity=resolve_numeric_severity(normalized),
        message=message,
        attribute_name=attribute_name,
        expected_value=expected_value,
        actual_value=actual_value,
    )
    return normalized


def coerce_result_item(item):
    if hasattr(item, "to_dict"):
        item = item.to_dict()
    if not isinstance(item, dict):
        raise TypeError("Result item must be a dict.")
    normalized = dict(item)
    normalized["script_name_display"] = normalized.get("script_name_display")
    normalized["function_key"] = normalized.get("function_key") or normalize_key(normalized.get("script_name_display") or "")
    normalized["passed"] = coerce_bool(normalized.get("passed"))
    normalized["status"] = normalized.get("status") or ("PASS" if normalized["passed"] else "FAIL")
    normalized["severity"] = normalized.get("severity") or ("INFO" if normalized["passed"] else "WARNING")
    normalized["threshold"] = coerce_int(normalized.get("threshold"))
    normalized["context"] = dict(normalized.get("context") or {})
    normalized["metadata"] = dict(normalized.get("metadata") or {})
    return normalized


def is_failure_result(result):
    return not coerce_result_item(result).get("passed")


def summarize_results(results, minimum_severity=None, include_results=False):
    normalized_results = [coerce_result_item(item) for item in (results or [])]
    summary = {
        "total": len(normalized_results),
        "pass": 0,
        "fail": 0,
        "by_severity": {},
        "highest_severity": None,
    }

    highest_rank = -1
    for result in normalized_results:
        if result.get("passed"):
            summary["pass"] += 1
        else:
            summary["fail"] += 1
            severity = result.get("severity") or "WARNING"
            summary["by_severity"][severity] = summary["by_severity"].get(severity, 0) + 1
            rank = SEVERITY_RANK.get(severity, 0)
            if rank > highest_rank:
                highest_rank = rank
                summary["highest_severity"] = severity

    if minimum_severity:
        minimum_rank = SEVERITY_RANK.get(minimum_severity, 0)
        summary["findings_at_or_above"] = [
            result for result in normalized_results
            if (not result.get("passed")) and SEVERITY_RANK.get(result.get("severity"), 0) >= minimum_rank
        ]

    if include_results:
        return {
            "summary": summary,
            "results": normalized_results,
        }
    return summary
