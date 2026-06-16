# Data Management

Use this file for data safety, result storage, and large files.

## Sensitive Files

- Do not commit credentials, API keys, private data, or personal secrets.
- Use template files for credentials and document how to fill them locally.

## Large Files

- Keep large `.mat`, `.bin`, `.h5`, and bulky result files out of normal source
  control unless intentionally managed.
- Prefer external storage, Git LFS, or regeneration scripts for large datasets.

## Results

- Store experiment outputs under timestamped `results/` directories.
- Keep parameters, random seeds, README/metadata, and result tables together.
- Do not overwrite old result directories unless the user explicitly asks.

## Backups

- Preserve important experiment outputs before cleanup or restructuring.
- If a result supports a report or thesis figure, keep the data table and figure
  source together.

## Change Log

- **2026-05-20**: Simplified data management rules.
- **2026-02-25**: v2.0 modular workbook created.
