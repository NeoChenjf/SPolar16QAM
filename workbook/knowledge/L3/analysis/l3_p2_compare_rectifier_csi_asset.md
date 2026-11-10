# L3 · p2_compare_rectifier_csi_asset

- method_id: l3_p2_compare_rectifier_csi_asset
- file_path: 16QAM_Polar/v2/analysis/p2_compare_rectifier_csi_asset.m
- module: analysis
- health: exploratory

`output=p2_compare_rectifier_csi_asset(policy,training_asset,test_dir,baseline_ids)` 基于探索训练资产与policy内假设参数重建并核对非线性CSI规则，再调用训练资产/测试核验和非线性配对比较。可识别与当前训练不一致的规则，但没有单独冻结假设参数，也没有证据表明policy在查看测试前已冻结；不能用于盲测或正式验收。

MATLAB对既有两测试信道和四基线得到8行，修改policy分档门槛被拒。依赖 l3_p2_train_rectifier_csi_policy、l3_p2_evaluate_strategy_asset、l3_p2_compare_rectifier_csi。
