# L1 · 信道与 SNR 口径（Channel & SNR Convention）

- **domain_id**: l1_channel_snr
- **maturity**: active
- **rks_score**: 78

## Research Question
在 AWGN 信道上，成形改变星座能量后，如何定义一致的 SNR 口径（Es/N0 vs Eb/N0），
使不同 p 之间的 BER/Goodput 对比公平、可解释？

## Hypotheses
- H1: 在 `fixed_esn0`（按帧符号功率缩放噪声）口径下，理论 Gray 16QAM BER 与仿真 BER 在瀑布区对齐 → 由 l2_sc_theory_vs_sim / l2_find_waterfall_and_refine 验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| sigma | `10^(−snr_dB/20)` | — | 仿真主循环 |
| sigma_noise | 实际加噪标准差（按口径缩放） | — | l3_sim_shaped_polar_16qam |
| Es/N0 | 符号级 SNR | dB | fixed_esn0 |
| Eb/N0 | 比特级 SNR | dB | fixed_n0 |

## Theoretical Boundaries
- `fixed_esn0`：`N0 = Es_frame / 10^(SNR/10)`，SNR 指 Es/N0。
- `fixed_n0`：`N0 = snr_ref_power / 10^(SNR/10)`，SNR 指 Eb/N0。
- 两口径下理论 BER 同用 Gray 16QAM 公式 `BER = (3/8)·Q(√(2·Eb/N0))`。
- AWGN：`rxSym = txSym + sigma_noise·(randn + j·randn)`。

## Pitfalls（护栏）
- ⚠️ **同口径原则**：理论-仿真对照时不可同时改公式、仿真链、SNR 定义三者（`workbook/mandatory-rules.md` §8）。
- ⚠️ 高 SNR 全零错误不是 BER 异常——应移到更低 SNR 找瀑布区，不要从单个高 SNR 点推断机制（§8）。
- ⚠️ 切换 `cfg.snr_mode` 会改变 SNR 的物理含义，跨实验对比前务必统一。

## Collaborators
- → l1_polar_coding：sigma 决定 GA 初值 `2/sigma²`。
- → l1_16qam_modulation_llr：sigma_noise 决定 LLR 噪声方差口径。
- → l1_multicarrier_ofdm：OFDM 下每子载波信道条件不同（Stage B 扩展）。

## Code Anchors
- l3_sim_shaped_polar_16qam（snr_mode 分支、加噪、LLR 口径）
- config.snr_mode / snr_ref_power / llr_use_legacy_noisevar
