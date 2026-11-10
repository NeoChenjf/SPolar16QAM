# L3 · p2_apply_csi_policy

- method_id: l3_p2_apply_csi_policy
- file_path: 16QAM_Polar/v2/analysis/p2_apply_csi_policy.m
- module: analysis
- health: exploratory

`choice=p2_apply_csi_policy(policy,h)` 根据输入信道频域平均增益与训练门槛选择已确定档位及候选；没有可行候选时原样返回空选择和状态。实际接收端CSI、估计误差及信令尚未实现，不证明泛化性能。

MATLAB测试覆盖训练两个信道档位、阈值相等、无可行档与非有限信道拒绝。
