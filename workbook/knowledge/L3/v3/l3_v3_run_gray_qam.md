# L3 — `run_gray_qam`

- **入口**：`summary = run_gray_qam(mode)`；支持默认`pmf_smoke`、`energy_smoke`、`ber_coarse`、`ber_refine`和`pmf_formal64`。
- **默认任务**：对8/16/32/64QAM，N=256、40独立帧、source-MC构造样本120、120dB近似无噪声，统计真实发送符号PMF与模型PMF的cluster-bootstrap TV，并保存CSV/MAT/README/PNG到时间戳results目录。
- **边界**：这是PMF smoke，不是BER扫描，不应据其得出有限SNR BER或能量单调性结论。编码构造仍为GA approximate。
- **健康度**：PMF-smoke-pass（2026-08-30，全M TV upper95均≤0.10）；尚非正式PMF/BER/能量门禁。
