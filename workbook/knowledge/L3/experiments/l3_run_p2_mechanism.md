

# L3 · run_p2_mechanism

- **method_id**: l3_run_p2_mechanism
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_mechanism.m
- **module**: experiments
- **health**: healthy

## Signature

`function out_dir = run_p2_mechanism(cfg_local)`

## Purpose / Math

源模板复用，配对消息/辅助/噪声，OFDM连续卷积、ZF与当前译码；每cell原始MAT、CSV与checkpoint。正式模式要求预算协议、源哈希、功率/PMF门禁；未测量通信为NaN。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_build_source_entropy_partition, l3_ofdm_channel_roundtrip, l3_p2_decode_block, l3_p2_default_config, l3_p2_llr_reference, l3_p2_predict_ga, l3_p2_prepare_state, l3_p2_seed, l3_p2_transmit_block

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_7b035b6109f5_20261024; current_status=current; supersedes=[].
