# L3 · llr_16qam_gray_LSE_prior

- **method_id**: l3_llr_16qam_gray_LSE_prior
- **file_path**: 16QAM_Polar/v2/modulation/llr_16qam_gray_LSE_prior.m
- **module**: modulation
- **health**: healthy

## Signature
**输入**：`y`（接收复符号）、`sigma`（每实维噪声标准差）、`psym`（长度 16 的星座先验概率，自动归一化）
**输出**：`LLR`（4·length(y) × 1）

## Purpose
带**符号级非均匀先验**的精确 MAP 逐比特 LLR，是 l3_llr_16qam_gray_LSE 的先验感知版本（用于概率整形的调制侧软解调）。

## Math / Algorithm
- `LLR_b = log(Σ_{s∈Sk0} P(s)·e^{-d(s)}) - log(Σ_{s∈Sk1} P(s)·e^{-d(s)})`
- 稳定实现 `LSE_logw_neg(a, logw) = tmax + log(Σ exp((logw-a) - tmax))`，`logw = log(max(psym, realmin))`。
- `psym(m)` 对应符号索引 (m-1)，先归一化为概率。

## Numerical Notes
- ⚠️ `psym` 必须非负、至少一个正项，长度恰为 16，否则报错。
- ⚠️ 用 `log(max(psym, realmin))` 防 `log(0)`；log-sum-exp 防溢出。

## Dependencies
无（自带 LSE_logw_neg 子函数）

## Health
healthy
