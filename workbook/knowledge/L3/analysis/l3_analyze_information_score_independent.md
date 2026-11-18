# L3 · analyze_information_score_independent

- method_id为l3_analyze_information_score_independent。
- file_path为16QAM_Polar/v2/diagnostics/analyze_information_score_independent.m。
- module为analysis。
- signature为analyze_information_score_independent(out)。
- health为healthy，仅实现限定域统计口径。

## Purpose

读取冻结独立数据，生成帧配对Goodput、排序和选择损失及图表。

## Math / Algorithm

Goodput=(K−I错误)/(4×49×80)，2000次整帧配对bootstrap；预测分数来自冻结文件，不用测试BER拟合。

## Numerical Notes

50帧区间不含PMF训练误差；零事件不能作零概率；最优是已搜索候选集合的经验最优。

## Dependencies

MATLAB readmatrix、prctile、绘图和文件I/O。
