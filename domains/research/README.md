# Domain: Research Paper Writing

End-to-end research paper writing support — from finding the right venue, to searching related work, to writing and formatting for any journal or publisher.

## Files

| File | Purpose |
|------|---------|
| `skills/research-paper/SKILL.md` | Main skill — invoke with `/research-paper` |
| `agents/research/literature-reviewer.md` | Deep literature search and gap analysis |
| `agents/research/venue-advisor.md` | Venue identification, ranking, and guideline fetch |

## Workflow

```
/research-paper
    ├── venue-advisor        ← find and rank target journals/conferences
    ├── literature-reviewer  ← search papers, build annotated bibliography, identify gap
    ├── [writing phases]     ← section-by-section guided writing
    └── [submission checklist] ← venue-specific formatting and submission steps
```

## Supported Publishers and Venues

| Category | Venues |
|----------|--------|
| ML / AI conferences | NeurIPS, ICML, ICLR, AAAI, IJCAI |
| NLP | ACL, EMNLP, NAACL |
| Computer Vision | CVPR, ICCV, ECCV |
| Systems | OSDI, SOSP, USENIX ATC |
| Security | IEEE S&P, CCS, USENIX Security |
| IEEE journals | TPAMI, TNNLS, TMM, Access |
| ACM journals | JACM, TOCS, TACL |
| Nature family | Nature, Nature MI, Nature Methods |
| Springer | LNCS series, many journals |
| Elsevier | ScienceDirect journals |
| Preprints | arXiv, bioRxiv, SSRN |

## Invocation

```
/research-paper
```

Then describe your topic, contribution type, and target venue (or let the skill recommend one).
