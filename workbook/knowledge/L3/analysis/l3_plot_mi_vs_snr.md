# L3 · plot_mi_vs_snr

- **method_id**: l3_plot_mi_vs_snr
- **file_path**: 16QAM_Polar/v2/analysis/plot_mi_vs_snr.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`p_list`、`snr_dB`、`MI_matrix`(nP×nSNR)、`fig_dir`
**输出**：图文件

## Purpose
绘制不同 p 下的总互信息 vs SNR 曲线。

## Math / Algorithm
可视化逻辑：每个 p 一条 MI_total 曲线（MI 由 `I=1-E[log2(1+e^{-sL})]` 估得）。

## Numerical Notes
无特别注意点。

## Dependencies
- 消费 l3_sim_shaped_polar_16qam 的 MI / MI_total 输出

## Health
healthy
