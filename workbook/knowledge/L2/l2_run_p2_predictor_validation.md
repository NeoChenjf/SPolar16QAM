# L2 · Frozen predictor independent validation

- **flow_id**: l2_run_p2_predictor_validation
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_predictor_validation.m
- **runtime**: long (independent); minutes (smoke)
- **needs_user_run**: true unless current user explicitly authorizes the concrete batch
- **validates**: bounded predictor precision and speed; no new physical hypothesis

## Purpose

Compare a frozen cheap predictor with newly simulated min-sum SC BER/Goodput.

## Pipeline

1. Load frozen model and 18 code-state configurations once.
2. Generate independent 16-tap Rayleigh H with p2_future_seed retest namespaces.
3. Rank carriers into 22/21/21 groups and map each 1024-symbol codeword.
4. l3_p2_predict_cheap: direct channel features and logistic prediction.
5. p2_transmit_block, ofdm_common_noise_roundtrip, p2_decode_block: actual communication.
6. Save group/stream counts, full channel/state raw records and per-cell timers.

## Inputs

Explicit cfg_local: approved, role, channels<=20, frames<=40, max_seconds<=3600,
max_case_frames<=14400; frozen asset. Fixed N1024, n_sc64, CP16, taps16,
reference labels20/24/28; fixed unit-amplitude QAM; actual I/S/F/K from asset.
Independent role uses seen_retest/unseen_retest; smoke uses diagnostic_b and
near-zero noise solely to verify loopback, never precision acceptance.

## Outputs

New timestamp results directory with params, model, source snapshots,
raw per-cell channels/states/group counts, validation.csv, completed.mat, README.
No overwrite or silent resume. Budget exhaustion saves partial cells and stops.

## Acceptance

At least10 eligible independent channels per split, >=20 errors and observed
BER in [1e-4,.1] for multiplicative statistics; median<=2, p90<=5;
Goodput MAE<=.02 over all valid cells; measured per-frame speed>=10.
Report group bias, zero-error denominators and rate ceiling. Partial or
insufficient data are not passing. Never adapt model after observing this batch.
Rules: AGENTS.md and workbook/mandatory-rules.md; stage B4 weekly report.
