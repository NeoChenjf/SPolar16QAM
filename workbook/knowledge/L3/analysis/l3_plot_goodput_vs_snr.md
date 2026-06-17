# L3 · plot_goodput_vs_snr

- **method_id**: l3_plot_goodput_vs_snr
- **file_path**: 16QAM_Polar/v2/analysis/plot_goodput_vs_snr.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`p_list`、`snr_dB`、`Goodput_matrix`(nP×nSNR)、`fig_dir`
**输出**：图文件

## Purpose
绘制不同 p 下的 Goodput vs SNR 曲线。

## Math / Algorithm
可视化逻辑：每个 p 一条 Goodput 曲线，对照设计码率上界。

## Numerical Notes
- ⚠️ 对比前核对各 p 的码率上界 R=ΣK/(4N)（成形会压低上界）。

## Dependencies
- 消费 l3_compute_goodput

## Health
healthy
