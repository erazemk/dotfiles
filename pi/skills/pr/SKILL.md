---
name: pr
description: "Open a GitHub PR using the last commit's title and description"
disable-model-invocation: true
---

Open a GitHub Pull Request from the current branch using the last commit's message.

## Steps

1. Ensure the current branch is not `main` or `master`. If it is, stop and tell the user.
2. Push the current branch to the remote: `git push -u origin HEAD`.
3. Extract the PR title and body from the last commit:
   - Title: `git log -1 --pretty=format:%s`
   - Body: `git log -1 --pretty=format:%b`
4. Check if the caller's arguments contain the word "draft" (case-insensitive). If so, add the `--draft` flag.
5. Open the PR with:
   ```bash
   gh pr create --title "<title>" --body "<body>" [--draft]
   ```
6. Print the PR URL from the output.

## Notes

- Do NOT modify the commit title or body — use them exactly as-is.
- If the arguments contain anything other than "draft", treat it as additional flags or instructions (e.g. reviewer names, labels).
- If `gh` is not installed or not authenticated, stop and tell the user.
