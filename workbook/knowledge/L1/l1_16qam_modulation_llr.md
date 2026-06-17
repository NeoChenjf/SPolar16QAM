# L1 · 16QAM 调制与软解调（Modulation & LLR）

- **domain_id**: l1_16qam_modulation_llr
- **maturity**: active
- **rks_score**: 80

## Research Question
在 Gray 16QAM 上，如何在均匀与非均匀（成形）先验下，计算与 MATLAB qammod/qamdemod
口径一致、数值稳定的精确比特 LLR，使译码器获得正确的软信息？

## Hypotheses
- H1: 自实现 LSE LLR 与 MATLAB `qamdemod(OutputType='llr')` 在均匀先验下数值一致 → 由诊断脚本/对照验证。
- H2: 引入符号先验 psym 的 LLR 能正确反映成形偏置，提升成形场景译码性能 → 由 l2_run_sweep（带先验译码）间接验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| LLR_b | 比特对数似然比 log P(b=0|y)/P(b=1|y) | — | l3_llr_16qam_gray_LSE |
| sigma | 每实维 I/Q 噪声标准差 | — | 仿真主循环 |
| psym | 16 符号先验概率 | — | l3_llr_16qam_gray_LSE_prior |

## Theoretical Boundaries
- 似然 `p(y|s) ∝ exp(−|y−s|²/(2σ²))`。
- 均匀：`LLR_b = LSE(−d over Sk0) − LSE(−d over Sk1)`。
- 先验：`LLR_b = log Σ_{Sk0} P(s)e^{−d} − log Σ_{Sk1} P(s)e^{−d}`。
- 比特序遵循 `de2bi(·,4,'left-msb')`（与 qammod InputType='bit' 一致）。

## Pitfalls（护栏）
- ⚠️ **噪声方差口径**必须与信道一致：主仿真默认 `NoiseVariance = 2·sigma_noise²`；
  legacy 开关 `cfg.llr_use_legacy_noisevar` 用 `2·sigma²`，仅复现旧实验（见 l3_sim_shaped_polar_16qam）。
- ⚠️ LLR 计算必须 log-sum-exp 防上/下溢；星座/标签须与 MATLAB 映射严格一致，否则 LLR 符号错。
- ⚠️ `sigma` 是**每实维**标准差，不是复噪声功率。

## Collaborators
- → l1_polar_coding：LLR 是译码器输入。
- → l1_probabilistic_shaping：成形先验 → 符号先验 psym / 比特先验。
- → l1_channel_snr：sigma 由 SNR 与功率口径决定。

## Code Anchors
- l3_llr_16qam_gray_LSE, l3_llr_16qam_gray_LSE_prior
- l3_parallel_to_serial_bits（串并）
- 内联 MATLAB qammod / qamdemod
