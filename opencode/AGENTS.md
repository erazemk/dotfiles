- My name is Erazem and I work at DevRev as a backend engineer.
- Keep your responses to me (the user) as concise as possible.

# General
- When writing markdown, put each sentence in its own line, do not split lines unnecessarily.
- When writing code in any project in the ~/DevRev subdirectory, always read ~/DevRev/airdrop-devrev-loader/docs/code-style.md first.
- Go module cache is stored in ~/.local/share/go/pkg/mod, not ~/go/pkg/mod
- When accessing directories, check first if they are within the current working directory. Only if they are not you can access them relative to /.

# Agents
- Use the built-in `explore` subagent for codebase exploration, broad file searches, symbol searches, and questions about where or how something works.
- Do not manually perform multi-step exploration in the parent agent when `explore` can do it faster and keep the main context cleaner.
- Use the built-in `general` subagent for text-intensive work, especially commands expected to produce long output (`make` commands), noisy test runs, build logs, or large pasted output.
- When delegating command execution to `general`, pass the exact command, working directory, success criteria, and the format of the summary you want back.
- Prefer reading the compact summary returned by `general` instead of pulling long raw command output into the parent context.
- Do not use the `general` subagent for coding tasks, do that yourself.
- When calling subagents, pass paths to any relevant documentation to them so that they read it (e.g. `code-style.md`)
