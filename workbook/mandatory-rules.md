# Mandatory Rules

These rules override other workbook files.

## 1. Weekly Report Is Required

Every code, script, or documentation change must update the relevant
`周报/*.md` before closing the task.

Record:
- what changed;
- impact scope;
- validation method;
- affected paths;
- result directory, if an experiment was run.

## 2. Bug Fixes Need Two Records

Every bug fix must be recorded in:

1. the relevant weekly report;
2. `workbook/troubleshooting-history.md`.

Troubleshooting entry format:

```markdown
### [编号]. [问题标题]
- **问题**：
- **触发场景**：
- **解决办法**：
- **相关文件**：
- **日期**：YYYY-MM-DD
```

## 3. MATLAB Run Permission

Long-running or high-compute MATLAB simulations must be run locally by the user
unless explicitly authorized.

If such a run is performed, record the command, context/path, time, and output
directory in the weekly report.

## 4. Stop On Rule Failure

If a mandatory rule cannot be satisfied:

1. stop the current action;
2. record the reason in the weekly report;
3. propose an alternative;
4. wait for confirmation.

## 5. Run Rule Reflection Before Closeout

Before closing any non-trivial task, run `workbook/rule-reflection-hook.md`.

The weekly report must record either:

- `Rule reflection: no new durable rule`
- `Rule reflection: added/updated [workbook/file.md] because ...`

## 6. Explain Clearly

When explaining theory, code, formulas, or results:

- start with plain-language intuition;
- then give technical details;
- include a simple analogy when useful;
- end with a check that the explanation is actionable.

## 7. Check System Limits First

Before judging polar-code or block-transmission results, check the rate ceiling
from `N`, `K`, shaping bits, and frozen bits. Do not mistake a designed rate
limit for an algorithm failure.

## 8. BER Anomalies Need A Waterfall Window

Before explaining a theory-vs-simulation BER gap:

- first locate an informative SNR window where simulated BER is roughly
  `1e-4 ~ 1e-1`;
- if Monte Carlo errors are all zero, move to lower SNR instead of explaining
  the point as an anomaly;
- do not infer mechanisms from a single high-SNR point;
- for same口径 validation, do not change theory formula, simulation chain, and
  SNR definition at the same time.

## Change Log

- **2026-05-20**: Added mandatory task-end rule reflection hook.
- **2026-05-20**: Simplified mandatory rules and retained BER waterfall rule.
- **2026-05-20**: Added BER waterfall rule.
- **2026-03-04**: Added explanation style and rate-ceiling rules.
- **2026-02-25**: v2.0 modular workbook created.
