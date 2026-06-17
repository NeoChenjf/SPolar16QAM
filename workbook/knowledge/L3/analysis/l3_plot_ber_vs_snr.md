# L3 · plot_ber_vs_snr

- **method_id**: l3_plot_ber_vs_snr
- **file_path**: 16QAM_Polar/v2/analysis/plot_ber_vs_snr.m
- **module**: analysis
- **health**: healthy

## Signature
**输入**：`p_list`(nP×1)、`snr_dB`(1×nSNR)、`BER_matrix`(nP×nSNR)、`fig_dir`
**输出**：图文件（保存到 fig_dir）

## Purpose
绘制不同整形参数 p 下的 BER vs SNR 曲线（半对数）。

## Math / Algorithm
可视化逻辑：每个 p 一条 semilogy 曲线；按项目约定保存（论文用 PDF、复核用 PNG）。

## Numerical Notes
- ⚠️ 读图判定时先聚焦 BER ∈ [1e-4,1e-1] 瀑布区（见 l1_metrics_tradeoff pitfalls）。

## Dependencies
- 消费 l3_sim_shaped_polar_16qam 的 BER 输出

## Health
healthy
