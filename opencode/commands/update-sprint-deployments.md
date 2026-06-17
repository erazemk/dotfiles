---
description: Check current sprint deployment status for my issues and optionally update DevRev stages
---

Arguments: $ARGUMENTS

Track deployment status for my current Airsync Platform sprint issues and optionally update their DevRev stages.

Follow this workflow exactly.

- Resolve the service name.
- If `$ARGUMENTS` contains a non-empty first argument, use `$1` as the service name.
- If no service name is provided, infer it from the current repository/base directory by using the repository root directory name when available, otherwise the current working directory name.
- The matching DevRev code change repository is `devrev/<service-name>`.
- Use the `devrev` subagent first, in read-only mode.
- Ask the `devrev` subagent to find the current Airsync Platform sprint and return only my issues in stages `In Deployment` or `In Testing`.
- Ask the `devrev` subagent to inspect linked `custom_object/code_change` records and include only code changes whose repository is exactly `devrev/<service-name>`.
- Ask the `devrev` subagent to ignore matching code changes without usable `Landed commits` / `custom_fields.tnt__target_commits`.
- Ask the `devrev` subagent to return only rows with these fields: issue ID like `ISS-12345` (or `ASC-12345`), issue title, current stage, related git commit hash.
- Do not ask the `devrev` subagent to update anything during this first step.
- If the `devrev` subagent returns no usable issue commit rows, report that there is nothing to update and stop.
- Run `~/.local/bin/deployment-status <service-name>` locally.
- Treat its non-TTY JSON output as authoritative for deployed commits by environment and region.
- For each issue commit, determine whether it is contained in each deployed commit for `devrev/<service-name>`.
- Prefer `gh api repos/devrev/<service-name>/compare/<issue-commit>...<deployed-commit>` for containment checks.
- Treat the issue commit as deployed in that environment when the compare status is `identical` or `ahead`.
- If a containment check cannot be verified, do not use that environment as evidence for an update.
- Group returned commit rows by issue before deciding stage updates.
- Determine proposed updates with this precedence.
- Propose `Completed` when every usable commit returned for the issue is deployed in every `prod` row returned by `deployment-status`.
- Otherwise propose `In Testing` when the issue is currently `In Deployment` and at least one usable commit returned for the issue is deployed in any `qa` row returned by `deployment-status`.
- Do not propose an update for an issue that is already at the target stage or past it.
- Do not propose an update for issues without verified deployment evidence.
- Show me the proposed updates before making changes.
- For each proposed update, include issue ID, issue title, current stage, target stage, related commit hash, and the environment/region evidence.
- Explicitly ask for approval with the `question` tool before any DevRev updates.
- The approval question must have an option to apply the listed updates and an option to skip.
- If I do not approve, stop without updating anything.
- Only after approval, use the `devrev` subagent to update exactly the listed issue IDs to exactly the listed target stages.
- Ask the `devrev` subagent to return the issue ID, final stage, and update result for each issue.
- Report the final update results concisely.

Important constraints:

- Only update my issues.
- Never update issues owned by someone else.
- Never update DevRev before explicit approval.
- Ignore code changes from repositories other than `devrev/<service-name>`.
- Ignore matching code changes that do not have landed commit hashes.
- If multiple usable commits exist for one issue, use any verified deployed commit as evidence for `In Testing`, but require every usable commit for that issue to satisfy every `prod` row before proposing `Completed`.
