# L3 — `cluster_bootstrap_tv`

- **签名**：`stats = cluster_bootstrap_tv(frame_psym,model_psym,n_boot,seed)`。
- **定义**：以独立帧为 cluster 重采样，输出经验PMF、TV点估计与95%上界；不得将单个polar码字内的符号当作独立Bernoulli样本。
- **健康度**：pending-runtime。
