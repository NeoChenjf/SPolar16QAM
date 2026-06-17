# L3 · phi_inverse

- **method_id**: l3_phi_inverse
- **file_path**: 16QAM_Polar/v2/polar/phi_inverse.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`y`（标量）
**输出**：`x = phi^{-1}(y)`

## Purpose
φ 函数的反函数，供 `GA` 蝶形递推的上支使用。

## Math / Algorithm
- 闭式区间 `0.0388 ≤ y ≤ 1.0221`：`x = ((0.0218 - ln y)/0.4527)^(1/0.86)`
- 区间外：以 `x0 = 0.0388` 为初值的 **Newton 迭代** 求根：`x_{k+1} = x_k - (phi(x_k)-y)/phi'(x_k)`，
  收敛判据 `|Δx| < epsilon`（默认 1e-3）。

## Numerical Notes
- ⚠️ 当迭代值 `x1 > 1e2` 时把 `epsilon` 放宽到 10，避免大 x 区域不收敛 / 死循环（源码内置的自适应放宽）。
- 反函数数值在 y 极端值附近敏感，依赖 `derivative_phi` 的精度。

## Dependencies
- l3_phi, l3_derivative_phi

## Health
healthy
