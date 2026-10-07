# Communication And Documentation

Use this file for reports, task handoff, and explanatory documents.

## Before Non-Trivial Changes

State briefly:

- why the change is needed;
- what will change;
- how it will be verified;
- known limits or risks.

## Weekly Report Entry

Every changed task should record:

- modification content;
- impact scope;
- validation method;
- affected paths;
- result directory if applicable;
- unresolved follow-up if any.
- rule reflection result.

## Asking For Help

When blocked, provide:

- expected result vs current result;
- attempted fixes;
- exact error or suspicious output;
- relevant files and result directories.

## Explanation Style

- Start with plain-language intuition.
- Then give technical detail.
- Use a simple analogy when it clarifies the idea.
- End with the concrete next action or decision.

## Research Presentation Handoff

For proposal, midterm, thesis-defense, or experiment-report presentations, use the project `research-presentation` Skill together with the available PPTX/Presentations Skill. Before visual polishing, require one unique argumentative role per slide, trace every central number to authoritative evidence, state the relationship between multiple figures, and separate supported conclusions from applicability boundaries. Generate Speaker Notes and any Markdown script from the same narration source, then verify slide/page counts, switch cues, note alignment, native chart preservation, package integrity, overflow, and at least one visual fix-and-rerender cycle.

Route Skills by responsibility: select one primary Skill from the requested outcome, add a file-format Skill only when that file is actually read or written, and add a research-domain Skill only when new domain judgment is required. In particular, `research-presentation` owns scientific narrative and cross-artifact alignment, while `pptx/presentations` owns PowerPoint mechanics; existing-result layout work does not by itself require `academic-research-suite`.

Whenever a report or slide states a relative error or relative deviation, name both compared quantities and the reference denominator. Keep `target`, `model`, and `empirical` distinct; a percentage computed relative to the model must not be presented as if it were relative to the empirical value or the theoretical target.

For multi-series scientific charts, do not use color as the only series identifier. Give each parameter or strategy a stable combination of color, line style, and marker, reuse the mapping across related pages, and make the legend display those encodings. Check that the curves remain distinguishable in grayscale or under projector color shift. Do not add artificial line-style variation to single-series plots or directly labeled bar charts.

When removing or replacing a research figure, audit the surrounding paragraphs, headings, captions, and later references against the figures that remain. Rewrite claims that depended on the removed visual or an old experimental comparison; checking image counts alone is insufficient.

## Change Log

- **2026-09-24**: Required text and figure alignment after deleting comparison plots left a midterm form describing a length comparison that was no longer shown.
- **2026-09-22**: Required redundant color/line/marker encoding for multi-series research charts after two different OFDM strategies appeared blue and could not be reliably distinguished by color alone.
- **2026-09-22**: Required relative-error statements to name the compared quantities and denominator after a correct 4.9% model-relative deviation was visually mistaken for a target-relative error above 5%.
- **2026-09-22**: Clarified primary-versus-companion Skill routing after introducing `research-presentation`, including the boundary between scientific narrative, PowerPoint mechanics, and new academic judgment.
- **2026-09-22**: Added the evidence-led research-presentation handoff and cross-artifact validation rule after the midterm deck required repeated structural, statistical-interpretation, and narration-alignment corrections.
- **2026-05-20**: Added rule reflection result to weekly report entries.
- **2026-05-20**: Simplified communication and reporting rules.
- **2026-02-25**: v2.0 modular workbook created.
