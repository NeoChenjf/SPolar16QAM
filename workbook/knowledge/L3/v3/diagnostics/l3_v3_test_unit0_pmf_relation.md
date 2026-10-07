# L3 — `test_unit0_pmf_relation`

- **检查**：对 8/16/32/64QAM 的非均匀 latent `p`，验证符号 PMF 归一、非均匀性、`z→b→constellation row` 可逆；对 8-PAM 轴枚举 GL(3,2) 并验证 auto relation 的可逆性与有限优化结果。
- **边界**：通过证明本测试覆盖的归一性、identity标签查表、选中T可逆性与有限优化值；不证明搜索全局最优、非单位relation完整链路或实际编码经验PMF匹配。选择矩阵仍须登记并冻结。
- **健康度**：smoke-pass（2026-08-27，用户MATLAB输出；8-PAM mean KL=2.521e-3）。
