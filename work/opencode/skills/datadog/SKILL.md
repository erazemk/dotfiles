---
name: datadog
description: Investigate runtime behavior through Datadog logs, traces, metrics, and events. Use proactively when code alone cannot confirm behavior, or when given a Datadog URL, service, environment, trace/run/request ID, time window, or production error.
---

Use Datadog when runtime evidence is the cheapest way to test a hypothesis — not reflexively. If reading code answers the question, skip it.

## Before searching

- Extract the likely service, environment, time window, identifiers, failure mode, and search terms from the input.
- If given a Datadog URL, infer as much as possible from it before searching broadly.
- The Datadog MCP ships skill guides. Load the relevant one first (e.g. `load_datadog_skill` with `datadog/logs`, `datadog/traces`, or `datadog/metrics`) for correct attributes and query syntax.

## Searching

Prefer narrow searches. Scope every query by service, environment, and a time window anchored to the incident. Reduce noise with trace ID, run ID, request ID, status, resource name, and distinctive error text. Follow the most promising trail first.

- **Logs** — error messages, stack traces, and context around the incident time.
- **Traces (APM) / spans** — where latency or errors originate across service boundaries; the failing span, slow query, or downstream dependency.
- **Metrics** — error rates, latency percentiles, throughput, resource usage; correlate spikes with deploys.
- **Services** — resolve or discover the right service name and its dependencies when you're unsure what to scope queries to.
- **Events/deploys** — deployment markers, config changes, and monitor alerts that line up with symptom onset.

Pull representative samples (a handful of error traces), not exhaustive dumps. Translate raw data into conclusions — explain what each finding proves or disproves; never just paste logs.

## Query escaping

The search tools take their query/filter as a JSON string, so the query has to be valid JSON before it is valid Datadog syntax. Malformed queries fail with `InputValidationError: ... could not be parsed as JSON`. Avoid it:

- Quote every value that contains a wildcard, colon, or special character — `@dev_oid:"*1234"`, not `@dev_oid:*1234` as a bare token; `extra_fields` must be a JSON array like `["*"]`, never a bare `*`.
- Escape backslashes for the JSON layer: a regex `\d` is written `\\d` in the query string.
- If a query round-trips through string building, validate it parses as JSON before sending rather than guessing at the escaping.

## Filtering by dev_oid

`dev_oid` appears in two formats depending on the service: Display ID (`DEV-1234`) in some services vs DON (`don:identity:dvrv-*:devo/1234`) in airdrop/snap-in services. A query in one format silently returns 0 results against logs in the other.

To match both, filter on the bare numeric ID with a leading wildcard: `@dev_oid:*<ID>` (for `DEV-1234`, `ID=1234` → `@dev_oid:*1234`). This matches both `DEV-1234` and `don:identity:dvrv-*:devo/1234`.
