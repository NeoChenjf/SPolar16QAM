# L3: `freeze_b4b_guardband_candidate`

**Signature:** `freeze_b4b_guardband_candidate(training_dir)`.

**Inputs:** completed formal B4 training `b4b_strategy_summary.csv` with the six registered strategies and confidence intervals.

**Selection:** each SNR chooses maximum receive energy subject to training BER upper95 <=0.08 and Goodput lower95 >=0.27. When no option satisfies both, it records a maximum-Goodput fallback. These margins are fixed at 0.02 inside the original 0.10/0.25 evaluation gates.

**Outputs and boundary:** new timestamped directory with frozen `policy_selection.csv`, copied training summary, README, source snapshot/hash. It must run before opening the seed2042 independent result. It does not itself validate the policy.

## 2026-10-09 implementation hardening

The helper now verifies `b4b_strict_ofdm_rayleigh.mat` records formal mode, seed42, 30 realizations, six strategies, and the same SNR grid before it freezes any policy. The training MAT file is copied and included in the output hash manifest. This protects F18 from accidentally consuming the old B4 codebook or a pilot/holdout directory.

## 2026-10-09 registered source-entropy candidate

Training input: `results/20261009_203109_b4_source_entropy_formal/`; output: `results/20261009_210928_b4b_guardband_candidate_frozen/`. Before any independent result was inspected, the helper froze the strategy per SNR with training gates BER upper95<=.08 and Goodput lower95>=.27, choosing maximum receive-energy among feasible entries, otherwise maximum Goodput. Selection: uniform_p05 at 20/24; good_channel_information at 28; good_channel_energy_shaping at 32; uniform_p01 at 36/40. The first attempt wrote under `experiments/results/` because its root-path walk omitted one parent; that artifact is retained, and the corrected result is in v2/results. This helper freezes a rule only; validation is supplied by the separate seed2042 analysis.
