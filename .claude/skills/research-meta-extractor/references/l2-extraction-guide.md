# L2 实验流程提取指南

## 扫描锚点

| 字段 | 扫描锚点 | 提取目标 |
|------|----------|----------|
| entry_script | `run_*.m` 或 experiments 下的 `run_*` | 入口路径 |
| purpose | 脚本头部 `%% RUN_XXX - 功能：...` | 实验目的 |
| runtime/needs_user_run | 头部"预计运行时间""几小时""先用 run_single 验证" | 长跑→ `needs_user_run: true` |
| pipeline | 脚本中调用的函数序列（编码→串并→qammod→AWGN→qamdemod→译码→指标） | 每步挂 l3_ref |
| inputs | 脚本里的参数覆盖（`cfg.num_frames=...`, `p_test=`, `snr_grid=`） + `config()` 字段 | 关键参数 |
| outputs | `results/<timestamp>_*` 写入、`.mat`/`.csv`/`figures/` | 产物结构 |
| acceptance | 头部"设计思想""口径""校准非理论"等约束 + 关联 L1 pitfalls | 验收标准 |

## 本项目真实示例锚点
- `run_single.m`：`cfg.num_frames=100` → runtime=minutes, needs_user_run=false。
- `run_sweep.m`：注释"SC 译码 ~几小时" → runtime=long, needs_user_run=true。
- `run_sc_theory_vs_sim.m`：注释"比值对齐""校准非理论" → acceptance 写明校准标注。
- `experiments/sc_checks/run_find_waterfall_and_refine.m`：瀑布区定位 → acceptance 强制 §8 护栏。
- `experiments/multicarrier/run_ofdm_baseline.m`：Stage B → acceptance 写三基线对照硬规则。

## 约束
1. pipeline 每个调用了 .m 的步骤必须挂 `l3_ref`；纯内联（如 AWGN 加噪、qammod）注明"内联"。
2. `validates` 写成 `l1_domain#Hn`，与 L1 假设编号对应（checker 据此算假设覆盖率）。
3. 长跑流程 `needs_user_run: true`，提醒不得擅自执行（项目硬规则 §3）。
