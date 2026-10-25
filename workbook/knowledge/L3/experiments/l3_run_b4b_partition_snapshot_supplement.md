# L3 Contract: run_b4b_partition_snapshot_supplement

- **method_id**: l3_run_b4b_partition_snapshot_supplement
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_partition_snapshot_supplement.m
- **module**: experiments
- **health**: healthy — provenance-only runner; MATLAB regression pending

## Signature

run_b4b_partition_snapshot_supplement(source_dirs)

- source_dirs: optional cell array of audit result directory paths; defaults to the preregistered formal N=1024 and blocklength N=256/1024 outputs.
- out_dir: timestamped companion result directory.

## Purpose

Reconstruct explicit S/I/F indices and source conditional entropy metadata for completed shaping audits that did not originally export those positions, without rerunning the payload PMF Monte Carlo or modifying the source directories.

## Math / Algorithm

For each source directory and p value, set p_vec=[0.5,p,0.5,p], use the recorded N, source sample count, and source seed with design sigma 10^(-20/20), and call l3_build_source_entropy_partition. Emit one row per (stream,set,index), per-index entropy, and a per-stream K/S/F-size/fingerprint summary. Copy implementation dependencies and write SHA-256 hashes.

## Numerical Notes

- This recreates metadata only. It is valid as paired provenance only if the source audit used the same N, p_vec, sigma, source sample count/seed, and exact helper implementation.
- It does not re-evaluate or upgrade the PMF confidence gate.
- The runner refuses to overwrite an existing timestamped output directory.

## Dependencies

- l3_build_source_entropy_partition
- inline result loading, CSV/MAT writing, source snapshot, and SHA-256 output

## Health

healthy — deterministic source parameters; execution and output-table types still require MATLAB smoke validation.


## 2026-10-09 Contract metadata correction

The runner in experiments/ is an L2 entry, not this L3 method. The atomic helper is now located at 16QAM_Polar/v2/analysis/rebuild_b4b_partition_snapshot_supplement.m with signature rebuild_b4b_partition_snapshot_supplement(source_dirs); its valid method_id is l3_rebuild_b4b_partition_snapshot_supplement and module is analysis. The initial header above is superseded by this correction; the L2 runner calls this helper.


## 2026-10-09 Superseded contract notice

This draft described the run_ workflow as an atomic L3 method and used unsupported module=experiments. It is retained for append-only history and is no longer an active contract. The current valid atomic contract is l3_rebuild_b4b_partition_snapshot_supplement in ../analysis/l3_rebuild_b4b_partition_snapshot_supplement.md; the experiment entry is governed by L2.
