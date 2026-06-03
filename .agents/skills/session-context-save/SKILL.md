---
name: session-context-save
description: "Explicitly save the current agent session context, progress, decisions, handoff, and workstream state into .agent-state. Use only when the user explicitly asks to save session context, save progress, write handoff, checkpoint, record progress, or invokes session-context-save/context-save. Do not trigger automatically for ordinary long-running work."
---

# Session Context Save

Save the current work context into repo-local agent state so a future agent can restore it later with `session-context-restore`.

This skill writes only session state under `.agent-state/`. Do not modify product code, app configuration, project documentation, or unrelated files as part of this skill.

Read `references/state-schema.md` when you need exact file formats.

## Save Flow

1. Gather the current git state:

```zsh
git branch --show-current
git status --short
git diff --stat
git diff --cached --stat
git log --oneline -10
```

2. Determine the workstream slug.
   - Use an explicit user-provided feature/task name if present.
   - Otherwise use the active workstream from `.agent-state/handoff.md` when the request is clearly continuing it.
   - Otherwise infer a short kebab-case English slug from the current goal or branch name.
   - If the save target is ambiguous, ask before writing state.

3. Create these directories if needed:

```text
.agent-state/
.agent-state/workstreams/{workstream-slug}/
.agent-state/workstreams/{workstream-slug}/checkpoints/
```

4. Append a concise progress entry to `.agent-state/workstreams/{workstream-slug}/current.md`.

5. Create a new checkpoint file:

```text
.agent-state/workstreams/{workstream-slug}/checkpoints/YYYYMMDD-HHMMSS-title.md
```

6. Update `.agent-state/workstreams/{workstream-slug}/handoff.md` with the latest goal, completed work, decisions, remaining work, changed files, verification, and next-agent first action.

7. Update root `.agent-state/handoff.md` as an index only:
   - active workstream pointer
   - active status
   - closed workstream pointers

8. Append one event to `.agent-state/timeline.jsonl`.

9. If you discovered a durable project learning that will save future agents time, append it to `.agent-state/learnings.jsonl`. Do not log secrets, credentials, personal data, one-time command output, or stale guesses.

## Completion Handling

If the user says the workstream is complete:

- Set the workstream handoff `Status` to `completed`.
- Move the workstream pointer into `closed_workstreams` in root `.agent-state/handoff.md`.
- Do not delete the workstream directory or checkpoints.

## Output

After saving, report:

- workstream slug
- checkpoint path
- handoff path
- number of modified files found from `git status --short`
- any ambiguity or missing verification

Keep the response short.
