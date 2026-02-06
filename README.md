# Conductor — Multi-Agent Orchestration for Claude Code

One agent to manage everything. Background & parallel sub-agents with project-scoped memory.

## What this is

A multi sub-agent orchestration system for Claude Code (Opus 4.6+). One user-level **conductor** agent automatically bootstraps any project with 14 specialized workers that run in **background and parallel**, maintain **persistent per-project memory**, and enforce quality through **mechanical hooks**.

You never call individual agents. You call the conductor. It reads the room.

## Install (one command)

```bash
git clone https://github.com/vansh-comprint/ironclad-agent-arch.git conductor-agents
cd conductor-agents
./install.sh
```

That's it. Restart Claude Code.

### What the installer does

1. Copies `conductor.md` to `~/.claude/agents/` (user-level — follows you everywhere)
2. Copies project templates to `~/.claude/ironclad-agents/` (template store)
3. Enables **agent teams** + **extended thinking** in `~/.claude/settings.json`

### Optional: bootstrap a project manually

```bash
cd /path/to/your/project
~/conductor-agents/install.sh --project
```

Or just skip this — the conductor auto-bootstraps any new project on first invocation.

### Uninstall

```bash
./install.sh --uninstall
```

## Usage

In Claude Code:

```
Use the conductor to add WebSocket support to the notification system
```
```
Use the conductor to fix the race condition in the payment handler
```
```
Use the conductor to refactor the auth module
```

The conductor handles everything from there.

## How it works

```
YOU → conductor (opus, user-level)
      │
      ├─ Checks .claude/memory/ → knows project state
      ├─ Assesses task complexity → picks the right tier
      ├─ Routes by domain → specialist or general builder
      ├─ Spawns agents in background/parallel where possible
      ├─ Hooks reject bad output mechanically
      └─ Updates memory → project gets smarter over time
```

### On first run in a new project

The conductor detects no `.claude/memory/` and automatically:
1. Copies 14 agent templates from `~/.claude/ironclad-agents/` → `.claude/agents/`
2. Creates memory directory with empty templates
3. Installs verification hooks
4. Adds `.claude/memory/` to `.gitignore`
5. Spawns analyst for the relevant area
6. Proceeds with your task

Bootstrap is invisible — you don't wait.

### On return to a project

The conductor reads `.claude/memory/wip.md` and tells you:
> "You were working on [X]. [Current state]. Want to continue or start something new?"

## Agent roster

| Agent | Model | Mode | Role |
|-------|-------|------|------|
| **conductor** | opus | user-level | Orchestrates everything, manages memory |
| **analyst** | sonnet | background | Codebase recon, dependency tracing, memory validation |
| **builder** | sonnet | foreground | General implementation (frontend, scripts, infra) |
| **surgeon** | sonnet | foreground | Precision multi-file atomic edits (delegated by builder) |
| **backend-engineer** | sonnet | foreground | FastAPI/Python specialist (replaces builder for backend) |
| **breaker** | sonnet | background | Destruction testing — writes & runs adversarial scripts |
| **sentinel** | haiku | background | Runs tests/types/lint — mechanical, no opinions |
| **librarian** | haiku | background | Consolidates agent logs into shared memory |
| **advocate** | sonnet | background | Flash tribunal — argues FOR the plan |
| **adversary** | sonnet | background | Flash tribunal — argues AGAINST the plan |
| **architecture-validator** | sonnet | read-only | Validates layer separation & naming |
| **code-reviewer** | sonnet | read-only | Type hints, async patterns, security review |
| **database-architect** | sonnet | foreground | Schema design, models, migrations |
| **security-auditor** | sonnet | read-only | OWASP scanning, auth validation |
| **test-generator** | sonnet | foreground | pytest-asyncio test generation |

## Task complexity tiers

The conductor auto-selects the right tier:

| Tier | Agents spawned | When |
|------|---------------|------|
| **TRIVIAL** | None (do it directly) | Typo, rename, config tweak |
| **SIMPLE** | analyst → builder → sentinel | Bug fix, add field, 3-8 files |
| **COMPLEX** | analyst → builder(+surgeon) → breaker → sentinel | New feature, refactor, 8+ files |
| **AMBIGUOUS** | analyst (deep) → present to user → re-assess | Unclear requirements |
| **CRITICAL** | analyst → flash tribunal → builder → security-auditor → sentinel | Irreversible changes, auth/payments |

## Project structure after bootstrap

```
your-project/
  .claude/
    agents/                      ← 14 project-level agents (committed to git)
      analyst.md
      builder.md
      surgeon.md
      backend-engineer.md
      breaker.md
      sentinel.md
      librarian.md
      advocate.md
      adversary.md
      architecture-validator.md
      code-reviewer.md
      database-architect.md
      security-auditor.md
      test-generator.md
    hooks/                       ← Mechanical quality gates (committed)
      subagent-stop-builder.sh
      subagent-stop-breaker.sh
      subagent-stop-sentinel.sh
      pre-write-validation.md
    skills/                      ← Domain knowledge (committed)
      backend.md
    checklists/                  ← Completion checklists (committed)
      endpoint-checklist.md
    memory/                      ← Per-project learning (GITIGNORED)
      architecture.md            ← Living codebase map
      decisions.md               ← Decision log + tribunal records
      failures.md                ← Failure registry + attack patterns
      wip.md                     ← Work-in-progress for session resume
      agent-logs/                ← Individual agent observations
        analyst.md
        builder.md
        ...
```

### What to commit vs. what to gitignore

| Path | Git | Why |
|------|-----|-----|
| `.claude/agents/` | Commit | Shared agent definitions — team config |
| `.claude/hooks/` | Commit | Quality gates — team standard |
| `.claude/skills/` | Commit | Domain knowledge — shared |
| `.claude/checklists/` | Commit | Standards — shared |
| `.claude/memory/` | **Gitignore** | Session-specific learning — local only |

## Memory system

| File | Written by | Purpose |
|------|-----------|---------|
| `architecture.md` | Librarian | Living codebase map, validated by analyst |
| `decisions.md` | Conductor | Decision log, flash tribunal records |
| `failures.md` | Librarian | Failure registry, effective attack patterns |
| `wip.md` | Conductor | Work-in-progress state for task resumption |
| `agent-logs/*.md` | Each agent | Individual observations and learned patterns |

Write discipline prevents conflicts: only the librarian writes to shared memory. Agents write to their own logs. The conductor writes decisions and WIP directly.

## Hooks (mechanical enforcement)

| Hook | Enforces | Rejects when |
|------|----------|--------------|
| `subagent-stop-builder.sh` | Tests + types + lint pass | Any automated check fails |
| `subagent-stop-breaker.sh` | Scripts were executed | No evidence of test execution |
| `subagent-stop-sentinel.sh` | Tests actually ran | No test runner output detected |
| `pre-write-validation.md` | Code quality on write | Naming/pattern violations |

No LLM judgment — real tools, real exit codes.

## Flash tribunal

For critical decisions (schema migrations, auth changes, irreversible actions), the conductor auto-escalates:

1. Writes proposed plan to `wip.md`
2. Spawns **advocate** (background) — builds case FOR with codebase evidence
3. Spawns **adversary** (background) — finds genuine risks with codebase evidence
4. Reads both reports
5. Makes final decision
6. Logs full reasoning to `decisions.md`

## Customization

**Add agents:** Create `.md` files in `.claude/agents/`. Follow the frontmatter format (name, description, tools, model).

**Change model allocation:** Edit `model:` in any agent's frontmatter. Use `haiku` for cheap tasks, `opus` for critical ones, `inherit` to match the session.

**Add hooks:** Create `subagent-stop-[name].sh` in `.claude/hooks/`. Auto-runs when that agent completes.

**Modify complexity tiers:** Edit the conductor's Task Assessment section.

## Requirements

- Claude Code with Opus 4.6 (for agent teams + background execution)
- Python 3 (for settings.json merge during install — optional)
- Git Bash on Windows (install script is bash)
