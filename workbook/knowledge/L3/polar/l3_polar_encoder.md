# L3 · polar_encoder

- **method_id**: l3_polar_encoder
- **file_path**: 16QAM_Polar/v2/polar/polar_encoder.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`u`（N×1，已放好信息位/整形位/冻结位的源向量）
**输出**：`x`（N×1，编码后码字）

## Purpose
极化编码：`x = u·G_N (mod 2)`。

## Math / Algorithm
- 取 `GN = get_GN(N)`，计算 `Y = u'·GN`，`x = mod(Y', 2)`。

## Numerical Notes
- ⚠️ 经由稠密矩阵乘法，O(N²)；与 `get_GN` 同样在大码长下有性能隐患。

## Dependencies
- l3_get_GN

## Health
healthy
