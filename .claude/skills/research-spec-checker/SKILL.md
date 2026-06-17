---
name: research-spec-checker
description: |
  科研三层知识库一致性与理论护栏校验器（对标 hic 的 l1-quality-fixer + l2-gap-fixer +
  l3-constraint-checker 三合一）。校验 workbook/knowledge/ 下 L1/L2/L3 的跨层引用完整性、
  假设覆盖、理论护栏遵守，输出分级问题清单。
  触发场景：
  (1) 用户说"校验知识库""检查 L1/L2/L3 一致性""跑一遍检查"
  (2) 提取/修改元数据后做质量门禁
  (3) 想知道哪些假设没有实验验证、哪些引用断链
---

# research-spec-checker — 科研知识库一致性校验器

不修改代码，只校验三层元数据自洽性，并把问题按严重度分级输出。

## 三类校验

### A. 假设覆盖（L1 ↔ L2）
- 取每个 L1 的 `hypotheses`（`#Hn`），检查是否有 L2 的 `validates` 引用它。
- 无人验证的假设 → 🟡 覆盖缺口。

### B. 跨层引用完整（L2 ↔ L3 / L2 ↔ L1）
- L2 pipeline 的每个 `l3_ref` 必须能在 `workbook/knowledge/L3/**/l3_*.md` 找到对应文件。
- L2 `validates` 的 `l1_xxx` 必须存在对应 L1 文件。
- 断链 → 🔴 严重。
- 反向：L3 契约未被任何 L2 引用 → 🟢 孤儿方法（提示，非错误）。

### C. 理论护栏遵守（L1 pitfalls → L2 acceptance）
- 含 `⚠️` pitfalls 的 L1，其关联 L2 的 `acceptance` 应留护栏痕迹
  （瀑布区 / 码率上界 / needs_user_run / 三基线 / 口径）。
- 护栏在实验流程里"消失" → 🔴 理论风险（可能违反 `workbook/mandatory-rules.md`）。
- 长跑 L2 未标 `needs_user_run: true` → 🔴（违反硬规则 §3）。

详见 `references/consistency-rules.md`。

## 执行方式

可用纯脚本快速量化（与 RKS 同源）：
```bash
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam
```
脚本输出含「断链引用」清单（cross_layer_integrity 维度）。

再做人工/语义层校验（脚本覆盖不到的 A、C 语义判断），输出：

```
🔍 知识库一致性报告
━━━━━━━━━━━━━━━━━━━━
🔴 High（N）:
  - l2_xxx 引用 l3_yyy 不存在（断链）
  - l1_zzz 的瀑布区护栏在 l2_www acceptance 缺失
🟡 Medium（M）:
  - l1_aaa#H3 无 L2 验证
🟢 Low（P）:
  - l3_bbb 未被任何 L2 引用（孤儿）
━━━━━━━━━━━━━━━━━━━━
```

## 边界
- 只读校验，**不自动改文件**；发现问题给修复建议，由用户或 extractor 修。
- 格式损坏的 md 报告但不强改。
