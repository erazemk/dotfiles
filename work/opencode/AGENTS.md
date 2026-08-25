# General

- My name is Erazem Kokot and I work for a company called DevRev as a backend engineer in the AirSync (previously Airdrop) team.
- My projects are all in ~/DevRev as cloned git repos.

# Output style

- Use the shortest complete response that preserves correctness.
- Lead with the result; omit preambles, restatements, and process narration.
- Include caveats and explanation only when they materially affect the answer.
- Match detail to the task instead of using a fixed response format.

# External tool use

- When interacting with DevRev systems or verifying test outcomes for DevRev-related code (e.g. checking whether a work was created with the right fields), use `dr` first when it supports the required operation.
- If `dr` does not support the operation, use the `devrev` CLI when it supports the required operation.
- If neither CLI supports the required operation, explain the gap and ask whether to extend `dr` before using another approach.
- Interact with Datadog through the `pup` CLI tool. Always invoke it with `--agent`.
- When interacting with Slack, if using a subagent, use the general subagent, as explore subagents don't have access to the Slack MCP.
- Don't set a timeout when running `make`, unless you're running individual Go tests through `make .a.run`.
- Don't use `rtk` commands with command substitution, `rtk` should only be used when you will directly be consuming the output.
- Restrict searches to the active repository or worktree, avoid searching `$HOME` or anything less granular, stick to project (`~/DevRev/**`) or configuration (`~/.config/dotfiles/**`) directories.
- Do all your temporary work (whatever you'd put into `/tmp`) in the project directory in `_build/opencode/tmp`

# Code style

- Any one-off scripts that should not be committed should go in the project's `_build/scripts/` directory (if the project is in the ~/DevRev directory).
- When starting coding work in the ~/DevRev directory or its subdirectories, use the worktree skill to switch to a new git worktree (this applies only after you start work, not while researching or planning), except if you'd be making changes to a gitignored file/directory, like locally testing, which only changes the gitignored `_build` directory.
- Before writing test cases, inspect surrounding tests to follow existing fixtures and mock patterns.

# Plan Maintenance

Plans under `_build/plans/` are current-state implementation documents, not append-only logs.
They must describe only the latest valid requirements, decisions, implementation state, and remaining work.
When working on an existing feature, check if there is an existing plan for it, and if there is, read it before proceeding.

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
10. Re-read the complete plan after editing it and check for stale, duplicated, contradictory, or missing work.

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
