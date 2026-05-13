---
name: git-commit
description: Inspect current git changes, draft a commit message, require question-tool approval, and create the commit safely. Use when asked to commit changes or when a workflow needs a structured commit step.
---

The user or caller must provide:
- a DevRev issue link to append to the commit body
- additional instructions for commit wording
- explicit direction to include unstaged changes when staged changes also exist

## Context Preference

When drafting the branch name, commit title, and commit body, prefer the context already available in this conversation first.
If you wrote or reviewed the changes earlier in the conversation, use that understanding instead of re-deriving everything from the code.
Only inspect git diffs or other git state when the conversation context is missing, incomplete, stale, or inconsistent with the current worktree.

## Initial Git Inspection

- Use any injected git status or diff stats only as startup context.
- If the conversation already gives you enough context to draft an accurate commit message, do that without re-inspecting the code.
- If more context is needed, inspect the actual patch:
  - run `git diff --staged` if staged changes exist
  - run `git diff` if no staged changes exist
  - if both staged and unstaged changes exist, inspect both, but commit only the staged changes unless the user explicitly asked to include unstaged changes
- Base the branch name, commit title, and commit body only on the changes that will be committed.
- If a DevRev issue link was not provided, stop and ask for it before drafting commit text.
- If there are no staged or unstaged changes, stop and tell the user there is nothing to commit.
- Do not include files that likely contain secrets, such as `.env`, credentials, private keys, or token files.
- If such files appear in the changes, warn the user and exclude them unless the user explicitly confirms.

## Branch Handling

- Check the current branch.
- If the current branch is `main`, create and switch to a new branch named `erazemk/<1-4-words>`.
- Derive the words from the behavioral change.
- Use lowercase kebab-case.
- Do not include the DevRev issue ID.
- If the branch already exists, use a different name.
- If the current branch is not `main`, stay on the current branch.
- Never use destructive git commands such as `git reset --hard` or `git checkout --`.

## Commit Message

Draft a commit message following this exact format.

Title line:
- format: `<prefix>: <Short sentence, first letter capitalized>`
- allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`
- use `chore` for refactors or maintenance changes that do not fit the other prefixes
- use imperative voice: `Add`, `Fix`, `Update`, not `Added`, `Fixed`, `Updated`
- do not end the title with a period

Body:
- always end with the DevRev issue link as a raw URL, not Markdown-formatted
- for simple commits, the body can be only the raw issue URL
- for complex commits, include one or more short explanatory paragraphs before the issue link
- do not wrap paragraphs manually; keep each paragraph as a single line
- backtick-wrap code identifiers, field names, function names, type names, commands, and paths
- add an empty line between the paragraphs and the issue link when both are present

Commit description style:
- opening sentence must start with `This commit ...`
- use `This commit adds ...` for new behavior
- use `This commit fixes ...` for bug fixes
- use `This commit updates ...`, `removes ...`, `enables ...`, or `disables ...` for chores and refactors
- for subsequent references, use `The commit ...` or `It also ...`; do not repeat `This commit`
- use present tense throughout
- use `we` for shared team context
- useful connector phrases include `This is needed because ...`, `Previously ...`, `The commit fixes this by ...`, `For now ...`, and `Due to ...`

- Before committing, always show the proposed commit title and body to the user.
- Always use the `question` tool for approval.
- Ask whether the commit title and description are okay.
- Provide exactly these two options:
  - `Yes`: create the commit
  - `No`: stop without committing
- Do not treat normal chat text as approval.
- If the user does not approve through the `question` tool, stop.

## Commit Creation

If the user approves:
- if changes are already staged, commit only the staged changes
- if nothing is staged, stage all safe changes with `git add -A`
- create the commit using a heredoc for the approved message
- do not amend an existing commit
- if `git commit` fails because a hook reformats or updates files, inspect the new diff, stage the hook-generated changes, and create a new commit with the approved message
- if `git commit` fails for any other reason, surface the error and stop
- after a successful commit, record the new commit hash

After a successful commit, return:
- commit title
- commit body
- commit hash
- branch name
- whether staged-only or all safe changes were committed
- whether hook-generated changes had to be staged and recommitted
