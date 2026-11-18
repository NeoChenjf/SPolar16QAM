# L2 · 信息分数冻结独立验证

- flow_id为l2_run_information_score_independent。
- entry_script为16QAM_Polar/v2/diagnostics/run_information_score_independent.m。
- runtime为minutes，needs_user_run为true。本次2026-11-11用户已明确授权2400 case帧、60分钟、500 MiB，0无编码符号，授权不跨批继承。

## Purpose

验证实际位度量信息分数能否预测三个固定候选的SC Goodput排序。无经验BER校准，无预设科学通过线。

## Pipeline

1. 从20261107训练资产读取40帧星座直方图和实际模板，核对测试I/S/F。
2. 生成8个新16抽头瑞利H；强22、中21、弱21载波，组内1024符号。
3. 固定s=1，以40/80阶求积计算预测并保存，之后才生成独立通信帧。
4. l3_p2_transmit_block，l3_ofdm_common_noise_roundtrip，l3_p2_decode_block调用生产SC完成测试。
5. analyze_information_score_independent按整帧配对bootstrap，输出候选计数、分数、选择损失和图。

## Inputs

N1024，Gray16QAM，固定幅度1，CP16，标签20/28，每格50帧。候选为全p=.5、(.3,.1,.1)、(.1,.1,.3)。训练PMF与测试消息分离，按组池化。噪声按真实N0计算。

## Outputs

results/20261111_231803_information_score_independent保存参数、冻结预测、channels/states/PMF、逐帧四路错误与I分母、预算检查点、CSV和PNG/PDF。

## Acceptance

2400case帧/7200组记录完整性，实际I分母，50帧配对区间，求积阶数排序敏感性，域限及失败样例；不把可达信息分数当BER或绝对Goodput。跨H以信道为统计单位。参见workbook/mandatory-rules.md。

## Weekly Report

周报/阶段B/B4：full-chain策略验证.md。
