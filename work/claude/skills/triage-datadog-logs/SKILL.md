---
name: triage-datadog-logs
description: Triage the most common production errors for Erazem's services using the live Datadog dashboard. Use when asked to check/triage Datadog errors, review the dashboard, or investigate recent production errors for the airdrop loader/extractor services.
model: sonnet
effort: high
---

Run a structured triage of recent production errors for the services on the **"Erazem's Services"** Datadog dashboard (`q7p-88p-qds`). Output is a **markdown report only** — never create issues, post to Slack, or mutate anything unless the user explicitly asks in a follow-up.

## Prerequisites

- The Datadog MCP must be connected. First load its skill guides: `mcp__datadog__load_datadog_skill` for `datadog/logs`, `datadog/traces`, and `datadog/investigation-workflows` (correct query syntax and attribute names live there).
- All Datadog log/span queries must be scoped by `env`, `service`, and a time window. Default window: past 24h (`from=now-1d`, `to=now`). Honor a different window if the user gives one.

## Step 1 — Read the dashboard live (do not hardcode scope)

Call `mcp__datadog__get_datadog_dashboard` with `dashboard_id=q7p-88p-qds`. Extract, from the response:

- The **service list** from the `service` template variable `defaults`.
- The **env** from the `env` template variable (default `prod`) and **region** from `region` (default `*` = all).
- The **"Errors and Emergencies" widget `query_string`** — currently `$env $region $service -status:(info OR warn)`. Use this exact status filter, **not** `status:error` (the widget intentionally also catches `emergency` and status-less logs). Substitute the template variables with the resolved values.

The scope as of this writing: services `airdrop-devrev-extractor`, `airdrop-devrev-loader`, `airdrop-kafka-consumer`; `env:prod`; all regions. Always re-read — the dashboard may have changed.

Build the base filter, e.g.:
```
env:prod (service:airdrop-devrev-extractor OR service:airdrop-devrev-loader OR service:airdrop-kafka-consumer) -status:(info OR warn)
```

## Step 2 — Rank error volume by service

`mcp__datadog__analyze_datadog_logs` over the window with the base filter as `filter`:
```sql
SELECT service, COUNT(*) as cnt FROM logs GROUP BY service ORDER BY cnt DESC
```
This tells you where to focus. One service usually dominates.

## Step 3 — Cluster errors into patterns

`mcp__datadog__search_datadog_logs` with `use_log_patterns=true`, `clustering_pattern_field="message"`, `pattern_group_by=["service"]`, and the base filter as `query`. Use `max_tokens` ~20000.

This returns one row per error pattern with a count and sample message. Note: pattern counts are **sampled (capped ~5000)** — treat them as relative shape, and confirm absolute counts with `analyze_datadog_logs` (Step 4).

For query syntax, scoping, `dev_oid` matching, and JSON escaping of filters, follow the `datadog` skill — it's the single source of truth for query mechanics, so don't restate those rules here.

## Step 4 — Baseline each top cluster (anomaly detection)

For each of the top patterns, pull a distinctive substring of the message (strip IDs/wildcards) and get its true daily volume over the past 7 days:
```sql
SELECT DATE_TRUNC('day', timestamp) as day, COUNT(*) as cnt
FROM logs
WHERE message LIKE '%<distinctive substring>%'
GROUP BY DATE_TRUNC('day', timestamp) ORDER BY day
```
Use `filter` = `env:prod service:<service>`, `from=now-7d`.

**Flag a cluster as an anomaly** when today's count is a large multiple of the prior-day baseline (e.g. prior days 0–15/day, today 7,925). Also flag any **new** pattern (no occurrences in prior days) even at low volume. Chronic-but-flat high-volume patterns are noise to call out separately, not anomalies.

For an anomaly, also bucket by hour (`DATE_TRUNC('hour', timestamp)`, `from=now-1d`) to find the spike window.

## Step 5 — Root-cause the top / anomalous clusters

For each cluster worth investigating:

1. Pull a representative sample with full context: `search_datadog_logs` with the message substring and `extra_fields=["*"]`, `max_tokens` ~5000. Capture: `custom.stacktrace`, `custom.event_type`, `custom.external_system_*`, `custom.sync_unit_id`, `custom.run_id`, `custom.recipe_system`, `trace_id`, and `version`.
2. **Is it one sync or broad?** Check whether the errors share a single `sync_unit_id` / `run_id` / `request_id`. A single-sync spike (one customer, one run) is very different from a systemic regression — say which.
3. **Correlate to code.** The `version` tag (e.g. `vc2915ae`) maps to a git commit (`c2915ae...`). Delegate reading the files named in `custom.stacktrace` to an `Explore` agent rather than reading them yourself, to keep stack-trace-driven code dumps out of this conversation's context. Frames under `github.com/devrev/airdrop-devrev-loader/internal/...` live in the loader repo (`~/DevRev/airdrop-devrev-loader`); frames under `github.com/devrev/airdrop-devrev-extractor/...` in the extractor repo. Stack frames under `github.com/devrev/airdrop-common/...` are the shared library (a Go module dependency, not editable from those repos — note the version). This skill is user-scoped and may run outside the relevant repo: if the source isn't reachable, report the `file:line` from the stacktrace and note the code wasn't read rather than guessing.
4. **Assess severity vs. logging.** Many loader "errors" are best-effort/recoverable paths logged loudly (e.g. an actor that fails to resolve falls back to a system user). Determine from the code whether the error is fatal to the sync or a noisy non-fatal log. State your confidence.
5. If the log alone is insufficient and a `trace_id` is present, pull the trace with `mcp__datadog__get_datadog_trace`.

## Step 6 — Write the markdown report

Output only a markdown report. Structure:

- **Scope** — dashboard services, env, region, window, and the exact query used (so the run is reproducible).
- **Volume by service** — the Step 2 table.
- **Per cluster** (ranked, anomalies first), for each:
  - Error message (templated) and total count.
  - **Trend**: today vs 7-day baseline; ANOMALY / new / chronic-flat label; spike window if any.
  - **Blast radius**: single sync (with `sync_unit_id`/`run_id`/external system) vs broad.
  - **Code location**: `file:line` for this-repo frames; note airdrop-common version for library frames.
  - **Root-cause hypothesis** with explicit confidence (high/medium/low) and what would confirm it.
  - **Proposed fix** — concrete (e.g. downgrade log severity, fix ordering, guard nil) — or "needs more data: <what>".
- **Noise / non-actionable** — single isolated events, transient infra blips (`no healthy upstream`, gRPC `Unavailable`), etc., listed briefly so they're acknowledged but not chased.

## Conventions

- Translate data into conclusions; do not paste raw log dumps into the report.
- Pull representative samples, not exhaustive lists.
- Run independent Datadog queries in parallel where possible.
- Do not propose code edits in this skill — propose fixes in prose. Implementing a fix is a separate, explicit ask.
