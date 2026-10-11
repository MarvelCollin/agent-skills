# Write Mode

Draft a new section or restructure an existing one so a reader in the field can follow the argument on one pass and every claim points at its evidence. The author's findings and meaning stay intact. You change shape, order, clarity and support, not the science.

## Rules

1. **Facts first.** Draft only from the document, the author's notes and verified sources. A number, result or citation you do not have becomes a placeholder: `[NUMBER: accuracy on the held out set]`, `[CITE: source for the adoption rate]`, `[RESULT: ablation without the filter]`
2. **One message per paragraph**, stated in its first sentence
3. **Claims match evidence.** If the evidence is narrower than the wording, narrow the wording and tell the author
4. **The field's conventions win.** Read the matching row of [fields.md](fields.md) and the venue's author guide when the user names a venue
5. **Keep markup.** Keep the document's citation commands, labels, macros and heading style. Write LaTeX for LaTeX and Markdown for Markdown
6. **No filler.** No "novel", "very", "clearly" or "significantly" (unless a test backs it), no restating the heading, no closing summary of the paragraph

## Steps

1. **Gather.** Read the whole document, not only the target section. List the contributions, the main results with their numbers and locations, the figures and tables, and the terms the document already uses
2. **Answer four questions** in one or two sentences each, from the document:
   - What problem is this, and why is it still open?
   - What exactly is the contribution?
   - Why should it work, in one sentence of mechanism or reasoning?
   - What does it achieve or reveal that earlier work did not, with the number that shows it?

   If an answer is missing from the document, ask the author once, listing all missing answers together, or mark it with a placeholder
3. **Pick the shape** for the section from the guides below and the field row
4. **Outline** in three to seven points, each naming the paragraph's role (context, gap, approach, mechanism, evidence, comparison, limitation, implication)
5. **Write** paragraph by paragraph following the outline and the paragraph rules
6. **Check** with the self check at the end, then fix what fails

To **restructure** existing text: reverse outline it first (one line per paragraph with its topic and role), find missing roles, repeated roles and paragraphs with two messages, then reorder, merge, split and cut. Report what moved, merged, was cut and was added.

## Section Guides

### Title

Names the problem and the approach or the main finding in plain, specific words. Usually under 15 words. No "novel" or "towards" unless the venue expects it.

### Abstract

One sentence or two per move, in this order, with the result always last:

| Shape | Moves | Use when |
|-------|-------|----------|
| Gap to contribution | Problem, what earlier work cannot do and why, what we contribute, its benefit, the main result | One clear contribution |
| Gap to insight to contribution | Problem, the gap and its cause, the key idea that removes the cause, how we build it, the main result | The idea is the selling point |
| Several contributions | Problem, then each contribution paired with its benefit, then the main result | Two or three separate contributions |
| Structured | Background, objective, methods, results with numbers, conclusion | Medicine, health and many sciences, or when the venue asks |

Rules: name each contribution by a term a reader can follow without the paper, give the headline numbers exactly as they appear in the results, no citations, no undefined acronyms, within the venue's word limit (often 150 to 250 words).

### Introduction

Plan backward, write forward. Start from the contribution and ask what the reader must believe first for it to matter. Then write in reading order:

1. **Context.** What the task or question is and why it matters, in two or three sentences. For a familiar topic go straight to the stakes. For a new setting, start from the broad area and narrow to the exact setting with its inputs, outputs or scope
2. **Gap.** What existing work does, where it falls short, and the cause of the shortfall. Every limitation named needs its cause. Walk from older to newer approaches when that history explains the gap, and make the last limitation exactly the one this work removes. For a problem with no prior methods, state the goal and break the difficulty into numbered points, each with its cause
3. **Approach.** What this work does and why it addresses the cause, at the level of mechanism, with a pointer to the overview figure if there is one
4. **Evidence.** The main results in a sentence or two, with numbers
5. **Contributions.** A short list. Each item is verifiable and points to the section that shows it

Avoid: building a weak version of your own method first and then presenting the real method as a patch (it makes the work look incremental and the idea look obvious), describing the insight in abstract terms without saying how it is implemented, stating a gap without its cause, and claiming "first" without a search that supports it.

### Related Work or Literature Review

- Two to four groups by theme or approach, not by year or one paper per paragraph
- Each paragraph: the group's scope, what its methods have in common, the limitation that matters for this work, and how this work differs in mechanism or assumption
- Include the strongest and newest competing work, especially work that does better on some measure
- For a thesis literature review, end with a synthesis that names the open question the research questions answer

### Method or Methods

- **Overview first:** the setting (inputs and outputs, or population and design), the core idea in one or two sentences, a pointer to the overview figure, and a map of the subsections
- **Per component:** why it is needed (the problem it solves), what it is (the structures, then the steps in order from input to output), and why this design beats the obvious alternative, tied to a result where possible. Draft the design part first, then add the motivation and advantage
- **Empirical studies:** participants or data (source, dates, inclusion, size), materials and instruments, procedure, design and variables, analysis plan, ethics approval
- **Last:** implementation details, settings and software versions, or a pointer to the appendix

### Results or Experiments

1. Setup: data, metrics with their direction (higher or lower is better), baselines or comparison groups, protocol
2. Main comparison
3. Analyses that isolate each claimed contribution or factor (ablations, manipulation checks, subgroup or robustness checks)
4. Harder or different settings, and failure cases

Each paragraph opens with the finding, then gives the number and points to the table or figure. Report spread, not only means. In IMRaD papers, save interpretation for the Discussion.

**Tables and figures.** A caption says what is shown and under which setting, so it reads without the text. Mark metric direction, give units, keep decimals consistent within a column, highlight the best result sparingly, and give each table one message. In LaTeX, prefer booktabs rules over grids when the venue allows. Follow the venue's caption placement.

### Discussion

Answer the research question directly, compare with prior findings and explain differences, interpret unexpected results, state limitations, and give implications that the evidence supports.

### Limitations

Separate scope limits (settings, populations or conditions the work does not cover) from defects (places where the method or study falls short). State both honestly, with what would address them. Do not hide a defect as a scope limit.

### Conclusion

The problem and the approach in a sentence, the strongest evidence, what it means, the main limit, and one concrete next step. No new results.

### Proposal Sections

Aims stated as testable or deliverable outcomes, significance tied to a named gap, approach per aim with methods and success criteria, a timeline, risks with fallbacks, and a budget that matches the work.

## Paragraph and Sentence Rules

- The first sentence states what the paragraph will establish
- Each sentence links to the one before it by cause, contrast, consequence, example or refinement. If the link is unclear, reorder or add the connecting word
- Old information first, new information last in a sentence, so each sentence picks up where the last ended
- One name per concept across the whole document, defined at first use
- Put the subject and verb early. Keep key claims in short sentences
- Hedge to the evidence: "shows" only for direct evidence, "suggests" or "is associated with" for indirect evidence
- Numbers: the same precision as the results, units always, percent versus percentage points kept apart
- When flow is weak, add temporary subheadings, reverse outline the section, fix the order, then remove the temporary headings

## Output Contract

1. **Outline:** three to seven points with paragraph roles
2. **Text:** the drafted or restructured section, each paragraph labeled with its role in a comment or a bracket line the author can delete
3. **Claim to evidence map:** one line per claim, `Claim | Evidence (location) | Status: supported or needs evidence`
4. **Self check:** one line each for clarity, flow, term consistency, unsupported claims, missing evidence, placeholders left, and length against the venue limit
5. **For a restructure:** what moved, merged, was cut and was added

Edit the file in place only when the user asks. Otherwise show the text in the reply or write it to a file the user names.
