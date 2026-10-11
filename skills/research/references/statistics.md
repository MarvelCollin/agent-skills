# Statistics and Evidence Checklist

Used by Audit Mode (Pass 2 and Pass 4) and Review Mode (strength and completeness of evidence). Each item says what to look for and what counts as a problem. Report a problem only with the quoted numbers and their locations.

## Reporting

| Check | Problem when |
|-------|--------------|
| n per analysis | A test, table or figure does not say how many cases it uses, or the n changes without a stated reason |
| Center with spread | A mean without a standard deviation or interval, a median without a range or interquartile range |
| Spread labeled | Error bars or plus or minus values without saying whether they are standard deviation, standard error or a confidence interval |
| Test named | A p value with no named test, or the test does not fit the data (a t test on counts, paired data analyzed as independent) |
| Exact values | "p < 0.05" everywhere instead of exact p values where the venue expects them |
| Effect size | Only significance is reported, with no effect size and interval, so the reader cannot judge whether the effect matters |
| Multiple comparisons | Many tests or outcomes with no correction and no prespecified primary outcome |
| Assumptions | Normality, independence or equal variance assumed without a check when the data clearly violate them |
| Repeated runs | Machine learning or simulation results from a single run or seed, or no spread across runs |
| Small differences | A claimed improvement smaller than the run to run spread, or no test of whether it is real |

## Design

| Check | Problem when |
|-------|--------------|
| Comparison | No control, baseline or prior cohort, yet the text claims an effect |
| Assignment | Groups self selected or assigned by the researcher, then compared as if random |
| Confounders | A plausible third factor (age, prior grades, hardware, data source) is neither measured nor discussed |
| Attrition | Participants or items lost between stages without counts and reasons per group |
| Leakage | Test data seen during training, tuning or feature selection, duplicates across splits, information from the future in time series |
| Equal effort | The proposed method tuned more, trained longer or given more data than the baselines |
| Measurement | An instrument without reported reliability or validity, or a proxy measure treated as the concept itself |
| Power | A null result from a small sample with no power analysis or interval |

## Quick Consistency Checks

Run these by hand on the numbers numbers-extract lists.

- **Percent of n.** A percentage of a group of n people must come from a whole number of people. 33 percent of 50 is 16.5 people, and neither 16 (32 percent) nor 17 (34 percent) rounds to 33, so the percentage or the n is off
- **Means of whole number data.** When every answer is a whole number (a 1 to 7 scale, counts), some whole total divided by n must round to the reported mean. A mean of 3.45 from 19 people needs a total of 65.55, and neither 65 (3.42) nor 66 (3.47) rounds to 3.45. This is the GRIM check
- **Totals.** Subgroup counts sum to the total, and percentages of one whole sum to 100 within rounding
- **Relative change.** "Rose by 20 percent" from 50 to 55 is wrong, it is 10 percent (or 5 percentage points if the values are percentages)
- **Intervals.** A confidence interval contains its point estimate. An interval for a ratio that excludes 1 should match a significant test at the same level
- **Ranges.** Values sit inside their possible range (scale limits, 0 to 1 for proportions and correlations, nothing negative that cannot be)
- **Degrees of freedom.** The degrees of freedom in a test fit the reported n (for example n minus 2 for a correlation)

## Strength of a Causal Claim

| Design | Supports |
|--------|----------|
| Randomized experiment with a control | Cause, within the studied population and setting |
| Natural experiment, regression discontinuity, difference in differences with checks | Cause, with stated assumptions |
| Observational study with adjustment for measured confounders | Association, with cause only cautiously |
| Cross sectional survey or correlation | Association only |
| Case study or anecdote | Illustration and hypotheses |

When the wording is stronger than the design allows, the finding is a Logic finding in Audit Mode and a soundness objection in Review Mode.
