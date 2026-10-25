# L2 · B4b 整形机制审计

- **flow_id**: l2_b4b_shaping_mechanism_audit
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_shaping_audit.m
- **runtime**: long（pmf/blocklength）；static/smoke为秒级
- **needs_user_run**: true（正式pmf或扩大预算；本轮20帧/seed短诊断实测约30秒）
- **validates**: l1_multicarrier_ofdm#H2 的编码与分布前置条件；不验证策略排序

## Purpose

对比B4b固定整形位实现与按payload条件化的SC整形，审计S/I/F集合、无噪声信息位恢复和经验16QAM PMF，为等平均发射功率的后续比较建立可信基线。

## Pipeline

| # | step | l3_ref | 说明 |
|---|---|---|---|
| 1 | 构造与核对B4b S/I/F集合 | l3_sim_shaped_polar_16qam | 使用B4b GA排序及ceil码率口径，断言集合互斥和完备 |
| 2 | 生成固定/条件化整形Polar块 | l3_v3_shape_stream_sc | 旧版沿用固定整形位；条件化版先约束当前payload和F，再求S |
| 3 | Gray 16QAM映射与无噪声回环 | l3_parallel_to_serial_bits, l3_llr_16qam_gray_LSE | 检查每路信息位，不把整形位误计入payload错误 |
| 4 | 统计目标/模型/经验PMF | 脚本内审计逻辑 | 以完整码字为bootstrap簇；按seed输出诊断 |
| 5 | 输出审计材料 | 内联 | timestamped results目录，CSV/MAT/README/log/PNG/PDF |

## Modes and Inputs

- `static`：每个p、每个版本、两个固定seed；每seed各测全零payload、全一payload及一组随机payload。
- `smoke`：每个p、每个版本，seed `[1701,2903]`，每seed 8帧；只验流程，不执行正式PMF门禁。
- `pmf`：每个p、每个版本，seed `[1701,2903,4127]`，每seed 80帧；固定`N=1024`及`p=[0.5,0.3,0.1]`，bootstrap重复2000次。
- `blocklength`：复用相同B4b集合构造、编码和统计，只允许`N=256/1024`；每个p/版本/码长使用3个seed×20帧，用于判断经验分布偏差是否随码长缩小，不替代pmf正式门禁。
- `frozen_compare`：在同一B4b集合、payload和消息条件化SC precoder下，仅比较`F=0`与逐帧iid Bernoulli(0.5)的F；随机F值作为已知旁信息交给无噪声接收端，暂不计旁信息开销。默认N=1024、每p/配置3个seed×20帧，用于隔离冻结值影响，不代表可直接部署的方案。

可通过工作区变量`b4b_audit_overrides.mode`选模式，也可覆写`seed_values`和`frames_per_seed`；pmf模式的默认预算为研究协议值。运行`pmf`前先运行smoke并计时，再评估是否应由用户本地运行。

## Outputs

- `partition_summary.csv`：每个p和bit stream的K/S/F集合大小。
- `frame_audit.csv`：每个码字的参数、payload场景、无噪声信息错误、冻结1的计数、发送符号能量、四个label-bit边缘率及16个星座点原始计数。
- `pmf_summary.csv`、`pmf_by_seed.csv`、`conditioning_probe.csv`：汇总PMF、seed分层区间与payload条件化探针。
- `b4b_shaping_audit.mat`、`README.txt`、`run_log.txt`、`figures/pmf_by_variant.{png,pdf}`。

## Acceptance

- 每路S/I/F两两互斥、合并覆盖N个位置，且信息位数量符合B4b契约。
- 固定非零payload和多个随机payload的无噪声信息位错误数为0。
- 条件化探针须保持I/F约束；S随payload是否变化仅作观测记录，不以单个payload翻转必须改变S作为判据。
- smoke仅报告诊断值；只有pmf模式按整体帧簇与每seed结果评估TV单侧95% bootstrap上界≤0.05。
- 若PMF门禁未通过，暂停等功率策略性能统计并调查模型、映射和有限长构造差异。blocklength结果只支持或削弱“有限码长解释”，不能单独证明渐近收敛。
- 同一`p/seed/frame`下两个版本的payload指纹必须完全相同，禁止把未配对样本作为版本对照。
- `frozen_compare`须保持两配置payload指纹逐帧一致；随机F必须在 precoder 与接收端约束中逐码字一致，且报告中注明旁信息开销未计。
- 本流程不执行Rayleigh full-chain长跑，不代表RF-DC效率。


## 2026-10-08 源概率与集合对照
- `source_compare`：同一分区比较min-sum MAP/F0、精确MAP/F0、精确条件抽样所有非I位；默认3seed×20帧。新增调用l3_v3_sc_decode_forced_full。
- `partition`取B4_GA（默认）或source_MC_GA；后者调用l3_v3_build_stream_partition_source_mc_ga，以独立seed9001、200个源码字选S，保留B4的ceil K与GA选I规则。
- 精确源LLR须通过N=2/4全前缀直接似然核对。所有配置只比较I恢复；随机F旁信息假设已知，不计开销，不能直接宣称可部署。
- `render_result_dir`只读取已有MAT补画图，不重做统计。
- 图、TV及逐seed结果仅作短诊断；正式80帧/seed PMF门禁仍待完成。

## 2026-10-09 构造契约追加

新版本为`source_entropy_S_GA_IF`：每一路保持原K和S数量；固定源熵估计选择S；每个通信SNR在剩余位置重新GA排序选I/F；逐帧按payload和F=0调用v3精确源SC强制构造。源熵估计seed与评价seed必须分离。接收端仍是现有SC/LLR契约，不能将source precoder准确性等同于接收度量匹配。正式PMF门禁和码长对照见本轮时间戳结果；本次不更新最优性能结论。


## 2026-10-09 Hypothesis coverage link

Additional validation target: l1_probabilistic_shaping#H3, limited to the finite N/p/source-seed regimes stated in that L1 hypothesis.
