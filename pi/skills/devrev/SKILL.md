---
name: devrev
description: Fetch DevRev work items (issues, tickets, tasks) or knowledge base articles from the DevRev API. Auto-detects resource type from the identifier. Returns structured JSON with title, description, body (articles), and optional comments (work items).
---

# DevRev Fetcher

Unified script to fetch DevRev work items and knowledge base articles. Theresource type is auto-detected from the identifier format.

## Prerequisites

`DEVREV_API_KEY` environment variable must be set with a valid DevRev PAT or service account token.

## Usage

```bash
~/.agents/skills/devrev/scripts/get <identifier> [--include-comments] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--include-comments` | Include timeline comments (work items only) |
| `--pretty` | Pretty-print JSON output |

## Identifier formats

The script auto-detects whether to fetch a work item or article:

### Work items

- Display ID: `ISS-123`, `TKT-456`, `TASK-789`
- URL: `https://app.devrev.ai/<org>/works/ISS-123`
- DON: `don:core:dvrv-us-1:devo/xxx:issue/yyy`

### Articles

- Display ID: `ART-21296`
- URL: `https://app.devrev.ai/<org>/settings/knowledge-base/articles/ART-15160`
- DON: `don:core:dvrv-us-1:devo/0:article/21296`
- Numeric ID: `21296`

The script returns JSON objects. Fields depend on the resource type.

## Examples

Fetch an issue:

```bash
~/.agents/skills/devrev/scripts/get ISS-216760
```

Fetch a ticket with comments:

```bash
~/.agents/skills/devrev/scripts/get TKT-42 --include-comments --pretty
```

Fetch an article by URL:

```bash
~/.agents/skills/devrev/scripts/get "https://app.devrev.ai/devrev/settings/knowledge-base/articles/ART-15160" --pretty
```

Fetch an article by numeric ID:

```bash
~/.agents/skills/devrev/scripts/get 21296
```
