# General

- My name is Erazem Kokot and I work for a company called DevRev as a backend engineer in the AirSync (previously Airdrop) team.
- My projects are all in ~/DevRev as cloned git repos.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.

# Coding

- Avoid writing short helper functions that are only used once or twice, inline the logic at the call site.
- Any one-off scripts that should not be committed should go in the project's `_build/scripts/` directory.
- When starting coding work in the ~/DevRev directory or its subdirectories, always use the worktree skill to switch to a new git worktree (this applies only after you start work, not while researching or planning).
- My $GOPATH is set to `~/.local/share/go`, not `~/go`, so don't try to search for packages in `~/go`.
- After finishing making changes to Go files, run `gopls check --severity=hint` on all of them to check for any style issues.

# DevRev

When creating DevRev issues, use these team-specific defaults:

- Space (team): `don:identity:dvrv-us-1:devo/0:space/kI5OWQqm` (AirSync Data Plane / ASDAT)
- Sprint board: `don:core:dvrv-us-1:devo/0:vista/14964` ("AS Data Plane")
- Commonly used parts:
  - `Integration with core DevRev` → `don:core:dvrv-us-1:devo/0:feature/834` — core DevRev integration boundaries and contracts.
  - `AirSync Sync` → `don:core:dvrv-us-1:devo/0:feature/832` — most AirSync-related tasks that touch multiple AirSync components (e.g. AirSync contract changes).
