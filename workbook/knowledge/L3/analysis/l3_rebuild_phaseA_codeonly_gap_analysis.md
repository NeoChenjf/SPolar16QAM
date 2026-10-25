# L3: `rebuild_phaseA_codeonly_gap_analysis`

**Signature:** `rebuild_phaseA_codeonly_gap_analysis(source_dir)` consumes a completed F19 result directory.

**Contract:** no simulation is run. Recomputes five-repetition Student-t (df=4) intervals from raw repetition records, pairs those empirical means with the stored GA/BER estimate, reports per-point simulation-to-estimate ratios and raw error/frame totals, and exports the theory/simulation and log-gap figures. Copies the inputs and records SHA-256 provenance in a new timestamped result directory.

**Interpretation boundary:** the estimate is not fitted to this validation set. A large gap is reported as model error, not corrected by an empirical scale factor. The source run's plain-SC/no-added-source-prior receiver and actual S/I/F indices are recorded. Zero-error repetitions do not establish a BER floor.
