# Load Test: {{service}}

**Date:** {{date}}
**Tester:** agent-skills /backend v0.6.0
**Target:** {{base_url}}
**Authorization:** {{local_build_or_user_statement}}

---

## Summary

{{three_plain_sentences: what was tested, whether it met the goal, the capacity found, and the bottleneck}}

**Result: {{pass_or_fail}} against the goal of {{goal}}**

---

## Setup

- **Test type:** {{smoke_load_stress_spike_soak_breakpoint}}
- **Tool:** {{autocannon_or_k6_or_other}}, {{open_or_closed}} workload model
- **Traffic mix:** {{endpoints_and_ratios}}
- **Data volume:** {{rows_in_main_tables}}
- **Environment:** {{server_size_and_location, generator_location}}
- **Caveats:** {{for_example_generator_and_server_on_one_machine}}

---

## Results

| Run | Rate or connections | Duration | Requests | RPS | p50 ms | p90 ms | p99 ms | Error % | Result |
|-----|---------------------|----------|----------|-----|--------|--------|--------|---------|--------|
| {{run}} | {{load}} | {{d}} | {{n}} | {{rps}} | {{p50}} | {{p90}} | {{p99}} | {{err}} | {{pass_fail}} |

**Knee of the curve:** {{rate_where_latency_starts_to_climb}}
**Capacity at the goal:** {{max_rate_that_meets_the_goal}}

---

## Server Side

| Resource | At baseline | At peak | Saturated? |
|----------|-------------|---------|------------|
| App CPU | {{v}} | {{v}} | {{y_n}} |
| App memory | {{v}} | {{v}} | {{y_n}} |
| Event loop lag or thread pool | {{v}} | {{v}} | {{y_n}} |
| DB connections in use and waiting | {{v}} | {{v}} | {{y_n}} |
| DB CPU | {{v}} | {{v}} | {{y_n}} |
| Cache hit ratio | {{v}} | {{v}} | {{y_n}} |
| Queue depth | {{v}} | {{v}} | {{y_n}} |

---

## Bottleneck

{{the_saturated_resource, the_evidence (trace, plan, metric), and_why_it_limits_throughput}}

---

## Fixes

| Priority | Fix | Expected effect | Effort |
|----------|-----|-----------------|--------|
| P0 | {{fix}} | {{effect}} | {{effort}} |

## Before and After

{{numbers_for_any_fix_applied_and_re-tested, or "No fixes applied yet."}}

---

## Appendix

- **Raw results:** {{paths_to_json_and_summaries}}
- **Scripts:** {{k6_script_or_commands}}
