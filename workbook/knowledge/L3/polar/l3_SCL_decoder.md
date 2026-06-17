# L3 · SCL_decoder

- **method_id**: l3_SCL_decoder
- **file_path**: 16QAM_Polar/v2/polar/SCL_decoder.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`llr`(N×1)、`L`(列表大小)、`K`(非冻结位数)、`frozen_bits`(N×1)、`lambda_offset`、`llr_layer_vec`、`bit_layer_vec`
**输出**：`polar_info_esti`（K×1）

## Purpose
基于 LLR 的串行抵消列表（Successive Cancellation List）译码器，**均匀先验**版本。单文件无子函数实现（效率考虑）。

## Math / Algorithm
- 维护 L 条路径，每条有路径度量 PM。
- f/g 节点同 SC；非冻结位对每条路径分裂 0/1 两分支，更新 PM：
  `P(1)≥0` → bit0 加 0、bit1 加 P(1)；`P(1)<0` → bit0 加 -P(1)、bit1 加 0。
- 用 `middle = min(2·活跃路径数, L)` 截断，保留 PM 最小的 L 条（剪枝 + 克隆栈）。
- **Lazy Copy**：路径克隆时只记录数据来源，避免实际复制 LLR/部分和。
- 末尾选 PM 最小路径输出。

## Numerical Notes
- 用 `realmax` 初始化淘汰分支的 PM；本实现**不含 CRC 辅助选路**（直接取 min PM）。

## Dependencies
- 消费 l3_get_llr_layer, l3_get_bit_layer, lambda_offset

## Health
healthy
