# L3 · p2_freeze_rectifier_csi

- method_id: l3_p2_freeze_rectifier_csi
- file_path: 16QAM_Polar/v2/analysis/p2_freeze_rectifier_csi.m
- module: analysis
- health: exploratory

`digest=p2_freeze_rectifier_csi(training_asset,output_file,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)` 核验探索训练资产绑定的参数、表、case、源码清单及所有raw后重训非线性CSI策略，拒绝覆盖输出文件；保存policy及训练资产哈希并返回资产SHA-256。必须由调用方在独立可信位置于测试前保存digest；函数本身不能证明时间先后或来源不可篡改，不是正式冻结。

MATLAB在临时目录生成并与测试接口联动通过；临时资产已清理，历史测试已观察，未形成正式冻结资产。依赖 l3_p2_train_rectifier_csi_policy。
