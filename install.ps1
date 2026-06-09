# Agent Skills Installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.ps1 | iex
# Or:    .\install.ps1  (from a local clone)
# Flags: --global (default), --local

$REPO = "https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main"
$ErrorActionPreference = "Stop"

function Write-Header($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "  " -NoNewline; Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " $msg" }
function Write-Info($msg)   { Write-Host "  " -NoNewline; Write-Host " -> " -ForegroundColor Yellow -NoNewline; Write-Host " $msg" }

Write-Header "Agent Skills Installer"
Write-Host "  github.com/OlixIgnacious/agent-skills"

# ── Scope ──────────────────────────────────────────────────────────────────────
$Scope = "global"
if ($args -contains "--local") { $Scope = "local" }

if ($Scope -eq "global") {
    $ClaudeDest = Join-Path $env:USERPROFILE ".claude"
    Write-Host "`nScope: global — available in every project"
    Write-Host "Installing into: $ClaudeDest"
} else {
    $ClaudeDest = Join-Path (Get-Location) ".claude"
    Write-Host "`nScope: local — this project only"
    Write-Host "Installing into: $ClaudeDest"
}
$ConfigDest = Get-Location

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
        "kaggle-grandmaster","kaggle-adversarial-validation","kaggle-validation",
        "kaggle-eda","kaggle-baselines","kaggle-target-transform","kaggle-optuna",
        "kaggle-feature-engineering","kaggle-hill-climbing","kaggle-stacking",
        "kaggle-pseudo-labeling","kaggle-extra-training"
    )
    $Agents = @("kaggle-grandmaster","kaggle-feature-engineer","kaggle-ensemble-builder")

    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                foreach ($skill in $Skills) {
                    Fetch "$REPO/skills/$skill/SKILL.md" "$ClaudeDest\skills\$skill\SKILL.md"
                }
                Write-Ok "$($Skills.Count) Kaggle skills -> $ClaudeDest\skills\"
                foreach ($agent in $Agents) {
                    Fetch "$REPO/agents/kaggle/$agent.md" "$ClaudeDest\agents\$agent.md"
                }
                Write-Ok "$($Agents.Count) Kaggle agents -> $ClaudeDest\agents\"
                Fetch "$REPO/domains/kaggle/ORCHESTRATION.md" "$ClaudeDest\kaggle\ORCHESTRATION.md"
                Write-Ok "ORCHESTRATION.md -> $ClaudeDest\kaggle\"
            }
            "antigravity" {
                Write-Info "Kaggle skills are Claude Code format — AGENTS.md stub created"
                Fetch "$REPO/domains/kaggle/ORCHESTRATION.md" "$ConfigDest\KAGGLE_ORCHESTRATION.md"
                @"
# Kaggle Competition Workflow
# Full skills + agents available for Claude Code: github.com/OlixIgnacious/agent-skills

## Agents
- kaggle-grandmaster — competition orchestrator
- kaggle-feature-engineer — feature engineering specialist
- kaggle-ensemble-builder — ensemble and blending specialist

## Workflow
Phase 1: Adversarial validation -> Fold strategy -> EDA
Phase 2: Diverse baselines -> Target transforms -> Optuna -> Feature engineering
Phase 3: Hill climbing -> Stacking
Phase 4: Pseudo-labeling -> Seed ensemble -> Full-data retrain -> Submit
"@ | Set-Content "$ConfigDest\AGENTS.md"
                Write-Ok "AGENTS.md + KAGGLE_ORCHESTRATION.md -> $ConfigDest\"
            }
            "copilot" { Write-Info "Kaggle domain has no Copilot config" }
        }
    }
}

# ── Install SDLC ───────────────────────────────────────────────────────────────
function Install-Sdlc {
    Write-Header "Installing SDLC domain"
    $SdlcSkills = @("sdlc-biz-to-tech","sdlc-architectural-review","sdlc-feature-dev","sdlc-code-review")
    $SdlcAgents = @(
        "biz-to-tech-orchestrator","architectural-review-orchestrator",
        "feature-dev-orchestrator","code-review-orchestrator",
        "requirements-analyst","code-archaeologist","api-designer",
        "test-engineer","technical-writer",
        "software-engineer","database-internals","devops-sre","cybersecurity",
        "linux-debugging","system-design","competitive-programming","ml-research"
    )

    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                Fetch "$REPO/domains/sdlc/CLAUDE.md" "$ConfigDest\CLAUDE.md"
                Fetch "$REPO/domains/sdlc/AGENTS.md"  "$ConfigDest\AGENTS.md"
                Write-Ok "CLAUDE.md + AGENTS.md -> $ConfigDest\"
                foreach ($skill in $SdlcSkills) {
                    Fetch "$REPO/skills/$skill/SKILL.md" "$ClaudeDest\skills\$skill\SKILL.md"
                }
                Write-Ok "$($SdlcSkills.Count) SDLC skills -> $ClaudeDest\skills\"
                foreach ($agent in $SdlcAgents) {
                    Fetch "$REPO/agents/sdlc/$agent.md" "$ClaudeDest\agents\$agent.md"
                }
                Write-Ok "$($SdlcAgents.Count) SDLC agents -> $ClaudeDest\agents\"
            }
            "antigravity" {
                Fetch "$REPO/domains/sdlc/AGENTS.md" "$ConfigDest\AGENTS.md"
                Fetch "$REPO/domains/sdlc/GEMINI.md" "$ConfigDest\GEMINI.md"
                Write-Ok "AGENTS.md + GEMINI.md -> $ConfigDest\"
            }
            "copilot" {
                Fetch "$REPO/domains/sdlc/copilot-instructions.md" "$ConfigDest\.github\copilot-instructions.md"
                Write-Ok ".github\copilot-instructions.md -> $ConfigDest\"
            }
        }
    }
}

# ── Install Research ───────────────────────────────────────────────────────────
function Install-Research {
    Write-Header "Installing Research domain"
    $ResearchAgents = @("literature-reviewer","venue-advisor")

    foreach ($tool in $Tools) {
        switch ($tool) {
            "claude" {
                Fetch "$REPO/skills/research-paper/SKILL.md" "$ClaudeDest\skills\research-paper\SKILL.md"
                Write-Ok "research-paper skill -> $ClaudeDest\skills\"
                foreach ($agent in $ResearchAgents) {
                    Fetch "$REPO/agents/research/$agent.md" "$ClaudeDest\agents\$agent.md"
                }
                Write-Ok "$($ResearchAgents.Count) Research agents -> $ClaudeDest\agents\"
                Fetch "$REPO/domains/research/AGENTS.md" "$ConfigDest\AGENTS.md"
                Write-Ok "AGENTS.md -> $ConfigDest\"
            }
            "antigravity" {
                Fetch "$REPO/domains/research/AGENTS.md" "$ConfigDest\AGENTS.md"
                Fetch "$REPO/domains/research/GEMINI.md" "$ConfigDest\GEMINI.md"
                Write-Ok "AGENTS.md + GEMINI.md -> $ConfigDest\"
            }
            "copilot" { Write-Info "Research domain has no Copilot config" }
        }
    }
}

# ── Meta skill ─────────────────────────────────────────────────────────────────
function Install-Meta {
    if ($Tools -contains "claude") {
        Fetch "$REPO/skills/skill-creator/SKILL.md" "$ClaudeDest\skills\skill-creator\SKILL.md"
        Write-Ok "skill-creator -> $ClaudeDest\skills\"
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
