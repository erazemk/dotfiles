---
name: add-pi-mcp-server
description: Add an MCP server to Pi through pi-mcp-adapter when the user provides MCP setup details in any format, including prose, copied docs, or configs from other clients like Claude Code, Codex, Cursor, or VS Code. Parse the server details, ask only for missing information, inspect the server with npx mcporter list, ask which tools to expose, and write Pi-compatible ~/.pi/agent/mcp.json using directTools only.
---

# Add Pi MCP Server

Use this skill when the user wants to add an MCP server to Pi through `pi-mcp-adapter`.

## Goal

Convert whatever MCP information the user has into a `pi-mcp-adapter` config entry, inspect the server with `npx mcporter list`, ask which tools to expose, and write Pi MCP config with `directTools`.

This workflow is direct-tools-first:
- For a selected subset of tools, configure `directTools: ["..."]`
- If the user wants all tools exposed directly, configure `directTools: true`
- Never rely on proxy-only mode in your workflow

Important: `pi-mcp-adapter` still registers a generic `mcp` tool internally. You are not removing it. You are configuring the server so the intended workflow uses direct tools only.

## Output Location

Always write user-global Pi MCP config at: `~/.pi/agent/mcp.json`

## Pi MCP Config Shape

For this skill, write config in one of these shapes:

Subset of tools:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "some-mcp-server"],
      "lifecycle": "keep-alive",
      "directTools": ["tool_a", "tool_b"]
    }
  }
}
```

All current and future tools from the server:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "some-mcp-server"],
      "lifecycle": "keep-alive",
      "directTools": true
    }
  }
}
```

Supported server fields:

### Stdio transport
- `command`
- `args`
- `env`
- `cwd`
- `lifecycle` with value `"keep-alive"`
- `directTools`

Example:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"],
      "env": {
        "FOO": "bar"
      },
      "cwd": "/path/to/project",
      "lifecycle": "keep-alive",
      "directTools": ["take_screenshot"]
    }
  }
}
```

### Remote transport
- `url`
- optional `headers`
- optional `auth: "bearer" | "oauth"`
- optional `bearerToken`
- optional `bearerTokenEnv`
- `lifecycle` with value `"keep-alive"`
- `directTools`

The adapter uses Streamable HTTP first and falls back to SSE automatically. You usually do not need to preserve a source config's `type: "http"` vs `type: "sse"` distinction.

Example with bearer env var:

```json
{
  "mcpServers": {
    "render": {
      "url": "https://mcp.render.com/mcp",
      "auth": "bearer",
      "bearerTokenEnv": "RENDER_API_KEY",
      "lifecycle": "keep-alive",
      "directTools": ["list_services"]
    }
  }
}
```

Example with explicit headers:

```json
{
  "mcpServers": {
    "custom-api": {
      "url": "https://example.com/mcp",
      "headers": {
        "X-API-Key": "${CUSTOM_API_KEY}",
        "X-Tenant": "acme"
      },
      "lifecycle": "keep-alive",
      "directTools": ["search_docs"]
    }
  }
}
```

## Procedure

1. Parse the user input first.
2. Extract as much as possible from unstructured prose, pasted JSON, copied docs, or examples from other MCP clients.
3. Only ask the user for fields that are still missing or ambiguous.
4. Probe the MCP server with `npx -y mcporter list` to discover the actual tool names.
5. Ask the user whether they want a selected subset of tools or all tools exposed in Pi.
6. Write or update Pi MCP config with either a `directTools` array or `directTools: true`, depending on that choice.
7. Tell the user if Pi restart is required for the direct tools to appear.

## What To Extract

Try to infer these fields from the user's input before asking questions:
- `server name`
- transport type:
  - stdio server: `command`, `args`, optional `env`, optional `cwd`
  - remote server: `url`, optional `headers`, optional auth mode
- auth details:
  - bearer token literal
  - bearer token env var name
  - OAuth requirement
- any user preference about naming or auth handling that affects the global config
- naming or prefix preference if relevant

Accept input copied from common MCP formats, including:
- `mcpServers` JSON blocks
- Claude Code or Claude Desktop examples
- Cursor, VS Code, Windsurf, or Codex style config
- prose instructions such as "run `npx ...` with these env vars"

### Mapping From Common Input Formats

If the user gives you Claude, Cursor, Codex, or similar JSON, keep these fields when present:
- `command`
- `args`
- `env`
- `cwd`
- `url`
- `headers`

Then:
- set `lifecycle: "keep-alive"` always
- if the user wants a subset, use an explicit `directTools` list
- if the user wants all tools exposed directly, use `directTools: true`

For prose instructions such as:
- `Run npx -y foo-mcp --token $TOKEN`
- `Use https://api.example.com/mcp with bearer auth`
- `Set API_KEY and start uvx bar-mcp`

Extract:
- binary or URL
- argument list
- env vars vs literal args
- auth style

Prefer env vars in config when the source material already uses env vars.

## When To Ask The User

Ask focused follow-up questions only when one of these is missing or ambiguous:
- server name
- command or URL
- args for stdio transport
- required env vars or headers
- whether auth is bearer vs OAuth
- which tools to expose
- any naming or auth detail still needed for the global config
- tool prefix preference if collisions are possible

Do not ask the user for information already present in their pasted config or docs.

## Probe With MCPorter

Always inspect the server with `npx -y mcporter list` before finalizing `directTools`, unless the server cannot be reached yet and the missing reason is already known.

Use ad hoc MCPorter invocation, not a local installation.

### Stdio probe

```bash
npx -y mcporter list --json --stdio "<command> <args...>" --name <server-name>
```

Optional flags:
- `--env KEY=value`
- `--cwd <path>`

Quote the full stdio command carefully so the original command and arguments survive intact.

### Remote probe

```bash
npx -y mcporter list --json --http-url <url> --name <server-name>
```

Add supporting values only when needed for probing.

If MCPorter fails, summarize the real failure and decide whether you already know enough to write config anyway. Typical examples:
- missing API key
- OAuth required
- service unreachable
- invalid command

If the server cannot be probed because user credentials are missing, ask only for the missing credential source or proceed with config-writing if the user wants setup completed first.

Use MCPorter for discovery even if you already know the expected tools from docs. The point is to verify the actual exposed tool names before writing `directTools`.

## Tool Selection

After probing, present the discovered tool names to the user and ask whether they want:
- a selected subset of tools exposed directly
- all tools exposed directly

Default behavior:
- if the user selects a subset, store exactly those original MCP tool names in `directTools`
- if the user wants all tools exposed directly, set `directTools: true`
- when using an array, keep the list as original MCP tool names, not Pi-prefixed names

If the server exposes resources as tools and the user wants them, include those names too.

Use `directTools: true` when the user explicitly wants all tools exposed directly so newly added tools from that MCP server are also exposed automatically in future sessions.

## Writing Pi Config

Write Pi-compatible config only after you know the selected direct tools.

Core rules:
- Always write `~/.pi/agent/mcp.json`
- Merge with existing config instead of overwriting unrelated servers
- Preserve existing settings unless the new server requires a change
- For a selected subset, set `directTools` per server as a string array
- If the user wants all tools exposed directly, set `directTools: true`
- Always set `lifecycle: "keep-alive"`

### Prefix choice

Pi tool names are derived from adapter settings, not from `directTools` values.

If `directTools` is an array, it must contain original MCP tool names, not prefixed Pi tool names.

Use this rule:
- if selected tool names do not collide with built-in tools or existing direct tools, `toolPrefix: "none"` is acceptable
- otherwise prefer `toolPrefix: "short"` or `"server"`

If there is a naming tradeoff, ask the user instead of guessing.

## After Writing Config

If the adapter is not installed yet, tell the user to install it:

```bash
pi install npm:pi-mcp-adapter
```

## Constraints

- Do not invent MCP fields the user did not provide.
- Do not assume proxy-mode workflow.
- Do not claim the generic `mcp` tool is removed; it is still part of the adapter.
- Use a small explicit `directTools` allowlist by default.
- Use `directTools: true` only when the user explicitly wants all current and future tools from that server exposed directly.
- If the user supplied docs or a URL, use them directly and extract the config details yourself before asking questions.
- Always place the resulting MCP server definition in `~/.pi/agent/mcp.json`.
