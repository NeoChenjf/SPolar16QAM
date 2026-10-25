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


## 2026-10-10 追加：多载波P1指标解释

P1新增信息块BLER（每个实际承载信息的Polar块至少一位错误的比例），与BER、现有按资源修正Goodput并列报告。该BLER不是CRC包失败率，当前Goodput也未扣CRC、导频、同步等净吞吐开销。能量轴使用加噪前接收RF时域均方；它不是整流器DC输出。


Revision metadata: revision_id=l1_metrics_p1_20261010; current_status=current; supersedes=[baseline].


## 2026-10-24 当前研究快照：随机辅助S与P2

- **domain_id**: l1_metrics_tradeoff
- **maturity**: active
- **rks_score**: 由结构扫描报告给出，不是科研完成率。

## Research Question

固定16QAM和发送时域功率后，区分整形消息配合、频域功率分布与通信代价，并检验实际I驱动的近似预测。

## Hypothesis status

既有l1_multicarrier_ofdm#H2仍为inconclusive：原P1六策略呈现折中，无普遍占优。既有l1_probabilistic_shaping#H3保持其原构造/PMF有限范围；新随机S证明与3×8诊断不能替代原假设或正式通信验收。

## Core Quantities / Boundaries

S是变换前辅助变量，p描述目标输出标签。S冻结0与独立随机S不是同一对照；同K同I不能保证均匀。随机S使用原I∪S且只计I有效载荷；其输入自由度增加，不能宣称同代码本大小。donor S保留独立S向量统计，输出不保证均匀。原星座关系E_norm=(18−16p)/10意味着p降低时未缩放能量增加；旧H1的“降低”方向文字不再采用，但不据此升级普遍性能主张。

多载波Goodput仍为实际I位数除以4×资源网格再乘CP因子及(1−BER)。BLER沿用B4四路联合组块口径。RF为加噪前时域均方，非DC。

## Pitfalls

⚠️ 按workbook/mandatory-rules.md核对瀑布区、码率上界及长跑授权；按workbook/quality-assurance.md检查实际集合、payload语义和未测量计数。近似模型必须冻结后独立验证，源条件熵不等于S边缘熵；相关边缘不能直接相乘。原P1三类基线保留，不能用新pilot宣称最优。只读引用/文件存在不等于验收。

## Code Anchors

l2_p2_mechanism、l2_p2_auxiliary_preflight、l3_p2_distribution_reference、l3_p2_uniformity_contract、l3_p2_predict_ga。

## Evidence status

精确集合覆盖和小码长穷举已核验；3seed×8码字只探索。正式1%功率、3×80 PMF和独立预测均待本轮预算确认，未将任何历史not_assessed自动改为supporting。

Revision metadata: revision_id=p2_af47b0441cc3_20261024; current_status=current; supersedes=[l1_metrics_p1_20261010].
