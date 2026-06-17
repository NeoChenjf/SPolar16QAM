# L2 · run_sc_theory_vs_sim（SC 理论 vs 仿真对照）

- **flow_id**: l2_sc_theory_vs_sim
- **entry_script**: 16QAM_Polar/v2/run_sc_theory_vs_sim.m
- **runtime**: minutes（局部加密模式）/ long（全范围）
- **needs_user_run**: false（局部加密）/ true（大范围）
- **validates**: l1_polar_coding#H2, l1_channel_snr#H1

## Purpose
清晰分离「GA 理论预测」与「SC 实际仿真」，用相对 p=0.5 的**比值对齐**突出整形 p 的净影响，
规避绝对量级系统差异。可选基线增益校准（仅工程工具，明确标注非理论）。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 理论侧：GA 推断各信道可靠性 | l3_GA | 计算信息位平均 BER 渐近估计 |
| 2 | 仿真侧：编码 | l3_polar_encoder | — |
| 3 | BPSK-AWGN + SC 译码 | l3_SC_decoder | 真实 Monte Carlo |
| 4 | 比值对齐 | （脚本内联） | 相对 p=0.5 |
| 5 | 可选基线增益校准 | （脚本内联） | 标注"工程校准，非理论" |

## Inputs
- 局部加密模式 `run_local_12db_mode=true`：p_list=[0.5 0.4 0.3 0.2 0.1], snr_grid=11:0.25:13
- decoder='SC'

## Outputs
- 理论 vs 仿真对照曲线（比值对齐）；保存到 results/ 时间戳目录。

## Acceptance
- ⚠️ 先定位 BER ∈ [1e-4,1e-1] 信息瀑布区再做对照；高 SNR 全零错误非异常。
- 校准线必须明确标注"非理论"，不得与真实仿真线混淆解读。

## Weekly Report
- 关联理论-仿真对照阶段周报。
