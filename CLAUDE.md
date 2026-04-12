# Claude Code Instructions

This file is read by Claude Code at startup. Use it to define how Claude should behave in your workspace.

Replace the contents below with your own instructions, or leave this file as-is to use the WAT framework pattern.

---

## WAT Framework (optional starting point)

WAT — **W**orkflows, **A**gents, **T**ools — is a pattern for structuring AI-assisted development:

- **Workflows** (`workflows/`) — Plain-language SOPs: what to do, which tools to call, how to handle edge cases
- **Agents** — Claude Code (this session). Reads workflows, runs tools, asks when unclear
- **Tools** (`tools/`) — Scripts that do the actual work deterministically (API calls, file ops, data transforms)

The separation matters: AI handles reasoning, scripts handle execution. A 5-step task where each step is 90% accurate succeeds 59% of the time end-to-end. Delegating execution to deterministic scripts keeps that number high.

### Operating Guidelines

1. **Check `tools/` before writing new code** — reuse what exists
2. **Read the relevant workflow before starting a task** — it defines the expected inputs, outputs, and edge cases
3. **Update workflows when you learn something new** — rate limits, better approaches, recurring issues
4. **Credentials go in `.env`** — never hardcoded, never committed

### Workspace Layout

```
projects/     # Your project directories
tools/        # Executable scripts
workflows/    # Markdown SOPs
.tmp/         # Scratch space (gitignored)
.env          # Secrets (gitignored)
```

Delete this file and write your own if the WAT pattern doesn't fit your workflow.
