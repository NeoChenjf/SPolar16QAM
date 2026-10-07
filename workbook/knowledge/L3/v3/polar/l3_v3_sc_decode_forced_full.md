# L3 · sc_decode_forced_full

- **method_id**: l3_v3_sc_decode_forced_full
- **file_path**: 16QAM_Polar/v3/polar/sc_decode_forced_full.m
- **module**: v3 polar
- **health**: planned-smoke-pending

## Purpose
SC 译码返回完整 `u`，并允许任意已知位置。发送端用它在当前 `I/F` 约束下求 `S`；接收端只能将 `F` 标为已知。

## Guardrail
不允许先求 S 后覆盖 I；通信 decoder 的活动集是 `I∪S`，仅 I 是 payload。

