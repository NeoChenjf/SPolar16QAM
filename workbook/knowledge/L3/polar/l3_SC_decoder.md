# L3 · SC_decoder

- **method_id**: l3_SC_decoder
- **file_path**: 16QAM_Polar/v2/polar/SC_decoder.m
- **module**: polar
- **health**: healthy

## Signature
**输入**
| 参数 | 类型 | 含义 |
|------|------|------|
| llr | N×1 | 信道 LLR |
| K | int | 非冻结位总数（|S|+|I|） |
| frozen_bits | N×1 | 冻结位标记（1=frozen, 0=unfrozen） |
| lambda_offset | vector | `2.^(0:log2(N))` 偏移表 |
| llr_layer_vec | N×1 | 见 l3_get_llr_layer |
| bit_layer_vec | N×1 | 见 l3_get_bit_layer |

**输出**：`polar_info_esti`（K×1，非冻结位硬判决）

## Purpose
基于 LLR 的串行抵消（Successive Cancellation）译码器，**均匀先验**版本。同时被复用为「源极化整形」生成整形位。

## Math / Algorithm
- **f 节点（min-sum）**：`f(a,b) = sign(a)·sign(b)·min(|a|,|b|)`
- **g 节点**：`g(a,b,û) = (1-2û)·a + b`
- 按蝶形结构逐位 phi 递推 LLR，冻结位判 0，非冻结位 `û = [P(1) < 0]`，部分和按 `bit_layer` 回传。

## Numerical Notes
- min-sum 近似无溢出问题；硬判决阈值在 LLR=0。

## Dependencies
- 消费 l3_get_llr_layer, l3_get_bit_layer, lambda_offset（均在 l3_sim_shaped_polar_16qam 内预计算）

## Health
healthy
