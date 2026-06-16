# Troubleshooting History - 历史问题记录

**适用范围**：历史问题查询、错误预防  
**强制等级**：⭐ 参考

---

## 使用说明

本文档记录所有已解决的问题，便于未来 Agent 查阅和避免重复踩坑。  
新增问题请追加在对应分类末尾，按时间倒序排列。

### 条目格式
```
### [编号]. [标题]
- **问题**：[描述]
- **触发场景**：[何时/如何触发]
- **解决办法**：[方案与步骤]
- **相关文件**：[路径]
- **日期**：YYYY-MM-DD
```

---

## MATLAB 相关

### 14. MATLAB 图中策略名下划线被渲染为下标
- **问题**：B3 策略对比图直接使用 `good_channel_information` 等内部策略 ID 作为横轴标签和图例标签，MATLAB TeX 解释器会把 `_` 后的字符渲染为下标，导致图中文字显示错误。
- **触发场景**：运行 `run_subcarrier_strategy_compare.m` 生成 `strategy_proxy_summary` 和 `strategy_proxy_vs_snr` 图时触发。
- **解决办法**：保留内部策略 ID 用于 CSV/MAT 数据处理；绘图时统一转换为显示标签，例如 `good channel information`，并对 title/xlabel/ylabel/tick label/legend 显式设置 `Interpreter` 或 `TickLabelInterpreter` 为 `none`。
- **相关文件**：`16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m`，`workbook/code-experiment-standards.md`
- **日期**：2026-06-02

### 13. 局部 p 列表扩展后绘图颜色数组越界
- **问题**：`run_find_waterfall_and_refine.m` 将 `local_p_list` 扩展为 5 个 p 后，局部复验仿真已完成，但绘制 `local_waterfall_curve` 时报错“位置 1 处的索引超出数组边界(不能超出 1)”。
- **触发场景**：粗扫仍使用 `p_list = 0.5`，因此 `colors = lines(nP)` 只生成 1 行颜色；局部绘图循环使用 `nP_local = 5`，访问 `colors(ip,:)` 时越界。
- **解决办法**：
  1. 将粗扫颜色表和局部颜色表分离为 `colors_coarse = lines(nP)` 与 `colors_local = lines(nP_local)`；
  2. 新增 `recover_waterfall_outputs_from_csv.m`，可从已完成的 CSV 恢复 `figures/*.png/pdf/fig` 和 `README.txt`，避免重跑 SC 仿真。
- **相关文件**：`16QAM_Polar/v2/experiments/sc_checks/run_find_waterfall_and_refine.m`，`16QAM_Polar/v2/experiments/sc_checks/recover_waterfall_outputs_from_csv.m`
- **日期**：2026-05-20

### 12. 长 SC 瀑布区脚本中途闪退且无中间日志
- **问题**：`run_find_waterfall_and_refine.m` 两次运行只创建结果目录和 `figures/`，没有生成 CSV，MATLAB 中途闪退后无法判断停在哪个 p/SNR 点。
- **触发场景**：粗扫或局部加密阶段运行时间较长，脚本只在阶段完成后统一写 CSV；若 MATLAB 在阶段中退出，所有阶段内进度丢失。
- **解决办法**：
  1. 增加 `diary` 写入 `run_log.txt`；
  2. 增加 `progress_log.txt`，每个 p/SNR 点写 START/DONE；
  3. 粗扫每完成一个点写 `coarse_scan_partial.csv`；
  4. 局部重复每完成一个点写 `local_waterfall_repetitions_partial.csv`；
  5. 将默认局部复验降为基线 p=0.5、较小帧数，先稳定定位窗口，再扩展全 p。
- **相关文件**：`16QAM_Polar/v2/experiments/sc_checks/run_find_waterfall_and_refine.m`，`workbook/code-experiment-standards.md`
- **日期**：2026-05-20

### 11. 下沉实验脚本直接运行时找不到 setup_paths
- **问题**：从 `experiments/sc_checks/` 等子目录直接运行脚本时，MATLAB 当前路径不包含 `16QAM_Polar/v2`，导致 `setup_paths` 未定义。
- **触发场景**：直接运行 `run_find_waterfall_and_refine.m`，报错“在当前文件夹或 MATLAB 路径中未找到 'setup_paths'”。
- **解决办法**：在脚本开头用 `mfilename('fullpath')` 定位脚本目录，向上两级得到 `v2` 根目录，先 `addpath(v2_root)`，再调用 `setup_paths()`。
- **相关文件**：`16QAM_Polar/v2/experiments/sc_checks/run_find_waterfall_and_refine.m`，`workbook/matlab-specific.md`
- **日期**：2026-05-20

### 10. 诊断脚本中 clear 清空流程变量 + SC输出映射错误导致误判
- **问题**：`diagnose_mc_simulation.m` 调用子脚本后出现 `do_step3` 未定义；同时 `test_polar_loopback.m` 将 `SC_decoder` 输出（长度 `K+S`）按 `N` 维索引提取，导致无噪声回环误报大错误。
- **触发场景**：执行 `setup_paths; diagnose_mc_simulation;`。
- **解决办法**：
	1. 去除子测试脚本中的 `clear`，避免清空主流程变量；
	2. 将 `SC_decoder` 输出先回填到 `SI_set` 再提取 `I_set`；
	3. 统一 `SI_set/I_set` 为升序，保持与主链路一致。
- **相关文件**：`16QAM_Polar/v2/diagnose_mc_simulation.m`，`16QAM_Polar/v2/test_bpsk_baseline.m`，`16QAM_Polar/v2/test_polar_loopback.m`。
- **日期**：2026-04-21

### 9. qammod(bit矩阵输入)列优先打包导致仿真先验与理论不一致
- **问题**：`run_layer1_uncoded_ber_reconcile_v2.m` 中把 `nSym x 4` 比特矩阵直接传给 `qammod(...,'InputType','bit')`，在当前 MATLAB 行为下按列优先打包，符号比特分组与“每行一个符号”假设不一致。
- **触发场景**：BER-SNR 对账中理论侧按 `P(b1,b2,b3,b4)` 构建符号先验，但仿真侧实际调制分组错位，导致低SNR与小p区域偏差放大。
- **解决办法**：调制前显式串行化为列向量 `tx_bits_col(1:4:end)=b1 ...`，并用同一 `tx_bits_col` 与 `qamdemod` 输出对比计算 BER。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 8. qamdemod 标签返回为串行向量导致索引越界
- **问题**：`local_build_symbol_prior` 中访问 `labels(m,b)` 报“位置 2 处索引超出数组边界”，因为 `labels` 实际为单列串行比特流而非 `M x 4`。
- **触发场景**：`run_layer1_uncoded_ber_reconcile_v2.m` 在理论分支调用 `qamdemod(constellation,'OutputType','bit')` 后直接按二维标签矩阵使用。
- **解决办法**：增加返回形状兼容处理：若 `labels_raw` 为向量则用 `reshape(labels_raw, bits_per_symbol, []).'` 还原为 `M x bits_per_symbol`；并新增维度断言防止静默错位。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 7. ML 理论分支符号标签与 Gray 映射错位导致 BER 偏差
- **问题**：Layer1 理论 BER 分支使用 `de2bi` 直接构造 16QAM 标签，在 Gray 映射口径下可能与 `qammod/qamdemod` 的实际标签顺序不一致，导致汉明距离统计与先验加权错位。
- **触发场景**：`run_layer1_uncoded_ber_reconcile_v2.m` 的 `local_theory_ber_ml_exact` 中用 `de2bi((0:M-1),...)` 作为标签表。
- **解决办法**：将理论标签改为由 `qamdemod(constellation, ...,'OutputType','bit')` 直接生成，确保理论与仿真共用完全一致的 Gray 映射标签。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 6. Gauss-Hermite 积分硬判决指示函数导致理论曲线台阶化
- **问题**：理论 BER 使用 GH 积分时出现随 SNR“分段重复/台阶化”现象。
- **触发场景**：对 `qamdemod` 硬判决误差（不连续指示函数）直接做 GH 求积。
- **解决办法**：改为判决区域高斯 CDF 精确积分（按矩形区域计算条件判决概率），避免不连续函数求积伪影。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 5. qamdemod 串行 bit 流 reshape 错序导致理论 BER 异常
- **问题**：ML 数值理论中，`qamdemod(...,'OutputType','bit')` 输出的串行 bit 流被错误 reshape，导致 BER 理论几乎不随 SNR 下降。
- **触发场景**：在 `run_layer1_uncoded_ber_reconcile_v2.m` 的理论分支中使用 `reshape(rx_bits, [], 4)`。
- **解决办法**：改为按每4 bit 还原每个符号：`reshape(rx_bits, 4, []).'`，保证 bit 顺序与调制映射一致。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 4. 行列向量形状不一致导致加噪时报错
- **问题**：运行脚本时报错 `矩阵维度必须一致`，定位到 `rx_sym = tx_sym + noise`。
- **触发场景**：`tx_sym` 与 `noise` 分别为行向量/列向量（或形状不一致）时直接相加。
- **解决办法**：在相加前统一转为列向量：`tx_sym = tx_sym(:); noise = noise(:);`，并增加长度一致性检查。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile.m`
- **日期**：2026-04-06

### 3. 噪声生成处使用矩阵乘法导致维度错误
- **问题**：运行无编码对账脚本时报错，`用于矩阵乘法的维度不正确`。
- **触发场景**：`noise = sigma_noise * (randn(...) + 1j * randn(...))`，当 `sigma_noise` 非严格标量时触发维度不匹配。
- **解决办法**：将噪声系数先标量化，再使用按元素乘法：`sigma_noise = mean(sigma_noise(:)); noise = sigma_noise .* (...)`。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile.m`
- **日期**：2026-04-06

### 2. qammod 输入为 logical 导致类型报错
- **问题**：运行无编码对账脚本时报错，`qammod` 第1个输入 `X` 类型为 `logical`，不满足数值类型要求。
- **触发场景**：执行 `run_layer1_uncoded_ber_reconcile.m`，在 `tx_bits` 由布尔比较结果直接拼接后传入 `qammod(..., 'InputType','bit')`。
- **解决办法**：在调制前将比特矩阵显式转换为数值类型：`tx_bits = double([b1, b2, b3, b4]);`。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile.m`
- **日期**：2026-04-06

### 1. MATLAB 文件命名错误
- **问题**：MATLAB 报错"名称必须以字母开头，并且只能包含字母、数字或下划线"
- **触发场景**：在 `16QAM_Polar` 目录中新建脚本 `260120test.m`（文件名以数字开头）
- **解决办法**：重命名为 `test_260120.m`，删除残留非法名文件，周报中记录
- **相关文件**：`16QAM_Polar/test_260120.m`
- **日期**：2026-01-20

---

## 代码错误

### 2. Layer1 理论 BER 近邻近似长期低估仿真
- **问题**：Layer1 无编码对账中，理论 BER 使用高SNR近邻近似，导致 fixed_n0 下与仿真实线存在明显量级偏差，高 SNR 还会触及理论下限。
- **触发场景**：运行 `run_layer1_uncoded_ber_reconcile_v2.m` 后，`ber_theory` 在中高 SNR 段显著低于 `ber_sim`，并在高 SNR 出现裁剪饱和。
- **解决办法**：将理论计算替换为与 `qamdemod` 一致的 ML 数值精确法：二维 Gauss-Hermite 对噪声积分，逐符号调用同一判决器并按先验加权统计汉明损失。
- **相关文件**：`16QAM_Polar/v2/run_layer1_uncoded_ber_reconcile_v2.m`
- **日期**：2026-04-12

### 1. 理论模型将几何增益误施加到全部4路
- **问题**：在仅 bit2/bit4 由 p 控制（`p_fixed=[0.5,NaN,0.5,NaN]`）的结构下，理论函数把几何增益统一施加到4路，导致 p 影响被结构性扭曲。
- **触发场景**：运行 `run_validate_ber_hat_sc_dual.m` 时，理论 Goodput 最优 p 全区间固化为 0.5，且 BER 曲线解释与“二路整形”设定不一致。
- **解决办法**：在 `estimate_ber_hat_sc_dual.m` 新增 `geom_apply_mode`：默认 `shaped_only` 仅对受控路施加几何增益，并保留 `all_bits` 兼容旧口径；同时导出 `B_geom_gain_per_bit` 便于验收。
- **相关文件**：`16QAM_Polar/v2/core/estimate_ber_hat_sc_dual.m`，`16QAM_Polar/v2/run_validate_ber_hat_sc_dual.m`
- **日期**：2026-03-24

---

## 实验设计

### 1. 理论 full-chain BER 合成口径被误读为精确定量预测
- **问题**：纯理论 full-chain 曲线使用 `P_code * R_geo` 相对风险缩放口径，容易被误读为编码侧 BER 与几何侧 BER 的精确联合概率，且与 Monte Carlo full-chain BER 存在数量级偏差。
- **触发场景**：运行 `run_phaseA_sc_theory_fullchain_curves.m` 后，理论 BER 在 `10 dB` 附近接近 `1e-12`，而统一口径 Monte Carlo 中 `p=0.5` 的 BER_mean 约为 `4.724e-1`、`p=0.1` 约为 `1.974e-1`。
- **解决办法**：在 `estimate_ber_hat_sc_dual.m` 新增 `geom_combine_mode`，保留旧 `ratio_scale` 口径，并增加 `independent_union = 1-(1-P_code)(1-P_geo)` 诊断口径；新增 `run_phaseA_sc_theory_combine_sensitivity.m` 对比两种合成方式与 Monte Carlo summary，并在阶段文档中明确理论曲线只用于机制说明，不作为定量验证曲线。
- **相关文件**：`16QAM_Polar/v2/core/estimate_ber_hat_sc_dual.m`，`16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_theory_combine_sensitivity.m`，`周报/阶段A：单载波关键结论.md`
- **日期**：2026-05-22

---

## 环境配置

（暂无记录）

---

## 变更记录

- **2026-02-25**：v2.0 重构，精简格式
- **2026-01-27**：初始创建
