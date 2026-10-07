# L3 — `test_unit0_finite_noise_llr`

- **检查**：在sigma=0.45、非均匀energy-lambda先验及星座点/非星座接收样本下，将稳定LSE latent LLR与独立直接星座枚举参考比较。
- **覆盖**：8/16/32/64QAM全部latent bit-level，误差阈值`1e-11`。
- **健康度**：全M PASS（2026-09-03，MATLAB）。
