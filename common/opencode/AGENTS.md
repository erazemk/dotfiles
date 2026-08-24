# General

- Be direct and concise, get to the point, and avoid filler words and pleasantries in your responses to me.
- Keep responses short, only reply with what is absolutely necessary for me to understand what you're saying.

# External tool use

- When interacting with GitHub links (e.g. PR comments), use the GitHub CLI to fetch the data, as it usually requires authentication.
- My `$GOPATH` is set to `~/.local/share/go`, not `~/go`, so don't try to search for packages in `~/go`.
- My OpenCode configuration is in `~/.config/opencode`, so don't try to search for it relative to `~`.

# Code style

- Keep changes minimal and local; leverage existing abstractions rather than plumbing code through multiple levels of function calls.
- Do not create small helper methods that are referenced only once.
- Only change what was asked; avoid unrequested refactors, dependencies, files, and speculative abstractions.
- Use the simplest solution that preserves correctness; when unsure, ask.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When writing plans, you must always make sure to remove any redundant text so that the plan is always only the latest state as if it was written in one go. This also applies if the plan changed, update any information that became outdated, or completely remove parts that are not needed.
- Avoid writing short helper functions that are only used once or twice, inline the logic at the call site.
- When planning a non-trivial feature, if there are any unresolved architectural or behavioral decisions, use the `grill-me` skill before implementation.
- Before changing a reproducible bug, establish and run a tight, deterministic feedback loop that reaches the reported symptom.
- Validate root-cause conclusions against timing, scope, and intermittency, and report confidence and remaining uncertainty.
- Declare variables around where they are actually needed, not earlier in the code.
- When planning, regardless of whether it's a bug fix or a new feature, and regardless of whether the plan is written down or not yet, consult the oracle with your final plan before proposing it to the user.
- Inspect git changes (`git status --short`, `git diff`, etc.) after completing the implementation, don't do it after every change.

## Go projects

- After completing all Go edits, run `gopls check --severity=hint $(git diff --name-only -- '*.go')` to check for any linter issues.
- In tests, use `t.Parallel()`, `t.TempDir`, `t.Setenv`, and `t.Cleanup` for hermetic lifecycle management; mark assertion helpers with `t.Helper()`; use `testing/synctest` when deterministic control of time-sensitive behavior is needed and `httptest` to test HTTP calls.
- If a linter points out any issues, you must not add exclusions for those issues or //nolint directives, but instead fix the code you wrote until there are no more issues.
- When adding support for a new interaction with an external service (e.g. adding support for a new endpoint), you can clone the relevant service's Git repository to a temporary directory for inspection (e.g. to see what kind of validations the service does on the input you send it). For libraries you can just inspect the go module cache code instead.
- Use `resp` for responses.
- Inline request structs into gRPC calls if you'd otherwise declare them and then immediately use them.
- Leave empty lines between unrelated blocks of code, like function calls or above a return statement (but keep connected if statements together).
- Avoid using `reflect` package code directly, but it's ok to use other packages/libraries that use reflection.
