# Code And Experiment Standards

Use this file for experiment design, parameters, outputs, and reproducibility.
MATLAB syntax/style belongs in `matlab-specific.md`.

## Principles

- Define the goal and acceptance criteria before changing experiment logic.
- Prefer the smallest experiment that can answer the question.
- Keep theory口径, simulation chain, and SNR definition stable during a same口径
  validation.
- Record random seeds and key parameters.

## Parameters

- Prefer `config.m` for shared parameters.
- Script-local overrides are allowed for one-off experiments, but must be
  written to the result README.
- If using weighted objectives, record weights, normalization, and why they were
  chosen.

## Result Directory

Every result-producing script should write to:

```text
results/YYYYMMDD_HHMMSS_experiment_name/
```

Include:
- `README.txt` or metadata;
- CSV/MAT data tables;
- figures as PNG/PDF when plots are produced;
- `.fig` when MATLAB figure reuse matters;
- enough parameters and random seeds to reproduce.

Long or crash-prone experiments must also write:
- `run_log.txt` or equivalent console diary;
- `progress_log.txt` with start/done markers for each expensive point;
- partial CSV checkpoints after each completed point or repetition.

If an experiment has both search and refinement stages, default to a short
search-only mode. Run expensive refinement only after the search window is
reviewed.

## Figure Provenance

If a figure mixes data from different statistical口径, such as old global
sweep lines plus local recheck mean/CI overlays, label it as an explanatory
overlay figure in the README and report. Do not present it as a statistically
uniform final paper curve. For paper main curves, use one unified run口径 for
all plotted points.

If a figure is generated from a pure theory or analytical model, label it as a
theory/model-prediction figure in the README and report. Do not present it as a
Monte Carlo validation curve, and do not use it to replace same口径 simulation
results.

For analytical BER composition, explicitly state whether the formula is a
relative-risk scaling, an independent-event union, or a simulation-calibrated
fit. Do not describe a relative ratio correction as an exact end-to-end BER
probability.

## MATLAB Figure Labels

For MATLAB figures, do not pass internal identifiers with underscores directly
to visible tick labels, legends, titles, axis labels, or annotations. Convert
labels such as `good_channel_information` to display text such as
`good channel information`, or explicitly set the relevant interpreter to
`none`. This prevents MATLAB's TeX interpreter from rendering unintended
subscripts.

## OFDM Spectrum Figures

For Stage B OFDM spectrum diagnostics, distinguish PSD figures from frequency
resource-grid figures:

- PSD figures must plot frequency on the x-axis and power spectral density on
  the y-axis.
- If guard bands are part of the visual check, show the full occupied-plus-guard
  band shape instead of truncating to active subcarriers only.
- For TX/RX PSD comparisons across shaping settings, use a matched panel layout:
  one column per `p`, TX on the top row and RX on the bottom row.
- Record any visualization-only oversampling or zero padding in the result
  README and weekly report, and state that it does not change BER/Goodput
  simulation logic.

## BER Theory-vs-Simulation Experiments

Always save:

- coarse scan table explaining how the SNR window was selected;
- local refinement table;
- repetition-level raw table;
- README summary with target BER window, selected SNR window, gap, CI, and
  conclusion label.

If the selected window has all-zero errors, keep the result directory and mark
the conclusion as: window too high; move to lower SNR.

## Composite Transmission

For mixed schemes such as half baseline `p=0.5` and half candidate `p`:

- compute effective Goodput and energy by arithmetic average;
- save the effective tables;
- document the formula in the weekly report.

## Change Log

- **2026-06-02**: Added MATLAB figure label rule to prevent internal names with
  underscores from rendering as unintended TeX subscripts.
- **2026-05-24**: Added Stage B OFDM spectrum figure rules for PSD axes,
  guard-band visibility, TX/RX panel layout, and visualization-only metadata.
- **2026-05-22**: Added figure provenance rule for pure theory/model-prediction curves.
- **2026-05-22**: Added analytical BER composition rule for relative-risk versus independent-event formulas.
- **2026-05-21**: Added figure provenance rule for mixed global/recheck overlay plots.
- **2026-05-20**: Added logging and partial-checkpoint requirements for long or crash-prone experiments.
- **2026-05-20**: Added two-stage search/refinement rule for long experiments.
- **2026-05-20**: Simplified experiment standards and kept BER windowing output rule.
- **2026-05-20**: Added BER theory-vs-simulation output requirements.
- **2026-02-25**: v2.0 modular workbook created.
