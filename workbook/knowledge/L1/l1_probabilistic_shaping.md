# L1 · 概率成形（Probabilistic Shaping）

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 80

## Research Question
在 16QAM 上对部分比特施加非均匀概率（成形），能否在保持/可控牺牲信息速率的前提下，
系统性地改变平均符号能量，从而服务于「信息-能量协同传输」的权衡？

## Hypotheses
- H1: 减小成形参数 p（偏离 0.5）会**降低平均符号能量** E(p)=18−16p，可为能量收获腾出预算 → 由 l2_run_single / l2_run_sweep 验证。
- H2: 成形在压低码率上界 R=ΣK/(4N) 的同时，存在使 Goodput-能量代价最优的 p 区间 → 由 l2_run_sweep 验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| p | 成形参数（受控比特为 1 的概率口径） | — | config.p_fixed / p_candidates |
| h(p) | 比特熵 −p·log2 p −(1−p)·log2(1−p) | bit | l3_sim_shaped_polar_16qam |
| E(p) | 平均符号能量 = 18 − 16p（归一化前） | 能量 | l3_compute_energy |
| S | 整形位数 = ceil(N(1−h)) | — | l3_sim_shaped_polar_16qam |

## Theoretical Boundaries
- 归一化能量 `E_norm = (18−16p)/10`，基线 E(0.5)=10。
- 半径类别概率：内 `p²`、中 `2p(1−p)`、外 `(1−p)²`。
- 源极化整形：整形位由 SC 在先验 `ln((1−p)/p)` 下确定性生成。

## Pitfalls（护栏）
- ⚠️ 判定成形后吞吐优劣前，先核对码率上界 R=ΣK/(4N)——成形本就压低上界，不能与基线直接比绝对 Goodput。见 `workbook/mandatory-rules.md` §7。
- ⚠️ 成形改变 SNR 口径含义（Es/N0 vs Eb/N0），对照前确认 `cfg.snr_mode`。

## Collaborators
- → l1_polar_coding：h(p) 决定 S/I/F 集合大小与冻结位布局。
- → l1_16qam_modulation_llr：成形先验进入软解调（symbol prior）与译码先验（bit prior）。
- → l1_metrics_tradeoff：E(p) 是能量轴，Goodput 是信息轴。

## Code Anchors
- l3_compute_energy（core/compute_energy.m）
- l3_sim_shaped_polar_16qam（整形位生成 prepare_one_bit）
- l3_SC_decoder_prior / l3_SCL_decoder_prior（先验译码）
