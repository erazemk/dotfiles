# General

- My name is Erazem Kokot

# Output style

- Use the shortest complete response that preserves correctness.
- Lead with the result; omit preambles, restatements, and process narration.
- Include caveats and explanation only when they materially affect the answer.

# External tool use

- When interacting with GitHub links (e.g. PR comments), use the GitHub CLI to fetch the data, as it usually requires authentication.
- My `$GOPATH` is set to `$HOME/.local/share/go`, not `$HOME/go`, so don't try to search for packages in `$HOME/go`.
- My OpenCode configuration is in `$HOME/.config/opencode`, so don't try to search for it in `$HOME`.
- If needing to do temporary work, create a new temporary directory for it with `mktemp -d`, don't put files into `/tmp` directly.

# Code style

- Keep changes minimal and local - avoid writing short helper functions that are only used once (inline the code instead), or adding structs where there is no need.
- Use the simplest solution that preserves correctness; when unsure, ask.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When planning a non-trivial feature, if there are any unresolved architectural or behavioral decisions, use the `grill-me` skill before implementation.
- When fixing a reproducible bug, figure out the fix, then test the before (by stashing the changes and seeing that the code reproducibly fails) and after (unstashing the fix).
- Declare variables close to where they are first needed, not earlier in the code.

## Go projects

- In tests, use `t.Parallel()`, `t.TempDir`, `t.Setenv`, `t.Cleanup`, `t.Helper()`, `testing/synctest`, and `httptest` when appropriate.
- Avoid using `reflect` package code directly, but it's ok to use other packages/libraries that use reflection.

## Writing and reading plans

- When working on an existing feature, check if there is an existing plan for it, and if there is, read it before proceeding.
- If there is not, only write one if the user explicitly says to write it to a file - otherwise just print the plan in the conversation.
- When writing plans, always remove any redundant text so that the plan only has the latest state. This also applies if the plan changed, update any information that became outdated, or completely remove parts that are not needed.
- Plans must describe only the latest valid requirements, decisions, implementation state, and remaining work.

When creating a plan:

- Explain the goal, intent, relevant context, constraints, important decisions, edge cases, and deferred work.
- Include a checklist of actionable implementation, testing, and validation tasks.
- Make each task specific enough for another agent to implement.
- Do not add changelog, history, or versioning sections.

When reading or revising an existing plan:

1. Read the entire plan before editing it.
2. Compare every existing task with the latest requirements and current implementation state.
3. Keep completed tasks when they still match the current plan.
4. Update tasks whose scope, approach, dependencies, acceptance criteria, or status changed.
5. Remove tasks that are obsolete, superseded, duplicated, or no longer required.
6. Replace outdated tasks with their updated equivalents instead of appending parallel tasks.
7. Add tasks only for genuinely new work that is not already represented.
8. Remove plan text that is no longer relevant.
9. Keep the task list and surrounding plan text aligned with each other.

Re-review and reconcile the plan at these checkpoints:

- When starting a session that references an existing plan.
- Before making changes to an existing plan.
- When requirements, design decisions, scope, or dependencies change.
- When implementation reveals that the plan is incomplete, incorrect, or no longer applicable.
- After completing related implementation work.
- Before marking the work complete.

Do not preserve obsolete tasks merely to record what used to be planned.
Do not add progress reports, changelogs, history, or version metadata.
Do not append a new task when an existing task should be updated, replaced, or removed.
