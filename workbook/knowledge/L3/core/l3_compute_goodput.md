# L3 · compute_goodput

- **method_id**: l3_compute_goodput
- **file_path**: 16QAM_Polar/v2/core/compute_goodput.m
- **module**: core
- **health**: healthy

## Signature
**输入**：`result`（`sim_shaped_polar_16qam` 返回结构体）
**输出**：`G`（Goodput 向量 1×nSNR）

## Purpose
从仿真结果计算 Goodput（有效信息传递效率）。

## Math / Algorithm
`G(p, SNR) = R_total(p) · (1 - BER(p, SNR))`，其中 `R_total = ΣK / (4N)`。

## Numerical Notes
- ⚠️ 判定吞吐高低前，先核对设计码率上界 `R_total = ΣK/(4N)`（成形会压低 K → 上界本就更低，
  不可与基线直接比绝对值）。见 l1_metrics_tradeoff pitfalls。

## Dependencies
- 消费 l3_sim_shaped_polar_16qam 的输出（`R_total`, `BER`）。

## Health
healthy
