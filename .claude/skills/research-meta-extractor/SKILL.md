---
name: research-meta-extractor
description: |
  科研三层知识库元数据提取引擎（对标 hic-meta-extractor）。从 MATLAB 仿真代码（16QAM_Polar/v2/）
  + 周报，按 L1 研究领域 / L2 实验流程 / L3 方法契约的 schema 提取结构化元数据，写入
  workbook/knowledge/{L1,L2,L3}/。
  触发场景：
  (1) 用户说"提取研究元数据""建知识库""提取 L1/L2/L3"
  (2) 新增了 .m 函数 / run_* 入口 / 研究领域，需要补建契约
  (3) 存量知识库补全（先做缺口检测，防止只改存量）
---

# research-meta-extractor — 科研元数据提取引擎

把 MATLAB 科研代码 + 周报，翻译成 L1/L2/L3 三层结构化知识。**提取而非重写代码**。

## Schema 真相源
- L1：`workbook/knowledge/schema/L1-research-domain.md`
- L2：`workbook/knowledge/schema/L2-experiment-flow.md`
- L3：`workbook/knowledge/schema/L3-method-contract.md`

每次提取前必须先读对应 schema，严格按字段产出。

## 核心原则
1. **数学语义保真**：公式照搬源码口径（如 `E(p)=18-16p`、`I=1-E[log2(1+e^{-sL})]`、
   `S=ceil(N(1-h))`、Gray 16QAM `BER=(3/8)Q(√(2Eb/N0))`），不口算改写。
2. **护栏回链**：L1 的 pitfalls 必须能回链到 `workbook/mandatory-rules.md` / `CLAUDE.md` /
   `AGENTS.md` 既有规则，不凭空造规则。
3. **防止只改存量**：先做缺口检测（见下），新建缺失契约优先于优化存量。
4. **长跑不执行**：标 `needs_user_run: true` 的 L2 不得由 AI 触发跑仿真（项目硬规则 §3）。

## Phase 0 — 缺口检测（关键，防止只改存量）

```bash
# L3 缺口：列全部 .m 函数 vs 已有 L3 契约
for mod in core polar modulation analysis; do
  find 16QAM_Polar/v2/$mod -name '*.m' -exec basename {} .m \;
done | sort > /tmp/all_funcs.txt
find workbook/knowledge/L3 -name 'l3_*.md' -exec basename {} .md \; \
  | sed 's/^l3_//' | sort > /tmp/have_l3.txt
echo "=== 缺 L3 契约的函数 ==="; comm -23 /tmp/all_funcs.txt /tmp/have_l3.txt

# L2 缺口：run_* 入口 vs 已有 L2 流程
ls 16QAM_Polar/v2/run_*.m 2>/dev/null | xargs -n1 basename | sed 's/.m$//'
find workbook/knowledge/L2 -name 'l2_*.md' | xargs -n1 basename
```

把缺口清单展示给用户确认，再进入提取。**完成后对比文件数：若未增加，检查是否遗漏缺口项。**

## Phase 1 — L3 方法契约提取
逐 `.m` 文件读源码 → 按 L3 schema 写 `workbook/knowledge/L3/{module}/l3_{func}.md`。
提取锚点见 `references/l3-extraction-guide.md`。重点：signature、math_definition、dependencies（函数内
调用的其它 .m → l3_ref）、health（注释里的"修复 bug""legacy 口径""近似模型"）。

## Phase 2 — L2 实验流程提取
逐 `run_*.m` 入口读脚本 → 按 L2 schema 写 `workbook/knowledge/L2/l2_{flow}.md`。
pipeline 每步挂 `l3_ref`；`validates` 指向 L1 假设；长跑标 `needs_user_run: true`。
见 `references/l2-extraction-guide.md`。

## Phase 3 — L1 研究领域提取
从周报 + 代码归纳研究子领域 → 按 L1 schema 写 `workbook/knowledge/L1/l1_{domain}.md`。
每条 hypothesis 关联一个 L2（`#Hn`）；pitfalls 回链 workbook 规则。
见 `references/l1-extraction-guide.md`。

## 产出后
建议接着调用 `research-spec-checker` 做一致性校验，或 `research-scan-orchestrator` 跑全流程 + RKS 评分。
