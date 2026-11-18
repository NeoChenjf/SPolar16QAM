# L3 · 信息前沿数值灵敏度

- method_id为l3_check_information_frontier_numerics。
- file_path为16QAM_Polar/v2/analysis/check_information_frontier_numerics.m。
- module为analysis，health为degraded：只检查固定子集，不能证明全域收敛。

## Signature

check_information_frontier_numerics(out)读取冻结输入与预测，比较固定8组条件下原预测、粒子seed+1和160阶数值积分，输出numeric_sensitivity.csv，不产生通信帧或替换独立预测。

## Math / Algorithm

调用l3_p1_predict_minsum，B8192不变；保留原始80阶/seed估计。固定H1/H8、标签16/28、组3与p=.1/.5。

## Numerical Notes

该检查不是独立通信测试，有限子集不能代表所有候选；有限粒子误差、输入分布误差和叶相关性需分别解释。

## Dependencies

l3_p1_predict_minsum，冻结frozen.mat及逐条件预测文件。
