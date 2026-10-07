# L2 · OOK gettest-style 复现

- **flow_id**: l2_ook_reproduce_smoke
- **entry_script**: 16QAM_Polar/OOK/run_ook_gettest_style.m
- **runtime**: long
- **needs_user_run**: true
- **validates**: l1_ook_shaped_polar#H1, l1_ook_shaped_polar#H2

## Purpose

按 `ShapedPolarS/gettest.m` / `drawtest.m` 的数据形状复现 OOK shaped-polar 曲线：`p=[0.5,0.7,0.9]`，`SNR=-5:0.5:10`，输出 BER/BLER 的 `p x SNR` 矩阵和对数坐标图。完整默认运行较长，需要用户授权；未授权时 agent 只跑短格式 smoke。本轮已在用户授权后完成一次完整运行。

## Pipeline

| # | step | l3_ref | 说明 |
| --- | --- | --- | --- |
| 1 | 配置 p/SNR/帧数/seed | 内联 | full 默认 `p=[0.5,0.7,0.9]`、`snr=-5:0.5:10`、1000 帧 |
| 2 | 构造 S/I/F 并仿真 OOK shaped polar | `l3_simulate_ook_shaped_polar` | 复用 legacy GA/SC/polar_encoder |
| 3 | 汇总 BER/BLER 矩阵 | `l3_simulate_ook_shaped_polar` | 输出 p x SNR matrix |
| 4 | 绘制 BER/BLER 对数图 | 内联 | `semilogy` 风格；0 值仅绘图时 floor 到 `1e-5` |
| 5 | 写结果 README 与 MAT/CSV | 内联 | timestamped results 目录 |

## Inputs

Full defaults:

- `p_list=[0.5,0.7,0.9]`
- `N=1024`
- `snr_grid=-5:0.5:10`
- `num_frames=1000`
- `seed=42`
- `regenerate_each_frame=true`

Format smoke used by agent:

- `snr_grid=[-5,0,5,10]`
- `num_frames=5`
- `result_tag='ook_gettest_style_snr_m5_to_10_smoke'`

Latest full run:

- `result_dir=16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/`
- `p_list=[0.5,0.7,0.9]`
- `snr_grid=-5:0.5:10`
- `num_frames=1000`
- BER/BLER figures regenerated with explicit log-scale y ticks `10^-5` to `10^0`.

## Outputs

```text
16QAM_Polar/OOK/results/YYYYMMDD_HHMMSS_ook_gettest_style*/
```

包含：

- `ook_gettest_style_long.csv`
- `ook_gettest_style_BER_matrix.csv`
- `ook_gettest_style_BLER_matrix.csv`
- `ook_gettest_style_curves.mat`
- `README.txt`
- `run_log.txt`
- `figures/ook_gettest_style_BER.*`
- `figures/ook_gettest_style_BLER.*`

## Acceptance

- MATLAB format smoke exit 0。
- BER/BLER matrix 行数等于 `numel(p_list)`，列数等于 `numel(snr_grid)+1`（含 p 列）。
- BER/BLER 图为对数坐标。
- 若高 SNR 出现全零错误，只记录为 smoke 边界，不用于最终排序。
- 完整 `num_frames=1000` 运行需要用户授权；2026-07-04 已完成一次授权运行。

## Weekly Report

- `周报/原始Shape/README.md`

