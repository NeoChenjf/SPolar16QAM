# L2 · run_b4b_fixed_policy_holdout_analysis

- **flow_id**：`l2_b4b_fixed_policy_holdout_analysis`
- **entry**：`run('experiments/multicarrier/run_b4b_fixed_policy_holdout_analysis.m')`
- **输入**：冻结训练码本`20260917_215938_b4b_paired_policy_analysis`与独立正式验证`20260917_221105_b4b_fixed_policy_holdout`。
- **冻结规则**：20 dB选择`uniform_p05`；24—40 dB选择`uniform_p01`；BER上95%不超过0.1且Goodput下95%不低于0.25。
- **输出**：逐SNR训练/验证指标、门限判定、相对$p=0.5$能量增量、MAT、README及两图三格式。
- **验收**：映射不变、区间恒等式、20 dB回退、通信门限、能量方向和图文件通过独立审计。
- **健康度**：审计PASS，研究结论PARTIAL（2026-09-17，24 dB BER上95%=0.1060超过0.1；其余点通过）。
- **边界**：不得使用该验证集事后调参并继续称独立验证；若修改切换点，须建立第三批测试集。
