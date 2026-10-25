# L2 Experiment: B4b partition snapshot supplement

- **flow_id**: l2_b4b_partition_snapshot_supplement
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_partition_snapshot_supplement.m
- **runtime**: minutes
- **needs_user_run**: true
- **validates**: l1_multicarrier_ofdm#H2

## Purpose

Reconstruct explicit S/I/F indices, source-entropy estimates, and per-stream fingerprints for completed PMF/blocklength audit result directories whose original outputs predate partition-index export. This is provenance completion; it does not rerun payload PMF or BER statistics.

## Pipeline

| # | step | l3_ref | description |
|---|---|---|---|
| 1 | Load each audit MAT and frozen source settings | inline | Read N, p values, source sample count/seed, and source result directory |
| 2 | Rebuild fixed-count source-S and design-sigma GA partition | l3_build_source_entropy_partition | Preserve the audit's fixed source seed and sigma |
| 3 | Write per-index S/I/F, entropy, K/S/F counts, and fingerprints | inline | Write companion CSV/MAT without modifying source result folders |
| 4 | Snapshot sources and compute SHA-256 manifest | inline | Include the v2 builder and v3 exact source-SC dependencies |

## Inputs

- Completed B4b audit result directories containing b4b_shaping_audit.mat.
- Recorded N, p values, source_samples, source_seed; design sigma is fixed to 10^(-20/20) as in the audit runner.

## Outputs

- New timestamped results/YYYYMMDD_HHMMSS_b4b_partition_snapshot_supplement/.
- partition_indices.csv, partition_summary.csv, source_entropy_by_index.csv, MAT, README, source snapshot, and SHA-256 manifest.

## Acceptance

- Each reconstructed partition has pairwise-disjoint S/I/F whose union is 1:N.
- K, |S|, |F| and fingerprints match the source construction contract.
- Source directory paths are recorded; the original audit results are not modified.
- Do not interpret metadata reconstruction as a rerun or validation of the PMF gate.
- This flow does not establish asymptotic convergence, BER accuracy, equal-power fairness, or RF-to-DC gain.

## Weekly Report

- 周报/阶段B/B4：full-chain策略验证.md


## 2026-10-09 验证目标勘误（追加）

本流程的有效验证目标为l1_probabilistic_shaping#H3（有限长度、指定p范围内源熵S集合可评估且元数据可复现）。它仅补全分区元数据，不单独验证自适应OFDM策略优越性；此前头部的l1_multicarrier_ofdm#H2标签不适用。


## 2026-10-09 Pipeline and validation-link correction

The run_ entry script delegates reconstruction to l3_rebuild_b4b_partition_snapshot_supplement in module analysis. The valid research target remains l1_probabilistic_shaping#H3; the initial l1_multicarrier_ofdm#H2 label above is superseded. This metadata supplement does not validate adaptive strategy superiority.
