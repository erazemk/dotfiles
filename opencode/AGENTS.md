# General
- My name is Erazem and I work at DevRev as a backend engineer.
- Keep your responses to me (the user) as concise as possible.
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When writing code in any project in the `~/DevRev` subdirectory, always read `~/DevRev/airdrop-devrev-loader/docs/code-style.md` first.
- Go module cache is stored in `~/.local/share/go/pkg/mod`, not `~/go/pkg/mod`.
- List directories always relative to the current working directory or `/Users/erazemk`, never just `/`.
- When running individual Go tests, always use at most a 30 second timeout.

# Agents
- Use the built-in `explore` subagent for codebase exploration, broad file searches, symbol searches, and questions about where or how something works.
- Use the built-in `general` subagent for text-intensive work, especially commands expected to produce long output (`make` commands), noisy test runs, build logs, or large pasted output.
- Always use a subagent to run individual Go tests or `make` commands.
- When delegating command execution to `general`, pass the exact command, working directory, success criteria, and the format of the summary you want back.
- Prefer reading the compact summary returned by `general` instead of pulling long raw command output into the parent context.
- Prefer doing coding tasks yourself, not delegating them to subagents.
- When calling subagents, pass paths to any relevant documentation to them so that they read it (e.g. `code-style.md`).
