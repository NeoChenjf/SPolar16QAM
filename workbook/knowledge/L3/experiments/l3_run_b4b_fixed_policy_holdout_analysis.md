# L3 · run_b4b_fixed_policy_holdout_analysis

- **method_id**: l3_run_b4b_fixed_policy_holdout_analysis
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_fixed_policy_holdout_analysis.m
- **module**: experiments/multicarrier
- **health**: healthy; consumes a policy frozen on training data.

## Signature
Script entry; override with `b4b_holdout_overrides.training_dir` and `.holdout_dir`, optionally original BER and Goodput gates.

## Purpose / algorithm
Read the frozen six-entry `policy_selection.csv` from training and apply it unchanged to the independent holdout summary. Calculate BER upper95, Goodput lower95, energy difference against `uniform_p05`, and gate margins. Training fallbacks remain labeled and are not claimed as communication-gate passes.

## Outputs and boundaries
Timestamped CSV/MAT/README and PNG/PDF/FIG with source/input hashes. Never select or tune policy using holdout. Receive energy is not RF-DC output.

## Dependencies
`l3_run_b4b_paired_policy_analysis`, `l3_verify_b4b_strict_smoke`.

## Validation
Seed1042 `results/20261009_223148_b4b_fixed_policy_holdout_analysis/`: 28–40 dB satisfy registered confidence-bound gates; 20/24 dB are training-set max-Goodput fallbacks. Source snapshot path normalization was necessary for MATLAB script filenames.
