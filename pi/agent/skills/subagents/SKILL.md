---
name: subagents
description: Launch parallel pi subagents for tasks that can be split into independent units of work (e.g. comparing many files, batch refactoring, running independent analyses). Use when the user asks to do something across many files or items that don't depend on each other.
---

# Parallel Subagents

Launch independent units of work as parallel pi subagent processes.

## Command

```bash
pi -p --model "<model>" "<instructions>"
```

Each subagent runs in non-interactive (`-p`) mode. Sessions are saved automatically for observability — do **not** pass `--no-session`.

## Model Selection

Pick the model based on task complexity:

| Model | Use when |
|-------|----------|
| `amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0` | Very basic work: comparing files, search-and-replace, simple lookups |
| `openai/gpt-5.4` | Everything else: analysis, code generation, refactoring, complex reasoning |

## Parallelism

Run up to **10** subagent processes in parallel. Achieve parallelism by making multiple `bash` tool calls in the same tool-call block — each call runs one subagent. Do **not** use shell-level parallelism (`&`, `wait`, `xargs`, GNU parallel, etc.).

### Example: 3 file comparisons in parallel

Issue these as three separate `bash` tool calls in a single block:

```
bash: pi -p --model "amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0" "Compare foo.json and bar.json and list differences"
bash: pi -p --model "amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0" "Compare baz.json and qux.json and list differences"
bash: pi -p --model "amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0" "Compare abc.json and xyz.json and list differences"
```

If there are more than 10 items, batch them into groups of 10 and issue each batch as a separate tool-call block, waiting for the previous batch to complete before starting the next.

## Guidelines

- Each subagent invocation must be **self-contained** — include all necessary context (file paths, what to do, expected output format) in the instructions string.
- Keep instructions concise but unambiguous.
- Aggregate and summarize results yourself after all subagents complete.
