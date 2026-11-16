ASAP2 Global Function Parameter Management — 综合设计方案

结合之前讨论的 Fa(MaxRate)、Fb(MaxRate)、Nested Global Functions、Class Objects、Deal Settings 和 ValidationEngine，我认为最合理的方向是：

不再仅管理 Parameter Values，而是建立统一的 Parameter Registry + Dependency Lineage + Pre-Validation Framework。

系统需要解决三个核心问题：

* Discovery：一个 Script 实际使用了哪些 Parameters？
* Comparison：相同名称的 Parameters 在不同 Functions 中来源、定义和取值是否一致？
* Management：哪些 Parameters 需要 Analyst 配置、确认和维护？

一、各种 Parameter 使用场景

场景	Python / ASAP2 示例	需要识别和管理的内容
1. Direct Parameter	gf.Fa(MaxRate=5)	显式传入值、调用位置
2. Function Default	def Fa(MaxRate=5)	默认值和是否被覆盖
3. Shared Deal Parameter	deal.params[“MaxRate”]	统一来源、使用者
4. Same Name, Different Values	Fa(MaxRate=5) / Fb(MaxRate=7)	比较定义、来源及实际值
5. Nested Global Function	Fa(MaxRate=gf.Fb())	递归追踪 Fb 的输入与输出
6. Local Variable / Transformation	max_rate = rate * 1.1	赋值、计算关系、派生值
7. Class Attribute	self.MaxRate = 5	对象状态、初始化和后续修改
8. ASAP2 Global / Runtime Variable	periodic.IndexRate	来源、数据有效性和期间
9. Dynamic Call	getattr(gf, name)()	实际调用目标及未解析依赖
10. Repeated Function Calls	Fa(5) / Fa(7)	区分每个 Call Site
11. Cross-Deal Configuration	Deal A: 5 / Deal B: 7	Deal、Shelf、Period 作用范围

重要原则：Parameter Name 不等于 Parameter Identity。

例如：

def Fa(MaxRate=5):
    ...
def Fb(MaxRate=7):
    ...

这两个 MaxRate 是独立的 Formal Parameters。

如果它们都引用：

deal.params["MaxRate"]

则两个函数共享一个数据来源，但仍拥有各自的 Argument Binding 和计算逻辑。

二、Parameter 应如何分类管理？

建议将所有发现的数据分为四类。

1. Configurable Inputs

deal.params["MaxRate"]、Tolerance、Deal Assumptions

由 Analyst 在 Deal Settings 设置并确认，是主要的人工维护对象。

2. System / Runtime Inputs

bonds、assets、periodic.IndexRate

由 ASAP2 提供，检查数据可用性及适用范围，不要求 Analyst 重复输入。

3. Derived Inputs

Nested GF outputs、Local Variables、Calculated Results

记录来源和转换关系，通常不进入 Deal Settings 参数表。

4. Function / Class State

Function Defaults、self.MaxRate、Object Attributes

记录定义、绑定及覆盖关系，识别可能的状态变化。

只有真正需要由业务人员维护的 Configurable Inputs 应默认进入 deal.params。

其余数据主要通过 Dependency Explorer 展示和检查。

三、如何解决 Fa(MaxRate) 与 Fb(MaxRate) 的差异？

这是我建议新增的核心功能：Cross-Function Parameter Comparison。

假设：

gf.Fa(MaxRate=deal.params["MaxRate"])
gf.Fb(MaxRate=7)

而：

deal.params["MaxRate"] = 5

系统应该展示：

Attribute	Fa.MaxRate	Fb.MaxRate
Default	5	6
Binding Source	Deal Settings	Hardcoded Literal
Actual Input	5	7
Transformation	None	None
Effective Value	5	7
Business Relationship	To be determined	To be determined

Parameter Binding & Lineage

但 不同值不应自动判定为 Error。

系统需要区分三种情况：

* Independent：Fa 和 Fb 的 MaxRate 本来就可以不同。
* Shared / Must Match：业务规则要求两者相同，差异应标记为错误。
* Unknown：尚未定义二者的业务关系，标记供人工审查。

如果它们来自同一个 deal.params["MaxRate"]，但函数内部进行不同换算，那么应该记录各自的 Transformation 和 Effective Value，而不是直接报告冲突。

四、技术架构：如何实现而不过度复杂？

建议采用三个互补机制。

Static Dependency Analysis

通过适配 ASAP2 Python 语法版本的 AST 分析，识别参数定义、调用、赋值、属性访问和可解析的嵌套 GF。

Explicit Dependency Contracts

由 ValidationEngine 和其他自定义 Class 提供只读 metadata，声明动态 portfolio、相关 GF 和输入依赖。

Runtime Observation

按需记录实际 Function Calls、Argument Bindings、Effective Values 和配置写入，补充静态分析无法确定的部分。

Unified Parameter Lineage Registry

Source → Binding → Transformation → Consumer

底层需要记录的最小信息可以是：

{
    "parameter": "MaxRate",
    "function": "Fa",
    "function_version": "v2",
    "call_site": "BondPayment:42",
    "source": "deal.params['MaxRate']",
    "default_value": 5,
    "effective_value": 5,
    "transformation": None,
    "deal": "RMBS_A",
    "period": "2026-10",
    "resolution": "OBSERVED"
}

这只是一个简化示例。正式数据结构还需要单独标识 Parameter Definition、Source 和每次 Invocation，并记录单位、数据类型及配置版本。

静态分析无法解析的动态调用，应明确显示 Unresolved，而不是假设参数缺失。

五、业务流程应该怎么设计？

我推荐保留此前 BRD 的方向，但升级它的分析能力。

Deal Settings — Parameter Management

Analyst 维护和确认业务配置：

* deal.params["MaxRate"]
* Data Type / Unit / Scope
* Analyst Confirmation
* Copy Deal Info 支持复制配置，并对复制后的确认状态进行管理

Pre-Validation — Dependency & Parameter Review

自动扫描当前 Deal Scripts 和嵌套 Global Functions，提供可下载报告，包含：

* 所有已发现输入及其来源；
* 相同 Parameter Name 在不同 Functions 的 Binding Comparison；
* Missing、Unconfirmed、Unused、Unresolved 和 Potential Conflicts；
* 相关 GF、Class、Script、Version、Call Site。

Periodic — Lightweight Runtime Checks

Setup 阶段执行完整依赖分析，Periodic 阶段只做必要的数据有效性检查。

当 GF 版本、Script、Class Contract 或 Deal Configuration 变化时，触发相应的重新分析或确认。

六、优先级与实施建议

阶段	功能	目标
Phase 1	Deal Parameter Table + AST Dependency Discovery + Excel Report	看清所有参数来源
Phase 2	Cross-Function Comparison + Nested GF / Class Contracts	比较 Fa.MaxRate 与 Fb.MaxRate
Phase 3	Runtime Effective Values + Conflict Detection + Change Impact	验证真实执行值和变更影响

我不建议第一期就尝试追踪所有 Python Local Variables 和 Class State 的全部实际值。这会明显增加性能开销，而且动态执行路径很难保证完整覆盖。

最终结论

你需要的系统应该区分三个层次：

Parameter Management：管理哪些业务输入需要人工设置，例如 deal.params["MaxRate"]。

Parameter Lineage：追踪这些输入如何进入不同的 Global Functions、Nested Functions 和 Class Objects，以及如何被转换。

Parameter Comparison & Validation：比较 Fa.MaxRate 与 Fb.MaxRate 的默认值、来源、实际绑定和有效值，并根据业务约束判断差异是否需要处理。

最终，不同 Functions 中同名的 Parameters 必须独立识别，但可以共享同一个配置来源。是否应当相同，由业务规则决定，而不是由参数名称决定。

这应该成为新版 ASAP2 Deal Input & Dependency Management BRD 的核心设计原则。