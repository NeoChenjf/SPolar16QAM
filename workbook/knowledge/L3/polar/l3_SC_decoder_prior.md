# L3 · SC_decoder_prior

- **method_id**: l3_SC_decoder_prior
- **file_path**: 16QAM_Polar/v2/polar/SC_decoder_prior.m
- **module**: polar
- **health**: healthy

## Signature
同 l3_SC_decoder，额外输入 `prior_llr`（N×1，先验 LLR；缺省/空等价于标准 SC）。

## Purpose
支持**非均匀先验**的 SC 译码器，用于概率整形场景：整形位带先验偏置。

## Math / Algorithm
与 l3_SC_decoder 算法相同，唯一区别在非冻结位硬判决：
- `L_eff = P(1) + prior_llr(phi+1)`，`û = [L_eff < 0]`
- 先验约定：`prior_llr(i) = ln(P(u_i=0)/P(u_i=1))`；信息位 0，整形位 `ln((1-p)/p)`。

## Numerical Notes
- `nargin < 7 || isempty(prior_llr)` 时退化为全零先验（= 标准 SC），向后兼容。

## Dependencies
- 同 l3_SC_decoder（get_llr_layer / get_bit_layer / lambda_offset）

## Health
healthy
