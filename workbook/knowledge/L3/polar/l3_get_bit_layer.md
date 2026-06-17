# L3 · get_bit_layer

- **method_id**: l3_get_bit_layer
- **file_path**: 16QAM_Polar/v2/polar/get_bit_layer.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`N`（码长）
**输出**：`layer_vec`（N×1，每个 phi 索引对应的部分和回传层）

## Purpose
预计算 SC/SCL 译码中部分和（partial-sum）回传时每个 phi 需要更新到哪一层，配合 `get_llr_layer` 使用。

## Math / Algorithm
对 phi = 0..N-1，先 `psi = floor(phi/2)`，再数 `psi` 二进制末尾连续 1 的个数为 layer。`layer_vec(phi+1) = layer`。

## Numerical Notes
无；纯整数位运算预计算。

## Dependencies
无

## Health
healthy
