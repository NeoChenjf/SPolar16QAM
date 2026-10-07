# v3：通用 Cartesian Gray-QAM shaped-polar

v3 是面向 8/16/32/64QAM 的单载波 multi-stream BICM 扩展；它不修改 v2，也不声称与参考论文的单整体 polar graph 有限长等价。

当前已实现 Unit 0 的星座、GF(2) relation、理想 PMF、latent MAP/LSE LLR、auto relation 搜索、消息条件化 SC，以及 `source='latent_p'` / `source='energy_lambda'` 的单载波 multi-stream 端到端路径。当前主流程以 source-MC 估计低条件熵 S 位、排除 S 后用 GA 划分 I/F；它是数值构造，不是参考论文单整体 polar graph 的有限长严格复现。

统一入口（默认仅 PMF smoke，依次运行 8/16/32/64QAM 并生成时间戳结果目录）：

```matlab
setup_paths
summary = run_gray_qam
```

能量参数 smoke（`lambda=[0,0.25,0.5]`，依次运行 8/16/32/64QAM；保存 target/model/empirical PMF、拟合误差、逐帧配对能量区间和 PNG/PDF/FIG）：

```matlab
summary = run_gray_qam('energy_smoke')
```

该入口的能量指固定均匀缩放下的平均发送 RF 能量代理，不是整流器收获能量。它可能运行数分钟，正式执行由用户本地完成。

有限SNR BER coarse（只用于寻找`1e-4~1e-1`瀑布区，不作为最终曲线排序）：

```matlab
summary = run_gray_qam('ber_coarse')
```

coarse覆盖`SNR=0:2:18 dB`和三个lambda，保存每点errors/frames、候选窗口、checkpoint以及PNG/PDF/FIG。零错误点保留在CSV中，但不画成伪造的BER下限。

coarse窗口审核后使用局部加密入口：

```matlab
summary = run_gray_qam('ber_refine')
```

refine按M使用中心`[8,10,14,16] dB`及偏移`-0.5:0.25:1 dB`，固定source-MC构造seed，只改变payload/AWGN seed；至少3次、至多10次独立重复，目标是每个M/lambda至少两个点落在`1e-4~1e-1`且各累计不少于100个payload错误。

64QAM正式PMF补充门禁（N=1024、80帧；其他M已在energy smoke达到正式阈值）：

```matlab
summary = run_gray_qam('pmf_formal64')
```

受控比较 `N=256/1024` 与理想目标/latent模型/真实码字的PMF和发送能量：

```matlab
summary = run_gray_qam('blocklength_compare_smoke')  % 仅验证入口
summary = run_gray_qam('blocklength_compare')        % 正式运行，需用户本地执行
```

正式模式保持帧数、source-MC样本数、构造seed、运行seed、lambda网格和SNR口径一致，
只改变码长。输出分别保留 `target`、`model` 和 `empirical`，并同时报告
empirical-to-target 与 empirical-to-model 的TV距离，用于区分模型拟合误差和有限长实现误差。

本地验证入口：

```bash
scripts/run_matlab_v3.sh test_unit0_gray_qam
scripts/run_matlab_v3.sh test_unit0_forced_sc
scripts/run_matlab_v3.sh test_unit0_noiseless_roundtrip
scripts/run_matlab_v3.sh test_unit0_pmf_relation
scripts/run_matlab_v3.sh test_unit0_bsc_ga_partition
```

结果目录、验收门禁和执行进度见：

```text
学习文档/高阶调制理论/通用GrayQAM-loop/
```
