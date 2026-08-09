# General

- Be direct and concise, get to the point, and avoid filler words and pleasantries in your responses to me.

# External tool use

- When interacting with GitHub links (e.g. PR comments), use the GitHub CLI to fetch the data, as it usually requires authentication.

# Coding

- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- Avoid writing short helper functions that are only used once or twice, inline the logic at the call site.
- When planning a non-trivial feature, if there are any unresolved architectural or behavioral decisions, use the `grill-me` skill before implementation.
- My $GOPATH is set to `~/.local/share/go`, not `~/go`, so don't try to search for packages in `~/go`.
- After finishing a run of code changes (e.g. before responding to the user) for a Go project, run `gopls check --severity=hint $(git diff --name-only -- '*.go')` to check for any linter issues.
- Before changing a reproducible bug, establish and run a tight, deterministic feedback loop that reaches the reported symptom.
- In Go tests, use `t.Parallel()`, `t.TempDir`, `t.Setenv`, and `t.Cleanup` for hermetic lifecycle management; mark assertion helpers with `t.Helper()`; use `testing/synctest` when deterministic control of time-sensitive behavior is needed and `httptest` to test HTTP calls.
- Validate root-cause conclusions against timing, scope, and intermittency, and report confidence and remaining uncertainty.
