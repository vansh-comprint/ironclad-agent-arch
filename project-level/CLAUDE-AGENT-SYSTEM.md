# Agent System — Conductor Orchestration

This project uses the **conductor agent system** — a self-managing AI orchestration
layer that handles task planning, delegation, memory, and quality enforcement.

## How to use

Just invoke the conductor for any task. It handles everything:

```
Use the conductor to [your task here]
```

The conductor will:
- Bootstrap the agent system on first run (if not already set up)
- Resume work-in-progress from memory
- Assess task complexity and delegate appropriately
- Manage project memory and agent learning
- Enforce quality through automated hooks

## Architecture

```
CONDUCTOR (user-level, opus) — the brain
  ├── ANALYST (sonnet, background) — reconnaissance & memory validation
  ├── BUILDER (sonnet) — implementation
  │     └── SURGEON (sonnet) — precision multi-file edits (builder-internal)
  ├── BREAKER (sonnet, background) — destruction testing
  ├── SENTINEL (haiku, background) — mechanical verification
  ├── LIBRARIAN (haiku, background) — memory management
  ├── ADVOCATE (sonnet, background) — flash tribunal: case FOR
  └── ADVERSARY (sonnet, background) — flash tribunal: case AGAINST
```

## Memory (DO NOT commit to git)

All agent memory lives in `.claude/memory/`:
- `architecture.md` — living codebase map (managed by librarian)
- `decisions.md` — decision log with tribunal records (managed by conductor)
- `failures.md` — failure registry and learned patterns (managed by librarian)
- `wip.md` — work-in-progress state for task resumption (managed by conductor)
- `agent-logs/` — individual agent observation logs (written by each agent)

Add to `.gitignore`:
```
.claude/memory/
```

## Hooks

Automated quality gates in `.claude/hooks/`:
- `subagent-stop-builder.sh` — rejects builder output if tests/types/lint fail
- `subagent-stop-breaker.sh` — rejects breaker if no test scripts were executed
- `subagent-stop-sentinel.sh` — verifies sentinel actually ran test commands

## Task Complexity Tiers

The conductor automatically assesses complexity:
- **TRIVIAL** — no delegation, handled directly
- **SIMPLE** — analyst → builder → sentinel
- **COMPLEX** — analyst → builder(+surgeon) → breaker → sentinel
- **AMBIGUOUS** — analyst deep scan → present findings → re-assess
- **CRITICAL** — full orchestration + flash tribunal (advocate + adversary)
