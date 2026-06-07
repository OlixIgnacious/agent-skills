# Agent Skills Installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.ps1 | iex
# Or:    .\install.ps1  (from a local clone)
# Requires: PowerShell 5.1+ (built into Windows 10/11)

$REPO = "https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main"
$ErrorActionPreference = "Stop"

function Write-Header($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "  " -NoNewline; Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " $msg" }
function Write-Info($msg)   { Write-Host "  " -NoNewline; Write-Host " -> " -ForegroundColor Yellow -NoNewline; Write-Host " $msg" }

Write-Header "Agent Skills Installer"
Write-Host "  github.com/OlixIgnacious/agent-skills"

# ── Destination ────────────────────────────────────────────────────────────────
$Dest = if ($args[0]) { $args[0] } else { "." }
$Dest = (Resolve-Path $Dest -ErrorAction SilentlyContinue)?.Path ?? $Dest
if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest | Out-Null }
Write-Host "`nInstalling into: $Dest"

# ── Domain selection ───────────────────────────────────────────────────────────
Write-Header "Select domain"
Write-Host "  1) Kaggle   — competitive ML (12 skills, 3 agents)"
Write-Host "  2) SDLC     — software development lifecycle (17 agents, 4 skills)"
Write-Host "  3) Research — paper writing, literature search, venue selection (1 skill, 2 agents)"
Write-Host "  4) All"
$domainInput = Read-Host "  Choice [1/2/3/4]"

$Domains = switch ($domainInput) {
    "1" { @("kaggle") }
    "2" { @("sdlc") }
    "3" { @("research") }
    "4" { @("kaggle", "sdlc", "research") }
    default { Write-Host "  Defaulting to All."; @("kaggle", "sdlc", "research") }
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

# ── Install SDLC ───────────────────────────────────────────────────────────────
function Install-Sdlc {
    Write-Header "Installing SDLC domain"
    $SdlcSkills = @("sdlc-biz-to-tech", "sdlc-architectural-review", "sdlc-feature-dev", "sdlc-code-review")
    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                Fetch "$REPO/domains/sdlc/CLAUDE.md" "$Dest\CLAUDE.md"
                Fetch "$REPO/domains/sdlc/AGENTS.md"  "$Dest\AGENTS.md"
                Write-Ok "CLAUDE.md + AGENTS.md -> $Dest\"
                foreach ($skill in $SdlcSkills) {
                    Fetch "$REPO/skills/$skill/SKILL.md" "$Dest\.claude\skills\$skill\SKILL.md"
                }
                Write-Ok "$($SdlcSkills.Count) SDLC skills -> $Dest\.claude\skills\"
            }
            "antigravity" {
                Fetch "$REPO/domains/sdlc/AGENTS.md" "$Dest\AGENTS.md"
                Fetch "$REPO/domains/sdlc/GEMINI.md" "$Dest\GEMINI.md"
                Write-Ok "AGENTS.md + GEMINI.md -> $Dest\"
            }
            "copilot" {
                Fetch "$REPO/domains/sdlc/copilot-instructions.md" "$Dest\.github\copilot-instructions.md"
                Write-Ok ".github\copilot-instructions.md -> $Dest\"
            }
        }
    }
}

# ── Install Research ───────────────────────────────────────────────────────────
function Install-Research {
    Write-Header "Installing Research domain"
    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                Fetch "$REPO/skills/research-paper/SKILL.md" "$Dest\.claude\skills\research-paper\SKILL.md"
                Write-Ok "research-paper skill -> $Dest\.claude\skills\"
                Fetch "$REPO/domains/research/AGENTS.md" "$Dest\AGENTS.md"
                Write-Ok "AGENTS.md -> $Dest\"
            }
            "antigravity" {
                Fetch "$REPO/domains/research/AGENTS.md" "$Dest\AGENTS.md"
                Fetch "$REPO/domains/research/GEMINI.md" "$Dest\GEMINI.md"
                Write-Ok "AGENTS.md + GEMINI.md -> $Dest\"
            }
            "copilot" {
                Write-Info "Research domain has no Copilot config (skill is agentic, not inline suggestions)"
            }
        }
    }
}

# ── Install meta skill (always for Claude) ─────────────────────────────────────
function Install-Meta {
    if ($Tools -contains "claude") {
        Fetch "$REPO/skills/skill-creator/SKILL.md" "$Dest\.claude\skills\skill-creator\SKILL.md"
        Write-Ok "skill-creator -> $Dest\.claude\skills\"
    }
}

# ── Run ────────────────────────────────────────────────────────────────────────
foreach ($domain in $Domains) {
    switch ($domain) {
        "kaggle"   { Install-Kaggle }
        "sdlc"     { Install-Sdlc }
        "research" { Install-Research }
    }
}

Install-Meta

# ── Next steps ─────────────────────────────────────────────────────────────────
Write-Header "Done"

foreach ($domain in $Domains) {
    switch ($domain) {
        "sdlc" {
            Write-Host "`n  SDLC — next step:" -ForegroundColor White
            Write-Host "  Edit the 'Codebase Context' section in CLAUDE.md / AGENTS.md"
            Write-Host "  with your stack, conventions, and constraints."
            Write-Host "  Then run: /sdlc-biz-to-tech"
        }
        "kaggle" {
            Write-Host "`n  Kaggle — next step:" -ForegroundColor White
            Write-Host "  Start a Claude Code session and run: /kaggle-grandmaster"
        }
        "research" {
            Write-Host "`n  Research — next step:" -ForegroundColor White
            Write-Host "  Start a Claude Code session and run: /research-paper"
        }
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
