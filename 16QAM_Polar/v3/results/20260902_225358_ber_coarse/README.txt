v3 finite-SNR BER coarse scan
M=[8 16 32 64]
lambda=[0 0.25 0.5]
SNR_dB=[0 2 4 6 8 10 12 14 16 18]
N=256; frames=30; seed=20260903; snr_mode=fixed_n0
source_construction=source_mc_ga; source_mc_samples=120
Purpose: locate BER roughly in [1e-4,1e-1]. This sparse, single-seed coarse scan is not a final BER ordering claim.
Candidate-with-20-errors requires both the BER window and at least 20 aggregate payload errors. Sparse candidates require local reruns.
Zero-error points are preserved in CSV and omitted from semilogy curves.
Energy uses fixed uniform constellation scaling and is an RF-energy proxy.
