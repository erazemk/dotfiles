---
name: open-pull-request
description: Open a GitHub pull request following DevRev conventions. Run after using the create-git-commit skill.
---

## PR

Open a GitHub pull request using DevRev's PR conventions. This skill should be run after the changes have been committed (e.g. after using `/create-git-commit`).

### Steps

1. Run `git log main..HEAD --oneline` and `git status` (never use `-uall`) in parallel to see all commits on the branch that differ from main.
2. Determine the PR title and body from the commits:
   - Use the **first** commit that differs from main (oldest on the branch) for the title and description.
   - **PR title** = that commit's title (the `prefix: Sentence` line)
   - **PR body** = that commit's description exactly (everything after the blank line — paragraphs + issue link). No test plan, no extra sections.
3. Show the user the PR title and body, and ask for approval before creating it. If a question tool is available, present the PR details in the question text and offer these options:
   - "Yes" — create the PR
   - "Yes (as draft)" — create the PR as a draft
   - "No" — exit without creating a PR
   - "Do something else" — the user types what to change
   If the user asks for changes, apply them and ask again until approved. If the user says no, stop.
4. Push the branch if it hasn't been pushed yet (`git push -u origin HEAD`).
5. Create the PR with `gh pr create --title "..." --body "..."`. Add `--draft` only if the user chose "Yes (as draft)".
6. Print the PR URL.
