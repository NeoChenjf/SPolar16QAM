# L2 · run_b4b_fixed_policy_holdout_analysis

- **flow_id**：`l2_b4b_fixed_policy_holdout_analysis`
- **entry**：`run('experiments/multicarrier/run_b4b_fixed_policy_holdout_analysis.m')`
- **输入**：冻结训练码本`20260917_215938_b4b_paired_policy_analysis`与独立正式验证`20260917_221105_b4b_fixed_policy_holdout`。
- **冻结规则**：20 dB选择`uniform_p05`；24—40 dB选择`uniform_p01`；BER上95%不超过0.1且Goodput下95%不低于0.25。
- **输出**：逐SNR训练/验证指标、门限判定、相对$p=0.5$能量增量、MAT、README及两图三格式。
- **验收**：映射不变、区间恒等式、20 dB回退、通信门限、能量方向和图文件通过独立审计。
- **健康度**：审计PASS，研究结论PARTIAL（2026-09-17，24 dB BER上95%=0.1060超过0.1；其余点通过）。
- **边界**：不得使用该验证集事后调参并继续称独立验证；若修改切换点，须建立第三批测试集。


## 2026-10-09 新构造独立分析输入支持

分析入口现支持通过本地override传入本轮source-entropy训练结果、seed1042 holdout、seed2042验证结果及训练阶段冻结的policy_selection.csv。holdout/test脚本不得使用独立验证集重选策略；每次分析需保存输入摘要、参数、图、README、源码快照及输入/源码SHA-256。

## 2026-10-09 seed1042独立验证更新

一般码本训练策略从F15输出读取并固定，seed1042正式结果`results/20261009_211124_b4_source_entropy_holdout1042/`经严格审计1080行、36汇总及纯能量语义检查通过。分析`results/20261009_223148_b4b_fixed_policy_holdout_analysis/`：28–40 dB满足原BER upper95<=.10和Goodput lower95>=.25，20/24 dB是预先冻结的最大Goodput fallback，不算约束通过。能量差仍为非等功率接收RF均方代理。F16/F17图通过视觉检查。

## 2026-10-09 pipeline references

- Frozen-policy evaluation: `l3_run_b4b_fixed_policy_holdout_analysis` consumes the policy from `l3_run_b4b_paired_policy_analysis` and formal data audited by `l3_verify_b4b_strict_smoke`.
