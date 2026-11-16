ASAP2 Parameter Management — 基于真实系统对象的案例与处理方案

我结合你上传的 ASAP_KNOWLEDGE_CONTEXT_20261025(3).md，重点检查了以下 ASAP2 能力：Global Functions、Deal/Group/Asset/Bond Objects、Periodic Data、Payment Inputs、Symbol Objects、Global Function Debugging，以及 Validation Errors。

可以把各种情况归纳为 15 种 Parameter Dependency Scenarios。这些情况涵盖从直接传参、嵌套 GF、同名参数，到 Class State、跨 Period 数据和动态调用的主要问题。

首先说明一个重要边界：

deal.params["MaxRate"] 是我们之前讨论的新增功能，不是这份 ASAP2 Knowledge 已确认支持的现有 API。

当前文档已确认支持的是 deal.fieldname、deal.periodics[period].field、payment_inputs[name].InputValue、gf[...] 等访问方式。下面会明确区分现有系统能力和建议增加的功能。

一、统一的管理逻辑

不论 Python Script 有多复杂，都应该把一个参数的生命周期理解为：

Source

Deal Settings · ASAP2 Objects · Literal · GF Output

Binding

哪个 Function、哪次调用、哪个参数接收它

Transformation

默认值 · 赋值 · 计算 · Override · Class Mutation

Consumer / Result

Calculation · Validation · Bond Payment · Reporting

每个 Parameter 应当具有自己的 Source Identity。每次被 Function 使用时，另外记录独立的 Binding Identity。

例如：

Source:
    deal.params["MaxRate"]
Bindings:
    Fa@v2 / call #1 / MaxRate
    Fb@v1 / call #1 / MaxRate
    Fa@v2 / call #2 / MaxRate

这样才可以准确比较 Fa(MaxRate) 和 Fb(MaxRate)，也可以区分同一个 Fa 的两次调用。

二、15 种实际场景：举例与对应处理

下面所有 Fa、Fb、ValidationEngine 示例均为说明拟议分析器而编写的示意代码；涉及现有 ASAP2 API 的案例会注明文档依据。

Case 1 — Direct Parameter Passing

显式参数

gf.Fa(MaxRate=5)
gf.Fb(MaxRate=7)

需要识别： 两个 Functions 都有 MaxRate 参数，但它们的实际 Binding Values 分别为 5 和 7。

处理：

* 建立 Fa.MaxRate 和 Fb.MaxRate 两条 Binding Records。
* 分别记录值、来源 LITERAL、调用位置。
* 显示 Different Values；只有业务规则要求相同时才标为 Conflict。

不需要自动把 5 和 7 添加到 Deal Settings。只有确定它们属于需要维护的业务配置时，才建议迁移。

Case 2 — Function Default vs Explicit Override

默认参数

def Fa(MaxRate=5):
    return MaxRate
gf.Fa()          # Uses default 5
gf.Fa(MaxRate=7) # Explicit override 7

需要识别： Default Value 与 Actual Bound Value 不一定相同。

处理： 分开记录 default_value=5、binding_type=DEFAULT/EXPLICIT、effective_input=5/7。

如果 Function Version 改变，默认值从 5 变成 6，需要重新评估所有依赖默认值的调用，而不是所有调用都重新审核。

Case 3 — Shared Deal Parameter

共享配置

gf.Fa(MaxRate=deal.params["MaxRate"])
gf.Fb(MaxRate=deal.params["MaxRate"])

假设 Deal Settings 中 MaxRate = 5。

需要识别： 两个独立的 Function Parameters 使用同一个 Source。

处理：

* 在 Deal Settings 只维护一项 MaxRate。
* 在 Lineage 中显示两个 Consumers。
* 修改配置时，报告受影响的 Functions、Scripts 和 Portfolios。
* 分别保留函数内部转换后的值，不因共享 Source 就自动合并 Effective Values。

这是你希望 deal.params 实现的最基础、也最重要的业务功能。

Case 4 — Same Parameter Name, Different Sources

需要区分身份

gf.Fa(MaxRate=deal.params["MaxRate"])
gf.Fb(MaxRate=bonds["A1"].setup.MaxRate)

第二个 MaxRate 是假设字段，用于演示同名不同来源。

需要识别： MaxRate 这个名字相同，但 Source Scope 分别为 Deal 和 Bond。

处理： 按完整 Source Path 分类，不按 Parameter Name 去重。

DEAL / MaxRate
BOND / A1 / MaxRate

如果业务上要求 Bond Cap 与 Deal Cap 相同，可以建立 MUST_MATCH 规则；否则它们是两个独立参数。

现有 ASAP2 Scripting Manual 已确认通过 bonds[bondname].setup 访问 Bond Setup 对象，但是否存在名为 MaxRate 的具体字段，应以实际字段目录为准。

Case 5 — Same Source, Different Calculations

派生值

def Fa(MaxRate):
    return MaxRate / 100.0
def Fb(MaxRate):
    return (MaxRate + 1.0) / 100.0

假设两者收到的都是 5：

Fa.MaxRate input = 5
    -> output = 0.05
Fb.MaxRate input = 5
    -> output = 0.06

处理： Source 和 Argument Binding 分别记录，再为各自的 Transformation 建立下游节点。

这里没有参数冲突，只有不同计算规则。

如果两者原本要求输出一致，才需要另设 Calculation Consistency Validation。

Case 6 — Nested Global Functions

递归依赖

def Fa(MaxRate):
    adjusted = gf.Fb(MaxRate)
    return adjusted * 1.1

这里 Fa 的计算依赖 Fb 的输出。Fb 又可能继续调用其他 Global Functions。

处理： 递归展开依赖关系，而不是只看到最外层的 Fa(MaxRate)。

MaxRate
  -> Fa.MaxRate
      -> Fb.MaxRate
          -> Fb.output
      -> Fa.output

实际 ASAP2 文档已有类似的 GF 计算案例：gf['agg_cumm_real_loss'] 通过读取 Subpool 的 prior-period 和 current-period 数据计算累计损失。它可以直接成为另一个 Function 的上游数据源。

遇到递归循环时应终止静态展开并标记 POTENTIAL_CYCLE，不能无限扫描。

Case 7 — Local Variable Reassignment

变量重新赋值

max_rate = 5
max_rate = max_rate + 1
max_rate = max_rate / 100

处理： 使用类似 SSA 的逻辑记录不同赋值版本：

max_rate#1 = 5
max_rate#2 = 6
max_rate#3 = 0.06

不需要在 Deal Settings 建立三项 MaxRate。这些只是同一个 Function 内部的计算过程。

ASAP2 Knowledge 还有一个很有价值的实际案例：

gf.PayIntProrata(
    Certs_Grp1,
    by="intdue",
    ida=AvailDistAmt_Grp1
)

文档指出，如果不把 Function 的返回值重新赋给 AvailDistAmt_Grp1，这个本地变量会保持原值，而且可能没有 Runtime Error。正确模式是：

AvailDistAmt_Grp1 = gf.PayIntProrata(
    Certs_Grp1,
    by="intdue",
    ida=AvailDistAmt_Grp1
)

这说明 Lineage 除了参数传递，还必须识别 Returned Value 是否被 Consumer 使用。否则会产生一种危险情况：代码执行成功，但后续计算继续使用旧值。

Case 8 — Class Attributes and Object State

对象状态

class RateManager(object):
    def __init__(self, MaxRate):
        self.MaxRate = MaxRate
    def calculate(self, rate):
        return min(rate, self.MaxRate)
manager = RateManager(5)
result_a = manager.calculate(6)
manager.MaxRate = 7
result_b = manager.calculate(6)

需要识别： self.MaxRate 是同一个 Object Instance 的可变属性，发生过 State Mutation。

处理：

* 将 RateManager 的实例与 RateManager.MaxRate 属性分开标识。
* 追踪 Constructor Binding 和后续 Assignment。
* 实际执行时可记录 before=5、after=7。
* 如果不同 instances 使用不同值，不应把它们合并。

对于动态 Class State，静态分析可能只能识别潜在赋值，无法保证恢复完整的执行状态。

建议让自定义 Class 支持只读 Dependency Contract，作为静态扫描的补充。

Case 9 — ASAP2 Function Input Source Selection

来源容易混淆

这是 Knowledge 中一个特别适合用来说明 Parameter Comparison 的真实案例：

rate_a = deal.get_index_value(
    "SOFR",
    deal_level=True
)
rate_b = deal.get_index_value(
    "SOFR",
    deal_level=False
)

两个调用使用完全相同的 Index Name，但 deal_level 的取值不同。

根据 Scripting Manual，deal.get_index_value() 的 deal_level 默认值为 False，用于区分 Deal-Level 和 Global-Level Index Source。

处理： 在 Parameter Comparison 中必须显示 Function Arguments，尤其是能够影响 Source Selection 的参数。

Function: deal.get_index_value
Call A:
    index_name = SOFR
    deal_level = True
    source = Deal-Level Index
Call B:
    index_name = SOFR
    deal_level = False
    source = Global-Level Index

即使两次返回的数值碰巧相同，也不能视为相同来源。

另一个类似案例是 deal.get_currency_conversion_rate()。其 deal_level 和 is_src_to_dest 分别影响 Rate Source 和兑换方向，因此应作为调用语义的一部分进行追踪。

Case 10 — Current vs Prior Period Data

时间作用范围

prior_balance = deal.periodics[period - 1].EndSchBal
current_balance = deal.periodics[period].EndSchBal

这是 ASAP2 已有的 Periodic Object 访问模式；EndSchBal 是 Scripting Manual 中列出的 Deal Periodic Field。

处理： Parameter Identity 必须包含 Period。

Deal A / Period 64 / EndSchBal
Deal A / Period 65 / EndSchBal

不能只存：

EndSchBal = 100000

否则系统无法区分 Current、Prior 和 Historical Values。

如果 Function 使用 period-1，Lineage 应记录 Relative Period Expression，运行时再解析实际 Period。

Case 11 — Required vs Optional Payment Inputs

需要运行时检查

这是 Knowledge 中已经明确存在的机制：

payment_inputs["PayInNumR"].InputValue
payment_inputs["PayInFlagR"].InputValue
payment_inputs["PayInDateR"].InputValue

Scripting Manual 指出：

* 非必需的 Payment Input，在缺失时可能返回 0、False 或 None。
* 必需的 Payment Input 缺失时，可能返回 None。
* 当执行 Generate Bond Payment 时，系统会阻止缺失必需 Payment Inputs 的处理。

处理： Pre-Validation 必须根据 required、Data Type、Period 和 Processing Step 判断，而不能简单用 if not value。

例如：

Payment Input A
    required = False
    value = 0
    status = VALID_DEFAULT
Payment Input B
    required = True
    value = None
    status = MISSING_REQUIRED

这里也说明你之前提出的 Setup Pre-Validation 应区分两类：

* Setup 阶段检查 Parameter Definition 和固定 Deal Configurations。
* Periodic 阶段检查当期必需输入是否已提供。

只在 Setup 检查一次，并不能保证后续所有 Payment Periods 的 Input Readiness。

Case 12 — User-Defined Variables and Symbol Objects

脚本变量共享

ASAP2 提供了通过 Symbol Object 读取 Waterfall Script 变量的方式：

# Waterfall Script
a = 10
# Supported downstream script context
value = symbols[period]["a"]

Scripting Manual 明确描述了 symbols[period][variable_name]，同时规定了 Symbol Object 的适用脚本范围。

处理：

Source:
    Waterfall Script / Variable a
Published As:
    symbols[period]["a"]
Consumer:
    Bond Validation / Reporting

这不是一个新的 Deal Settings Parameter，而是跨脚本传递的 Computed / Runtime Value。

如果另一个 Function 也定义了局部变量 a，不能仅凭名称把它当成同一个 Symbol。

Case 13 — Calculated Data Persisted Across Scripts

持久化计算结果

ASAP2 支持通过 write_calc_data 将数据写入 PeriodicCalc，并通过以下方式读取：

for item in deal.periodics[period].get_calc_datas():
    print(item.CalcName, item.CalcValues)

这属于文档中已确认的 Deal-Periodic Calculation Data Access。

处理： Lineage 不仅记录 Python Function Return，还要记录 Data Persistence Boundary。

Calculation Function
    -> write_calc_data
        -> PeriodicCalc / Deal / Period / CalcName
            -> get_calc_datas
                -> Reporting Function

不能假设一个下游 Function 读取到的数据一定来自当前执行刚完成的上游 Function。系统还需要记录实际数据所属 Period、写入/更新信息，以及在可获得时关联到相应的执行记录。

这也是你后续想实现 Audit / Reproducibility 时需要的机制。

Case 14 — Dynamic Function Calls and ValidationEngine

动态解析

你的现有架构类似于：

function_name = validation_meta["gf_function_name"]
func = getattr(gf, function_name)
result = func(
    runtime_context=bonds,
    include_results=False
)

这里静态扫描未必能仅通过 getattr() 判断最终调用哪个 GF。

处理：

* 支持读取 ValidationEngine 的内部 Registry。
* 根据 portfolio_key 展开对应 Validation Keys。
* 再根据 gf_function_name 解析实际 GF。
* 在 Call Graph 中保留 portfolio → validation → gf 的关系。

如果 function_name 由运行时动态生成，而且 Registry 也无法提供完整映射，则显示 UNRESOLVED_DYNAMIC_CALL。

这不应直接当成一个 Missing Deal Parameter。

Case 15 — Function Versions and Cross-Deal Usage

版本与适用范围

假设：

Deal A -> gf.Fa (Approved v1)
Deal B -> gf.Fa (Approved v1)
Debug Session -> gf.Fa (Modified test version)

ASAP2 Knowledge 已确认 Global Function Debugging 会使用最新 approved version 创建调试副本，并允许在特定 Deal Script 内进行临时测试。系统还会标识 Debug Mode Workflow Steps。

另外，现有 Global Function Management 提供 Export Usages，可以导出 Deal 和 Global Function 的直接使用关系。

处理：

* Lineage 记录 GF Version 和 Execution Mode。
* Approved 与 Debug Versions 分开分析。
* 使用现有 Export Usages 作为 Deal-to-GF Mapping 的初始数据来源。
* 对通过 ValidationEngine 间接调用的 GFs，额外展开其 Portfolio Registry。

这样才可以回答：

“如果我修改 gf.Fa，哪些 Deals 及 Portfolios 可能受到影响？”

注意，Export Usages 已确认的能力不能直接等同于完整 Nested Dependency Coverage，后者仍需要新增分析逻辑。

三、最终如何在 UI 中管理这些情况？

我建议不是建立一个显示所有 Python Variables 的大表，而是通过两个互相关联的视图管理。

View A — Parameter Inventory

用于快速查看一个 Deal Script 的全部依赖。

Source Type	示例	管理方式
Deal Configuration	deal.params[“MaxRate”]	Analyst 设置、确认
Direct Argument	Fa(MaxRate=5)	跟踪 Call Site
Function Default	def Fa(MaxRate=5)	跟踪 Definition / Version
Runtime Field	deal.periodics[period].EndSchBal	检查数据、Period
Payment Input	payment_inputs[“PayInNumR”]	检查 Required / Value
Derived Result	gf.Fb() 的输出	Lineage Tracking
Class State	manager.MaxRate	State / Mutation Tracking
Persisted Data	PeriodicCalc	追踪读写关系

View B — Parameter Comparison

这是你之前提出的 Fa(MaxRate) vs Fb(MaxRate) 查询功能。

Cross-Function Parameter Comparison

Different SourcesTransformationsDefaults

Fa.MaxRate

5

deal.params'MaxRate'

Fb.MaxRate

7

Hardcoded literal 7

Difference: Different input sources and values

Recommended handling: Review if both functions should share the same deal configuration

切换上方情景，可以看到系统应如何解释不同类型的参数差异。示例数据不代表真实 Deal。

业务端不应简单地将所有 Difference 标记为 Error。应当允许为参数关系定义 INDEPENDENT、MUST_MATCH、DERIVED_FROM 或 UNKNOWN。

四、技术实现建议（精简版）

建议 PwC 实现以下四个核心数据结构，而不需要建设一个完整的 Python Debugger。

数据结构	主要字段	目的
ParameterSource	Source ID, path, type, unit, scope	确定参数真实身份
FunctionBinding	GF name/version, call site, argument, source ID	确定参数如何传入
DependencyEdge	From, to, transformation, resolution status	追踪嵌套调用和转换
ExecutionSnapshot	Deal, period, invocation, resolved value, version	保存实际执行证据

发现机制采用：

* Static AST Analysis：分析直接传参、赋值和可确定的 GF 调用。
* Registry / Class Contracts：解析 ValidationEngine、动态注册和 Class Dependencies。
* Optional Runtime Tracing：针对无法静态确定的实际值或状态进行验证。

每条依赖必须标注是 STATIC、DECLARED 还是 OBSERVED，避免把静态推导的可能性误认为已经执行的事实。

Pre-Validation 则应根据类型进行处理：

* MISSING_REQUIRED：必要配置或输入缺失。
* TYPE_MISMATCH：输入数据类型不符合要求。
* SOURCE_CONFLICT：业务上要求一致的参数来源不一致。
* UNCONFIRMED：Deal Settings 已有值但尚未确认。
* UNRESOLVED：动态依赖无法静态确定。
* POTENTIAL_CYCLE：检测到可能的递归调用循环。

对于真正需要阻断的错误，可以把结构化结果映射到 ASAP2 现有的 deal.raise_error(severity, ...)。根据 Knowledge，ASAP2 的原生 Severity 是 1–5，并结合 Deal-Level Validation Error Threshold 决定是否阻断下一步。

五、我建议的开发优先级

Phase 1 — Input Discovery & Classification

识别所有直接调用、基础 GF 参数和 ASAP2 对象字段；区分 Deal Settings、Runtime、Derived 和 Default Inputs，并生成可下载报告。

Phase 2 — Cross-Function Comparison & Dependency Graph

实现 Fa.MaxRate vs Fb.MaxRate 比较、Nested GF 解析、Call Site 区分、Class Contracts 和 ValidationEngine Portfolio Expansion。

Phase 3 — Runtime Lineage & Impact Analysis

记录实际有效值、状态变化、历史 GF 版本，并支持跨 Deal / Shelf 的变更影响分析。

最终，Deal Settings 管理需要人工维护的参数值，Dependency Explorer 管理全部输入和调用关系，Pre-Validation 负责发现缺失与不一致，ValidationEngine 继续负责实际 Validation Execution 和 Reporting。

这样既符合上传的 ASAP2 Knowledge 中现有的数据对象、Global Functions 和 Processing Steps，也能兼容你未来要求 PwC 新增的 deal.params、递归扫描和参数比较能力，而不必把所有 Python Variables 都搬到 Deal Settings 中。