# L3 — `paired_cluster_difference_ci`

- **签名**：`stats = paired_cluster_difference_ci(frame_low,frame_high,n_boot,seed)`。
- **定义**：先按帧形成 `high-low` 配对差，再重采样完整帧差，输出均值和单侧95%下置信界。
- **用途**：判断相邻 lambda 的经验平均发送RF能量代理是否可靠增加；不得把码字内部符号当iid样本。
- **健康度**：implemented-pending-runtime。
