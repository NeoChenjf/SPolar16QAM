# 一致性校验规则细则

## A. 假设覆盖矩阵（L1 → L2）

对每个 L1 文件：
1. 抓 `domain_id` 与所有 `Hn:` 假设编号。
2. 在全部 L2 文件文本里搜 `l1_domain#Hn`。
3. 命中 = 已验证；未命中 = 🟡 覆盖缺口。

输出矩阵：
```
| L1 domain | 假设数 | 已验证 | 缺口 | 覆盖率 |
| l1_metrics_tradeoff | 2 | 2 | 0 | 100% |
```

## B. 跨层引用校验

| 规则 | 检查 | 严重度 |
|------|------|--------|
| B1 l3_ref 存在性 | L2 中每个 `l3_xxx` 在 L3/ 有同名文件 | 🔴 断链 |
| B2 l1 domain 存在性 | L2 `validates` 的 `l1_xxx` 有对应 L1 文件 | 🔴 断链 |
| B3 L3 孤儿 | L3 契约未被任何 L2 pipeline 引用 | 🟢 提示 |
| B4 依赖闭合 | L3 `dependencies` 的 `l3_ref` 都存在（不悬空、不自环） | 🟡 |

## C. 理论护栏遵守

| 规则 | 检查逻辑 | 严重度 | 回链 |
|------|---------|--------|------|
| C1 瀑布区 | 含瀑布区 pitfalls 的 L1，关联 BER 类 L2 的 acceptance 须提瀑布区 | 🔴 | mandatory-rules §8 |
| C2 码率上界 | 含码率上界 pitfalls 的 L1，关联吞吐类 L2 须提 R=ΣK/(4N) | 🔴 | §7 |
| C3 长跑权限 | runtime=long 的 L2 必须 `needs_user_run: true` | 🔴 | §3 |
| C4 Stage B 三基线 | l1_multicarrier_ofdm 关联 L2 须提三基线对照 | 🔴 | AGENTS.md |
| C5 LLR 口径 | 调制类 L1 须提噪声方差口径一致性 | 🟡 | — |

## 健康度联动
- L3 标 `degraded`/`broken` 的方法，若被 L2 pipeline 关键步引用且 L2 未在 acceptance 说明限制
  （如"近似模型不作定量"）→ 🟡 提示。
  典型：`l3_estimate_ber_hat_sc_dual`(degraded) 被 l2_sc_ga_only_curve / l2_find_waterfall 引用，
  须在 acceptance 标"理论估计，最终以 Monte Carlo 为准"。

## 不做的事
- 不自动改 md；只给"建议新增/补全"清单。
- 不改 .m 代码。
