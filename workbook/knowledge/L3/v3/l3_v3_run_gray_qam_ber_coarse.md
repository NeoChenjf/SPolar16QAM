# L3 — `run_gray_qam_ber_coarse`

- **入口**：`summary = run_gray_qam_ber_coarse()`；推荐通过`run_gray_qam('ber_coarse')`调用。
- **定义**：对4种M、3个lambda和`0:2:18 dB`运行有限SNR SC链路，输出BER/BLER、聚合及逐流errors、frames、码率、Goodput和RF能量代理。
- **窗口规则**：BER在`1e-4~1e-1`为候选；至少20错误标为较稳定候选，否则标稀疏候选；无候选不静默扩大结论。
- **恢复能力**：每完成一个M/lambda块写partial CSV和checkpoint；完整产物含CSV/MAT/README/log/PNG/PDF/FIG。
- **健康度**：coarse-pass（`20260903_160356_ber_coarse`）；每组仅1个候选点，需局部加密。
