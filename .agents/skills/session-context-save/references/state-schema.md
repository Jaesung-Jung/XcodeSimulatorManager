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

`.agent-state/` is runtime state and must stay ignored by git.

## Root Handoff

Path: `.agent-state/handoff.md`

Purpose: index only.

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

```markdown
# Handoff: {workstream title}

Status: {in-progress|paused|completed}
Branch: {branch}
Updated: {ISO-8601 timestamp}
Latest checkpoint: .agent-state/workstreams/{slug}/checkpoints/{file}.md

## Goal
{Current goal in 1-3 sentences.}

## Completed
- {Completed item}

## Current State
- {Important current fact}

## Decisions
- {Decision and reason}

## Remaining Work
1. {Next concrete step}

## Changed Files
- `{path}`: {why it changed}

## Verification
- {Command or check}: {result}

## Next Agent First Action
{The first concrete action the next agent should take.}

## Notes
- {Gotchas, blockers, failed approaches, or user preferences}
```

## Current Log

Path: `.agent-state/workstreams/{workstream-slug}/current.md`

```markdown
# Current Log: {workstream title}

## {ISO-8601 timestamp}
- Request: {short user request summary}
- Action: {what changed or was investigated}
- Evidence: {commands, files, checks}
- Next: {next step}
```

## Checkpoint

Path: `.agent-state/workstreams/{workstream-slug}/checkpoints/YYYYMMDD-HHMMSS-title.md`

```markdown
---
status: in-progress
workstream: {workstream-slug}
branch: {branch}
timestamp: {ISO-8601 timestamp}
files_modified:
  - path/to/file1
---

## Working on: {title}

### Summary
{1-3 sentences describing current progress.}

### Decisions Made
- {Decision, tradeoff, and reason}

### Remaining Work
1. {Concrete next step}

### Notes
{Gotchas, blockers, open questions, or failed attempts}
```

## Timeline JSONL

Path: `.agent-state/timeline.jsonl`

```json
{"ts":"2026-04-27T12:00:00Z","workstream":"feature-b","event":"saved","branch":"main","summary":"Saved handoff after schema update"}
```

Allowed events: `started`, `progress`, `saved`, `restored`, `paused`, `completed`.

## Learnings JSONL

Path: `.agent-state/learnings.jsonl`

```json
{"ts":"2026-04-27T12:00:00Z","type":"operational","key":"make-dev-workspace","insight":"Use make dev before opening Readin.xcworkspace.","confidence":8,"source":"observed"}
```

Allowed `type`: `operational`, `architecture`, `testing`, `preference`, `pitfall`, `tool`.

Allowed `source`: `observed`, `user-stated`, `inferred`.
