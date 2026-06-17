# L3 · plot_pareto

- **method_id**: l3_plot_pareto
- **file_path**: 16QAM_Polar/v2/analysis/plot_pareto.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`p_list`、`snr_dB`、`Goodput_matrix`(nP×nSNR)、`E_norm_vec`(nP×1)、`snr_targets`、`fig_dir`
**输出**：图文件

## Purpose
绘制 Goodput vs 归一化能量的 Pareto 前沿图（信息-能量权衡核心可视化）。

## Math / Algorithm
可视化逻辑：在选定 `snr_targets` 处，以 (E_norm, Goodput) 为坐标画各 p 点并标出 Pareto 前沿。
`E_norm = (18-16p)/10`。

## Numerical Notes
- 能量轴用归一化能量，便于跨 p 对比。

## Dependencies
- 消费 l3_compute_goodput, l3_compute_energy

## Health
healthy
