# L3 · 信息前沿分析

- method_id为l3_analyze_information_frontier_main。
- file_path为16QAM_Polar/v2/analysis/analyze_information_frontier_main.m。
- module为analysis，health为degraded：分析正在执行，未独立审查。

## Signature

analyze_information_frontier_main(out)只读取已完成条件的冻结预测与通信数据，输出候选、排序、RF与非线性前沿、能量门槛选择损失及bootstrap区间。

## Math / Algorithm

每帧Goodput为(K−I错误)/(4×49×80)。RF功率由包络二阶矩和参考电压/阻抗计算；二极管代理使用SMS7630二/四阶矩系数。每条件枚举125候选非支配点，以21个均匀能量要求评估共享能量轴下的选择损失。候选对点排序统计分别汇报一致、反向和平局。

## Numerical Notes

按50配对帧bootstrap，阈值和选中候选固定，区间不包括PMF训练与重新选优不确定性。能量坐标来自同批次实际波形统计，非独立的能量预测精度验证。前沿、最优及损失均限定已搜索125候选。

## Dependencies

MATLAB readtable/writetable、prctile、rng和基础数组运算；上游l2_run_information_frontier_main。
