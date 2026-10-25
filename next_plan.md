# 下一步执行计划：阶段 B 从正式统计进入独立验证与论文收束

> 更新时间：2026-09-17
> 当前状态：24 dB边界失败已转化为28 dB保护带；第三批全新样本验证PASS；B5初稿已更新
> 下一位 Agent / 用户的目标：补充复杂度运行时间实测、论文最终排版与中期PPT实际制作

---

## 0. 继任者入口

工作目录：

```text
C:\Users\11956\Desktop\研究生毕设
```

必读：

```text
CLAUDE.md
workbook/README.md
workbook/mandatory-rules.md
workbook/code-experiment-standards.md
workbook/quality-assurance.md
workbook/environment-setup.md
周报/阶段B/阶段B：多载波系统构建.md
周报/阶段B/B1：OFDM baseline阶段文档.md
周报/阶段B/B2：Rayleigh子载波可靠性画像.md
周报/阶段B/B3：子载波策略对比.md
周报/阶段B/B4：full-chain策略验证.md
```

必须遵守：

1. 不自动跑 full mode 或长 MATLAB 仿真；
2. 任何代码、脚本、文档改动后更新相关 `周报/阶段B/*.md`；
3. 阶段 B 不能声称策略最优，除非同口径比较 `uniform_p05`、`good_channel_information`、`good_channel_energy_shaping`、`bad_channel_energy_only`；
4. MATLAB 图上不要直接显示带 `_` 的内部策略名；
5. 测试、smoke、验证或实验结果写入阶段文档时，尽量附关键图片和图片分析；
6. 关闭非平凡任务前运行 rule reflection，并写入阶段文档。

---

## 1. 已完成状态

### B1：OFDM AWGN baseline

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_visual_check.m
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline_dense.m
```

主要结果：

```text
16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/
16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/
```

关键结论：AWGN OFDM baseline 已跑通；`p=0.5, 20 dB` 的 CP 修正 Goodput 最高，为 `0.393934`。B1 只是轻量 baseline，不用于最终策略排序。

### B2：Rayleigh 子载波可靠性画像

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m
```

主要结果：

```text
16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/
```

关键结论：已输出 `|H_k|^2`、等效 `gamma_k`、MI proxy 和 high/mid/low 分组。当前 realization 数只够支撑画像和 B3 proxy，不够论文级统计结论。

### B3：子载波策略 proxy 对比

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m
```

最新结果：

```text
16QAM_Polar/v2/results/20260614_212900_subcarrier_strategy_compare/
```

数据层已比较六类策略：

```text
uniform_p05
uniform_p03
uniform_p01
good_channel_information
good_channel_energy_shaping
bad_channel_energy_only
```

B3 只能写成 proxy tradeoff，不能写最终 BER/Goodput 最优结论。

### B4a：分组块 full-chain 策略验证

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
```

阶段文档：

```text
周报/阶段B/B4：full-chain策略验证.md
```

smoke 结果：

```text
16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/
```

已完成：

1. 修复 adaptive batch 重复 seed 风险；
2. MATLAB `check_env` 通过；
3. 默认 smoke 运行成功；
4. 输出 block/realization/summary CSV、MAT、README、run_log 和三张图；
5. README 和 B4 文档明确 B4a 不是严格逐子载波 OFDM polar 编码。

B4a 只能作为分组块近似验证。不能写最终策略排序，不能写成严格 Rayleigh OFDM full-chain。

---

## 2. 已完成：正式统计、配对分析与低复杂度码本

B4b入口已经实现：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
```

正式结果：

```text
16QAM_Polar/v2/results/20260917_210504_b4_strict_ofdm_rayleigh_formal/
16QAM_Polar/v2/results/20260917_215938_b4b_paired_policy_analysis/
```

正式仿真采用以下预登记参数，并在用户授权后完成：

```matlab
snr_grid = [20 24 28 32 36 40];
num_realizations = 30;
min_frames = 5;
target_errors = 200;
max_frames = 50;
run_mode = 'formal';
```

正式仿真形成1080条重复记录、36条汇总与1920条信道记录，独立审计PASS。随后按同一SNR/realization完成90条配对差值，并形成六项低复杂度约束码本：BER上区间不超过0.1且Goodput下区间不低于0.25时最大化接收能量，否则回退最大Goodput。默认结果为20 dB选择`uniform_p05`，24—40 dB选择`uniform_p01`。

当前验收：

1. 正式重复以Rayleigh realization为统计单元，公共信道/噪声用于配对比较；
2. 全零错误点已写入上界，不作为理论BER=0；
3. 配对键、区间、方向检验、可行性筛选和码本选择规则均通过独立审计；
4. 已新增`学习文档/多载波OFDM瑞利信道-loop/中期PPT材料.md`逐图解释结果；
5. 下一步不是重复正式长跑，而是用独立信道样本验证固定码本，并进入B5论文收束。

---

## 3. 下一步首选：独立样本验证与B5论文初稿

建议新建：

```text
周报/阶段B/B5：论文二初稿.md
```

初稿结构：

1. 研究动机：Rayleigh OFDM 子载波可靠性不均匀；
2. 阶段 A 承接：单载波概率整形存在 BER / Goodput / Energy tradeoff；
3. B1：AWGN OFDM baseline；
4. B2：Rayleigh 子载波画像；
5. B3：六类策略 proxy 对比；
6. B4a：分组块 full-chain 验证；
7. B4b：严格 OFDM Rayleigh full-chain，作为增强验证或待完成边界；
8. Pareto 分析；
9. 局限性：B4a 不是逐子载波编码，未引入 SCL / 整流器 / 硬件；
10. 下一步：逐子载波编码、SCL 先验适配、能量收集非线性模型。

---

## 4. 不要做的事

1. 不要回头纠缠阶段 A 单点异常；
2. 不要把 B3 proxy 当作最终策略结论；
3. 不要把 B4a smoke 当作论文级统计结果；
4. 不要自动跑 B4a/B4b full mode；
5. 不要修改 `16QAM_Polar/v2/config.m` 做实验专用覆盖；
6. 不要只比较 `uniform_p05` 和单一候选策略；
7. 不要声称单次或少量 Rayleigh realization 证明策略有效。

---

## 5. 当前文件变更记录

- **2026-09-17**：两轮B4b受限pilot完成且通过审计：`20260917_194823_b4_strict_ofdm_rayleigh_pilot`覆盖20—32 dB，`20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr`覆盖32—40 dB。正式网格预登记为20—40 dB六点、30 realization、5—50帧、目标200错误；实际长跑仍待实现checkpoint/resume与用户授权。Rule reflection: no new durable rule
- **2026-09-17**：正式统计入口现已支持checkpoint/resume、partial CSV和零错95%上界，并拒绝没有`formal_authorized=true`的实际启动。重构后的高SNR pilot`20260917_205527_b4_strict_ofdm_rayleigh_pilot_high_snr_formal_ready`审计通过；正式长跑仍等待用户授权。Rule reflection: no new durable rule
- **2026-09-17**：B4b严格OFDM-Rayleigh六策略smoke完成并通过审计，权威目录为`16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/`。8—20 dB主要仍在高误码区，下一步改为20—32 dB短pilot定位瀑布区；正式长仿真需在pilot后预登记预算并取得用户授权。Rule reflection: no new durable rule
- **2026-06-28**：按用户反馈加宽 B4a SNR 范围。脚本 full 默认 SNR 改为 `0:2:20`，默认 smoke 改为 `0:5:20`；重新运行 smoke 输出 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`，B4 文档图片和分析已切换到新结果。Rule reflection: no new durable rule
- **2026-06-28**：补充 B4a smoke 图和图片分析；`CLAUDE.md` 新增测试/验证结果写入阶段文档时应尽量附关键图片和图片分析的规则。Rule reflection: added/updated `CLAUDE.md` because result documentation should include figures and figure analysis for readability.
- **2026-06-28**：B4a 分组块 full-chain 策略验证完成 smoke。结果目录 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`；脚本修复 adaptive batch 重复 seed 风险；新增 `周报/阶段B/B4：full-chain策略验证.md`；阶段总纲已更新。下一步进入 B4b 严格 OFDM Rayleigh smoke 或 B5 论文二初稿。Rule reflection: no new durable rule


## 2026-10-10 当前有效计划快照

当前优先完成RKS范围/证据登记修复，以及固定16QAM多载波等功率P1。P1输出后进入P2匹配可靠性模型、P3 27候选分组策略选择，再评估P4非线性收能及硬件损伤，最后P5 USRP。多QAM限定为整形可外推性的支撑验证，不展开其多载波策略与Goodput主线。具体P1实验协议和门禁见`workbook/knowledge/L2/l2_b4_equal_power_p1.md`。

Revision metadata: revision_id=next_plan_p1_current_20261010; current_status=current; supersedes=[baseline].


## 2026-10-11 当前有效计划快照

当前状态：P1等功率正式验证已完成；治理工具可按明确范围和当前修订扫描，但完整知识库覆盖仍有缺口。下一项为P2匹配可靠性模型，之后进入P3的27种固定16QAM分组整形策略选择。P4评估整流非线性、CSI/峰值/削顶和协议开销；P5完成USRP验证。多QAM范围不扩展。

P1正式结果入口：`16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/LATEST_ANALYSIS_PATH.txt`；解释与限制见最终分析目录README和阶段B/B4文档。RKS 70.5/100仅为结构指标，flow/H/guardrail覆盖缺口是治理待办，不代表研究验收已完成。

Revision metadata: revision_id=next_plan_p1_complete_20261011; current_status=current; supersedes=[next_plan_p1_current_20261010].

## 2026-10-11 扫描报告最终口径

最终current-revision扫描记录为`workbook/knowledge/reports/rks-20261011_002500.md`，结构分70.1/100（方法35/35、流程6/31、假设引用12/18、完整性88/88、护栏9/17）。前一追加段中的70.5来自扫描器读取整份历史Markdown；修复为只读当前修订段后得到70.1。后者为当前口径，仍仅代表结构完整度。

Revision metadata: revision_id=next_plan_p1_rks_final_20261011; current_status=current; supersedes=[next_plan_p1_complete_20261011].


## 2026-10-24 当前状态追加：辅助S方案恢复推进，正式预算待确认

用户已同意尝试独立随机S与独立供体S并继续原路径，取代前文“暂停新增对照”的中间状态。已完成独立P2实现、17配置短pilot、21组生成矩阵覆盖审计、3seed×8码字/S统计、原接收端回归与检查点/版本拒绝测试。源MC直接复用P1的200样本seed9001模板；未改共享config或旧正式结果。

随机S修复原S冻结0对照的非均匀问题：p=.3/.1实际24码字TV(均匀)=.00688/.00903，供体S为.04236/.31283。供体不是均匀目标。小校准尚未通过正式1%门禁；模型仅实现并完成合成/短训练smoke，未达独立精度或速度科研验收。冻结S旧对照只留诊断，不称GA错误或原整形PMF失败。

当前阅读入口：学习文档/等功率机制与P2当前结论.md；唯一任务入口：学习文档/等功率机制对照与P2执行清单.md；正式预算：学习文档/P2正式实验预算与执行顺序.md。首轮23job、414366帧，实测点估计18.8小时、建议预留23—30小时；具体批准前不启动。

本轮当前完成的是代码/理论诊断/材料准备。正式1%功率、3×80 PMF、单载波代表点、独立模型预测及正式图均未完成。P2之后才进入P3的27组合；P4非线性收能、CSI/削顶及P5 USRP、CRC/净吞吐/RF–DC标定仍开放。多QAM仅为外推支撑。

Rule reflection: added/updated workbook/quality-assurance.md，因为辅助S对照必须保留接收掩码、独立供体及有效载荷语义，并禁止把未测量通信记为零错误。所有Markdown采用追加；本上下文自审，不声称独立reviewer。源码自审/简化后最终检查另见清单最新快照。

Revision metadata: revision_id=p2_7d6303cf812a_20261024; current_status=current; supersedes=[next_plan_p1_rks_final_20261011].


## 2026-10-25 P2准备阶段收尾

用户提出的随机辅助S与独立供体S已落实，原I/S/F和生产接收端保持。17项准备工作（含41文件台账、24方法/5流程契约、短pilot和源码/恢复测试）完成，8项正式/交接仍待本轮具体预算。最新清单与图片见学习文档/等功率机制对照与P2执行清单.md、等功率机制与P2当前结论.md。

正式提案为16QAM_Polar/v2/results/20261025_001500_p2_budget_proposal，23job/414366帧，实测点估计18.8小时，建议23—30小时；approved=false。当前源码已绑定最终协议，不启动正式长跑。随机S有21组覆盖证明和3×8诊断，供体不是均匀目标；两者均未获正式通信/RF收益结论。P2模型未获独立精度/速度验收，不能先给P3作可靠筛选。

最终验证：MATLAB机制/恢复/原缩放回归通过；RKS修订链解析21测试通过，当前源码与官方入口同哈希；Markdown原前缀、公式/图片路径及git diff检查通过。源码/测试审查及简化为本上下文自审。恢复路径采用临时checkpoint提交并重建CSV；其对应行为已实际测试。

Rule reflection: added/updated workbook/quality-assurance.md，原因是随机S辅助位、接收掩码及未测量通信必须有明确语义；补记RKS历史相同假设的严格修订链去重。模型、图像与文档交付不替代正式科研门禁。

Revision metadata: revision_id=p2_next_preflight_closed_20261025; current_status=current; supersedes=[p2_7d6303cf812a_20261024].


## 2026-10-25 正式实验批准与启动

用户明确指令：“批准按该协议启动正式实验”。批准记录为16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/approval.json，绑定协议SHA256 `3e030c9beb1557e62382d6a27165babdd40d6a88cdf4d4dc9508fe04a1f33962`；原提案及approved=false请求保留为历史，不作为当前批准状态。

本批于01:18（Asia/Shanghai）启动，当前执行ofdm_power_calibration_8101，已生成未缩放校准记录。按功率校准→独立功率验证→PMF门禁→单载波桥梁→模型校准→冻结模型→独立已见/未见测试→诊断与图表的依赖执行23个注册任务。若基础门禁失败即停止依赖阶段，未授权自动扩大80帧首轮预算。

新调度只安排已批准job，不改变协议中的方法、接收端或参数。调度源码另存orchestration_source并记录SHA256；正式方法仍由协议校验。实时状态16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/status.json，事件日志events.log，每job独立日志和原始结果目录；中断可按同一批次恢复。尚未将任何功率/PMF/模型门禁标为通过。

相关入口：scripts/run_p2_approved_batch.py；p2_execute_batch_job.m；p2_batch_power_check.m。验证：Python语法通过，批准/协议/方法哈希一致，首job实际运行且产生数据。全部调度后续分支尚待实际执行，不宣称已通过。

Rule reflection: no new durable rule。沿用冻结预算、检查点、独立门禁及统计证据规则。本次仅确认启动，不表示正式研究完成。

Revision metadata: revision_id=p2_next_approved_running_20261025; current_status=current; supersedes=[p2_next_preflight_closed_20261025].


## 2026-10-25 最新完整交接：P2功率门禁失败后的写作与研究入口

**继任agent先读本段。当前不是“仍在运行”，也不是P2已完成。** 用户希望继续毕业论文写作、理解机制，并在证据允许范围内推进实验；暂无硬期限，接受否定结果。沟通先讲直觉再讲公式，持续自主推进已授权工作；重大范围与额外长跑预算需明确确认。

### 必须读取与当前真相源

1. AGENTS.md、workbook/README.md、mandatory-rules.md、communication-documentation.md；已有Markdown全部append-only。
2. [本轮进度与写作交接](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)：含两条机制、图、S对照证据、运行状态和可写边界。
3. [执行清单末尾最新快照](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)。不要改旧勾选。
4. `16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/status.json`、events.log、ofdm_power_check/power_gate.csv；若后续状态改变，以实际产物重新核查。
5. `workbook/knowledge/meta/current-revisions.json`当前修订；周报/阶段B/B4：full-chain策略验证.md的末尾。

### 已决定的范围与实现

固定16QAM承担OFDM、BER/BLER/Goodput及后续硬件；多QAM只为已有可扩展性支撑。主方案保持原K及|S|、源条件熵选S、剩余GA选I/F、逐帧消息条件化；生产LLR/SC不改。模型必须使用实际I，不自行重建I。当前不展开27组合搜索、不引入新译码或DC/USRP实验。

原S冻结0的同K同I方案不均匀，已退为历史诊断。用户启发已落实random S与donor S：保留原集合和有效K，receiver仍译码I∪S、只计I；辅助位不预知也不计有效载荷。random公平独立，donor来自独立消息的完整整形S向量。前者有21组覆盖证明及24码字诊断；后者不保证均匀。不能宣称同代码本大小或所有编码因素完全隔离。

### 运行真相、预算与禁止误操作

正式批次 `20261025_011808_p2_approved_batch` 于北京时间01:18:21—03:39:41运行，status=gate_failed；完成6/23job、83,520帧。校准8101/8102/8103与验证8201/8202/8203完成。522单元206失败；3个总功率超限（与组失败重叠），最大总1.12635%、组1.80612%。正式PMF、单载波、模型校准/冻结、独立seen8501/unseen8601及正式图未执行。

协议路径 `16QAM_Polar/v2/results/20261025_001500_p2_budget_proposal/protocol_proposal.json`，SHA256 `3e030c9beb1557e62382d6a27165babdd40d6a88cdf4d4dc9508fe04a1f33962`。approval在batch内；原提案UNAPPROVED_PROPOSAL是历史请求，并不否认已批准首轮。用户只批准23注册job/414366帧首轮；门禁失败后不自动增至160/320/640，不直接重新启动调度器。旧估计18.8小时/预留23—30小时不再是本批剩余倒计时。

状态里旧PID不是运行证明，无自动通知配置。保留所有raw、源码快照、日志、检查点和冻结系数。当前没有确认实现bug；不能把小幅功率超限直接归因于样本不足或理论失败。勿重复旧P1长跑、勿改config.m、勿更改冻结源码后冒充同版恢复。

### 下一agent首先做什么

1. 向用户说明本报告三层状态：实现/小样本已完成；首轮功率验证执行完但未通过；正式P2性能证据尚无。无需再重复大范围采访。
2. 使用现有六job数据做只读诊断：从raw保留带符号总/组偏差，按seed、SNR、case分层；核对组分量之和与实际时域总功率、CP/padding及交叉项；比较各SNR实际K/I/F与PMF、校准按全SNR池化是否带来系统差异。区分有限样本波动与固定系数不能同时匹配的问题，不把原绝对偏差CSV当作可恢复符号的数据。
3. 如发现确定bug，按真实仓库证据审查、修复、回归并登记故障历史；若只是采样/目标问题，形成新版本的具体协议和实测预算。沿用1%门槛与独立验证，不用通信测试调系数；提交用户确认后才补跑。不能仅把失败seed换到通过为止。
4. 等基础门禁通过后再执行正式PMF→单载波桥梁→模型校准/冻结→独立seen/unseen→配对统计。最终门槛：BER倍数偏差中位≤2、p90≤5；Goodput MAE≤.02；在线速度≥10倍；错误计数/信道不足即证据不足。模型失败也可如实完成研究报告，禁止提前当P3可靠筛选器。
5. 与此同时推进已有证据支持的论文方法与P1结果写作，P2结果留明确待补段；不因实验暂停而停止所有写作。

### 写作路线、证据与交接风格

先围绕一条主线组织毕业论文：固定幅度整形观察→公平等功率问题→P1现象→功率分布和消息条件化机制→P2可解释预测及独立验证→限制与硬件门禁。具体章节需读取用户当前论文文本后再落位，不虚构已存在稿件。

可立即写：研究问题、S/I/F方法、等功率/噪声/资源口径、已有P1结果、旧冻结S对照缺陷、random/donor结构与探索图、功率门禁失败。暂不能写：正式新对照收益排序、波形额外RF收益、模型通过P3筛选验收、DC提升或CRC净吞吐。

主要证据：P1的 `results/20261010_220626_b4_equal_power_p1/LATEST_ANALYSIS_PATH.txt`；辅助诊断 `results/20261024_232507_p2_auxiliary_preflight/`；精确覆盖 `results/20261025_000154_p2_uniformity_exact/`（以上results相对16QAM_Polar/v2）。新正式功率证据位于当前batch与status列出的6个job目录。正式与pilot图分开标注；旧固定幅度图仅作非等功率观察，旧码本/保护带不转用于当前协议。

本轮不修改DOCX/PPTX，已有对应段落/图修改清单：学习文档/中期材料P2修订清单.md。用户后续明确要求写二进制文稿时，加载科研写作/汇报及对应格式Skill再编辑和渲染。不要仅为了套流程重新采访已决定事项，也不要将“完整图重建完成”误称毕业设计完成。

后续顺序：P2补齐机制与模型验收→P3的27候选及full-chain复核→P4非线性收能/CSI/峰值削顶/协议成本→P5 USRP。CRC、净包吞吐和RF–DC标定仍开放。交接保持三种状态独立：交付完成度、科研证据成熟度、硬件准备度；RKS结构分不能替代它们。

Rule reflection: no new durable rule。已核对status/events/522行CSV及6job原始文件；只追加说明与索引，未改冻结实验、未补跑、未放宽验收。

Revision metadata: revision_id=p2_next_handoff_gate_failed_20261025; current_status=current; supersedes=[p2_next_approved_running_20261025].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制对照与P2执行清单.md](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)
- [等功率机制与P2当前结论.md](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制与P2当前结论.md)
- [中期材料P2修订清单.md](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/中期材料P2修订清单.md)
- [P2阶段进度与写作交接-2026-10-25.md](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)
- [P2正式实验预算与执行顺序.md](学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2正式实验预算与执行顺序.md)

继任agent先读上文“P2功率门禁失败后的写作与研究入口”，再读新目录下的阶段交接和清单末尾；本次搬迁不改变gate_failed状态或长跑预算。

Revision metadata: revision_id=learning_relocation_561192d8b3_20261025; current_status=current; supersedes=[p2_next_handoff_gate_failed_20261025].
