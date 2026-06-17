# L3 · plot_cost_curves

- **method_id**: l3_plot_cost_curves
- **file_path**: 16QAM_Polar/v2/analysis/plot_cost_curves.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`p_list`、`snr_dB`、`Goodput_matrix`、`E_theory_vec`、`idx_baseline`、`snr_targets`、`fig_dir`
**输出**：图文件

## Purpose
绘制能量-信息代价函数 cost(p) 曲线（单位能量增益的信息损失）。

## Math / Algorithm
可视化逻辑：以 `idx_baseline`（p=0.5）为基线，调用代价公式
`cost = -(G-G0)/(E-E0)`（仅 E>E0 有效）逐 p 绘制。

## Numerical Notes
- `E ≤ E0` 处 cost 为 NaN，不绘点（见 l3_compute_cost）。

## Dependencies
- 消费 l3_compute_cost, l3_compute_goodput, l3_compute_energy

## Health
healthy
