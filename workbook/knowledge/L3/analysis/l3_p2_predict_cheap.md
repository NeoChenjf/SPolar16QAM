# L3 · p2_predict_cheap

- **method_id**: l3_p2_predict_cheap
- **file_path**: 16QAM_Polar/v2/analysis/p2_predict_cheap.m
- **module**: analysis
- **health**: degraded — development model; independent precision and speed acceptance pending.

## Signature

Inputs: H (n_sc complex gains), N0 (positive complex time noise power), n_sc,
states (actual S/K/p/kind), locations (group symbol indices), model (cheap JSON structure).
Output: prediction.per_group, prediction.ber, prediction.features.

## Purpose

Compute group BER using cheap known-channel features and a fitted logistic surrogate.

## Math / Algorithm

For unique occupied subcarriers per group, sigma=sqrt(n_sc*N0/2)/max(abs(H),1e-8).
Let s=log(mean(sigma)). Features are s, s^2, mean(log(max(abs(H)^2,1e-12))),
log(max(min(abs(H)^2),1e-12)), p_vec(2), sum(K)/4096, sum(S_size)/4096,
random_s and donor_s indicators. No-S collapses both indicators to zero.
Standardize with frozen training mean/scale, then sigmoid of linear coefficients;
clip the logit to [-40,40]. Total BER is weighted by actual group sum(K).

## Numerical Notes

Development support is N1024, 64 subcarriers, fixed unit amplitude; no claims for
changed amplitude, resource layout, physical system or code construction. No
reference label, group ID, measured errors or PMF/GA values are model inputs.
Channel estimation and code-state construction costs are outside this function;
timing must state their reuse assumptions. Training p/K/S were constant, so their
effects are not learned. Zero measured errors are not true zero BER.

## Dependencies

No project function calls.

## Health

degraded — candidate model, preserve original precision/speed thresholds and
observed-data development boundary in AGENTS.md and workbook/mandatory-rules.md.
