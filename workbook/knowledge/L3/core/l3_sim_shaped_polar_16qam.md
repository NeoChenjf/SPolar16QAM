# L3 · sim_shaped_polar_16qam

- **method_id**: l3_sim_shaped_polar_16qam
- **file_path**: 16QAM_Polar/v2/core/sim_shaped_polar_16qam.m
- **module**: core
- **health**: healthy — 已修复原 get_16test 的 frozen_bits 引用 bug；统一了三个旧入口的功能

## Signature
**输入**
| 参数 | 类型 | 含义 |
|------|------|------|
| p | 标量 | 整形参数，填充 `cfg.p_fixed` 中 NaN 位置的比特概率 |
| snr_dB | 1×nSNR | SNR 向量（dB） |
| cfg | struct | `config()` 返回的参数结构体 |

**输出**
| 参数 | 类型 | 含义 |
|------|------|------|
| result | struct | 含 `.BER .BLER .BER_per_bit .BLER_per_bit .MI .MI_total .spow .K .S_size .R_total .E_theory .p .snr_dB .cfg` |

## Purpose
16QAM 概率整形极化码的**端到端蒙特卡洛仿真**主函数：4 路并行极化码 → Gray 16QAM →
AWGN → 软解调 LLR → SC/SCL 译码 → BER/BLER/MI 统计。这是整个项目的核心计算单元。

## Math / Algorithm
- **整形熵 → 集合划分**：每路比特概率 `pb`，熵 `h = -pb·log2(pb) - (1-pb)·log2(1-pb)`；
  整形位数 `S = ceil(N·(1-h))`，信息位数 `K = ceil((N-S)/2)`（剩余为冻结位 F）。
- **源极化整形**：整形位由 `SC_decoder` 在先验 LLR `ln((1-pb)/pb)` 下确定性生成。
- **GA 排序**：每个 SNR 用 `GA(sigma,N)` 估计各虚拟信道可靠性，降序排得 S/I/F。
- **信道**：`sigma = 10^(-snr_dB/20)`；`fixed_esn0` 模式按帧符号功率缩放噪声，`fixed_n0` 模式固定噪声功率。
- **LLR 噪声方差口径**：默认 `NoiseVariance = 2·sigma_noise^2`（匹配口径）。
- **互信息估计**：`I(B;L) = 1 - E[log2(1 + e^{-sL})]`，`s = 1-2x`。
- **解析能量**：`E_theory = 18 - 16p`（归一化前）。
- **加权 BER**：`BER = Σ_b K_b·BER_b / ΣK_b`。

## Numerical Notes
- ⚠️ LLR 噪声方差有 legacy 开关 `cfg.llr_use_legacy_noisevar`（旧实现用 `2·sigma^2`），仅复现旧实验时启用 → 见 `health=degraded` 的口径风险。
- ⚠️ 高 SNR 出现全零错误属正常，**不是异常**（见 l1_metrics_tradeoff pitfalls / `workbook/mandatory-rules.md`）。

## Dependencies
- l3_GA, l3_get_llr_layer, l3_get_bit_layer, l3_polar_encoder, l3_parallel_to_serial_bits,
  l3_SC_decoder, l3_SC_decoder_prior, l3_SCL_decoder, l3_SCL_decoder_prior
- 内联调用 MATLAB `qammod` / `qamdemod`（Gray, UnitAveragePower）

## Health
healthy — 主仿真核心；注意 legacy LLR 口径开关默认关闭。
