# L3 · llr_16qam_gray_LSE

- **method_id**: l3_llr_16qam_gray_LSE
- **file_path**: 16QAM_Polar/v2/modulation/llr_16qam_gray_LSE.m
- **module**: modulation
- **health**: healthy

## Signature
**输入**：`y`（接收复符号向量）、`sigma`（每实维 I/Q 噪声标准差）
**输出**：`LLR`（4·length(y) × 1，比特 LLR，比特序同 `qammod` left-msb）

## Purpose
MATLAB Gray 16QAM 的**精确 MAP（log-sum-exp）逐比特 LLR**，均匀先验版本。与 `qammod(...,'gray','InputType','bit','UnitAveragePower',true)` 星座一致。

## Math / Algorithm
- 似然 `p(y|s) ∝ exp(-|y-s|²/(2σ²))`，`denom = 2σ²`。
- 距离度量 `d = |y - const|² / denom`（16 个星座点）。
- 逐比特 `LLR_b = LSE_neg(d over idx0) - LSE_neg(d over idx1)`，
  `LSE_neg(a) = -min(a) + log(Σ exp(-(a-min(a))))`（log-sum-exp 防溢出）。
- 星座与比特标签用 `persistent` 缓存，避免重复构造。

## Numerical Notes
- ⚠️ 关键在 `LSE_neg` 的 log-sum-exp 技巧防止 `exp(-d)` 下溢；这是数值稳定的精确 LLR。
- ⚠️ `sigma` 是**每实维**标准差，与主仿真噪声口径需对齐（见 l3_sim_shaped_polar_16qam 的 LLR 口径）。

## Dependencies
无（自带 LSE_neg 子函数；星座经 MATLAB `qammod` 构造）

## Health
healthy
