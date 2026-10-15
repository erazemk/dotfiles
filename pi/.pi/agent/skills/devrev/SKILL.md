---
name: devrev
description: Look up DevRev issues, enhancements and team sprints; create backlog todo issues on explicit request, or prepare confirmed working issues and update their lifecycle for DevRev repository work using the CLI and a bundled API fallback.
---

# Scope and defaults

Use this workflow only for an intended GitHub remote owned exactly by `devrev`, following the commit skill's remote checks.
Use the CLI for DevRev operations; `scripts/issues` wraps it and compensates for missing discovery commands with authenticated API calls.
Normal operations explicitly use `-e prod -o devrev`; never rely on the CLI's remembered environment or org.
Do not print access tokens, enable debug tracing around authentication, or store tokens in files.
Dependencies: Python 3 and an authenticated `devrev` CLI profile.

Hardcoded production defaults:

- User: Erazem Kokot, `don:identity:dvrv-us-1:devo/0:devu/442`.
- Team: AirSync Forge, `don:identity:dvrv-us-1:devo/0:team/Z8HitvyW`.
- Team space: `don:identity:dvrv-us-1:devo/0:space/hLERNDo6`.
- Default parent part: DevRev MCP Server, `don:core:dvrv-us-1:devo/0:capability/147`.

Resolve `scripts/issues` relative to this skill directory and execute it.
Commands default to prod; `show`, `context`, `enhancements`, `prepare`, and `recover` are read-only remotely.
Team assignment is represented by the issue's direct `space` field, which must be set for both working issues and todos.
Assigning a sprint alone does not assign the issue to its team.
Working issues must also use a sprint whose parent space matches the issue's space.
When updating an issue's `space` through `works.update`, include `"type": "issue"` so the API accepts the issue-specific field.
Issues do not accept a direct `group` field.

# Choose the flow

Use the todo flow when explicitly asked to capture a newly discovered issue for later, such as "create a todo for this" or "file this bug for later".
That request authorizes creation immediately; do not add a proposal-confirmation round trip.
Do not create todos merely because an investigation discovers a problem.
Use the existing working-issue flow for the issue being implemented or the commit/PR finishing workflow.
If the intent is ambiguous, ask whether this is backlog capture or current work.
A todo is a separate issue, not a replacement for the issue tracking the current implementation.

# Issue authorship

You may draft descriptions for new issues as part of either authorized creation workflow below.
The user may overwrite them in the app; do not overwrite those edits without a separate request.
When asked to publish user-supplied text, preserve it verbatim.
Do not draft or publish issue comments unless explicitly asked.

# Existing issues

Use an exact issue URL supplied by the user or unambiguously established for this task in the conversation.
If missing, ask: "Is there an existing DevRev issue for this work? Share its URL, or say no and I'll prepare a new one."
Do not create an issue merely because a URL was not supplied.
Run `<script> show <issue-url>` and confirm that it matches the task.
Preserve the supplied exact URL for the commit body, rather than replacing it with a reconstructed URL.
Do not change an existing issue's title, description, owner, sprint, part, dates, or effort without a separate request.
During the finish workflow, transition the existing issue to `in_development` before commit preparation and to `in_review` after successful PR publication.
If already in review with an open PR, preserve its stage during follow-up work rather than moving it backward.
Never reopen a completed/final-stage issue or bypass transition validation automatically.

# Todo issues (backlog capture)

1. Determine a concise title and brief description from the requested finding and available evidence.
   Describe the task to be done, how it was discovered, and relevant links.
   Prefer short `Tasks`, `Discovery`, and `Links` sections with easy-to-scan bullet points.
   Put each distinct action or fact in its own bullet; avoid dense narrative paragraphs and unnecessary nesting.
   Keep descriptions at most 200 words, preferably shorter; there is no minimum length.
   Use proper Markdown with named links such as `[Grafana dashboard](https://devrev.grafana.net/d/ijvsm5n/mcp-dashboard)`, not bare URLs.
   Issue `works.body` is a Markdown string, not an article `devrev/rt` JSON document.
   Distinguish verified facts from suspicions; do not claim an unverified cause or fix.
   Preserve user-supplied text verbatim when asked to publish it, and leave the description blank if requested.
   If supplied text exceeds the limit, ask before shortening it rather than silently rewriting it.
   Ask only if the issue's scope or a consequential choice is unclear.
2. Always use DevRev MCP Server, `don:core:dvrv-us-1:devo/0:capability/147`.
   Todos must not apply to enhancements or any other part.
   Do not discover or select enhancements for this flow.
3. Use a directory from `mktemp -d` for the Markdown description and immutable plan.
   Write the description to a file (empty if requested), then run:
   `<script> prepare --flow todo --title '<title>' --description-file <description-file> --out <plan.json>`.
   The script enforces the DevRev MCP Server part and the 200-word maximum.
   The script validates the AirSync Forge team space and active owner Erazem Kokot, sets `space` directly and stage `triage`, and omits sprint, target start/close dates, and Effort Level entirely (not empty or null values).
   It does not discover or require an active sprint, or require the Pebble effort enum.
4. Run `<script> create --plan <plan.json> --confirmed` immediately; the explicit todo request supplies this authorization.
   The script revalidates the plan, creates directly in Triage, and verifies team space, owner, part, title/description, Triage stage, and absence of sprint, dates, and Effort Level.
   Do not bypass server validation or silently supply dates/effort to satisfy a requirement; report any blocker.
5. Return the issue URL and a short summary of the filed todo, noting that its part is DevRev MCP Server.
   Leave it in Triage and stop this flow; do not transition it to In development/In review or start commit/PR preparation.
   Continue unrelated ongoing work only if already requested.

The shared receipt and recovery rules below also apply to todos.
If creation succeeds but verification fails (including server-assigned sprint, dates, or effort), report the issue URL and mismatch; do not create a duplicate or silently change the persisted fields.
If a todo plan changes during revalidation, prepare it again only when the changes remain within the explicitly authorized todo defaults and scope; ask about any material change.

# New working issues

1. Determine the title and description from the actual task and verified changes, avoiding invented requirements or claims.
   Issue descriptions may describe technical details; they do not inherit the commit skill's restrictions on mentioning code constructs.
   Leave the description blank if the user requests it; the script supports empty descriptions.
2. Honor an explicit user-provided part/enhancement.
   Otherwise run `<script> enhancements` to list all direct child enhancements beneath the default parent, including pagination.
   Choose a clearly fitting enhancement and explain the choice in the proposal; ask if multiple candidates are plausible.
   If none fits, ask whether to use DevRev MCP Server itself or a custom enhancement supplied by the user.
   Do not silently fall back to the parent or create an enhancement.
3. Use a directory from `mktemp -d` for the description and immutable proposal.
   Write the description to a file (empty if requested), then run:
   `<script> prepare --title '<title>' --description-file <description-file> --part <part-don> --out <plan.json>`.
   The script discovers exactly one active sprint in the team space, resolves the team's group, sets the issue's `space` directly to the team space, sets the owner, sets target start to today's local midnight, sets target close to the sprint's exact end timestamp, and resolves Effort Level = Pebble from the tenant schema.
   It does not choose a future/latest-created sprint over the active sprint.
   Ambiguous/missing sprints, inconsistent dates or missing schema values are blockers, not reasons to invent values.
4. Show the complete proposed title and description, owner/team, sprint name and dates, part name/ID, target start/close dates with timezone, and Effort Level.
   Ask for explicit confirmation before creating anything.
   Edits require a new proposal and confirmation; do not treat a request to finish as approval of a not-yet-shown issue.
5. After confirmation, run `<script> create --plan <plan.json> --confirmed`.
   The script revalidates the proposal, creates without a specified initial stage, verifies persisted fields, then transitions to `in_development` and checks the result.
   The initial stage need not be Triage.
   Print the issue URL immediately and continue to commit preparation without requiring another finish invocation.

# Creation safety (both flows)

The proposal includes a unique external reference and creation writes a receipt before calling the API.
Never delete the receipt or blindly retry creation after a timeout/failure; inspect it and run `<script> recover --plan <plan.json>` to look up the external reference, or `show` for its recorded ID.
If recovery finds nothing, report the uncertain result and obtain explicit user authorization before preparing a fresh attempt; do not automatically retry.
If creation succeeded but verification or transition failed, report the issue URL and fix/resume that issue instead of creating a duplicate.
For working issues, if the proposal changes because the date, sprint, owner, part or schema changed, prepare and confirm it again.

# Lifecycle and failure recovery

`<script> transition <issue-url-or-don> in_development`
`<script> transition <issue-url-or-don> in_review`

Only update to In review after the intended PR is successfully opened, or a requested follow-up push to its matching open PR succeeds.
Draft PRs count as opened PRs for this workflow.
If publication fails, leave the issue In development and report the incomplete step.
If publication succeeds but the stage update fails, return both URLs and report the incomplete update; never recreate the commit, issue or PR.
Transitions are idempotent but honor server stage validation.
