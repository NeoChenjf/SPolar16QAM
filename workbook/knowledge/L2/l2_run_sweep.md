# L2 · run_sweep（p × SNR 全网格扫参）

- **flow_id**: l2_run_sweep
- **entry_script**: 16QAM_Polar/v2/run_sweep.m
- **runtime**: long
- **needs_user_run**: true
- **validates**: l1_metrics_tradeoff#H1, l1_metrics_tradeoff#H2, l1_probabilistic_shaping#H2

## Purpose
对所有候选 p（`cfg.p_candidates`，10 个值）× 全 SNR 范围（-5:1:25）做系统性扫参，
产出完整 BER/Goodput/MI/能量/代价/Pareto 数据与图表 —— 这是 **BER/Goodput/能量三维权衡的主结果**。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 初始化 | （setup_paths/config） | 用 config 全量参数 |
| 2 | 对每个 p 跑端到端仿真 | l3_sim_shaped_polar_16qam | 外层 p 循环 |
| 3 | 计算 Goodput | l3_compute_goodput | 每 p×SNR |
| 4 | 计算理论能量 | l3_compute_energy | E(p)=18-16p |
| 5 | 计算代价函数 | l3_compute_cost | 相对 p=0.5 基线 |
| 6 | 绘图 | l3_plot_ber_vs_snr, l3_plot_goodput_vs_snr, l3_plot_mi_vs_snr, l3_plot_pareto, l3_plot_cost_curves | — |
| 7 | 提取周报素材 | l3_extract_weekly_report_from_sweep | 最优 p / Pareto 前沿 |

## Inputs（config.m）
- N=1024, p_candidates=[0.50…0.10], SNR_dB=-5:1:25, num_frames=1000, seed=42, decoder='SC'(可切 SCL)

## Outputs
- `results/<timestamp>_pareto_sweep/`：`sweep_results.mat` + `sweep_summary.csv` + `figures/` + README

## Acceptance
- ⚠️ **长跑（SC 约数小时）→ 须用户本地运行**，AI 不得擅自执行（`AGENTS.md` Non-Negotiables）。
- 产物须含参数/种子/数据/图/README（`workbook/data-management.md`）。
- 判定某 p 吞吐优劣前核对其码率上界 R=ΣK/(4N)。

## Weekly Report
- 扫参结果须更新对应阶段 `周报/*.md`（代码/结果变更须更新周报硬规则）。
