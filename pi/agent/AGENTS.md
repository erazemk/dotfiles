# General
- Do not delete any files or folders without explicit user permission.
- If deletion is approved, use `trash` to remove files instead of `rm`.
- Do not automatically start work unless the user explicitly asks. This includes things like asking how you would do something - respond but don't make any code changes until the user says to do so.
- Only install Python/pip packages in a virtual environment (`python3 -m venv .venv`), never in the global or user scope

# Web search
- Use web search when researching new general topics.
- Use web fetch if user passed a URL, or if needing to get more context from web search.
- You can also use `curl` through the bash command for fetching websites if needing to fetch raw data.

# Git
- Use `gh pr view/diff` to review PRs.
- Some DevRev repos are cloned to ~/DevRev, you can use those during DevRev-related research.
- Git commit and push only when explicitly asked.
- Destructive git actions forbidden unless explicitly asked by the user to do them (`reset --hard`, `clean`, `restore`, `rm`, etc.).
- Only switch git branches if asked by the user.

## Go toolchain and syntax
- Go version is defined by `go.mod` / `go.work`. Treat it as the source of truth for valid language features.
- If code compiles/tests pass under the repo’s Go toolchain, do not “fix” unfamiliar syntax; flag uncertainty and verify with `go vet` or the compiler.
- Go 1.26 language changes to be aware of: `new(expr)` is valid and generic types may reference themselves in their own type parameter list.
- Avoid “cleanup” edits based on assumed syntax rules, the compiler will warn about any actual issues.
