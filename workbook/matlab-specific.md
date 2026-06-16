# MATLAB Rules

Use this file for MATLAB naming, paths, and code shape. Experiment design and
outputs belong in `code-experiment-standards.md`.

## Naming

- File names must match `[A-Za-z][A-Za-z0-9_]*.m`.
- Use camelCase or snake_case for variables.
- Use uppercase for constants.
- Avoid globals; if unavoidable, prefix with `g_`.

## Script Shape

- Start active scripts with `setup_paths` when project functions are needed.
- Use `%%` sections: config, setup, main loop, outputs, local functions.
- Prefer reusable local functions for repeated logic.
- Add function header comments for reusable functions.

## Paths

- Use relative paths and `fullfile()`.
- Do not hard-code absolute user paths in reusable scripts.
- Save outputs under `cfg.output_dir` or the matching project `results/`
  directory.
- Runnable scripts below `diagnostics/` or `experiments/` must bootstrap the
  project root from `mfilename('fullpath')` before calling `setup_paths()`, so
  they work even when MATLAB's current folder is not `16QAM_Polar/v2`.

## Runtime

- Preallocate arrays before loops.
- Run small checks before long sweeps.
- Do not auto-run long MATLAB jobs without user authorization; see
  `mandatory-rules.md`.

## Figures

- Save paper-use plots as PDF.
- Save review-use plots as PNG.
- For MATLAB figure reuse, save `.fig` when the plot is part of an experiment
  result.

## Change Log

- **2026-05-20**: Added path bootstrap rule for runnable subdirectory scripts.
- **2026-05-20**: Simplified MATLAB rules and removed long examples.
- **2026-02-25**: v2.0 modular workbook created.
