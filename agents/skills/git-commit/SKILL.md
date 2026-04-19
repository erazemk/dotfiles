---
name: git-commit
description: Create a git commit following DevRev commit conventions
---

### Input

The user may provide:
- A DevRev issue ID (e.g. `ISS-289180`) - required; if it is missing, ask before committing
- A description of what changed - optional; if not given, infer from the diff

### Steps

1. Run `git status --short` (never use `-uall`) and `git diff --staged` in parallel to inspect what is already staged.
2. If nothing is staged, run `git diff` as well so you understand what would be added before staging it.
3. If there are no staged or unstaged changes, tell the user and stop.
4. If nothing is staged, stage everything with `git add -A`, except files that likely contain secrets such as `.env`, `*.pem`, or `credentials*.json`. If some files are staged and others are not, commit only the staged files and do not stage the unstaged ones.
5. Draft the commit message following the format below. Infer the change summary from the diff if the user did not provide one, but never invent the DevRev issue ID.
6. Show the full commit message to the user and wait for approval before committing. If a question tool is available, offer three outcomes: approve the commit, edit the message, or cancel. If the user asks for changes, apply them and ask again until approved.
7. Create the commit using a HEREDOC for the message.
8. If `git commit` fails because a hook reformats or updates files, inspect the new diff, stage the hook-generated changes, and create a new commit with the approved message. If the commit fails for any other reason, surface the error and stop.
9. After a successful commit, show the new commit hash and a short `git status` summary.

### Commit message format

**Title line:** `<prefix>: <Short sentence, first letter capitalised>`

- Allowed prefixes: `fix`, `feat`, `chore`, `docs`
- Use `chore` for refactors or maintenance changes that do not fit the other prefixes
- Imperative voice: `Add`, `Fix`, `Update` - not `Added`, `Fixed`, `Updated`
- No trailing period
- Example: `feat: Track unresolved references`

**Body** (blank line after title, always ends with a DevRev issue link):

- **Simple commits** (dependency updates, vulnerability fixes, trivial changes): body = issue link only
- **Complex commits**: one or more short explanatory paragraphs followed by the issue link
- **No line wrapping** - each paragraph is a single long line; separate paragraphs with empty lines
- **Backtick-wrap** all code identifiers: function names, field names, type names, file paths
- Issue link format: `https://app.devrev.ai/devrev/works/ISS-XXXXXX`
- Never omit the issue link

### Commit description style

- **Opening sentence**: always `This commit [verb]s...`
  - Feature: `This commit adds (support for) ...`
  - Bug fix: `This commit fixes a bug where ...` / `This commit fixes an issue with ...`
  - Chore/refactor: `This commit updates/removes/enables/disables ...`
- **Subsequent references**: use `The commit ...` or `It also ...` (not `This commit` again)
- Present tense throughout
- Use `we` for shared team context: `we forgot to`, `we previously didn't`
- Connector phrases: `This is needed because ...`, `Previously ...`, `The commit fixes this by ...`, `For now ...`, `Due to ...`

### Example - simple commit

```
chore: Upgrade `go.opentelemetry.io/otel` to `v1.43.0`

https://app.devrev.ai/devrev/works/ISS-290000
```

### Example - complex commit

```
fix: Retry transient gRPC extractor calls

This commit fixes an issue with extractor gRPC calls failing on transient transport errors. Previously, a single `Unavailable` or `DeadlineExceeded` response would cause the entire sync unit to fail.

The commit wraps each extractor gRPC client call in `util.RetryWithBackoff`, which retries `Unavailable` and `DeadlineExceeded` status codes up to 3 times.

https://app.devrev.ai/devrev/works/ISS-289180
```
