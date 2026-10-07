# L3 — `sim_shaped_polar_gray_qam`

- **签名**：`result = sim_shaped_polar_gray_qam(M,shaping_spec,snr_dB,cfg)`
- **当前契约**：接受 `source='latent_p'` 和 `source='energy_lambda'`，以每 latent bit 一条 N 长 polar 流构建单载波 Gray-QAM；后者先把能量目标拟合为每轴 latent模型，并把真实target/model KL/TV写入结果。完整星座 MAP/LSE demapper输出 latent LLR，接收端仅冻结 F，BER/BLER/Goodput 只统计 I。
- **SNR**：`fixed_n0: sigma^2=1/(2*10^(SNR/10))`；`fixed_esn0` 以 model Es 替换 1。
- **边界**：当前主流程使用source-MC构造S、GA划分I/F；它是数值近似，不能作为论文单整体polar graph的严格有限长构造结论。
- **诊断选项**：`cfg.force_nonzero_payload=true` 仅用于环回测试，强制每个非空 payload 的首位为 1，不能用于统计实验。
- **维度契约**：`K/S_size/F_size`均为`m×1`；`frames`为`1×nSNR`，故`K*frames`为逐流逐SNR总比特数矩阵。
- **随机性契约**：`cfg.seed`控制payload/AWGN；可选`cfg.source_mc_seed`单独冻结source-MC构造。source构造函数必须恢复调用者RNG状态，避免离线设计污染运行随机流。
- **健康度**：latent-p PMF smoke已通过；energy-lambda等待用户运行。
