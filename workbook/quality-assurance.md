# Quality Assurance

Use this file for validation strategy. Output requirements belong in
`code-experiment-standards.md`.

## Validation Ladder

1. Static inspection: paths, parameters, dimensions, output names.
2. Smoke test: minimal frames or existing `quick_*_test.m`.
3. Baseline comparison: compare against a known script/result.
4. Full run: only after the above pass, and only with user approval if long.

## Test Naming

- `test_*.m`: assertions or focused correctness tests.
- `verify_*.m`: consistency or reconciliation checks.
- `quick_*_test.m`: smoke tests before expensive runs.

## Required Checks

- Compare against a baseline when changing behavior.
- Check edge cases when relevant: empty inputs, zero errors, NaN/Inf, extreme
  SNR, and dimension mismatches.
- For BER curves, inspect error counts as well as BER values.
- Treat all-zero Monte Carlo errors as insufficient evidence for BER-gap
  mechanism claims.
- Treat sparse SNR, single-seed, low-frame BER curves as direction checks only.
  Do not infer stable monotonicity, curve crossing, or global `p` ordering from
  one surprising point; first review errors/frames, then rerun local dense SNR
  with repetitions or multiple seeds.

## Change Log

- **2026-05-21**: Added QA rule for sparse single-seed BER curve anomalies.
- **2026-05-20**: Simplified QA rules and added zero-error BER check.
- **2026-02-25**: v2.0 modular workbook created.


## Explicit partition-index validation

When a construction selects S/I/F by different criteria, every encoder, decoder, estimator, and report must consume the explicit set indices. Equal cardinalities do not make a set equivalent to the first |S| entries of another ranking. For per-SNR I selection, verify S∩I=∅, |I|=K, and I equals the top-K GA positions remaining after removing the actual S indices at each SNR.

- **2026-10-09**: Added after the source-entropy S / channel-GA I estimator mismatch was found during theory-curve review.


## Transmission semantics versus metric masks

For a strategy labeled “energy-only” or “no information,” verify the transmitted payload itself is absent/fixed; excluding a group from BER/Goodput denominators does not make its emitted waveform information-free. Add a behavioral assertion on the payload and keep the information-resource denominator consistent with the strategy definition.

- **2026-10-09**: Added after B4 review found the low group was omitted from metrics but still carried random payload bits.


## 2026-10-10 元数据评分与研究证据边界

报告知识库覆盖或治理评分时，必须说明实际纳入的目录、入口和检查算法；部分范围的100%不得泛化为全仓库完整性。分别记录“引用可解析”“有验证流程”“实验已执行”“验收通过/结论支持”；关键词命中或文件存在只能作为结构检查，不能代表理论护栏落实或科学假设已经证明。


## 2026-10-11 RKS治理实现验收

范围感知RKS扫描器的13项测试通过，覆盖嵌套入口、同名方法精确契约、空范围、读取错误、重复current、失效supersedes、无效H编号、过期证据目标和不完整证据。正式报告`workbook/knowledge/reports/rks-20261011_000500.md`公开纳入/排除文件及缺口。结构得分70.5/100，不是研究通过率。P1只为多载波H2登记一条新证据，状态inconclusive；其他主张仍为not_assessed。

测试针对真实路径、修订和证据目标；错误案例要求失败，固定输入保障确定性。MATLAB诊断包含时域噪声功率、LLR幅度缩放和整链路核对；P1正式CSV通过固定50帧、唯一组合及功率门禁审计。零错误上界保留在图表和数据，不被隐藏。

## 2026-10-11 最终RKS复核

current-revision读取逻辑加入15项确定性测试，扫描器现只使用索引当前版本的L2/L3追加段；未修订的初始文件在索引中记作baseline current。最终报告`workbook/knowledge/reports/rks-20261011_002500.md`为70.1/100结构分，方法35/35、流程6/31、假设12/18、完整性88/88、护栏9/17。相较较早报告分值变化来自历史追加内容不再自动参与coverage，不代表科学结果退步或提升。

本轮知识库治理工具实现交付，但全局flow/claim coverage仍是明确待办；P1相关文档和evidence记录已建立。


## 2026-10-24 辅助位机制对照与未测量数据

随机S对照保留原S/I/F与接收端活动集I∪S，辅助位不计入有效K；独立供体必须与当前消息分离。均匀性先核对实际自由输入对生成矩阵的覆盖，再检验实际联合PMF。供体S不得预设为均匀或原p目标。未执行译码的校准/PMF记录须以NaN及communication_measured=false表示误码/Goodput，不能写0错误冒充测量。

Revision metadata: revision_id=p2_d0a46f9f3a5a_20261024; current_status=current; supersedes=[baseline_p2_d0a46f9f3a5a].
