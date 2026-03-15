---
name: pr
description: "Open a GitHub PR using the last commit's title and description"
disable-model-invocation: true
---

Open a GitHub Pull Request from the current branch using the last commit's message.

## Steps

1. Extract the PR title and body from the last commit:
   - Title: `git log -1 --pretty=format:%s`
   - Body: `git log -1 --pretty=format:%b`
2. Build the `gh pr create` command using those values.
3. If the caller's arguments contain the word "draft" (case-insensitive), add the `--draft` flag.
4. If the caller's arguments contain anything other than "draft", treat it as additional flags or instructions (e.g. reviewer names, labels) and append them to the command.
5. Run:
   ```bash
   gh pr create --title "<title>" --body "<body>" [--draft] <additional-args>
   ```
6. Print the PR URL from the output.

## Notes

- Do NOT modify the commit title or body — use them exactly as-is.
- Assume `gh` is installed, authenticated, and the branch is already pushed; do not run `git push` or `gh auth` checks.
