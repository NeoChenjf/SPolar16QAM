# L3 · p2_common_freeze_model

- **method_id**: l3_p2_common_freeze_model
- **file_path**: 16QAM_Polar/v2/analysis/p2_common_freeze_model.m
- **module**: analysis
- **health**: degraded（仅探索训练/测试连通，非正式验收）

## Signature

`model_path = p2_common_freeze_model(training_dir)`：仅接受非正式model_calibration且使用PMF预测的目录，校验每行角色及seed，保存不可覆盖探索模型。

## Purpose / Math

调用p2_calibrate_model，以训练误码统计拟合全局logit变换；保留训练cfg、目录、PMF SHA256及探索状态。训练不足时保留原模型的明确fallback标记，不虚称拟合成功。

## Numerical Notes

只允许短运行探索，需独立test_seen；模型/PMF文件哈希与物理配置须与训练一致。不能用于test_unseen或正式结论；测试样本不足不判精度失败。

## Dependencies

- l3_ref: l3_p2_calibrate_model

## Verification status

N32、8401训练三case×1帧、8501独立test_seen各1帧，训练不足fallback且独立评价为样本不足；仅测试角色与接口，正式速度和精度未验收。


## 2026-11-06 未见组合探索入口补充

上文“不能用于test_unseen”被新原型取代：允许由同一独立PMF资产中的预留配置构造test_unseen，强制与模型校准strategy_p不重叠并检查PMF哈希、资源及controls。未见仅指模型通信误码拟合没见过组合；PMF训练事先覆盖这些组合，不是对未知符号分布的零样本泛化。依然不能用于正式结论。
