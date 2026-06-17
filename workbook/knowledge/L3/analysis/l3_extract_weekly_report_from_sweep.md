# L3 · extract_weekly_report_from_sweep

- **method_id**: l3_extract_weekly_report_from_sweep
- **file_path**: 16QAM_Polar/v2/analysis/extract_weekly_report_from_sweep.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`result_dir`（含 `sweep_results.mat` 的结果目录）
**输出**：可粘贴到周报的 markdown 文件（写入 result_dir）

## Purpose
从 sweep 结果自动提取周报素材：每个 SNR 下的 Goodput 最优 p、Goodput-Energy Pareto 前沿点，输出 markdown。

## Math / Algorithm
可视化/汇总逻辑：加载 `sweep_results.mat`，按 SNR 找 Goodput 最大的 p，并计算 (E_norm, Goodput) 的 Pareto 前沿，格式化为周报表格。

## Numerical Notes
- 依赖 sweep 产物结构完整（params/seeds/BER/Goodput 矩阵）。

## Dependencies
- 消费 l2_run_sweep 的产物（sweep_results.mat）

## Health
healthy — 直接服务于项目"代码变更须更新周报"的硬规则。
