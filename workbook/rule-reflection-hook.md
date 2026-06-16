# Rule Reflection Hook

Use this file at the end of every non-trivial task. Its purpose is to decide
whether the task produced a durable rule that should be added to `workbook/`.

## When To Run

Run this hook before final response whenever the task involved:

- code, script, or documentation edits;
- debugging or anomaly analysis;
- a failed attempt, workaround, or recovered mistake;
- a new experiment pattern or result interpretation pattern;
- repeated user clarification about how agents should behave.

## Reflection Questions

Ask these questions:

1. Did this task reveal a mistake that could recur?
2. Did we discover a better default workflow?
3. Did we add a validation pattern worth reusing?
4. Did we clarify a project-specific interpretation rule?
5. Did we learn a permission, reporting, or data-handling constraint?

If all answers are no, write only in the weekly report: `Rule reflection: no new durable rule`.

## Add A Rule Only If

The candidate rule is:

- reusable across future tasks;
- project-specific enough to matter here;
- short and actionable;
- not already covered by an existing workbook rule.

Do not add one-off observations, temporary parameter choices, or results that
belong only in a weekly report.

## Where To Add

| Rule type | Target file |
| --- | --- |
| Mandatory workflow or permission | `mandatory-rules.md` |
| MATLAB style/path/script shape | `matlab-specific.md` |
| Experiment design/output/reproducibility | `code-experiment-standards.md` |
| Validation/test strategy | `quality-assurance.md` |
| Reporting/handoff/explanation | `communication-documentation.md` |
| Data/storage/sensitive files | `data-management.md` |
| Specific bug and fix | `troubleshooting-history.md` |

If no target fits, update `README.md` only to add an index entry or ask the user
before creating a new workbook file.

## Required Record

Every task-end weekly report entry must include one of:

- `Rule reflection: no new durable rule`
- `Rule reflection: added/updated [workbook/file.md] because ...`

If a rule is added, also add a dated change note in that workbook file.

## Change Log

- **2026-05-20**: Added task-end rule reflection hook.
