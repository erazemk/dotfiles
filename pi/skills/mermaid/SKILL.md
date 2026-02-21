---
name: mermaid
description: "Use when creating mermaid markdown diagrams or writing markdown files with inline mermaid markdown"
---

# Mermaid Skill

Validate Mermaid diagram syntax. Supports all diagram types (flowchart, sequence, class, state, ER, gantt, pie, git graph, etc.).

## Usage

### Validate a diagram

```bash
./scripts/validate.ts <file.mmd|file.md>
```

- **Markdown files** (`.md`, `.mdx`, `.markdown`): extracts all `` ```mermaid `` blocks and validates each one, reporting errors by block number and line.
- **Plain mermaid files** (`.mmd` or any other extension): validates the entire file as a single diagram.
- Non-zero exit = at least one block failed validation.

## Notes

1. Write or update the Mermaid diagram directly in the Markdown file.
2. Run `./scripts/validate.ts document.md`.
3. Fix any errors reported by the parser (errors include block number and line number).
4. Repeat until all blocks pass.
