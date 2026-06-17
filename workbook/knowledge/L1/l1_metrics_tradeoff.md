# L1 · 指标与权衡（Metrics & Tradeoff）

- **domain_id**: l1_metrics_tradeoff
- **maturity**: active
- **rks_score**: 81

## Research Question
如何用一组自洽的指标（BER、Goodput、平均符号能量、互信息、代价、Pareto 前沿）刻画
「信息-能量协同传输」的三维权衡，并据此选出面向无电池 6G IoT 的最优工作点？

## Hypotheses
- H1: 存在使 Goodput 最大或代价最优的成形参数 p（随 SNR 变化）→ 由 l2_run_sweep 验证（含 l3_extract_weekly_report_from_sweep 自动提取最优 p）。
- H2: Goodput-能量平面上存在非平凡 Pareto 前沿，成形点可优于纯基线 → 由 l2_run_sweep（l3_plot_pareto）验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| BER | 加权误比特率 ΣK_b·BER_b/ΣK_b | — | l3_sim_shaped_polar_16qam |
| Goodput | `R_total·(1−BER)` | bit/符号·路 | l3_compute_goodput |
| E(p) | 平均符号能量 18−16p | 能量 | l3_compute_energy |
| MI | 互信息 `1−E[log2(1+e^{−sL})]` | bit | l3_sim_shaped_polar_16qam |
| cost | `−(G−G0)/(E−E0)` | — | l3_compute_cost |

## Theoretical Boundaries
- Goodput 上界由码率上界 `R=ΣK/(4N)` 限制。
- 代价仅在 `E>E0` 区有定义（能量增加换信息损失）。
- Pareto 前沿在 (E_norm, Goodput) 平面上构造。

## Pitfalls（护栏）
- ⚠️ **码率上界优先**：判定 Goodput/吞吐优劣前先核对 R=ΣK/(4N)（`workbook/mandatory-rules.md` §7）。
- ⚠️ **瀑布区优先**：解释 BER 前先定位 BER∈[1e-4,1e-1] 窗口；高 SNR 全零错误非异常（§8）。
- ⚠️ 代价函数在 `E≤E0` 处为 NaN，不可强行解读。

## Collaborators
- ← l1_probabilistic_shaping（能量轴）、l1_polar_coding（码率/BER）、l1_16qam_modulation_llr（MI）。
- 是各 L1 结论汇聚成"工作点选择"的终端领域。

## Code Anchors
- l3_compute_goodput, l3_compute_energy, l3_compute_cost
- l3_plot_ber_vs_snr, l3_plot_goodput_vs_snr, l3_plot_mi_vs_snr, l3_plot_pareto, l3_plot_cost_curves
- l3_extract_weekly_report_from_sweep
