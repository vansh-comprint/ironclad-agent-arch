#!/bin/bash
# ============================================================================
# CONDUCTOR AGENT SYSTEM — INSTALLER
# ============================================================================
# This script installs the conductor orchestration system.
#
# What it does:
# 1. Installs the conductor (user-level) to ~/.claude/sub-agents/
# 2. Optionally bootstraps the current project with project-level agents
#
# Usage:
#   ./install.sh              # Install conductor only (user-level)
#   ./install.sh --project    # Install conductor + bootstrap current project
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_AGENTS_DIR="$HOME/.claude/sub-agents"
PROJECT_DIR="$(pwd)"

echo "============================================"
echo "  CONDUCTOR AGENT SYSTEM — INSTALLER"
echo "============================================"
echo ""

# --- Step 1: Install conductor (user-level) ---
echo "[1/3] Installing conductor to ~/.claude/sub-agents/ ..."

mkdir -p "$USER_AGENTS_DIR"

if [ -f "$USER_AGENTS_DIR/conductor.md" ]; then
    echo "  ⚠  conductor.md already exists. Backing up to conductor.md.backup"
    cp "$USER_AGENTS_DIR/conductor.md" "$USER_AGENTS_DIR/conductor.md.backup"
fi

cp "$SCRIPT_DIR/user-level/.claude/sub-agents/conductor.md" "$USER_AGENTS_DIR/conductor.md"
echo "  ✅ Conductor installed"
echo ""

# --- Step 2: Optionally bootstrap project ---
if [ "$1" = "--project" ]; then
    echo "[2/3] Bootstrapping project at $PROJECT_DIR ..."

    # Create directories
    mkdir -p "$PROJECT_DIR/.claude/sub-agents"
    mkdir -p "$PROJECT_DIR/.claude/hooks"
    mkdir -p "$PROJECT_DIR/.claude/skills"
    mkdir -p "$PROJECT_DIR/.claude/checklists"
    mkdir -p "$PROJECT_DIR/.claude/memory/agent-logs"

    # Copy agent files (don't overwrite existing)
    for agent_file in "$SCRIPT_DIR/project-level/.claude/sub-agents/"*.md; do
        filename=$(basename "$agent_file")
        if [ -f "$PROJECT_DIR/.claude/sub-agents/$filename" ]; then
            echo "  ⚠  $filename already exists — skipping (won't overwrite)"
        else
            cp "$agent_file" "$PROJECT_DIR/.claude/sub-agents/$filename"
            echo "  ✅ Installed $filename"
        fi
    done

    # Copy hooks — shell scripts (don't overwrite existing)
    for hook_file in "$SCRIPT_DIR/project-level/.claude/hooks/"*.sh; do
        [ -e "$hook_file" ] || continue
        filename=$(basename "$hook_file")
        if [ -f "$PROJECT_DIR/.claude/hooks/$filename" ]; then
            echo "  ⚠  $filename already exists — skipping"
        else
            cp "$hook_file" "$PROJECT_DIR/.claude/hooks/$filename"
            chmod +x "$PROJECT_DIR/.claude/hooks/$filename"
            echo "  ✅ Installed $filename"
        fi
    done

    # Copy hooks — prompt-based hooks (don't overwrite existing)
    for hook_file in "$SCRIPT_DIR/project-level/.claude/hooks/"*.md; do
        [ -e "$hook_file" ] || continue
        filename=$(basename "$hook_file")
        if [ -f "$PROJECT_DIR/.claude/hooks/$filename" ]; then
            echo "  ⚠  $filename already exists — skipping"
        else
            cp "$hook_file" "$PROJECT_DIR/.claude/hooks/$filename"
            echo "  ✅ Installed $filename"
        fi
    done

    # Copy skills (don't overwrite existing)
    for skill_file in "$SCRIPT_DIR/project-level/.claude/skills/"*.md; do
        [ -e "$skill_file" ] || continue
        filename=$(basename "$skill_file")
        if [ -f "$PROJECT_DIR/.claude/skills/$filename" ]; then
            echo "  ⚠  skills/$filename already exists — skipping"
        else
            cp "$skill_file" "$PROJECT_DIR/.claude/skills/$filename"
            echo "  ✅ Installed skills/$filename"
        fi
    done

    # Copy checklists (don't overwrite existing)
    for checklist_file in "$SCRIPT_DIR/project-level/.claude/checklists/"*.md; do
        [ -e "$checklist_file" ] || continue
        filename=$(basename "$checklist_file")
        if [ -f "$PROJECT_DIR/.claude/checklists/$filename" ]; then
            echo "  ⚠  checklists/$filename already exists — skipping"
        else
            cp "$checklist_file" "$PROJECT_DIR/.claude/checklists/$filename"
            echo "  ✅ Installed checklists/$filename"
        fi
    done

    # Copy memory templates (don't overwrite existing)
    for mem_file in "$SCRIPT_DIR/project-level/.claude/memory/"*.md; do
        filename=$(basename "$mem_file")
        if [ -f "$PROJECT_DIR/.claude/memory/$filename" ]; then
            echo "  ⚠  $filename already exists — skipping"
        else
            cp "$mem_file" "$PROJECT_DIR/.claude/memory/$filename"
            echo "  ✅ Created $filename"
        fi
    done

    # Copy agent log templates
    for log_file in "$SCRIPT_DIR/project-level/.claude/memory/agent-logs/"*.md; do
        filename=$(basename "$log_file")
        if [ -f "$PROJECT_DIR/.claude/memory/agent-logs/$filename" ]; then
            echo "  ⚠  agent-logs/$filename already exists — skipping"
        else
            cp "$log_file" "$PROJECT_DIR/.claude/memory/agent-logs/$filename"
        fi
    done
    echo "  ✅ Agent logs initialized"

    # Add to .gitignore
    if [ -f "$PROJECT_DIR/.gitignore" ]; then
        if ! grep -q ".claude/memory/" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
            echo "" >> "$PROJECT_DIR/.gitignore"
            echo "# Agent system memory (session-specific, not for git)" >> "$PROJECT_DIR/.gitignore"
            echo ".claude/memory/" >> "$PROJECT_DIR/.gitignore"
            echo "  ✅ Added .claude/memory/ to .gitignore"
        else
            echo "  ℹ  .gitignore already excludes .claude/memory/"
        fi
    else
        echo "# Agent system memory (session-specific, not for git)" > "$PROJECT_DIR/.gitignore"
        echo ".claude/memory/" >> "$PROJECT_DIR/.gitignore"
        echo "  ✅ Created .gitignore with .claude/memory/ exclusion"
    fi

    # Append to CLAUDE.md if exists, or note for user
    if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
        if ! grep -q "Agent System" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
            echo "" >> "$PROJECT_DIR/CLAUDE.md"
            cat "$SCRIPT_DIR/project-level/CLAUDE-AGENT-SYSTEM.md" >> "$PROJECT_DIR/CLAUDE.md"
            echo "  ✅ Appended agent system docs to CLAUDE.md"
        else
            echo "  ℹ  CLAUDE.md already has agent system reference"
        fi
    else
        cp "$SCRIPT_DIR/project-level/CLAUDE-AGENT-SYSTEM.md" "$PROJECT_DIR/CLAUDE.md"
        echo "  ✅ Created CLAUDE.md with agent system docs"
    fi

    echo ""
    echo "  Project bootstrapped successfully!"
else
    echo "[2/3] Skipping project bootstrap (use --project to bootstrap current directory)"
fi

echo ""
echo "[3/3] Done!"
echo ""
echo "============================================"
echo "  INSTALLATION COMPLETE"
echo "============================================"
echo ""
echo "  Conductor installed at: $USER_AGENTS_DIR/conductor.md"
if [ "$1" = "--project" ]; then
    echo "  Project agents at:      $PROJECT_DIR/.claude/sub-agents/"
    echo "  Memory at:              $PROJECT_DIR/.claude/memory/"
    echo "  Hooks at:               $PROJECT_DIR/.claude/hooks/"
fi
echo ""
echo "  To use: just say 'use the conductor to [task]' in Claude Code"
echo ""
echo "  The conductor will automatically:"
echo "    • Bootstrap new projects on first run"
echo "    • Resume work-in-progress from memory"
echo "    • Delegate to specialized agents"
echo "    • Enforce quality through hooks"
echo "    • Learn from this project over time"
echo ""
echo "============================================"
