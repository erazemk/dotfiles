---
name: datadog
description: Work with Datadog logs and traces for debugging. Use when you need to search logs or spans, aggregate by facets, or cluster log patterns, and when you want concise, actionable log bodies without HTTP noise. Includes stdlib Python scripts for log search/aggregate/patterns and trace search.
---

# Datadog Debug Skill

Use the scripts in `scripts/` to query Datadog and return concise, actionable output. Default output omits noisy fields (`tags`, `host`, and large attribute subtrees). Use `--all` to include everything.

## Quick Start

1. Build a Datadog query string (same syntax as the Datadog UI).
2. Call one of the scripts below.
3. Use the output to reason about errors, patterns, and traces.

## Scripts

`logs` supports log search, aggregation, and pattern clustering.
```bash
scripts/logs search --query 'service:airdrop-devrev-loader @run_id:8ea11faf-4b93-47d8-bbf8-f4541a395cc8'
scripts/logs aggregate --query 'service:airdrop-devrev-loader status:error' --group-by @error.message
scripts/logs pattern --query 'service:airdrop-devrev-loader status:warn'
```

`traces` supports span search.
```bash
scripts/traces search --query 'service:airdrop-devrev-loader @trace_id:1234'
```

## Interface

`logs <action> --query <datadog query> [options]`

Actions:
- `search`
- `aggregate`
- `pattern`

Options:
- `--from` (default `now-1h`)
- `--to` (default `now`)
- `--limit` (defaults: search 20, aggregate/pattern 10)
- `--all` (include full tags, host, and attributes)

Action-specific options:
- `aggregate`: `--group-by`, `--aggregation` (default `count`), `--metric`
- `pattern`: `--pattern-field` (default `message`)

`traces <action> --query <datadog query> [options]`

Actions:
- `search`

Options:
- `--from` (default `now-1h`)
- `--to` (default `now`)
- `--limit` (default 20)
- `--all` (include full tags, host, and attributes)

## Environment

Set these env vars before running:

- `DD_API_KEY`
- `DD_APP_KEY`

## Output Rules

- Default output omits `content.tags`, `content.host`, `content.attributes.sync_options`, and `content.attributes.lambda`.
- Use `--all` to include full content.
- Always return formatted log bodies or span summaries; never print raw HTTP payloads.
- The `pattern` action paginates through up to 100 pages (100 000 logs) with `page.limit=1000`, clusters the sampled logs client-side, and returns only the summarized patterns instead of every log event; counts may be incomplete when more than 100 000 logs match the query.
