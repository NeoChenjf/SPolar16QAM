# 2026-11-09 仓库清理记录

本轮完成全仓文件盘点与验证脚本重点清理。不是对全部算法逐行审计；未运行MATLAB、启动实验、提交或推送。

## 实际处理

- 全仓17680文件、4352652994字节（排除.git与本轮治理输出）；逐项路径/大小/初分类见[inventory.csv](inventory.csv)。
- 对328个项目代码/脚本扫描符号引用；68个验证类文件初筛见[validation-script-audit.json](validation-script-audit.json)，其余保留不等于均已审查通过。
- 从活跃目录移除10个一次性/固定历史批次脚本，共27891字节（含2个零字节占位）；源码存入[retired-scripts.zip](retired-scripts.zip)，压缩13691字节。此处“清理”主要减少活跃入口，不能宣称大量释放磁盘。
- 逐项原因和SHA256见[retired-manifest.json](retired-manifest.json)。三个已有L3契约追加退役状态，current-revisions同步修订。

| 原路径 | 退役依据 |
| --- | --- |
| `16QAM_Polar/v2/diagnostics/check_ofdm_per_bit_ber.m` | 写死20260522结果目录的打印探针，无断言；保留原始MAT数据。 |
| `16QAM_Polar/v2/diagnostics/quick_layer1_test.m` | 旧Layer1单次修复探针；无固定种子与失败断言，打印完成不代表通过。 |
| `16QAM_Polar/v2/diagnostics/quick_layer2_test.m` | 旧Layer2符号约定探索；两种MI约定取最大值且无失败断言，不作为回归测试。 |
| `16QAM_Polar/v2/diagnostics/test_bpsk_direct.m` | 重复手算BPSK探针；A/C表达式相同，未调用项目方法；保留test_bpsk_baseline。 |
| `16QAM_Polar/v2/diagnostics/test_llr_inspection.m` | 伪16QAM与BPSK不同口径；末尾用1000元素掩码索引250元素llr_qam，不能作为可信测试。 |
| `16QAM_Polar/v2/diagnostics/test_qamdemod_bug.m` | 工具箱单符号旧排障探针，仅打印结果无失败断言；check_env及实际链路测试保留。 |
| `16QAM_Polar/v2/experiments/sc_checks/run_local_12db_check.m` | 固定p=.5、11:0.5:13 dB及旧日期种子的局部问题实验；通用理论/瀑布区入口保留。 |
| `16QAM_Polar/v2/diagnostics/multicarrier/verify_b4b_energy_by_strategy.m` | 固定180行、30 realization及能量策略极值的旧图验收器，非通用科学门禁。 |
| `16QAM_Polar/v2/diagnostics/multicarrier/verify_b4b_fixed_policy_holdout_analysis.m` | 写死24 dB失败、PARTIAL状态及旧码本的特定历史批次验收。 |
| `16QAM_Polar/v2/diagnostics/multicarrier/verify_b4b_guardband_policy_test_analysis.m` | 写死六点SNR、策略映射及全通过结论的第三拆分历史验收。 |
| `questions.txt` | 零字节占位文件。 |
| `未命名.base` | 零字节占位文件。 |

## 保留的内容与发现

1. `diagnostics/multicarrier/test_p2_*`、`analysis/p2_validate_*`等存在有意义的断言、隔离与恢复/输入门禁；命名像验证工具并不代表一次性垃圾。本轮保留。
2. 通用 `verify_b4b_strict_smoke`、`verify_b4b_paired_policy_analysis` 和 `verify_energy_tradeoff_results` 保留；后者由当前实验直接调用。
3. `run_p2_common_environment`、`run_p2_v2_batch`、`run_p2_v2_strategy_batch`有大量相似批处理代码，已确认属于复杂度热点，但也承担不同批次的配置和已有结果复现。本轮不强行合并，避免改变正在开发及已有实验的口径；未宣称已完成全仓重构。
4. 文档保留：Markdown受全仓append-only规则保护，历史周报、协议、批准及解释材料不能仅因过时而删除。本轮追加当前入口和退役说明，没有删除或压缩原文。旧研究计划不作为当前执行授权。
5. 结果占用空间最多；保存的MAT、图、日志、checkpoint、源码快照属于复现证据，不按文件名中的smoke/test临时判断删除。历史v1/v3/OOK、参考文献、汇报视频和先前治理包保留。
6. 现有未提交与未跟踪文件在任务开始前已经存在，保留；仅清单列出的目标允许移除，元数据与导航采用追加/显式修订。工具/Skills目录未修改。

## 恢复

退出正在使用的MATLAB会话或清理旧路径缓存后，先查清单确保原路径未被新文件占用；在仓库根执行：

```powershell
Expand-Archive -LiteralPath .\治理记录\20261109\retired-scripts.zip -DestinationPath .
```

不要添加 `-Force`，避免覆盖后续文件。必须恢复到原路径；部分旧脚本通过自身目录推导依赖/结果目录，从别处运行不保证有效。退役源码保持原样，包括已知问题，恢复不代表测试有效或实验获授权。ZIP被仓库通用 `*.zip` 忽略规则排除，当前是本机恢复材料，提交清理记录时应另行保留备份。

## 验证与边界

见[validation.json](validation.json)。ZIP逐成员对照原字节，检查保留源码未变、Markdown原前缀保持、活跃代码无退役入口调用；历史文档提到旧路径不视为当前调用。未新增自动测试或修改科学算法，因此不跑长仿真。自审采用代码复用、质量和效率三个视角；不以文件少代替行为正确。未启动子agent。

Skill使用：grill-me（仓库证据已足够，不强行访谈）、codex-plan-review（依据真实引用与调用点自审）、test-quality-review（具体旧测试）、simplify（仅高置信退役）、research-meta-extractor（限既有L3的退役维护，无新增函数/流程提取）。未调用不适用的PR编排器或重新扫描整个科研知识库。

Rule reflection: no new durable rule。


### 2026-11-09 最终核验补充

完整性检查确认688个其余受检源码/文档保持任务开始时哈希，8份追加文档原字节前缀保持，12个归档成员核验通过，活跃代码无退役符号调用，新增链接及控制字符检查通过。期间 `scripts/prediction_redesign.py`、`scripts/test_prediction_redesign.py` 发生并发修改，已单独列入validation.json，未覆盖、回滚或将其列入清理。批处理相似度记录见治理目录batch-similarity.json，仅用于定位重构热点，不表示逻辑等价。未运行MATLAB。
