# L3 · p2_train_rectifier_csi_policy

- method_id: l3_p2_train_rectifier_csi_policy
- file_path: 16QAM_Polar/v2/analysis/p2_train_rectifier_csi_policy.m
- module: analysis
- health: exploratory

`policy=p2_train_rectifier_csi_policy(run_dir,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)` 从训练信道平均增益中位数形成两档，再按每档实际训练信道上的信息门槛与给定物理参数的电流代理选候选；不覆盖的档返回no_training_coverage，档内范围均不合适则no_feasible。返回接口可由 l3_p2_apply_csi_policy 使用。当前模型、参数和范围均为假设，输出不是DC功率或已验证最优策略。依赖 l3_p2_train_csi_policy、l3_p2_select_rectifier_tradeoff。

MATLAB用两训练信道各一帧短数据，两档各选combo_01；假设极窄有效范围两档无可行，重复信道子集被拒。未作可信事前冻结、正式独立信道验证或硬件标定。
