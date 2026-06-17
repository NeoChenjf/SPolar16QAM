# L3 · get_llr_layer

- **method_id**: l3_get_llr_layer
- **file_path**: 16QAM_Polar/v2/polar/get_llr_layer.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`N`（码长）
**输出**：`layer_vec`（N×1，每个 phi 索引对应的 LLR 计算起始层）

## Purpose
预计算 SC/SCL 译码中每个比特位置 phi 需要从哪一层开始做 LLR 递推，避免重复计算、提升效率。

## Math / Algorithm
对 phi = 1..N-1，`layer = phi 二进制末尾 0 的个数`（不断 `/2` 直到为奇）。`layer_vec(phi+1) = layer`。

## Numerical Notes
无；纯整数位运算预计算。

## Dependencies
无

## Health
healthy
