# L2 · run_single（单点快速测试）

- **flow_id**: l2_run_single
- **entry_script**: 16QAM_Polar/v2/run_single.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: l1_metrics_tradeoff#H1, l1_polar_coding#H1, l1_probabilistic_shaping#H1

## Purpose
对单个 p（默认 0.3）和少量 SNR（[0 5 10 15 20]）跑少帧仿真，**验证端到端链路正确性**（冒烟测试）。
快速确认编码→调制→信道→译码→指标全链路无误，再去跑长扫参。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 初始化路径与参数 | （setup_paths/config） | `cfg.num_frames=100`, `cfg.seed=42` |
| 2 | 端到端仿真 | l3_sim_shaped_polar_16qam | 内部含编码/调制/信道/译码/统计全链路 |
| 2.1 | GA 可靠性排序 | l3_GA | S/I/F 集合划分 |
| 2.2 | 极化编码（4 路） | l3_polar_encoder | — |
| 2.3 | 串并 + Gray 16QAM | l3_parallel_to_serial_bits | qammod |
| 2.4 | 软解调 LLR | （qamdemod 内联） | 噪声方差匹配口径 |
| 2.5 | SC 译码 | l3_SC_decoder | cfg.decoder='SC' |
| 3 | 指标计算 | l3_compute_goodput, l3_compute_energy | BER/Goodput/E |

## Inputs（config.m + 脚本覆盖）
- N=1024, M=16, p_fixed=[0.5,NaN,0.5,NaN]
- 覆盖：p_test=0.3, snr_test=[0 5 10 15 20], num_frames=100, seed=42, decoder='SC'

## Outputs
- 控制台逐 SNR 打印 BER / MI_total；快速验证用，通常不强制落 results/ 目录。

## Acceptance
- 链路无报错、BER 随 SNR 单调下降趋势合理。
- 读结果时聚焦 BER ∈ [1e-4,1e-1] 瀑布区；高 SNR 全零错误非异常（见 l1_metrics_tradeoff pitfalls）。

## Weekly Report
- 关联各阶段 `周报/` 验证记录。
