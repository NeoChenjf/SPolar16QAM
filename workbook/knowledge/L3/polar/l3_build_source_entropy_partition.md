# L3 Contract: `build_source_entropy_partition`

**Source:** `16QAM_Polar/v2/polar/build_source_entropy_partition.m`  
**Status:** healthy with finite-sample/decoder-metric limits

## Purpose

Build a fixed-count S/I/F partition for four bit streams. For each Bernoulli source parameter, estimate source conditional entropies, choose S from the lowest-entropy positions, then choose I/F from the remainder using GA channel reliability at the supplied design sigma.

## Signature

`partition = build_source_entropy_partition(N, p_vec, sigma_design, n_samples, seed)`

- `N`: power-of-two block length.
- `p_vec`: four source probabilities in `(0,1)`.
- `sigma_design`: positive AWGN design standard deviation used only for the helper's initial GA I/F partition.
- `n_samples`, `seed`: source-entropy Monte Carlo budget and reproducible seed; defaults are 200 and 9001.

## Invariants

- $S_b$, $I_b$, and $F_b$ are mutually exclusive and complete over `1:N`.
- $|S_b|=\lceil N(1-H_2(p_b))\rceil$ and $K_b=|I_b|=\lceil(N-|S_b|)/2\rceil$.
- S is sorted by estimated source conditional entropy; I/F are GA-ranked after removing S.
- Source entropy uses exact sum-product SC likelihoods from the v3 helper, but the entropy values are Monte Carlo estimates.
- A deterministic fingerprint is metadata only; use SHA-256 manifests for artifact integrity.

## Important call-site rule

The returned I/F are a design-sigma snapshot. Communication simulations with per-SNR construction must preserve S and recompute I/F from the current SNR's GA ordering after excluding S. Do not reuse the helper's I/F across SNR unless that fixed-code experiment is explicitly intended.

The helper does not establish target-PMF exactness, asymptotic convergence, receiver prior matching, equal-power fairness, or RF-to-DC conversion.

## Evidence

- Independent source entropy holdout: `results/20261009_180433_b4b_source_partition_holdout_audit/`.
- N=256/1024 PMF/energy comparison: `results/20261009_182029_b4b_blocklength_comparison/`.
- N=1024 formal joint-PMF gate: `results/20261009_175322_b4b_shaping_audit_formal_source_N1024_source_MC_GA/`.
