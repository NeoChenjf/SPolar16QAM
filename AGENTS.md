# Codex Harness

`workbook/` is the project rulebook. This file is only the short entrypoint for
agents working in this repository.

## Startup

Before non-trivial work, read:

1. `workbook/README.md`
2. `workbook/mandatory-rules.md`
3. Task-specific workbook files listed in `workbook/README.md`
4. `next_plan.md`
5. The relevant stage document under `周报/`

If rules conflict, follow `workbook/mandatory-rules.md`.

## Current Stage Entry

- Current phase: Stage B, multicarrier OFDM construction.
- Stage B index: `周报/阶段B/阶段B：多载波系统构建.md`
- Current task document: `周报/阶段B/B1：OFDM baseline阶段文档.md`
- Next code target: `16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m`

Stage documents are the working source of truth for research scope,
acceptance criteria, and result interpretation. Keep them concise and update
the relevant one before closing a task.

## Project Map

- Active code: `16QAM_Polar/v2/`
- Main config and entries: `16QAM_Polar/v2/config.m`, `setup_paths.m`,
  `run_single.m`, `run_sweep.m`
- Core modules: `core/`, `polar/`, `modulation/`, `analysis/`
- Checks and experiments: `diagnostics/`, `experiments/`
- Stage B experiments should live under `experiments/multicarrier/`
- Results: `16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_*`
- Reports and stage docs: `周报/`
- Stage B docs: `周报/阶段B/`
- Operating rules: `workbook/`

## Non-Negotiables

- Any code, script, or doc change must update the relevant `周报/*.md` or
  stage document under `周报/阶段B/`.
- Any bug fix must also update `workbook/troubleshooting-history.md`.
- Long MATLAB simulations must be run locally by the user unless explicitly
  authorized.
- Results-producing scripts must save parameters/data/figures/README under a
  timestamped `results/` directory.
- Do not modify `config.m` for experiment-specific overrides; use `cfg_local`.
- For BER theory-vs-simulation work, first locate an informative waterfall
  region. An all-zero-error SNR window is not evidence for a BER anomaly.
- For Stage B, do not claim a multicarrier strategy is best until it is compared
  against the three planned baselines: good-channel information, good-channel
  energy shaping, and bad-channel pure energy transfer.
- Before finishing any non-trivial task, run the rule reflection hook in
  `workbook/rule-reflection-hook.md`.

## Common Commands

Run from `16QAM_Polar/v2/`:

```matlab
setup_paths; run_single;                    % fast smoke test
setup_paths; run_sweep;                     % long full sweep
setup_paths; run_sc_theory_vs_sim;          % SC theory-vs-sim entry
setup_paths; run_find_waterfall_and_refine; % auto waterfall search
run('experiments/multicarrier/run_ofdm_baseline.m'); % planned Stage B/B1 entry
```
