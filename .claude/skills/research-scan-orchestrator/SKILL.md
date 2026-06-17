---
name: research-scan-orchestrator
description: |
  科研三层知识库全量扫描编排器（对标 hic-scan-orchestrator）。端到端编排
  research-meta-extractor（提取）→ research-spec-checker（校验）→ RKS 完备度评分 的流水线，
  产出报告到 workbook/knowledge/reports/。
  触发场景：
  (1) 用户说"扫描科研项目""全量扫描""跑一遍知识库流程"
  (2) 用户说"跑完备度评分""RKS""知识完备度评分"
  (3) 新项目接入需从零建 L1/L2/L3，或存量项目补全 + 评分
---

# research-scan-orchestrator — 科研知识库扫描编排器

编排提取→校验→评分的闭环，确保 L1/L2/L3 元数据形成可度量的完备度闭环。**编排而非重写**。

## 子能力依赖
```
research-meta-extractor  → 提取 L1/L2/L3（产出 workbook/knowledge/{L1,L2,L3}/）
        │
research-spec-checker    → 跨层一致性 + 理论护栏校验
        │
rks_evaluate.py          → 五维完备度评分 + scan-ledger.tsv
        │
        └→ 总报告 workbook/knowledge/reports/scan-summary-{ts}.md
```

## Phase 0 — 初始化与缺口检测
```bash
# 环境检查
ls workbook/knowledge/L1 workbook/knowledge/L2 workbook/knowledge/L3 2>/dev/null
# L3 缺口（防止只改存量）
for mod in core polar modulation analysis; do
  find 16QAM_Polar/v2/$mod -name '*.m' -exec basename {} .m \; ; done | sort > /tmp/all.txt
find workbook/knowledge/L3 -name 'l3_*.md' -exec basename {} .md \; | sed 's/^l3_//' | sort > /tmp/have.txt
comm -23 /tmp/all.txt /tmp/have.txt   # 缺失契约
```
展示缺口清单，确认后进入提取。

## Phase 1 — 提取（调用 research-meta-extractor）
按缺口清单：新契约从零提取，存量按需补全。覆盖 L3 → L2 → L1。

## Phase 2 — 校验（调用 research-spec-checker）
跑三类校验，输出分级问题清单（🔴/🟡/🟢）。

## Phase 3 — RKS 评分
```bash
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```
五维评分定义见 `references/rks-scoring.md`。

## Phase 4 — 总报告
汇总各阶段结果到 `workbook/knowledge/reports/scan-summary-{ts}.md`：
```
📊 三层知识库扫描总报告
  L1 领域: n  | L2 流程: m | L3 方法: p
  RKS: NN.N [阈值 75] → PASS/BELOW
  覆盖率: 方法 X% / 流程 Y% / 假设 Z%
  跨层完整: W%   护栏遵守: V%
  待处理（按严重度）: 🔴.. 🟡.. 🟢..
  建议下一步: [P0/P1/P2]
```

## 模式速查
| 模式 | 执行 Phase | 场景 |
|------|-----------|------|
| 全量扫描 | 0→1→2→3→4 | 新建或重做 |
| 增量扫描 | 0→1(部分)→2→3→4 | 补新函数/领域 |
| 仅校验+评分 | 0→2→3→4 | 已有知识库，只检查 |
| 仅评分 | 3 | 快速看 RKS |

## 硬规则遵守
- **不触发 MATLAB 长跑仿真**（项目硬规则 §3）；本编排只读代码 + 写元数据/报告。
- 本次扫描产出须在相关 `周报/*.md` 记一笔变更（硬规则 §1）。
- 评分脚本纯 Python 标准库，本地可跑。

## 目录
```
research-scan-orchestrator/
├── SKILL.md
├── references/rks-scoring.md      ← 五维评分定义
└── scripts/rks_evaluate.py        ← 评分 CLI（标准库）
```
