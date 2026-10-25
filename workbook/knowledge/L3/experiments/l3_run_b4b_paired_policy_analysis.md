# L3 · run_b4b_paired_policy_analysis

- **method_id**: l3_run_b4b_paired_policy_analysis
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_paired_policy_analysis.m
- **module**: experiments/multicarrier
- **health**: healthy after source-path normalization; output is descriptive training evidence.

## Signature
Script entry; optional `b4b_analysis_overrides.source_result_dir`, `reference_strategy`, `ber_limit`, `goodput_floor`, and `result_tag`.

## Purpose / algorithm
Load repetition-level B4 data; pair each candidate to `uniform_p05` by SNR and Rayleigh realization. Compute paired candidate-minus-reference differences and 95% intervals, per-strategy means/intervals, non-dominated points, and a low-complexity per-SNR policy. Select max pre-noise receive energy among entries passing training BER upper95<=.10 and Goodput lower95>=.25; when none passes, choose max mean Goodput and label fallback.

## Outputs and numerical notes
Timestamped result with paired CSV, strategy summary, policy CSV, Pareto CSV, MAT, README, PNG/PDF/FIG, source snapshot and SHA-256. Same training corpus is used for policy selection, so it is not independent evidence. Energy is a received RF mean-square proxy, not DC harvesting.

## Dependencies
`l3_verify_b4b_strict_smoke` (input contract), MATLAB table/statistics and plotting functions.

## Validation
`results/20261009_210714_b4b_source_entropy_training_policy_analysis/`; 1080 input rows, 90 paired rows, 36 strategy/SNR summaries and 6 policy rows. The provenance copy required an explicit `.m` suffix because `mfilename('fullpath')` omits it.
