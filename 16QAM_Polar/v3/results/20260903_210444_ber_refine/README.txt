v3 BER local refinement with independent runtime seeds
M=[8 16 32 64]; lambda=[0 0.25 0.5]; centers=[8 10 14 16]; offsets=[-0.5 -0.25 0 0.25 0.5 0.75 1]
N=256; frames_per_repetition=30; source_mc_samples=120
source_mc_seed=20260903; snr_mode=fixed_n0
min_repetitions=3; max_repetitions=10
D gate: at least two points with BER in [0.0001,0.1] and >=100 errors each.
Source construction is frozen by source_mc_seed; repetition seeds change payload and AWGN only.
This validates finite-SNR execution and waterfall coverage. Stable lambda ordering still requires confidence analysis before a paper claim.
Zero-error points are retained in CSV and omitted from semilogy.
overall_pass=1
