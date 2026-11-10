# L2 · A0 diagnostics
- **flow_id**: l2_run_a0_diagnostics
- **entry_script**: 16QAM_Polar/v2/diagnostics/run_a0_diagnostics.m; run_a0_statistics.m; run_a0_production.m
- **runtime**: minutes
- **needs_user_run**: true
- **purpose**: 固定幅度16QAM与min-sum SC正确性核验；仅本轮明确预算授权可执行。
- **inputs**: 固定诊断种子；T5实际Es/N0=8/12；T6 N1024、64载波、CP16、16tap、参考标签20/28。
- **pipeline**: 确定性编码/映射与递归参照 → LLR枚举 → 无编码统计 → 生产逐帧保存。
- **l3_ref**: l3_run_a0_diagnostics
- **outputs**: 时间戳A0目录，日志、MAT、CSV、PNG。
- **acceptance**: T1—T6分别报告；2026-11-10指定T6因模板索引错误未通过，不得自动补跑；120帧与200000符号已用满。
- **weekly_report_link**: 周报/阶段B/B4：full-chain策略验证.md

## 2026-11-10 修复批验收
用户明确新增120帧授权后，指定T6完成；修复结果20261110_144834_A0_production，复核360组通过。原200000无编码符号不重跑。有限用例实现检查通过，统计总体收敛证据不足；完整判断见A0交付报告末尾。
