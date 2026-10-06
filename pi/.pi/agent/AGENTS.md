# General

- My name is Erazem Kokot.
- My projects are cloned Git repositories in `~/Code`.
- I work at DevRev as a backend engineer.

# External tools

- My `$GOPATH` is `$HOME/.local/share/go`, not `$HOME/go`.
- Create temporary work inside a new directory from `mktemp -d`, not directly in `/tmp`.
- Use `gh` to fetch GitHub links, including PR comments, because authentication is often required.
- Use `circleci` when needing to interact with CircleCI - getting the last job, seeing why it failed.
- Use `devrev` when needing to interact with DevRev - getting or updating issues.
- Use `ketch` for external research - web pages, OSS code, library docs.
- Use `gcx` when needing to interact with Grafana/Loki - checking logs, dashboards, or alerts.

## Using ketch

- `ketch search "query"` / `ketch search "query" --scrape` for web results with optional full content (add `--multi` to federate across backends and rank-fuse)
- `ketch scrape <url> [url...]` for clean markdown from one or more URLs
- `ketch extract` for already-fetched/piped HTML (`curl ... | ketch extract`) — no fetch, no cache, no browser
- `ketch code "query" --lang go` for real OSS code with repo/line context; `--repo owner/name` searches one repository
- `ketch docs "query" --library /org/repo` for version-aware library docs
- All commands support `--json`. `ketch config` reports active backends.

# Code style

- Keep changes minimal and local; avoid single-use convenience helpers and unnecessary structs.
- Use the simplest solution that preserves correctness; ask when a consequential decision is unclear.
- Declare variables close to their first use.
- Do not shorten preexisting comments; only correct parts made inaccurate by the change.
- In Markdown, put each sentence on its own line without unnecessarily splitting sentences.
- Use `grill-me` before implementation when consequential architectural or behavioral decisions remain unresolved.
- For a reproducible bug, verify that the same scenario fails without the fix and passes with it.
- When using stash for this comparison, stash only the relevant fix changes and preserve unrelated user work, including staged state.
- Report verification that could not be completed; do not present a hypothesis or passing unrelated tests as proof of a fix.

## Go

- In tests, use `t.Parallel()`, `t.TempDir`, `t.Setenv`, `t.Cleanup`, `t.Helper()`, `testing/synctest`, and `httptest` when appropriate.
- Avoid using `reflect` directly; libraries that use reflection are fine.

# Delegation

- Use `openai/gpt-6.1-sol` for general work.
- Use Sol with high thinking in a separate Pi instance for code reviews and independent second opinions (the oracle).
- Use `openai/gpt-6-luna` for bounded code exploration and reading or summarizing large volumes of text.
- Delegate independent tasks or large reads when doing so improves focus or allows useful parallel work, not for trivial lookups.
- Run child instances from the relevant repository directory.
- They do not inherit this conversation: provide the concrete task, scope, relevant files or diff, constraints, verification results, and required output.
- Use `--no-session -p` for one-shot tasks; omit tool restrictions so normal tools and integrations remain available.
- For large task context, write a context file inside a directory created with `mktemp -d` and pass it as `@<context-file>`.

Exploration example:

```sh
pi --model arcus/openai/gpt-6-luna --print "<bounded exploration task and output requirements>"
```

Oracle example:

```sh
pi --model arcus/openai/gpt-6.1-sol:high --append-system-prompt "$HOME/.pi/agent/skills/second-opinion/SKILL.md" --print "<review question, scope, evidence, and constraints>"
```

The `second-opinion` instructions are for the child oracle, not for the main agent's implementation work.
When acting as that oracle, do not spawn another reviewer or delegate the assessment.
Evaluate returned findings against the evidence before applying changes; do not treat a second opinion as authoritative.
