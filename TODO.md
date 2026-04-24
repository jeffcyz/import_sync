不建议按“先 return_results 再 interrupt_after_scan”这样做。

原因很直接：Python 里一旦 return 执行，函数就结束了，后面的 raise ValueError(...) / interrupt 不会再执行。 你现在代码里也明确禁止两者同时为 True：

if return_results and interrupt_after_scan:
    raise ValueError("return_results and interrupt_after_scan cannot both be True.")

而且当前流程是：

summary = summarize_results(normalized_results)
if interrupt_after_scan and summary.get("fail", 0) > 0:
    raise ValueError(message)
if return_results:
    return results
return summary.get("fail", 0) == 0

也就是说现在设计上是三选一：

1. interrupt_after_scan=True：有 fail 就直接 raise ValueError
2. return_results=True：返回 results
3. 两个都 False：返回 True / False

代码位置大概在 finalize_scan() 的结尾部分，当前实现明确先判断二者不能同时开启，然后在 fail 时 raise，最后才 return results。 ￼

⸻

正确做法取决于你的目标

如果你的目标是：

扫描结束后，既要拿到完整 validation results，又要在有 fail 时 interrupt 流程

那么不要用“return 后再 interrupt”。应该改成下面两种模式之一。

⸻

方案 A：推荐，返回 payload，让 caller 决定是否 interrupt

把 finalize_scan() 改成永远返回一个结构化对象：

def finalize_scan(
    results,
    return_results=False,
    interrupt_after_scan=False,
    error_prefix="Validation failed after scan",
    identifier_key=None,
    identifier_label=None,
):
    normalized_results = [coerce_result_item(item) for item in (results or [])]
    summary = summarize_results(normalized_results)
    should_interrupt = interrupt_after_scan and summary.get("fail", 0) > 0
    payload = {
        "success": summary.get("fail", 0) == 0,
        "should_interrupt": should_interrupt,
        "summary": summary,
    }
    if return_results:
        payload["results"] = normalized_results
    if should_interrupt:
        message = "%s: %s finding(s), highest severity=%s" % (
            error_prefix,
            summary.get("fail", 0),
            summary.get("highest_severity"),
        )
        if identifier_key:
            failed_identifiers = [
                result.get("context", {}).get(identifier_key)
                for result in normalized_results
                if not result.get("passed")
            ]
            message = "%s, %s=%s" % (
                message,
                identifier_label or identifier_key,
                failed_identifiers,
            )
        payload["interrupt_message"] = message
    return payload

然后 caller 这样用：

scan_output = ValidationHelperApi(
    "finalize_scan",
    results=validation_results,
    return_results=True,
    interrupt_after_scan=True,
)
# 先拿到结果
results = scan_output.get("results")
summary = scan_output.get("summary")
# caller 自己决定何时 interrupt
if scan_output.get("should_interrupt"):
    raise ValueError(scan_output.get("interrupt_message"))

这个逻辑最干净：finalize_scan 负责整理结果，caller 负责中断流程。

⸻

方案 B：保留 interrupt，但把 results 放进自定义 Exception

如果你必须让 finalize_scan() 自己 interrupt，同时又希望外层能拿到 results，可以定义一个 custom exception：

class ValidationScanError(ValueError):
    def __init__(self, message, summary=None, results=None):
        ValueError.__init__(self, message)
        self.summary = summary
        self.results = results

然后：

if interrupt_after_scan and summary.get("fail", 0) > 0:
    raise ValidationScanError(
        message,
        summary=summary,
        results=normalized_results if return_results else None,
    )

外层这样接：

try:
    output = ValidationHelperApi(
        "finalize_scan",
        results=validation_results,
        return_results=True,
        interrupt_after_scan=True,
    )
except ValidationScanError as exc:
    results = exc.results
    summary = exc.summary
    raise

但这个方案对 ASAP2 / IronPython 环境不一定最稳，因为宿主系统可能只显示 exception message，不一定方便访问 exception object 上的 custom attributes。

⸻

我的建议

对你这个 validation_api.py，不要把 return_results 放在 interrupt_after_scan 前面。这样会导致有 fail 时也不会 interrupt。

更好的设计是把语义拆开：

return_results=True

表示：返回完整扫描结果。

interrupt_after_scan=True

表示：结果里如果有 fail，payload 里标记 should_interrupt=True，由 caller 再 raise。

也就是我建议用方案 A。这样最适合后续让 Roo / Copilot / ASAP2 script manager 做统一 logging、统一报错、统一 export validation report。


是因为现在每个 result item 里面同时塞了 3 套表达同一件事的数据，不是因为 scan 跑了三遍。

现在为什么看起来冗余

在 emit_result() 里，代码先创建一个完整的 result dict，里面已经有：

script_name_display
function_key
status
passed
severity
threshold
issue_code
issue
explanation
impact
action
context
metadata
expected
actual

其中 metadata 本身又包含了很多和 top-level 重复的信息。代码位置显示 result 里同时有 top-level 字段和 "metadata": prepared_metadata。 ￼

然后这里又执行了一句：

result.update(build_log_entry(result))

这会再往同一个 result 里加入：

log_level_name
log_method_name
log_message

而 log_message 又是把 issue / explanation / impact / action / expected / actual / context 拼成一条字符串，所以视觉上像第三套重复内容。 ￼

最后 finalize_scan() 在 return_results=True 时返回的是：

return results

也就是直接返回原始 heavy results，而不是返回精简后的 normalized/compact results。 ￼

所以你看到的结构大概是：

[
  {
    # 第一组：top-level validation result
    "status": "FAIL",
    "issue": "...",
    "explanation": "...",
    "impact": "...",
    "action": "...",
    # 第二组：metadata 里又有类似信息
    "metadata": {
      "script_name_display": "...",
      "severity": "...",
      "explanation": "...",
      "impact": "...",
      "action": "..."
    },
    # 第三组：log_message 又把上面内容拼了一遍
    "log_message": "[FAIL] [ERROR] ..."
  }
]

⸻

建议精简方式

不要在 finalize_scan(return_results=True) 时直接 return results。应该加一个 compact projection。

最小修改版

在 validation_api.py 里加这两个 helper：

COMPACT_RESULT_FIELDS = (
    "script_name_display",
    "function_key",
    "status",
    "passed",
    "severity",
    "threshold",
    "issue_code",
    "issue",
    "explanation",
    "impact",
    "action",
    "context",
    "expected",
    "actual",
)
def compact_result_item(item):
    normalized = coerce_result_item(item)
    compact = {}
    for key in COMPACT_RESULT_FIELDS:
        value = normalized.get(key)
        if value is None:
            continue
        if value == {}:
            continue
        if value == []:
            continue
        compact[key] = value
    return compact
def compact_results(results):
    return [compact_result_item(item) for item in (results or [])]

然后把 finalize_scan() 里的：

if return_results:
    return results

改成：

if return_results:
    return compact_results(normalized_results)

这样返回结果会从 heavy object：

{
    "script_name_display": "...",
    "function_key": "...",
    "status": "FAIL",
    "passed": False,
    "severity": "ERROR",
    "threshold": 4,
    "issue_code": "...",
    "issue": "...",
    "explanation": "...",
    "impact": "...",
    "action": "...",
    "context": {...},
    "metadata": {...},
    "expected": "...",
    "actual": "...",
    "log_level_name": "ERROR",
    "log_method_name": "error",
    "log_message": "..."
}

精简成：

{
    "script_name_display": "...",
    "function_key": "...",
    "status": "FAIL",
    "passed": False,
    "severity": "ERROR",
    "threshold": 4,
    "issue_code": "...",
    "issue": "...",
    "explanation": "...",
    "impact": "...",
    "action": "...",
    "context": {...},
    "expected": "...",
    "actual": "..."
}

⸻

更强一点的版本：支持 compact / full 两种模式

我更建议这样改，避免以后你偶尔需要 full debug payload。

1. 修改 ValidationHelperApi()

在 operation == "finalize_scan" 这里增加：

result_view=kwargs.get("result_view", "compact"),
failures_only=kwargs.get("failures_only", False),

完整改成：

if operation == "finalize_scan":
    return finalize_scan(
        results=kwargs.get("results", []),
        return_results=kwargs.get("return_results", False),
        interrupt_after_scan=kwargs.get("interrupt_after_scan", False),
        error_prefix=kwargs.get("error_prefix", "Validation failed after scan"),
        identifier_key=kwargs.get("identifier_key"),
        identifier_label=kwargs.get("identifier_label"),
        result_view=kwargs.get("result_view", "compact"),
        failures_only=kwargs.get("failures_only", False),
    )

2. 增加 compact helper

COMPACT_RESULT_FIELDS = (
    "script_name_display",
    "function_key",
    "status",
    "passed",
    "severity",
    "threshold",
    "issue_code",
    "issue",
    "explanation",
    "impact",
    "action",
    "context",
    "expected",
    "actual",
)
def compact_result_item(item):
    normalized = coerce_result_item(item)
    compact = {}
    for key in COMPACT_RESULT_FIELDS:
        value = normalized.get(key)
        if value is None:
            continue
        if value == {}:
            continue
        if value == []:
            continue
        compact[key] = value
    return compact
def project_results(results, result_view="compact", failures_only=False):
    normalized_results = [coerce_result_item(item) for item in (results or [])]
    if failures_only:
        normalized_results = [
            item for item in normalized_results
            if not item.get("passed")
        ]
    if result_view == "full":
        return normalized_results
    if result_view == "compact":
        return [compact_result_item(item) for item in normalized_results]
    raise ValueError("Unsupported result_view: %s" % result_view)

3. 修改 finalize_scan() signature

把：

def finalize_scan(
    results,
    return_results=False,
    interrupt_after_scan=False,
    error_prefix="Validation failed after scan",
    identifier_key=None,
    identifier_label=None,
):

改成：

def finalize_scan(
    results,
    return_results=False,
    interrupt_after_scan=False,
    error_prefix="Validation failed after scan",
    identifier_key=None,
    identifier_label=None,
    result_view="compact",
    failures_only=False,
):

4. 修改 return_results 部分

把：

if return_results:
    return results

改成：

if return_results:
    return project_results(
        normalized_results,
        result_view=result_view,
        failures_only=failures_only,
    )

⸻

使用方式

默认精简返回：

validate_next_index_rate(
    bonds,
    period - 1,
    return_results=True,
    interrupt_after_scan=False,
)

只返回失败项：

ValidationHelperApi(
    operation="finalize_scan",
    results=results,
    return_results=True,
    interrupt_after_scan=False,
    result_view="compact",
    failures_only=True,
)

需要完整 debug 时：

ValidationHelperApi(
    operation="finalize_scan",
    results=results,
    return_results=True,
    interrupt_after_scan=False,
    result_view="full",
)

⸻

我的建议

保留 emit_result() 里的 metadata 和 log_message，因为它们对 debug/logging 有价值。
但是 finalize_scan(return_results=True) 默认应该返回 compact results。

也就是：内部结果可以 rich，外部返回要 clean。
