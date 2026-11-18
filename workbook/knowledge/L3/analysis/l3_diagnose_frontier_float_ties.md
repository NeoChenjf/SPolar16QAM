# L3 · 浮点近并列诊断

- method_id为l3_diagnose_frontier_float_ties。
- file_path为16QAM_Polar/v2/analysis/diagnose_frontier_float_ties.m。
- module为analysis，health为healthy，仅解释浮点精度。

## Signature

diagnose_frontier_float_ties(out)从原生双精度预测MAT统计每条件7750对的精确平局和64 ulp内非零近并列，不改变冻结排名。

## Math / Algorithm

逐方法比较候选分数差并设浮点容差为64倍当前数值的机器间隔。

## Numerical Notes

该容差仅诊断浮点表示，不是科学准确率门槛，也不覆盖粒子/PMF/帧误差。

## Dependencies

冻结预测MAT，MATLAB eps、nchoosek、writetable。
