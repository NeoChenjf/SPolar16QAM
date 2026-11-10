# L3 · p2_audit_common_pairing

- **method_id**: l3_p2_audit_common_pairing
- **file_path**: 16QAM_Polar/v2/analysis/p2_audit_common_pairing.m
- **module**: analysis
- **health**: degraded（短样本及合成错误路径已测；非独立随机性证明）

## Signature

`report=p2_audit_common_pairing(run_dir)`：读取params、cases及每channel/SNR/case的raw，返回配对证据表；发现缺失、channel哈希错误、scale/N0或帧输入哈希不一致立即报错。

## Purpose / Math

逐case按同信道同SNR对照第一case的信道数值、噪声功率及每帧payload/auxiliary/donor/noise哈希，并重新计算信道SHA256。输入数组实际噪声和payload未保存，故只能比较生成时保存的哈希，不能独立重新计算或证明PRNG统计独立。

## Numerical Notes

当前按本机double字节生成h哈希，跨平台字节序可能不同；只接受scale=1、N0>0，旧无哈希raw不可通过。检查所有预登记case/信道/SNR覆盖，但不代替数据完整性哈希或科学门槛。

## Dependencies

无项目方法依赖。

## Verification status

MATLAB合成测试通过匹配、噪声哈希不符、raw缺失和h/hash不一致；N32两帧三S原始smoke审计3行通过。未经正式大规模验证。


## 2026-11-06 校准无噪角色拒绝

新增角色检查，仅pilot/model_calibration/test_seen/test_unseen可审计；power_calibration、power_validation和pmf在原型中实际关闭信道加噪，即使raw记录名义N0也不可当作实际噪声证据。对应错误路径测试通过。


## 2026-11-06 纯能量组配对例外

仅bad_channel_energy_only_shaped允许第3组payload与其他case不同；须验证raw role和N×4零payload哈希，其余组payload、全部auxiliary/donor、共同h和noise仍匹配。两个信道、六候选短运行共12条审计通过。


## 2026-11-06 独立策略角色

新增strategy_training/strategy_test角色支持；训练与测试独立seed及raw配对审计保持，模型calibration/test_seen旧入口兼容。N1024、27组合及纯能量基线的两信道单帧训练/测试仅完成探索通路，未验证统计收益或DC。
