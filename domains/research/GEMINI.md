# Research Paper Writing — Antigravity Configuration
<!-- Antigravity (agy) reads this file. Rules here override AGENTS.md for Antigravity sessions. -->

## Model and Effort

All agents: Gemini 3.5 Pro at maximum effort. Literature search and venue analysis require deep reasoning — do not downgrade to Flash for these tasks.

## Subagent Orchestration

Antigravity supports parallel subagent execution. Use it:

- **research-paper startup**: spawn `venue-advisor` and `literature-reviewer` in parallel — venue identification and literature search are independent and both require extensive web fetching.
- **literature-reviewer**: run Layer 1 (seed search), Layer 2 (citation chaining), and Layer 3 (venue sweep) searches concurrently across multiple sources.

## Agy CLI Invocation

```bash
# Full paper writing pipeline
agy "Help me write a research paper on [topic] for [venue]"

# Venue selection only
agy --agent venue-advisor "Find the best venue for a paper on [topic] in [field]"

# Literature search only
agy --agent literature-reviewer "Search related work on [topic], find the gap"

# Writing a specific section
agy "Write the related work section for my paper on [topic], based on these papers: [list]"

# Formatting for a specific venue
agy "Format my paper for NeurIPS 2026 submission requirements"
```

## Mission Control Setup

| Task name | Agent | Trigger |
|-----------|-------|---------|
| `find-venue` | venue-advisor | Topic + field identified, venue unknown |
| `lit-review` | literature-reviewer | Topic locked, need related work map |
| `write-paper` | research-paper | Venue + gap established, ready to write |

## Background Scheduling

Use Antigravity's background scheduling for:
- Weekly arXiv sweep for new papers on your topic (concurrent work monitoring)
- Deadline reminders fetched from the venue's call for papers

## Web Fetching Notes

- Always fetch from official publisher pages, not third-party summaries.
- arXiv abstract pages: `https://arxiv.org/abs/<id>` (not PDF directly for initial scan)
- Semantic Scholar API: `https://api.semanticscholar.org/graph/v1/paper/search?query=<topic>`
- For paywalled journals: fetch the abstract + author guidelines page (not the full paper)
