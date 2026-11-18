# L2 · 五档成形信息预测与前沿主实验

- flow_id为l2_run_information_frontier_main。
- entry_script为16QAM_Polar/v2/diagnostics/run_information_frontier_main.m。
- runtime为long，needs_user_run为true。2026-11-12用户授权本批代理运行；授权不继承至其他批次。
- validates为l1_polar_coding和l1_metrics_tradeoff的信息预测与候选取舍；不声明L1假设已通过。

## Purpose

对同一批125候选比较简单位度量分数、显式SC数值预测和完整通信的Goodput排序、选择损失及RF/非线性候选前沿。

## Pipeline

1. prepare从历史40帧计数得到五档PMF，核对四噪声条件的I/S/F并冻结H、映射、种子和参数。
2. predict调用l3_information_score_quadrature和l3_p1_predict_minsum；每组五档预测复用到125组合，按I权重合成BER/Goodput。
3. simulate调用l3_p2_transmit_block、l3_ofdm_common_noise_roundtrip、l3_p2_decode_block；候选间共用独立帧payload/noise。通信前保存本条件预测。
4. l3_ofdm_oversampled_channel和l3_rf_envelope_moments记录无噪声L4/L8接收包络矩。
5. analyze_information_frontier_main生成候选、成对排序、前沿与配对选择损失；plot_information_frontier_main绘图。

## Inputs

N1024，16QAM，固定公共幅度，三个资源组各p=[.1,.2,.3,.4,.5]，8随机16抽头H、三个预定义诊断H，标签16/20/24/28，50配对帧。F已知、I/S自由、仅I计误码。详细参数、seed与二极管假设见输出protocol.json。

## Outputs

results/20261112_150949_information_frontier_main/：冻结资产、逐条件预测、逐帧错误和包络矩、预算检查点、分析CSV、图及最终报告。重跑入口会生成新通信帧，需新的明确预算。

## Acceptance

完整矩阵、分母与资源核对；先看BER瀑布区和设计K上限；报告配对损失、区间与边界样例。前沿限定125候选；能量使用同一组实际波形统计，不构成能量模型独立预测验证。低阶二极管代理不能称实测直流功率。无预设成功阈值。

## Weekly Report

周报/阶段B/B4：full-chain策略验证.md。
