# L3 · 125候选三路实验入口

- method_id为l3_run_information_frontier_main。
- file_path为16QAM_Polar/v2/diagnostics/run_information_frontier_main.m。
- module为analysis，health为degraded：本批正在运行，独立正确性与完整适用域尚待最终审查。

## Signature

run_information_frontier_main(out,phase)，phase为prepare、predict或simulate，out为本批结果目录。simulate会产生新增通信帧，必须具有有效授权。

## Purpose

统一冻结并运行五档p、125组候选在多H/噪声下的简单分数、显式SC和完整通信对照，保存RF与非线性分析所需帧级矩。

## Math / Algorithm

输入分布从历史训练直方图计算并校验I/S/F；每条件预测15个组/p，再用实际K加权组合。测试帧候选间共享payload/noise。空口噪声以N0为时域复数噪声功率，均衡后每实维标准差 $\sqrt{64N_0/2}/|H_k|$。每候选共三组，累计I错误和位数，输出L4/L8包络二/四阶矩。

## Numerical Notes

有限PMF、粒子和求积近似；H极小值数值敏感。三条路径共享真实H与映射；RF/二极管统计是同一测试波形的共享值。absolute deadline、预算预记和断点用于本批，时间常量失效后不可直接重跑。

## Dependencies

l3_information_score_quadrature、l3_p1_predict_minsum、l3_p2_prepare_state、l3_p2_transmit_block、l3_p2_decode_block、l3_ofdm_common_noise_roundtrip、l3_ofdm_oversampled_channel、l3_rf_envelope_moments。
