# L2 Experiment: B4b source-entropy partition holdout audit

**Entry:** `16QAM_Polar/v2/experiments/multicarrier/run_b4b_source_partition_holdout_audit.m`  
**Purpose:** Independently evaluate source conditional entropy on legacy GA-prefix versus source-entropy S/I/F sets while preserving K and |S|.

## Pipeline

1. Freeze the new source-S construction with seed 9001 and 200 source codewords.
2. Evaluate entropy with independent seeds 12001, 22001, and 32001, each using 200 source codewords.
3. Compare mean conditional entropy in S/I/F and save per-position entropy plus exact set indices.
4. Emit PNG/PDF, CSV/MAT, README, source snapshot, and SHA-256 manifest in a timestamped result directory.

## Acceptance and limits

- New and legacy sets have identical K and |S| for each p.
- Independent evaluation samples are disjoint from construction samples.
- This diagnoses set allocation; it is not a PMF gate, communication-performance result, or optimality proof.

## Current evidence

`results/20261009_180433_b4b_source_partition_holdout_audit/`; see the plotted S/I/F means and raw CSVs. For p=0.1 the new S/I/F means are approximately 0.054/0.944/0.942, compared with legacy 0.459/0.428/0.541.


## 2026-10-09 Hypothesis coverage link

Additional validation target: l1_probabilistic_shaping#H3, limited to the finite N/p/source-seed regimes stated in that L1 hypothesis.


## 2026-10-09 Hypothesis coverage link

Additional validation target: l1_probabilistic_shaping#H3, limited to the finite N/p/source-seed regimes stated in that L1 hypothesis.
