# ASAP Validation Enrichment — Single Validation Workflow

> 适用范围：**一个 Claude Session 只处理一个编号 Validation Record（含其全部 Continuation Rows）**。
> 
> 本文适用于新版 `tools/single_validation.py`：支持 `--manual-mode shared`（默认）、`full`、`selected` 以及 `--embed-shared`。**如果你本地还是旧版脚本（仅支持 full/selected），必须先替换新版脚本；仅更新此文档不会让旧脚本自动支持 shared。**

## 1. 目标与原则 / Goal

每次指定一个 `record_id`，将其原始 Validation Master 规则与 ASAP Knowledge Context 一起提供给全新的 Claude 对话。Claude 只为该 Record 及附加条件生成：

- `implementation_spec`：Required Data Points、ASAP Runtime Access、Calculation Steps、Validation Logic、Source Evidence 和未解决问题；
- `QA_R###.json`：本次分析覆盖率、证据情况和剩余问题。

**Python 负责准备数据、校验和增量合并；Claude 负责阅读来源并分析技术逻辑。** 原始 `validation_master_flat.json` 不会被 `prepare` 或 `merge` 改写。`development_status` 是既有进度属性，不能被 Claude 的 Spec Readiness 覆盖。

业务规则以 Validation Master 为准；ASAP Runtime API 以实际提供的 Scripting Manual 为准；User Manual 用于业务语义；Release Notes 用于版本限制；SQL Schema 仅证明数据库元数据，**不能单独证明 Runtime 对象支持直接访问**。未证实的 API、容差、计算公式、默认值应保持 `null` 或标为 `unresolved`，而不是猜测。

## 2. 项目目录 / Directory Layout

在 `ASAP-Validation-Enrichment/` 根目录执行下面所有命令。

```text
ASAP-Validation-Enrichment/
├── source/
│   ├── validation_master_flat.json        # 原始 Flat JSON；不要直接 enrich
│   ├── merged_scripting_manual.md         # ASAP Runtime 技术依据
│   ├── merged_user_manual.md              # ASAP 业务和应用依据
│   ├── Releases-be4181818e.md            # 版本与兼容性
│   └── schema_catalog.md                  # SQL Table/View/Column 目录
├── control/
│   ├── ROW_REGISTRY.jsonl                 # build_registry.py 生成
│   ├── PROJECT_STATE.json                 # 来源 SHA-256；本工作流不依赖旧 Session 状态
│   └── SPEC_SCHEMA.json                   # implementation_spec 固定 Schema
├── context_packs/
│   ├── shared/
│   │   └── ASAP_KNOWLEDGE_CONTEXT.md      # 4 份 Markdown 的合并版本
│   └── by_record/
│       ├── R020_HEADER.txt
│       ├── R020_CONTEXT.txt
│       └── R020_EXECUTE.txt
├── prompts/
│   ├── SINGLE_VALIDATION_HEADER.md
│   └── SINGLE_VALIDATION_EXECUTE.md
├── patches/by_record/
│   └── SPEC_R020.jsonl                     # Claude 输出，合并前须验证
├── qa/by_record/
│   └── QA_R020.json                        # Claude QA 输出，单独保存
├── final/
│   ├── validation_master_enriched.json    # 本地增量合并结果
│   └── validation_master_enriched_*.bak.json  # 旧版本备份
├── tools/
│   ├── build_registry.py
│   ├── build_asap_context.py
│   └── single_validation.py               # 本文对应新版脚本
└── docs/
    └── ONE_VALIDATION_WORKFLOW.md
```

真实的公司手册、原始 Validation JSON、Context Pack、Claude Patch 和 QA 结果应留在获公司批准的本地环境；**不要提交到公开 GitHub 仓库**。确认项目 `.gitignore` 已排除这些文件，提交前仍须人工检查 `git status`。

## 3. 首次初始化 / One-time Setup

### 3.1 准备五份来源

将原始 Flat JSON 与四份 Markdown 按上表文件名放入 `source/`。JSON 应包含 `record_id`、`parent_record_id`、`row_type` 和已有开发状态；不应是先前 enrichment 后的数据。

### 3.2 建立 Row Registry

```powershell
py tools/build_registry.py
```

预期生成：

- `control/ROW_REGISTRY.jsonl`：编号记录对应 `R001`、`R020` 等；附加行对应 `C020-01` 等；每行包含原始数据 Fingerprint。
- `control/PROJECT_STATE.json`：保存原始 Flat JSON 的 SHA-256。

原始 JSON **改变时**需要重建 Registry，但旧 Patch 的 Hash 将可能失效，已有 Enriched 文件也可能无法与新基线合并。不要通过修改 Hash 绕过检查，应先进行版本迁移或重新生成相关 Patch。

### 3.3 构建共享知识文档

```powershell
py tools/build_asap_context.py
```

预期生成：

`context_packs/shared/ASAP_KNOWLEDGE_CONTEXT.md`

它包含四份原文，并以 `SOURCE_ID` 和 `BEGIN SOURCE / END SOURCE` 界定来源。四份 Manual 有变化时重新运行即可。**将它们合并只减少本地管理和粘贴次数，不会减少 Claude 实际处理的 Token 数量。**

建议检查：

```powershell
Test-Path context_packs/shared/ASAP_KNOWLEDGE_CONTEXT.md
Get-Item context_packs/shared/ASAP_KNOWLEDGE_CONTEXT.md | Select-Object Name,Length
```

如果出现 `assert actual == combined`（Windows CRLF/LF 换行问题），在 `build_asap_context.py` 中改用 `write_bytes(combined.encode("utf-8"))` 和 `read_bytes().decode("utf-8")` 作字节一致性验证。

## 4. 每条 Validation 的标准流程 / Per-record Procedure

以下以 **Record #20** 为例；其他 ID 替换 `20` 即可。

### Step 1 — Generate record-specific Claude Context

```powershell
py tools/single_validation.py prepare --id 20
```

新版脚本的默认 Manual Mode 为 `shared`。它先确认共享文档存在及四个 Source ID 是否齐全，然后生成：

```text
context_packs/by_record/R020_HEADER.txt
context_packs/by_record/R020_CONTEXT.txt
context_packs/by_record/R020_EXECUTE.txt
```

`R020_CONTEXT.txt` **只含**当前编号记录、属于它的全部 Continuation Rows、对应 Row Registry 和 SPEC_SCHEMA；不会再嵌入四份 Manual，因此体积较小。

`prepare` **不会**生成 `SPEC_R020.jsonl`，也不会更新最终 JSON。

### Step 2 — New Claude conversation / 粘贴顺序

每条 Validation **重新开启一个 Claude Session**，按以下顺序提供资料：

1. `R020_HEADER.txt`：本次任务身份与约束，Claude 应等待最后的 Execute 指令。
2. `R020_CONTEXT.txt`：原始 Validation、Row Key/Fingerprint 和固定 Schema。
3. `context_packs/shared/ASAP_KNOWLEDGE_CONTEXT.md`：通用 ASAP 文档全文（必要时按完整 Source Blocks 分次 Paste）。
4. `R020_EXECUTE.txt`：**最后发送**，启动本 Record 的深度分析。

**重要：本地路径不代表 Claude 能读取本地文件。** 必须实际粘贴 Markdown 的内容，或通过经批准的 Chat 页面 Pasted Text 附件提供，而不是只在消息中写文件路径。不要同时粘贴四份独立 Manual 和 Shared Context，避免重复消耗 Token。

如果希望**一个 Record Context 文件包含 Shared 全文**，也可以运行：

```powershell
py tools/single_validation.py prepare --id 20 --embed-shared
```

此时粘贴顺序改为 `HEADER → CONTEXT → EXECUTE`，**不要再额外粘贴 Shared 文件**。

> 提示：`--embed-shared` 是本地拼接选项，并不减少 Token。若 Context 太长，应改用 Selected Mode。

### Step 3 — Claude outputs / 本地保存

Claude 完成后应生成两个 Artifact：

| Claude 输出 | 保存位置 | 功能 |
|---|---|---|
| `SPEC_R020.jsonl` | `patches/by_record/SPEC_R020.jsonl` | `R020` 以及所有 `C020-##` 的 Specs |
| `QA_R020.json` | `qa/by_record/QA_R020.json` | 来源、假设、缺口和 Readiness 报告 |

`SPEC_R020.jsonl` 要求：**一行一个完整 JSON 对象**，不得带 Markdown 的 ```jsonl 代码围栏，也不是 JSON Array。

每条 Patch 对象的外层字段固定为：

```json
{"row_key":"R020","source_row_sha256":"<从本地 ROW_REGISTRY 取得的精确哈希>","implementation_spec":{"...":"根据真实来源完整填写"}}
```

上面的结构只是示意；不能将占位符原样当作实际 Patch。若 #20 有一个 Continuation，则应另外有 `C020-01` 的独立 JSONL 行。`source_row_sha256` 必须与本地 Registry 完全一致。

### Step 4 — Validate the patch / 本地校验

```powershell
py tools/single_validation.py validate --id 20
```

至少检查：JSONL 可以解析、Row Key 不缺失/不重复、Continuation Rows 全覆盖、每个 Patch 对应的原始 Fingerprint 正确，以及 `implementation_spec` 满足本项目 Schema 的必需字段和支持的类型约束。

**此检查不能保证 Claude 的 ASAP API 映射或公式真的正确。** 必须对重要技术结论核对所引用的 Manual 章节，`implementation_readiness: ready` 不应替代证据审查。

如果验证失败，先检查 `SPEC_R020.jsonl` 是否确实使用当前 Registry 的真实 Hash、是否包含所有关联 Row Keys，以及有无从 Claude 复制出的代码围栏。

### Step 5 — Incremental Merge / 增量写入

验证通过后运行：

```powershell
py tools/single_validation.py merge --id 20
```

输出：

`final/validation_master_enriched.json`

第一次 Merge：基于原始 Flat JSON 创建 Enriched JSON，只添加 #20 和 Continuation Rows 的 `implementation_spec`。

之后处理 #21：

```powershell
py tools/single_validation.py prepare --id 21
# New Claude conversation; 保存 SPEC_R021.jsonl / QA_R021.json
py tools/single_validation.py validate --id 21
py tools/single_validation.py merge --id 21
```

这会在**同一份** `final/validation_master_enriched.json` 中保留 #20，新增 #21，不会将原有记录清空。

重新分析一个已经 Merge 的 Record，需要显式使用：

```powershell
py tools/single_validation.py merge --id 20 --replace
```

新版脚本替换前会为现有 Enriched JSON 创建带时间戳的 `.bak.json` 备份；操作完成后可检查 `final/`。

### Step 6 — Open / Verify final output

```powershell
code final/validation_master_enriched.json
# 或
explorer final
```

也可执行：

```powershell
Test-Path final/validation_master_enriched.json
```

`True` 表示文件存在，但并不等于全部 92 条 Validation 都完成。尚未分析的 Record 可以不含 `implementation_spec`；这是**增量处理**的预期行为。

## 5. 其他 Manual Modes / Token 管理

### Shared mode（默认，推荐）

```powershell
py tools/single_validation.py prepare --id 20
```

生成小型 Record Context；Claude 中再 Paste 一份 Shared Knowledge。

### Shared mode + Embed（只粘贴一份 Context）

```powershell
py tools/single_validation.py prepare --id 20 --embed-shared
```

Record Context 中已包含 Shared 全文；Claude 中不必再粘贴 Shared。

### Full mode（旧模式）

```powershell
py tools/single_validation.py prepare --id 20 --manual-mode full
```

从 `source/` 直接读取四份独立 Markdown，并包含在每条 Record Context 中，不依赖 Shared 文件。

### Selected mode（只提供相关章节）

先在本地创建实际存在的片段文件，例如 `source/chunks/SM_interest.md`，再运行：

```powershell
py tools/single_validation.py prepare --id 20 --manual-mode selected `
  --include ASAP_SCRIPTING_MANUAL:source/chunks/SM_interest.md `
  --include ASAP_USER_MANUAL:source/chunks/UM_bond.md
```

所列片段必须确实存在。Claude 只能基于当前实际粘贴的章节得出技术结论；未提供来源的能力标为未解决。

## 6. 常见问题 / Troubleshooting

| 问题 | 原因 / 处理 |
|---|---|
| `unrecognized arguments: --embed-shared` | 正在使用旧版 `single_validation.py`；替换为支持 shared 的新版。 |
| `invalid choice: 'shared'` | 同样说明旧脚本尚未更新。 |
| `Shared Context not found` | 运行 `py tools/build_asap_context.py`，确认文件在 `context_packs/shared/`。 |
| `Missing or duplicated source` | Shared 文件缺少四个 SOURCE_ID 之一，或将相同 Source Block 重复合并。 |
| `Source fingerprint mismatch` | 原始 Flat JSON 与 Row Registry 不一致；检查文件版本，不要改 Hash 绕过验证。 |
| `Patch fingerprint mismatch` | Claude 输出 Hash 和 Registry 不符；从对应 Registry 条目核实并纠正 Patch。 |
| `Patch row coverage mismatch` | 缺少目标主行或 Continuation，或含无关 Row Key。 |
| `Invalid JSONL` | 复制了 Markdown 代码围栏、漏掉对象边界、用 JSON Array 代替 JSONL 等。 |
| `already enriched` | 此 Record 已 Merge；如确实需要替换，使用 `--replace`。 |
| `Original data changed` | `final/` 中已有文件与原始 Flat JSON 不一致；检查是否手动改动了业务字段或 `development_status`。 |
| `validate` 通过但没有 final JSON | `validate` 不创建最终文件；继续运行 `merge`。 |
| Claude Context 超出限制 | 不要同时提供 Full/Shared 两份；用 `selected` 只提供经过定位的章节。 |

## 7. 最短日常命令 / Quick Reference

首次初始化：

```powershell
py tools/build_registry.py
py tools/build_asap_context.py
```

每一条 Validation：

```powershell
py tools/single_validation.py prepare --id 20
# Claude: HEADER → CONTEXT → SHARED → EXECUTE
# Save: patches/by_record/SPEC_R020.jsonl and qa/by_record/QA_R020.json
py tools/single_validation.py validate --id 20
py tools/single_validation.py merge --id 20
```

重新分析同一条：

```powershell
py tools/single_validation.py merge --id 20 --replace
```

**最终原则：** 一条 Validation、一轮 Claude、一个 JSONL Patch、一次本地校验、一次增量 Merge。继续保留原始数据和明确来源证据。
