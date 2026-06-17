# SPolar16QAM 科研 Spec-Harness — Skill 集

对标 hic-spec 的扫描 harness，把"代码库知识治理"范式迁移到本 MATLAB 科研项目。
三个 skill 协同维护 `workbook/knowledge/` 下的 L1/L2/L3 三层知识库。

## 三层模型（科研语义）

| 层 | hic-spec 原义 | 本项目科研义 | 落地目录 |
|----|---------------|--------------|----------|
| L1 | 领域专家认知 | 研究领域：问题/假设/物理量/理论边界/护栏 | `workbook/knowledge/L1/` |
| L2 | 工作流编排 | 实验流程：pipeline/参数/产物/验收 | `workbook/knowledge/L2/` |
| L3 | 原子工具契约 | 方法契约：单个 .m 函数的签名/公式/数值坑/依赖 | `workbook/knowledge/L3/` |

## Skill 一览

| skill | 对标 hic | 职责 | 触发词 |
|-------|----------|------|--------|
| `research-meta-extractor` | hic-meta-extractor | 从 .m + 周报提取 L1/L2/L3 | 提取研究元数据 / 建知识库 |
| `research-spec-checker` | l1/l2/l3-fixer 三合一 | 跨层一致性 + 理论护栏校验 | 校验知识库 / 检查一致性 |
| `research-scan-orchestrator` | hic-scan-orchestrator | 编排提取→校验→RKS 评分 | 扫描科研项目 / 跑 RKS |

## 典型用法

```text
# 全量扫描（提取 + 校验 + 评分）
"扫描这个科研项目，建 L1/L2/L3 知识库并打 RKS 分"
→ research-scan-orchestrator（Phase 0→4）

# 新增了一个 .m 函数后补契约
"给 polar/ 新增的函数补 L3 契约"
→ research-meta-extractor（Phase 0 缺口检测 → Phase 1）

# 只想检查一致性
"校验一下知识库有没有断链或没验证的假设"
→ research-spec-checker
```

## RKS 完备度评分

```bash
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```
五维：方法覆盖(0.30) / 流程覆盖(0.20) / 假设覆盖(0.20) / 跨层完整(0.15) / 理论护栏(0.15)，阈值 75。

## 与项目硬规则的关系
- 这些 skill **只读代码、只写元数据/报告**，不触发 MATLAB 长跑仿真（`workbook/mandatory-rules.md` §3）。
- L1 pitfalls 与 L2 acceptance 都回链到既有规则（§7 码率上界、§8 瀑布区、AGENTS.md 三基线），
  让知识库成为这些硬规则的"结构化索引"，而非另立一套规则。
