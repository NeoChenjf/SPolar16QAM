# L3 — `run_gray_qam_pmf_formal64`

- **入口**：`summary = run_gray_qam_pmf_formal64()`；推荐通过`run_gray_qam('pmf_formal64')`调用。
- **配置**：64QAM、lambda=0/0.25/0.5、N=1024、80帧、source-MC样本200、2000次frame bootstrap。
- **门禁**：每点target-model非fail且经验PMF TV上界≤0.05。
- **恢复能力**：每点写partial CSV/checkpoint；完整输出三份PMF、CSV/MAT/README/log和PNG/PDF/FIG。
- **健康度**：PASS（2026-09-03，`20260903_221630_pmf_formal64`）；三个lambda点TV上界为0.01877/0.02680/0.03310，`overall_pass=1`。
