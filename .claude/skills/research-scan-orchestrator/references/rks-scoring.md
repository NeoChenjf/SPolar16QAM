# RKS — Research Knowledge Score 评分体系

对标 hic-spec 的 KCS（Knowledge Completeness Score），把"知识完备度"从业务代码迁移到科研项目。

## 五维评分（加权总分，阈值 75）

| 维度 | 权重 | 定义 | 类比 |
|------|------|------|------|
| method_coverage | 0.30 | 已建 L3 契约的 .m 函数 / 全部 .m 函数 | 仪器都有说明书吗 |
| flow_coverage | 0.20 | 已建 L2 流程引用的 run_* 入口 / 全部入口 | 实验都有 SOP 吗 |
| hypothesis_coverage | 0.20 | 被某 L2 validates 引用的假设 / 全部 L1 假设 | 假设都有实验验证吗 |
| cross_layer_integrity | 0.15 | L2 的 l3_ref/validates 可解析比例 | 引用都不断链吗 |
| theory_guardrail | 0.15 | 含 pitfalls 的 L1 在 L2 acceptance 留痕比例 | 护栏都被执行了吗 |

`RKS = Σ 维度分 × 权重`，每维 0–100。

## 阈值与判定
- `RKS ≥ 75` → PASS
- `RKS < 75` → BELOW THRESHOLD，按断链/缺口/护栏缺失优先级补全

## 账本 scan-ledger.tsv
表头：`timestamp  system_id  rks  method  flow  hypothesis  integrity  guardrail  verdict`
每次评分追加一行，用于跟踪完备度随时间的提升趋势（对标 hic 的 scan-ledger）。

## 运行
```bash
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```

## 设计说明
- method_coverage 权重最高（0.30）：科研项目的"专家知识"主要沉淀在方法契约（公式、数值坑）。
- theory_guardrail 单独成维：科研最致命的不是漏函数，而是**违反同口径/瀑布区/码率上界等理论护栏**
  导致错误结论，所以护栏遵守必须可量化。
- 脚本只用 Python 标准库（os/re/argparse/datetime），无 numpy/yaml 依赖，保证本地零配置可跑。
