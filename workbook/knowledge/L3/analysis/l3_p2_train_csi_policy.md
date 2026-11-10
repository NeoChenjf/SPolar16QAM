# L3 · p2_train_csi_policy

- method_id: l3_p2_train_csi_policy
- file_path: 16QAM_Polar/v2/analysis/p2_train_csi_policy.m
- module: analysis
- health: exploratory

`policy=p2_train_csi_policy(run_dir,max_ber,min_goodput,beta2,beta4)` 审计探索训练数据；以信道频域平均增益的训练中位数分两档，分别在27组合中按给定门槛和无量纲矩代理选择候选；空档和无可行候选明确保留。示例阈值不是业务规格，代理不是DC。本规则只用总信道增益而未覆盖频率选择性、CSI误差、控制开销；无正式训练资产绑定或独立泛化验证。依赖 l3_p2_verify_common_snapshot、l3_p2_audit_common_pairing、l3_p2_validate_common_raw_metrics、l3_p2_select_training_tradeoff。

MATLAB现有2信道训练每档1个，两档恰好均选combo_01；仅供接口检查，不证明策略自适应收益。
