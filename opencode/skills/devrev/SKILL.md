---
name: devrev
description: Create, fetch, update, or normalize DevRev work items, including current-work tracking issues for in-progress code changes.
---

Work directly with DevRev tools.
Use concise output and return clickable Markdown links.
Include only relevant IDs, titles, stages, dates, owners, parts, and warnings.

## Context

Prefer the conversation context first.
If you already wrote or reviewed the changes in this conversation, use that understanding.
Only inspect git state when conversation context is missing, incomplete, stale, or inconsistent with the current worktree.

## Existing References

If given `ISS-123456`, `TKT-123456`, or a DevRev work URL, normalize the display ID to uppercase and return the Markdown work link.
Use the standard issue URL pattern `https://app.devrev.ai/devrev/works/ISS-299327`, replacing the display ID suffix with the actual work ID.
Fetch object details only if needed for the requested operation.

## Approval

Before creating any issue:
- propose the title and body
- ask for approval with the `question` tool
- ask whether the issue title and description are okay
- provide exactly `Yes` and `No`
- if approval is not granted through `question`, stop

## Current-Work Issue

Use this mode for the current task, current changes, current PR, commit, branch, or finish workflow.
If conversation context is not enough, inspect the relevant patch:
- use `git diff --staged` when staged changes exist
- otherwise use `git diff`
- if both staged and unstaged changes exist, inspect both, but describe only what will actually be committed
- if staged changes exist, assume those are the tracked changes unless the user says otherwise
- if there are no relevant changes and no separate work description, ask what work the issue should track

For current-work issues:
- infer a concise title and body from conversation context first, otherwise from the patch
- describe the change and why it is needed
- do not mention exact file paths or git-specific terms
- use owner `don:identity:dvrv-us-1:devo/0:devu/442`
- use sprint board `don:core:dvrv-us-1:devo/0:vista/2113`
- use effort `Pebble`
- fetch the active sprint from that board and use its ID and `end_date`
- set `target_start_date` to today in UTC at `00:00:00Z`
- omit `stage` on create
- after create, update stage to `in_development` with `don:core:dvrv-us-1:devo/0:custom_stage/5`
- then update stage to `in_review` with `don:core:dvrv-us-1:devo/0:custom_stage/17`
- do not attempt a direct `triage` to `in_review` transition
- if `in_review` update fails, return the created issue and say it remained in `in_development`

Choose `applies_to_part` in this order:
1. For new feature work, search for a matching enhancement first and ask the user if the best match should be used when it is plausible but not certain.
2. Otherwise use these fallback parts when clearly applicable:
`Integration with core DevRev`: `don:core:dvrv-us-1:devo/0:feature/834`
`AirSync Platform`: `don:core:dvrv-us-1:devo/0:capability/5`
`AirSync Sync`: `don:core:dvrv-us-1:devo/0:feature/832`
3. If still unclear, search DevRev parts across `feature`, `capability`, and `product`.
4. If still ambiguous, ask the user.

Use `Integration with core DevRev` for core DevRev integration boundaries and contracts.
Use `AirSync Platform` for generic AirSync or Airdrop platform work, shared libraries, generic loader maintenance, dependency updates, and repo-wide cleanup.
Use `AirSync Sync` for sync behavior and lifecycle changes.

Return for current-work issues:
- display ID
- title
- stage
- Markdown link
- any stage-transition warning

## Normal Issue

Use this mode for separately described work that is not framed as current work.
Use explicit user-provided fields.
Do not apply current-work defaults unless the user asks.
Do not automatically move stages.
If required fields are missing, ask one concise clarifying question.
If names are provided instead of IDs, resolve them when possible.

## Other Operations

For fetch, update, link, or comment requests, do only the requested operation.
If the target or change is unclear, ask one concise clarifying question.
