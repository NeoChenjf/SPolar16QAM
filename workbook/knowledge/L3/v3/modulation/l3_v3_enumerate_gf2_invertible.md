# L3 · enumerate_gf2_invertible

- **method_id**: l3_v3_enumerate_gf2_invertible
- **file_path**: 16QAM_Polar/v3/modulation/enumerate_gf2_invertible.m
- **module**: v3 modulation
- **health**: partial-smoke-pass

## Purpose
枚举 `GL(k,2)`，首版限制 `k≤3`；预期数量为 1、6、168，用于 auto relation 搜索。

## Numeric contract
`bitget` 的中间结果是整数类型，但所有候选矩阵在返回前统一转换为 `double`，避免 MATLAB 禁止 `uint16 * double` 的矩阵乘法；元素仍严格为 0/1。
