---
name: research-paper
description: End-to-end research paper writing skill. Searches the web for top papers in your area, fetches journal/publisher formatting guidelines, identifies related work, and guides writing from abstract to references. Adapts to IEEE, ACM, Nature, Springer, Elsevier, NeurIPS, ICML, and more.
allowed-tools: Read Write Edit Bash WebSearch WebFetch
effort: xhigh
---

# Skill: Research Paper Writing

An agentic research assistant that helps you plan, research, and write papers targeted at specific journals or conferences — with correct formatting from the start.

---

## Step 0 — Establish Context

Before anything else, determine:

1. **Topic:** What is the paper about? (one paragraph summary)
2. **Contribution type:** What is the primary claim?
   - Novel method / algorithm
   - Empirical study / benchmark
   - Survey / literature review
   - System / tool paper
   - Theory / proof
   - Replication / negative result
3. **Target venue:** Journal, conference, or preprint (arXiv)?
   - If known: name it (e.g., "IEEE TPAMI", "NeurIPS 2026", "Nature Machine Intelligence")
   - If unknown: describe the field and audience — the skill will recommend venues
4. **Stage:** Starting from scratch? Have a draft? Have results but no paper?
5. **Page/word limit:** If known

---

## Step 1 — Identify and Validate Target Venue

### If venue is known — fetch live guidelines

```
WebSearch: "<venue name> author guidelines 2026"
WebSearch: "<venue name> submission format LaTeX template"
WebFetch: [official author guidelines URL]
```

Extract and record:
- Page / word limit
- Column format (single / double)
- Required sections
- Citation style (IEEE numbered, APA, ACM, Chicago, Vancouver)
- Abstract word limit
- Figure/table limits
- Blind review requirements (anonymization rules)
- Supplementary material policy
- LaTeX class / Word template URL

### If venue is unknown — recommend based on field

Search for top venues by field:

```
WebSearch: "top journals conferences <field> 2025 2026 impact factor"
WebSearch: "best venue to publish <topic> machine learning / systems / biology / etc."
```

**Common venues by domain:**

| Domain | Top Conferences | Top Journals |
|--------|----------------|--------------|
| ML / AI | NeurIPS, ICML, ICLR, AAAI, IJCAI | JMLR, TPAMI, Nature MI, AIJ |
| NLP | ACL, EMNLP, NAACL, COLING | CL, TACL |
| CV | CVPR, ICCV, ECCV | IJCV, TIP, TPAMI |
| Systems | OSDI, SOSP, USENIX ATC, EuroSys | TOCS, CACM |
| Security | IEEE S&P, CCS, USENIX Security, NDSS | TOPS, JCS |
| Bioinformatics | ISMB, RECOMB | Bioinformatics, PLOS Comp Bio, NAR |
| Medicine | NEJM, Lancet, JAMA, BMJ | Nature Medicine, Cell |
| Physics | PRL, PRX | Nature Physics, Science |
| General / Preprint | — | arXiv, SSRN, bioRxiv |

Recommend 2–3 venues ranked by fit, impact, and realistic acceptance rate for the contribution.

---

## Step 2 — Literature Search

### Find seminal and recent papers

```
WebSearch: "<topic> survey paper site:arxiv.org OR site:semanticscholar.org"
WebSearch: "<topic> state of the art 2024 2025 2026"
WebSearch: "<method/problem> benchmark <venue>"
```

For each candidate paper, fetch the abstract and record:

```
WebFetch: https://arxiv.org/abs/<id>
```

Organize into:
- **Directly competing work** — papers that solve the same problem
- **Foundational work** — papers whose methods you build on
- **Peripheral work** — related problems or domains

### Identify the gap

After surveying:
- What does no existing paper address?
- What assumptions do prior methods make that you relax?
- What metric / benchmark / scale does your work improve on?

This gap is your **contribution statement** — the core of the paper.

---

## Step 3 — Paper Structure by Type

Adapt the structure to the contribution type:

### Method / Algorithm Paper

```
Abstract        (150–250 words)
1. Introduction
   1.1 Problem statement
   1.2 Challenges
   1.3 Contributions (bullet list)
   1.4 Paper organization
2. Related Work
3. Background / Preliminaries
4. Method
   4.1 Overview (figure + one paragraph)
   4.2 Component A
   4.3 Component B
   4.4 Theoretical analysis (if applicable)
5. Experiments
   5.1 Setup (datasets, baselines, metrics, hardware)
   5.2 Main results
   5.3 Ablation study
   5.4 Analysis / qualitative results
6. Discussion (limitations, failure cases)
7. Conclusion
References
Appendix (proofs, additional experiments, implementation details)
```

### Survey / Literature Review Paper

```
Abstract
1. Introduction (scope, methodology, organization)
2. Background
3. Taxonomy / Classification of approaches
4. Category A — deep dive
5. Category B — deep dive
6. Category C — deep dive
7. Benchmarks and Datasets
8. Open Problems and Future Directions
9. Conclusion
References
```

### System / Tool Paper

```
Abstract
1. Introduction (problem, system goals, contributions)
2. System Overview (architecture diagram)
3. Design Decisions (why each choice was made)
4. Implementation
5. Evaluation (performance, scalability, real-world usage)
6. Related Work
7. Conclusion
References
```

### Empirical / Benchmark Paper

```
Abstract
1. Introduction (what we measure and why it matters)
2. Related Work
3. Benchmark Design (tasks, metrics, collection methodology)
4. Baseline Experiments
5. Analysis (what the results reveal)
6. Limitations and Scope
7. Conclusion
References
```

---

## Step 4 — Section-by-Section Writing Guide

### Abstract
Write last. Contains exactly: problem, gap, method (one sentence each), key result (one number), implication. Never cite in the abstract. Word limit: check venue guidelines.

### Introduction
Structure as a funnel:
1. **Hook** — broad context (2–3 sentences)
2. **Problem** — specific gap (1 paragraph)
3. **Challenges** — why it's hard (1 paragraph)
4. **Existing work and its limits** (1 paragraph)
5. **Our approach** — high-level intuition, not implementation (1 paragraph)
6. **Contributions** — bullet list, claim-first format:
   - "We propose X, which achieves Y on Z benchmark."
   - "We prove that X holds under Y conditions."
   - "We release dataset X of N examples for Y task."
7. **Paper organization** — one line per section

### Related Work
Organize by theme, not chronologically. Each paragraph covers one sub-area. End each paragraph with how your work differs. Never criticize — describe what each work does and what it doesn't address that you do.

### Method
Start with a figure showing the full pipeline. Write top-down: overview → components. Define all notation at first use. Every design choice should be motivated ("We use X rather than Y because...").

### Experiments
- **Setup first:** reader must be able to reproduce without reading your code.
- **Main results table:** your method vs all baselines, all metrics, bold best, underline second-best.
- **Ablation:** remove one component at a time. Shows each component contributes independently.
- **Analysis:** qualitative examples, error analysis, scaling behavior.

### Conclusion
3–5 sentences: what we did, what we found, broader implications. One sentence on limitations. One sentence on future work. Do not introduce new information.

---

## Step 5 — Formatting by Publisher

Fetch live formatting instructions for the target venue, then apply:

### IEEE
```
WebFetch: https://www.ieee.org/conferences/publishing/templates.html
```
- Two-column, 10pt Times New Roman
- `\documentclass[conference]{IEEEtran}` or `\documentclass[journal]{IEEEtran}`
- References: IEEE numbered `[1]`, sorted by appearance
- Figures: `\begin{figure}[!t]`
- No colored links in final submission

### ACM
```
WebFetch: https://www.acm.org/publications/proceedings-template
```
- `\documentclass[sigconf]{acmart}` (conference) or `\documentclass[acmsmall]{acmart}` (journal)
- References: ACM numeric or author-year depending on venue
- CCS concepts required: fetch taxonomy at `https://dl.acm.org/ccs`
- Rights/permissions block required

### Nature Family
```
WebSearch: "Nature <journal name> author instructions submission guidelines"
WebFetch: [journal-specific author instructions page]
```
- Single column, 12pt
- Strict section names for research articles (Introduction, Results, Discussion, Methods)
- Methods after Discussion, not before Results
- References: numbered, Vancouver style
- Figures: separate files, minimum 300 DPI for print
- Word limits vary by article type: Research Article ~3000w body, Letter ~1500w

### Springer (LNCS — common for CS conferences)
```
WebFetch: https://www.springer.com/gp/computer-science/lncs/conference-proceedings-guidelines
```
- `\documentclass[runningheads]{llncs}`
- Page limit enforced (usually 15–16 pages)
- References: Springer numbered, `\bibliographystyle{splncs04}`

### Elsevier
```
WebSearch: "<journal name> Elsevier guide for authors"
WebFetch: [Elsevier journal's Guide for Authors page]
```
- LaTeX: `\documentclass{elsarticle}`
- Highlights required (3–5 bullet points, max 85 chars each)
- Graphical abstract required for most journals
- References: journal-specific style (check the Guide for Authors)

### NeurIPS / ICML / ICLR
```
WebSearch: "NeurIPS 2026 paper format LaTeX template"  # use current year
WebFetch: [official call for papers or style file link]
```
- Anonymous submission: remove all author info, acknowledgments, and identifying citations
- `\usepackage{neurips_2026}` (or `icml2026`, `iclr2026`)
- 9 pages content + unlimited references for NeurIPS/ICML
- Checklist required (NeurIPS): reproducibility, broader impacts, limitations

### arXiv (preprint)
- No enforced format — use the target journal's template
- Submit source `.tex` + figures
- Choose correct category: cs.LG, cs.CL, cs.CV, stat.ML, etc.
- Add `\arxiv{XXXX.XXXXX}` comment once uploaded

---

## Step 6 — Quality Checklist

Before submission, verify:

### Content
- [ ] Every claim is supported by a citation, experiment, or proof
- [ ] Contribution bullets are falsifiable — each claims a specific, measurable improvement
- [ ] Ablation confirms each component contributes independently
- [ ] Limitations section is honest and specific
- [ ] Abstract matches the paper (no claims not in the body)

### Writing
- [ ] No paragraph longer than 8 sentences
- [ ] Every figure and table is referenced in the text before it appears
- [ ] Every figure has a caption that stands alone (readable without the text)
- [ ] No first-person singular ("I") in multi-author papers — use "we"
- [ ] Consistent tense: past tense for what you did, present for what the paper does

### Formatting
- [ ] Page limit respected (count carefully — figures and references count)
- [ ] Anonymization complete for blind submissions (author names, affiliations, self-citations as "[ANON]")
- [ ] LaTeX compiles without errors or warnings
- [ ] Figures are legible in grayscale (some reviewers print in black and white)
- [ ] All URLs are live and resolve correctly
- [ ] Supplementary material referenced from the main paper

### Citations
- [ ] All cited papers are from the correct venue/year (check DOI)
- [ ] No broken BibTeX entries (missing fields, duplicate keys)
- [ ] Self-citations are not excessive and are anonymized if blind review

---

## Step 7 — Submission Checklist

```
WebSearch: "<venue> submission instructions <year> deadline"
WebFetch: [submission system URL — OpenReview, CMT, HotCRP, ScholarOne, Editorial Manager]
```

- [ ] PDF generated from final LaTeX
- [ ] Supplementary zip prepared (code, data, appendix)
- [ ] Author list and affiliations finalized and match the submission system
- [ ] Abstract in submission system matches paper abstract exactly
- [ ] Conflict of interest declared
- [ ] Appropriate subject areas / topics selected
- [ ] Preferred reviewers (if allowed) listed
- [ ] Suggested reviewers to exclude (if allowed)
- [ ] Submission confirmation email received

---

## Output

By the end of this skill session:
- `paper.tex` — main LaTeX file following venue format
- `paper.bib` — BibTeX references
- `figures/` — all figure files at correct resolution
- `paper.pdf` — compiled output
- `submission-checklist.md` — venue-specific checklist with deadlines
