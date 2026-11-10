# L3 · rectifier_proxy_from_moments

- method_id: l3_rectifier_proxy_from_moments
- file_path: 16QAM_Polar/v2/analysis/rectifier_proxy_from_moments.m
- module: analysis
- health: exploratory

`result=rectifier_proxy_from_moments(m2,m4,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)` 对既存复包络二/四阶矩应用与 `rectifier_moment_proxy` 相同的峰值包络载波平均假设。检查矩非负和 M4≥M2²、物理标尺及有效范围，输出RF输入功率与电流代理；未知器件、滤波、标定和模型适用范围时不能称实际DC功率。帧平均需使用相同样本数/窗口，不能由均方单独恢复四阶矩。

MATLAB对显式波形接口的等价性、超范围、非法矩及同均方不同四阶矩检查通过。初始测试直接比较浮点数导致断言失败，改用1e-12容差后通过；未修改历史实验。依赖数学定义同 l3_rectifier_moment_proxy。
