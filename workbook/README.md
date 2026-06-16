# Workbook Index

This folder is the operating rulebook for research agents in this project.
Keep files short and single-purpose.

## Read Order

Always read:

1. `mandatory-rules.md`
2. One or more task files below

## File Responsibilities

| File | Responsibility |
| --- | --- |
| `mandatory-rules.md` | Non-negotiable workflow rules: weekly report, bug record, MATLAB run permission, BER anomaly guardrails |
| `matlab-specific.md` | MATLAB naming, path, script/function style |
| `code-experiment-standards.md` | Experiment design, parameters, outputs, reproducibility |
| `quality-assurance.md` | Smoke tests, small-scale validation, baseline comparison |
| `communication-documentation.md` | Weekly report format, documentation, task handoff |
| `data-management.md` | Data/results storage, large files, sensitive files |
| `rule-reflection-hook.md` | End-of-task check for whether new durable rules should be added |
| `troubleshooting-history.md` | Historical bug and fix log |

## Scenario Guide

| Scenario | Read |
| --- | --- |
| MATLAB code or script change | `mandatory-rules.md`, `matlab-specific.md`, `code-experiment-standards.md` |
| New or changed experiment | `mandatory-rules.md`, `code-experiment-standards.md`, `quality-assurance.md` |
| BER theory-vs-simulation analysis | `mandatory-rules.md`, `code-experiment-standards.md`, `quality-assurance.md` |
| Bug fix | `mandatory-rules.md`, `troubleshooting-history.md` |
| Documentation/reporting | `mandatory-rules.md`, `communication-documentation.md` |
| Data/result handling | `mandatory-rules.md`, `data-management.md` |
| Task closeout | `mandatory-rules.md`, `rule-reflection-hook.md` |

## Maintenance Rules

- Add durable rules to the most specific workbook file.
- Add dated change notes when rules change.
- Do not duplicate large rule blocks across files; link to the responsible file.
- Every code/script/doc change still requires a weekly report update.
- Every non-trivial task closeout must run `rule-reflection-hook.md`.

## Change Log

- **2026-05-20**: Added rule reflection hook to workbook index.
- **2026-05-20**: Simplified workbook index and clarified file responsibilities.
- **2026-02-25**: v2.0 modular workbook created.
