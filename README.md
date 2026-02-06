# Conductor — Multi-Agent Orchestration for Claude Code

One agent to manage everything. Agent Teams with peer-to-peer messaging, self-improving memory, and parallel execution.

## What this is

A multi-agent orchestration system for Claude Code (Opus 4.6+) using **Agent Teams**. One user-level **conductor** agent automatically bootstraps any project with 14 specialized teammates that run in **persistent parallel sessions**, communicate **peer-to-peer**, maintain **self-improving per-project memory**, and enforce quality through **mechanical hooks**.

You never call individual agents. You call the conductor. It reads the room.

**Key features:**
- **Agent Teams** — teammates get their own context windows and message each other directly
- **Self-improving** — every task makes the team smarter (attack patterns, scan strategies, conventions)
- **Smart communication** — structured messages with priority, type, and action routing
- **Hybrid orchestration** — Agent Teams for complex work, lightweight subagents for simple work
- **Meta-learning** — librarian tracks team effectiveness and recommends improvements to conductor

## Install (one command)

### Linux / macOS / Git Bash on Windows
```bash
git clone https://github.com/vansh-comprint/ironclad-agent-arch.git conductor-agents
cd conductor-agents
./install.sh
```

### Windows PowerShell
```powershell
git clone https://github.com/vansh-comprint/ironclad-agent-arch.git conductor-agents
cd conductor-agents
.\install.ps1
```

That's it. Restart Claude Code.

### What the installer does

1. Copies `conductor.md` to `~/.claude/agents/` (user-level — follows you everywhere)
2. Copies 14 agent templates to `~/.claude/ironclad-agents/` (template store)
3. **Enables Agent Teams** in `~/.claude/settings.json`:
   - Sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (enables teammate sessions)
   - Sets `alwaysThinkingEnabled=true` (extended thinking for better orchestration)

### Manual Agent Teams setup (if not using installer)

If you already have the agents and just need to enable Agent Teams:

```bash
# Option 1: Edit ~/.claude/settings.json manually
# Add this to your settings.json:
{
  "alwaysThinkingEnabled": true,
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

```bash
# Option 2: The conductor auto-enables it on first bootstrap
# Just invoke the conductor — it checks and enables Agent Teams automatically
```

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
      ├─ Checks .claude/memory/ → knows project state + meta-learnings
      ├─ Assesses task complexity → picks orchestration mode
      ├─ Routes by domain → specialist or general builder
      │
      ├─ SIMPLE tasks: Task tool subagents (cheap, sequential)
      │   └─ analyst → builder → sentinel
      │
      ├─ COMPLEX tasks: Agent Team (parallel, peer-to-peer)
      │   └─ spawnTeam → teammates communicate directly
      │       analyst ──HANDOFF──▶ builder ──HANDOFF──▶ breaker + sentinel
      │                                                       │
      │       breaker ──BUG──▶ builder (fix cycle)            │
      │       sentinel ──PASS──▶ ALL (broadcast)              │
      │       librarian ──META──▶ conductor (team learnings)  │
      │
      ├─ CRITICAL tasks: Agent Team + Flash Tribunal
      │   └─ advocate + adversary → decision → team execution
      │
      └─ Updates memory → project gets smarter every task
```

### Self-improvement loop

Every task makes the team smarter:

```
Task N:
  analyst scans → builder implements → breaker tests → sentinel verifies
                                          │
                                          ▼
  librarian consolidates ALL agent logs + messages:
    - Which scan strategies found useful info? (promote/demote)
    - Which attack patterns found real bugs? (promote/demote)
    - How many fix cycles? (track trend)
    - What communication patterns worked? (record)
                                          │
                                          ▼
  librarian sends META-LEARNING report to conductor:
    "Team effectiveness: 4/5. Builder's null handling improved.
     Breaker's auth bypass pattern found 2 bugs — promote it.
     Recommend: always include security-auditor for auth tasks."
                                          │
                                          ▼
Task N+1:
  conductor reads meta-learnings → adapts team composition + routing
  each agent reads its own log → adapts strategy based on past effectiveness
```

### On first run in a new project

The conductor detects no `.claude/memory/` and automatically:
1. Copies 14 agent templates from `~/.claude/ironclad-agents/` → `.claude/agents/`
2. Creates memory directory with empty templates
3. Installs verification hooks
4. Enables Agent Teams if not already enabled
5. Adds `.claude/memory/` to `.gitignore`
6. Proceeds with your task

Bootstrap is invisible — you don't wait.

### On return to a project

The conductor reads `.claude/memory/wip.md` and tells you:
> "You were working on [X]. [Current state]. Want to continue or start something new?"

It also reads the librarian's meta-learning report to improve orchestration.

## Agent roster

### Teammates (persistent sessions, peer-to-peer messaging)

| Agent | Color | Model | Role |
|-------|-------|-------|------|
| **conductor** | orange | opus | Orchestrates teams, manages memory, approves plans |
| **analyst** | cyan | sonnet | Codebase recon, sends HANDOFF to builder with findings |
| **builder** | yellow | sonnet | General implementation, receives from analyst, hands off to breaker+sentinel |
| **backend-engineer** | blue | sonnet | FastAPI specialist, replaces builder for backend tasks |
| **breaker** | red | sonnet | Destruction testing, sends BUG reports directly to builder |
| **sentinel** | green | haiku | Runs tests/types/lint, broadcasts PASS/FAIL to all |
| **librarian** | purple | haiku | Memory consolidation + meta-learning, makes team smarter |

### Task subagents (lightweight, spawned by teammates)

| Agent | Color | Model | Spawned by | Role |
|-------|-------|-------|-----------|------|
| **surgeon** | yellow | sonnet | builder | Precision multi-file atomic edits |
| **advocate** | magenta | sonnet | conductor | Flash tribunal — argues FOR |
| **adversary** | magenta | sonnet | conductor | Flash tribunal — argues AGAINST |
| **architecture-validator** | cyan | sonnet | backend-engineer | Validates layer separation |
| **code-reviewer** | cyan | sonnet | backend-engineer | Type hints, async, security |
| **database-architect** | blue | sonnet | backend-engineer | Schema design, migrations |
| **security-auditor** | red | sonnet | backend-engineer | OWASP scanning |
| **test-generator** | green | sonnet | backend-engineer | pytest-asyncio generation |

## Task complexity tiers

The conductor auto-selects the right orchestration mode:

| Tier | Mode | Agents | When |
|------|------|--------|------|
| **TRIVIAL** | Direct | None | Typo, rename, config tweak |
| **SIMPLE** | Task subagents | analyst → builder → sentinel | Bug fix, add field, 3-8 files |
| **COMPLEX** | Agent Team | analyst + builder + breaker + sentinel + librarian | New feature, refactor, 8+ files |
| **AMBIGUOUS** | Explore first | analyst (deep scan) → present to user | Unclear requirements |
| **CRITICAL** | Agent Team + tribunal | Full team + advocate + adversary | Irreversible, auth/payments |

**Cost awareness:** Agent Teams use ~5x tokens (each teammate = full session). The conductor uses them only when parallel work genuinely adds value.

## Communication protocol

All teammates use structured messages:

```
[PRIORITY: LOW|MEDIUM|HIGH|CRITICAL]
[TYPE: REPORT|HANDOFF|BUG|PLAN|PASS|FAIL|META|...]
[TO: teammate_name or ALL]

[Structured content — compressed, actionable]

[ACTION NEEDED: what the recipient should do]
```

### Message flow (COMPLEX task)

```
conductor ──mission──▶ analyst
analyst ──HANDOFF──▶ builder (with LANDMINE tags)
analyst ──REPORT──▶ breaker (fragile areas to attack)
builder ──PLAN──▶ conductor (for approval)
conductor ──approvePlan──▶ builder
builder ──HANDOFF──▶ sentinel + breaker
breaker ──BUG──▶ builder (individual bugs as found)
builder ──BUG_FIX──▶ sentinel (re-verify)
sentinel ──PASS──▶ ALL (broadcast)
librarian ──META──▶ conductor (team learnings)
```

## Project structure after bootstrap

```
your-project/
  .claude/
    agents/                      ← 14 project-level agents (committed to git)
    hooks/                       ← Mechanical quality gates (committed)
    skills/                      ← Domain knowledge (committed)
    checklists/                  ← Completion checklists (committed)
    memory/                      ← Per-project learning (GITIGNORED)
      architecture.md            ← Living codebase map
      decisions.md               ← Decision log + tribunal records
      failures.md                ← Failure registry + attack pattern scores
      wip.md                     ← Work-in-progress for session resume
      agent-logs/                ← Individual agent observations + learnings
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
| `failures.md` | Librarian | Failure registry, attack pattern effectiveness scores |
| `wip.md` | Conductor | Work-in-progress state for task resumption |
| `agent-logs/*.md` | Each agent | Individual observations, effectiveness tracking, learnings |

Write discipline prevents conflicts. The librarian is the meta-learner — it tracks team effectiveness across tasks and sends recommendations to the conductor.

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

**Add agents:** Create `.md` files in `.claude/agents/`. Follow the frontmatter format (name, description, tools, model, color).

**Change model allocation:** Edit `model:` in any agent's frontmatter. Use `haiku` for cheap tasks, `opus` for critical ones.

**Add hooks:** Create `subagent-stop-[name].sh` in `.claude/hooks/`. Auto-runs when that agent completes.

**Modify complexity tiers:** Edit the conductor's Task Assessment section.

**Tune self-improvement:** Each agent's Self-Improvement Protocol section controls what it learns. Edit to add project-specific patterns.

## Requirements

- Claude Code with Opus 4.6+ (for Agent Teams + background execution)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings (installer handles this)
- Python 3 (for settings.json merge during install — optional)
- Git Bash on Windows (install script is bash) or PowerShell (install.ps1)
