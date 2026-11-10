# L3 · p2_candidate_validation_seed

- method_id: l3_p2_candidate_validation_seed
- file_path: 16QAM_Polar/v2/core/p2_candidate_validation_seed.m
- module: core
- health: proposed_not_registered

`value=p2_candidate_validation_seed(split,realization,snr_index,frame,group,role)` 拒绝诊断实际接触过的整组 `seen_first`、`unseen_first`、`strategy_test` 和两个diagnostic split，仅允许预先列出的8类候选训练/测试域，并转交 l3_p2_future_seed。为保守起见，整组拒绝不等于组内每个key都实际使用过。

此检查只是当前已知使用记录的防误用，不是全项目历史碰撞审计、PRNG独立证明、正式注册或长实验授权；没有连接正式入口。候选strategy_test_v2仅参与数值测试，未由此测试生成随机样本。

MATLAB测试拒绝6个不允许名称、8类候选键互异；修改p2_future_seed后1066个边界键检查通过。
