# Research Paper Writing — Agent Rules
<!-- Universal format: read by Antigravity (agy), Cursor, and Claude Code -->

## What This Does

This workspace supports end-to-end academic research paper writing. Agents search the live web for related work and publisher guidelines, then assist writing and formatting papers for any journal or conference.

## Agent Roles

### Skill Entry Point
- **research-paper** — primary skill; invoke with `/research-paper`. Orchestrates the full pipeline from venue selection through submission.

### Specialist Agents
- **literature-reviewer** — deep literature search across arXiv, Semantic Scholar, and venue proceedings. Produces annotated bibliography and gap analysis.
- **venue-advisor** — identifies and ranks target journals/conferences. Fetches live acceptance rates, impact factors, and formatting guidelines.

## Workflow

```
/research-paper
    ├── venue-advisor        ← identify and rank target venues (live web search)
    ├── literature-reviewer  ← search related work, identify the gap
    ├── [writing phases]     ← section-by-section guided writing
    └── [submission prep]    ← formatting, checklist, submission system
```

## Workflow Rules

1. **Venue before writing.** Formatting requirements, page limits, and blind review rules must be established before drafting begins — changing them mid-draft is expensive.
2. **Literature before contribution.** The contribution statement can only be written after related work is mapped — the gap defines the contribution.
3. **Fetch guidelines live.** Publisher guidelines change. Always fetch the current author instructions page, not a cached version.
4. **Anonymize for blind review.** If the venue uses double-blind review, remove all author names, affiliations, and identifying self-citations before submission.

## Communication Standards

- Lead with the metric or result, not the method.
- Every recommendation cites the source (paper title/URL or guideline URL).
- Flag concurrent work (papers from the last 6 months on the same topic) explicitly — reviewers will notice if they're missing.

## Supported Venues (guidelines fetched live)

IEEE, ACM, Nature family, Springer (LNCS), Elsevier, NeurIPS, ICML, ICLR, ACL/EMNLP/NAACL, CVPR/ICCV/ECCV, AAAI, arXiv and more.

## Codebase Context

<!-- Customize for your research project -->
- Field: [e.g., machine learning, bioinformatics, systems]
- Target venue: [journal or conference name]
- Contribution type: [method / survey / empirical / system / theory]
- Existing draft: [yes/no — location if yes]
- Deadline: [date]
