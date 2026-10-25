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

## 2026-10-09 构造契约追加

新版本为`source_entropy_S_GA_IF`：每一路保持原K和S数量；固定源熵估计选择S；每个通信SNR在剩余位置重新GA排序选I/F；逐帧按payload和F=0调用v3精确源SC强制构造。源熵估计seed与评价seed必须分离。接收端仍是现有SC/LLR契约，不能将source precoder准确性等同于接收度量匹配。正式PMF门禁和码长对照见本轮时间戳结果；本次不更新最优性能结论。


## 2026-10-09 Formal source-entropy protocol extension

The same entry supports pilot and formal operation. Formal source-entropy runs keep 64 subcarriers, CP=16, 3 reliability groups, N=1024 per group, and the six historical strategies; S is fixed by source conditional entropy and I/F are reselected by channel GA per SNR, with message-conditioned shaping per payload. The training split uses seed42 and 30 channel realizations after pilot freezes the waterfall grid. Independent evaluations use seeds1042 and2042 on the frozen grid and do not retune policy. All full-chain runs remain long and require explicit user authorization; this round has authorization for necessary runs. The source construction change is not an equal-power comparison and cannot establish RF-DC conversion gain.


## 2026-10-09 纯能量基线语义修正（待smoke验收）

代码审计发现，旧版bad_channel_energy_only虽然把low组排除在BER/Goodput分母外，却仍为该组随机生成信息位并发射，故旧图中的“纯能量”名称与载荷不一致。新版本仅对low组固定零payload，仍使用该组p=.1、原S/I/F构造和消息条件化整形；该组不计为信息子载波。加入零payload断言后再进行B4 pilot/正式运行。历史B4数据保留，但只代表旧定义，不能与修正版本直接合并或作同一baseline结论。


## 2026-10-09 Baseline semantics and resume integrity

The bad_channel_energy_only strategy now fixes all four low-group payloads to zero and exports per-group payload one-counts; only high/mid groups contribute communication statistics. The formal runner saves params.mat and refuses resume unless parameters, source SHA-256 manifest, and source snapshot all match the original run. Older B4 results/partial files use the historical random-low-payload definition and are not resumable into this protocol.

## 2026-10-09 source-entropy正式训练证据

source-entropy正式训练`results/20261009_203109_b4_source_entropy_formal/`通过1080行重复键、36策略/SNR汇总、1920信道行、2160 START/DONE事件及指标恒等式审计；30实现、六SNR、六策略，CP16、3组N1024。low组纯能量payload逐行计数为0。训练分析和F10–F15图位于`results/20261009_210714_b4b_source_entropy_training_policy_analysis/`。实际帧数按5–50帧自适应，README已更正旧版显示的默认num_frames误导。

## 2026-10-09 pipeline references and outcome

- Run/construction: `l3_run_b4_strict_ofdm_rayleigh_validation`, `l3_build_source_entropy_partition`, `l3_sim_shaped_polar_16qam`.
- Data audit: `l3_verify_b4b_strict_smoke`; it asserts all-zero low-group payload for the pure-energy strategy.
- Results: source-entropy training seed42, independent policy holdout seed1042, and frozen guardband validation seed2042 all completed 30 realizations and strict audits. Each produced 1080 repetitions; see the timestamped directories in this contract's appended execution report and the Stage B report.
