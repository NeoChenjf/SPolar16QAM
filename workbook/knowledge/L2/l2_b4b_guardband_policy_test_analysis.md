# L2 · run_b4b_guardband_policy_test_analysis

- **entry**：`run('experiments/multicarrier/run_b4b_guardband_policy_test_analysis.m')`
- **输入**：第三批正式测试`20260917_223848_b4b_guardband_policy_test`。
- **冻结规则**：20/24 dB使用`uniform_p05`；28—40 dB使用`uniform_p01`。
- **验收**：低SNR保持最大Goodput；高SNR满足BER上95%不超过0.1、Goodput下95%不低于0.25且能量增量为正。
- **健康度**：PASS（`20260917_225122_b4b_guardband_policy_test_analysis`）。
- **边界**：第三批数据不得继续用于调参。


## 2026-10-09 新构造独立分析输入支持

分析入口现支持通过本地override传入本轮source-entropy训练结果、seed1042 holdout、seed2042验证结果及训练阶段冻结的policy_selection.csv。holdout/test脚本不得使用独立验证集重选策略；每次分析需保存输入摘要、参数、图、README、源码快照及输入/源码SHA-256。

## 2026-10-09 append-only contract update — pre-freeze guardband candidate

`freeze_b4b_guardband_candidate(training_dir)` builds a candidate policy using only the formal seed42 training summary. It chooses the highest receive-energy strategy satisfying a training BER upper bound of 0.08 and Goodput lower bound of 0.27; if none qualifies it falls back to maximum training Goodput and labels the fallback. The helper writes a timestamped policy CSV, training data copy, thresholds, source copy, and hashes. F18 analysis must consume this frozen policy and check the original registered limits (BER upper <=0.10, Goodput lower >=0.25) on the independent seed2042 split. No holdout result may influence candidate construction.

## 2026-10-09 seed2042预注册保护带验证更新

候选`results/20261009_210928_b4b_guardband_candidate_frozen/policy_selection.csv`由seed42正式训练集冻结，guardband BER upper<=.08、Goodput lower>=.27；seed2042结果未用于候选选择。结果`results/20261009_223251_b4_source_entropy_guardband2042/`1080条重复通过数据审计。F18分析`results/20261009_230741_b4b_guardband_policy_test_analysis/`：28/32/36/40 dB的BER upper95和Goodput lower95均满足原门槛，接收能量代理差值对uniform_p05均为正；20/24 dB按训练规则fallback，不声称通信约束通过。总体通过指高SNR候选点的注册门槛，非等功率或RF-DC结论。

## 2026-10-09 pipeline references

- Freeze: `l3_freeze_b4b_guardband_candidate` uses the seed42 training summary only.
- Independent test: `l3_run_b4b_guardband_policy_test_analysis` reads the frozen policy and `l3_verify_b4b_strict_smoke`-audited seed2042 data.
