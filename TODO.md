ASAP2 Global Function 参数管理：从 Python 依赖分析到业务可视化系统

针对你现在的 ASAP2 架构，我认为需要重新定义这个需求。

你真正要解决的已经不只是 Global Function Parameter Management，而是：

如何自动发现一个 ASAP2 Script 所依赖的全部输入及其来源，追踪这些输入在嵌套 Global Functions、Class Objects 和计算过程中的传递关系，并提供一个可以检查、确认、修改和审计的可视化管理界面。

这在软件工程中涉及三个概念：

* Dependency Analysis：依赖分析。一个 Script 最终依赖哪些 Functions、Objects 和 Input Fields？
* Data Lineage：数据血缘。某个参数从哪里来，经过哪些计算或函数，最终影响什么结果？
* Configuration Management：配置管理。哪些输入值需要由 Analyst 设置、确认和维护？

这三件事相关，但不应该混为一谈。

一、首先明确：Python 中的 Parameter 和 Variable 不是一回事

假设一个 ASAP2 Script 包含：

max_rate = deal.params["MaxRate"]
reference_rate = gf.calculate_reference_rate(
    period=period
)
coupon = gf.calculate_coupon(
    reference_rate=reference_rate,
    max_rate=max_rate
)
result = gf.validate_coupon(
    bonds=bonds,
    expected_coupon=coupon
)

从 Python 语言角度，可以识别出多种数据：

数据	类型	是否需要 Analyst 管理
deal.params[“MaxRate”]	Deal-level configuration	是
period	ASAP2 runtime object	通常不需要
reference_rate	Function-derived variable	通常不需要
max_rate	Local variable	不应单独管理
coupon	Computed variable	不应单独管理
bonds	ASAP2 runtime data	通常不需要
expected_coupon	Function argument	需要追踪，但不一定需要配置

这里有一个关键区别：

所有需要追踪的变量，不一定都是需要人工维护的参数。

如果系统把每个局部变量、计算结果、Function Argument 和 Class Attribute 全部放到 Deal Settings 里，就会把一个简洁的参数配置工具变成非常庞大的 Python Debugger。

因此，我建议把系统明确分成两部分：

1. Deal Parameter Manager

管理真正需要 Analyst 设置和确认的业务输入，例如 MaxRate、Tolerance、特殊 Deal Assumptions。

2. Script Dependency Explorer

展示所有 Function Calls、Function Arguments、Class State、Intermediate Results 和数据传递关系，包括用户不能直接修改的内容。

两者使用同一份底层依赖数据，但面向不同业务目的。

二、Python 中真正复杂的情况：嵌套函数和 Class State

你的 ASAP2 环境比普通的 function parameter table 更复杂，因为它至少包含以下四种依赖方式。

A. Direct Function Parameters

gf.validate_rate(bonds, max_rate=5)

可以直接识别 max_rate 的传入值。

B. Nested Global Functions

gf.validate_rate(
    gf.calculate_rate(period)
)

要继续分析 gf.calculate_rate() 内部又依赖哪些输入。

C. Class Attributes / Object State

manager = RateManager(deal)
manager.validate(bonds)

validate() 可能读取 self.max_rate，而该属性可能来自 deal.params、其他 methods 或后续修改。

D. Global / Host Variables

rate = periodic.IndexRate
deal_name = deal.setup.DealName

数据由 ASAP2 runtime 提供，不一定出现在函数签名中。

仅扫描 Global Function 的 def 语句，无法发现以上所有关系。

甚至仅扫描一个 Function 的直接调用，也无法知道这个 Script 实际需要哪些底层业务输入。

因此，你需要的是 跨函数、跨对象的递归依赖分析（Interprocedural Dependency Analysis）。

但这里还存在一个重要限制：Python 支持动态调用、动态属性和运行时修改对象，所以静态扫描不能保证识别所有执行路径。系统必须明确区分“静态发现的潜在依赖”和“实际执行观察到的依赖”。

三、我推荐的核心架构：Static Analysis + Explicit Contracts + Runtime Observation

我不建议 PwC 只做一个递归扫描 Global Function signatures 的工具。

那只能解决最简单的直接参数和部分 nested calls，无法可靠解决你已经实现的 ValidationEngine，更无法完整处理其他自定义 class 的状态。

更合理的是三层分析机制。

层级	技术	负责解决的问题
1. Static Analysis	Python AST / Source Parser	识别代码中可能存在的调用和数据依赖
2. Explicit Contracts	Function / Class Metadata	补充动态代码无法可靠推导的依赖
3. Runtime Observation	Execution Trace	验证实际执行时使用了哪些输入和调用路径

第一层：静态代码分析（Static Analysis）

Python 本身提供 ast，可以解析函数调用、变量赋值、属性访问以及关键字参数等语法结构。例如 ast.Call 可以识别调用目标和传入参数，ast.Attribute 可以识别对象属性访问。Python 3.14.7 documentation

假设：

max_rate = deal.params["MaxRate"]
result = gf.calculate_rate(
    periodic.IndexRate,
    max_rate
)

Static Analyzer 至少应该识别：

deal.params["MaxRate"]
    -> assigned to max_rate
    -> passed as second argument
    -> gf.calculate_rate()

但它还需要继续解析 gf.calculate_rate() 的源代码，直到找到更多底层输入，或者遇到无法继续解析的边界。

对于你的 ASAP2，分析流程应当是：

flowchart TD
    A["Select Deal / Script"] --> B["Parse Script Source"]
    B --> C["Discover Global Function Calls"]
    C --> D["Resolve Function Source and Version"]
    D --> E["Recursively Analyze Nested GF Calls"]
    E --> F["Inspect Variables, Parameters and Class State"]
    F --> G["Build Dependency Graph"]
    G --> H["Identify Configurable Inputs"]
    G --> I["Mark Dynamic or Unresolved Dependencies"]
    H --> J["Pre-Validation Report"]
    I --> J

这里必须增加 Function Version。

因为你前面提到 ASAP2 有 approved / unchecked Global Function versions。不同版本的代码可能具有不同依赖，不能只用函数名称表示同一个分析对象。

静态分析还可以识别调用位置、默认参数和部分 *args / **kwargs 结构。现代 Python 的 inspect.signature() 能提供函数签名，但不能单凭签名确定完整的数据来源，且部分 callable 无法被可靠 introspect。Python 3.15.2 documentation +1

对 IronPython / ASAP2，我倾向于把主要静态分析放在独立分析组件中，根据 ASAP2 实际使用的 Python 语法版本解析源码，而不是假设所有现代 CPython introspection API 在 host 中都可用。

第二层：显式依赖声明（Explicit Dependency Contracts）

这是整个设计最重要的补充。

考虑你已经有的：

engine = ValidationEngine(gf)
engine.run_portfolio(
    portfolio_key="rmbs_pmt",
    bonds=bonds,
    deal=deal
)

Python 静态分析看到的是：

ValidationEngine.run_portfolio(...)

但真正的 Global Functions 隐藏在：

self.portfolios["rmbs_pmt"] = {
    "validation_keys": [
        "validate_periodic_cls_pct",
        "validate_pmt_positive_int",
        "validate_negative_ending_balance"
    ]
}

而各个 validation key 又通过 registry 映射成真正的 gf 函数名称。

一个普通的 AST scanner 不一定能正确展开这套关系。尤其是当 portfolio 被动态更新、使用 getattr() 或运行时决定 function name 的时候。

因此，我建议让 ValidationEngine 提供一个只读的 Dependency Contract，供 PwC 的分析器使用。

例如：

{
    "component": "ValidationEngine",
    "portfolio": "rmbs_pmt",
    "global_functions": [
        "validate_periodic_cls_pct",
        "validate_pmt_positive_int",
        "validate_negative_ending_balance"
    ],
    "runtime_inputs": ["bonds", "deal", "period"]
}

这个 Contract 可以从内部 registry 自动生成，不需要 Analyst 手工登记。

对其他自定义 classes，也可以允许提供相似的 metadata，说明其外部依赖和可能输出。

这样做的优势是：分析器无需执行每个 class 的所有方法，就能先获得一个可靠的、由开发者声明的依赖边界。

特别注意：Contract 不是参数值存储表。它只是告诉系统依赖关系是什么。

实际的 MaxRate = 5 依然保存在 Deal Settings，而不是保存在 Contract 里。

第三层：运行时观察（Runtime Observation）

当静态分析无法确认某个依赖时，可以通过实际执行观察。

例如：

function_name = deal.params["ValidationFunction"]
func = getattr(gf, function_name)
result = func(bonds)

Static Analyzer 可以发现存在一个动态调用，但不一定能在不执行代码的情况下确定最终会调用哪个函数。

运行时则可能观察到：

Deal: RMBS_A
Period: 2026-10
Resolved function:
    gf.validate_negative_ending_balance
Input:
    bonds
Result:
    PASS

这可以作为 Observed Dependency 补充静态分析。

但运行时 tracing 也有两个局限：

第一，它只能证明某条执行路径实际发生过，不能保证覆盖所有可能的 if 分支、未来 periods 或异常条件。

第二，如果直接追踪所有 Python 局部变量、Class Attributes 和大型资产对象，性能与日志体积都可能不可控。

所以，我不建议在 ASAP2 中持续记录所有变量值。更适合只记录 Global Function 边界、关键配置字段读取、Class Contract 和调用关系；深层追踪按需启用。

四、最终数据模型应当是一个 Dependency Graph，而不是单纯 Parameter Table

这部分是我认为 PwC 最值得重点开发的核心能力。

假设一个 RMBS deal 有：

deal.params["MaxRate"] = 5.0
deal.params["Spread"] = 0.5
periodic.IndexRate = 4.8

一个 Global Function 计算 coupon rate，Class Object 应用 cap，另一个 Global Function 检查结果：

raw_coupon = gf.calculate_coupon(
    periodic.IndexRate,
    deal.params["Spread"]
)
policy = RatePolicy(deal.params["MaxRate"])
effective_coupon = policy.apply_cap(raw_coupon)
result = gf.validate_bond_rate(
    bonds,
    effective_coupon
)

数据血缘图应当能够展示：

flowchart TD
    A["Deal Params: MaxRate = 5.0"]
    B["Deal Params: Spread = 0.5"]
    C["Periodic: IndexRate = 4.8"]
    B --> D["gf.calculate_coupon"]
    C --> D
    D --> E["Raw Coupon = 5.3"]
    A --> F["RatePolicy Class"]
    E --> F
    F --> G["Effective Coupon = 5.0"]
    G --> H["gf.validate_bond_rate"]
    I["Runtime: bonds"] --> H
    H --> J["Validation Result"]
    classDef config fill:#e2edfa,stroke:#6488b0,color:#152c46
    classDef logic fill:#eae5f5,stroke:#8c75a8,color:#302445
    class A,B config
    class D,F,H logic

这时，用户不仅可以看到 MaxRate 的当前值，还能看到它影响哪些函数、Class Methods 和最终输出。

如果 Analyst 把 MaxRate 从 5.0 改为 5.5，系统就能够回答：

“哪些 Functions 和计算结果可能受到这次修改影响？”

这就是 Impact Analysis（变更影响分析）。

需要强调的是，这里提供的应是基于依赖图的 potential impact。如果要判断实际计算结果是否改变，仍需要执行对应的计算或测试。

这种显式描述输入与输出之间依赖边的方式，也符合数据血缘系统的设计方向；例如 OpenLineage 支持记录运行、输入、输出及明确的 lineage relationships。GitHub +1

五、业务端应该如何可视化？

我建议不要把所有能力都塞进 Deal Settings 的新参数表。

更合理的是给 Analyst 两个相互关联的界面：

* Deal Settings → Parameters：负责维护和确认可配置值。
* Deal Validation → Dependency Explorer：负责展示脚本真实依赖关系、缺失参数、调用路径和变更影响。

界面 A：Deal Settings → Parameters

这个界面主要面向 Analyst，不需要懂 Python。

Deal Parameters

Illustrative UI · RMBS_A · Setup

1 needs review

Parameter	Value	Confirmed
MaxRate	5.0	Yes
Spread	0.5	Yes
Tolerance	0.01	Pending

A real interface would also support editing, review history and an expandable “Used By” field.

每一个参数背后建议维护以下信息：

属性	业务意义
Parameter Name	MaxRate
Value / Type	5.0 / Decimal
Scope	Deal / Period / Shelf
Source	Manually configured / Inherited
Used By	哪些 Global Functions 依赖它
Confirmation	Analyst 是否已确认
Last Modified	最近修改人及时间
Effective Date	参数从哪个时期开始适用

这里的 Used By 非常重要。

它应当由 Dependency Analyzer 自动生成，而不是让 Analyst 逐一手动关联。

例如 Analyst 点击 MaxRate，可以展开：

MaxRate = 5.0
Used by:
  RatePolicy.__init__
    -> RatePolicy.apply_cap
       -> gf.validate_bond_rate
Affected scripts:
  Bond Payment
  Periodic Validation
Affected portfolios:
  rmbs_pmt

这样就把普通参数配置表提升成了具备影响分析能力的管理界面。

界面 B：Deal Validation → Dependency Explorer

这是我认为应该让 PwC 重点开发的界面。

它不只是检查参数有没有填写，而是展示 Script 的全部已发现依赖，以及哪些依赖尚未被解析。

我建议第一屏不要直接展示几十层的 Python 函数树，而是先给用户一个汇总：

Script Dependency Analysis

Illustrative results · RMBS_A · Bond Payment Script

18

Inputs

3

Configurable

1

Unconfirmed

2

Unresolved

AllDealGFIssues

Input	Origin	Status
MaxRate5.0	Deal Settings	Confirmed
Spread0.5	Deal Settings	Confirmed
Tolerance0.01	Deal Settings	Review
IndexRate4.8	Periodic Object	Resolved
expected_coupon5.0	GF output	Derived
validation_function—	Dynamic getattr	Unresolved

示例交互模型，不代表当前 ASAP2 已有这些 UI 功能。

在实际产品中，点击某一个 Input 或 Function 后，旁边打开 Dependency Graph 和详细说明。

用户应当能够回答：

* 这个 input 来自 Deal Settings、ASAP2 系统字段、另一个 Global Function，还是一个 Class Attribute？
* 目前值是多少？哪个调用实际使用它？
* 如果它缺失，是缺少业务配置，还是源代码分析器无法解析？
* 哪些 Functions、Scripts 和 Portfolios 可能受它影响？

这比一个纯粹罗列 Missing / Extra Parameters 的报告有用得多。

六、Pre-Validation 最重要的设计：不能把所有 Inputs 都当作 Deal Settings Parameters

你原先 BRD 中最值得修正的一点，就是报告如何进行分类。

如果一个 Script 依赖 100 个变量，并不代表 Deal Settings 应该有 100 行。

我建议 Pre-Validation Report 先按照下面的来源分类。

Category	例子	应该如何处理
Deal Configurations	deal.params[“MaxRate”]	检查设置、类型和确认状态
ASAP2 Host Data	bonds, periodic.IndexRate	检查数据可用性及适用时期
Global Function Arguments	expected_coupon	追踪实参来自哪里
Derived Variables	raw_coupon	自动计算，保留 lineage
Class State	policy.max_rate	追踪初始化和修改来源
Dynamic / Unresolved	getattr(gf, name)	报告无法确定的依赖

其中只有第一类默认属于 Deal Settings 的参数维护范围。

其他类别应该主要用于分析和审计。

这也意味着不能把下面两种情况混成一个 Missing：

* deal.params["MaxRate"] 未配置：可能是真正的业务设置缺失。
* expected_coupon 没有定义在 Deal Settings：完全正常，因为它可能来自上游 Global Function 的计算结果。

还需要引入 Dependency Resolution Status

我建议系统至少区分：

Status	含义	对 Setup 的影响
Resolved	已找到输入来源	正常
Missing	必需输入实际缺失	可能阻断
Unconfirmed	已配置但未由 Analyst 确认	依据流程决定
Type Mismatch	参数类型不符合要求	可能阻断
Unresolved	静态分析无法确定来源	需审查
Unused	已配置但未发现使用位置	提示，不一定是错误
Cyclic Dependency	发现循环依赖	需深入检查

Unresolved 不应自动等于 Missing；Unused 也不应自动等于错误。

否则系统可能产生大量 false positives，Analyst 最终会倾向于忽略报告。

同样，Python 中的数值 0、布尔值 False 和空字符串需要按参数约束分别判断，不能简单通过 truthiness 判定是否缺失。

七、从业务控制角度，完整流程应该是什么？

我建议把这套能力与现有的 Setup 生命周期结合，而不是每次 Periodic 都执行整个代码依赖扫描。

flowchart TD
    A["Deal Setup / Copy Deal"] --> B["Configure Deal Parameters"]
    B --> C["Analyze Script and GF Dependencies"]
    C --> D["Reconcile Required Inputs"]
    D --> E["Analyst Reviews and Confirms"]
    E --> F{"Required Inputs Ready?"}
    F -->|No| G["Show Missing / Unresolved Issues"]
    G --> B
    F -->|Yes| H["Run Setup Validation"]
    H --> I["Store Validation Snapshot"]
    I --> J["Periodic Processing"]
    J --> K["Lightweight Runtime Input Checks"]
    K --> L["Execution and Reporting"]

1. Setup 阶段：完整扫描和确认

用户配置参数，系统通过 Source Analysis 与 Contract 获取完整的依赖清单。

确认需要哪些 deal-level values 后，Analyst 在 Deal Settings 中逐项勾选。

配置修改、Copy Deal Info、相关 Global Function 的依赖定义变更，都可能触发重新确认。

2. Setup Validation：检查配置完整性

Pre-Validation 可以通过 Run Setup 旁边的按钮手动执行，也可以作为 Setup Validation 的自动步骤。

对于真正缺失或错误的必需配置，可以使用系统已有的 Validation Error Threshold 机制进行控制。

但不建议直接把所有 unresolved dynamic calls 都视为 CRITICAL failures，因为某些情况可能仅是静态分析能力不足。

3. Periodic：轻量检查，不重复完整扫描

这里需要对你之前的方案做一个小修正。

避免每个 Period 都重新做完整的 Script/GF Dependency Scan 是合理的，但不代表 Periodic 不需要任何 parameter validation。

比如：

* Setup 时 MaxRate 已存在且确认。
* 某个新的 Periodic run 中 IndexRate 缺失。
* 另一个业务参数在该 Period 的 effective date 下已经失效。

这些仍然需要运行时检查。

所以我建议：

Setup 做 Dependency Discovery + Configuration Completeness；Periodic 做必要的 Runtime Readiness Checks。

这样兼顾 performance 和 reliability。

4. Reporting：提供可复现的审计记录

每次 Pre-Validation 的结果最好保存为一个 Snapshot，至少包含：

* Deal、Period、Script 和相关 GF 的版本标识；
* 当前所分析的 portfolio 和代码依赖版本；
* Deal Settings 中实际生效的配置值及确认状态；
* Resolved、Missing、Unresolved 等分类结果；
* Analyst 确认时间和后续修改记录。

这里需要区分“扫描时的静态依赖”与“某次执行实际使用的数据”。两者可以关联，但不能互相替代。

这对于你们的证券化业务很重要，因为同一个 deal 不同 payment dates 的输入、计算与验证结果，可能需要在未来重新核对。

八、还有几个必须解决的 Python 技术问题

这部分决定 PwC 能不能把需求真正做成稳定的平台功能。

1. 同一个 Global Function 多次调用

例如：

gf.validate_balance(senior_bonds, tolerance=0.01)
gf.validate_balance(residual_bonds, tolerance=0.10)

这里的函数名称相同，但调用位置和有效输入不同。

因此 Dependency Graph 的节点不能只用 function_name 唯一标识。

至少需要区分 Function Definition 和 Function Call Site。

2. Class Object 的状态变化

例如：

policy = RatePolicy(deal)
policy.max_rate = 5.0
policy.validate(bonds)
policy.max_rate = 6.0
policy.validate(bonds)

同一个 Class Instance，在不同调用时使用了不同状态。

如果只扫描 RatePolicy.__init__()，就会遗漏后续属性赋值。

因此静态分析器需要追踪能识别的属性赋值；无法确定的动态 mutation 需要标成 Unresolved，或者通过 runtime observation 辅助判断。

3. 循环依赖与重复引用

例如：

gf.function_a()
    -> gf.function_b()
        -> gf.function_a()

Dependency Scanner 必须检测循环，避免无限递归。

但需要注意：静态调用图存在循环，不一定意味着实际运行会发生无限递归。代码可能有终止条件。

所以更合适的状态是 Potential Recursive Dependency，在运行时确认后再进一步判断。

4. Dynamic Functions

例如：

func = getattr(gf, function_name)
func(...)

如果 function_name 来自 ValidationEngine 的内部 registry，系统可以利用 registry metadata 展开它。

如果名称来自运行时输入，就应显示 Unresolved Dynamic Call，直到有额外的 Contract 或运行时证据。

不能为了生成一份完整的报告而凭空推断调用目标。

5. Performance 和增量扫描

如果一个 shelf 下有很多 deals，而它们共享大量 Global Functions，每次从头解析所有源码非常浪费。

应当缓存以 Function Version / Source Hash 为基础的分析结果。

例如：

GF Version 12
    -> Dependencies: MaxRate, Periodic.IndexRate
    -> Cached analysis
Deal A
    -> MaxRate = 5.0
Deal B
    -> MaxRate = 6.0

两个 deals 可以复用同一份代码依赖分析，仅分别检查其参数值和有效配置。

当 Global Function 版本变化时，再失效并重建相关依赖缓存。

九、给 PwC 的需求如何分阶段？

我认为不要第一期就要求 PwC 建设一个能够完全追踪 Python 所有变量状态的通用系统。这会显著增加开发复杂度，也不容易界定验收标准。

更合理的是：

Phase	建议范围	业务价值
Phase 1	Deal Settings deal.params、Copy Deal、确认 checkbox、基础 Pre-Validation、Excel Report	解决当前配置管理问题
Phase 2	递归 GF dependency scan、ValidationEngine Registry 展开、Class Contracts、可视化调用图	解决可见性和配置完整性
Phase 3	Runtime Observation、历史版本比较、变更影响分析、跨 deal/shelf dependency reporting	支持审计和规模化管理

我建议 Phase 1 虽然不需要做完整 Data Lineage Graph，但底层数据结构应该为 Phase 2 留好空间。

尤其是不要把数据库设计成只有：

FunctionName
ParameterName
ParameterValue

因为这样的模型很难表达：

* 一个参数被多个 Functions 复用；
* 一个 Function Output 作为另一个 Function Input；
* 一个 Class Attribute 依赖 Deal Configuration；
* 一个参数在不同 periods 有不同值；
* 一个 GF 的不同版本有不同依赖。

底层应当区分至少四种实体：Input、Function/Object、Call Site、Execution/Configuration Context，并记录它们之间的依赖关系。

十、最后从商业价值考虑：你到底要向 Dan 和 PwC 争取什么？

如果只是让 Analyst 在 Deal Settings 中输入 MaxRate = 5，这个需求相对简单。

如果只是扫描 Python function signatures，找出哪些参数没有填，技术上也有一定可行性。

但是两者都无法完整解决你真正的管理问题：

我们不知道一个 Deal Script 经过多层 Global Functions 和 Class Objects 后，最终到底依赖什么、这些数据从哪里来、谁负责维护，以及修改某个值会影响哪些计算。

我认为真正有价值的产品目标应该写成：

Provide a centralized, deal-level dependency discovery and input management framework that identifies and visualizes the configuration values, runtime inputs, nested Global Function calls, and class-level dependencies used by ASAP2 scripts. The framework should distinguish analyst-managed inputs from system-provided and derived values, support pre-validation and confirmation during deal setup, and enable traceability and impact analysis across scripts, functions, deals, and shelves.

这里比 Global Function Parameter Table 更准确的模块名称可以考虑：

* Deal Input & Dependency Management
* Script Dependency Explorer
* Deal Configuration & Validation

如果只能选一个作为整体业务模块名称，我倾向于 Deal Input & Dependency Management。它不会被限制在 Validation 功能上，同时包含 Rani 强调的通用 Deal Settings Input Management，以及你希望实现的 Global Function Dependency Analysis。

最终建议

我会把整个需求明确拆成三个独立但可以集成的模块：

Deal Input Manager 负责值的维护、复制、权限和 Analyst Confirmation。

Dependency Analyzer 负责解析 Script、Global Functions 和 Classes，建立来源与调用关系，并识别静态分析无法解析的依赖。

Validation & Reporting Layer 负责 Setup Pre-Validation、运行结果、Severity、错误分发以及可下载的审计报告。你现在的 ValidationEngine 可以继续承担其中的 validation orchestration，不需要变成数据存储系统或 Python Source Analyzer。

真正值得请 PwC 负责的，是 ASAP2 原生的数据模型、源代码和版本访问、依赖发现以及 Deal Settings UI 的集成能力。这些是你单独通过 Global Function Python 代码较难可靠完成的部分。

而你的 ValidationEngine 已经能够完成 portfolio selection、Global Function orchestration 和 structured results aggregation，可以继续作为独立、可复用的业务执行层。

这样既能控制开发范围，也能避免在 PwC 建设原生功能时推翻你已经完成的 validation framework。


===


这是整个 ASAP2 Parameter Lineage 设计中最关键的问题之一。

如果两个 Global Functions 都使用 MaxRate，系统不能只根据参数名称判断它们使用的是同一个值，更不能把两次使用合并为一条简单的依赖关系。

我建议采用：

Parameter Identity + Function Call Context + Value Transformation + Effective Value

也就是说，Lineage 不只记录 Which function uses MaxRate?，还必须记录：

* Source：两个 Function 引用的是同一个 deal.params["MaxRate"]，还是不同来源？
* Binding：这个值怎样绑定到各 Function 的参数或局部变量？
* Transformation：Function 内部是否对它进行了换算、覆盖或重新赋值？
* Effective Value：最终实际参与校验或计算的是多少？
* Usage：这个值用于什么业务规则？
* Call Context：是哪个 Deal、Period、Script、Function Version 和调用位置使用了它？

这样才能区分“共用同一个业务参数”与“两个函数恰好用了相同的变量名”。

一、首先区分三种完全不同的情况

情况 A：两个 Function 读取同一个 MaxRate，但计算方式不同

假设 Deal Settings 里：

deal.params["MaxRate"] = 5.0  # 5%

Function A：

def validate_coupon(deal, bonds):
    max_rate = deal.params["MaxRate"]
    cap = max_rate / 100.0
    return bonds[0].CouponRate <= cap

Function B：

def validate_index_rate(deal, period):
    max_rate = deal.params["MaxRate"]
    adjusted_rate = (max_rate + 1.0) / 100.0
    return period.IndexRate <= adjusted_rate

两个函数的 Source 完全相同，但计算结果不同：

	Function A	Function B
Source	deal.params[“MaxRate”]	deal.params[“MaxRate”]
Original Value	5.0%	5.0%
Transformation	÷ 100	(MaxRate + 1) ÷ 100
Effective Value	0.05	0.06
Business Usage	Coupon cap	Adjusted index threshold

这里不应该产生 Parameter Conflict。

因为两个函数并没有修改原始 MaxRate，只是各自计算了不同的派生值。

对应的 Lineage

Deal Settings · MaxRate

5.0%

One authoritative source

Function A

validate_coupon

MaxRate / 100

0.05

Coupon cap

Function B

validate_index_rate

(MaxRate + 1) / 100

0.06

Index threshold

一个源参数、两个独立的数据流分支。数值为示例。

设计原则：相同 Source 可以产生多个 Derived Values，它们应是不同的 Lineage Nodes。

情况 B：两个 Function 使用名为 max_rate 的变量，但实际来源不同

例如：

Function A：

max_rate = deal.params["MaxRate"]

Function B：

max_rate = bond.setup.MaxRate

尽管两个局部变量都叫 max_rate，但它们不是同一个 Parameter。

Lineage 必须展示两个独立的 Source：

Deal Settings
  deal.params["MaxRate"] = 5.0
      |
      +-- Function A.max_rate
Bond Setup
  bond.setup.MaxRate = 6.0
      |
      +-- Function B.max_rate

系统必须按照 Parameter Source Identity 区分参数，而不能仅凭 MaxRate 这个名字合并。

尤其在 ASAP2，以下字段即便名称相似，也可能拥有不同的业务含义：

deal.params["MaxRate"]
bond.setup.MaxRate
periodic.MaxRate
self.max_rate

它们各自有不同的 scope、owner 和生命周期。

情况 C：两个 Function 使用同一个 MaxRate，但其中一个覆盖了原值

例如：

def validate_a(deal):
    max_rate = deal.params["MaxRate"]
    return max_rate
def validate_b(deal):
    max_rate = deal.params["MaxRate"]
    if some_condition:
        max_rate = 6.0
    return max_rate

Function A 实际使用 5.0，而 Function B 在满足条件时使用 6.0。

这里需要记录：

Attribute	Function A	Function B
Configured Value	5.0	5.0
Local Override	No	Yes
Effective Value	5.0	6.0
Original Deal Parameter Modified	No	No
Review Flag	None	Override detected

这里的 max_rate = 6.0 只是重新绑定了 Function B 的局部变量，并没有修改 deal.params["MaxRate"]。

但如果 Function B 写的是：

deal.params["MaxRate"] = 6.0

性质就完全不同了。

这属于对共享配置对象的写入，可能改变后续 Global Functions 读取的值，必须作为 Configuration Mutation 单独追踪。

对于你的 validation framework，我建议 deal.params 在 Global Functions 中默认只读。业务参数的修改统一通过 Deal Settings 进行，避免 validation 的执行顺序影响实际参数值。

二、从 Python 的角度，应该如何区分这些变量？

这里可以借鉴编译器中的 Static Single Assignment（SSA，静态单赋值） 思想。

例如：

max_rate = deal.params["MaxRate"]  # 5.0
max_rate = max_rate + 1.0        # 6.0
max_rate = max_rate * 0.01       # 0.06

普通 Python 代码中，它们都叫 max_rate。

但做 Data Lineage 时，应当把它们理解成三个不同版本：

max_rate#1 = deal.params["MaxRate"]
max_rate#2 = max_rate#1 + 1.0
max_rate#3 = max_rate#2 * 0.01

形成：

deal.params["MaxRate"]
      |
      v
max_rate#1 = 5.0
      |
      v
max_rate#2 = 6.0
      |
      v
max_rate#3 = 0.06
      |
      v
Validation / Calculation

这不是要求修改原始 Python，而是分析器内部需要建立这样的变量版本关系。

遇到 if/else 时，分析器还必须保留可能的分支。例如静态分析只能知道 max_rate 可能是 5 或 6，而实际使用哪个值，需要运行时的条件结果才能确定。

同一个 Global Function 被多次调用怎么办？

假设：

gf.validate_rate(bonds, max_rate=5.0)
gf.validate_rate(bonds, max_rate=6.0)

不能只建立一个 gf.validate_rate 节点，否则会丢失不同调用的参数。

需要区分：

* Function Definition：gf.validate_rate 这个函数的定义及版本。
* Function Call Site：它在什么 Script 的什么位置被调用。
* Function Invocation：某次实际执行，使用了哪些参数值。

如果 MaxRate 本身是另一个 Global Function 的输出，同样遵循这个原则。两次 gf.get_max_rate(...) 调用不能因为函数名称相同，就自动认定结果是同一个值。

三、我建议的 Lineage 数据结构

不应该只存：

{
    "parameter": "MaxRate",
    "used_by": ["validate_a", "validate_b"]
}

因为这只能回答“谁用过”，不能回答“怎么用”。

更完整的结构可以这样设计：

{
  "parameter_id": "deal:RMBS_A:params:MaxRate",
  "parameter_name": "MaxRate",
  "source": "deal.params",
  "configured_value": 5.0,
  "unit": "percent",
  "uses": [
    {
      "function": "validate_coupon",
      "binding": "max_rate",
      "operation": "divide_by_100",
      "effective_value": 0.05,
      "purpose": "Coupon cap",
      "modified_source": false
    },
    {
      "function": "validate_index_rate",
      "binding": "max_rate",
      "operation": "add_1_then_divide_by_100",
      "effective_value": 0.06,
      "purpose": "Adjusted index threshold",
      "modified_source": false
    }
  ]
}

这是面向报告的示例结构，不一定是最终数据库格式。

对于正式的 Lineage 系统，我建议分离以下实体。

Entity	主要内容
Parameter Source	参数的唯一身份、来源、scope、单位
Parameter Value	某个 Deal/Period/Version 实际生效的值
Function Definition	Global Function 名称及代码版本
Function Call	Script 位置、传参及调用对象
Variable Transformation	赋值、转换、计算、覆盖
Result / Consumer	哪个 Calculation 或 Validation 使用最终结果

这样多个 Functions 可以共享一个 Parameter Source，但拥有完全不同的调用关系和计算过程。

还需要为每条关系保存证据来源：

* STATIC：由源代码分析推导。
* DECLARED：由 Global Function 或 Class Contract 声明。
* OBSERVED：通过实际执行获取。

对于 effective_value，如果没有实际执行，仅凭静态代码无法确定其数值，就应该显示计算表达式或 Runtime-dependent，而不是给出一个未经验证的结果。

四、业务上怎样可视化才真正有用？

我建议 Analyst 点击 MaxRate 时，看到的不是单纯一个调用函数列表，而是一个 Parameter Usage & Impact View。

下面是一个可交互的展示示例。

MaxRate — Parameter Lineage

Illustrative UI · Deal RMBS_A

Configured

Source value

5.0%

Consumers

3

Needs review

1

Select a function to inspect its use of MaxRate

validate_coupon

Coupon cap

Normal

validate_index_rate

Index threshold

Derived

validate_special_rate

Special rate check

Review

validate_coupon

Parameter source	deal.params
Original value	5.0%
Transformation	Divide by 100
Effective value	5.0%
Business usage	Coupon cap
Status	Normal

示例为假设数据；实际值需要来自代码解析或运行时记录。

这种 UI 对 Analyst 和 Manager 比纯调用图更有价值，因为它直接区分：

* 两个 Functions 使用同一个值，是正常的共享依赖。
* 两个 Functions 从相同值计算出不同结果，是正常的派生计算。
* 某个 Function 覆盖了配置值，需要确认是否符合业务规则。
* 某个 Function 实际读取了另一个 Source，则可能存在配置不一致或业务含义不同。

五、如何判断两个 Function 的不同赋值是否需要报错？

这里不能简单地规定：

Function A.MaxRate != Function B.MaxRate 就失败。

因为它们可能本来就需要不同的 Effective Values。

我建议设置以下规则：

情况	Lineage 状态	建议处理
相同 Source，相同业务含义	Shared dependency	正常
相同 Source，不同计算方式	Derived dependency	正常，展示转换
相同 Source，局部覆盖值	Local override	标记 Review
相同参数名，不同 Source	Source mismatch / distinct scope	先判断是否本应相同
不同 Functions 写入同一共享配置	Configuration mutation	高风险，建议禁止
相同 Source，不同单位解释	Unit / semantic mismatch	需要确认或报错
动态赋值无法分析	Unresolved dependency	人工审查或运行时追踪

其中还有一个非常重要的业务问题：Unit 和 Semantic Meaning。

例如：

deal.params["MaxRate"] = 5

Function A 将它理解为 5%，Function B 将它理解为 5.0（十进制利率）。

它们拥有完全相同的 Source，却可能计算出相差 100 倍的结果。

因此，你的 deal.params 如果未来支持 typed values，我强烈建议不只有 Parameter Name 和 Value，还需要明确 Type、Unit、Scope，必要时再定义业务用途或约束。

这样系统才能识别真正的业务配置冲突，而不是只比较变量名称和数字。

六、如何让 PwC 实现，又不把整个需求做得过于复杂？

我建议你给 PwC 提出三个逐步增强的要求。

第一阶段：Parameter Usage Mapping

识别一个 deal.params["MaxRate"] 被哪些 Global Functions 使用，并展示函数名、调用位置、Function Version 和所属 Script。

即使同一个 Function 使用多次，也要分别显示 call sites。

第二阶段：Transformation Lineage

识别各 Function 如何读取、赋值、转换和使用这个参数。

静态可确定的表达式应展示出来；动态表达式或 Class State Mutation 无法确定时，应明确标为 Unresolved。

第三阶段：Runtime Effective Value & Conflict Detection

在受支持的执行路径中记录实际 Effective Value，对 Local Overrides、Configuration Mutations、单位不一致等情况提供 review flags，并与对应 Deal/Period 的执行记录关联。

不建议第一阶段就强制每个计算结果都有可追踪的实际值，否则性能和实现成本会明显上升。

对应可以加入 BRD 的核心需求

Parameter Usage and Transformation LineageThe system shall distinguish parameter identity from variable names and function arguments. When multiple Global Functions reference the same deal-level parameter, the dependency report shall identify each function call separately and show the parameter’s source, binding, transformation, and downstream usage.Where determinable, the system shall distinguish the configured source value from the effective value used by each function. Local overrides, shared-configuration mutations, unit mismatches, and unresolved dynamic dependencies shall be flagged for review.The system shall not treat different derived values as conflicting solely because they originate from the same parameter.

最后一个更深层的判断： 你的需求其实同时涉及 Source Lineage 和 Value Lineage。

* Source Lineage 回答：MaxRate 从哪里来，哪些 Functions 使用它？
* Value Lineage 回答：它进入某个 Function 后，经过哪些变换，最后真正使用的值是什么？

从业务价值看，我建议 先确保 Source Lineage 可靠，再逐步实现 Value Lineage。对于 ASAP2 这样存在 nested Global Functions、动态调用和可变 Class State 的系统，后者的技术难度会明显更高，但也更有助于发现隐藏的配置和计算风险。


===


明白了。你真正想解决的是：

假设 ASAP2 中有两个 Global Functions：Fa(MaxRate) 和 Fb(MaxRate)，它们都定义了一个叫 MaxRate 的参数。如何自动发现这两个参数，并判断它们的定义、来源和实际取值有什么不同？

这本质上是 Function Parameter Comparison + Argument Binding Analysis，而不只是 Data Lineage。

一、首先，两个 MaxRate 在 Python 中是独立的参数

例如：

def Fa(MaxRate=5):
    return MaxRate
def Fb(MaxRate=6):
    return MaxRate

虽然都叫 MaxRate，但实际上是：

Fa.MaxRate = 5
Fb.MaxRate = 6

Python 不会认为它们是同一个参数。

所以你的参数管理系统应该使用 Function + Parameter Name 作为标识，而不是只使用 MaxRate。

Function	Parameter	Default	Actual Value
Fa	MaxRate	5	5
Fb	MaxRate	6	6

但是这只能比较函数定义里的默认值。

如果实际脚本调用：

gf.Fa(MaxRate=deal.params["MaxRateA"])
gf.Fb(MaxRate=deal.params["MaxRateB"])

那么真正需要比较的是 实际传入的参数值。

二、我建议建立 Parameter Binding Table

例如当前 deal：

deal.params["MaxRateA"] = 5
deal.params["MaxRateB"] = 7

系统自动生成：

	Fa.MaxRate	Fb.MaxRate
Parameter Name	MaxRate	MaxRate
Default Value	5	6
Actual Input	5	7
Source	deal.params[“MaxRateA”]	deal.params[“MaxRateB”]
Binding	Keyword argument	Keyword argument
Comparison	Different	Different

这就能发现：

两个 Function 都有 MaxRate，但其默认值不同，实际输入来源不同，实际取值也不同。

而且能区分这究竟是有意设计，还是参数配置不一致。

三、如何通过 Python 自动检查？

这里需要结合两种分析。

1. Function Definition Analysis

检查：

def Fa(MaxRate=5):
    ...

以及：

def Fb(MaxRate=6):
    ...

通过 Python AST 分析，可以识别：

* 参数名称
* 参数位置
* 默认值
* 参数是否必需
* 是否通过 *args / **kwargs 接收

从而得到：

{
    "Fa": {"MaxRate": {"default": 5}},
    "Fb": {"MaxRate": {"default": 6}}
}

2. Function Call Analysis

检查调用它们的 ASAP2 Script：

gf.Fa(MaxRate=deal.params["MaxRateA"])
gf.Fb(MaxRate=deal.params["MaxRateB"])

分析器应该记录：

{
    "Fa.MaxRate": {
        "source": "deal.params['MaxRateA']",
        "actual_value": 5
    },
    "Fb.MaxRate": {
        "source": "deal.params['MaxRateB']",
        "actual_value": 7
    }
}

这里有一个重要的技术边界：

AST 可以静态识别 MaxRateA 和 MaxRateB 的引用关系，但要知道它们当前分别等于 5 和 7，还需要读取当前 deal 的配置数据。

如果它们来自动态表达式或其他 Global Function 的输出，则需要进一步递归解析或在运行时观察。

四、Deal Settings 应该如何支持这两种 MaxRate？

你之前给 PwC 的设计是：

deal.params["MaxRate"]

如果两个 Functions 的 MaxRate 本来就应该相同，可以共用这一项。

如果它们需要不同值，我建议利用你已经设计的 Group / Function Name 列。

例如：

Group / Function	Parameter Name	Value
General	MaxRate	5
Fa	MaxRate	6
Fb	MaxRate	7

对应的访问方式：

deal.params["MaxRate"]          # General value: 5
deal.params["Fa"]["MaxRate"]    # Fa-specific: 6
deal.params["Fb"]["MaxRate"]    # Fb-specific: 7

这样系统可以同时支持共享参数和 function-specific 参数。

但这里不要自动认为：

Fa.MaxRate != Fb.MaxRate

就是错误。

需要通过业务规则决定它们是否应该相同。

五、最终可视化应该是什么样？

我建议在 PwC 的 Deal Pre-Validation Report 中增加一个：

Parameter Comparison by Function

Parameter Comparison — MaxRate

Illustrative interactive view

gf.Fa

Bound source

deal.params"MaxRateA"

Actual value

gf.Fb

Bound source

deal.params"MaxRateB"

Actual value

Business relationship

Independent parameters — differences allowed

Must have the same value

Different values — permitted

Fa.MaxRate = 5, Fb.MaxRate = 7. The result depends on the declared business relationship.

这个界面还应允许 Analyst 进一步点击，查看两个参数分别从哪段 Script、哪个 GF、哪个上游计算中获得。

六、还有一个必须考虑的问题

如果同一个 Fa 被调用两次：

gf.Fa(MaxRate=5)
gf.Fa(MaxRate=7)

系统不能只有一条 Fa.MaxRate 记录。

必须进一步区分 Call Site：

Script A → Fa invocation #1 → MaxRate = 5
Script A → Fa invocation #2 → MaxRate = 7
Script B → Fb invocation #1 → MaxRate = 6

因此最终唯一标识应当包含：

Function Name + Function Version + Call Site + Parameter Name

而具体某一次执行的值，还要关联 Deal、Period 和 Execution ID。

我的建议

你真正应该要求 PwC 实现的是：

Cross-Function Parameter Binding Comparison

核心需求可以概括成一句英文：

The system should identify parameters with the same name across different Global Functions, compare their definitions, default values, actual argument bindings, input sources, and resolved values, and highlight differences for review. Comparisons must distinguish function definitions from individual call sites and should not treat different values as errors unless a shared-value constraint is explicitly defined.

这样你就能查询 Fa.MaxRate 与 Fb.MaxRate，既能看到 parameter definition differences，又能看到 actual value differences，而且可以进一步判断它们是否属于业务上需要纠正的配置不一致。

