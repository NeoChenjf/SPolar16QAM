# L3 · analyze_information_certified_frontier

- **method_id**: l3_analyze_information_certified_frontier
- **file_path**: 16QAM_Polar/v2/analysis/analyze_information_certified_frontier.m
- **module**: analysis
- **health**: degraded — 新分析入口，独立数据待产生；不代表方法通过。

## Signature
`analyze_information_certified_frontier(out)`，out为含frozen.mat及已完成condition MAT的结果目录。输出17位CSV、MAT、PNG/PDF。

## Purpose
以三方法停止后生成的独立评价帧描述成本、信息损失、能量收益、排序和认证成员。

## Math / Algorithm
$G=(K-E_I)/15680$，损失$1-\bar G_c/\bar G_{125}$。独立100帧配对bootstrap2000次给固定策略损失描述区间；RF与四阶二极管代理沿用冻结尺度。枚举7750候选对点反序，125候选非支配成员及认证子集的样本内前沿。原始SC预测与有限细化集合另列。

## Numerical Notes
帧bootstrap不等于认证界、同时覆盖或跨H保证。评价点损失超过5%不单独证明认证失效。诊断H单列；前沿是有限样本点集合，非true Pareto。能量坐标不等于实测DC。输入分布/模型相关性误差及不同调度近似限制因果解释；方法差异不能全部归因于显式SC。

## Dependencies
无外部项目函数（本地pointfront、writecsv及MATLAB内置统计绘图）。

## Health
只分析完成文件，数据缺失不能填成功；独立评价数据不得用于调参、认证或重选。阶段末尾追加真实运行证据。


## 2026-11-18 实际验证补充

测试/分析已执行；仅1完整独立H条件，不将公式测试当科研验收。详见loop本轮报告末尾；整体健康度保持degraded。
