# L1 · 多载波 OFDM（Multicarrier OFDM）— Stage B

- **domain_id**: l1_multicarrier_ofdm
- **maturity**: active（Stage B 在研，部分占位）
- **rks_score**: 60

## Research Question
将单载波成形极化码系统扩展到多载波 OFDM 后，如何在频选信道上按子载波分配
「信息传输 / 能量成形 / 纯能量传输」策略，最大化信息-能量协同收益？

## Hypotheses
- H1: 最小 OFDM 全链路基线（均匀 p、AWGN、SC）能跑通并复现单载波量级结果 → 由 l2_ofdm_baseline 验证。
- H2（计划）: 按子载波信道质量分配策略，可优于均匀策略 —— **须与三基线对照后才可下结论**。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| n_subcarriers | 子载波数 | — | run_ofdm_baseline（64） |
| cp_ratio | 循环前缀比例 | — | run_ofdm_baseline（1/4） |
| （计划）子载波 SNR 分布 | 频选信道每子载波 Es/N0 | dB | Stage B 扩展 |

## Theoretical Boundaries
- 基线：均匀 p、AWGN OFDM、SC 译码、轻量代表性网格。
- （计划）Rayleigh 子载波 profile、子载波策略对比。

## Pitfalls（护栏）
- ⚠️ **Stage B 核心硬规则**：不得在与三个计划基线（好信道信息、好信道能量成形、坏信道纯能量传输）
  对照前宣称某多载波策略"最优"（`AGENTS.md` Non-Negotiables / 阶段B文档）。
- ⚠️ 多载波模块仍在建，部分 pipeline 为脚本内联，尚未全部下沉为可复用 L3 → 本领域 rks 偏低。

## Collaborators
- ← l1_channel_snr：每子载波信道条件不同。
- ← l1_metrics_tradeoff：策略对比沿用同一套指标。
- ← l1_probabilistic_shaping / l1_polar_coding：单载波核心被 OFDM 复用。

## Code Anchors
- l2_ofdm_baseline（experiments/multicarrier/run_ofdm_baseline.m）
- experiments/multicarrier/run_subcarrier_strategy_compare.m, run_rayleigh_subcarrier_profile.m（计划纳入 L2/L3）
- 周报/阶段B/B1：OFDM baseline阶段文档.md
