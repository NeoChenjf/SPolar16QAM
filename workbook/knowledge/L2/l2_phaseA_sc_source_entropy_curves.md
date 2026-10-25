# L2 Experiment: Phase A source-entropy code-only curves

**Entry:** `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_final_global_curves.m`  
**Purpose:** Generate code-only BER theory/simulation curves with fixed source-entropy S and per-SNR GA I/F reconstruction; optional full-chain mode retains the same per-SNR construction.

## Protocol

- Source entropy: 200 samples, seed 9001, design sigma -20 dB; S remains fixed across the SNR grid.
- At each SNR, rank GA channels and choose I/F from positions outside S.
- In every frame, condition the S precoder on the current payload with F=0.
- Decoder remains the configured existing SC path. The approximate GA model does not include the complete joint effect of message-conditioned shaping and the receiver metric.
- Full-chain BER/Goodput can be supplied from the shared rectifier-energy formal run to avoid duplicating Monte Carlo; the code-only sweep is separate.

## Output and status

Timestamped results include code-only repetitions, summary, theory comparison, README, source snapshot and hashes. A one-frame smoke at N=1024 and three p values passed the source-S/GA-I/F code path; it is not formal evidence. Formal curves remain pending.


## 2026-10-09 理论集合审计输出

Code-only结果另保存codeonly_theory_partition_indices.csv及MAT内code_I_sets/code_partitions，逐p、SNR、bit-stream记录固定源S、当前GA选择I、K/|S|和指纹。该接口保证估计器的I索引可检查，不代表近似模型已经定量准确；需结合理论—模拟瀑布区差异报告适用范围。
