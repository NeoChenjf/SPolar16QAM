# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

This is a graduate thesis project on adaptive wireless information-and-energy co-transmission coding. The active implementation is a MATLAB simulation system for 16QAM probabilistic shaping with polar codes, aimed at exploring the BER / Goodput / harvested-energy tradeoff for batteryless 6G IoT scenarios.

Current active code lives under `16QAM_Polar/v2/`. Older scripts remain under `16QAM_Polar/` and should be treated as historical reference unless the user explicitly asks to edit them.

## Startup Rules

Before non-trivial work, read:

1. `workbook/README.md`
2. `workbook/mandatory-rules.md`
3. Task-specific workbook files listed in `workbook/README.md`

Important workbook rules:

- Any code, script, or documentation change must update the relevant `周报/*.md` before closeout.
- Any bug fix must also update `workbook/troubleshooting-history.md`.
- Long-running or high-compute MATLAB simulations must be run by the user locally unless explicitly authorized.
- Before closing any non-trivial task, run the rule reflection check in `workbook/rule-reflection-hook.md` and record the result in the weekly report.
- When explaining theory, code, formulas, or results, start with plain-language intuition, include a simple analogy when useful, then give technical details.

## Common MATLAB Commands

Run from MATLAB unless otherwise noted.

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_single;                       % fast smoke test, minutes
```

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_sweep;                        % full p × SNR sweep, long run; ask first
```

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_sc_theory_vs_sim;             % SC theory-vs-simulation comparison
run_sc_ga_only_curve;             % GA-only SC theory curve
run_find_waterfall_and_refine;    % coarse BER waterfall search, then optional refinement
```

Diagnostics and experiments are on the MATLAB path after `setup_paths`, so they can be called from the `v2` root:

```matlab
cd('16QAM_Polar/v2');
setup_paths;
diagnose_mc_simulation;
run_local_12db_check;
run_single_scl;
run_sweep_scl;
```

There is no separate build system or lint command documented for this repository; validation is by MATLAB smoke tests, diagnostics, and experiment outputs.

## Architecture Overview

`16QAM_Polar/v2/` is organized around a small set of top-level entry scripts and modular simulation components:

- `config.m` is the shared parameter entry point for main flows (`N`, shaping probabilities, SNR grid, frame count, seeds, output paths).
- `setup_paths.m` initializes paths for `core/`, `polar/`, `modulation/`, `analysis/`, `diagnostics/`, and `experiments/`.
- `run_single.m` is the quick validation path.
- `run_sweep.m` is the full BER / Goodput / energy sweep.
- `run_sc_theory_vs_sim.m`, `run_sc_ga_only_curve.m`, and `run_find_waterfall_and_refine.m` support SC theoretical checks and waterfall-window selection.

Core data flow:

1. Four parallel polar-code bit streams are encoded.
2. Bits are serialized into Gray-mapped 16QAM symbols.
3. The AWGN channel is simulated under a shaping parameter `p`.
4. LLRs are computed with either uniform or non-uniform priors.
5. SC/SCL decoders recover each bit stream.
6. Analysis functions compute BER, Goodput, energy, MI, cost, and Pareto curves.

Main modules:

- `core/sim_shaped_polar_16qam.m` contains the end-to-end shaped polar 16QAM simulation.
- `core/compute_energy.m`, `compute_goodput.m`, and `compute_cost.m` define derived metrics.
- `polar/` contains GA reliability estimation plus polar encoder and SC/SCL decoders, including prior-aware decoder variants.
- `modulation/` contains bit serialization and 16QAM LLR functions for uniform and shaped priors.
- `analysis/` contains plotting and sweep-report extraction utilities.
- `diagnostics/` contains quick baseline, loopback, LLR, and Monte Carlo debugging scripts.
- `experiments/` contains stage-specific scripts, including layer1/layer2 reconciliation, SC/SCL checks, and single-carrier closure experiments.

## Experiment and Output Conventions

- Prefer changing shared experiment parameters in `16QAM_Polar/v2/config.m`; one-off experiment overrides may stay in the relevant experiment script but must be recorded in the result README and weekly report.
- Result-producing scripts should write to `16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_experiment_name/`.
- Result directories should include parameters/seeds, data tables or MAT files, figures when produced, and a README or metadata file.
- Long or crash-prone experiments should write logs, progress markers, and partial checkpoints.
- For BER theory-vs-simulation analysis, first locate an informative waterfall region where BER is roughly `1e-4` to `1e-1`; all-zero high-SNR errors are not evidence of an anomaly.
- When judging polar-code throughput or Goodput, check the designed rate ceiling from `N`, `K`, shaping bits, and frozen bits before calling a result poor.

## MATLAB Conventions

- MATLAB file names must match `[A-Za-z][A-Za-z0-9_]*.m`.
- Active scripts that need project functions should call `setup_paths`.
- Runnable scripts below `diagnostics/` or `experiments/` should bootstrap the project root from `mfilename('fullpath')` before calling `setup_paths`, so they work even when MATLAB's current folder is elsewhere.
- Use relative paths and `fullfile()`; do not hard-code absolute user paths in reusable scripts.
- Save paper-use plots as PDF and review-use plots as PNG; save `.fig` when MATLAB figure reuse matters.
