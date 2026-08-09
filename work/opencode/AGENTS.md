# General

- My name is Erazem Kokot and I work for a company called DevRev as a backend engineer in the AirSync (previously Airdrop) team.
- My projects are all in ~/DevRev as cloned git repos.

# External tool use

- When interacting with DevRev systems or verifying test outcomes for DevRev-related code (e.g. checking whether a work was created with the right fields), use `dr` first when it supports the required operation.
- If `dr` does not support the operation, use the `devrev` CLI when it supports the required operation.
- If neither CLI supports the required operation, explain the gap and ask whether to extend `dr` before using another approach.
- Interact with Datadog through the `pup` CLI tool. Always invoke it with `--agent`.
- When interacting with Slack, if using a subagent, use the general subagent, as explore subagents don't have access to the Slack MCP.

# Coding

- Any one-off scripts that should not be committed should go in the project's `_build/scripts/` directory (if the project is in the ~/DevRev directory).
- When starting coding work in the ~/DevRev directory or its subdirectories, use the worktree skill to switch to a new git worktree (this applies only after you start work, not while researching or planning), except if you'd be making changes to a gitignored file/directory, like locally testing, which only changes the gitignored `_build` directory.
- When working in a Go project and adding support for a new interaction with an external service (e.g. adding support for a new endpoint), you can clone the relevant service's Git repository to a temporary directory for inspection (e.g. to see what kind of validations the service does on the input you send it). For libraries you can just inspect the go module cache code instead.
