# 冻结候选 · p1_predict_minsum
- method_id: l3_p1_predict_minsum
- flow_id: l2_p1_predict_minsum
- file_path / entry_script: 16QAM_Polar/v2/analysis/p1_predict_minsum.m
- module: analysis
- runtime: minutes
- needs_user_run: false
- health: degraded，开发候选，未独立验证
## Signature
prediction=p1_predict_minsum(pmf,sigma,map,state,B,seed)。PMF16元素、正sigma、N个位置映射、实际I/S/F/K；B默认2048，seed默认112100004。保存并恢复调用方随机状态。
## Purpose / Math / Pipeline
Gauss-Hermite20阶离散积分→依实际联合符号PMF及真实likelihood得到符号对齐叶边缘→独立抽取数值粒子→min-sum f和g递推→SC部分和与自由位误差状态→实际I加权BER和genie BER。误差域不是实际零字发送；连续非零判决的符号变换等变性已有40例测试，零平局受truth影响是限制。输入无目标真值/首错/损失。
## Inputs / Outputs
输出分路BER、K加权BER、genie、粒子帧标准误和运行秒数。数值粒子不是通信样本。不生成通信波形。
## Numerical Notes / Acceptance
独立边缘替代联合分布、组内池化PMF替代位置PMF；固定3诊断H、p=.5/.3、N1024、min-sum。允许参数输入不表示扩展域已验证。求积CDF归一后非递减断言。有限粒子/求积对传播有放大；零错误不能当精确0。无自造成功线，P4尚无。
## Dependencies
内联local_density_particles/local_sc；MATLAB qammod/de2bi。无目标SC轨迹依赖。
## Evidence / Weekly Report
results/20261110_182159_p1_reliability；周报/阶段B/B4：full-chain策略验证.md。


## 2026-11-10 最终数值分辨率与状态
最终候选order默认80、B默认8192、seed默认112100004；候选另接受可选order用于显式数值检查。原20阶/2048文本是开发版本。最新80阶全表证据见报告末尾，P4仍未独立验证/未压缩。PMF训练误差不包含在真实帧区间内。非零误差域代数对非均匀实际码字仍成立，独立边缘替代联合分布为近似，零平局限制保留。
