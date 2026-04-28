---
description: Create a DevRev issue if needed, commit, push, and open a PR
---

Arguments: $ARGUMENTS
Current date (UTC): !`date -u +%Y-%m-%d`
Current branch: !`git branch --show-current`
Git status: !`git status --short`
Staged diff stat: !`git diff --staged --stat`
Unstaged diff stat: !`git diff --stat`

Create a DevRev-backed commit and pull request for the current changes. Follow the workflow in this command exactly.

## Argument Handling

- Parse `$ARGUMENTS` for an optional DevRev issue reference. Accept either `ISS-123456` or any DevRev work link containing an `ISS-123456` display ID. Normalize the display ID to uppercase.
- Parse `$ARGUMENTS` for the standalone word `draft`, case-insensitive. If present, create a draft PR. Remove this word from the remaining free-form instructions.
- Treat any remaining argument text as additional instructions for issue, commit, branch, and PR wording.
- If an issue reference is provided, do not create a new DevRev issue. Use `https://app.devrev.ai/devrev/works/ISS-123456` as the issue link in the commit and PR body.

## Initial Git Inspection

- Use the injected git status and diff stats only as startup context.
- Before drafting any issue or commit text, inspect the actual patch:
  - Run `git diff --staged` if staged changes exist.
  - Run `git diff` if no staged changes exist.
  - If both staged and unstaged changes exist, inspect both, but commit only the staged changes unless the user explicitly asks to include the unstaged changes.
- Base the issue title, issue body, branch name, commit message, and PR text only on the changes that will be committed.
- If there are no staged or unstaged changes, stop and tell the user there is nothing to commit.
- Do not include files that likely contain secrets, such as `.env`, credentials, private keys, or token files. If such files appear in the changes, warn the user and exclude them unless the user explicitly confirms.

## DevRev Issue Creation

Only create a DevRev issue when no issue reference was provided.

Use these known DevRev values without schema discovery unless a DevRev MCP call fails because the schema or IDs are stale:

- Owner: `don:identity:dvrv-us-1:devo/0:devu/442`
- AirSync Platform sprint board: `don:core:dvrv-us-1:devo/0:vista/2113`
- Effort level: `Pebble`
- Initial stage name: `in_review`

When creating an issue:

- Infer a sensible title and body from the diff and extra instructions.
- Do not mention exact file paths or git-specific terms in the issue title or body.
- Describe what changes did and why, if the reason is visible from context.
- Choose `tnt__category_ai_predicted` as one of `Bug`, `Incident`, `New Work`, or `Tech Debt` based on the type of change.
- Find the most relevant part with DevRev hybrid search over `feature`, `capability`, and `product`, using a concise query based on the behavior being changed. For obvious AirSync/Airdrop DevRev core-service work, prefer `don:core:dvrv-us-1:devo/0:feature/834` (`Integration with core DevRev`) if it matches the change.
- Fetch the active AirSync Platform sprint with DevRev `list_objects(action_name="list_sprint", values=...)` using:
  - `parent_id`: [`don:core:dvrv-us-1:devo/0:vista/2113`]
  - `state`: [`active`]
  - `sort_by`: [`start_date:desc`]
  - `limit`: `1`
- Use the active sprint ID as `sprint`.
- Use `Current date (UTC)` as `target_start_date` in the form `YYYY-MM-DDT00:00:00Z`.
- Use the active sprint `end_date` as `target_close_date`.

Create the issue with DevRev `create_object(action_name="create_issue", values=...)` and these fields:

- `title`: inferred issue title
- `body`: inferred issue description
- `applies_to_part`: selected part ID
- `owned_by`: [`don:identity:dvrv-us-1:devo/0:devu/442`]
- `sprint`: active AirSync Platform sprint ID
- `stage`: `{ "name": "in_review" }`
- `target_start_date`: today at `00:00:00Z`
- `target_close_date`: active sprint end date
- `tnt__category_ai_predicted`: inferred category
- `tnt__effort_level`: `Pebble`

After creation, use the returned display ID to build the issue link: `https://app.devrev.ai/devrev/works/ISS-123456`.

## Branch Handling

- Check the current branch.
- If the current branch is `main`, create and switch to a new branch named `erazemk/<1-4-words>`:
  - Derive the words from the behavioral change.
  - Use lowercase kebab-case.
  - Do not include the DevRev issue ID.
  - If the branch already exists, use a different name.
- If the current branch is not `main`, stay on the current branch.
- Never use destructive git commands such as `git reset --hard` or `git checkout --`.

## Commit Message

Draft a commit message following this exact format.

Title line:

- Format: `<prefix>: <Short sentence, first letter capitalized>`
- Allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- Use `chore` for refactors or maintenance changes that do not fit the other prefixes.
- Use imperative voice: `Add`, `Fix`, `Update`, not `Added`, `Fixed`, `Updated`.
- Do not end the title with a period.

Body:

- Always end with the DevRev issue link.
- For simple commits, the body can be only the issue link.
- For complex commits, include one or more short explanatory paragraphs before the issue link.
- Do not wrap paragraphs manually; keep each paragraph as a single line.
- Backtick-wrap code identifiers, field names, function names, type names, commands, and paths.
- Add an empty line between the paragraphs and the issue link.

Commit description style:

- Opening sentence must start with `This commit ...`.
- Use `This commit adds ...` for new behavior.
- Use `This commit fixes ...` for bug fixes.
- Use `This commit updates ...`, `removes ...`, `enables ...`, or `disables ...` for chores and refactors.
- For subsequent references, use `The commit ...` or `It also ...`; do not repeat `This commit`.
- Use present tense throughout.
- Use `we` for shared team context.
- Useful connector phrases include `This is needed because ...`, `Previously ...`, `The commit fixes this by ...`, `For now ...`, and `Due to ...`.

Show the proposed commit message to the user before committing. Ask for confirmation with exactly two options:

- `Yes`: commit, push, and open the PR.
- `No`: stop without committing, pushing, or opening a PR.

Do not offer a separate revise option. If the user says no or does not approve, stop.

## Commit Creation

If the user approves:

- If changes are already staged, commit only the staged changes.
- If nothing is staged, stage all safe changes with `git add -A`.
- Create the commit using a heredoc for the approved message.
- Do not amend an existing commit.
- If `git commit` fails because a hook reformats or updates files, inspect the new diff, stage the hook-generated changes, and create a new commit with the approved message.
- If `git commit` fails for any other reason, surface the error and stop.
- After a successful commit, record the new commit hash.

## Push And PR

- Push the branch with `git push -u origin HEAD`.
- Open the PR immediately after push. Do not ask for separate PR confirmation.
- PR title must exactly match the commit title.
- PR body must exactly match the commit body.
- Use `gh pr create --title "..." --body "..."`.
- Add `--draft` only if the standalone word `draft` appeared in `$ARGUMENTS`.
- Print the PR URL at the end.

If `gh` is not authenticated, stop after the branch is pushed and tell the user to authenticate with `gh auth login`, then rerun only the PR creation step.
