# Audit Mode

Audit the logic, data and consistency of the user's paper, thesis, report or proposal. Find what is missing, what is wrong, what does not follow and what contradicts itself. This mode reads and judges. It does not rewrite the document unless the user asks.

Run the passes in this order. Each pass feeds the next, so do not skip ahead.

| Pass | Question | Main output |
|------|----------|-------------|
| 0. Map | What does the document claim, and where is the evidence? | Map notes and script output |
| 1. Claims | Is every central claim backed by evidence in the document? | Claim ledger |
| 2. Numbers | Do the numbers agree everywhere and add up? | Data findings |
| 3. Missing pieces | What would a careful reader expect that is not there? | Missing findings |
| 4. Logic | Do the conclusions follow from the evidence? | Logic findings |
| 5. Consistency | Do terms, notation and claims agree across sections? | Consistency findings |
| 6. Structure | Does every section and paragraph serve the main argument? | Reverse outline and structure findings |

## Pass 0. Map the Document

1. Read the whole document, including tables, captions, footnotes and appendices
2. Write down: the document type, the field, the research question or aim, the main claim in one sentence, the list of contributions or findings as stated, the design (experiment, survey, case study, model, proof, archival study), and where each kind of evidence lives
3. Run both scripts on the document folder and save the output next to the report:

```
bash "<skill-dir>/scripts/numbers-extract.sh" "<path>"
bash "<skill-dir>/scripts/cite-check.sh" "<folder>"
```

On Windows without bash, run the `.ps1` versions with `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/<name>.ps1" -Path "<path>"`.

From cite-check, carry only MISSING_KEY into this audit as a consistency finding. Point the user to References Mode for a full citation check.

## Pass 1. Claim Ledger

List every claim in the abstract, the contribution list, the conclusion and any executive summary. For each, find the evidence in the document and give a status.

| Status | Meaning |
|--------|---------|
| Supported | A result in the document backs it at the stated strength |
| Partly supported | The evidence exists but is narrower (fewer settings, a subgroup, one dataset) or weaker (not significant, small effect) than the wording |
| Unsupported | No result in the document backs it |
| Contradicted | A result in the document says otherwise |

Format each row as `Claim (location, quoted) | Evidence (location) | Status | Note`. Every claim that is not supported becomes a finding in Pass 4.

## Pass 2. Numbers and Data

Use the numbers-extract output as the index, then read each number in context.

- **Same number everywhere.** Compare abstract, text, tables, figures, captions and conclusion. A value that differs between two places is a finding even when the difference is small. ABSTRACT_ONLY lines are the first leads
- **Sample sizes.** Trace the flow from recruited or collected, to excluded, to analyzed. Every drop needs a reason and a count. Every table and test should state its n. SAMPLE_SIZE lines are the first leads
- **Totals.** Percentages of one whole sum to 100 within rounding (PCT_SUM lines). Counts in a breakdown sum to the total. Table rows and columns sum to their stated totals
- **Recompute.** Check relative changes (new minus old, divided by old), percentage points versus percent, averages of listed values, differences quoted in the text, and percentages of n that give whole people (33 percent of 50 is 16.5 people, which is impossible). For means of whole number answers, run the GRIM check in [statistics.md](statistics.md)
- **Units and scale.** Same unit across the document, seconds versus milliseconds, fractions versus percentages, per year versus per month
- **Precision.** The same number of decimals for a metric across tables and text, and no more precision than the measurement allows
- **Impossible values.** Negative standard deviations, p values above 1, correlations outside minus 1 to 1, percentages above 100, means outside the scale's range, more events than participants
- **Statistics.** Follow [statistics.md](statistics.md) for test reporting, effect sizes, multiple comparisons and the quick consistency checks
- **Figures.** When the text describes a figure, open the image if it is available and compare. If you cannot see it, list the check as not done instead of assuming
- **Numbers credited to a source.** When a sentence gives a number and cites someone for it ("Lee et al. report 41 percent"), fetch the source when you can and check the number, the population and the condition it came from. A misquoted or out of context number is a Data finding. When you cannot fetch the source, list the check as not done

## Pass 3. Missing Pieces

Check what the document type and field expect. Use the matching row of [fields.md](fields.md). The common list:

- **Definitions.** Every technical term, acronym and symbol defined at first use, before it carries an argument
- **Comparison.** A baseline, control group, prior method or benchmark that a skeptical reader would ask for, run under the same conditions
- **Isolation.** For a claim that a component or factor causes the effect, an ablation, a manipulation check, or a design that isolates it
- **Variance.** Spread, confidence intervals, repeated runs or seeds, and how many
- **Method detail.** Enough to repeat the work: data source and dates, sampling, instruments, procedure, settings, software versions, analysis plan
- **Limitations.** A section that states the boundaries of the findings honestly, separating scope limits (where the claims stop) from defects (what went wrong)
- **Threats to validity.** Internal (confounds, selection, attrition), external (who and what the findings extend to), construct (does the measure capture the concept), statistical (power, multiple tests)
- **Ethics and data.** Ethics approval and consent when people are studied, conflicts of interest, data and code availability where the venue expects them
- **Answer to every question.** Each research question, hypothesis or aim stated at the start gets an explicit answer later

## Pass 4. Logic

For each claim from Pass 1 that is not fully supported, and for every conclusion sentence, check the reasoning.

| Problem | What it looks like | Typical fix |
|---------|--------------------|-------------|
| Causal claim from correlation | "causes", "leads to", "improves", "the effect of" drawn from observational or cross sectional data | Use "is associated with", add the design that supports cause, or discuss confounders |
| Overgeneralization | From one sample, site, dataset or period to "people", "all", "in general" | Name the population and setting the evidence covers |
| Conclusion stronger than evidence | "proves", "demonstrates" from a small, non significant or single study result | Hedge to the evidence or add evidence |
| Circular reasoning | The conclusion is assumed in a premise, or the evaluation uses what built the method (tuning on the test set, scoring with the same annotations used to train) | Separate the evidence from the assumption, use held out data |
| Selection effects | Self selected participants, survivors only, best cases shown as typical | State the selection, compare to the full group, show typical and failure cases |
| Absence of evidence as evidence of absence | A non significant result read as "no effect" | Report the interval and say the study could not rule out an effect |
| Unfair comparison | Baselines with less tuning, data, compute or an older version | Equalize or state the difference |
| Alternative explanations ignored | A plausible confound or rival mechanism never discussed | Discuss it, test it, or narrow the claim |
| Results contradict the conclusion | A table shows the opposite of the text, or a key comparison is reversed | Fix the text or the table, whichever is wrong |
| Unchecked priority or superlative | "the first", "the only", "state of the art", "no prior work" with no search or comparison behind it | Search the literature (References Mode) before accepting it, cite the closest prior work, or soften to what was checked |

## Pass 5. Consistency

- **Terms.** Build a table of each concept, every name used for it, and where. One concept gets one name. Two concepts never share a name
- **Acronyms.** Defined once at first use, then used. Not redefined, not defined and never used
- **Notation.** One symbol per quantity, defined before use, the same in text, equations, tables and figures
- **Cross references.** Each "Table 3 shows" or "as in Section 4" points to something that exists and shows what the text says
- **Claims between sections.** The introduction's promises, the results and the limitations agree. A design described one way in the method and another way in the discussion is a finding
- **Citations.** Every cited key resolves (MISSING_KEY from cite-check)

## Pass 6. Structure

Write a reverse outline: the main claim in one sentence, then one line per paragraph with its topic. Check that each paragraph's topic serves the main claim, that its sentences support the topic, and that the section order follows the field's convention. Flag paragraphs that do not map, repeat another paragraph, or carry two messages.

## Confirm Each Finding (Five Gates)

A lead becomes a finding only when it passes all five.

1. **Located.** You can quote the exact text and give its location. An inconsistency has both
2. **Real.** You reread the surrounding text, footnotes, captions and appendix, and the explanation is not given elsewhere
3. **Material.** It matters to a reader's trust in a result, a conclusion or the ability to repeat the work, or it is a clear error even if small
4. **Fixable.** You can name a concrete fix
5. **Not invented.** The finding relies only on the document and fetched sources. You did not assume a number, a method detail or a result

## Severity

| Severity | Use when |
|----------|----------|
| Blocker | A central claim is unsupported or contradicted, data errors change a conclusion, or a key citation is fabricated or unresolvable |
| Major | A careful reviewer would raise it: a missing baseline, ablation, control or limitation, an unexplained change in sample size, a causal claim from correlational data, a contradiction between sections |
| Minor | It does not change a conclusion: a rounding mismatch, a term used two ways, a missing definition of a secondary term |

## Finding Format

```
A3. [Major] [Data] Sample size changes without explanation
Location: Method, line 26 and Results, line 31
Quote: "We recruited participants (n = 120)" and "Of the remaining participants (n = 112)"
What is wrong: Eight participants disappear between recruitment and analysis.
Why it matters: Attrition can bias the comparison if dropouts differ between groups.
Fix: Report how many left each group and why, and check that dropouts do not differ on baseline measures.
```

Each finding has an ID, a severity, a type (Missing, Data, Logic, Consistency, Structure), the location, the exact quote, what is wrong, why it matters and a fix.

## Output

Write `research-audit-<slug>-<YYYYMMDD>/report.md` from [../templates/audit-report-template.md](../templates/audit-report-template.md), with the script output saved beside it. In chat, give the counts by severity, the three findings to fix first, and the report path.
