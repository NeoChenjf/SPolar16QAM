# L3 · p2_common_freeze_pmf

- **method_id**: l3_p2_common_freeze_pmf
- **file_path**: 16QAM_Polar/v2/analysis/p2_common_freeze_pmf.m
- **module**: analysis
- **health**: degraded（短训练资产已跑通，未通过正式PMF验收）

## Signature

`asset_path = p2_common_freeze_pmf(training_dir)`：从短power_calibration目录每个case/SNR/信道读取raw计数，输出不可覆盖的 `frozen_exploratory_pmf.mat`。

## Purpose / Math

独立训练分布：各配置和SNR下按组跨信道与帧累积16标签计数，再除以组内总计数；存完整cfg、cases、帧数和训练目录。只接受非正式power_calibration、全覆盖、scale=1、每组计数等于N×帧数。

## Numerical Notes

输出仅为探索短样本经验PMF；不证明目标分布通过或适合正式预测。不进行平滑，有限样本零概率可出现；不能使用训练结果评估自身误差。模型跑通不是物理/统计验收。

## Dependencies

无其他项目方法依赖；读取run_p2_common_environment的raw资产。

## Verification status

N32、8101训练两帧/配置，8301独立pilot一帧预测可运行，3case预测值有限；尚缺自动化错误路径、正式PMF/独立预测精度和速度验收。
