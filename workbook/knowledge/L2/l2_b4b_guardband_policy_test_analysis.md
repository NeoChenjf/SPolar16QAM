# L2 · run_b4b_guardband_policy_test_analysis

- **entry**：`run('experiments/multicarrier/run_b4b_guardband_policy_test_analysis.m')`
- **输入**：第三批正式测试`20260917_223848_b4b_guardband_policy_test`。
- **冻结规则**：20/24 dB使用`uniform_p05`；28—40 dB使用`uniform_p01`。
- **验收**：低SNR保持最大Goodput；高SNR满足BER上95%不超过0.1、Goodput下95%不低于0.25且能量增量为正。
- **健康度**：PASS（`20260917_225122_b4b_guardband_policy_test_analysis`）。
- **边界**：第三批数据不得继续用于调参。
