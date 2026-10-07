# L3 · verify_b4b_fixed_policy_holdout_analysis

- **入口**：`report = verify_b4b_fixed_policy_holdout_analysis(result_dir)`。
- **职责**：核对冻结策略映射、训练/验证区间关系、通信门限判定、20 dB回退、相对能量方向和两图三格式。
- **关键契约**：验证失败是允许且必须被保存的研究结果；当前预期审计本身PASS、分析状态PARTIAL、失败SNR仅为24 dB。
- **输出**：`audit.txt`及包含`analysis_status`和`failed_snr`的报告结构。
- **健康度**：PASS（2026-09-17，`20260917_222439_b4b_fixed_policy_holdout_analysis`）。
