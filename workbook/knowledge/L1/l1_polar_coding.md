# L1 · 极化码（Polar Coding）

- **domain_id**: l1_polar_coding
- **maturity**: active
- **rks_score**: 82

## Research Question
如何用极化码在成形约束（部分位被整形占据）下，正确划分 S/I/F 集合并可靠译码，
使非均匀先验信息被译码器充分利用？

## Hypotheses
- H1: 极化编码 + SC 译码在 AWGN 下可正确恢复 4 路并行信息位，BER 随 SNR 单调下降 → 由 l2_run_single 验证。
- H2: GA 估计的虚拟信道可靠性排序，能正确指导 S/I/F 划分，使理论与仿真趋势一致 → 由 l2_sc_theory_vs_sim / l2_sc_ga_only_curve 验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| N | 码长（2 的幂） | — | config.N=1024 |
| K | 每路信息位数 = ceil((N−S)/2) | — | l3_sim_shaped_polar_16qam |
| E[LLR_i] | 各虚拟信道 LLR 均值（可靠性） | — | l3_GA |
| L | SCL 列表大小 | — | config.SCL_L=8 |

## Theoretical Boundaries
- 编码 `x = u·G_N (mod 2)`，`G_N = F^{⊗n}`，`F=[1 0;1 1]`。
- SC f/g 节点：`f=sign·sign·min(|·|)`，`g=(1−2û)a+b`。
- 设计码率上界 `R = ΣK/(4N)`（成形会压低）。
- GA 蝶形：上支 `phi^{-1}(1−(1−phi(u))²)`，下支 `2u`。

## Pitfalls（护栏）
- ⚠️ 判定吞吐/译码"差"前先核对码率上界（`workbook/mandatory-rules.md` §7）——设计码率限制不是算法失败。
- ⚠️ 理论 vs 仿真对照不可同时改公式/仿真链/SNR 定义（§8 同口径原则）。
- ⚠️ `get_GN`/`polar_encoder` 用稠密矩阵 O(N²)，大码长有性能隐患。
- ⚠️ `cfg.decoder='SCL'` 默认走**带先验**版本（l3_SCL_decoder_prior），`'SCL_no_prior'` 才是标准 SCL。

## Collaborators
- → l1_probabilistic_shaping：成形熵决定集合划分。
- → l1_16qam_modulation_llr：译码输入是 16QAM 软解调 LLR。
- → l1_channel_snr：GA 初值 `2/sigma²` 依赖信道 sigma。

## Code Anchors
- l3_GA, l3_phi, l3_phi_inverse, l3_derivative_phi（GA 估计）
- l3_polar_encoder, l3_get_GN（编码）
- l3_SC_decoder[_prior], l3_SCL_decoder[_prior]（译码）
- l3_get_llr_layer, l3_get_bit_layer（译码辅助）
