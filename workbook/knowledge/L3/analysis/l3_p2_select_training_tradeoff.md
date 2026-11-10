# L3 · p2_select_training_tradeoff

- **method_id**: l3_p2_select_training_tradeoff
- **file_path**: 16QAM_Polar/v2/analysis/p2_select_training_tradeoff.m
- **module**: analysis
- **health**: degraded（合成测试通过；未验证物理DC和独立策略）

## Signature

`result = p2_select_training_tradeoff(T,max_ber,min_goodput,beta2,beta4)`：单seed/SNR且仅model_calibration角色、shaped配置、完整同信道配对的训练表；返回候选均值表、可行性/非支配标记、选中case或no_feasible。

## Purpose / Math

对每个候选等权平均独立信道 $BER$、Goodput 和代理 $J=\beta_2M_2+\beta_4M_4$。BER≤上限且Goodput≥下限才可行；以Goodput和代理分别越大越好标识可行非支配点，再在可行点中按代理、Goodput降序和BER升序选取，完全相同按case ID字典序。

## Numerical Notes

$M_2,M_4$为L4归一复包络离散矩；系数未标定时J为无量纲示例代理，不是DC功率或效率。均值约束不是逐信道可靠性保证；独立测试严禁进入选择。拒绝缺失、重复信道、不同帧数、非finite、非训练角色及无效阈值。

## Dependencies

无其他项目方法依赖；使用MATLAB table功能。

## Verification status

MATLAB `test_p2_select_training_tradeoff`通过，覆盖非支配集、无可行解、相同值排序、缺配对、测试集角色和NaN；尚无正式训练/独立验证结果。


## 2026-11-06 独立验证信息补充

返回结构体新增training_seed和reference_snr_db，以便独立测试核对；不替代资产冻结和真实h/n指纹审计。test_p2_select_training_tradeoff回归通过。


## 2026-11-06 独立策略角色

新增strategy_training/strategy_test角色支持；训练与测试独立seed及raw配对审计保持，模型calibration/test_seen旧入口兼容。N1024、27组合及纯能量基线的两信道单帧训练/测试仅完成探索通路，未验证统计收益或DC。
