# L3: `test_source_entropy_partition`

**Signature:** runnable MATLAB diagnostic script at `16QAM_Polar/v2/diagnostics/test_source_entropy_partition.m`.

**Contract:** checks S/I/F disjointness, completeness and cardinalities; verifies design-sigma and per-SNR GA top-K I selection after excluding actual S; tests all-zero, all-one and two seeded random payloads through the message-conditioned source precoder and noiseless SC recovery; saves a timestamped evidence directory.

**Boundary:** this deterministic check verifies indexing and noiseless correctness only. It does not validate noisy BER predictions, PMF gate bounds, or asymptotic convergence. It uses existing SC and does not add a decoder.
