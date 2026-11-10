# L2 · run_p2_v2_strategy_report

- **flow_id**: l2_run_p2_v2_strategy_report
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_v2_strategy_report.m
- **runtime**: minutes
- **needs_user_run**: false（长跑仅在用户明确授权预算内由 agent 执行）
- **validates**: l1_multicarrier_ofdm#H2（限定本次候选和模型，不能泛化最优）

## Purpose
汇总独立测试、基线配对差、条件/总达标率和三种假设标尺。

## Pipeline
调用既有 MATLAB 编码、信道或结果分析链；相关方法契约：l3_p2_paired_channel_bootstrap。具体参数、随机角色及运行状态以输出 `params.mat`、源码快照和阶段报告为准。

## Inputs / Outputs
输入为调用参数或新批次结果路径；产出存于新时间戳 `results/` 目录或对应批次目录，包括参数、原始数据及适用的表和图。

## Acceptance
固定星座幅度和物理噪声；比较点共享h/n；按实际I/K及含CP资源计数；训练与测试分离。对照三类基线后方可讨论限定范围的策略表现。能量为假设非线性代理，不等同实测DC。长期统计结论以实际样本、误码分母和阶段报告为准。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md
