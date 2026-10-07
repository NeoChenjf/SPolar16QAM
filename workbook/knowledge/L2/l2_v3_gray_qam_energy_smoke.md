# L2 · v3 通用 Gray-QAM 能量参数 smoke

- **flow_id**: `l2_v3_gray_qam_energy_smoke`
- **entry**: `summary = run_gray_qam('energy_smoke')`
- **runtime**: medium/long
- **needs_user_run**: true

## 目的

对 Cartesian Gray 8/16/32/64QAM 统一验证 `energy_lambda` 目标、latent-axis 近似模型、真实 shaped-polar 经验分布及平均发送 RF 能量代理的单调性。该指标不是整流器收获能量。

## 流程

1. 固定均匀星座缩放，令 `P_X(x) ∝ exp(lambda*|x|^2)`，`lambda=[0,0.25,0.5]`。
2. 每轴固定 relation，多起点拟合独立 latent Bernoulli `p`，保存 target/model KL、TV和 solver 证据。
3. 使用 source-MC+GA、`N=256`、40帧、120个构造样本，以 `fixed_n0` 和120 dB运行近似无噪声 PMF smoke。
4. 保存每帧 PMF；相邻 lambda 用同 seed、按帧配对 bootstrap 估计 `E_high-E_low` 的单侧95%下界。
5. 每点写 partial CSV/checkpoint，最终写 CSV/MAT/README/run log/progress log及PNG/PDF/FIG。

## 验收

- target→model 不得为 `fail`：exact 为 `KL≤1e-10, TV≤1e-8`；approximate-pass 为 `KL≤0.02 nat, TV≤0.05`。
- 每个 M 的模型能量随 lambda 严格递增。
- 两个相邻经验能量差的配对 bootstrap 下界均 `>0`。
- 经验 PMF smoke 的 cluster-bootstrap TV 上界 `≤0.10`。
- 本入口通过后才设计有限 SNR BER 瀑布区；不把120 dB结果解释成BER曲线。

## 产物

`16QAM_Polar/v3/results/YYYYMMDD_HHMMSS_energy_lambda_smoke/`

## 健康度

smoke-pass：`20260902_224303_energy_lambda_smoke`，overall_pass=1；8组经验相邻能量差下界均大于0。64QAM经验PMF仍未达到正式TV上界0.05。
