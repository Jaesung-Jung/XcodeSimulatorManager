---
name: session-context-restore
description: "Explicitly restore saved agent session context, handoff, checkpoint, or previous workstream state from .agent-state. Use only when the user explicitly asks to restore context, resume from handoff, continue saved work, inspect previous session state, or invokes session-context-restore/context-restore. Do not trigger automatically for ordinary requests."
---

# Session Context Restore

Restore saved work context from `.agent-state/` so the current or next agent can continue with the right workstream context.

This skill is read-oriented. Do not modify product code, app configuration, project documentation, or session state unless the user explicitly asks for a follow-up save.

Read `references/state-schema.md` when you need exact file formats.

## Restore Flow

1. Read root `.agent-state/handoff.md`.
   - If it does not exist, say there is no saved session context yet.

2. Select the workstream.
   - If the user names a workstream, use that workstream.
   - If the user says only "restore" or "continue", use `active_workstream`.
   - If the user asks for a closed workstream, read only that closed workstream's handoff.
   - If multiple workstreams match, ask which one to restore.

3. Read `.agent-state/workstreams/{workstream-slug}/handoff.md`.

4. Read the latest checkpoint only when the handoff is missing important detail or the user asks for full saved context.
   - Latest checkpoint ordering uses the `YYYYMMDD-HHMMSS` filename prefix.
   - Do not read every checkpoint.

5. If the current git branch differs from the branch recorded in the handoff, tell the user before continuing.

6. Present a compact restore summary:
   - workstream slug
   - status
   - saved branch
   - latest checkpoint path
   - goal
   - completed work
   - remaining work
   - next-agent first action
   - cautions or blockers

7. If the user asked only to restore context, stop after the summary.

8. If the user explicitly asked to restore and continue implementation, continue from the next-agent first action after presenting the restored context.

## Context Isolation

- Do not read closed workstream handoffs unless the user explicitly names that workstream or the active handoff points to it.
- Do not merge multiple workstreams into the active context by default.
- Do not treat old checkpoints as current truth when a newer handoff exists.

## Output

Keep the response short and concrete. State exactly which workstream was restored and what the next action is.
