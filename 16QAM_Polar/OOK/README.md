# OOK shaped polar reproduction

This folder is a clean reproduction entry for the original OOK shaped-polar
code path, based on:

```text
16QAM_Polar/ShapedPolarS/gettest.m
```

## Scope

The reproduction keeps the legacy research口径:

1. `S = ceil(N * (1 - h(p)))`;
2. GA reliability ordering builds shaping, information, and frozen sets;
3. SC decoder generates shaping bits from the shaping prior LLR;
4. polar encoder maps `(S,I,F)` bits to an OOK `0/1` codeword;
5. Gaussian noise is added to the OOK levels;
6. SC decoder recovers information bits;
7. BER and BLER follow the gettest-style p x SNR matrix format.

## gettest-style command

Run the full reproduction from this folder:

```matlab
run('run_ook_gettest_style.m');
```

Full defaults:

```text
p_list = [0.5, 0.7, 0.9]
N = 1024
snr_grid = -5:0.5:10
num_frames = 1000
seed = 42
```

This is the closest entry to `gettest.m`, and it is a long run. It outputs:

```text
ook_gettest_style_BER_matrix.csv
ook_gettest_style_BLER_matrix.csv
ook_gettest_style_curves.mat
figures/ook_gettest_style_BER.png/pdf/fig
figures/ook_gettest_style_BLER.png/pdf/fig
```

Zero BER/BLER values are preserved in CSV/MAT and only floored to `1e-5` in the log-scale figures for visibility.

## Format smoke command

Use a short format check before the full run:

```matlab
ook_overrides = struct('snr_grid', [-5 0 5 10], ...
                       'num_frames', 5, ...
                       'result_tag', 'ook_gettest_style_snr_m5_to_10_smoke');
run('run_ook_gettest_style.m');
```

Latest format-smoke output:

```text
16QAM_Polar/OOK/results/20260704_162754_ook_gettest_style_snr_m5_to_10_smoke/
```

Latest full output:

```text
16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/
```

## Legacy smoke command

`run_ook_reproduce_smoke.m` remains a shorter scaffold smoke using the same
`p_list=[0.5,0.7,0.9]` but coarser SNR and fewer frames.

## Notes

This is a reproduction scaffold, not a final paper-grade sweep unless you run
`run_ook_gettest_style.m` with its full defaults. For BER interpretation, first
locate a non-zero-error waterfall window.

## Change Log

- **2026-07-04**: Ran full `run_ook_gettest_style.m` with `p_list=[0.5,0.7,0.9]`, `SNR=-5:0.5:10`, and `num_frames=1000`; regenerated BER/BLER figures with explicit log-scale y ticks from `1e-5` to `1`. Rule reflection: updated `workbook/troubleshooting-history.md` for log plot tick clarity
- **2026-07-04**: Added `run_ook_gettest_style.m` with `p_list=[0.5,0.7,0.9]`, `SNR=-5:0.5:10`, `num_frames=1000`, gettest-style BER/BLER matrices, and log-scale BER/BLER figures. Fixed `simulate_ook_shaped_polar` override handling. Rule reflection: no new durable rule
- **2026-07-04**: Created OOK reproduction module with smoke entry, core simulator, result output, and figures. Rule reflection: no new durable rule

