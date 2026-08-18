# General

- Be direct and concise, get to the point, and avoid filler words and pleasantries in your responses to me.

# External tool use

- When interacting with GitHub links (e.g. PR comments), use the GitHub CLI to fetch the data, as it usually requires authentication.
- My $GOPATH is set to `~/.local/share/go`, not `~/go`, so don't try to search for packages in `~/go`.
- My OpenCode configuration is in `~/.config/opencode`, so don't try to search for it relative to `~`.

# Coding

- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When writing plans, you must always make sure to remove any redundant text so that the plan is always only the latest state as if it was written in one go. This also applies if the plan changed, update any information that became outdated, or completely remove parts that are not needed.
- Avoid writing short helper functions that are only used once or twice, inline the logic at the call site.
- When planning a non-trivial feature, if there are any unresolved architectural or behavioral decisions, use the `grill-me` skill before implementation.
- After finishing a run of code changes (e.g. before responding to the user) for a Go project, run `gopls check --severity=hint $(git diff --name-only -- '*.go')` to check for any linter issues.
- Before changing a reproducible bug, establish and run a tight, deterministic feedback loop that reaches the reported symptom.
- In Go tests, use `t.Parallel()`, `t.TempDir`, `t.Setenv`, and `t.Cleanup` for hermetic lifecycle management; mark assertion helpers with `t.Helper()`; use `testing/synctest` when deterministic control of time-sensitive behavior is needed and `httptest` to test HTTP calls.
- Validate root-cause conclusions against timing, scope, and intermittency, and report confidence and remaining uncertainty.
- If a linter points out any issues, you must not add exclusions for those issues or //nolint directives, but instead fix the code you wrote until there are no more issues.
