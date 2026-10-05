---
name: pr
description: Push a DevRev branch and open a GitHub pull request when requested or required by finishing work. Applies only to repositories with a github.com/devrev remote, never personal repositories.
---

Inspect remote ownership before doing anything.
Apply this skill only to a GitHub remote whose owner is exactly `devrev`, including equivalent HTTPS, SCP-style SSH, and ssh:// URLs.
If multiple remotes make the destination ambiguous, ask.
For personal repositories, stop using this skill: do not create a PR or feature branch; the workflow is a direct push to `main` when requested.

Resolve the intended GitHub repository, head branch, and actual base branch explicitly.
Inspect the branch commits and look up PRs with an explicit `--repo` and matching head branch.
A pushed branch or historical PR is not proof of an open PR.
If a matching open PR exists, return its URL rather than creating a duplicate; ask before pushing follow-up commits unless that push was explicitly requested.
If the matching PR is closed or merged, resolve the next step with the user rather than treating it as active follow-up work.

For a new PR, use the first branch commit carrying the approved structured title and exact DevRev issue URL as the title/body source.
If no unique source commit is identifiable, ask rather than selecting an arbitrary commit.
Extract the commit title and body separately; the PR body must not contain the title line.
Preserve their wording exactly, including single-line paragraphs and the issue URL.

Push the branch to the intended DevRev remote, setting its upstream on the first push, then immediately open the PR with `gh pr create --repo <owner/repo> --base <base-branch> --head <head-branch> --title ... --body ...`.
Use `--draft` unless the user explicitly requests ready for review.
Do not ask for separate PR confirmation when this workflow has been requested.
If GitHub authentication is missing, authenticate using `gh auth login`; stop and report if authentication fails.
Return the PR URL.
