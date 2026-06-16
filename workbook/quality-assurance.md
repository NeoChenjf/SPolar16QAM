# Quality Assurance

Use this file for validation strategy. Output requirements belong in
`code-experiment-standards.md`.

## Validation Ladder

1. Static inspection: paths, parameters, dimensions, output names.
2. Smoke test: minimal frames or existing `quick_*_test.m`.
3. Baseline comparison: compare against a known script/result.
4. Full run: only after the above pass, and only with user approval if long.

## Test Naming

- `test_*.m`: assertions or focused correctness tests.
- `verify_*.m`: consistency or reconciliation checks.
- `quick_*_test.m`: smoke tests before expensive runs.

## Required Checks

- Compare against a baseline when changing behavior.
- Check edge cases when relevant: empty inputs, zero errors, NaN/Inf, extreme
  SNR, and dimension mismatches.
- For BER curves, inspect error counts as well as BER values.
- Treat all-zero Monte Carlo errors as insufficient evidence for BER-gap
  mechanism claims.
- Treat sparse SNR, single-seed, low-frame BER curves as direction checks only.
  Do not infer stable monotonicity, curve crossing, or global `p` ordering from
  one surprising point; first review errors/frames, then rerun local dense SNR
  with repetitions or multiple seeds.

## Change Log

- **2026-05-21**: Added QA rule for sparse single-seed BER curve anomalies.
- **2026-05-20**: Simplified QA rules and added zero-error BER check.
- **2026-02-25**: v2.0 modular workbook created.
