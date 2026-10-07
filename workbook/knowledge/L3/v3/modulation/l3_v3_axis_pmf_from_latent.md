# L3 · axis_pmf_from_latent

- **method_id**: l3_v3_axis_pmf_from_latent
- **file_path**: 16QAM_Polar/v3/modulation/axis_pmf_from_latent.m
- **module**: v3 modulation
- **health**: planned-smoke-pending

## Math
对每个 canonical Gray label `b` 求 `z=T^{-1}b mod2`，再计算 `P(b)=Π p_k^{z_k}(1-p_k)^{1-z_k}`。

## Guardrail
这只给理想边缘 PMF；有限长 shaped-polar 偏差由跨帧统计另验。

