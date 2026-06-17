# L1 研究领域层 Schema —— Research Domain

> L1 是「研究领域专家认知」层。每个 L1 文件描述一个**研究子领域**：它回答什么科学
> 问题、基于什么假设、涉及哪些核心物理量与理论边界、有哪些已知陷阱（护栏）、与其它
> 领域如何耦合。对标 hic-spec 的「领域专家认知图谱」，但语义换成科研。
>
> 一句话类比：L1 就像「请一位资深审稿人坐下来，用一页纸讲清这个子领域到底在研究什么、
> 哪些坑别人踩过」。

---

## 文件命名

`workbook/knowledge/L1/l1_{domain}.md`，例：`l1_probabilistic_shaping.md`

## 字段定义

| 字段 | 必填 | 说明 |
|------|------|------|
| `domain_id` | ✅ | `l1_*`，全局唯一 |
| `domain_name` | ✅ | 中文领域名，如「概率成形」 |
| `maturity` | ✅ | `active`（在研）/ `explored`（已验证）/ `planned`（计划中，可占位） |
| `rks_score` | ✅ | 该领域完备度评分（0–100），由 `rks_evaluate.py` 回填，初始可估 |
| `research_question` | ✅ | 一句话：该领域回答的核心科学问题 |
| `hypotheses` | ✅ | 假设列表。每条假设**应能被某个 L2 实验流程验证**（供 checker 做覆盖校验） |
| `core_quantities` | ✅ | 核心物理量：符号 / 定义 / 单位 / 计算位置（指向 L3 或 config） |
| `theoretical_boundaries` | ✅ | 理论边界、极限、闭式公式（保留数学语义） |
| `pitfalls` | ✅ | ⚠️ 已知陷阱（护栏）。**优先引用** `workbook/mandatory-rules.md` 等现有硬规则 |
| `collaborators` | ⬜ | 与其它 L1 的耦合关系 + 传递的关键量 |
| `code_anchors` | ✅ | 对应的代码文件 / 函数（指向 L3 `method_id` 或 `.m` 路径） |

## Markdown 骨架

```markdown
# L1 · {domain_name}

- **domain_id**: l1_{domain}
- **maturity**: active | explored | planned
- **rks_score**: NN

## Research Question
（一句话核心科学问题）

## Hypotheses
- H1: （假设；标注由哪个 L2 验证 → l2_xxx）
- H2: ...

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| BER | 误比特率 | — | l3_sim_shaped_polar_16qam |
| E(p) | 平均符号能量 = 18 − 16p（归一化前） | 能量单位 | l3_compute_energy |

## Theoretical Boundaries
- Gray 16QAM 理论 BER：BER = (3/8)·Q(√(2·Eb/N0))
- 设计码率上界：R = ΣK / (4N)

## Pitfalls（护栏）
- ⚠️ （陷阱描述） — 见 `workbook/mandatory-rules.md` §X

## Collaborators
- → l1_polar_coding：成形熵 h(p) 决定 S/I/F 集合大小

## Code Anchors
- l3_xxx（core/xxx.m）
```

## 提取约束（System Prompt 级）

1. **聚焦科学本质**：写研究问题、假设、物理量、理论极限，不要堆 MATLAB 语法细节
   （语法细节归 L3）。
2. **假设可验证**：每条 hypothesis 尽量关联一个 L2 流程，否则 checker 会标记为「无验证缺口」。
3. **护栏回链**：pitfalls 必须能回链到项目既有规则文件（`workbook/`、`CLAUDE.md`、`AGENTS.md`），
   避免凭空发明规则。
4. **数学语义保真**：公式照搬源码与文献口径，不做近似改写。
