# Conductor — Self-Managing Agent Orchestration for Claude Code

One agent to manage everything. You talk to the conductor — it handles the rest.

## What this is

A complete agent orchestration system for Claude Code built around a single managing
agent (the **conductor**) that automatically bootstraps projects, delegates to
specialized workers, manages persistent memory, enforces quality through hooks,
and learns about your codebase over time.

You never call individual agents. You call the conductor. It reads the room.

## Architecture

```
YOU → "conductor, [task]"
      │
      ▼
   CONDUCTOR (opus, user-level)
      │
      ├── Reads project memory → knows where things stand
      ├── Assesses complexity → picks the right agents
      ├── Delegates & coordinates → manages the whole flow
      ├── Enforces quality → hooks reject bad output mechanically
      └── Updates memory → project gets smarter over time
          │
          ├── ANALYST (sonnet, bg)    — maps code, validates memory
          ├── BUILDER (sonnet)        — implements, delegates to surgeon
          │     └── SURGEON (sonnet)  — precision multi-file edits
          ├── BREAKER (sonnet, bg)    — destruction testing
          ├── SENTINEL (haiku, bg)    — runs tests/types/lint
          ├── LIBRARIAN (haiku, bg)   — consolidates memory
          ├── ADVOCATE (sonnet, bg)   — tribunal: case FOR
          └── ADVERSARY (sonnet, bg)  — tribunal: case AGAINST
```

## Key design decisions

**One managing agent, not a pipeline.** The conductor adapts its approach per task.
A typo fix gets no delegation. A new feature gets full orchestration. A risky
schema change gets a flash tribunal. The conductor decides.

**Memory lives in the project.** Each project has `.claude/memory/` with a living
architecture map, decision log, failure registry, and per-agent learning. When you
switch projects, the conductor reads that project's memory and picks up instantly.

**Agents learn per-project.** The breaker remembers which attack patterns find real
bugs in THIS specific codebase. The builder remembers which conventions THIS project
follows. The analyst remembers what it's already mapped. Every session makes them sharper.

**Mechanical enforcement, not LLM judgment.** SubagentStop hooks run actual test suites,
type checkers, and linters. If tests fail, the builder's output is rejected — no
LLM decides whether to accept it. Machines verify what machines are good at verifying.

**Cost-optimized model mixing.** Only the conductor uses opus (for judgment and planning).
Workers use sonnet (for code generation and analysis). Sentinel and librarian use haiku
(for mechanical tasks). Background execution where possible.

**Flash tribunal for critical decisions.** When the conductor faces an irreversible or
high-risk decision, it spawns an advocate and adversary in parallel. They argue FOR
and AGAINST the plan with specific codebase evidence. The conductor makes the final
call and logs the full reasoning.

## Installation

### Quick setup (all platforms)

```bash
# Clone this repo
git clone <repo-url> conductor-agents
cd conductor-agents

# Install conductor only (user-level, works across all projects)
./install.sh

# OR install conductor + bootstrap current project
cd /path/to/your/project
/path/to/conductor-agents/install.sh --project
```

### Windows (PowerShell)

```powershell
# Clone this repo
git clone <repo-url> conductor-agents
cd conductor-agents

# Install conductor only
.\install.ps1

# OR install conductor + bootstrap current project
cd C:\path\to\your\project
C:\path\to\conductor-agents\install.ps1 -Project
```

### Team onboarding

Every team member runs these two steps after cloning:

1. **Install the conductor** (once per machine):
   ```bash
   ./install.sh          # or .\install.ps1 on Windows
   ```
2. **Bootstrap your project** (once per project):
   ```bash
   cd /path/to/your/project
   /path/to/conductor-agents/install.sh --project
   ```

The conductor will also auto-bootstrap any new project on first invocation —
you don't HAVE to run `--project` manually.

### What gets committed vs. what doesn't

| Path | Git status | Why |
|------|-----------|-----|
| `.claude/sub-agents/` | Committed | Agent definitions are shared config |
| `.claude/hooks/` | Committed | Quality gates are shared config |
| `.claude/memory/` | **Gitignored** | Session-specific agent learning |

## Usage

In Claude Code, just say:

```
Use the conductor to add WebSocket support to the notification system
```

```
Use the conductor to fix the race condition in the payment handler
```

```
Use the conductor to refactor the auth module to use JWT
```

The conductor handles everything from there.

## Task complexity tiers

| Tier | Agents used | When |
|------|-------------|------|
| TRIVIAL | None (direct) | Rename, typo, config change |
| SIMPLE | analyst → builder → sentinel | Small bug fix, add field |
| COMPLEX | analyst → builder(+surgeon) → breaker → sentinel | New feature, refactor |
| AMBIGUOUS | analyst (deep) → present findings → re-assess | Unclear requirements |
| CRITICAL | Full orchestration + flash tribunal | Irreversible changes, auth/payments |

## File structure

```
~/.claude/sub-agents/
  conductor.md                    ← user-level, follows you everywhere

your-project/.claude/
  sub-agents/                     ← project-level workers
    analyst.md
    builder.md
    surgeon.md
    breaker.md
    sentinel.md
    librarian.md
    advocate.md
    adversary.md
  hooks/                          ← mechanical quality gates
    subagent-stop-builder.sh
    subagent-stop-breaker.sh
    subagent-stop-sentinel.sh
  memory/                         ← persistent project knowledge (gitignored)
    architecture.md
    decisions.md
    failures.md
    wip.md
    agent-logs/
      analyst.md
      builder.md
      breaker.md
      sentinel.md
      librarian.md
      advocate.md
      adversary.md
```

## Memory system

| File | Writer | Purpose |
|------|--------|---------|
| `architecture.md` | Librarian | Living codebase map, validated by analyst |
| `decisions.md` | Conductor | Decision log, tribunal records |
| `failures.md` | Librarian | Failure registry, effective attack patterns |
| `wip.md` | Conductor | Work-in-progress state for task resumption |
| `agent-logs/*.md` | Each agent | Individual observations and learned patterns |

**Write discipline:** Only the librarian writes to shared memory (architecture.md,
failures.md). Agents write to their own logs. The conductor writes to decisions.md
and wip.md. This prevents conflicts.

**Memory is gitignored.** It contains session-specific learning that's meaningful to
the agents, not to human reviewers. The `.claude/sub-agents/` and `.claude/hooks/`
directories CAN be committed — they're configuration, not state.

## Hooks

| Hook | Enforces | Rejects when |
|------|----------|--------------|
| `subagent-stop-builder.sh` | Tests, types, lint pass | Any automated check fails |
| `subagent-stop-breaker.sh` | Scripts were executed | No evidence of test execution |
| `subagent-stop-sentinel.sh` | Tests actually ran | No test runner output detected |

Hooks are bash scripts. They run real tools. No LLM judgment. This is the ratchet —
code can never get worse because bad output is mechanically rejected.

## Opus 4.6 features used

- **Model mixing**: opus (conductor) / sonnet (workers) / haiku (verification)
- **Project memory**: agents learn per-project patterns across sessions
- **User memory**: conductor knows your preferences across all projects
- **Background execution**: analyst, breaker, sentinel, librarian run in background
- **Agent-to-agent delegation**: builder spawns surgeon for multi-file edits
- **SubagentStop hooks**: mechanical quality enforcement on builder, breaker, sentinel

## Customization

**Add project-specific agents:** Create new `.md` files in `.claude/sub-agents/`.
The conductor will discover and use them if relevant.

**Modify complexity thresholds:** Edit the conductor's Task Assessment section
to change when different tiers trigger.

**Add more hooks:** Create new `subagent-stop-[name].sh` files in `.claude/hooks/`.
They'll automatically run when that agent completes.

**Tune model allocation:** Change the `model:` field in any agent's frontmatter.
Use `model: inherit` to match whatever the main session uses.
