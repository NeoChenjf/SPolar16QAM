# 高阶调制 shaped-polar 阶段记录

## 2026-09-23：第11页BER曲线高SNR探索性粗扫

- **修改内容**：新增`run_16qam_ber_high_snr_coarse.m`，沿用任务二SC、`fixed_esn0`和匹配LLR方差口径，扫描五个$p$及20/25/30/35/40 dB标签，每点20帧、seed=4242；新增独立L2入口，并在任务二PPT材料补充观测结果与结论边界。
- **结果**：[探索性结果目录](../../16QAM_Polar/v2/results/20260923_211103_16qam_ber_high_snr_coarse/)。本seed下，五个$p$在20 dB均有错误，25 dB首次观测零错误；零错95%上界约$7.31\times10^{-5}$至$9.96\times10^{-5}$。该样本不能证明真实BER等于零，也不替代正式曲线。
- **验证方法**：MATLAB R2020b本地运行通过；核对CSV逐路BER加权、错误数/信息位分母及零错上界，并目视确认PNG对数轴、图例和零错标记。中间一次图检发现MATLAB坐标轴未按预期取对数并修正后重新生成最终结果。
- **涉及路径**：`16QAM_Polar/v2/experiments/rectifier/run_16qam_ber_high_snr_coarse.m`、`学习文档/高阶调制理论/16QAM整流效率-loop/中期PPT材料.md`、`workbook/knowledge/L2/l2_16qam_ber_high_snr_coarse.md`、本周报及`workbook/troubleshooting-history.md`。
- **Rule reflection**：no new durable rule；有限样本零错误需报告信息位数和BER上界，现有mandatory-rules已覆盖。

## 2026-09-12：16QAM能量联合实现与smoke通过

- **修改**：新增联合实验、配对统计、Pareto/三类工作点、四图重建、CSV/MAT审计、恢复/计时测试；真实sim链路增加默认关闭的逐帧采集与逐SNR回调。Windows MATLAB包装及环境说明已按本机R2020b许可实测更新；对应L1/L2/L3已同步。
- **结果**：[最终90帧smoke](../../16QAM_Polar/v2/results/20260912_172318_16qam_energy_tradeoff_smoke/)，45重复点、四图PNG/PDF/FIG、CSV/MAT、源快照/哈希及审计齐全。见[审查证据](../../学习文档/高阶调制理论/16QAM整流效率-loop/验证与审查.md)。
- **测试**：check_env、纯统计负路径/边界、真实链路RNG/BER回归、完整及缺块恢复精确一致、CSV/MAT图数审计通过。正式未运行；DOCX/PPT和中期完成状态尚未改动。
- **修复**：NaN配置比较与工作点错序连接，已记troubleshooting-history。只读自审及simplify在本上下文完成，无子agent。
- **观测**：smoke p=0.1经验单位能量约1.36—1.40，不同于目标解析1.64；如实保留，不能替换数据。下图仅验证统计与输出机制，每seed仅两帧。

![smoke单位能量](../../16QAM_Polar/v2/results/20260912_172318_16qam_energy_tradeoff_smoke/figures/energy_p.png)

- **耗时与下一步**：120帧计时2.86秒，58,500帧线性约23.2分钟；正式预留25—45分钟并等待用户单独授权。数据按新时间戳保留。
- **Rule reflection: added/updated workbook/environment-setup.md because 当前Windows实测MATLAB可用，与旧Mac/Octave说明不同，运行入口必须按目标环境验证。** 指标与统计选择保留在loop协议。

## 2026-09-12：16QAM能量强度联合实验loop设计（待审核）

- **需求变化**：用户明确开题任务中的“整流效率”本阶段按能量强度代理评价，取消整流模型硬门禁；固定星座缩放，真实发送符号均方以同seed/SNR下p=0.5归一化为1。旧2026-09-11终态盘点中的模型硬门禁不再适用此新范围，但尚未实施的模型不会登记为完成。
- **设计产物**：[16QAM工作包唯一入口](../../学习文档/高阶调制理论/16QAM整流效率-loop/README.md)，包含需求、设计、协议、进度、问题、下一步和中期PPT材料共8份文件。
- **冻结范围**：五p、8:1:20 dB、seed 42/43/44、每点300帧的完整联合重跑；四图和逐SNR Pareto/三类工作点，正文展示8/14/20 dB。正式长跑待smoke计时后单独授权。
- **代码证据与风险**：噪声实际复方差使v2标签与标准Es/N0差3.01 dB；GA构造依赖SNR，不能预设经验能量与SNR无关。协议保留通信实现、记录换算并逐点统计；待实施审查及测试核验。
- **影响范围**：本轮仅新增loop及本周报；用户现有修改、代码、历史结果、中期DOCX/PPT与进度状态保留。新L1/L2/L3契约随方案确认和对应实现更新。
- **验证**：本上下文依据源代码和既有正式参数自审，检查8份文档、相对链接及单元/网格/授权门禁一致性。未运行MATLAB/Octave，未声称测试或formal通过；未启动子agent。
- **Rule reflection: no new durable rule**。指标选择为本工作包决定，记录于协调协议；真实性、图数审计与运行授权复用既有workbook规则。

## 2026-09-11：建立截至9月中期终态进度表

- **修改内容**：在`中期相关/截至2026年9月中期终态进度表.md`建立开题前三阶段的严格验收清单，将高阶调制框架、16QAM BER—整流效率和多载波瑞利优化拆分为实现、正式数据、完整出图、数值准确和结论边界五类门禁。
- **盘点结论**：高阶调制框架已达到终态；16QAM现有结果仍是BER/Goodput—RF能量代理量，缺正式整流模型和BER—整流效率曲线；多载波已有B1、B2、B3和B4a前置结果，但缺B4b严格OFDM-Rayleigh全链路、正式重复统计、优化算法及最终图表。
- **影响范围**：仅新增进度文档并更新本周报；未修改MATLAB代码、实验数据或结果图片，未运行新实验。
- **验证方法**：对照中期填写稿研究计划表、`项目整体计划书.md`、阶段A/v3进度、阶段B B1—B4文档及各时间戳结果目录，逐项核验代码、CSV、MAT、日志和PNG/PDF/FIG是否存在，并检查proxy/smoke/整流效率边界。
- **后续事项**：优先从整流器模型接入（T2-03）或严格OFDM-Rayleigh链路（T3-06）启动下一工作包；只有正式数据、终态图和图数一致性同时通过才改为完成。
- **Rule reflection**：no new durable rule；严格完成口径复用现有实验、图表和证据规则，本表只将它们映射到中期终态。

## 2026-09-10：建立开题计划第一项单一文档入口

- **修改内容**：将`学习文档/高阶调制理论/通用GrayQAM-loop/`建设为“高阶调制极化码仿真框架”的统一资料入口；新增README总览和六页中期PPT材料，按“v2固定16QAM闭环→v3通用8/16/32/64QAM扩展”组织完整主线，并同步loop设计入口、进度总览和next_plan边界。
- **中期汇报材料**：参照开题PPT的16:9浅灰几何背景、蓝色主色和章节编号体系，在`中期相关/`生成16页中期汇报终稿；嵌入v2 Goodput—Energy/BER与v3 PMF/Energy/BER原始结果图，补充开题计划对照、阶段成果、五类门禁、研究边界和下一步，并加入逐页讲稿备注。
- **影响范围**：仅文档；MATLAB代码、CSV、MAT、日志和结果图片均未移动或修改，仍保存在`16QAM_Polar/v2/`与`16QAM_Polar/v3/`。
- **验证方法**：检查新增及修改文档中的本地相对链接；直接对照v2 final global curve CSV、v3 energy/BER/PMF结果文件核验核心数字；审查能量代理量、multi-stream BICM扩展、OFDM/Rayleigh和USRP边界表述；使用Microsoft PowerPoint打开中期汇报并导出PDF，完成两轮逐页视觉检查与修正，无占位符、遮挡或文字截断。
- **受影响路径**：`学习文档/高阶调制理论/通用GrayQAM-loop/{README.md,中期PPT材料.md,loop设计.md,进度表.md,next_plan.md}`、`中期相关/基于自适应无线数能内生传输的编码方案研究-中期汇报-终稿.pptx`及本周报。
- **结果目录**：未运行新实验，无新增结果目录；文档仅索引既有时间戳结果。
- **后续事项**：中期答辩前按学校时长要求删减或补充个人信息；新的OFDM/Rayleigh、整流器或USRP工作进入其他阶段文档。
- **Rule reflection**：no new durable rule。

## 2026-09-03：64QAM正式PMF通过，通用GrayQAM loop技术门禁完成

- **结果目录**：`16QAM_Polar/v3/results/20260903_221630_pmf_formal64/`，`overall_pass=1`。
- **正式PMF门禁**：lambda=0/0.25/0.5的经验TV点估计为0.01261/0.02232/0.02940，独立帧cluster-bootstrap 95%上界为0.01877/0.02680/0.03310，全部低于预登记阈值0.05。
- **拟合与能量**：三个target→model状态依次为exact/approximate-pass/approximate-pass；经验能量依次为0.99795/1.06503/1.14973，继续支持能量随lambda增加的既有结论。设计`R_code`依次为0.50000/0.49837/0.49414，后续Goodput解释仍须带上码率变化。
- **图形复核**：三个柱均明显低于0.05红色门限线，且随lambda增大TV上界上升；这支持“当前lambda网格全部达标”，不证明更大lambda仍会达标。

![64QAM正式PMF门禁](../../16QAM_Polar/v3/results/20260903_221630_pmf_formal64/pmf_formal64.png)

- **Loop状态**：64QAM的B PMF与产物同步转绿；8/16/32/64QAM四个工作单元及跨M技术门禁全部完成，仅待用户最终审核确认。
- **Rule reflection**：no new durable rule；正式PMF的独立帧cluster-bootstrap和预登记阈值已由现有实验规则及本loop协议覆盖。

## 2026-09-03：BER refine全M通过，收束到64QAM正式PMF

- **BER结果目录**：`16QAM_Polar/v3/results/20260903_210444_ber_refine/`，`overall_pass=1`。12个M/lambda组合均在3次独立重复后通过；每条曲线有5–7个有效点，最低有效错误数104，满足至少2点落在`1e-4~1e-1`且每点≥100错误的D门禁。
- **中心点表现**：在8/10/14/16 dB，8QAM BER为0.02445/0.01668/0.00680，16QAM为0.05944/0.04569/0.02663；32QAM约0.0454/0.0488/0.0460，64QAM约0.0504/0.0543/0.0567（均按lambda 0/0.25/0.5）。这说明低阶M在fixed_n0下呈下降方向，高阶M没有相同排序。
- **解释边界**：lambda增大同时提高发送能量并轻微降低R_code，故上述差异不能单独称编码增益；3次重复足以完成D门禁，但不足以宣称稳定lambda最优。32/64QAM错误集中于少数bit-level，仍需结合bit-channel构造解释。
- **relation/LLR收束**：新增PAM2/4/8统一版本relation registry；PAM4显式关系对energy-lambda族精确，PAM8保持optimized/approximate命名。全M在sigma=0.45下的非均匀latent LLR与独立直接星座枚举参考误差≤1e-11，两项MATLAB诊断均PASS。
- **下一实现**：仅64QAM尚未通过正式经验PMF 0.05门禁。新增`pmf_formal64`入口：N=1024、80帧、source-MC样本200，三个lambda点使用2000次独立帧bootstrap；8/16/32QAM不重复运行。
- **验证**：relation/LLR测试及formal64入口codecheck为0 issue，64QAM模型预检为approximate-pass。正式PMF长跑待用户执行。
- **文档收口**：同步修正无噪声环回与source-MC构造的L3健康度，PAM4不再记作临时测试夹具，统一引用已冻结的PAM2/4/8 relation registry。
- **Rule reflection**：no new durable rule；D门禁、码率先核对和PMF独立帧统计均已由现有规则覆盖。

## 2026-09-03：BER coarse定位完成，新增局部加密重复入口

- **coarse结果**：`16QAM_Polar/v3/results/20260903_160356_ber_coarse/`完整生成。8/16/32/64QAM的12条lambda曲线分别在8/10/14/16 dB找到BER约`0.0126~0.0183`、`0.0418~0.0657`、`0.0503~0.0539`、`0.0389~0.0555`的候选点，所有候选均超过100个聚合payload错误。
- **结论边界**：每条曲线只有1个有效点，下一档2 dB处均为零错误，因此coarse仅完成瀑布中心定位，不满足D门禁至少2点，也不能用于稳定lambda排序。32/64QAM在瀑布前的错误明显集中于少数bit-level，先记为bit-channel不等可靠现象，不作机制定论。
- **码率核对**：lambda增大时R_code轻微下降，例如8QAM为0.5000/0.4961/0.4870，64QAM为0.5000/0.4974/0.4935；后续Goodput解释必须同时带上该设计码率上界，不能只比较BER。
- **新实现**：新增`ber_refine`模式，各M围绕8/10/14/16 dB使用`-0.5:0.25:1.0 dB`网格；每次30帧，至少3次、至多10次独立重复。每个M/lambda达到至少2个`1e-4~1e-1`且累计≥100错误的点后停止。
- **随机性修复**：新增`cfg.source_mc_seed`固定S/I/F构造；source-MC函数恢复调用者RNG，确保重复seed只改变payload/AWGN。该问题已登记troubleshooting。
- **验证**：新增/修改文件MATLAB codecheck为0 issue；RNG隔离断言通过；M=8双SNR、双runtime seed微型链路确认构造一致且样本变化。未运行正式refine。
- **下一步**：用户运行`summary = run_gray_qam('ber_refine')`并回传validation表和结果目录。
- **Rule reflection**：no new durable rule；随机性隔离属于具体bug修复，通用可复现性规则已有覆盖。

## 2026-09-02：新增全M有限SNR BER coarse入口

- **修改内容**：统一主入口新增`ber_coarse`模式，对8/16/32/64QAM、lambda 0/0.25/0.5扫描`SNR=0:2:18 dB`；固定N=256、30帧、source-MC样本120、seed=20260903及fixed_n0，不改变已通过的能量链路口径。
- **统计与产物**：逐点保存BER/联合BLER、聚合及逐流errors、bits、frames、R_code/R_bpcu、Goodput与能量；自动登记BER在`1e-4~1e-1`的窗口，至少20错误才标较稳定候选。每个M/lambda块写partial CSV/checkpoint，最终输出CSV/MAT/README/run/progress log和PNG/PDF/FIG。
- **解释边界**：这是稀疏单seed搜索，只负责定位窗口；全零错误点保留计数但不画伪造floor。不能据此声明lambda或M的稳定BER排序，必须先审核errors/frames再做局部加密和重复。
- **验证状态**：MATLAB codecheck为0 issue。首次双SNR微型检查暴露K被转成行向量、`K*frames`只在单SNR下偶然可用的维度错误；已将K/S/F统一为列向量并登记troubleshooting。修复后M=8、N=8、2帧、SNR=[0,4]微型有限SNR链路通过，`BER_per_bit`为3×2、K为3×1；该极小样本只证明接口可执行，不提供BER结论。用户coarse结果目录尚未生成。
- **Rule reflection**：no new durable rule；两阶段搜索、错误数审查和全零点规则已存在workbook。

## 2026-09-02：全M energy-lambda smoke通过

- **结果目录**：`16QAM_Polar/v3/results/20260902_224303_energy_lambda_smoke/`，`overall_pass=1`。
- **拟合结论**：8/16QAM三点均为exact；32/64QAM正lambda点为approximate-pass，target→model最大KL=0.002613、最大TV=0.03392，均在预登记阈值内。
- **能量结论**：四种M的模型能量严格递增；8组相邻经验能量差的配对bootstrap单侧95%下界全部大于0，最小下界为64QAM从lambda 0到0.25的0.03363。因此本轮真实发送码字的能量单调smoke通过，不只是模型曲线通过。
- **PMF边界**：所有点通过经验PMF smoke阈值0.10；64QAM三个点的TV上界为0.0515/0.0586/0.0648，未通过正式0.05，故B项不全绿。经验能量普遍低于模型正lambda能量，反映有限长成形损失。
- **图形复核**：模型实线与经验虚线均随lambda上升；经验曲线低于模型曲线，和CSV的finite-length偏差一致。该图不包含BER证据。
- **下一步**：保持所有口径不变，仅新增有限SNR coarse扫描，依errors/frames寻找BER约`1e-4~1e-1`的瀑布区，再决定局部加密。
- **Rule reflection**：no new durable rule；现有PMF/能量cluster统计和BER瀑布区规则已覆盖。

## 2026-09-02：实现全M energy-lambda smoke，等待MATLAB结果

- **修改内容**：v3新增每轴latent概率拟合器和`source='energy_lambda'`规格生成器，目标固定为`P_X∝exp(lambda|x_scaled|^2)`；统一入口新增`energy_smoke`模式，预登记`lambda=[0,0.25,0.5]`，覆盖8/16/32/64QAM。新增逐帧配对bootstrap，对相邻lambda经验能量差给出单侧95%下界。
- **实验口径**：固定均匀星座缩放、`fixed_n0`、N=256、40帧、source-MC样本120、seed=20260902、120 dB近似无噪声。能量是平均发送RF能量代理，不是整流器收获能量。
- **产物与恢复**：入口写时间戳`energy_lambda_smoke`目录，含target/model/empirical PMF、model preflight、partial/final CSV、checkpoint/MAT、README、run/progress log及PNG/PDF/FIG。每点完成即落盘，避免12点运行中断后无证据。
- **辅助修正**：均匀目标直接返回latent `p=0.5`，并在source-MC构造中对`S_size=0`跳过无意义采样，避免数值微扰把lambda=0误成非均匀构造；KL最终值钳制到非负，消除exact点约`-1e-16`的浮点负机器零。
- **验证方法**：MATLAB `checkcode` 对7个新增/修改入口均为0 issue。纯模型12点预检全部通过且能量严格递增：8/16QAM各点exact；32QAM最大TV=0.0339、64QAM最大TV=0.0261，均为approximate-pass范围。另以M=8、N=8、2帧/2构造样本完成核心链路微型运行，确认energy规格、SC链路、逐帧PMF和配对统计接口可执行；该样本量不构成能量统计证据。未代用户运行中等时长真实码字仿真；下一步执行`summary = run_gray_qam('energy_smoke')`，以`overall_pass`、逐点TV上界及相邻能量差下界判定。
- **影响路径**：`16QAM_Polar/v3/{modulation,analysis,polar,core}/`、两个run入口、v3 README、L2/L3、通用GrayQAM loop文档及本周报；v2未修改。
- **结果目录**：待用户运行生成。
- **Rule reflection**：no new durable rule；target/model/empirical分层和cluster统计已由现有protocol/workbook规则覆盖。

## 2026-09-02：沿用现有loop并统一中文文档名

- **决策**：能量参数化、能量单调性与后续AWGN BER仍围绕同一批8/16/32/64QAM工作单元和同一协议推进，因此继续使用`通用GrayQAM-loop`，不新开loop。只有转向cross-QAM/APSK、OFDM、多用户或整流器非线性等改变工作单元/协议/终止条件时才新开。
- **文档迁移**：loop目录内统一为`需求澄清.md`、`loop设计.md`、`协调协议.md`、`进度表.md`、`问题记录.md`、`next_plan.md`；更新内部交接链接和`方法.md`引用。
- **历史loop同步**：`学习文档/shaped_polar验证loop/`也迁移为同一中文命名，并补`next_plan.md`；`最新认知与执行基线.md`作为领域补充文档保留。
- **next_plan**：明确下一单元为`energy_lambda` target→model求解、模型/经验RF能量单调性与cluster-bootstrap门禁，通过后再进入BER瀑布区smoke。
- **全局skill**：已更新`loop-designer`，补齐YAML frontmatter并将未来loop默认产物固定为上述中文文件名；`skill-creator`的`quick_validate.py`验证通过。不改变非loop的clarify/impl-plan文件协议。应用若缓存skill清单，需重启/刷新后才会在`/`命令中反映。
- **Rule reflection**：no new durable rule；这是用户的全局skill偏好，将写入skill而非项目workbook。

## 2026-08-30：统一入口全M source-MC PMF smoke通过

- **结果目录**：`16QAM_Polar/v3/results/20260830_003724_pmf_smoke/`。
- **结果**：8/16/32/64QAM的TV点估计为0.0543/0.0637/0.0685/0.0747，cluster-bootstrap 95%上界为0.0603/0.0693/0.0752/0.0854，全部低于smoke阈值0.10。经验RF能量为0.6440/0.5769/0.6716/0.6920，仍高于model的0.6000/0.5200/0.6054/0.6257，符合残余有限长成形损失。
- **判定范围**：全M共享PMF smoke通过；不等于正式TV≤0.05门禁，不证明能量随lambda单调，也不提供有限SNR BER证据。
- **文档同步**：更新loop board与run_gray_qam L3健康度；无代码修改。
- **下一步**：实现energy_lambda/axis target求解、至少三个lambda点的模型及经验RF能量单调性检查；通过后才进入AWGN BER瀑布区smoke。
- **Rule reflection**：no new durable rule。

## 2026-08-30：source-MC PMF 随码长收敛，主入口切换N=256

- **结果证据**：16QAM source-MC在N=64/256/1024时TV上界为0.1245/0.0690/0.0506，经验能量为0.6328/0.5769/0.5616，经验p逐步接近目标。N=256通过smoke阈值0.10；N=1024仅接近正式0.05阈值，因20帧/60构造样本不记正式通过。
- **决策与修改**：统一入口改为source-MC+GA，默认N=256、40帧、每流120个source构造样本；README产物动态记录这些参数。下一步以同一入口验证全部四种M。
- **边界**：source-MC是数值构造并有额外设计成本；仍未达到论文严格构造或正式PMF统计门禁，不进入BER长跑。
- **结果目录**：本轮码长对照为内存结果；全M新结果待运行生成。
- **Rule reflection**：no new durable rule。

## 2026-08-30：修正后的source-MC显著改善但未过PMF smoke

- **结果证据**：16QAM/N=64同口径下，source-MC+GA得到TV点估计0.1057、上界0.1159、E=0.6294、经验p=[0.613 0.731 0.613 0.732]；均优于BSC+GA的0.1665/0.1769/0.6972及[0.58 0.692 0.568 0.686]。
- **判定**：条件熵升序修复有效，但TV上界仍高于smoke阈值0.10，暂不进入BER。
- **修改内容**：新增source-MC专用码长对照N=64/256/1024，用以判断剩余偏差是否随极化长度收敛；构造样本数随N为200/120/60，必须结合该预算解释。
- **结果目录**：无，对照先输出控制台内存表。
- **Rule reflection**：no new durable rule。

## 2026-08-30：source-MC 对照暴露 S 条件熵方向错误

- **结果证据**：同口径16QAM/N=64下，BSC+GA为TV上界0.1769、E=0.6972、经验p=[0.58 0.692 0.568 0.686]；source-MC+GA错误版本为TV上界0.4186、E=1.0000、经验p约[0.487 0.498 0.491 0.502]。
- **根因与修复**：source-MC按高条件熵选S，但 `|S|=N(1-H2(p))` 对应低条件熵可预测位置；已改为升序选择最低熵位置。
- **验证边界**：修复尚待重跑同一对照。当前结果只证明旧方向错误，不证明修复后PMF通过。
- **受影响路径**：source-MC构造、对应L3、troubleshooting和本周报。
- **结果目录**：无，对照为控制台内存结果。
- **Rule reflection**：no new durable rule。

## 2026-08-28：定位为source shaping边缘概率失配，新增条件熵对照

- **结果证据**：16QAM的目标latent p=[0.65 0.8 0.65 0.8]，BSC+GA实际仅为N=64的[0.58 0.692 0.568 0.686]、N=256的[0.585 0.676 0.583 0.689]、N=1024的[0.554 0.661 0.55 0.671]。边缘已失配，relation不是首因。
- **修改内容**：SC完整译码器可选返回逐位posterior LLR；新增source-MC+GA构造，以当前SC/极化矩阵和source先验直接估计每个U位条件熵来选S；新增与BSC proxy同条件PMF对照入口。
- **下一步**：运行`run_source_construction_compare`。它只对16QAM、N=64比较BSC proxy与source-MC，source-MC使用200个离线构造样本；仍不是BER长跑。
- **结果目录**：无，新对照先输出控制台内存表。
- **Rule reflection**：no new durable rule。

## 2026-08-28：码长对照排除短码长解释，新增latent边缘诊断

- **结果证据**：BSC可靠端S下16QAM：N=64/256/1024的TV上界为0.1765/0.1743/0.2114，经验能量为0.6972/0.7077/0.7341。TV未随N收敛，故不把当前偏差归因于N=64短码长。
- **修改内容**：主仿真记录每条latent编码输出的实际1比例；码长诊断打印target/empirical latent p。
- **下一步**：重跑轻量码长诊断并检查每一流边缘。若边缘已偏离目标，修复source shaping/BSC构造；若边缘一致，再检查relation的联合实现。
- **结果目录**：本轮码长诊断为控制台内存结果；无新结果目录。
- **Rule reflection**：no new durable rule。

## 2026-08-28：确认BSC S方向正确，进入码长诊断

- **结果证据**：`run_s_construction_compare` 在相同16QAM设定下给出：reliable TV上界0.1769、经验能量0.6972；unreliable TV上界0.4115、经验能量0.9912。高可靠端作为S明显优于反向集合。
- **结论边界**：这确认BSC极化S的方向不是问题；当前偏差仍可能来自N=64有限长度，或Bhattacharyya proxy与SC precoder的构造精度。不能因reliable较好就宣称PMF已通过。
- **修改内容**：新增`run_pmf_blocklength_compare`，以16QAM的N=64/256/1024及80/40/20帧比较TV和经验能量，区分有限长度损失与构造问题。
- **下一步**：运行码长诊断；不执行BER扫描。
- **结果目录**：S方向诊断为控制台内存结果；已有PMF结果目录保持不变。
- **Rule reflection**：no new durable rule。

## 2026-08-28：BSC proxy PMF 结果更差，新增 S 方向对照

- **结果证据**：BSC+GA的 `20260828_230847_pmf_smoke` TV上界为0.1546/0.1767/0.1917/0.1975，较旧GA-only结果更差；不能用更多帧把这种系统性偏差解释为采样误差。
- **修改内容**：BSC+GA构造增加可控S方向；新增 `run_s_construction_compare`，固定16QAM和所有其他条件，只比较BSC可靠端与非可靠端选择S的PMF/能量。
- **下一步**：用户运行该诊断后，根据同口径结果决定修正S方向、替换BSC proxy，或评估码长效应；此前不运行BER扫描。
- **结果目录**：BSC+GA对照为 `16QAM_Polar/v3/results/20260828_230847_pmf_smoke/`；新诊断仅输出内存表，待决定后再写正式产物。
- **Rule reflection**：no new durable rule。

## 2026-08-28：PMF smoke 暴露 GA-only S 集偏差，切换 BSC+GA

- **结果证据**：`20260828_195508_pmf_smoke` 中TV上界为8/16/32/64QAM的0.0994/0.1112/0.1229/0.1316；按smoke阈值0.10，只有8QAM勉强通过，整体不能进入BER扫描。经验RF能量也系统性高于model（例如16QAM 0.6316 vs 0.5200），偏向高能点的程度不足。
- **根因与修改**：原v3将同一AWGN-GA排序同时用于S/I/F，与已确认的BSC+GA方案不一致。新增BSC Bhattacharyya极化proxy选S，排除S后用GA选I，剩余为F；主仿真改接新构造，并新增p/1-p对称性与集合分割诊断。
- **边界**：BSC proxy是近似构造，尚不是论文严格的虚拟信道Monte Carlo构造；需先运行新诊断及重跑PMF smoke，不能将本次失败归咎于抽样波动。
- **受影响路径**：v3 polar/core/diagnostics、L3、loop board、README和本周报。
- **结果目录**：`16QAM_Polar/v3/results/20260828_195508_pmf_smoke/`（失败但保留用于对照）。
- **Rule reflection**：no new durable rule。

## 2026-08-28：新增统一 PMF smoke 入口

- **修改内容**：新增 `run_gray_qam` 作为v3主入口；默认按M=8/16/32/64运行真实整形码字，保存model/empirical PMF、逐帧PMF、能量、TV点估计及cluster-bootstrap 95%上界。核心仿真增加可选逐帧PMF收集，新增cluster统计函数。
- **操作**：MATLAB执行 `setup_paths; summary = run_gray_qam`。结果写入 `16QAM_Polar/v3/results/时间戳_pmf_smoke/`，包含CSV、MAT、README和PNG。
- **边界**：N=64、80帧、120dB，仅验证分布统计链路；不构成BER曲线或正式PMF门禁。构造仍标注GA approximate。
- **受影响路径**：v3 core/analysis/顶层入口/setup_paths、对应L3、loop board、v3 README和本周报。
- **结果目录**：待用户运行生成。
- **Rule reflection**：no new durable rule。

## 2026-08-28：非均匀relation完整环回通过

- **证据**：用户运行扩展后的 `test_unit0_noiseless_roundtrip`，4个均匀基线与16个整形组合全部PASS。组合覆盖M=8/16/32/64、seed=17/29、p与1-p，32/64QAM使用冻结8-PAM关系。
- **确认范围**：真实非空S/I、非单位relation映射、全星座latent LLR符号，以及120 dB近似无噪声下各流payload恢复；未据此宣称实际发送PMF匹配、能量单调或有限SNR性能通过。
- **修改**：仅同步loop board/issues和两份相关L3契约，未改代码或运行新仿真。
- **下一步**：实现按独立帧保存经验PMF/能量及统计区间的诊断与时间戳产物，同时补齐target→model及冻结关系的逐点指标，再进入正式BER扫描。
- **结果目录**：无，当前证据为用户MATLAB输出。
- **Rule reflection**：no new durable rule。

## 2026-08-28：登记8-PAM矩阵，扩展非均匀relation环回

- **修改内容**：新增 `frozen_gray_pam8_relation`，登记用户输出T=`[0 0 1;1 0 0;1 1 0]`及版本；扩展原 `test_unit0_noiseless_roundtrip`，在8/16/32/64QAM下覆盖两个seed、p与1-p、非空S/I、非单位relation的完整星座查表/latent LLR符号/编码环回。
- **指标边界**：mean KL=2.521e-3来自前次输出，max KL约0.0067；此次cell仅显示尺寸，未获得p数值，未编造p或完整精度指标。2-bit非单位关系仅作测试夹具。
- **验证**：用户给出的T可逆性此前测试PASS；本次扩展代码尚未运行。用户下一步运行原名 `test_unit0_noiseless_roundtrip`，不再重复168矩阵搜索。
- **影响路径**：v3 modulation/diagnostics、对应L3、loop board/issues与本周报；未修改v2，未跑长仿真。
- **结果目录**：无；冻结矩阵已持久化到源码，完整搜索数据仍待采集。
- **Rule reflection**：no new durable rule。

## 2026-08-27：PMF/relation 专项重跑通过

- **证据**：用户清理函数缓存并核对 `which -all`，测试与gf2_inverse均来自v3；四种M非均匀PMF/identity查表PASS，8-PAM auto relation搜索PASS，mean KL=2.521e-3。不能仅据重跑成功确定之前重复错误是否由缓存造成。
- **修改内容**：同步loop board/issues与诊断L3；本次未修改代码。整数类型修复已有运行通过证据。
- **范围与限制**：四个已提供的基础诊断均已通过，但不等于Unit 0全部门禁完成。平均KL不是逐点验收，也不是误码率或经验PMF偏差；仍需具体T与逐点指标持久化、关系冻结、非单位relation及非均匀整形完整环回、结果写出等。
- **受影响路径**：`学习文档/高阶调制理论/通用GrayQAM-loop/`、`workbook/knowledge/L3/v3/diagnostics/l3_v3_test_unit0_pmf_relation.md`、本文件。
- **结果目录**：无；证据为用户回传MATLAB输出，未运行长仿真。
- **Rule reflection**：no new durable rule。

## 当前目标

在 `16QAM_Polar/v3/` 规划并后续实现调制阶数 `M` 驱动的单载波 Cartesian Gray QAM 数能同传极化码系统。首轮工作单元为 8/16/32/64QAM，SC precoder与SC decoder，v2保持不动作为限定回归参考。

## 2026-08-26：通用 Gray QAM loop 设计

- **修改内容**：依据用户逐项确认，新增 clarification、loop design、protocol、board、issues五份可交接文档；新增 L1研究方向 `l1_general_gray_qam_shaping.md`。
- **影响范围**：仅文档与知识库；未创建 v3 MATLAB实现，未运行仿真。
- **关键决策**：代码根为 `16QAM_Polar/v3/`；支持单载波 Cartesian Gray 8/16/32/64QAM；统一用每轴 latent `p + relation` 表达分布，`relation=[]` 为单位退化；完整符号先验 MAP LLR；固定均匀星座缩放；五项验收与跨 M 终止门禁。
- **验证方式**：对照 `CLAUDE.md`、workbook规则、v2固定16QAM实现和论文方法完成静态一致性审查；独立评审首轮FAIL、第二轮FAIL后已逐项修订。最终复审结论为PASS：multi-stream架构边界、消息条件化precoder、latent MAP LLR、8-PAM optimized relation门禁、cluster统计、机器阈值、码率/Goodput与SNR/能量口径均已闭合。当前只待用户最终确认loop设计。
- **受影响路径**：`学习文档/高阶调制理论/通用GrayQAM-loop/`、`workbook/knowledge/L1/l1_general_gray_qam_shaping.md`、本文件。
- **结果目录**：无（本轮未运行实验）。
- **未解决问题**：8-PAM optimized GF(2) relation尚需在Unit 0完成设计网格枚举、冻结和测试证据，已作为阻塞issue #1；接收端改为按 `z=T^-1b` 直接计算latent MAP/LSE metric。
- **Rule reflection**：no new durable rule；本轮规则均为该研究线的具体契约，已放入 loop protocol/L1，不新增跨项目 workbook规则。

## 2026-08-26：执行 loop — Unit 0 共享底座（进行中）

- **修改内容**：新建 `16QAM_Polar/v3/`，实现 Cartesian Gray 8/16/32/64QAM 构造、GF(2)可逆关系/枚举/auto选择、latent→轴/符号PMF、完整符号先验的latent MAP/LSE LLR、可强制已知u位的SC完整输出，以及 Unit 0 静态诊断；新增 `scripts/run_matlab_v3.sh` 与对应L3契约。
- **影响范围**：v3新代码与知识库；v2未修改。
- **验证方式**：已完成静态路径/接口审查与 `git diff --check`。尝试运行 `test_unit0_gray_qam` 时，PowerShell找不到Octave，WSL创建实例返回拒绝访问，故未产生可执行smoke证据；board保持◐，不宣称通过。
- **受影响路径**：`16QAM_Polar/v3/`、`scripts/run_matlab_v3.sh`、`workbook/knowledge/L3/v3/`、loop board/issues。
- **结果目录**：无（诊断未能启动）。
- **下一步**：用户本地运行 `scripts/run_matlab_v3.sh test_unit0_gray_qam`；通过后补消息条件化SC专项测试，再进入8QAM端到端单元。
- **Rule reflection**：no new durable rule；运行环境不可用已按现有环境/验证规则记录，没有新增通用规则。

## 2026-08-26：执行 loop — Unit 0 端到端 smoke 骨架（进行中）

- **修改内容**：新增 GA 近似 S/I/F 构造、按真实 payload 条件化的 SC shaping precoder、`b=Tz` 映射、F-only 接收端 SC 解码，以及 `sim_shaped_polar_gray_qam` 的 `source='latent_p'` 单载波 multi-stream smoke 路径；新增 forced-SC 和四种 M 的无噪声非零消息环回诊断。
- **影响范围**：仅 `16QAM_Polar/v3/`、对应 L3/loop 文档；v2 不变。此实现明确标注为 multi-stream BICM extension + GA approximate，不是参考论文严格 BSC 构造。
- **验证方式**：静态审查发送端先写 I/F 后只解 S、接收端只冻结 F、payload仅由 I 统计、LLR包含完整 `model_psym` 先验；未运行 MATLAB/Octave，原因仍为本机运行环境不可调用。因此测试尚未通过，不产生 BER/能量结论。
- **受影响路径**：`16QAM_Polar/v3/core/sim_shaped_polar_gray_qam.m`、`16QAM_Polar/v3/polar/build_stream_partition_ga.m`、`16QAM_Polar/v3/polar/shape_stream_sc.m`、`16QAM_Polar/v3/modulation/map_latent_bits_to_qam.m`、`16QAM_Polar/v3/diagnostics/`、本文件与 loop board。
- **结果目录**：无（尚未运行）。
- **下一步**：先由用户本地运行三项 Unit 0 检查；通过后，补 `energy_lambda/axis_pmf` 的 target→model solver 与时间戳结果写出，再按 8→16→32→64 的单元门禁推进。
- **Rule reflection**：no new durable rule。

## 2026-08-26：Unit 0 星座/LLR smoke 已通过，修复 v3 路径警告

- **修改内容**：用户在 MATLAB 运行 `test_unit0_gray_qam`，8/16/32/64QAM 的星座、每轴 Gray 相邻性、固定均匀缩放、均匀 latent PMF 与 noiseless latent MAP/LSE LLR 以及 GL(1,2)/GL(2,2)/GL(3,2) 枚举计数均通过；修复 `setup_paths` 将 v2 polar 误拼到项目根的多回退一级错误。
- **验证方式**：用户提供的 MATLAB 输出包含四个 `PASS` 和 GL counts `PASS`。修复后的路径为 `16QAM_Polar/v2/polar`；仍需重跑该测试确认警告消失，并运行 forced-SC、无噪声端到端两项 smoke。
- **受影响路径**：`16QAM_Polar/v3/setup_paths.m`、`workbook/knowledge/L3/v3/core/l3_v3_setup_paths.md`、loop board/issues、`workbook/troubleshooting-history.md`、本文件。
- **结果目录**：无（诊断测试未写结果目录）。
- **Rule reflection**：no new durable rule。

## 2026-08-26：Unit 0 消息条件化 SC smoke 通过

- **修改内容**：无新增代码；根据用户 MATLAB 执行 `test_unit0_forced_sc` 的结果，更新 loop 验收状态与 L3 健康度。
- **验证方式**：输出 `forced SC I/F constraints and receiver F-only mask PASS`。该测试确认 I/F 强制约束、payload 改变后码字改变，以及通信接收端掩码只含 F。
- **影响范围**：Unit 0 的发送端条件化和接收端集合角色门禁已通过；尚未验证完整调制—AWGN—demap—SC 无噪声环回。
- **受影响路径**：loop board、`workbook/knowledge/L3/v3/polar/l3_v3_shape_stream_sc.md`、`workbook/knowledge/L3/v3/diagnostics/l3_v3_test_unit0_forced_sc.md`、本文件。
- **结果目录**：无（诊断测试未写结果目录）。
- **Rule reflection**：no new durable rule。

## 2026-08-26：Unit 0 全 M 无噪声环回通过；补非均匀 PMF/relation 检查

- **修改内容**：用户运行 `test_unit0_noiseless_roundtrip`，8/16/32/64QAM 均通过非零消息的完整无噪声环回；新增 `test_unit0_pmf_relation`，覆盖非均匀 latent PMF、`z↔b` 标签查表，以及 8-PAM 的 GL(3,2) auto relation 搜索。
- **验证方式**：用户输出显示四种 M 均为 `nonzero-message noiseless roundtrip PASS`。新 PMF/relation 测试尚待运行，因而 Unit 0 未宣称全部完成。
- **影响范围**：通用 multi-stream 链路的 C 无噪声门禁已通过；B 非均匀 PMF 与 auto relation 仍是共享底座剩余门禁。
- **受影响路径**：`16QAM_Polar/v3/diagnostics/test_unit0_pmf_relation.m`、v3 README、L3诊断契约、loop board、本文件。
- **结果目录**：无（诊断测试未写结果目录）。
- **Rule reflection**：no new durable rule。

## 2026-08-26：修复 8-PAM auto relation 的整数矩阵乘法错误

- **修改内容**：`test_unit0_pmf_relation` 已通过 8/16/32/64 的非均匀 PMF 与 `z↔b` 查表部分；随后在 8-PAM auto relation 最终断言处暴露 `uint16 * double` 不受 MATLAB 支持。枚举器现统一输出 double GF(2) 矩阵，测试也显式以 double 验证逆矩阵。
- **验证方式**：用户提供的运行输出和 MATLAB 堆栈定位到 `selection.T * gf2_inverse(selection.T)`；修复后尚待重跑，不把前半段 PASS 记为 auto relation 已通过。
- **影响范围**：auto relation 候选矩阵现在可被 PMF、映射及可逆性检验一致使用；GF(2) 元素仍为 0/1。
- **受影响路径**：`16QAM_Polar/v3/modulation/enumerate_gf2_invertible.m`、`16QAM_Polar/v3/diagnostics/test_unit0_pmf_relation.m`、L3、loop issues、`workbook/troubleshooting-history.md`、本文件。
- **结果目录**：无（诊断测试未写结果目录）。
- **Rule reflection**：no new durable rule。
# 2026-09-15：16QAM发送能量权衡正式实验完成

- **正式运行**：在用户明确授权后运行5个p × 13个SNR × 3个seed × 每点300帧，共195个重复点、58,500帧；耗时1366秒（约22.8分钟）。
- **结果与审计**：[正式目录](../../16QAM_Polar/v2/results/20260915_122326_16qam_energy_tradeoff_formal/)包含逐帧/重复/汇总/工作点CSV与MAT、四图PNG/PDF/FIG、检查点、源码快照和SHA256。自动审计验证计数、唯一键、CSV/MAT一致性、能量/误码/加权BLER分母、配对归一化、CI和工作点连接，195重复点/58,500帧PASS；四张正式PNG已视觉检查。
- **指标口径**：用户确认的“整流效率”在本阶段表达能量强度，采用真实发送符号均方并按同seed/SNR的p=0.5归一为1；固定星座缩放，不使用RF–DC整流模型。p=0.1的单位能量在13个SNR上为1.353—1.400。
- **代表点**：8 dB的三种角色均为p=0.1；14 dB通信优先p=0.4、能量/折中p=0.1；20 dB通信优先p=0.5、能量优先p=0.1、折中p=0.3。Pareto仅是每SNR五个离散p均值的描述性比较。
- **边界**：SNR为v2历史标签，实际Es/N0=标签−3.0103 dB；Goodput=R×(1−BER)，不是分组吞吐量；3 seed的t区间精度有限。中期DOCX/PPT尚待编辑和渲染QA。
- **Rule reflection**：no new durable rule。本轮沿用已确认的能量代理、长仿真授权、时间戳产物、可恢复检查点和可追溯审计规则，无需新增跨项目约束。
# 2026-09-15：重构前两项中期PPT材料的逐图证据链

- **结构决策**：使用全局`grill-me`逐项确认，使用`presentations`约束页面叙事和图表可读性。先保证内容完整，演练时再删减；任务一展示v3的Energy、BER和64QAM PMF，任务二集中展示2026-09-15正式16QAM四图。原始图保持不变，PPT旁注中文结论。
- **材料重构**：[任务一中期PPT材料](../../学习文档/高阶调制理论/通用GrayQAM-loop/中期PPT材料.md)重构为5页，[任务二中期PPT材料](../../学习文档/高阶调制理论/16QAM整流效率-loop/中期PPT材料.md)重构为6页。每张图统一包含页面文字、原图路径、数据验证、图像解说、核心结论、讲稿、边界和答辩追问。
- **验证**：所有本地Markdown链接可解析；CSV自动断言核对任务一8组能量增量、12条BER门禁、64QAM三个PMF上界，以及任务二195重复点、58,500帧和8/14/20 dB工作点，全部PASS。`codex-plan-review`按仓库证据自审通过；`simplify`确认逐页重复字段属于有意模板，不合并。
- **剩余工作**：用户审阅两份内容源后，按现有模板修改中期PPTX和DOCX，并执行渲染QA。当前未改PPTX/DOCX。
- **Rule reflection**：no new durable rule。逐图证据、解说和讲稿统一进入`中期PPT材料.md`是本次材料结构约定，已写入两份内容源，不新增跨项目workbook规则。

# 2026-09-16：中期PPT能量主图、BER非单调解释与文献依据补强

- **修改内容**：第3页主图由13面板改为14 dB单一代表SNR的五点能量图，原13面板保留为附录；第2/4/5页补充`fixed_esn0`、普通SC/默认QAM LLR和逐bit BER/K加权解释；新增快速文献证据说明。
- **关键重算**：正式逐帧数据表明，p=0.1在8/14/20 dB的bit2/4平均BER分别约0.498/0.473/0.136，而每路K从p=0.5的512降至240；bit1/3在同三点约0.173/0.0010/0。聚合BER交叉可由逐路BER与K权重直接重算，不能只归因于Monte Carlo波动。

## 2026-09-16：新增v3 N=256/1024与理论三层对照入口

- **修改内容**：新增`run_gray_qam_blocklength_compare.m`及统一入口模式`blocklength_compare_smoke/blocklength_compare`，在四种QAM和三个lambda下同时保存理想target、latent model与真实码字empirical的PMF和发送RF能量代理量。
- **比较口径**：正式模式只改变`N=256/1024`；帧数、source-MC样本数、构造seed、运行seed、SNR模式和lambda网格保持一致。另行输出empirical-target与empirical-model TV上界，区分target→model拟合损失和有限长实现损失。
- **影响范围**：新增实验入口、v3 README、L2契约和loop next_plan；不修改既有结果，不自动运行正式仿真，不产生N=1024 BER结论。
- **验证方法**：MATLAB `checkcode`对新增入口和统一入口均为0 issue；`blocklength_compare_smoke`已以8QAM、lambda=0/0.5、N=256/1024、每点2帧完成微型运行，最终结果目录`16QAM_Polar/v3/results/20260916_221629_energy_lambda_blocklength_smoke/`。入口内置行数、唯一键、有限值及target/model不随N变化的行为断言；该极小样本只验证N=1024路径、三层能量/TV字段、CSV/MAT/日志和PNG/PDF/FIG产物，不提供码长优劣结论。正式`blocklength_compare`仍由用户本地运行后再记录结论。
- **Rule reflection**：no new durable rule；现有码长受控比较、时间戳产物与长仿真授权规则已覆盖。

### 正式运行结果

- **运行授权与命令**：用户明确允许使用命令行运行；在项目根执行`./scripts/run_matlab_local.ps1 "cd(fullfile('..','v3')); summary = run_gray_qam('blocklength_compare');"`，约52秒完成。
- **结果目录**：`16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/`，24个`M × lambda × N`组合全部完成，CSV/MAT/checkpoint/日志及两组PNG/PDF/FIG齐全。
- **PMF结论**：N从256增至1024后，12个`M × lambda`点的empirical-target TV 95%上界全部下降。lambda=0.5时，8/16/32/64QAM依次由`0.03639/0.04236/0.05924/0.07475`降至`0.02575/0.03089/0.05103/0.05230`。
- **能量结论**：12点中11点的经验能量绝对理论差缩小；唯一例外为64QAM、lambda=0的机器量级波动。lambda=0.5时，N=1024经验能量分别为`1.18197/1.12313/1.21774/1.14725`，较N=256更接近target `1.21434/1.15790/1.27453/1.19872`。
- **解释边界**：增大码长稳定改善PMF逼近，但没有消除经验能量低于理论的系统性差距；32/64QAM还包含target→model近似，主要剩余差距仍在model→empirical有限长构造。该实验为120 dB PMF/能量隔离检查，不提供N=1024 BER排序。
- **Rule reflection**：no new durable rule；现有受控变量、长仿真授权和结果产物规则已覆盖。
- **文献扫描**：安装全局`research-systematic-literature-review` Skill并按`rapid-scan + theoretical/mathematical`检索。确认非均匀QAM MAP BER/SER、BICM AIR/GMI和非对称polar编码均有成熟定量理论，但未发现直接覆盖本项目特定有限长full-chain的单一闭式BER文献。
- **影响范围**：仅中期说明材料、派生SVG和文献依据；未修改仿真链路，未运行新的Monte Carlo实验。
- **验证方法**：从正式`frame_results.csv`与`point_summary.csv`重算代表点；核对`sim_shaped_polar_16qam.m`和正式入口的噪声、LLR、译码器及K/S集合逻辑；检查新增SVG数值与14 dB汇总一致。
- **涉及路径**：`学习文档/高阶调制理论/16QAM整流效率-loop/中期PPT材料.md`、`定量分析文献依据.md`、`figures/energy_p_14db.svg/.png`、本文件。
- **结果目录**：复用`16QAM_Polar/v2/results/20260915_122326_16qam_energy_tradeoff_formal/`，无新仿真目录。
- **Rule reflection**：no new durable rule。

# 2026-09-16：在任务二讲稿中显式补充BER相对排序非单调

- **修改内容**：第2页讲稿明确说明不同p的BER相对大小不单调、曲线随SNR交叉；第4页讲稿明确说明同一SNR下能量升高不保证BER降低；三句总结同步保留该结论。
- **影响范围**：仅`学习文档/高阶调制理论/16QAM整流效率-loop/中期PPT材料.md`及本周报，不改变数据、图或仿真链路。
- **验证方法**：检索讲稿和三句总结，确认“BER相对大小并不单调”在口头讲述文本中显式出现，而非只存在于图像解说。
- **Rule reflection**：no new durable rule。

# 2026-09-17：中期PPT材料嵌入N=256/1024正式对照图

- **修改内容**：在任务一`中期PPT材料.md`第2页“码长补充对照”中直接嵌入正式能量对照图和PMF TV对照图，不再只提供文字链接；补充图例含义、数据路径和结论边界。
- **影响范围**：仅Markdown汇报内容源与本周报，不修改仿真代码、结果数据或PPTX。
- **验证方法**：核对两张图片与`blocklength_compare.csv`均存在，Markdown相对路径可从材料文件位置解析。
- **涉及路径**：`学习文档/高阶调制理论/通用GrayQAM-loop/中期PPT材料.md`、本文件。
- **结果目录**：复用`16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/`，未运行新仿真。
- **Rule reflection**：no new durable rule；现有结果图嵌入与阶段文档记录规则已覆盖。

# 2026-09-17：新增多载波任意 Gray-QAM 能量分布可调理论说明

- **修改内容**：在通用 GrayQAM loop 中新增答辩用理论文档，从固定星座缩放、能量倾斜分布 `P_lambda(x) ∝ exp(lambda|x|^2)` 出发，推导平均能量单调性、I/Q轴分解、latent概率与Polar S/I/F实现，并扩展到OFDM的分组/子载波级 `lambda_k`、Parseval能量关系、Rayleigh接收能量、先验LLR、Goodput资源分母和公平性约束。
- **影响范围**：仅理论与资料导航，不修改仿真代码，不产生新的多载波实验结论。
- **验证方法**：逐式对照v3 `build_cartesian_gray_qam`、`build_energy_lambda_spec`、`build_qam_model_pmf`、`llr_gray_qam_latent_lse` 和 `sim_shaped_polar_gray_qam`；对照多载波loop的分组编码、物理链路、能量与Goodput协议；检查文档内部公式、边界和本地链接。
- **涉及路径**：`学习文档/高阶调制理论/通用GrayQAM-loop/多载波任意GrayQAM能量分布可调理论说明.md`、同目录`README.md`、本文件。
- **结果目录**：无（未运行仿真）。
- **Rule reflection**：no new durable rule；任意QAM的适用边界、功率公平性和能量术语已写入本理论文档，现有workbook规则已覆盖文档解释与结果边界。

# 2026-09-17：修复多载波 Gray-QAM 理论文档的 Typora 公式渲染

- **修改内容**：将理论文档中的行内数学分隔符统一由 `\\(...\\)` 改为 `$...$`，独立公式统一由 `\\[...\\]` 改为独占行的 `$$...$$`，以适配 Typora 的稳定数学渲染路径；不改动任何公式推导、变量定义或研究结论。
- **影响范围**：仅 `多载波任意GrayQAM能量分布可调理论说明.md` 的 Markdown 排版。
- **验证方法**：静态检查确认无残余 `\\(` / `\\[` 分隔符、70 个独立公式分隔行成对、每行美元符号成对且无不可见控制字符。
- **结果目录**：无（文档格式修复，未运行仿真）。
- **Rule reflection**：no new durable rule；该问题属于 Typora 对数学分隔符的兼容性处理，不需要新增项目通用规则。

# 2026-09-17：固化 Typora Markdown 公式格式规则

- **修改内容**：将 Typora 数学公式兼容性规则加入根目录 `AGENTS.md`，并将完整、唯一维护版本加入 `CLAUDE.md`：行内公式使用 `$...$`，独立公式使用独占行的 `$$...$$`；禁止使用 `\\(...\\)` / `\\[...\\]`，修改后检查分隔符成对、旧分隔符和不可见控制字符。
- **影响范围**：后续所有面向 Typora 的 Markdown 理论、汇报与学习文档；不修改仿真逻辑或已有实验结果。
- **验证方法**：核对根 `AGENTS.md` 可见提醒和 `CLAUDE.md` 的唯一维护版本一致，且两处均明确 Typora 公式分隔符和收尾检查要求。
- **结果目录**：无。
- **Rule reflection**：added/updated `CLAUDE.md` because Typora formula delimiters are a reusable project-wide documentation compatibility rule.

# 2026-09-18：补充能量倾斜 PMF 的逐符号物理解释

- **修改内容**：在多载波 Gray-QAM 理论文档的 $P_\lambda(x)$ 能量倾斜分布公式后，原位补充 $P_\lambda(x)$、$x$、$|x|^2$、$\lambda$、$\exp(\cdot)$、$Z(\lambda)$、$\mathcal X$、求和哑变量 $x'$ 及排版符号 $\qquad$ 的逐项物理/数学意义，并说明分子、分母和 PMF 归一化的关系。
- **影响范围**：仅理论文档的答辩可读性，不修改公式、仿真代码或实验结论。
- **验证方法**：检查新增内容紧随目标公式，且所有行内数学均使用 Typora 规定的 `$...$` 格式。
- **结果目录**：无。
- **Rule reflection**：no new durable rule；本次是对既有理论文档的局部可读性补强。

# 2026-09-18：首次出现 PMF 时补充全称与中文名

- **修改内容**：将理论文档中首次出现的 PMF 改为“PMF（Probability Mass Function，概率质量函数）”，后续继续使用缩写，兼顾术语准确性与阅读流畅性。
- **影响范围**：仅理论文档术语释义，不修改公式、仿真代码或实验结论。
- **验证方法**：检索确认第一次 PMF 出现位置包含英文全称和中文名，后续缩写保持一致。
- **结果目录**：无。
- **Rule reflection**：no new durable rule；属于既有文档可读性规范的局部应用。
