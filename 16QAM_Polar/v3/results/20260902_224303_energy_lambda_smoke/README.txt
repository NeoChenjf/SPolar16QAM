v3 energy-lambda smoke
M=[8 16 32 64]
lambda=[0 0.25 0.5]
target P_X proportional to exp(lambda*|x_scaled|^2); positive lambda favors outer points.
uniform constellation scaling is fixed; no shaped-PMF renormalization.
snr_mode=fixed_n0; SNR=120 dB; N=256; frames=40; seed=20260902
source_construction=source_mc_ga; source_mc_samples=120; paired_bootstrap=2000
Pair acceptance: model energy strictly increases and paired independent-frame bootstrap lower95(high-low)>0.
Target-model acceptance: exact KL<=1e-10 and TV<=1e-8; approximate-pass KL<=0.02 nat and TV<=0.05.
Empirical PMF smoke acceptance: cluster-bootstrap TV upper95<=0.10.
Energy is average transmit RF-energy proxy, not rectifier harvested energy.
overall_pass=1
