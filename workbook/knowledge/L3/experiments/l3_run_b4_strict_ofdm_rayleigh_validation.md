# L3 · run_b4_strict_ofdm_rayleigh_validation

- **method_id**: l3_run_b4_strict_ofdm_rayleigh_validation
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **module**: experiments/multicarrier
- **health**: healthy; formal mode is authorization-gated and checkpointed.

## Signature
Script entry; use workspace-local `b4_strict_overrides` for run mode, tag, seed, SNR grid, realization/frame budgets, `formal_authorized`, resume directory, and strategy list.

## Purpose / algorithm
Construct four source-S templates using fixed K and |S|, source conditional entropy with source seed9001/200 words; for each p and SNR choose channel-GA I from the remainder and F as the residual set. For every frame, condition shaping on current payload and F=0, then run grouped polar OFDM IFFT/CP/multipath/AWGN/FFT/ZF/LLR/SC. Energy-only strategy uses all-zero payload on low-reliability group; high/mid groups remain data-bearing. Formal repetition budget stops after at least 5 frames and 200 errors or at max 50 frames.

## Outputs / acceptance
Timestamped `results/` with params, source snapshot and hashes, repetition checkpoint/results, strategy summary, channel data, log, README and PNG/PDF/FIG. Acceptance via `l3_verify_b4b_strict_smoke`; SNR means fixed Es/N0 noise convention, not equal-power comparison. BER zero observations use the saved finite-sample upper bound.

## Dependencies
`l3_build_source_entropy_partition`, `l3_sim_shaped_polar_16qam`, `l3_verify_b4b_strict_smoke`.

## Validation
Smoke/pilot evidence frozen in this task plus three formal 30-realization seeds 42/1042/2042; all pass 1080-row strict audit. Actual experiment is long and requires explicit user authorization.


## 2026-10-10 追加：固定平均发射功率P1模式

新增配置通过局部`b4_strict_overrides`传入全局策略幅度系数、目标时域功率及`power_mode='equal_time_power'`。发送网格缩放后按同一系数计算TX平均功率；复噪声功率固定为目标功率除以线性SNR，接收均衡器与LLR使用真实ZF后噪声标准差，并将同一TX幅度尺度传入Gray 16QAM LLR星座。formal等功率模式固定运行`max_frames`，仍逐策略/信道/SNR保存checkpoint。旧`legacy`模式保持原行为。

Revision metadata: revision_id=b4_runner_equal_power_20261010; current_status=current; supersedes=[baseline].

## 2026-10-10 修订：等功率噪声参数精确定义

`power_mode='equal_time_power'`中$N_0=P_{target}/10^{SNR/10}$是OFDM串行时域的复噪声样本功率。当前通道函数API接收FFT后每实维标准差，继而除以$\sqrt{N_{sc}}$生成时域噪声，因此调用处必须传$\sigma_{freq}=\sqrt{N_{sc}N_0/2}$；ZF后标准差继续按$|H_k|$缩放。修正不改变legacy模式。首版少传$\sqrt{N_{sc}}$的正式批次在36条重复后中止并标为无效；正确口径已由噪声功率测试和非单位幅度整链路smoke核对，正式新证据待运行完成。

Revision metadata: revision_id=b4_runner_noise_conversion_20261010; current_status=current; supersedes=[b4_runner_equal_power_20261010].


## 2026-10-11 P1正式运行验证

等功率模式的正式seed3142运行完成：30个独立信道×7个SNR×6策略×固定50帧，耗时约5858.6秒；1260条重复记录均有唯一键和固定帧数。校准系数由独立数据冻结，验证最后一轮各策略均值在目标±1%内；正式发射功率各策略均值亦在±1%内。SNR按目标时域发射功率除以时域复噪声功率定义，接收端按FFT/ZF噪声方差及发射幅度缩放传递至LLR。

正式版本源码哈希见正式结果目录`sha256_manifest.txt`；数据、检查点、日志与MAT文件均保留。首轮错误噪声换算批次因时域噪声低18.06 dB已标记无效，不纳入正式结果。最终分析证明存在通信-RF折中，不证明策略全局最优或DC输出增益。

Revision metadata: revision_id=b4_runner_equal_power_formal_20261011; current_status=current; supersedes=[b4_runner_noise_conversion_20261010].

## 2026-10-11 当前方法契约快照

- **method_id**: l3_run_b4_strict_ofdm_rayleigh_validation
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **health**: healthy; equal-power formal P1 completed and acceptance passed.

Revision metadata: revision_id=b4_runner_equal_power_contract_snapshot_20261011; current_status=current; supersedes=[b4_runner_equal_power_formal_20261011].
