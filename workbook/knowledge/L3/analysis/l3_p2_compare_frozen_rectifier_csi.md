# L3 · p2_compare_frozen_rectifier_csi

- method_id: l3_p2_compare_frozen_rectifier_csi
- file_path: 16QAM_Polar/v2/analysis/p2_compare_frozen_rectifier_csi.m
- module: analysis
- health: exploratory

`output=p2_compare_frozen_rectifier_csi(frozen_file,expected_sha256,test_dir,baseline_ids)` 先核验外部传入的policy资产指纹及训练资产指纹，再重建策略、审计数据并比较；预期指纹若与资产一起被改或在测试后才记录，不能证明事前冻结。测试数据独立性、样本和物理模型另验。

MATLAB临时资产对既有两信道四基线得到8行，错误的外部指纹被拒。依赖 l3_p2_compare_rectifier_csi_asset。
