# L2 · run_find_waterfall_and_refine（瀑布区自动定位与加密复验）

- **flow_id**: l2_find_waterfall_and_refine
- **entry_script**: 16QAM_Polar/v2/experiments/sc_checks/run_find_waterfall_and_refine.m
- **runtime**: minutes（粗扫）/ long（全 p 局部加密复验）
- **needs_user_run**: false（粗扫）/ true（加密复验）
- **validates**: l1_metrics_tradeoff#H1, l1_channel_snr#H1

## Purpose
自动寻找 SC code-only 链路的有效**瀑布区**（BER∈[1e-4,1e-1]），并在该窗口做局部加密复验。
口径与 `run_sc_theory_vs_sim` 一致（Theory=estimate_ber_hat_sc_dual disable_geom; Sim=polar+BPSK-AWGN+SC）。
直接服务于项目"先定位瀑布区再判定 BER"的硬规则。

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 粗扫定位窗口 | l3_estimate_ber_hat_sc_dual（disable_geom） | 只扫基线 p=0.5 |
| 2 | 仿真侧粗扫 | l3_polar_encoder, l3_SC_decoder | 自适应帧数（达到最小误码数） |
| 3 | 定位 BER 中点 | （脚本内联） | target_ber_mid=√(1e-4·1e-1) |
| 4 | 局部加密复验 | l3_SC_decoder | 全 p 在窗口 ±1dB、步长 0.25dB |

## Inputs
- target_ber ∈ [1e-4, 1e-1], coarse_snr_grid=-8:2:10, local_half_width_db=1.0, local_step_db=0.25
- p_list 粗扫=0.5；local_p_list=[0.5 0.4 0.3 0.2 0.1]

## Outputs
- 瀑布区窗口定位结果 + 局部加密 BER 曲线（results/ 时间戳目录）。

## Acceptance
- ⚠️ **核心护栏**：必须先定位 BER∈[1e-4,1e-1] 的信息瀑布区；
  高 SNR 全零错误窗口不是 BER 异常的证据（`workbook/mandatory-rules.md` / `AGENTS.md`）。

## Weekly Report
- 关联瀑布区定位阶段周报。
