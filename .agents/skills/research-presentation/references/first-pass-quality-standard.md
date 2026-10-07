# Research presentation first-pass quality standard

This standard captures reusable lessons from iterative optimization of a five-minute graduate research progress presentation. It intentionally avoids project-specific page numbers and parameter values.

## 1. A slide is a reasoning unit

A slide should have one answerable question or one defensible conclusion. Multiple graphics may share a slide only when their relationship is stated explicitly. Typical valid pairs are:

- overall trend + focused validation;
- model prediction + empirical realization;
- training result + independent holdout;
- average performance + paired difference;
- result + acceptance margin.

Two graphics are not related merely because they use the same modulation order, dataset, or color palette.

## 2. The audience should not reconstruct the method

When the upper part of a page represents a link, pipeline, or experimental procedure, draw it as that procedure. Use explicit source, processing blocks, medium/channel, receiver or analysis blocks, and directional arrows. Put evaluation criteria below or beside it as gates. A row of technical nouns is not yet a system diagram.

Parallel research tasks should use the same semantic architecture when their roles are comparable. This makes differences meaningful instead of accidental.

## 3. Charts need interpretation, not just captions

On-slide interpretation should normally include:

- full name and intuitive meaning of unfamiliar metrics;
- axis reading;
- sample size or statistical unit when important;
- the quantitative result, including uncertainty or threshold;
- the decision consequence;
- the limit of that consequence.

Use direct statements such as “95% upper bound 3.31% < 5% gate; therefore the distribution-level implementation error passes this gate.” Then add the boundary: “This does not imply every constellation point has less than 5% relative error.”

For multi-series charts, color must be a secondary cue rather than the only identifier. Assign each parameter or strategy a stable line-style and marker pair, reuse that mapping across slides, and show the pair in the legend. The figure should remain distinguishable in grayscale, under projector color shift, and for viewers with color-vision differences. Single-series plots and labeled bar charts do not need artificial style variation.

## 4. Redundancy is about argumentative function

Figures can look different yet be redundant if they support the same conclusion. Before keeping a slide, ask:

1. Does it add a new claim?
2. Does it provide stronger or independent evidence?
3. Does it establish a boundary or mechanism needed later?
4. Would removing it make the later conclusion unsupported?

If all answers are no, merge its one unique sentence into the stronger slide and remove it.

## 5. Strategy selection must show why the answer changes

A single constraint example can make a selection rule look arbitrary. When the scientific point is adaptivity, show a small set of representative regimes:

- reliability-tight;
- throughput-tight;
- energy-priority;
- balanced/default;
- infeasible fallback, if it exists.

For each regime show the constraints, feasible set or rejection reason, chosen strategy, and decision rationale. Clearly separate offline sensitivity examples from independently validated operating rules.

## 6. Failed boundaries strengthen a credible story

If an independent test exposes a borderline failure, present the chronology:

1. training-derived rule;
2. untouched holdout result;
3. exact failed bound or gate;
4. preregistered correction such as a guard band;
5. new sample or third-batch validation;
6. final rule and remaining scope.

Do not retroactively describe the corrected rule as if it had been the original rule.

## 7. Conclusions and next steps should be auditable

Use a three-column conclusion grammar:

`formal evidence → supported conclusion → applicability boundary`

Use a three-column roadmap grammar:

`current gap → next work → expected acceptance evidence`

This prevents generic “future work” lists and makes the next research stage testable.

## 8. Script quality is part of slide quality

A script that sounds good but does not follow the slide is a design defect. The script should name what the audience is looking at, move in the same order as the layout, explain terms at first encounter, and reach the visible takeaway before advancing.

Speaker Notes and the external Markdown script should be generated from one source so they cannot drift independently.

## 9. A technical script must also be listenable

The first spoken sentence on a result page should tell the audience what question the page answers, not repeat the title mechanically. Introduce unfamiliar terms with a plain-language meaning before using them in a conclusion. Follow the visible reading order, select only decisive numbers, and separate observation, interpretation, and claim boundary.

When a prior script from the same presenter is available, use it to calibrate formality, sentence rhythm, explanation depth, and speaking rate. Reuse the style, not the prior research content.

## 10. Acceptance checklist

A first-pass deck is ready for user review only when:

- [ ] one unique job is written for every slide;
- [ ] no two adjacent slides prove the same conclusion;
- [ ] every method diagram reflects the real processing order;
- [ ] every multi-figure page states the relationship among figures;
- [ ] every unfamiliar metric has its full name and physical meaning;
- [ ] axes, uncertainty, thresholds, and sample units are readable;
- [ ] multi-series curves use stable color + line-style + marker encoding and remain distinguishable without color;
- [ ] every central number is traceable to an authoritative result;
- [ ] training, validation, and post-failure correction are distinct;
- [ ] conclusions include applicability boundaries;
- [ ] limitations map to actions and acceptance evidence;
- [ ] Speaker Notes and Markdown narration agree;
- [ ] slide count and switch-cue count agree;
- [ ] spoken duration fits the requested time;
- [ ] specialist terms are explained before they carry the argument;
- [ ] narration follows the visible reading order and does not merely read legends or bullets;
- [ ] each result-page script states the question, decisive evidence, meaning, and boundary;
- [ ] native charts/tables and source workbooks survive editing;
- [ ] package integrity and overflow checks pass;
- [ ] a visual issue was fixed and the affected slide rerendered.
