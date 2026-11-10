# L2 · P2共同环境短运行原型

- **flow_id**: l2_p2_common_environment
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_common_environment.m
- **runtime**: minutes
- **needs_user_run**: false（仅短smoke；正式功能被拒绝）
- **validates**: l1_multicarrier_ofdm（仅调试，不更新假设验收）

## Purpose

固定幅度三种S的独立短运行原型，检验共同h/噪声及随机角色；不是正式通信或模型结果。

## Pipeline

1. 读取源模板及实际S/I/F；通过l3_p2_paired_seed分角色生成h、消息、辅助、供体及噪声。
2. 通过l3_p2_transmit_block构造各组网格，scale固定1；l3_ofdm_common_noise_roundtrip施加共同信道和噪声。
3. 原接收机解码并保存raw、repetitions、参数、seed、源码快照和README。

## Inputs / outputs

默认p2_default_config，prototype只接受短运行、空power/model文件和predict=false；现仍使用 $N_0=10^{-s/10}$，即参考功率1，不是已冻结的新P_ref。输出 `results/YYYYMMDD_HHMMSS_p2_common_env_*`。

## Acceptance / limits

smoke核验h及噪声种子、I/S、scale与源快照；噪声样本本身未落盘。不能用种子相同等同全链路输出独立审计；接收矩统计、独立PMF、非线性、预测、正式授权和新的P_ref均未实现。禁止正式运行、禁止从少量误码下科研结论。

## Evidence

20261106_162019_p2_common_env_smoke_pilot_1cf97e7c：N32、一信道一帧三case，MATLAB退出0，raw核对h/seed/I/S/scale通过。此前20261106_161952为快照漏包含新包装函数的首版试运行，保留但不得作为完整可复现证据。


## 2026-11-06 参考时域功率修订

新原型采用理想独立零均值、单位符号能量及占用格布局计算 $P_{ref}=G N/(N_{sc}^2 T)$（G为组数，T为OFDM块数），假设参考各频点非相干、CP期望等于无CP。$N_0=P_{ref}10^{-s/10}$；GA构造标签为 $-10\log_{10}(N_{sc}N_0)$，对应归一符号平均能量1。候选实际功率不是该参考。row和raw保存reference_time_power/noise_complex_time_power/construction_snr_db。20261106_162154 smoke对N32配置核查参考96/(2×64²)、N0、GA标签及配对seed/h一致通过；一个码字每组非科研证据。旧162019使用P_ref=1，不可直接比较。正式功能、预测和PMF资产仍未实现。


## 2026-11-06 接收包络矩集成

短运行原型增加L=1/L=4接收包络二、四阶矩，调用l3_ofdm_oversampled_channel与l3_rf_envelope_moments，断言L4抽取原采样点等于基础信道。20261106_162336 smoke检查RF均方与L1二阶矩一致、L4第四矩有限；一信道一帧三S仅行为验证。采用理想逐符号插值、负Nyquist和整数时延tap，不是模拟滤波、物理DC或收敛保证。


## 2026-11-06 探索独立PMF及预测通路

短power_calibration数据经l3_p2_common_freeze_pmf冻结经验PMF；pilot须提供资产，验证角色/seed、N/资源/模板/SNR/cases、PMF尺寸与非负归一，按当前h和N0运行p2_llr_reference与p2_predict_ga。模型校准与正式模式仍不可用。8101训练两帧×三case，8301独立一帧smoke `20261106_162557_p2_common_env_smoke_pilot_fbf52935` 三case预测有限。训练数据极小，未验证绝对BER或速度，也非正式PMF门禁。


## 2026-11-06 PMF资产前置拒绝

正式模式、PMF缺失、训练角色不符和资源配置不一致在创建输出目录前拒绝；`test_p2_common_pmf_guards`通过。20261106_162839独立pilot回归预测三case有限。正式模型/PMF验收仍缺。


## 2026-11-06 探索模型训练与独立测试

允许model_calibration短运行及test_seen独立短运行；l3_p2_common_freeze_model仅训练角色并绑定PMF SHA256，test_seen检查模型角色、seed、PMF哈希和配置。N32训练 `20261106_163018_p2_common_env_smoke_model_calibration_a359941f`、测试 `20261106_163021_p2_common_env_smoke_test_seen_11c6c26f` 每case仅一帧；拟合不足回退，独立门槛为样本不足。test_unseen及formal尚不支持；旧门禁未被修改。


## 2026-11-06 未见组合短通路

PMF训练资产可包含超集case，运行时按ID及完整case配置匹配子集；test_unseen须与模型校准策略不重叠并绑定相同PMF哈希。训练PMF事先观察预留组合，未见定义仅针对模型误码拟合。8102 PMF训练 `20261106_163215_p2_common_env_smoke_power_calibration_b44be893`、8401模型 `20261106_163217_p2_common_env_smoke_model_calibration_a8288c4b`、8601未见 `20261106_163219_p2_common_env_smoke_test_unseen_7d4b898a` 全部仅每case一帧，9行预测有限而独立评估样本不足；formal仍禁止。


## 2026-11-06 L4/L8逐帧四阶矩比较

原型新增L8二四阶矩与每帧相对差均值，分母为同一帧L8四阶矩，零分母记录NaN。逐帧L8抽取与L4样本一致。N32一信道两帧/每case `20261106_163838_p2_common_env_smoke_pilot_a411e3c9`，三case相对差均值约0.149%、0.358%、0.459%；均为有限探索样本，不能代表全部策略和信道，也不证明物理前端或DC收敛。


## 2026-11-06 实际随机输入哈希

短原型raw追加channel_hash与每帧noise/payload/auxiliary/donor SHA256：按double实部向量再虚部向量的机器字节计算；对跨平台字节序须显式规范后才可跨平台比对。N32、一信道两帧三S `20261106_163955_p2_common_env_smoke_pilot_b33e6f54` MATLAB原始哈希核对：跨方案h/n与各输入同组一致，不同帧噪声不同，部分角色哈希不同；后者不构成统计独立证明。旧文件无字段，不回填。


## 2026-11-06 原始配对证据审计

新增l3_p2_audit_common_pairing，验证注册的每个信道/SNR/case覆盖、实际h及记录的h哈希、N0/scale及逐帧输入哈希一致；短smoke `20261106_163955_p2_common_env_smoke_pilot_b33e6f54` 三行通过，合成错误测试通过。噪声/payload数组未保存，无法独立重算其哈希，不能把校验提升为PRNG独立性证明。


## 2026-11-06 信道依赖积分在线计时修正

短原型 `online_seconds` 含当前信道LLR quadrature与GA，另列online_ga_seconds及online_reference_seconds；哈希与L4/L8矩测量开销从通信计时剔除并单列。尚无PMF训练离线摊销，不以一次短smoke宣称10倍门槛。此前把信道依赖积分列为离线的原型数字不可用于速度验收。结果 `20261106_164655_p2_common_env_smoke_test_seen_22bc2909` 校验在线包含两项，单信道单帧仅功能检查。


## 2026-11-06 离线策略独立短测

允许test_seen/test_unseen在predict=false且无model_file下进行离线策略验证；预测开启的独立测试仍强制冻结模型。训练seed8401选择固定候选后，test_seen seed8501两信道两帧/候选结果 `20261106_165514_p2_common_env_pilot_test_seen_89d0251b` 经raw/配对审计与四个现有基线比较；能量J为未标定代理且缺坏信道纯能量基线，无正式收益结论。


## 2026-11-06 坏信道纯能量基线

新增bad_channel_energy_only_shaped：三组p=[.5,.3,.1]，第3低可靠性组全零payload仍编码发射但不计信息比特、译码块或码率，预测模式暂不支持。配对审计校验该组零payload哈希并对其余信息组、共同信道噪声严格匹配。训练 `20261106_165829_p2_common_env_pilot_model_calibration_37402adf` 与独立测试 `20261106_165900_p2_common_env_pilot_test_seen_2345a5ce` 各2信道×2帧，三计划基线已可纳入短接口对照；非正式统计或DC结论。


## 2026-11-06 27组合独立短通路

新增strategy_training/9211和strategy_test/9212，禁止对应保留槽作为新映射power_validation；训练与测试各为N1024、27组合+纯能量基线×两信道×单帧。训练结果 `20261106_170217_p2_common_env_pilot_strategy_training_b657112d`，独立测试 `20261106_170258_p2_common_env_pilot_strategy_test_7d9fec20`，配对及raw评价通过。门槛.2/.2和J=M2+M4仅示意，未标定DC、不具正式统计；纯能量低组不计有效信息。


## 2026-11-06 探索策略资产与raw验证

strategy_training short run先经l3_p2_audit_common_pairing和l3_p2_validate_common_raw_metrics再由l3_p2_freeze_exploratory_strategy写不可覆盖资产，绑定参数/表/cases/源码哈希清单及逐raw哈希；l3_p2_evaluate_strategy_asset验证训练哈希后调用独立测试评价。N1024 27组合两信道单帧训练/测试通路与资产哈希篡改、测试冒训练拒绝测试通过；仅核验源码哈希清单文件本身，没有逐个重算源码副本。非正式结论。


## 2026-11-06 策略资产源码快照逐项核验

新增l3_p2_verify_common_snapshot；训练与测试每个目录50个源码副本及1外部模板与原清单一致。冻结和独立评价现先执行该核查；合成篡改/缺失测试和已有资产回归通过。清单真实性依赖冻结绑定，外部文件路径迁移尚无方案。


## 2026-11-06 L8/L16探索

短原型增加L16二四阶矩及逐帧相对差|M4_L8−M4_L16|/M4_L16，逐点断言L16抽取与L8一致；`20261106_172200_p2_common_env_pilot_strategy_training_d315f961` N1024、六候选、两信道两帧，共24候选×信道×帧记录，中位0.000847618、最大0.00438084。只有2独立信道，无预注册容差，不代表物理前端收敛或正式门禁。
