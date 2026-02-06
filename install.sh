#!/bin/bash
# ============================================================================
# Conductor — Multi-Agent Orchestration for Claude Code
# Background & parallel sub-agent system with project-scoped memory
#
# Usage:
#   ./install.sh              Install conductor + enable agent teams
#   ./install.sh --project    Install + bootstrap current project
#   ./install.sh --uninstall  Remove conductor from user-level
# ============================================================================

set -e

# --- Colors (works on most terminals including Git Bash) ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}>>>${NC} $1"; }
ok()      { echo -e "${GREEN} +${NC} $1"; }
warn()    { echo -e "${YELLOW} !${NC} $1"; }
fail()    { echo -e "${RED} x${NC} $1"; exit 1; }

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
AGENTS_DIR="$CLAUDE_HOME/agents"
TEMPLATE_SRC="$SCRIPT_DIR/project-level/.claude"
TEMPLATE_DEST="$CLAUDE_HOME/ironclad-agents/project-level/.claude"
SETTINGS="$CLAUDE_HOME/settings.json"

# --- Preflight ---
preflight() {
    # Check source files exist
    if [ ! -d "$SCRIPT_DIR/project-level/.claude/sub-agents" ]; then
        fail "Template files not found. Run this from the cloned repo directory."
    fi

    # Find conductor source (handles both layouts)
    if [ -f "$SCRIPT_DIR/user-level/.claude/sub-agents/conductor.md" ]; then
        CONDUCTOR_SRC="$SCRIPT_DIR/user-level/.claude/sub-agents/conductor.md"
    elif [ -f "$SCRIPT_DIR/conductor.md" ]; then
        CONDUCTOR_SRC="$SCRIPT_DIR/conductor.md"
    elif [ -f "$AGENTS_DIR/conductor.md" ]; then
        CONDUCTOR_SRC="$AGENTS_DIR/conductor.md"
        warn "Using existing conductor at $AGENTS_DIR (no source in repo)"
    else
        fail "conductor.md not found in repo or ~/.claude/agents/"
    fi
}

# --- Install conductor (user-level) ---
install_conductor() {
    info "Installing conductor agent (user-level)..."
    mkdir -p "$AGENTS_DIR"

    if [ -f "$AGENTS_DIR/conductor.md" ] && [ "$CONDUCTOR_SRC" != "$AGENTS_DIR/conductor.md" ]; then
        cp "$AGENTS_DIR/conductor.md" "$AGENTS_DIR/conductor.md.backup"
        warn "Backed up existing conductor.md"
    fi

    if [ "$CONDUCTOR_SRC" != "$AGENTS_DIR/conductor.md" ]; then
        cp "$CONDUCTOR_SRC" "$AGENTS_DIR/conductor.md"
    fi
    ok "Conductor installed at ~/.claude/agents/conductor.md"
}

# --- Install templates to user-level store ---
install_templates() {
    info "Installing project templates to ~/.claude/ironclad-agents/..."

    # If already running from inside ~/.claude/ironclad-agents, skip copy
    if [ "$(cd "$SCRIPT_DIR" && pwd)" = "$(cd "$CLAUDE_HOME/ironclad-agents" 2>/dev/null && pwd)" ]; then
        ok "Templates already in place (running from ~/.claude/ironclad-agents)"
        return
    fi

    mkdir -p "$TEMPLATE_DEST/sub-agents"
    mkdir -p "$TEMPLATE_DEST/memory/agent-logs"
    mkdir -p "$TEMPLATE_DEST/hooks"
    mkdir -p "$TEMPLATE_DEST/skills"
    mkdir -p "$TEMPLATE_DEST/checklists"

    # Copy all template directories
    cp "$TEMPLATE_SRC/sub-agents/"*.md "$TEMPLATE_DEST/sub-agents/" 2>/dev/null || true
    for f in architecture.md decisions.md failures.md wip.md; do
        [ -f "$TEMPLATE_SRC/memory/$f" ] && cp "$TEMPLATE_SRC/memory/$f" "$TEMPLATE_DEST/memory/$f"
    done
    cp "$TEMPLATE_SRC/memory/agent-logs/"*.md "$TEMPLATE_DEST/memory/agent-logs/" 2>/dev/null || true
    cp "$TEMPLATE_SRC/hooks/"* "$TEMPLATE_DEST/hooks/" 2>/dev/null || true
    cp "$TEMPLATE_SRC/skills/"*.md "$TEMPLATE_DEST/skills/" 2>/dev/null || true
    cp "$TEMPLATE_SRC/checklists/"*.md "$TEMPLATE_DEST/checklists/" 2>/dev/null || true

    local agent_count=$(ls "$TEMPLATE_DEST/sub-agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
    ok "Installed $agent_count agent templates + memory + hooks + skills"
}

# --- Update settings.json (non-destructive merge) ---
update_settings() {
    info "Configuring Claude Code settings..."

    if [ ! -f "$SETTINGS" ]; then
        cat > "$SETTINGS" << 'EOF'
{
  "alwaysThinkingEnabled": true,
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
        ok "Created settings.json"
        return
    fi

    # Use python for safe JSON merge (available on macOS, Linux, Win Git Bash)
    local PY=""
    command -v python3 &>/dev/null && PY="python3"
    [ -z "$PY" ] && command -v python &>/dev/null && PY="python"

    if [ -n "$PY" ]; then
        $PY << PYEOF
import json, sys
try:
    with open("$SETTINGS", "r") as f:
        data = json.load(f)
except:
    data = {}

changed = False

if not data.get("alwaysThinkingEnabled"):
    data["alwaysThinkingEnabled"] = True
    changed = True

if "env" not in data:
    data["env"] = {}

if data["env"].get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") != "1":
    data["env"]["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"
    changed = True

if changed:
    with open("$SETTINGS", "w") as f:
        json.dump(data, f, indent=2)
    print("updated")
else:
    print("already_configured")
PYEOF
        local result=$?
        if [ $result -eq 0 ]; then
            ok "Agent teams + extended thinking enabled"
        fi
    else
        warn "Python not found. Add manually to $SETTINGS:"
        echo '  "alwaysThinkingEnabled": true,'
        echo '  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }'
    fi
}

# --- Bootstrap a project ---
bootstrap_project() {
    info "Bootstrapping project at $(pwd)..."

    local src="$TEMPLATE_DEST"
    [ ! -d "$src/sub-agents" ] && src="$TEMPLATE_SRC"

    mkdir -p .claude/agents .claude/memory/agent-logs .claude/hooks .claude/skills .claude/checklists

    # Agents (sub-agents/ → agents/ rename for Claude Code discovery)
    local count=0
    for f in "$src/sub-agents/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        if [ ! -f ".claude/agents/$name" ]; then
            cp "$f" ".claude/agents/$name"
            count=$((count + 1))
        fi
    done
    ok "$count agents installed to .claude/agents/"

    # Memory templates
    for f in architecture.md decisions.md failures.md wip.md; do
        [ ! -f ".claude/memory/$f" ] && [ -f "$src/memory/$f" ] && cp "$src/memory/$f" ".claude/memory/$f"
    done
    for f in "$src/memory/agent-logs/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        [ ! -f ".claude/memory/agent-logs/$name" ] && cp "$f" ".claude/memory/agent-logs/$name"
    done
    ok "Memory templates created"

    # Hooks
    for f in "$src/hooks/"*; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        if [ ! -f ".claude/hooks/$name" ]; then
            cp "$f" ".claude/hooks/$name"
            [ "${name##*.}" = "sh" ] && chmod +x ".claude/hooks/$name"
        fi
    done
    ok "Hooks installed"

    # Skills + checklists
    for f in "$src/skills/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        [ ! -f ".claude/skills/$name" ] && cp "$f" ".claude/skills/$name"
    done
    for f in "$src/checklists/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        [ ! -f ".claude/checklists/$name" ] && cp "$f" ".claude/checklists/$name"
    done
    ok "Skills + checklists installed"

    # .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q ".claude/memory/" .gitignore 2>/dev/null; then
            printf "\n# Agent memory (local, not shared)\n.claude/memory/\n" >> .gitignore
            ok "Added .claude/memory/ to .gitignore"
        fi
    fi

    ok "Project ready"
}

# --- Uninstall ---
uninstall() {
    info "Uninstalling conductor..."

    [ -f "$AGENTS_DIR/conductor.md" ] && rm "$AGENTS_DIR/conductor.md" && ok "Removed conductor"
    echo ""
    warn "Template store (~/.claude/ironclad-agents/) not removed."
    warn "To fully remove: rm -rf ~/.claude/ironclad-agents/"
    warn "Project .claude/ directories not removed (remove manually per project)."
}

# --- Main ---
echo ""
echo -e "${BOLD}Conductor — Multi-Agent Orchestration for Claude Code${NC}"
echo -e "Background & parallel sub-agents with project-scoped memory"
echo "======================================================"
echo ""

case "${1:-}" in
    --uninstall|-u)
        uninstall
        ;;
    --project|-p)
        preflight
        install_conductor
        install_templates
        update_settings
        echo ""
        bootstrap_project
        ;;
    --help|-h)
        echo "Usage:"
        echo "  ./install.sh              Install conductor (user-level)"
        echo "  ./install.sh --project    Install + bootstrap current project"
        echo "  ./install.sh --uninstall  Remove conductor"
        echo ""
        echo "After install, say in Claude Code:"
        echo '  "Use the conductor to [your task]"'
        exit 0
        ;;
    *)
        preflight
        install_conductor
        install_templates
        update_settings
        ;;
esac

echo ""
echo -e "${GREEN}${BOLD}Done!${NC}"
echo ""
echo "  Conductor:  ~/.claude/agents/conductor.md"
echo "  Templates:  ~/.claude/ironclad-agents/"
echo "  Settings:   Agent teams + extended thinking enabled"
echo ""
echo "  In Claude Code, say:"
echo '    "Use the conductor to [your task]"'
echo ""
echo "  The conductor auto-bootstraps any new project on first run."
echo "  Or manually: ./install.sh --project (from project directory)"
echo ""
echo -e "${YELLOW}  Restart Claude Code to pick up changes.${NC}"
echo ""
