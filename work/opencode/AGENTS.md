# General

- Be direct and concise and get to the point.
- My name is Erazem Kokot and I work for a company called DevRev as a backend engineer in the AirSync (previously Airdrop) team.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When interacting with GitHub links (e.g. PR comments), use the GitHub CLI to fetch the data, as it usually requires authentication.

# DevRev

- My projects are all in ~/DevRev as cloned git repos.
- When interacting with DevRev systems or verifying test outcomes for DevRev-related code (e.g. checking whether a work was created with the right fields), use `dr` first when it supports the required operation.
- If `dr` does not support the operation, use the `devrev` CLI when it supports the required operation.
- If neither CLI supports the required operation, explain the gap and ask whether to extend `dr` before using another approach.

# Coding

- Avoid writing short helper functions that are only used once or twice, inline the logic at the call site.
- Any one-off scripts that should not be committed should go in the project's `_build/scripts/` directory (if the project is in the ~/DevRev directory).
- When starting coding work in the ~/DevRev directory or its subdirectories, use the worktree skill to switch to a new git worktree (this applies only after you start work, not while researching or planning), except if you'd be making changes to a gitignored file/directory, like locally testing, which only changes the gitignored `_build` directory.
- My $GOPATH is set to `~/.local/share/go`, not `~/go`, so don't try to search for packages in `~/go`.
- After finishing a run of code changes (e.g. before responding to the user), run `gopls check --severity=hint $(git diff --name-only -- '*.go')` to check for any linter issues.
