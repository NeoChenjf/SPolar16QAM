# L1 · 多载波 OFDM（Multicarrier OFDM）— Stage B

- **domain_id**: l1_multicarrier_ofdm
- **maturity**: active（B4b严格OFDM-Rayleigh smoke与两轮瀑布区pilot已通过，正式统计待开展）
- **rks_score**: 80

## Research Question
将单载波成形极化码系统扩展到多载波 OFDM 后，如何在频选信道上按子载波分配
「信息传输 / 能量成形 / 纯能量传输」策略，最大化信息-能量协同收益？

## Hypotheses
- H1: 最小 OFDM 全链路基线（均匀 p、AWGN、SC）能跑通并复现单载波量级结果 → 由 l2_ofdm_baseline 验证。
- H2（验证中）: 按子载波信道质量分配策略，可优于均匀策略。B4b六策略严格物理链路smoke与pilot已通过，pilot把普通策略的有效窗口定位为24—40 dB、纯能量策略定位为20—24 dB；**仍须正式多realization统计后才可下结论**。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| n_subcarriers | 子载波数 | — | run_ofdm_baseline（64） |
| cp_ratio | 循环前缀比例 | — | run_ofdm_baseline（1/4） |
| 子载波频响 | `|H_k|²`及high/mid/low分组 | — | B2/B4b channel CSV |
| OFDM帧资源 | 49个OFDM符号、padding 2.0408% | — | B4b smoke |
| 接收能量代理 | Rayleigh后、AWGN前时域均方 | 相对功率 | B4b repetition CSV |

## Theoretical Boundaries
- 基线：均匀 p、AWGN OFDM、SC 译码、轻量代表性网格。
- B4b采用三组独立polar块映射到真实子载波，不等同于64套逐子载波独立polar码。
- smoke为2个realization×1帧，只验证链路与量级；两轮pilot为5个realization×2帧，仅用于冻结SNR网格，不提供稳定排序。

## Pitfalls（护栏）
- ⚠️ **Stage B 核心硬规则**：不得在与三个计划基线（好信道信息、好信道能量成形、坏信道纯能量传输）
  对照前宣称某多载波策略"最优"（`AGENTS.md` Non-Negotiables / 阶段B文档）。
- ⚠️ B4b正式统计规模已由pilot预登记为20—40 dB六点；checkpoint/resume与零错上界已通过微型控制路径验证，仍必须完成30 realization统计；不得由pilot曲线推断稳定交叉或Pareto前沿。

## Collaborators
- ← l1_channel_snr：每子载波信道条件不同。
- ← l1_metrics_tradeoff：策略对比沿用同一套指标。
- ← l1_probabilistic_shaping / l1_polar_coding：单载波核心被 OFDM 复用。

## Code Anchors
- l2_ofdm_baseline（experiments/multicarrier/run_ofdm_baseline.m）
- l2_b4b_strict_ofdm_rayleigh_smoke（experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m）
- l3_ofdm_channel_roundtrip（core/ofdm_channel_roundtrip.m）
- experiments/multicarrier/run_subcarrier_strategy_compare.m, run_rayleigh_subcarrier_profile.m（计划纳入 L2/L3）
- 周报/阶段B/B1：OFDM baseline阶段文档.md
