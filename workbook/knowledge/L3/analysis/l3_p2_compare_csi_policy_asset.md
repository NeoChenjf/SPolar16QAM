# L3 · p2_compare_csi_policy_asset

- method_id: l3_p2_compare_csi_policy_asset
- file_path: 16QAM_Polar/v2/analysis/p2_compare_csi_policy_asset.m
- module: analysis
- health: exploratory

`output=p2_compare_csi_policy_asset(policy,asset_file,test_dir,baseline_ids)` 先以冻结训练资产记录的门槛重建分档策略并比较，再重验训练资产和测试、执行逐信道比较。已有训练资产的哈希绑定不能证明这个分档policy在测试被观察前已冻结；policy仍需单独可信时间戳/冻结和未观察测试。

MATLAB对已有两个探索测试信道与四基线得到8行，修改分档门槛参数后拒绝。测试规模不足、非盲测、无CSI误差或正式性能结论。依赖 l3_p2_train_csi_policy、l3_p2_evaluate_strategy_asset、l3_p2_compare_csi_policy。
