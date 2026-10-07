# L2 · run_b4b_energy_by_strategy_figure

- **flow_id**：`l2_b4b_energy_by_strategy_figure`
- **entry**：`run('experiments/multicarrier/run_b4b_energy_by_strategy_figure.m')`
- **输入**：B4b正式重复表`b4b_repetition_results.csv`。
- **处理**：先在每个“策略 × Rayleigh realization”内对六个SNR点的加噪前接收信号功率取均值，消去SNR维度；再以每策略30个独立realization计算均值与95%区间。
- **输出**：180条realization级CSV、6条策略汇总CSV、MAT、README，以及Energy-by-strategy图的PNG/PDF/FIG三种格式。
- **验收**：完整SNR覆盖、realization级均值与区间恒等式、最高/最低能量策略和三格式图均通过独立审计。
- **健康度**：PASS（2026-09-20，`20260920_211759_b4b_energy_by_strategy`）。
- **边界**：能量是Rayleigh多径后、加噪前的时域信号均方代理量，不是RF–DC整流效率；六个相关SNR点不作为独立样本。
