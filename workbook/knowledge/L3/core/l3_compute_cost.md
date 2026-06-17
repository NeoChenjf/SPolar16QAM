# L3 · compute_cost

- **method_id**: l3_compute_cost
- **file_path**: 16QAM_Polar/v2/core/compute_cost.m
- **module**: core
- **health**: healthy

## Signature
**输入**：`G`（当前 Goodput）、`E`（当前能量）、`G0`（基线 Goodput, p=0.5）、`E0`（基线能量, p=0.5）
**输出**：`cost`（代价值，仅 `E > E0` 时有意义，其余为 NaN）

## Purpose
计算能量-信息代价函数：单位能量增益带来的信息损失（越小越好）。

## Math / Algorithm
`cost(p) = -(G(p) - G(p0)) / (E(p) - E(p0))`，仅在 `dE = E - E0 > 0` 处有定义。

## Numerical Notes
- `dE ≤ 0` 的点置 NaN，避免除零与无意义符号。

## Dependencies
- 消费 l3_compute_goodput、l3_compute_energy 的输出。

## Health
healthy
