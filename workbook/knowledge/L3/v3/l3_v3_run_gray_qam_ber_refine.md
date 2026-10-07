# L3 — `run_gray_qam_ber_refine`

- **入口**：`summary = run_gray_qam_ber_refine()`；推荐通过`run_gray_qam('ber_refine')`调用。
- **输入口径**：M=8/16/32/64、lambda=0/0.25/0.5、各M coarse中心附近0.25 dB网格、fixed_n0。
- **重复策略**：固定`source_mc_seed`保持S/I/F不变，独立runtime seed改变payload/AWGN；至少3次、最多10次，每次30帧。
- **D门禁**：每个M/lambda至少2个点在`1e-4~1e-1`且各累计≥100错误。
- **产物**：重复表、聚合表、validation表、partial/checkpoint、MAT、README、log和三种图形格式。
- **健康度**：PASS（2026-09-03，`20260903_210444_ber_refine`，overall_pass=1）。
