# L2 · run_p2_v2_sensitivity_report

- **flow_id**: l2_run_p2_v2_sensitivity_report
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_v2_sensitivity_report.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: l1_multicarrier_ofdm#H2（只提供模型假设下的辅助比较）

## Purpose / Pipeline
从独立测试的二、四阶矩和冻结训练参考计算三种全局标尺的二阶、四阶及总电流代理，生成独立时间戳结果。相关契约：l3_rectifier_proxy_from_moments。

## Inputs / Outputs
读取冻结训练参数与测试汇总表；输出参数MAT、分量CSV、PNG/PDF和README，不产生新仿真帧。

## Acceptance
各场景使用一个全局标尺，不逐候选归一；明确示例系数、50欧姆、理想插值和非实测DC/效率的限制。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md
