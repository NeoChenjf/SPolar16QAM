v3 energy-lambda blocklength comparison
run_mode=formal
M=[8 16 32 64]
lambda=[0 0.25 0.5]
N=[256 1024]
Controlled comparison: frames, source_mc_samples, source_mc_seed, runtime_seed, SNR mode and lambda grid are held fixed across N.
frames=40; source_mc_samples=200; source_mc_seed=20260916; runtime_seed=20260916
snr_mode=fixed_n0; SNR=120 dB; cluster_bootstrap=2000
target: ideal P_X proportional to exp(lambda*|x_scaled|^2); model: fitted latent PMF; empirical: transmitted shaped-polar codewords.
Primary comparisons are empirical-target energy gap and PMF TV; empirical-model metrics separate finite-length loss from target-model fitting loss.
This experiment evaluates PMF and transmit RF-energy proxy only. It does not establish N=1024 BER ordering or rectifier efficiency.
