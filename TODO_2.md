可以。你这个 validate_next_index_rate.py 正好就是我说的 caller：它调用 ValidationHelperApi(operation="finalize_scan", ...)。现在它的结构是：

results = scan_next_index_rate(bds, p=p)
return ValidationHelperApi(
    operation="finalize_scan",
    results=results,
    return_results=return_results,
    interrupt_after_scan=interrupt_after_scan,
    ...
)

也就是说，目前 validate_next_index_rate() 把中断逻辑完全交给了 validation_api.finalize_scan()。而 finalize_scan() 现在明确禁止 return_results=True 和 interrupt_after_scan=True 同时使用。 ￼

⸻

你现在已经可以这样中断

当前默认参数是：

return_results=False
interrupt_after_scan=True

所以直接这样调用就会中断：

validate_next_index_rate(bonds, period - 1)

因为 finalize_scan() 里有这段逻辑：

if interrupt_after_scan and summary.get("fail", 0) > 0:
    ...
    raise ValueError(message)

所以只要有 fail，就会 raise ValueError。 ￼

⸻

但如果你想“先拿结果，再由 caller 中断”

那就不要让 finalize_scan() 自己中断。应该让 validate_next_index_rate() 先拿 compact results，然后自己判断是否 raise。

也就是把你的 caller function 改成下面这种结构。

推荐改法

def validate_next_index_rate(
    bds,
    p: int = None,
    return_results: bool = False,
    interrupt_after_scan: bool = True,
):
    """
    Validates that the Next Index Rate is populated for floating-rate bonds.
    Behavior:
    - return_results=False, interrupt_after_scan=True:
      interrupt immediately if validation fails.
    - return_results=True, interrupt_after_scan=False:
      return structured validation results only.
    - return_results=True, interrupt_after_scan=True:
      scan results first, then caller raises ValueError after preparing message.
    """
    results = scan_next_index_rate(bds, p=p)
    summary = ValidationHelperApi(
        operation="summarize_results",
        results=results,
    )
    if return_results:
        output_results = ValidationHelperApi(
            operation="finalize_scan",
            results=results,
            return_results=True,
            interrupt_after_scan=False,
            error_prefix="ValidateNextIndexRate failed after scan",
            identifier_key="bond_name",
            identifier_label="bonds",
        )
        if interrupt_after_scan and summary.get("fail", 0) > 0:
            failed_bonds = [
                item.get("context", {}).get("bond_name")
                for item in output_results
                if not item.get("passed")
            ]
            raise ValueError(
                "ValidateNextIndexRate failed after scan: %s finding(s), highest severity=%s, bonds=%s"
                % (
                    summary.get("fail", 0),
                    summary.get("highest_severity"),
                    failed_bonds,
                )
            )
        return output_results
    if interrupt_after_scan and summary.get("fail", 0) > 0:
        failed_bonds = [
            item.get("context", {}).get("bond_name")
            for item in results
            if not item.get("passed")
        ]
        raise ValueError(
            "ValidateNextIndexRate failed after scan: %s finding(s), highest severity=%s, bonds=%s"
            % (
                summary.get("fail", 0),
                summary.get("highest_severity"),
                failed_bonds,
            )
        )
    return summary.get("fail", 0) == 0

⸻

关键点

这里最重要的是这句：

output_results = ValidationHelperApi(
    operation="finalize_scan",
    results=results,
    return_results=True,
    interrupt_after_scan=False,
    ...
)

也就是说，即使外层 validate_next_index_rate() 收到了 interrupt_after_scan=True，也不要原样传给 finalize_scan()。

否则还是会触发你现在 validation_api.py 里面的限制：

if return_results and interrupt_after_scan:
    raise ValueError("return_results and interrupt_after_scan cannot both be True.")

正确逻辑是：

scan_next_index_rate()
        ↓
拿到 results
        ↓
summarize_results()
        ↓
需要 return_results？先整理 results
        ↓
需要 interrupt_after_scan？caller 自己 raise ValueError

⸻

更干净的写法：拆出 build error message

为了避免重复拼 message，可以在 validate_next_index_rate.py 里加一个 helper：

def _build_validation_error_message(results, summary):
    failed_bonds = [
        item.get("context", {}).get("bond_name")
        for item in results
        if not item.get("passed")
    ]
    return (
        "ValidateNextIndexRate failed after scan: %s finding(s), highest severity=%s, bonds=%s"
        % (
            summary.get("fail", 0),
            summary.get("highest_severity"),
            failed_bonds,
        )
    )

然后主函数写成：

def validate_next_index_rate(
    bds,
    p: int = None,
    return_results: bool = False,
    interrupt_after_scan: bool = True,
):
    results = scan_next_index_rate(bds, p=p)
    summary = ValidationHelperApi(
        operation="summarize_results",
        results=results,
    )
    if return_results:
        output_results = ValidationHelperApi(
            operation="finalize_scan",
            results=results,
            return_results=True,
            interrupt_after_scan=False,
            error_prefix="ValidateNextIndexRate failed after scan",
            identifier_key="bond_name",
            identifier_label="bonds",
        )
        if interrupt_after_scan and summary.get("fail", 0) > 0:
            raise ValueError(_build_validation_error_message(output_results, summary))
        return output_results
    if interrupt_after_scan and summary.get("fail", 0) > 0:
        raise ValueError(_build_validation_error_message(results, summary))
    return summary.get("fail", 0) == 0

⸻

使用方式

1. 生产环境：只要失败就中断

validate_next_index_rate(bonds, period - 1)

这个会在发现 missing NextIndexRate 时直接 raise ValueError。

⸻

2. Debug：只返回结果，不中断

results = validate_next_index_rate(
    bonds,
    period - 1,
    return_results=True,
    interrupt_after_scan=False,
)
fs.output(results)

⸻

3. 扫描后由 caller 中断

results = validate_next_index_rate(
    bonds,
    period - 1,
    return_results=True,
    interrupt_after_scan=True,
)

注意：如果有 fail，这个函数最终还是会 raise ValueError，所以外部不会真正拿到 results 作为返回值。因为一旦 raise，正常 return 就不会发生。

如果你想 既输出结果，又中断 ASAP2 流程，可以这样：

try:
    results = validate_next_index_rate(
        bonds,
        period - 1,
        return_results=True,
        interrupt_after_scan=False,
    )
    fs.output(results)
    summary = ValidationHelperApi(
        operation="summarize_results",
        results=results,
    )
    if summary.get("fail", 0) > 0:
        raise ValueError(
            "ValidateNextIndexRate failed after scan: %s finding(s), highest severity=%s"
            % (
                summary.get("fail", 0),
                summary.get("highest_severity"),
            )
        )
except ValueError as exc:
    raise

⸻

我建议你的最终设计

finalize_scan() 只负责：

normalize results
summarize results
compact return results

validate_next_index_rate() 负责：

是否 raise ValueError

这样你的每个 validation caller，例如：

validate_next_index_rate.py
validate_coupon.py
validate_balance.py
validate_interest.py

都可以有统一模式：

results = scan_xxx()
summary = summarize_results(results)
if return_results:
    return compact_results
if interrupt_after_scan and fail:
    raise ValueError(...)
return True / False

这比把所有中断逻辑都塞进 validation_api.py 更灵活，尤其适合 ASAP2 这种每个 validation script 都可能需要不同 interrupt message 的场景。
