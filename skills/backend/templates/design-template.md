# Design: {{feature_or_service}}

**Date:** {{date}}
**Author:** agent-skills /backend v0.7.0
**Status:** {{draft_or_approved}}

---

## Summary

{{three_plain_sentences: what is being built, for whom, and the chosen shape}}

## Requirements

| Fact | Value | Source |
|------|-------|--------|
| Peak requests per second now and in 12 months | {{rps}} | {{measured_or_assumed}} |
| Read to write ratio | {{ratio}} | {{source}} |
| Data size now and growth per month | {{size}} | {{source}} |
| Tenancy | {{tenancy}} | {{source}} |
| Data sensitivity | {{tier}} | {{source}} |
| Strongly consistent operations | {{operations}} | {{source}} |
| Team and on call | {{team}} | {{source}} |

**Assumptions:** {{defaults_picked_without_user_input}}

## Success Criteria

| Journey | p50 | p95 | p99 | SLO |
|---------|-----|-----|-----|-----|
| {{journey}} | {{ms}} | {{ms}} | {{ms}} | {{pct}} |

- **RPO:** {{rpo}}
- **RTO:** {{rto}}
- **Built for:** {{capacity}}. **First expected bottleneck:** {{bottleneck}}

## Capacity Estimate

{{back_of_envelope_math_with_numbers}}

## Architecture

{{components, what each owns, how they talk (sync or async), and why this shape}}

## Data Model

| Table | Key | Columns | Constraints | Tenancy |
|-------|-----|---------|-------------|---------|
| {{table}} | {{pk}} | {{columns}} | {{constraints}} | {{tenant_column}} |

### Access Patterns and Indexes

| Query | Filter and sort | Rows | Frequency | Index |
|-------|-----------------|------|-----------|-------|
| {{query}} | {{filter_sort}} | {{rows}} | {{per_second}} | {{index}} |

## API Contract

| Method and path | Purpose | Who may call | Idempotent | Notes |
|-----------------|---------|--------------|------------|-------|
| {{method_path}} | {{purpose}} | {{policy}} | {{yes_no_key}} | {{pagination_limits}} |

OpenAPI: {{path_to_spec}}

## Failure Modes

| Dependency | If slow | If down | If it answers twice | Timeout | Retry | Fallback |
|------------|---------|---------|---------------------|---------|-------|----------|
| {{dependency}} | {{behavior}} | {{behavior}} | {{behavior}} | {{t}} | {{r}} | {{f}} |

## Security and Privacy

{{authentication, authorization model, data classification, audit events, secrets, abuse limits}}

## Observability

{{SLIs, alerts with runbooks, dashboards, key logs and traces}}

## Rollout

{{migration order, feature flag, load test plan and pass criteria, canary, rollback triggers}}

## Decisions

### ADR 1: {{decision_title}}

- **Context:** {{why_a_decision_was_needed}}
- **Options:** {{options_considered}}
- **Decision:** {{choice}}
- **Consequences:** {{trade_offs_accepted}}

## Risks and Open Questions

- {{risk_or_question_with_owner}}
