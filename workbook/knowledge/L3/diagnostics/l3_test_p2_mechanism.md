

# L3 · test_p2_mechanism

- **method_id**: l3_test_p2_mechanism
- **file_path**: 16QAM_Polar/v2/diagnostics/multicarrier/test_p2_mechanism.m
- **module**: diagnostics
- **health**: healthy

## Signature

`function test_p2_mechanism()`

## Purpose / Math

非零消息环回、辅助/供体约束、小码长穷举max-log、实际I敏感性、似然、校准恢复及泄漏拒绝断言。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_build_source_entropy_partition, l3_llr_16qam_gray_LSE, l3_p2_calibrate_model, l3_p2_decode_block, l3_p2_default_config, l3_p2_distribution_reference, l3_p2_evaluate_predictions, l3_p2_llr_reference, l3_p2_predict_ga, l3_p2_prepare_state, l3_p2_seed, l3_p2_transmit_block, l3_p2_uniformity_contract, l3_polar_encoder, l3_run_p2_mechanism, l3_v3_sc_decode_forced_full

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_459e31da9ee3_20261024; current_status=current; supersedes=[].
