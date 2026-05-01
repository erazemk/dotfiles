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

## DevRev Issue Delegation

Only create a DevRev issue when no issue reference was provided.

Delegate issue creation to the `devrev` sub-agent instead of calling DevRev tools directly here.

Ask the sub-agent to create a current-work PR tracking issue for the changes that will actually be committed.

Pass the sub-agent the following context:

- `Current date (UTC)` from the injected command context.
- The current branch name.
- The staged and unstaged diff stats, plus the actual patch that will be committed.
- A concise summary of the behavior changed.
- The reason for the change, if it is visible from the diff or user instructions.
- Any extra instructions left in `$ARGUMENTS` after removing `draft` and any provided DevRev issue reference.
- Whether the work looks like a bug fix, feature, chore, docs, or CI change.
- Relevant product or domain hints such as AirSync, Airdrop, DevRev loader, core DevRev integration, sync behavior, dependency maintenance, or repo-wide maintenance.
- A reminder to infer a sensible title and body, and to avoid exact file paths or git-specific terms in the issue title or body.
- A reminder to use the current-work PR issue defaults, including the standard owner, sprint lookup, effort level, and stage progression.
- A reminder to return the display ID, title, stage, issue link, and any warning from the stage update.

Use the issue link returned by the sub-agent as the DevRev link in the commit message and PR body.

If the user already provided an issue reference, skip delegation and use that link directly.

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
