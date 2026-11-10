# L2 · p2_future_diagnostic

- pipeline_id: l2_p2_future_diagnostic
- entry: 16QAM_Polar/v2/experiments/multicarrier/run_p2_future_diagnostic.m
- status: diagnostic_only

## Contract

这是独立复制的新键短流程原型，保留原共同环境入口和正式拒绝；仅接受 `future_split=diagnostic_a` 或 `diagnostic_b`，拒绝候选正式测试split。信道/噪声/消息/辅助/供体使用 l3_p2_future_seed；候选ID不进入键，共享h/n。旧 `cfg.seed` 保留原配置角色检查及元数据兼容，但不决定本原型这些随机键；应以 `future_split` 和各键索引为准。预测、模型和PMF仍限探索资产。结果存带时间戳目录。

当前实现复制自旧短入口，存在重复维护风险；旧formal分支仍不可达且包含旧功率逻辑，不能删除顶层保护即作为正式入口。正式协议、训练资产、预算、独立键和验收需另实现并测试。

## Verification

N32、1信道×1参考点×1帧、三S，diagnostic_a短运行产生3条raw；78源码副本、配对和raw指标验证通过；`seen_first_v2` 被拒，formal模式被拒。诊断数据不能用于正式性能或盲测。原训练、测试候选域没有由该次smoke触及。

## 2026-11-06 未来诊断键的预测路径smoke

N1024、diagnostic_a、1信道×3参考点×三S×1帧，使用已有探索PMF并启用预测，结果 `results/20261106_213856_p2_future_diagnostic_smoke_model_calibration_a94fd1d8`。MATLAB对78源码副本、9条配对与raw指标、PMF计数、GA参考及预测表值回算通过。仅内部一致性检查，复用探索PMF与诊断键，不是独立模型训练、盲测、精度/速度门禁或正式资产。

诊断入口中随机键只由future_split和索引决定，不由旧purpose/seed决定；不同实验purpose若使用同一个diagnostic_a及索引会复用相应物理键，属于诊断用途，不能声称两者独立。正式设计须绑定独立split并作碰撞与角色校验。

## 2026-11-06 README随机键说明修正

新产物README记录future_split、键索引角色并标明旧seed不是物理随机键；旧产物README未写明，需要以其params.mat为准。N32短运行检查通过，历史输出未覆盖。

## 2026-11-06 点级恢复测试

项目results下临时复制单个历史诊断批，去掉末case后恢复，输入与误码计数重现；更改帧数的恢复配置被拒。MATLAB默认临时路径中 `movefile` 首次报系统找不到文件，根因未定；项目路径通过。仅覆盖N32单case点级，不覆盖帧内/正式规模断点。

## 2026-11-06 临时目录最小复现

在当前环境，独立MAT文件在默认MATLAB临时目录movefile失败且源仍存在，项目results临时目录同操作成功；未定位底层原因。该路径差异不等于正式断点恢复验收。

## 2026-11-06 checkpoint完整性检查

新诊断入口恢复前验证completed、表和raw集合及通信原始指标；缺raw或未提交raw拒绝并保留，避免静默跳过。N32临时副本的实际入口负向和合法恢复测试通过。PMF无噪条目仅检查文件集合；帧级/大规模与异常恢复仍未完成。旧源文件快照对应结果若引用修改前源码，按原版本独立复现，当前源码无法直接续跑不匹配的旧快照。

## 2026-11-06 无噪checkpoint补充

无噪角色在文件集合之外校验通信指标NaN及逐组逐帧计数基本约束；修改复制表和计数的负向测试、通信恢复回归通过。标签互换和原始样本来源未由计数总和证明。

## 2026-11-06 checkpoint摘要与旧诊断恢复兼容性

新checkpoint记录每个raw的SHA-256，恢复前逐项核验；无摘要旧checkpoint由新代码拒绝，旧历史产物不改，需用其原始快照进行复现。N32三S复制fixture中总标签数不变但换一个标签被拒，通信缺raw/孤立raw及合法恢复回归通过。若checkpoint和raw同时改变，摘要不能提供独立信任；此仍非正式恢复验收。
