# L3 · derivative_phi

- **method_id**: l3_derivative_phi
- **file_path**: 16QAM_Polar/v2/polar/derivative_phi.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`x`（标量）
**输出**：`dx = phi'(x)`

## Purpose
φ 函数的导数，供 `phi_inverse` 的 Newton 迭代使用。

## Math / Algorithm
- `0 ≤ x ≤ 10`：`dx = -0.4527·0.86·x^(-0.14)·exp(-0.4527·x^0.86)`
- `x > 10`：`dx = exp(-x/4)·sqrt(pi/x)·(-1/(2x)·(1-10/(7x)) - 1/4·(1-10/(7x)) + 10/(7x²))`

## Numerical Notes
- 与 `phi` 同分段；`x→0` 时 `x^{-0.14}` 发散，Newton 初值取 0.0388 规避。

## Dependencies
无（与 phi 同口径，但不直接调用 phi）

## Health
healthy
