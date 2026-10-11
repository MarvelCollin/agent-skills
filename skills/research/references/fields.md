# Field and Document Conventions

Pick the row that matches the document, then follow the venue's author guide when the user names a venue. These are defaults, not laws. The venue's template and the field's norms always win.

## Document Types

| Type | Shape | Readers expect | Common gaps |
|------|-------|----------------|-------------|
| Computer science or machine learning conference paper | Abstract, introduction with a contribution list, related work, method, experiments, conclusion, appendix | Strong recent baselines under equal conditions, ablations for each component, several datasets, variance over seeds, compute and settings reported, code release | Weak or untuned baselines, no ablation, single seed, test set used for tuning, novelty overstated |
| Journal article in the life, health or physical sciences (IMRaD) | Structured abstract, introduction, methods, results, discussion, conclusion | Methods detailed enough to repeat, prespecified outcomes, effect sizes with confidence intervals, ethics approval and consent, data availability, the matching reporting guideline (CONSORT for trials, STROBE for observational studies, PRISMA for systematic reviews, ARRIVE for animal research, STARD for diagnostic accuracy) | Outcome switching, no power analysis, causal wording from observational data, missing flow of participants |
| Social science, education or psychology article | Introduction with theory and hypotheses, method, results, discussion, often APA style | A theoretical frame, hypotheses before analysis, validated instruments with reliability, effect sizes with intervals, preregistration where expected, threats to validity | Measures without reliability, many tests without correction, sample of convenience generalized to a population |
| Engineering or technical report | Executive summary, background, requirements, design, evaluation, recommendations | An executive summary that matches the body, requirements traced to tests, assumptions and constraints stated, recommendations that follow from findings | Summary claims the body does not support, untested requirements, no risk or cost analysis |
| Thesis or dissertation | Introduction with research questions, literature review, methodology, one chapter per study or question, discussion, conclusion | Each research question answered explicitly, a literature review that synthesizes and leads to the questions, consistent terms across chapters, each chapter opening with its aim and closing with its findings | Research questions that drift between chapters, a literature review that lists summaries, repeated material, contributions not stated |
| Research proposal or grant | Aims, significance, innovation, approach, timeline, risks, budget | Aims that are specific and testable, a gap tied to evidence, feasibility shown by preliminary work, success criteria, a risk plan, a budget that matches the work | Vague aims, no fallback, timeline that does not fit the work, preliminary data overstated |
| Humanities article or chapter | Argument led sections, close reading of sources, notes | A clear thesis, primary sources quoted and cited precisely, engagement with counterarguments and the scholarly debate, notes in the field's style | Thesis that shifts, sources quoted without page or edition, debate ignored |
| Systematic review or meta analysis | Protocol, search, screening, synthesis | A registered protocol, a reproducible search string with dates and databases, a screening flow diagram, risk of bias assessment, heterogeneity reported | Search not reproducible, no risk of bias, pooled results from incomparable studies |

## Citation Styles

| Field | Usual style |
|-------|-------------|
| Computer science, engineering | Numeric (IEEE, ACM) or author and year (ACL, many ML venues) |
| Medicine, health | Numeric (Vancouver, AMA) |
| Psychology, education, social sciences | Author and year (APA) |
| Natural sciences | Numeric or author and year, set by the journal (Nature, Science, ACS, AIP) |
| History, arts, much of the humanities | Notes and bibliography (Chicago), or MLA in literature |
| Law | The jurisdiction's citator (Bluebook, OSCOLA) |

When the venue gives a `.bst` or `.csl` file, use it and do not hand format entries.

## Words That Carry Weight

| Word | Needs |
|------|-------|
| "significant" | A statistical test, or use "large" or "notable" instead |
| "causes", "leads to", "improves" | A design that supports cause (randomized, natural experiment, strong quasi experiment) |
| "first", "novel", "state of the art" | A search that supports it and a citation to the strongest prior work |
| "proves", "demonstrates" | Proof, or direct and robust evidence. Otherwise "shows" or "suggests" |
| "generalizes" | Evidence on settings, populations or data not used to build the method |
