# Session Context State Schema

## Directory Layout

```text
.agent-state/
├── handoff.md
├── timeline.jsonl
├── learnings.jsonl
└── workstreams/
    └── {workstream-slug}/
        ├── handoff.md
        ├── current.md
        └── checkpoints/
            └── YYYYMMDD-HHMMSS-title.md
```

## Root Handoff

Path: `.agent-state/handoff.md`

Purpose: index only. Read this first, then follow the active or requested workstream pointer.

```markdown
# Active Handoff

active_workstream: {workstream-slug}
status: {in-progress|paused|completed}
handoff: .agent-state/workstreams/{workstream-slug}/handoff.md
updated_at: {ISO-8601 timestamp}

closed_workstreams:
- {slug}: {completed|paused}, see .agent-state/workstreams/{slug}/handoff.md
```

## Workstream Handoff

Path: `.agent-state/workstreams/{workstream-slug}/handoff.md`

Primary restore source.

Important fields:
- `Status`
- `Branch`
- `Updated`
- `Latest checkpoint`
- `Goal`
- `Completed`
- `Current State`
- `Decisions`
- `Remaining Work`
- `Changed Files`
- `Verification`
- `Next Agent First Action`
- `Notes`

## Checkpoints

Path: `.agent-state/workstreams/{workstream-slug}/checkpoints/YYYYMMDD-HHMMSS-title.md`

Use only when the handoff is missing detail or the user asks for full context. Latest ordering is based on the filename timestamp prefix, not filesystem mtime.

## Timeline

Path: `.agent-state/timeline.jsonl`

Use only when the user asks for history or when the handoff is insufficient to determine recent activity. Do not load the full timeline by default.

## Learnings

Path: `.agent-state/learnings.jsonl`

Use only when durable project knowledge is relevant to the restore request. Do not load all learnings by default.
