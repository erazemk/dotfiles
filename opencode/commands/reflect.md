---
description: Analyze the current thread and improve durable agent guidance after approval
---

Arguments: $ARGUMENTS

Analyze this thread and propose durable updates that will make future agents more effective, use fewer tool calls, use fewer turns and less context, and produce clearer output.
Present the proposal and in the same turn ask for approval with the `question` tool.
If approved, apply the approved edits in the same run.

Use this command as a memory-consolidation pass, not as a session summary.
The goal is to improve persistent guidance in both places below when justified:

- Built-in opencode configuration under `~/.config/opencode`, including `AGENTS.md`, configs, commands, agents, skills, plugins, and related docs.
- The current project, including its `AGENTS.md`, `README.md`, docs such as files under `docs/`, skills such as files under `.agents/skills`, scripts, and other durable processes that help future agents work faster and more clearly.

Follow this workflow exactly.

1. Identify the current project and instruction sources in both the built-in opencode setup and the current project.
2. Read the global instruction file at `/Users/erazemk/.config/opencode/AGENTS.md`.
3. Find the nearest project `AGENTS.md` or `CLAUDE.md` by walking up from the current working directory, and read it if present.
4. Read `opencode.json` or `opencode.jsonc` only if needed to understand explicit `instructions` entries.
5. Read referenced instruction docs and other candidate durable files only when the thread shows they matter, when an `AGENTS.md` rule points to them, or when a proposed edit should go there instead of bloating `AGENTS.md`.
6. Do not bulk-read unrelated docs just to search for a place to write memory.

Extract candidate improvements from the thread.
Prioritize these signals:

- User corrections about code style, response style, workflow, tool choice, or what the agent forgot.
- Repeated searches, failed attempts, retries, or debugging paths that should not be rediscovered.
- Recurring test or local-environment failures, especially service setup issues such as Redis or other dependencies.
- Instructions the agent missed, misunderstood, or had to be reminded about.
- Cases where a rule should be moved higher, reworded, shortened, or made more actionable.
- Cases where a required linked file was not read and `AGENTS.md` should make that dependency clearer.
- Cases where `gopls` pointed out issues after Go edits and the underlying pattern should be turned into a durable code-style rule.
- Bulky details that should move out of always-loaded `AGENTS.md` into a referenced doc.
- Reusable multi-step procedures that should become a command or skill rather than another `AGENTS.md` bullet.
- Stale, duplicated, or contradictory instructions.
- Durable project facts, setup quirks, architecture conventions, and troubleshooting recipes that took more than about 1 minute to discover.
- Durable opportunities to improve scripts, repo docs, or other recurring project processes that would reduce future tool churn, turns, or ambiguous output.

Apply this quality filter before proposing any persistent change:

- Keep only durable, reusable, actionable information.
- Skip one-off status, current ticket state, PR state, timestamps, temporary debug paths, and facts that a live API should provide fresh.
- Skip facts discoverable from first principles in under about 1 minute.
- Prefer updating existing instructions over adding duplicates.
- Resolve contradictions at the source instead of appending a second conflicting rule.
- Never store secrets, credentials, private tokens, or sensitive third-party data.
- Convert relative dates to absolute dates if a date is truly needed.
- Prefer edits that improve future agent performance across both the built-in opencode setup and the active project when the thread supports them.

Choose the destination using these rules:

- Use `AGENTS.md` for short, high-priority rules that should affect every future session.
- Put frequently forgotten instructions earlier in `AGENTS.md`, or reword them to be direct.
- When a reusable Go pattern is discovered from `gopls` feedback, prefer adding or refining a rule in `docs/code-style.md` and link it from `AGENTS.md` if future agents should read it.
- Use a referenced doc such as `README.md` or files under `docs/` for verbose troubleshooting, repo maps, debugging recipes, or detailed workflows.
- Add or improve a link from `AGENTS.md` to that doc when the agent should read it lazily for specific tasks.
- Use a command for user-invoked repeatable workflows in either the built-in opencode setup or the current project.
- Use a skill for reusable procedural knowledge that the agent should load on demand.
- Use scripts or other durable project processes when they would materially reduce repeated manual work in future sessions.
- If no persistent file change is justified, say so and do not edit files.

When considering tool-use guidance, include this preference unless an explicit newer instruction contradicts it:

- Focused unit tests should usually run in the primary agent when the primary agent has enough context and the command is bounded.
- Use at most a 10 second timeout for individual Go tests.
- Use the `general` subagent for noisy, long-running, broad, or log-heavy commands such as `make` or large test suites.
- Prefer coding in the primary agent; delegate exploration, broad searches, noisy logs, and external-service work to specialized subagents or tools.

Print a concise proposal with these sections and in the same turn call the `question` tool to ask for approval.

## Proposed Updates
- File: `<path>`
- Change: `<what would change>`
- Why: `<future benefit>`

## Exact Edits
Show the exact text changes the user is approving.
Prefer a unified diff for each file.
If a unified diff would be noisy, show compact before/after snippets with enough surrounding context to make the edit unambiguous.
Do not summarize edits only in prose.

## Skipped Candidates
- `<candidate>` — `<why it should not be persisted>`

## Approval
Ask with the `question` tool.
The approval prompt must come after `Proposed Updates`, `Exact Edits`, and `Skipped Candidates` are visible to the user, but in the same turn (print and then immediately ask, without waiting for a response).
Offer at least these choices:

- Apply all proposed updates
- Skip all updates

If there are multiple independent update groups, include separate approval choices for each group and allow multiple selection.
Do not edit files before approval.

After approval:

- Apply only the approved edits.
- Keep edits small and surgical.
- Preserve the existing style and ordering unless reordering is part of the approved proposal.
- Use concise wording.
- Do not create backward-compatibility rules or extra abstractions unless clearly useful.
- If editing files under `/Users/erazemk/.config/opencode`, remind the user that opencode must be restarted for command, skill, plugin, or config-time changes to take effect.

At the end, report:

- Files changed.
- Candidates skipped.
- Any edits that were approved but could not be applied.
