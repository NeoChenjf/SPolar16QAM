# L2 · v3 通用 Gray-QAM BER局部加密

- **flow_id**：`l2_v3_gray_qam_ber_refine`
- **entry**：`summary = run_gray_qam('ber_refine')`
- **runtime**：medium/long
- **needs_user_run**：true

## 目的

围绕coarse确定的8/10/14/16 dB中心，对四种M和三个lambda作0.25 dB局部加密及独立重复，验证AWGN D门禁覆盖；不把该任务等同于最终lambda优劣证明。

## 配置与自适应停止

- 每个M的SNR为`center+(-0.5:0.25:1.0)`。
- N=256，每次重复30帧，至少3次、至多10次。
- 每个M/lambda至少有2个点满足BER在`[1e-4,1e-1]`且累计错误数≥100后停止。
- `source_mc_seed=20260903`冻结S/I/F构造；每次重复使用独立运行seed，仅改变payload与AWGN。

## 产物

时间戳`results/*_ber_refine/`保存重复级原始表、聚合表、D门禁表、MAT/checkpoint、run/progress log及PNG/PDF/FIG。

## 健康度

refine-pass（`20260903_210444_ber_refine`，overall_pass=1）：12组均有5–7个有效D点，最低有效错误数104。
