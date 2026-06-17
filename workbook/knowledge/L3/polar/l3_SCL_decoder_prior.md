# L3 · SCL_decoder_prior

- **method_id**: l3_SCL_decoder_prior
- **file_path**: 16QAM_Polar/v2/polar/SCL_decoder_prior.m
- **module**: polar
- **health**: healthy

## Signature
同 l3_SCL_decoder，额外输入 `prior_llr`（N×1，先验 LLR；缺省/空等价标准 SCL）。
**注意**：`cfg.decoder = 'SCL'` 默认走此带先验版本（向后兼容），`'SCL_no_prior'` 才走 l3_SCL_decoder。

## Purpose
支持**非均匀先验**的 SCL 译码器，用于概率整形场景的列表译码。

## Math / Algorithm
与 l3_SCL_decoder 相同，唯一区别在非冻结位 PM 更新使用有效 LLR：
- `L_eff = P(1,l) + prior_llr(phi+1)`
- `L_eff≥0` → PM_pair = [PM, PM+L_eff]；`L_eff<0` → PM_pair = [PM-L_eff, PM]。
- 先验约定同 l3_SC_decoder_prior。

## Numerical Notes
- `nargin < 8 || isempty(prior_llr)` 退化为全零先验（= 标准 SCL）。

## Dependencies
- 同 l3_SCL_decoder

## Health
healthy
