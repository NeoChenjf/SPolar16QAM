# L3 · 125候选前沿图

- method_id为l3_plot_information_frontier_main。
- file_path为16QAM_Polar/v2/analysis/plot_information_frontier_main.m。
- module为analysis，health为degraded：图的解释与完整结果待最终核验。

## Signature

plot_information_frontier_main(out)读取完整条件的分析表，输出PNG和PDF。

## Math / Algorithm

在随机H条件中选简单分数平均经验损失最大的案例，显示125点、共同RF轴及三条前沿；右图显示每条件7750候选对的两种点排序反向比例。诊断H不混入随机H图。

## Numerical Notes

前沿坐标的能量来自同一测试波形，点估计本身未展示联合置信区间；图仅限定所搜候选。

## Dependencies

MATLAB table/plot，输入为l3_analyze_information_frontier_main输出。
