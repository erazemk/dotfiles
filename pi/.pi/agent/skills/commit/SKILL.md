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
Require an exact DevRev issue URL from the user or established conversation context, including an issue created with approval through the devrev skill.
Within the finish workflow, use the devrev skill to resolve or create the issue; for standalone commits, ask for the URL if missing or ambiguous.

For personal repositories, work directly on `main`; do not create a feature branch for this workflow.
If already on another branch, ask before switching or transferring changes.
Do not require or include a DevRev issue URL in personal commit messages.
Do not push merely because a commit was requested.

## Message

A follow-up commit means a DevRev branch with an open PR matching the intended GitHub repository and head branch, not merely a pushed branch or a historical PR.
Check PR state through `gh` with an explicit target repository when needed.
If the matching PR is closed or merged, resolve whether to start new work with the user before committing.

For an initial DevRev commit or a personal commit, use these rules when drafting a message:

- Use `<prefix>: <Short imperative sentence, first letter capitalized>` with `fix`, `feat`, `chore`, `docs`, or `ci`; no trailing period.
- Describe what behavior changed, not which code constructs were modified; never mention specific function names, variable names, type names, error names, or file paths in the commit body.
- Add a short explanatory paragraph only when needed; start it with `This commit ...`, use present tense, and avoid personal pronouns and vague referents.
- Keep each body paragraph on one line.
- For DevRev, end the body with the exact issue URL; simple commits need only that URL as the body.
- For personal repositories, omit the issue URL; simple commits can have no body.
- Show the proposed title and body and obtain user approval before committing.

Accept a user-written title and body instead of drafting them.
For an initial DevRev commit, show the complete final message, including the exact issue URL, and obtain approval before committing.
Follow-up commits on a matching open PR do not require message approval or an issue URL in the body.
If the user rewrites either field, preserve their final wording exactly; do not silently reformat, capitalize, paraphrase, or add text.
Resolve missing issue URLs or conflicts with message conventions explicitly before approval; an explicit user override governs their wording.
Use a message file with `git -c commit.cleanup=verbatim commit -F <message-file>` so Git does not strip approved content.
Read the actual commit title/body back after hooks; if either differs from the intended message, stop publication and ask rather than silently amending or publishing changed wording.
Use `git cat-file commit <hash>` to inspect the stored message without pretty-format extra newlines; separate the first line from the body at the first blank line.

For a follow-up DevRev commit with a matching open PR, use a short summary title; no body or issue URL is required, and no message approval is needed before committing.
Pushing still requires explicit user approval; a request to commit and push supplies that approval, but a request only to commit does not.
Ask whether to push after committing if approval to push has not already been given.
During the finish workflow for an initial DevRev commit, state before message approval that approval also authorizes pushing and PR publication; after approval do not ask again unless the scope or destination changes.
During the finish workflow for a follow-up commit, do not request message approval, but obtain explicit approval to push unless the user has already requested publication.
Never squash, rebase, amend, or force-push merely to tidy DevRev branch history; those commits are squashed on merge.

After committing, report the title, body if present, hash, branch, committed scope, and any hook-generated changes.
If a hook changes files, inspect them and preserve unrelated work before retrying; do not amend automatically.
If relevant code changes during hooks, rerun required verification against the actual committed snapshot before publishing.
