# General

- My name is Erazem Kokot and I work for a company called DevRev as a backend engineer in the AirSync (previously Airdrop) team.
- My projects are all in ~/DevRev as cloned git repos.
- When investigating in another repo, if that repo is on its main branch, pull the latest commits first so the investigation runs against the current version of that service.
- When asked to plan or design an approach before writing code, use the `plan` skill.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When a task list exists, work through tasks sequentially.

# Coding

- Avoid writing short helper functions that are only used once or twice — inline the logic at the call site instead.
- LSP-resolve callsites for a function only when that function's task is the active one — do not pre-read all callsites upfront across multiple tasks.
- For bulk mechanical renames in Go files, use the `Edit` tool with `replace_all: true` per file — do not use shell `sed -i` or `find -exec sed`.

# Claude configuration

- My Claude agents, hooks, settings, the global CLAUDE.md, and global skills are symlinked from `~/.config/dotfiles/work/claude` into `~/.claude`. Edit the real files under `~/.config/dotfiles/work/claude` — writing through the `~/.claude` symlink fails.
- Plugin skills (including `commit`, `pr`, `finish`, etc.) live in `~/DevRev/airsync-claude-plugins/plugins/core/skills/`. Edit them there directly.
- When updating a skill, agent, or hook, search both `~/.config/dotfiles/work/claude` and `~/DevRev/airsync-claude-plugins/plugins/core` to find the right file.
- When modifying skills, documentation, or similar prose, correct wrong assumptions in place — edit or remove the incorrect text rather than appending a note saying not to do the previous thing.

# Scripts and one-off tools

- Any one-off, testing, or debugging scripts that should not be committed to the repo go in the project's `_build/scripts/` directory (if `_build/` already exists in the project root — it is gitignored by convention).

# Git discipline

- When starting coding work on a new feature in the ~/DevRev directory or its subdirectories, always use the worktree skill to switch to a new git worktree.
- Never run `git stash` to investigate whether a test failure is pre-existing.
- Read the diff and reason from the code changes instead.
- When you apply a fix in response to a PR reviewer's comment, do not post a reply comment on that reviewer's comment thread.
- Only resolve a review thread when I explicitly ask (see the `pr` skill's "Resolving review conversations" section), and never add a new comment there.

# LSP tool

Prefer the LSP tool over Read/Grep/Glob in these cases, since it resolves symbols semantically instead of matching text:
- Finding all callers of a function before renaming, changing its signature, or deleting it (`findReferences`/`incomingCalls`).
- Understanding a function's call graph / blast radius (`incomingCalls`, `outgoingCalls`).
- Finding all concrete implementations of an interface (`goToImplementation`).
- Jumping to a symbol's actual definition across files or packages, including through imports/aliases (`goToDefinition`).
- Disambiguating same-named symbols in different scopes or types (e.g. multiple `Validate()` methods).
- Getting a quick outline of a file's functions/types/methods before deciding what to read in full (`documentSymbol`).
- Locating a symbol by name across the whole workspace when the file is unknown (`workspaceSymbol`).
- Checking a symbol's resolved type/doc without opening its defining file (`hover`).
- Verifying a rename/refactor is complete and didn't miss usages behind interfaces (`findReferences`).
- Investigating usages of a symbol across repos, following the real import graph rather than guessing which repo to grep.

# DevRev issue creation defaults

When creating issues for the current work, use these team-specific defaults:
- Space (team): `don:identity:dvrv-us-1:devo/0:space/kI5OWQqm` (AirSync Data Plane / ASDAT)
- Sprint board: `don:core:dvrv-us-1:devo/0:vista/14964` ("AS Data Plane")
- Commonly used parts:
  - `Integration with core DevRev` → `don:core:dvrv-us-1:devo/0:feature/834` — core DevRev integration boundaries and contracts.
  - `AirSync Platform` → `don:core:dvrv-us-1:devo/0:capability/5` — shared libraries, generic loader maintenance, dependency updates, repo-wide cleanup, generic AirSync/Airdrop platform work.
  - `AirSync Sync` → `don:core:dvrv-us-1:devo/0:feature/832` — sync behavior and lifecycle changes.
