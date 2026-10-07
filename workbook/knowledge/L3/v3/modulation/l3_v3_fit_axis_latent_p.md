# L3 — `fit_axis_latent_p`

- **签名**：`fit = fit_axis_latent_p(axis_labels,target_axis,T)`。
- **定义**：在固定可逆 GF(2) 关系 `b=Tz` 下，以有界 logistic 参数化和多起点 `fminsearch` 最小化 `D_KL(P_target||P_model)`，返回 latent `p`、模型轴PMF、KL/TV及 solver 状态。
- **数值约束**：`p∈[1e-4,1-1e-4]`；均匀目标直接返回精确 `p=0.5`；KL最终钳制为非负，避免浮点负机器零。
- **健康度**：implemented-pending-runtime。
