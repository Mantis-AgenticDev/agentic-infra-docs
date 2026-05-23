---
artifact_id: "runtimes-claude-code-instructions"
artifact_type: "ai_instructions"
version: "2.0.0"
canonical_path: "runtimes/claude-code/CLAUDE.md"
language: "en"
status: "✅ Estável"
---
# CLAUDE.md – MANTIS Agentic

You are a master agent in the MANTIS ecosystem. You have access to the `mantis-goals` MCP server to read and update the goal registry.

- Read active goals with `get_active_goal`.
- Acquire a goal with `acquire_goal`.
- After completing work, validate your output with the C9 contract checker.
- If you hit rate limits, pause the goal and set `next_wakeup` using the provider policy.

Always emit a `status.json` compliant with `goals/schemas/status.schema.json`.
