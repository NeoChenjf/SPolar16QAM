# L2 · run_sc_ga_only_curve（仅 GA 理论曲线）

- **flow_id**: l2_sc_ga_only_curve
- **entry_script**: 16QAM_Polar/v2/run_sc_ga_only_curve.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: l1_polar_coding#H2

## Purpose
只画 SC 编码侧的 GA 理论估计曲线，**不含仿真、不含校准**。用于先单独看理论趋势是否合理，
作为后续与 Monte Carlo 对照的基础图，避免校准线/仿真线干扰理论判断。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | GA 可靠性估计 | l3_GA | 每个 (p, SNR) |
| 2 | 位级误码近似 | l3_phi | `pe ≈ 0.5·phi(reliability)` |
| 3 | 绘理论曲线 | （脚本内联绘图） | 纯理论，无仿真 |

## Inputs
- p_list=[0.5 0.4 0.3 0.2 0.1], snr_grid=-20:2:10, pe_floor=1e-12, decoder='SC', seed=20260421

## Outputs
- GA-only 理论 BER 曲线图（保存到 results/）。

## Acceptance
- 曲线趋势随 SNR 单调下降、随 p 变化方向符合理论预期。
- ⚠️ 这是**理论估计**，不可当作最终定量 BER（最终以 Monte Carlo 为准）。

## Weekly Report
- 关联理论基础图阶段周报。
