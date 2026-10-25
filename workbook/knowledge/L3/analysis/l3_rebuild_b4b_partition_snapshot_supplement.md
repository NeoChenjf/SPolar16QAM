# L3 Contract: rebuild_b4b_partition_snapshot_supplement

- **method_id**: l3_rebuild_b4b_partition_snapshot_supplement
- **file_path**: 16QAM_Polar/v2/analysis/rebuild_b4b_partition_snapshot_supplement.m
- **module**: analysis
- **health**: healthy — runtime validation pending

## Signature

out_dir = rebuild_b4b_partition_snapshot_supplement(source_dirs)

- source_dirs: optional cell array of audit result directories; omitted uses the preregistered PMF and blocklength results.
- out_dir: new timestamped companion result directory.

## Purpose

Reconstruct explicit S/I/F indices, source-entropy values, and fingerprints for completed audit results that lack those metadata, without rerunning payload PMF statistics or modifying source results.

## Math / Algorithm

For each result MAT, use its recorded N, p values, source sample count and source seed; set p_vec=[0.5,p,0.5,p] and design sigma to 10^(-20/20). Call l3_build_source_entropy_partition and emit per-index S/I/F membership, source entropy, per-stream sizes/fingerprint, source snapshot, and SHA-256 manifest.

## Numerical Notes

- This is metadata reconstruction, not a PMF-gate rerun.
- Pairing is valid only when the recorded parameters and the exact builder implementation match the original audit.
- Existing source directories are read-only inputs; output creation refuses overwrite.

## Dependencies

- l3_build_source_entropy_partition
- inline MAT/CSV I/O, source snapshot and SHA-256

## Health

healthy — deterministic parameter replay; MATLAB smoke remains required.
