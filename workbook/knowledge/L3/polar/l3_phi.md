# L3 · phi

- **method_id**: l3_phi
- **file_path**: 16QAM_Polar/v2/polar/phi.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`x`（标量，LLR 均值）
**输出**：`y = phi(x)`

## Purpose
高斯近似中的 φ 函数：刻画 LLR 期望经校验节点运算后的演化，供 `GA` 调用。

## Math / Algorithm
分段闭式近似：
- `0 ≤ x ≤ 10`：`y = exp(-0.4527·x^0.859 + 0.0218)`
- `x > 10`：`y = sqrt(pi/x)·exp(-x/4)·(1 - 10/(7x))`

## Numerical Notes
- 分段拼接点在 x=10 附近连续但非光滑；属标准 GA 近似（Trifonov / Chung 等文献口径）。

## Dependencies
无

## Health
healthy
