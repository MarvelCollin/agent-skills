# Review Mode

Review the document the way a tough but fair reviewer at the target venue would, so the author can fix the weak points before submission or answer them in a rebuttal. Audit Mode asks whether the document is internally correct. Review Mode asks whether it is worth accepting.

## Setup

1. **Venue and bar.** Use the venue the user named. Otherwise ask once, and if there is no answer, assume a good peer reviewed venue in the document's field and say so in the report. For a thesis, the bar is the examiners' standard for the degree. For a proposal, it is the funder's criteria
2. **Stance.** Specific, evidence based, no tone of contempt. Every point cites a location. A predicted objection is labeled as a prediction, not stated as fact
3. **Read twice.** First as a busy reviewer: title, abstract, figures, the contribution list and the conclusion. Write the summary a reviewer would write in three sentences. If you cannot, that is a clarity objection. Then read everything in order

## Probe Five Dimensions

For each dimension, answer the probes with evidence from the document and mark each probe **pass**, **needs revision** (fixable with text or analysis of existing data) or **needs new work** (new experiments, data or study).

### 1. Contribution and Novelty

- What will a reader know after this paper that they did not know before?
- Is the problem real and frequent enough to matter, or is the targeted failure rare?
- Is the idea beyond what the field already does routinely, so the gain was not predictable?
- Which kind of novelty is it: a new problem, method, component, design choice, finding, dataset or explanation?
- What is the closest prior work? Run two or three searches for it. If you find closer work than the paper cites, that is an objection. Name it only with its verified identifier

### 2. Clarity and Reproducibility

- Could an expert repeat the work from the paper and its supplement?
- Does each component or step have a stated reason for existing?
- Are terms, notation and figures consistent and defined?
- Does each paragraph carry one clear message?

### 3. Strength of Evidence

- Are the gains or effects large enough to matter, not just measurable?
- Is the absolute result good enough for the venue, not only better than a weak baseline?
- Do the gains hold across datasets, settings, populations or metrics?
- Are variance, significance and effect sizes reported (see [statistics.md](statistics.md))?
- Are failure cases shown honestly?

### 4. Completeness of Evaluation

- Is every key design choice or factor isolated by an ablation or a control?
- Are the strongest and most recent baselines or comparisons included under the same conditions?
- Are the metrics and measures the standard ones for the task, and enough of them?
- Are the datasets, cases or samples hard and varied enough to support the claim?
- Are the protocols documented well enough to judge fairness?

### 5. Soundness of Design and Assumptions

- Is the setting realistic for the use the paper claims?
- Are there hidden assumptions or technical flaws a reviewer could exploit?
- Does the method need tuning per case to work?
- Do the benefits outweigh the added cost, complexity and new limits?
- Could a reviewer argue that the net value is negative?

For a non empirical document (theory, humanities, policy), replace the evaluation probes with the field's equivalents from [fields.md](fields.md): soundness of argument, use of sources, engagement with counterarguments.

## Score

Score each dimension from 1 to 5 with a one line reason tied to a location.

| Score | Meaning |
|-------|---------|
| 5 | Excellent. No meaningful weakness |
| 4 | Good. Minor issues fixable in the text |
| 3 | Adequate. At least one major issue that is fixable before the deadline |
| 2 | Weak. A major issue that needs new work |
| 1 | Failing. A fundamental flaw in the idea, design or evidence |

Then give an overall recommendation on this scale, mapped to the venue's own scale when known: strong reject, reject, weak reject, borderline, weak accept, accept, strong accept. Add a confidence from 1 (guess) to 5 (certain), and say what lowered it (outside your expertise, figures not visible, supplement not read).

## Rank the Objections

List the objections a reviewer is likely to raise, ranked by how much each would move the decision: first those that would decide rejection on their own, then those that would lower the score, then minor ones. For each objection give:

- **Objection:** in the words a reviewer would write
- **Where:** the location that triggers it, with a short quote
- **Why a reviewer raises it:** the probe it fails
- **Likelihood:** high, medium or low that a reviewer raises it
- **Fix before submission:** the concrete change, with its cost (S for text only, M for new analysis of existing data, L for new experiments, data or study)
- **Rebuttal if not fixed:** the answer the author could give, with the evidence that answer needs

## Rebuttal Plan

Build a table of the objections in rank order: fix now, fix if time allows, or answer in the rebuttal. Then give rules for the rebuttal text:

- Answer the question asked in the first sentence, then give the evidence or number
- Point to the exact revised location (section, line, table)
- Concede valid points and say what changed
- Correct factual misreadings politely, quoting the paper
- Never promise results you do not have
- Keep each answer short and in the order of the reviews

## Strengths

List three real strengths with locations. Reviewers write them, and the author needs to know what to protect while revising.

## Several Reviewers

When the user asks for a full panel, write three short reviews from different angles: an expert in the method, an expert in the application or domain, and a careful generalist. Then write the area chair's summary that weighs them. Keep each review in the same format.

## Output

Write `research-review-<slug>-<YYYYMMDD>/report.md` from [../templates/review-template.md](../templates/review-template.md). In chat, give the overall recommendation with confidence, the top three objections and the report path.
