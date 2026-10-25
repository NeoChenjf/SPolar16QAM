# L3 · run_b4b_guardband_policy_test_analysis

- **method_id**: l3_run_b4b_guardband_policy_test_analysis
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_guardband_policy_test_analysis.m
- **module**: experiments/multicarrier
- **health**: healthy; evaluates a previously frozen candidate.

## Signature
Script entry; `b4b_guardband_overrides.test_dir` and `.policy_file` select the independent formal corpus and frozen candidate CSV.

## Purpose / algorithm
Apply each frozen candidate per SNR to the seed2042 summary. Evaluate original BER upper95<=.10 and Goodput lower95>=.25 gates for candidates marked feasible on training; max-Goodput fallbacks are labeled as such. Compute receive-energy difference relative to `uniform_p05`.

## Outputs and boundaries
Timestamped CSV/MAT/README and PNG/PDF/FIG with source and input SHA-256. It does not tune the candidate. Energy is pre-noise receive mean square, not RF-DC conversion.

## Dependencies
`l3_freeze_b4b_guardband_candidate`, `l3_verify_b4b_strict_smoke`.

## Validation
Seed2042 `results/20261009_230741_b4b_guardband_policy_test_analysis/`: all four candidate points at 28/32/36/40 dB pass original communication gates and have positive receive-energy difference; low-SNR fallback points are not claimed as gate passes. MATLAB provenance source path now explicitly receives `.m` suffix.
