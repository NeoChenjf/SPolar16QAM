
## 2026-10-09 append-only contract update — post-process Phase A figures

`analysis/rebuild_phaseA_figures_from_energy_results.m` accepts only a completed and audited energy-tradeoff result directory. It performs no Monte Carlo; it creates an independent timestamped result directory containing F04/F05/F07 exports, a copy of the numerical summary and the hashes of its source CSV and plotting function. F04 shows full-chain BER with the source run's three-seed confidence intervals; F05 plots Goodput against measured transmit RF energy; F07 isolates label=14 dB. The source README's SNR conversion and RF-proxy boundary must remain visible in interpretation. This helper supplements, and does not replace or overwrite, the source run's F06/F08/F09 figures.
