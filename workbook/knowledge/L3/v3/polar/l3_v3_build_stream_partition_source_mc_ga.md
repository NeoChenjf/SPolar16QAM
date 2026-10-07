# L3 — `build_stream_partition_source_mc_ga`

- **定义**：从iid Bernoulli(p)样本经当前极化矩阵得到真实u，用同一source LLR和SC递推估计每个U位的条件熵；最低熵的 `N(1-H2(p))` 个可预测位置为S，剩余位置用GA选择I/F。
- **用途**：诊断BSC Bhattacharyya proxy与当前极化实现的索引/构造不匹配。
- **边界**：Monte Carlo近似，构造样本数必须预登记；主smoke当前使用120样本。`p=0.5`时S为空，直接跳过无意义的source-MC循环并由GA划分I/F。
- **RNG契约**：提供seed时函数保存并恢复调用者RNG状态，离线source构造不得改写后续payload/AWGN随机流。
- **健康度**：排序方向与RNG隔离均已修复；N=256全M PMF smoke、全M energy-lambda smoke及BER refine D门禁均通过。64QAM正式经验PMF门禁待用户运行。
