# L3 · p2_evaluate_predictions_checked

- method_id: l3_p2_evaluate_predictions_checked
- file_path: 16QAM_Polar/v2/analysis/p2_evaluate_predictions_checked.m
- module: analysis
- health: exploratory

## Signature / purpose

`report=p2_evaluate_predictions_checked(T)` 检查所需列存在、每行仿真/在线时间均有限且大于零、帧数有限正整数，再调用原 `p2_evaluate_predictions`；非空分割的加速比必须有限。保留旧函数与历史结果。输出范围明确为数值探索门禁。

## Limitations

没有核实数据来源、资产哈希、真实独立信道与训练/测试泄漏，也不替代其余输入数据的全面有效性核验；不能用于正式科研验收。计时为零需改善测量精度或增加计时重复，而非取无穷大。

## Verification

MATLAB R2020b 合成数据正向与 seen/unseen 空分割、零/负/NaN/Inf 在线时间、零仿真时间、小数帧数、单信道重复输入的短测试通过。依赖 l3_p2_evaluate_predictions。
