# L3 · llr_gray_qam_latent_lse

- **method_id**: l3_v3_llr_gray_qam_latent_lse
- **file_path**: 16QAM_Polar/v3/modulation/llr_gray_qam_latent_lse.m
- **module**: v3 modulation
- **health**: finite-noise-reference-pass

## Math
输出 `log Σ_{z_k=0}P_X(x)e^{-d}/Σ_{z_k=1}P_X(x)e^{-d}`，而非从 Gray label LLR 逆推 relation 前的 latent LLR。

## Numerical Notes
使用 log-sum-exp；`sigma` 是每实维标准差。

## Evidence

2026-09-03：8/16/32/64QAM在非均匀energy-lambda先验、`sigma=0.45`下与独立直接星座枚举参考误差≤`1e-11`。
