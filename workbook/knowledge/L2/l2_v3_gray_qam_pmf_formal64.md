# L2 · v3 64QAM正式PMF补充门禁

- **flow_id**：`l2_v3_gray_qam_pmf_formal64`
- **entry**：`summary = run_gray_qam('pmf_formal64')`
- **runtime**：long
- **needs_user_run**：true

## 目的

只重跑尚未达到正式经验PMF阈值的64QAM三个energy-lambda点；8/16/32QAM已在`20260902_224303_energy_lambda_smoke`达到TV上界≤0.05，不重复消耗算力。

## 配置

- M=64，lambda=0/0.25/0.5，N=1024，80帧。
- source-MC样本200，source/runtime seed=20260904。
- fixed_n0、120 dB近似无噪声；2000次独立帧cluster bootstrap。

## 验收

每点target→model状态不得为fail，且经验PMF TV的单侧95%上界≤0.05。产物含逐点三份PMF、partial/checkpoint、CSV/MAT/README/log及PNG/PDF/FIG。

## 健康度

PASS（2026-09-03，`20260903_221630_pmf_formal64`）：lambda=0/0.25/0.5的帧级bootstrap TV上界为0.01877/0.02680/0.03310，三个`formal_pass`及`overall_pass`均为1。
