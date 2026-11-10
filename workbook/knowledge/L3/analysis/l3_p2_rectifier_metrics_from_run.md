# L3 · p2_rectifier_metrics_from_run

- method_id: l3_p2_rectifier_metrics_from_run
- file_path: 16QAM_Polar/v2/analysis/p2_rectifier_metrics_from_run.m
- module: analysis
- health: exploratory

`output=p2_rectifier_metrics_from_run(run_dir,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)` 核验保存的源码、配对和raw指标，然后对每行 L4 二/四阶复包络矩应用 `rectifier_proxy_from_moments`，保留参考点、信道、候选和帧数，并逐行输出输入RF功率、电流代理及适用范围状态。输入量纲、阻抗、系数、范围、帧窗口等物理假设由调用方给出；程序不能验证器件或范围真实有效。L4理想插值不是模拟前端。输出不是实测DC或效率。

MATLAB对已有探索训练批56行进行假设参数检查，宽范围时均有值、收窄范围时均返回out_of_range及NaN；未新增通信仿真。依赖 l3_p2_verify_common_snapshot、l3_p2_audit_common_pairing、l3_p2_validate_common_raw_metrics、l3_rectifier_proxy_from_moments。
