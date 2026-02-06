# ============================================================================
# CONDUCTOR AGENT SYSTEM — INSTALLER (PowerShell)
# ============================================================================
# For Windows users without Git Bash. Same behavior as install.sh.
#
# Usage:
#   .\install.ps1              # Install conductor only (user-level)
#   .\install.ps1 -Project     # Install conductor + bootstrap current project
# ============================================================================

param(
    [switch]$Project
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserAgentsDir = Join-Path $env:USERPROFILE ".claude\sub-agents"
$ProjectDir = Get-Location

Write-Host "============================================"
Write-Host "  CONDUCTOR AGENT SYSTEM - INSTALLER"
Write-Host "============================================"
Write-Host ""

# --- Step 1: Install conductor (user-level) ---
Write-Host "[1/3] Installing conductor to ~/.claude/sub-agents/ ..."

if (-not (Test-Path $UserAgentsDir)) {
    New-Item -ItemType Directory -Path $UserAgentsDir -Force | Out-Null
}

$ConductorDest = Join-Path $UserAgentsDir "conductor.md"
if (Test-Path $ConductorDest) {
    Write-Host "  WARNING: conductor.md already exists. Backing up to conductor.md.backup"
    Copy-Item $ConductorDest "$ConductorDest.backup" -Force
}

$ConductorSrc = Join-Path $ScriptDir "user-level\.claude\sub-agents\conductor.md"
Copy-Item $ConductorSrc $ConductorDest -Force
Write-Host "  OK: Conductor installed"
Write-Host ""

# --- Step 2: Optionally bootstrap project ---
if ($Project) {
    Write-Host "[2/3] Bootstrapping project at $ProjectDir ..."

    # Create directories
    $dirs = @(
        ".claude\sub-agents",
        ".claude\hooks",
        ".claude\memory\agent-logs"
    )
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $ProjectDir $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    }

    # Copy agent files (don't overwrite existing)
    $agentSrc = Join-Path $ScriptDir "project-level\.claude\sub-agents"
    Get-ChildItem "$agentSrc\*.md" | ForEach-Object {
        $dest = Join-Path $ProjectDir ".claude\sub-agents\$($_.Name)"
        if (Test-Path $dest) {
            Write-Host "  WARNING: $($_.Name) already exists - skipping"
        } else {
            Copy-Item $_.FullName $dest
            Write-Host "  OK: Installed $($_.Name)"
        }
    }

    # Copy hooks (don't overwrite existing)
    $hookSrc = Join-Path $ScriptDir "project-level\.claude\hooks"
    Get-ChildItem "$hookSrc\*.sh" | ForEach-Object {
        $dest = Join-Path $ProjectDir ".claude\hooks\$($_.Name)"
        if (Test-Path $dest) {
            Write-Host "  WARNING: $($_.Name) already exists - skipping"
        } else {
            Copy-Item $_.FullName $dest
            Write-Host "  OK: Installed $($_.Name)"
        }
    }

    # Copy memory templates (don't overwrite existing)
    $memSrc = Join-Path $ScriptDir "project-level\.claude\memory"
    Get-ChildItem "$memSrc\*.md" | ForEach-Object {
        $dest = Join-Path $ProjectDir ".claude\memory\$($_.Name)"
        if (Test-Path $dest) {
            Write-Host "  WARNING: $($_.Name) already exists - skipping"
        } else {
            Copy-Item $_.FullName $dest
            Write-Host "  OK: Created $($_.Name)"
        }
    }

    # Copy agent log templates
    $logSrc = Join-Path $ScriptDir "project-level\.claude\memory\agent-logs"
    Get-ChildItem "$logSrc\*.md" | ForEach-Object {
        $dest = Join-Path $ProjectDir ".claude\memory\agent-logs\$($_.Name)"
        if (-not (Test-Path $dest)) {
            Copy-Item $_.FullName $dest
        }
    }
    Write-Host "  OK: Agent logs initialized"

    # Add to .gitignore
    $gitignore = Join-Path $ProjectDir ".gitignore"
    if (Test-Path $gitignore) {
        $content = Get-Content $gitignore -Raw
        if ($content -notmatch "\.claude/memory/") {
            Add-Content $gitignore "`n# Agent system memory (session-specific, not for git)`n.claude/memory/"
            Write-Host "  OK: Added .claude/memory/ to .gitignore"
        } else {
            Write-Host "  INFO: .gitignore already excludes .claude/memory/"
        }
    } else {
        Set-Content $gitignore "# Agent system memory (session-specific, not for git)`n.claude/memory/"
        Write-Host "  OK: Created .gitignore with .claude/memory/ exclusion"
    }

    # Handle CLAUDE.md
    $claudeMd = Join-Path $ProjectDir "CLAUDE.md"
    $agentDocSrc = Join-Path $ScriptDir "project-level\CLAUDE-AGENT-SYSTEM.md"
    if (Test-Path $claudeMd) {
        $content = Get-Content $claudeMd -Raw
        if ($content -notmatch "Agent System") {
            Add-Content $claudeMd "`n$(Get-Content $agentDocSrc -Raw)"
            Write-Host "  OK: Appended agent system docs to CLAUDE.md"
        } else {
            Write-Host "  INFO: CLAUDE.md already has agent system reference"
        }
    } else {
        Copy-Item $agentDocSrc $claudeMd
        Write-Host "  OK: Created CLAUDE.md with agent system docs"
    }

    Write-Host ""
    Write-Host "  Project bootstrapped successfully!"
} else {
    Write-Host "[2/3] Skipping project bootstrap (use -Project to bootstrap current directory)"
}

Write-Host ""
Write-Host "[3/3] Done!"
Write-Host ""
Write-Host "============================================"
Write-Host "  INSTALLATION COMPLETE"
Write-Host "============================================"
Write-Host ""
Write-Host "  Conductor installed at: $ConductorDest"
if ($Project) {
    Write-Host "  Project agents at:      $ProjectDir\.claude\sub-agents\"
    Write-Host "  Memory at:              $ProjectDir\.claude\memory\"
    Write-Host "  Hooks at:               $ProjectDir\.claude\hooks\"
}
Write-Host ""
Write-Host "  To use: just say 'use the conductor to [task]' in Claude Code"
Write-Host ""
Write-Host "  The conductor will automatically:"
Write-Host "    - Bootstrap new projects on first run"
Write-Host "    - Resume work-in-progress from memory"
Write-Host "    - Delegate to specialized agents"
Write-Host "    - Enforce quality through hooks"
Write-Host "    - Learn from this project over time"
Write-Host ""
Write-Host "============================================"
