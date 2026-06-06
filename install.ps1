# Agent Skills Installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.ps1 | iex
# Or:    .\install.ps1  (from a local clone)
# Requires: PowerShell 5.1+ (built into Windows 10/11)

$REPO = "https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main"
$ErrorActionPreference = "Stop"

function Write-Header($msg) {
    Write-Host "`n$msg" -ForegroundColor Cyan -NoNewline
    Write-Host ""
}
function Write-Ok($msg)   { Write-Host "  " -NoNewline; Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " $msg" }
function Write-Info($msg) { Write-Host "  " -NoNewline; Write-Host "  -> " -ForegroundColor Yellow -NoNewline; Write-Host " $msg" }

Write-Header "Agent Skills Installer"
Write-Host "  github.com/OlixIgnacious/agent-skills"

# ── Destination ────────────────────────────────────────────────────────────────
$Dest = if ($args[0]) { $args[0] } else { "." }
$Dest = (Resolve-Path $Dest -ErrorAction SilentlyContinue)?.Path ?? $Dest
if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest | Out-Null }
Write-Host "`nInstalling into: " -NoNewline
Write-Host $Dest -ForegroundColor White

# ── Domain selection ───────────────────────────────────────────────────────────
Write-Header "Select domain"
Write-Host "  1) Kaggle  — competitive ML (12 skills, 3 agents)"
Write-Host "  2) SDLC    — software development lifecycle (17 agents, 4 skills)"
Write-Host "  3) Both"
$domainInput = Read-Host "  Choice [1/2/3]"

$Domains = switch ($domainInput) {
    "1" { @("kaggle") }
    "2" { @("sdlc") }
    "3" { @("kaggle", "sdlc") }
    default { Write-Host "  Defaulting to Both."; @("kaggle", "sdlc") }
}

# ── Tool selection ─────────────────────────────────────────────────────────────
Write-Header "Select tools"
Write-Host "  1) Claude Code"
Write-Host "  2) Antigravity (agy)"
Write-Host "  3) GitHub Copilot"
Write-Host "  4) All"
$toolInput = Read-Host "  Choice [1/2/3/4]"

$Tools = switch ($toolInput) {
    "1" { @("claude") }
    "2" { @("antigravity") }
    "3" { @("copilot") }
    "4" { @("claude", "antigravity", "copilot") }
    default { Write-Host "  Defaulting to All."; @("claude", "antigravity", "copilot") }
}

# ── Download helper ────────────────────────────────────────────────────────────
function Fetch($Src, $Dst) {
    $dir = Split-Path $Dst -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Invoke-WebRequest -Uri $Src -OutFile $Dst -UseBasicParsing
}

# ── Install SDLC ───────────────────────────────────────────────────────────────
function Install-Sdlc {
    Write-Header "Installing SDLC domain"
    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                Fetch "$REPO/domains/sdlc/CLAUDE.md" "$Dest\CLAUDE.md"
                Fetch "$REPO/domains/sdlc/AGENTS.md"  "$Dest\AGENTS.md"
                Write-Ok "CLAUDE.md + AGENTS.md -> $Dest\"
            }
            "antigravity" {
                Fetch "$REPO/domains/sdlc/AGENTS.md" "$Dest\AGENTS.md"
                Fetch "$REPO/domains/sdlc/GEMINI.md"  "$Dest\GEMINI.md"
                Write-Ok "AGENTS.md + GEMINI.md -> $Dest\"
            }
            "copilot" {
                Fetch "$REPO/domains/sdlc/copilot-instructions.md" "$Dest\.github\copilot-instructions.md"
                Write-Ok ".github\copilot-instructions.md -> $Dest\"
            }
        }
    }
}

# ── Install Kaggle ─────────────────────────────────────────────────────────────
function Install-Kaggle {
    Write-Header "Installing Kaggle domain"
    $Skills = @(
        "kaggle-grandmaster", "kaggle-adversarial-validation", "kaggle-validation",
        "kaggle-eda", "kaggle-baselines", "kaggle-target-transform", "kaggle-optuna",
        "kaggle-feature-engineering", "kaggle-hill-climbing", "kaggle-stacking",
        "kaggle-pseudo-labeling", "kaggle-extra-training"
    )

    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                foreach ($skill in $Skills) {
                    Fetch "$REPO/skills/$skill/SKILL.md" "$Dest\.claude\skills\$skill\SKILL.md"
                }
                Write-Ok "$($Skills.Count) Kaggle skills -> $Dest\.claude\skills\"
                Fetch "$REPO/domains/kaggle/ORCHESTRATION.md" "$Dest\.claude\kaggle\ORCHESTRATION.md"
                Write-Ok "ORCHESTRATION.md -> $Dest\.claude\kaggle\"
            }
            "antigravity" {
                Write-Info "Kaggle skills are Claude Code format — AGENTS.md stub created"
                Fetch "$REPO/domains/kaggle/ORCHESTRATION.md" "$Dest\KAGGLE_ORCHESTRATION.md"
                @"
# Kaggle Competition Workflow
# Full skills available for Claude Code: /plugin install OlixIgnacious/agent-skills

## Workflow
Phase 1: Adversarial validation -> Fold strategy -> EDA
Phase 2: Diverse baselines -> Target transforms -> Optuna -> Feature engineering
Phase 3: Hill climbing -> Stacking
Phase 4: Pseudo-labeling -> Seed ensemble -> Full-data retrain -> Submit

See KAGGLE_ORCHESTRATION.md for the full phase-by-phase guide.
"@ | Set-Content "$Dest\AGENTS.md"
                Write-Ok "AGENTS.md + KAGGLE_ORCHESTRATION.md -> $Dest\"
            }
            "copilot" {
                Write-Info "Kaggle domain has no Copilot config (skills are agentic, not inline suggestions)"
            }
        }
    }
}

# ── Run ────────────────────────────────────────────────────────────────────────
foreach ($domain in $Domains) {
    switch ($domain) {
        "sdlc"   { Install-Sdlc }
        "kaggle" { Install-Kaggle }
    }
}

# ── Next steps ─────────────────────────────────────────────────────────────────
Write-Header "Done"

foreach ($domain in $Domains) {
    if ($domain -eq "sdlc") {
        Write-Host "`n  SDLC — next step:" -ForegroundColor White
        Write-Host "  Edit the 'Codebase Context' section in the installed files"
        Write-Host "  with your stack, conventions, and constraints."
    }
    if ($domain -eq "kaggle") {
        Write-Host "`n  Kaggle — next step:" -ForegroundColor White
        Write-Host "  Start a Claude Code session and run: /kaggle-grandmaster"
    }
}

foreach ($tool in $Tools) {
    switch ($tool) {
        "claude"      { Write-Host "`n  Claude Code:  " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " (in your project directory)" }
        "antigravity" { Write-Host "`n  Antigravity:  " -NoNewline; Write-Host "agy" -ForegroundColor Cyan -NoNewline; Write-Host " (in your project directory)" }
        "copilot"     { Write-Host "`n  Copilot:      Commit " -NoNewline; Write-Host ".github\copilot-instructions.md" -ForegroundColor Cyan -NoNewline; Write-Host " — auto-detected by VS Code" }
    }
}

Write-Host ""
