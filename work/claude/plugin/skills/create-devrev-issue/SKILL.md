---
name: create-devrev-issue
description: Create a current-work DevRev issue non-interactively from an already-confirmed title and description. Built for the finish workflow — runs in a forked context and never asks the user anything. For interactive or general DevRev work, use the devrev skill instead.
context: fork
user-invocable: false
allowed-tools: mcp__devrev__*
---

Create a DevRev issue for the current work and return its URL. You run in a forked context and cannot talk to the user — **never ask a question; decide everything deterministically.**

## Input contract

The caller provides an **already-confirmed** exact title and exact description (the user has already approved them in the main conversation).

- Use the title and description verbatim. Do not rewrite, summarize, improve, expand, or shorten them.
- Do not put file paths or git-specific terms in the issue text unless the caller included them.
- If the caller named an owner, use it; otherwise default the owner to the active user — call `mcp__devrev__get_self` and use the returned user's ID.

## Create the issue

Call `mcp__devrev__discover_schema` with `action_name='create_issue'` first to confirm field names/enums for the org, then create with:

- `title` / `body`: the confirmed title and description.
- `owned_by`: the caller-named owner, or the active user's ID from `mcp__devrev__get_self` as the default.
- `space` (team): `don:identity:dvrv-us-1:devo/0:space/kI5OWQqm` — AirSync Data Plane (ASDAT). The `space` field requires a space ID; a `group/...` DON is rejected as the wrong ID type.
- `priority_v2`: `3` (P2).
- `applies_to_part`: choose per the heuristics below.
- `sprint`: the latest active sprint (see below).
- `tnt__effort_level`: `Pebble`.
- `target_start_date`: today (the day of creation) in UTC at `00:00:00Z`.
- `target_close_date`: the latest active sprint's `end_date`.
- Omit `stage` on create — the issue lands in `triage`.

After create, transition the stage through `in_development` → `in_review`:

1. `in_development` → `don:core:dvrv-us-1:devo/0:custom_stage/5`. This create-then-update step is required; an issue cannot be created directly in `in_development`.
2. `in_review` → `don:core:dvrv-us-1:devo/0:custom_stage/17`. This is a valid `in_development` → `in_review` transition; do not attempt a direct `triage` → `in_review` move.

If the `in_development` transition fails, return the created issue and note it remained in `triage`. If the `in_review` transition fails, return the created issue and note it remained in `in_development`.

### Fetching the latest sprint

The sprint board (vista) for AirSync Data Plane is `don:core:dvrv-us-1:devo/0:vista/14964` ("AS Data Plane").

- Call `mcp__devrev__list_objects` with `action_name='list_sprint'` and `values`: `{ "parent_id": ["don:core:dvrv-us-1:devo/0:vista/14964"], "state": ["active"], "sort_by": ["start_date:desc"], "limit": 1 }`.
- Use the first returned sprint's `id` for `sprint` and its `end_date` for `target_close_date`.
- If no active sprint is returned, retry with `state: ["planned"]` and the same sort. If still none, omit `sprint` and `target_close_date` and note this in the result — do not block.

### Choosing `applies_to_part`

Decide deterministically and without asking. The part is easily corrected later, so always pick one.

1. **High-confidence enhancement match.** Search the `enhancement` namespace; if the title/description maps to a specific enhancement *near-exactly*, use that enhancement's ID. If the match is only plausible (not near-exact), skip this step.
2. **Intent heuristics** — pick the first that clearly applies:
   - `Integration with core DevRev` → `don:core:dvrv-us-1:devo/0:feature/834` — core DevRev integration boundaries and contracts.
   - `AirSync Platform` → `don:core:dvrv-us-1:devo/0:capability/5` — shared libraries, generic loader maintenance, dependency updates, repo-wide cleanup, generic AirSync/Airdrop platform work.
   - `AirSync Sync` → `don:core:dvrv-us-1:devo/0:feature/832` — sync behavior and lifecycle changes.
3. **Default.** If nothing above clearly applies, use `AirSync Sync` → `don:core:dvrv-us-1:devo/0:feature/832`.

## Return value

Return the created issue's display ID, its canonical app URL (`https://app.devrev.ai/devrev/works/ISS-123`), the chosen `applies_to_part`, the sprint used, and the final stage (`in_review`, or `in_development`/`triage` if a transition failed).
