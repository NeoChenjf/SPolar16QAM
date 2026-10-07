# L3 — `run_gray_qam_energy_smoke`

- **入口**：`summary = run_gray_qam_energy_smoke()`；推荐从 `run_gray_qam('energy_smoke')` 调用。
- **配置**：M=8/16/32/64，lambda=0/0.25/0.5，N=256，40帧，source-MC样本120，fixed_n0，120 dB，seed=20260902。
- **统计**：target/model/empirical三份PMF；经验PMF cluster-bootstrap；相邻能量逐帧配对bootstrap；同时保存R_code/R_bpcu。
- **容错产物**：每点更新partial CSV、checkpoint、progress log；完成后保存summary/difference CSV、MAT、README和PNG/PDF/FIG。
- **健康度**：smoke-pass（2026-09-02，结果`20260902_224303_energy_lambda_smoke`，overall_pass=1）。
