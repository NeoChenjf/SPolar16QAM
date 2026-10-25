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


## 2026-10-10 追加：B4等发射时域功率SNR

P1定义$P_{tx}$为包含CP和padding的串行OFDM时域样本均方，目标为1；SNR标签表示$10\log_{10}(P_{tx}/E|n|²)$。对复高斯噪声，频域每实维标准差$σ=\sqrt{P_{target}/(2·10^{SNR/10})}$。此新口径单独用于固定功率P1；旧`fixed_esn0/fixed_n0`历史数据标签不自动换算成同一接收链路结论。GA按该σ构造I，接收LLR仍使用实际ZF后每实维σ并匹配缩放星座。


Revision metadata: revision_id=l1_channel_snr_p1_20261010; current_status=current; supersedes=[baseline].

## 2026-10-10 修订：OFDM辅助函数的σ接口换算

前一节将$\sqrt{N_0/2}$误标为P1的“频域每实维标准差”。实际`ofdm_channel_roundtrip`接收的是FFT后每实维标准差，并除以$\sqrt{N_{sc}}$生成时域噪声。若P1定义$N_0=P_{target}/10^{SNR/10}$为时域复噪声功率，则应传入$\sigma_{freq}=\sqrt{N_{sc}N_0/2}$；时域每实维标准差才是$\sqrt{N_0/2}$。固定噪声功率回归确认换算成立。首版噪声换算错误的中断批次已标记无效，不作为研究证据。

Revision metadata: revision_id=l1_channel_snr_noise_conversion_20261010; current_status=current; supersedes=[l1_channel_snr_p1_20261010].


## 2026-10-11 P1最终噪声口径验证

时域定义$N_0=P_{target}/10^{SNR_{dB}/10}$已由单元测试确认：当前OFDM helper的FFT域输入标准差需乘$\sqrt{N_{sc}}$，内部缩放后时域复噪声功率与目标$N_0$一致；非单位幅度端到端smoke也通过。正式SNR网格16—40 dB上所有策略共用固定复噪声功率，噪声不随策略或帧调整。旧错误换算会使时域噪声功率偏低18.06 dB，首批已标记无效。

零错误点报告有限样本上界：正式每个策略/SNR汇总30×50帧，信息位总分母按实际信息组计；上界不等于真实BER/BLER估计为零。

Revision metadata: revision_id=l1_channel_snr_p1_formal_20261011; current_status=current; supersedes=[l1_channel_snr_noise_conversion_20261010].
