# L3 — frozen_gray_pam8_relation

- **签名**：`[T,metadata] = frozen_gray_pam8_relation()`。
- **定义**：返回double矩阵 `[0 0 1;1 0 0;1 1 0]`，列向量约定 `b=Tz mod 2`。
- **来源**：2026-08-28用户MATLAB枚举搜索输出；版本 `pam8-gf2-v1-20260828`；轴自身均匀能量归一化，设计lambda为 `[-.5,-.25,0,.25,.5]`。
- **精度边界**：mean KL=2.521e-3来自前次打印，max KL=0.0067为四位小数输出。未获得完整精度指标及cell中的p；不得伪造。矩阵是搜索选定候选，不声称已证明全局最优或为论文polar relation。
- **健康度**：矩阵已登记；2026-08-28用户MATLAB扩展环回通过，覆盖32/64QAM、seed=17/29及p/1-p。
