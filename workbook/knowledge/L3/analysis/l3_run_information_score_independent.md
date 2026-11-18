# L3 · 信息分数独立验证入口

- method_id为l3_run_information_score_independent。
- file_path为16QAM_Polar/v2/diagnostics/run_information_score_independent.m。
- module为analysis。
- signature为run_information_score_independent(out)，out是新结果目录。
- health为degraded，科研近似仍待独立评价，运行数据不构成全域证明。

## Purpose

冻结训练PMF与指标后比较3候选在8新信道、2噪声条件下的生产SC信息性能。

## Math / Algorithm

指标为实际16点PMF下的固定s=1位度量广义互信息表达式积分，求和后除4×49×80。分数不输出BER。复噪声每实维标准差sqrt(64N0/2)/abs(H)。SC中I/S自由、F已知，只计I错误。Goodput为(K−错误)/(4×49×80)。

## Numerical Notes

40/80阶Gauss–Hermite对照；log-sum-exp；PMF由独立历史40帧估计，位置池化；不包括完整联合码字分布。绝对通信截止及2400帧预算在生成前检查。

## Dependencies

l3_p2_prepare_state、l3_p2_transmit_block、l3_ofdm_common_noise_roundtrip、l3_p2_decode_block；MATLAB qammod/de2bi、线性代数和文件I/O。
