# L2 Experiment: B4b shaped-polar blocklength comparison

**Entries:** `run_b4b_shaping_audit.m` (`mode=blocklength`) and `rebuild_b4b_blocklength_comparison.m`  
**Purpose:** Compare N=256 and N=1024 empirical joint-symbol PMF and transmitted-symbol energy under the same source-entropy S + GA I/F construction.

## Inputs and pipeline

- Five p values: 0.5, 0.4, 0.3, 0.2, 0.1.
- Three codeword-level evaluation seeds, 80 frames per seed, 2000 bootstrap resamples.
- Only `message_conditioned` rows enter the new-construction gate and comparison; `legacy_fixed` remains a diagnostic contrast.
- Whole codewords are bootstrap clusters; report target, model, empirical PMF separately.
- Energy proxy is actual transmitted-symbol mean power normalized to the p=0.5 value at each N.

## Acceptance

For each p and N, pooled and each seed's one-sided 95% TV upper bounds must be <=0.05. Do not alter the threshold after observing data. A difference between N=256 and 1024 supports finite-length sensitivity but does not prove asymptotic convergence.

## Current evidence

Raw source directories: `results/20261009_180522_b4b_shaping_audit_blocklength_N256_source_MC_GA/` and `results/20261009_180551_b4b_shaping_audit_blocklength_N1024_source_MC_GA/`. Combined figure/table: `results/20261009_182029_b4b_blocklength_comparison/`.


## 2026-10-09 Hypothesis coverage link

Additional validation target: l1_probabilistic_shaping#H3, limited to the finite N/p/source-seed regimes stated in that L1 hypothesis.
