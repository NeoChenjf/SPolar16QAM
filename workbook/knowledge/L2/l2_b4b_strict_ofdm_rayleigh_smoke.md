# L2 · run_b4_strict_ofdm_rayleigh_validation（Stage B / B4b）

- **flow_id**: l2_b4b_strict_ofdm_rayleigh_smoke
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **runtime**: smoke约数秒；两轮受限pilot计算20.4秒与15.3秒
- **needs_user_run**: false（smoke/pilot）/ true（后续正式长仿真）
- **validates**: l1_multicarrier_ofdm#H2 的严格物理链路前置条件；不验证最终策略最优性

## Purpose

把B3 proxy和B4a加权分组近似推进到真实OFDM-Rayleigh物理链路。high/mid/low各使用一套`N=1024` polar块，共同映射到64子载波时频网格，经过IFFT、CP、16-tap Rayleigh、AWGN、去CP、FFT、ZF、逐子载波方差LLR和SC译码。

## Pipeline

| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 预计算p/SNR对应polar状态 | l3_sim_shaped_polar_16qam | 复用S/I/F、GA和SC口径 |
| 2 | 生成三组独立polar/QAM块 | l3_sim_shaped_polar_16qam | energy-only组仍发送真实p=0.1波形但payload=0 |
| 3 | 分组装入共同OFDM网格 | 脚本内layout契约 | 49个OFDM符号；padding mask显式计入Goodput分母 |
| 4 | 时域OFDM-Rayleigh链路 | l3_ofdm_channel_roundtrip | 连续卷积、公共噪声、ZF与深衰落保护 |
| 5 | 逐子载波LLR与SC译码 | l3_llr_16qam_gray_LSE | sigma为每个均衡后符号的实维噪声标准差 |
| 6 | BER/Goodput/能量统计 | 脚本指标契约 | CP+padding修正；加噪前接收信号均方为主能量代理 |
| 7 | 输出与审计 | verify_b4b_strict_smoke | CSV/MAT/日志/四图/audit |

## Smoke Inputs

- `snr_grid=[8 14 20]`
- `num_realizations=2`
- `num_frames=1`
- `Nsc=64`、`CP=16`、`channel_taps=16`、seed=42
- 六策略：三个统一p、好信道偏信息、好信道偏能量、差信道纯能量

## Pilot Evidence

- 入口只允许有上限的`smoke`或`pilot`，拒绝`formal`；pilot最多4个SNR、5个realization、每点2帧。
- 第一轮：`[20,24,28,32] dB`，目录`results/20260917_194823_b4_strict_ofdm_rayleigh_pilot/`。
- 第二轮：`[32,36,40] dB`，目录`results/20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr/`。
- 推荐正式网格`[20,24,28,32,36,40] dB`；它是pilot的预登记推断，不是正式结果。

## Formal Readiness

- `formal`模式只有收到`formal_authorized=true`才会启动；未授权路径已测试为拒绝。
- 每完成一个`strategy × realization × SNR`重复即重写`b4b_repetition_partial.csv`；传入已有`resume_dir`会跳过已完成键并追加进度日志。
- 正式停止规则：每重复至少`min_frames=5`，达到`target_errors=200`后停止，或在`max_frames=50`强制停止。
- 汇总表为累计零错误的策略/SNR点提供`ber_zero_error_upper95=-log(0.05)/N_bits`，不把有限样本零错解释为真实BER为零。
- 1 SNR × 1 realization × 1帧的formal控制路径测试已实际写入6条partial记录；同目录resume后6条键均被跳过，独立审计PASS：`results/20260917_205835_b4_strict_ofdm_rayleigh_formal_controlpath_test/`。

## Outputs

- `results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/`
- repetition/summary/channel CSV、MAT、README、run/progress log、audit
- BER、Goodput、接收能量、20 dB tradeoff图的PNG/PDF/FIG

## Acceptance

- 36个strategy/realization/SNR键唯一且START/DONE完整。
- 信道表含2×64行，high/mid/low计数分别22/21/21。
- rate、Goodput、padding和信息子载波比例恒等式通过。
- 不含NaN/Inf；49个OFDM符号，padding=2.0408%。
- smoke只验证链路、量级与产物，不用于最终排序或论文级Pareto。

## Weekly Report

- 周报/阶段B/B4：full-chain策略验证.md
