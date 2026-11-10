# L3 · p2_compare_rectifier_csi

- method_id: l3_p2_compare_rectifier_csi
- file_path: 16QAM_Polar/v2/analysis/p2_compare_rectifier_csi.m
- module: analysis
- health: exploratory

`output=p2_compare_rectifier_csi(policy,test_dir,baseline_ids)` 对探索性电流代理CSI规则执行已审计的逐信道配对测试，并用同一电压、阻抗、系数和范围逐行重算被选策略与基线的电流代理差。任一超出假设范围，该差值为NaN并标记out_of_range，BER/Goodput配对值仍保留。不是DC功率。未对传入policy进行事前可信冻结或证明测试未被观察；调用者应负责源与时间证明。

MATLAB使用既有2个测试信道×4基线得到8条假设范围内记录，直接与加权计算一致；测试用改窄范围后8条均标out_of_range且代理差为NaN。该后者是错误路径，不代表有效器件范围。依赖 l3_p2_compare_csi_policy、l3_p2_rectifier_metrics_from_run。
