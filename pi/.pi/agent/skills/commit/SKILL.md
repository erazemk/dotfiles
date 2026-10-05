---
name: commit
description: Create a Git commit when requested or required by a finishing workflow, using remote ownership to distinguish DevRev issue-linked commits from personal main-branch commits.
---

Inspect the current branch, status, relevant diff, and fetch/push remote URLs.
A DevRev repository has a GitHub remote owned by `devrev`, such as `git@github.com:devrev/<repo>.git`, `ssh://git@github.com/devrev/<repo>.git`, or `https://github.com/devrev/<repo>.git`.
Match the host and owner exactly, case-insensitively; do not infer ownership from the local path or a substring in a different host or owner.
If multiple remotes make the intended workflow ambiguous, ask which remote is being used.

Prefer conversation context when drafting names and messages.
If staged and unstaged changes coexist, commit staged changes only unless the user explicitly requests otherwise.
Include only changes relevant to the requested commit; never stage unrelated work.
If there are no changes, stop and say so.

## Branch and issue

For DevRev work on `main`, create `erazemk/<1-4-short-words>` in lowercase kebab-case, without an issue ID.
Require an exact DevRev issue URL from the user or established conversation context; ask for it if missing or ambiguous.

For personal repositories, work directly on `main`; do not create a feature branch for this workflow.
If already on another branch, ask before switching or transferring changes.
Do not require or include a DevRev issue URL in personal commit messages.
Do not push merely because a commit was requested.

## Message

A follow-up commit means a DevRev branch with an open PR matching the intended GitHub repository and head branch, not merely a pushed branch or a historical PR.
Check PR state through `gh` with an explicit target repository when needed.
If the matching PR is closed or merged, resolve whether to start new work with the user before committing.

For an initial DevRev commit or a personal commit:

- Use `<prefix>: <Short imperative sentence, first letter capitalized>` with `fix`, `feat`, `chore`, `docs`, or `ci`; no trailing period.
- Describe what behavior changed, not which code constructs were modified; never mention specific function names, variable names, type names, error names, or file paths in the commit body.
- Add a short explanatory paragraph only when needed; start it with `This commit ...`, use present tense, and avoid personal pronouns and vague referents.
- Keep each body paragraph on one line.
- For DevRev, end the body with the exact issue URL; simple commits need only that URL as the body.
- For personal repositories, omit the issue URL; simple commits can have no body.
- Show the proposed title and body and obtain user approval before committing.

For a follow-up DevRev commit with an existing PR, use a short summary title and skip message approval.
Do not push it automatically; ask whether to push after committing.
Never squash, rebase, amend, or force-push merely to tidy DevRev branch history; those commits are squashed on merge.

After committing, report the title, body if present, hash, branch, committed scope, and any hook-generated changes.
If a hook changes files, inspect them and preserve unrelated work before retrying; do not amend automatically.
If relevant code changes during hooks, rerun required verification against the actual committed snapshot before publishing.
