# L3 — `run_pmf_blocklength_compare`

- **目的**：固定16QAM、BSC可靠端S、概率与relation，比较N=64/256/1024时PMF TV是否收敛。
- **帧数**：80/40/20，均为轻量PMF诊断，不是BER统计。
- **判读**：若TV随N显著下降，主要是有限长度损失；若不下降，则Bhattacharyya proxy/precoder口径仍需修正。
- **健康度**：pending-runtime。
