# L3 · p2_compare_csi_policy

- method_id: l3_p2_compare_csi_policy
- file_path: 16QAM_Polar/v2/analysis/p2_compare_csi_policy.m
- module: analysis
- health: exploratory

`output=p2_compare_csi_policy(policy,test_dir,baseline_ids)` 核对探索训练/测试角色、参数、源码、共同环境、原始指标和信道指纹后，按给定策略逐测试信道选候选并与基线逐信道求BER、Goodput及无量纲代理差值；无可行选择时明确报错。其不绑定传入policy与训练资产、也不证明创建策略的时间，故不构成正式冻结或盲测验收。未计真实CSI误差和开销。

MATLAB使用已有2个训练/2个不同测试信道、每候选每信道一帧的短数据，四基线共8行通过；训练目录充测试被拒。两测试信道均落低增益档并选combo_01，不能证明自适应收益。依赖 l3_p2_apply_csi_policy、l3_p2_verify_common_snapshot、l3_p2_audit_common_pairing、l3_p2_validate_common_raw_metrics。
