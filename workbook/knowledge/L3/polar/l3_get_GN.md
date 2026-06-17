# L3 · get_GN

- **method_id**: l3_get_GN
- **file_path**: 16QAM_Polar/v2/polar/get_GN.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`N`（码长，2 的幂）
**输出**：`FN`（N×N 极化生成矩阵）

## Purpose
构造极化码生成矩阵 G_N（Arikan 核的 Kronecker 幂）。

## Math / Algorithm
- 核 `F = [1 0; 1 1]`。
- `F_N = F^{⊗ log2(N)}`，源码用迭代 Kronecker：`FN(1:2^i,1:2^i) = kron(FN(1:2^{i-1},1:2^{i-1}), F)`。
- 注意：此实现**不含**比特反转置换（直接 Kronecker 幂），与编码 `x = u·G_N (mod 2)` 配套。

## Numerical Notes
- ⚠️ 显式构造 N×N 稠密矩阵，N 较大时内存/速度开销大（O(N²)）；大码长应改用蝶形递推编码。

## Dependencies
无

## Health
healthy — 小码长可用；大码长有性能隐患（见 Numerical Notes）。
