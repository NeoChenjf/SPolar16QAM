# L3 · 二极管指数模型回放诊断

- method_id为l3_audit_frontier_rectifier_diode。
- file_path为16QAM_Polar/v2/diagnostics/audit_frontier_rectifier_diode.m。
- module为analysis，health为degraded：探索性简化器件模型，需在首批诊断后验证。

## Signature

audit_frontier_rectifier_diode(out)要求原通信批次完成，从冻结种子恢复指定信号帧，输出diode_replay.csv。每个重生成的信号帧计入本批case帧预算，不生成独立无编码符号。

## Purpose

选取固定代表性H、标签和候选，检查二极管指数曲线与原四阶代理的差距及功率情景敏感性；不改变已冻结信息预测和前沿模型。

## Math / Algorithm

L8接收包络恢复后与原帧二阶/四阶矩逐一比对。对已知载波相位均值计算 $A=E[I_0(|v|/(nV_T))]$，与四阶矩代理比较；理想平滑输出和假定负载 $R_L=10\,\mathrm{k}\Omega$ 下二分求解 $I=I_s(Ae^{-R_LI/(nV_T)}-1)$，参考直流负载功率为$I^2R_L$。三种统一电压尺度对应−30/−25/−20 dBm训练基准假设。

## Numerical Notes

仅用于敏感性和有效性诊断；没有匹配网络、寄生电阻与结电容、电源背作用、纹波和实测电路标定，功率可违反能量守恒假设，须单独报告。原主实验仍使用固定零偏四阶代理，不将回放诊断当独立电路验证。

## Dependencies

l3_p2_transmit_block、l3_ofdm_oversampled_channel、l3_rf_envelope_moments；MATLAB besseli与二分求根。
