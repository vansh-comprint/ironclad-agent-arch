# ============================================================================
# Conductor — Multi-Agent Orchestration for Claude Code
# Install Script (Windows PowerShell)
#
# Usage:
#   .\install.ps1              Install conductor + enable agent teams
#   .\install.ps1 -Project     Install + bootstrap current project
#   .\install.ps1 -Uninstall   Remove conductor
# ============================================================================

param(
    [switch]$Project,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$AgentsDir = Join-Path $ClaudeHome "agents"
$TemplateSrc = Join-Path $ScriptDir "project-level\.claude"
$TemplateDest = Join-Path $ClaudeHome "ironclad-agents\project-level\.claude"
$SettingsFile = Join-Path $ClaudeHome "settings.json"

Write-Host ""
Write-Host "Conductor - Multi-Agent Orchestration for Claude Code" -ForegroundColor White
Write-Host "Background & parallel sub-agents with project-scoped memory"
Write-Host "======================================================"
Write-Host ""

# --- Uninstall ---
if ($Uninstall) {
    $conductor = Join-Path $AgentsDir "conductor.md"
    if (Test-Path $conductor) {
        Remove-Item $conductor -Force
        Write-Host " + Removed conductor" -ForegroundColor Green
    } else {
        Write-Host " ! Conductor not found" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host " ! Template store not removed. To fully remove:" -ForegroundColor Yellow
    Write-Host "   Remove-Item -Recurse $ClaudeHome\ironclad-agents"
    exit 0
}

# --- Step 1: Install conductor ---
Write-Host ">>> Installing conductor agent (user-level)..." -ForegroundColor Cyan

if (-not (Test-Path $AgentsDir)) {
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
}

$ConductorDest = Join-Path $AgentsDir "conductor.md"
if (Test-Path $ConductorDest) {
    Copy-Item $ConductorDest "$ConductorDest.backup" -Force
    Write-Host " ! Backed up existing conductor.md" -ForegroundColor Yellow
}

$ConductorSrc = Join-Path $ScriptDir "user-level\.claude\sub-agents\conductor.md"
if (-not (Test-Path $ConductorSrc)) {
    $ConductorSrc = Join-Path $ScriptDir "conductor.md"
}
if (Test-Path $ConductorSrc) {
    Copy-Item $ConductorSrc $ConductorDest -Force
    Write-Host " + Conductor installed at ~/.claude/agents/conductor.md" -ForegroundColor Green
} else {
    Write-Host " x conductor.md not found in repo" -ForegroundColor Red
    exit 1
}

# --- Step 2: Install templates ---
Write-Host ">>> Installing project templates..." -ForegroundColor Cyan

# Skip if running from inside the target
$srcNorm = (Resolve-Path $ScriptDir -ErrorAction SilentlyContinue).Path
$destNorm = (Resolve-Path (Join-Path $ClaudeHome "ironclad-agents") -ErrorAction SilentlyContinue).Path

if ($srcNorm -eq $destNorm) {
    Write-Host " + Templates already in place" -ForegroundColor Green
} else {
    $templateDirs = @(
        "sub-agents", "memory\agent-logs", "hooks", "skills", "checklists"
    )
    foreach ($dir in $templateDirs) {
        $full = Join-Path $TemplateDest $dir
        if (-not (Test-Path $full)) {
            New-Item -ItemType Directory -Path $full -Force | Out-Null
        }
    }

    # Copy all template files
    if (Test-Path "$TemplateSrc\sub-agents") {
        Copy-Item "$TemplateSrc\sub-agents\*.md" (Join-Path $TemplateDest "sub-agents") -Force
    }
    foreach ($f in @("architecture.md", "decisions.md", "failures.md", "wip.md")) {
        $s = Join-Path "$TemplateSrc\memory" $f
        if (Test-Path $s) { Copy-Item $s (Join-Path "$TemplateDest\memory" $f) -Force }
    }
    if (Test-Path "$TemplateSrc\memory\agent-logs") {
        Copy-Item "$TemplateSrc\memory\agent-logs\*.md" (Join-Path $TemplateDest "memory\agent-logs") -Force
    }
    if (Test-Path "$TemplateSrc\hooks") {
        Copy-Item "$TemplateSrc\hooks\*" (Join-Path $TemplateDest "hooks") -Force
    }
    if (Test-Path "$TemplateSrc\skills") {
        Copy-Item "$TemplateSrc\skills\*.md" (Join-Path $TemplateDest "skills") -Force
    }
    if (Test-Path "$TemplateSrc\checklists") {
        Copy-Item "$TemplateSrc\checklists\*.md" (Join-Path $TemplateDest "checklists") -Force
    }

    $agentCount = (Get-ChildItem "$TemplateDest\sub-agents\*.md" -ErrorAction SilentlyContinue).Count
    Write-Host " + Installed $agentCount agent templates + memory + hooks + skills" -ForegroundColor Green
}

# --- Step 3: Update settings.json ---
Write-Host ">>> Configuring Claude Code settings..." -ForegroundColor Cyan

if (-not (Test-Path $SettingsFile)) {
    @{
        alwaysThinkingEnabled = $true
        env = @{
            CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
        }
    } | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
    Write-Host " + Created settings.json" -ForegroundColor Green
} else {
    try {
        $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        $changed = $false

        if (-not $settings.alwaysThinkingEnabled) {
            $settings | Add-Member -NotePropertyName "alwaysThinkingEnabled" -NotePropertyValue $true -Force
            $changed = $true
        }

        if (-not $settings.env) {
            $settings | Add-Member -NotePropertyName "env" -NotePropertyValue @{} -Force
        }

        if ($settings.env -is [PSCustomObject]) {
            if ($settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -ne "1") {
                $settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force
                $changed = $true
            }
        }

        if ($changed) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
            Write-Host " + Agent teams + extended thinking enabled" -ForegroundColor Green
        } else {
            Write-Host " + Settings already configured" -ForegroundColor Green
        }
    } catch {
        Write-Host " ! Could not update settings.json. Add manually:" -ForegroundColor Yellow
        Write-Host '   "alwaysThinkingEnabled": true,'
        Write-Host '   "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }'
    }
}

# --- Step 4 (optional): Bootstrap project ---
if ($Project) {
    Write-Host ""
    Write-Host ">>> Bootstrapping project at $(Get-Location)..." -ForegroundColor Cyan

    $src = $TemplateDest
    if (-not (Test-Path "$src\sub-agents")) { $src = $TemplateSrc }

    # Create directories
    foreach ($dir in @(".claude\agents", ".claude\memory\agent-logs", ".claude\hooks", ".claude\skills", ".claude\checklists")) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }

    # Agents (sub-agents/ → agents/ rename)
    $count = 0
    Get-ChildItem "$src\sub-agents\*.md" | ForEach-Object {
        $dest = Join-Path ".claude\agents" $_.Name
        if (-not (Test-Path $dest)) {
            Copy-Item $_.FullName $dest
            $count++
        }
    }
    Write-Host " + $count agents installed to .claude/agents/" -ForegroundColor Green

    # Memory templates
    foreach ($f in @("architecture.md", "decisions.md", "failures.md", "wip.md")) {
        $s = Join-Path "$src\memory" $f
        $d = Join-Path ".claude\memory" $f
        if ((Test-Path $s) -and -not (Test-Path $d)) { Copy-Item $s $d }
    }
    Get-ChildItem "$src\memory\agent-logs\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $d = Join-Path ".claude\memory\agent-logs" $_.Name
        if (-not (Test-Path $d)) { Copy-Item $_.FullName $d }
    }
    Write-Host " + Memory templates created" -ForegroundColor Green

    # Hooks
    Get-ChildItem "$src\hooks\*" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $d = Join-Path ".claude\hooks" $_.Name
        if (-not (Test-Path $d)) { Copy-Item $_.FullName $d }
    }
    Write-Host " + Hooks installed" -ForegroundColor Green

    # Skills + checklists
    Get-ChildItem "$src\skills\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $d = Join-Path ".claude\skills" $_.Name
        if (-not (Test-Path $d)) { Copy-Item $_.FullName $d }
    }
    Get-ChildItem "$src\checklists\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $d = Join-Path ".claude\checklists" $_.Name
        if (-not (Test-Path $d)) { Copy-Item $_.FullName $d }
    }
    Write-Host " + Skills + checklists installed" -ForegroundColor Green

    # .gitignore
    if (Test-Path ".gitignore") {
        $content = Get-Content ".gitignore" -Raw
        if ($content -notmatch "\.claude/memory/") {
            Add-Content ".gitignore" "`n# Agent memory (local, not shared)`n.claude/memory/"
            Write-Host " + Added .claude/memory/ to .gitignore" -ForegroundColor Green
        }
    }

    Write-Host " + Project ready" -ForegroundColor Green
}

# --- Done ---
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "  Conductor:  ~/.claude/agents/conductor.md"
Write-Host "  Templates:  ~/.claude/ironclad-agents/"
Write-Host "  Settings:   Agent teams + extended thinking enabled"
Write-Host ""
Write-Host "  In Claude Code, say:"
Write-Host '    "Use the conductor to [your task]"'
Write-Host ""
Write-Host "  The conductor auto-bootstraps any new project on first run."
Write-Host "  Or manually: .\install.ps1 -Project (from project directory)"
Write-Host ""
Write-Host "  Restart Claude Code to pick up changes." -ForegroundColor Yellow
Write-Host ""
