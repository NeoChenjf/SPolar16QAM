# L2 · run_ofdm_baseline（Stage B / B1 多载波基线）

- **flow_id**: l2_ofdm_baseline
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
- **runtime**: minutes（轻量代表性网格）/ long（加密）
- **needs_user_run**: false（轻量）/ true（大网格）
- **validates**: l1_multicarrier_ofdm#H1

## Purpose
Stage B / B1 的**最小 OFDM 全链路基线**：均匀 p、AWGN OFDM、SC 译码、轻量代表性网格。
作为多载波系统构建的起点，后续在此之上做子载波策略对比（信息/能量成形/纯能量传输三基线）。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 初始化（含 v2 root bootstrap） | （setup_paths/config） | 从 mfilename 定位根 |
| 2 | 单载波端到端仿真 | l3_sim_shaped_polar_16qam | 复用主仿真核心 |
| 3 | OFDM 调制/解调（子载波映射 + CP） | （脚本内联，多载波模块在建） | n_subcarriers=64, cp_ratio=1/4 |
| 4 | 指标统计 | l3_compute_goodput, l3_compute_energy | — |

## Inputs
- p_list=[0.5 0.3 0.1], snr_grid=[8 12 16 20], n_subcarriers=64, cp_ratio=1/4, channel='AWGN', num_frames=100, seed=42

## Outputs
- `results/<timestamp>_ofdm_baseline/`：参数/数据/图/README

## Acceptance
- ⚠️ **Stage B 硬规则**：不得在与三个计划基线（好信道信息、好信道能量成形、坏信道纯能量传输）
  对照前，宣称某多载波策略"最优"（`AGENTS.md` Non-Negotiables）。
- 产物须落时间戳 results/ 目录并更新 Stage B 文档。

## Weekly Report
- 周报/阶段B/B1：OFDM baseline阶段文档.md
