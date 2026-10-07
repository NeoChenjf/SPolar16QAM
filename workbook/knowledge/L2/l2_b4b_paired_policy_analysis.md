# L2 · run_b4b_paired_policy_analysis

- **flow_id**：`l2_b4b_paired_policy_analysis`
- **entry**：`run('experiments/multicarrier/run_b4b_paired_policy_analysis.m')`
- **输入**：B4b正式重复表`b4b_repetition_results.csv`；默认参考策略`uniform_p05`。
- **处理**：按SNR和Rayleigh realization配对，计算候选减参考的BER/Goodput/接收能量差值与95%区间、符号检验；生成逐SNR三目标非支配点；在BER区间上界和Goodput区间下界约束后最大化接收能量，若无可行项则回退到最大Goodput。
- **默认约束**：`BER upper95 <= 0.1`、`Goodput lower95 >= 0.25`。
- **输出**：配对CSV、策略汇总CSV、码本选择CSV、Pareto CSV、MAT、README、run log、四图三格式和审计文件。
- **Pareto图图例**：六种颜色表示六种策略；黑色空心圈覆盖三目标非支配点，显式标注为`Nondominated (black ring)`，避免MATLAB自动生成无语义的`data1`。
- **验收**：90条配对统计、36条策略汇总、6条码本选择；配对键、均值恒等式、可行性与选择规则、图文件均通过独立审计。
- **健康度**：PASS（2026-09-17，`20260917_215938_b4b_paired_policy_analysis`）。
- **边界**：策略选择由同一正式数据设计并回看，属于描述性离线码本，不是独立测试集泛化证明；能量指标不是RF–DC效率。
