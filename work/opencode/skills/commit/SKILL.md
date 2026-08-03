---
name: commit
description: Create a git commit. Use whenever the user asks to commit changes or a finishing workflow requires a commit.
---

Commit messages require a DevRev issue URL to be appended to the commit body.
If the conversation did not reference a DevRev issue URL yet, ask the user to provide one.

Prefer the existing conversation context when drafting the branch name, commit title, and commit body.
The current git state is captured below; use it as the primary input and only re-inspect with git tools if it is truncated or you need more detail (e.g. a full diff of a specific file).

## Current git state

Branch prefix:
!`id -un`

Branch:
!`git branch --show-current`

Status (short):
!`git status --short`

Staged diff:
!`git diff --staged`

Unstaged diff:
!`git diff`

## Inspection rules

- If staged changes exist, use the staged diff above.
- If nothing is staged, use the unstaged diff above.
- If both staged and unstaged changes exist, consider both, but commit only the staged changes unless the caller explicitly asked to include unstaged changes.
- If there are no staged or unstaged changes, stop and say there is nothing to commit.

## Branch rules

- Check the current branch.
- If it is `main`, create and switch to `<prefix>/<1-4-words-about-the-change>`, where `<prefix>` is the branch prefix captured above.
- Use lowercase kebab-case derived from the behavioral change.
- Do not include the DevRev issue ID in the branch name.
- If the branch is not `main`, stay on it.

## Commit format

The required format depends on whether this is the first commit on the branch (i.e. nothing has been pushed yet) or a follow-up commit on an already-pushed branch.

### First commit (branch not yet pushed to origin)

This commit's title and body become the basis for the PR title and description, so they must follow the full convention:

- Title: `<prefix>: <Short sentence, first letter capitalized>`.
- Allowed prefixes: `fix`, `feat`, `chore`, `docs`, `ci`.
- Use imperative voice and do not end the title with a period.
- Body must end with the exact DevRev URL provided by the caller.
- Simple commits should use only that exact DevRev URL as the body.
- Complex commits may include a short paragraph before the issue URL only when the extra context is genuinely needed.
- Describe what behavior changed — what works differently after the change — not which functions, variables, files, or code constructs were modified; never mention specific function names, variable names, type names, error names, or file paths in the commit body.
- The opening sentence (if applicable) must start with `This commit ...`.
- Use present tense.
- Avoid personal pronouns (`I`, `we`, `our`, `my`) entirely.
- Avoid vague referents like `it`, `this`, `that` — name the actual service, function, file, or person explicitly instead.
- Don't hard wrap the body, keep each paragraph as a single line; the PR body will be wrapped automatically.
- **The first commit's title and description must be approved by the user before committing. Show the proposed title and body, then use an available tool to request approval; otherwise ask for approval in the conversation.**

After a successful commit, return the commit title, body, hash, branch name, whether staged-only or all safe changes were committed, and whether hook-generated changes had to be staged and recommitted.

### Follow-up commits (branch already pushed to origin)

- The PR title and description are already set; these commits are squashed on merge, so only a short summary title is needed.
- For follow-up commits also skip asking for approval, but do not push the follow-up commit automatically — ask the user whether to push it after committing.
- Never squash, rebase, amend, or force-push to tidy up branch history. The repo's enforced merge strategy squashes all commits into one on merge, so intermediate commits never reach `main` — a messy branch history is expected and requires no cleanup.
