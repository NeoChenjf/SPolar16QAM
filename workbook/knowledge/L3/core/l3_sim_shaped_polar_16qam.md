# L3 · sim_shaped_polar_16qam

## 2026-09-12 可选能量采集

`cfg.collect_energy_frames=true`增加`result.energy_frames`（frames×13×SNR）和列名；列为frame_id、symbols、sum_abs2、sum_abs4、N0、四路errors、四路block_errors。默认不采集，旧通信行为不变。可选`energy_checkpoint(index,frames,K,S)`逐SNR调用，回调前后恢复RNG；异常传播。fixed_esn0复噪声总方差为`2*spow_frame*10^(-snr_label/10)`。单元测试核对统计开关及回调对BER和RNG无影响。

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

## 2026-10-09 构造模式契约追加

当`cfg.partition_mode='source_entropy'`时，输入`cfg.source_partition_state`提供固定S、K及源熵构造元数据；函数使用每个SNR对应的GA排序，从S以外选择I/F，并把当前SNR集合记录到`result.partition.I_by_snr/F_by_snr`。每帧`shape_stream_sc`使用当帧payload和F=0产生S，编码、译码统计都使用同一SNR下I。默认旧模式保持兼容。

适用边界：source entropy selector的有限样本估计和全零F约束是构造定义的一部分；默认SC接收度量未增加非均匀先验，本函数不证明PMF渐近精确，也不代表等功率或RF–DC结果。
