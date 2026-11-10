# L3 · p2_validate_common_references

- method_id: l3_p2_validate_common_references
- file_path: 16QAM_Polar/v2/analysis/p2_validate_common_references.m
- module: analysis
- health: exploratory

## Scope

`p2_validate_common_references(run_dir)` 从保存的信道、噪声、各组载波布局、缩放和PMF文件重新计算GA输入参考，检查保存的FFT信道及GA均值；检验内部一致性，不证明PMF来源、噪声参考口径、物理模型或数值精度。依赖 l3_p2_llr_reference。

## Verification

MATLAB 对探索校准和seen两批各27行通过；复制一条raw后修改其GA参考时，负向测试返回预期错误。原始结果未修改。
