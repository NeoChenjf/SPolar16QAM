# L2 · v3 通用 Gray-QAM BER coarse

- **flow_id**：`l2_v3_gray_qam_ber_coarse`
- **entry**：`summary = run_gray_qam('ber_coarse')`
- **runtime**：medium/long
- **needs_user_run**：true

## 目的

在不改变已通过的星座、energy-lambda、source-MC+GA、SC和fixed_n0口径下，仅扫描有限SNR，寻找BER约`1e-4~1e-1`的信息瀑布候选区。该入口是搜索阶段，不是最终BER曲线。

## 配置

- M=8/16/32/64，lambda=0/0.25/0.5。
- N=256，30帧，source-MC样本120，seed=20260903。
- SNR=`0:2:18 dB`，`fixed_n0`。

## 产物

时间戳`results/*_ber_coarse/`内保存逐点BER/BLER/errors/frames、每流错误数、码率、Goodput、能量、候选窗口、MAT/checkpoint、run/progress log及PNG/PDF/FIG。

## 验收与边界

- `in_waterfall`要求BER位于`[1e-4,1e-1]`；稳定候选另要求至少20个聚合payload错误。
- 全零错误点保留原始计数，绘图时置空，不伪造BER floor。
- sparse单seed曲线只能选局部窗口；审核后必须局部加密/重复，才能讨论曲线排序或交叉。

## 健康度

coarse-pass（`20260903_160356_ber_coarse`）：12个M/lambda组合均找到1个≥20错误的候选点，中心依次为8/10/14/16 dB；尚不满足D门禁要求的至少2个有效点。
