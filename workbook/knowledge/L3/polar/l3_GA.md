# L3 · GA

- **method_id**: l3_GA
- **file_path**: 16QAM_Polar/v2/polar/GA.m
- **module**: polar
- **health**: healthy

## Signature
**输入**：`sigma`（每实维噪声标准差）、`N`（码长，2 的幂）
**输出**：`u`（1×N，各虚拟信道的 LLR 均值期望，已 bitrevorder）

## Purpose
高斯近似（Gaussian Approximation）估计极化后各虚拟信道的可靠性，用于 S/I/F 集合排序。

## Math / Algorithm
- 初始：`u(1) = 2/sigma^2`（AWGN-BPSK 信道 LLR 均值）。
- 蝶形递推 log2(N) 层：上支 `u_k ← phi^{-1}(1-(1-phi(u_k))^2)`（校验节点合并），下支 `u_{k+j} ← 2·u_k`（变量节点）。
- 末尾 `bitrevorder` 还原自然序。
- 可靠性越大 → 该信道越适合放信息位/整形位。

## Numerical Notes
- ⚠️ 依赖 `phi` / `phi_inverse` 的分段闭式近似，极端 SNR 下有近似误差（高斯近似固有）。

## Dependencies
- l3_phi, l3_phi_inverse

## Health
healthy
