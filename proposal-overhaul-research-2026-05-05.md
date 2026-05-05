# Proposal Skill Overhaul: Research Report

**Date:** 2026-05-05
**Author:** Stafford
**Inputs:** 4 parallel research agents, 14 signed contracts read, 2 workgraph tasks reviewed, full skill source audited
**Working files:** `/tmp/proposal-skill-research/` (15 files, ~190KB of analysis)
**Status:** Research complete. Decisions needed from Justin before implementation.

---

## TL;DR

1. **Three things shipped in signed contracts that should not have.** Highest-stakes finding: a Hirewell Pulse SOW signed 2026-04-09 contains "Solarea Bio employees only" in its Distribution Rights clause. A leftover from a prior client's template that survived signing. Treat as contract integrity bug, not voice issue.
2. **The Powerfleet 2026-05-04 MSA is ready to be the canonical lock.** 1,383 words, 11 numbered sections, 6 per-client tokens. Five small ambiguities flagged for your decision (one is whether Jason is "Rubinstein" or "Rubenstein").
3. **The double-column bug has a verified root cause.** It is not in the canonical template. It happens when agents clone a *prior client's* docx as the base instead of `templates/sow-template.docx`. Inherited inline column directives leak into new content because the cleanup loop walks paragraphs only and misses sectPrs and tables.
4. **Most of the regex and scripts can die.** 27 deterministic-text instances audited. About 75% are kill candidates. Five legitimately defend MSA legal-text fidelity and stay.
5. **The three-agent architecture maps cleanly onto the rewriter pattern.** Quality work belongs inside Agent 1 (where prose is written), not as a fourth pass.
6. **A "Remix Proposals" voice guide is drafted.** 423 lines, ready to drop into `~/.claude/skills/voices/remix-proposals.md` after your review. Pacific Transformer Sprint 2 is the corpus's gold standard.

---

## Section 1. The canonical MSA from Powerfleet

Source: `LEADS/Powerfleet/Powerfleet_MSA & SOW_2026.05.04.docx`. Extracted, tokenized, and saved to `/tmp/proposal-skill-research/01-canonical-msa.md`.

### Stats
- **Word count (MSA only):** 1,383
- **Sections:** 11 numbered top-level (1. SERVICES through 11. DISPUTE RESOLUTION) plus preamble and signature blocks
- **MSA-to-SOW boundary:** MSA spans paragraphs 0-38, SOW begins at paragraph 39 with no separator
- **Cross-references inside the MSA to the SOW** (e.g., "as set forth in the applicable Statement of Work") appear in Sections 1, 2, 4.B, 4.D, 7.B, 8, 9.B. These stay verbatim, not tokens.

### Tokens (six per-client variables, everything else locked)
```
{{CLIENT_NAME}}              e.g., "Powerfleet, Inc."  — 3 occurrences, bold
{{CLIENT_ENTITY_TYPE}}       e.g., "a Delaware corporation"  — 1, includes article
{{CLIENT_ADDRESS}}           e.g., "123 Tice Boulevard, Suite 101..."  — 1, inline
{{EFFECTIVE_DATE}}           blank in source by convention  — 1
{{CLIENT_SIGNATORY_NAME}}    e.g., "Mike Powell"  — 1
{{CLIENT_SIGNATORY_TITLE}}   e.g., "Chief Innovation Officer"  — 1
```

### Five ambiguities flagged for your decision

These were NOT silently fixed. You decide:

1. **Jason's name spelling.** Source says `Jason Rubinstein` (with `i`). Your CLAUDE.md says `Rubenstein` (with `e`). Which is canonical? Lock the canonical spelling everywhere.
   - 1. Rubinstein [a]
   - 2. Rubenstein [b]
2. **Section 11.C cross-reference is wrong.** It says "breaches of Section 5, Confidentiality" but Confidentiality is Section 6. Fix in canonical, or preserve verbatim?
   - 1. Fix to Section 6 [a]
   - 2. Preserve verbatim [b]
3. **Effective Date convention.** Source has the date blank (`________________`) for hand/DocuSign fill at signing. Keep blank by default? Or auto-fill?
   - 1. Keep blank (recommend) [a]
   - 2. Auto-fill at generation [b]
4. **Style artifact in source.** Last signature-block line is styled `Heading 2`. Generator should normalize to `Normal`.
5. **Subsection bold-formatting inconsistency** across sections 4, 7, 9, 10. Preserve per-section verbatim, or pick one canonical style?
   - 1. Preserve verbatim per section [a]
   - 2. Pick one canonical style [b]

### Recommendation
Once you call those five, freeze the MSA into `templates/msa-canonical-2026-05-04.docx` and never touch the legal text again except by deliberate review with counsel. Document the lock date in a comment header inside the template.

---

## Section 2. Workgraph issues (deep analysis)

Two relevant tasks in `wg`:

### `fix-recurring-double` (PAUSED) — root cause verified

The bug is not in the canonical template. It is in the *workflow that bypasses the template.*

**What I verified by inspecting the .docx XML directly:**

| File | sectPr count | sectPr with `cols num=2` |
|---|---|---|
| `templates/sow-template.docx` (canonical) | 1 | 0 |
| `templates/teays-original.docx` | 1 | 0 |
| `templates/pulse-template.docx` | 1 | 0 |
| `LEADS/Powerfleet/old proposal drafts/2026.04.24.docx` | **4** | **2** (inline at body indices 38, 165) |
| `LEADS/Powerfleet/Powerfleet_MSA & SOW_2026.05.04.pdf` (canonical) | 4 | 2 (rendered correctly because surrounding sectPrs contain them) |

**Failure mode:** when an agent clones a prior client's docx as the base, it inherits intentional two-column sectPrs that wrap the side-by-side signature blocks. The cleanup loop walks `doc.paragraphs` (which only contains `<w:p>` elements) and misses `<w:sectPr>` and `<w:tbl>` body children. New SOW content lands in a section governed by an orphaned 2-column directive and renders as columns.

**Concrete fixes (from agent's analysis, prioritized):**
1. Make the skill physically incapable of using anything except the canonical templates. Resolve `template_path = SKILL_DIR / "templates" / "sow-template.docx"`, never search the filesystem.
2. Maintain a clean MSA-only template alongside the SOW one.
3. Add a 5-line lxml structural assertion as the final gate: walk every `<w:sectPr>`, fail if any has `cols num != 1` outside known signature-block regions. **One of the few places a deterministic check earns its keep, not an LLM call.**
4. Eliminate `remove_msa_section()` entirely. Two-template strategy beats post-hoc deletion.

### `update-remix-proposal` (FAILED) — KOSME learnings

Triggered by the KOSME GBC Chicago rewrite on 2026-04-28. Original output was a discussion-stage "Engagement Options" doc with three balanced options. You wanted a signable MSA + SOW with one recommended path and the former Option C repositioned as "where this could go" with no price. Conversion took 4 round-trips of manual docx surgery.

**Eight recommended changes from the workgraph task body:**
1. Default to signable MSA + SOW, not "options doc." Add `--discussion-only` flag for the rare case.
2. "Lead with recommendation" framing as default. Three balanced options is the exception.
3. Codify the "Where This Could Go" pattern (future-state, no price) as a structural element across offer templates.
4. Add a `kickstart_cohort` offer type. KOSME wasn't single-company kickstart, AIBA, or subscription.
5. MSA selection logic: for a new lead with no prior MSA, pull from "most recently signed similar engagement" rather than the generic.
6. Output self-test before declaring done. Catches the layout-bug class.
7. Capture "client legal entity TBD" pattern for non-standard contracting.
8. Document formatting traps in `templates/README.md`.

**Why it failed in the agent:** Sonnet 4.5 agent-10 exited code 1 after 5 seconds. Single retry, then failed. Plausible: too broad for one-shot agency, no environment setup, needs a human-supervised plan.

---

## Section 3. Regex and scripts: what dies, what stays

Full audit at `/tmp/proposal-skill-research/02-regex-and-script-inventory.md`. **27 instances total**, classified KEEP / KILL / MIGRATE.

### KEEP (5 instances) — defending MSA legal-text fidelity
1. Token replacement of `{CLIENT_COMPANY}`, `{CLIENT_COMPANY_LEGAL}`, `{DATE}` and the new tokens listed above. These are literal string matches inside locked legal text. LLM reasoning is the wrong tool for this.
2. The "IN WITNESS WHEREOF" structural assertion (does the MSA still end with that phrase after token replacement?).
3. The "Jason Rubinstein" name appearance check (or whichever spelling you canonicalize).
4. The unreplaced-`{TOKEN}` detection that fails the build if any token survived to output.
5. The new sectPr-cols structural assertion (item 3 in the double-column fix list above).

### KILL (~75% of the 27) — replace with LLM judgment
- Bullet-glyph stripping with regex defensively applied to every input (the LLM should produce clean text)
- String-match section finders that look for "Strategic Opportunity" and similar headings to anchor paragraph indices
- The 80+ paragraph-index map that drives the `ProposalBuilder` class
- Anti-AI vocabulary regex matchers (move into the voice scrub stage that the rewriter already does well)
- The deterministic style-guide enforcement passes that try to mimic editorial judgment

### MIGRATE (small number) — move responsibility to Agent 2 or Agent 3
- The verify_proposal.py 14-check script gets refactored: structural checks (sectPr cols, missing sections, signature block present) stay as cheap deterministic gates. Stylistic checks (em-dashes in text, empty bullets, register) become LLM passes inside Agent 1's quality discipline or Agent 3's review.

### Net result
The skill should retain a tight kernel of structural assertions (small Python, no regex on Word XML, lxml namespace queries only) and otherwise be 100% LLM-driven for content, voice, and judgment.

---

## Section 4. The three-agent architecture (proposed)

Mirrors the rewriter's pattern: Editor orchestrator runs each stage as a real `Task()` sub-agent when supported, inline persona-switches as fallback. Prose-in/prose-out contracts. Lazy reference loading per stage.

Full architecture at `/tmp/proposal-skill-research/03-proposal-three-agent-architecture.md`.

### Agent 1: Context & Draft
**Inputs:** transcripts, CLIENT.md, prior signed proposals (for voice anchoring), the brief, offer type
**Internal work:** loads transcripts and CLIENT.md, runs rewriter quality discipline inline (Strategist / Craftsman / Anti-AI Scrub thinking, voice match if requested), composes the proposal narrative + SOW content
**Outputs:** hybrid YAML envelope (typed metadata fields + prose blocks with style hints) + a human-readable Markdown draft for your skim review
**References loaded:** `voices/remix-proposals.md` (the new one), `voices/justin.md` (only if voice match requested for cover note), the rewriter's writing-craft references (`pinker-clarity.md`, `klinkenborg-sentences.md`, `strunk-white-elements.md`, `anti-ai-checklist.md`)

### Agent 2: Assembly
**Inputs:** Agent 1's structured envelope + the locked canonical MSA template + per-client tokens
**Work:** copies the canonical MSA-only template; assembles the SOW content from Agent 1's prose blocks using existing template styles; applies token replacement; never edits MSA legal text
**Outputs:** the .docx file path
**Wraps:** a slimmed-down `ProposalBuilder` (with `remove_msa_section()` deleted entirely, replaced by the two-template strategy) plus the lxml structural assertions

### Agent 3: Visual Review
**Inputs:** the .docx path
**Work:** converts to PDF via `soffice --headless --convert-to pdf`, opens in Playwright, runs page-bound checks (page-break overflow, double-column anywhere, table overflow, signature block placement, orphan bullets, font consistency), captures screenshots of issues
**Outputs:** a structured JSON report of issues + screenshots
**Loop policy:** **report-and-loop with N=2 retries, then escalate.** Agent 3 never directly mutates the .docx; it routes issues back to Agent 2 (formatting) or Agent 1 (content). After 2 failed rounds, escalate to you with screenshots.

### Top three decisions you need to make

**1. Where does quality work live?**
- **(a)** Inside Agent 1 (recommend) — Agent 1 internalizes Strategist/Craftsman/Scrub/Voice thinking, then emits the envelope. Same model the rewriter uses for inline-persona environments.
- **(b)** Run `/rewriter` as a literal sub-skill on each prose block before Agent 2 — adds a fourth agent you didn't ask for.
- **(c)** Add a quality-pass stage between Agent 1 and Agent 2.

**2. Should Agent 3 edit-and-retry or report-and-stop?**
- **(a)** Report-and-loop with N=2 retries (recommend) — Agent 3 never mutates docx XML; routes issues back upstream.
- **(b)** Edit-and-retry — invites the same paragraph-index bugs the existing skill fought for months.

**3. Output contract Agent 1 → Agent 2: pure JSON, pure Markdown, or hybrid?**
- **(a)** Hybrid YAML envelope with prose blocks as values (recommend)
- **(b)** Pure JSON
- **(c)** Pure Markdown

Recommendations are the agent's; happy to redirect on any of them.

### Smaller decisions (defaulting to the recommendation unless you object)
- Offer type stays as a parameter to Agent 1, not separate sub-agents per offer
- MSA stored as a locked .docx template with token markers, same as today
- Voice-neutral default; opt-in voice match via intake question
- Render path is PDF (not HTML) so page-bound bugs are visible
- Both `verify_proposal.py` AND Playwright run, in that order
- Per-proposal scratch directory: `/tmp/proposal-build/{client}-{offer}-{date}/`

Twelve open questions in total at `/tmp/proposal-skill-research/03-open-questions.md`.

---

## Section 5. Contract corpus analysis and the Remix Proposals voice

14 signed contracts read across active and old clients. Coverage: 6 Kickstarts, 4 AIBA Sprints, 1 Strategy/Assessment, 3 Retainer/Pulse/annual, 1 Extension SOW.

Full analysis at:
- `/tmp/proposal-skill-research/04-corpus-inventory.md` — every contract, with metadata
- `/tmp/proposal-skill-research/04-themes-and-patterns.md` — voice, structure, conventions, anti-patterns
- `/tmp/proposal-skill-research/04-remix-proposals-voice.md` — 423-line voice guide draft, ready for `~/.claude/skills/voices/remix-proposals.md`
- `/tmp/proposal-skill-research/04-skill-fix-recommendations.md` — prioritized P0/P1/P2 fixes

### Top five voice patterns (high confidence)

1. **Client-language pickup.** Signed proposals echo the client's own phrases back to them: "vanguard" (Hirewell), "Tiger Team" + "could vs should" (NineStar), "in the ballpark" (Pacific Transformer engineer), "administrative tax on the business" (William A. Randolph). The single biggest separator from generic consulting prose.

2. **Three-paragraph Executive Summary shape.** Paragraph 1 is a substantive opportunity grounded in numbers. Paragraph 2 is "Client stands at a strategic inflection point. As a [type], your [strength]..." Paragraph 3 is an engagement effect statement.

3. **"Where This Could Go" close** with two named, client-specific extensions. Universal in 2026 SOWs longer than 800 words.

4. **"Key dynamics shaping this engagement:" 4-6 bullet list** in Background & Context. Universal Remix-ism.

5. **Concrete numbers tied to real client decisions** in the Executive Summary. Pacific Transformer's "$65,000 to $85,000 per year" hire-avoidance line is the corpus's gold standard.

### P0 skill fixes (must do before next use)

**P0.1: Stop reusing paragraph 3 of the Executive Summary verbatim.** "Transform [Client] from [X]-based foundation into AI-enhanced organization" leaked from Teays into Pacific Transformer's signed Sprint SOW with leftover "portfolio management" language that's nonsensical for a transformer manufacturer.

**P0.2: Add a client-language-pickup pass.** Extract distinctive client phrases from the transcript before drafting; mandate at least 2 appear in Background & Context.

**P0.3: Ban "Rather than viewing AI as another technology upgrade."** Appears verbatim in 3 of 4 Kickstart SOWs. Templated boilerplate that survived signing because reviewers were tired.

**P0.4: Guard against previous-client-name leak.** Hirewell Pulse 4/9 (signed) contains "Solarea Bio employees only" in Distribution Rights. Copy/paste from a prior Pulse SOW. **This is a contract integrity bug and is shipping right now.** Build a forbidden-name list of known prior clients; halt the build if any of those names appears anywhere except the actual client's name slot.

### Other prioritized fixes (P1/P2)

- Standardize "AI Square Dance" — Teays got "Jedi Square Dance," variant slipped
- Mandate 2 client-specific named extensions in "Where This Could Go" (never both generic)
- Force at least one number in the Executive Summary tied to a real client decision
- Cover-note voice should be Justin-voice; SOW voice should be Remix Proposals voice (different by intent)
- Add Pacific Transformer Sprint 2 to `examples/` as the Sprint reference; replace Teays Jan 16 draft with the Feb 25 signed final
- Within-sentence number formatting consistency
- Era anti-patterns reference (kill 2025-style ALL-CAPS headers, arrow callouts, heavy nested bullets if they re-creep)
- Termination clause library keyed by payment cadence
- Final-pass proofread guard for "Hirewell'" possessives and Jason's name spelling
- "Pacific Transformer test" — five-question quality gate at end of Executive Summary generation

### Honest signal notes (from the agent)
- The "Important: we are not asking your team to practice on abstract exercises..." paragraph appears verbatim across 3+ docs. Recommendation: preserve the *posture*, recompose the words per client.
- Some patterns showed up in 2-3 docs only ("thin signal"). Flagged as such; not promoted to canonical voice rules.

---

## Section 6. Beads issues created for implementation

Created in `~/Projects/ClaudeProjects/.beads/`. Epic + 12 children + 4 dependency edges wired.

| ID | Pri | Title |
|---|---|---|
| `vf6` | P0 | EPIC: Overhaul remix-proposal-writer |
| `2wj` | P0 | Lock canonical MSA from Powerfleet 2026-05-04 |
| `19m` | P0 | Fix double-column bug at root (template-only path) |
| `9mi` | P0 | Add forbidden-name guard (contract integrity) |
| `x2g` | P0 | Ban Executive Summary boilerplate phrases |
| `7qr` | P0 | Add client-language pickup pass |
| `0os` | P1 | Audit and strip regex/scripts (keep 5 MSA-fidelity items) |
| `925` | P1 | Author and install Remix Proposals voice guide |
| `nvn` | P1 | Build Agent 1: Context and Draft |
| `wp2` | P1 | Build Agent 2: Assembly |
| `gt4` | P1 | Build Agent 3: Visual Review |
| `9jl` | P2 | Add `kickstart_cohort` offer type |
| `d70` | P2 | Update examples library |

Wired dependencies:
- `wp2` (Agent 2) depends on `2wj` (canonical MSA) and `19m` (double-column fix)
- `gt4` (Agent 3) depends on `wp2` (Agent 2)
- `nvn` (Agent 1) depends on `925` (voice guide)

Quick-fix lane (P0 items that can ship inside the current skill before the multi-agent rebuild): `9mi` forbidden-name guard, `x2g` boilerplate phrase bans, `7qr` client-language pickup, `2wj` MSA lock, `19m` double-column fix. These five fix shipping bugs and don't require waiting on the architecture work.

---

## Section 7. What I need from you when you're back from lunch

Five decisions to unblock implementation:

1. **MSA ambiguity calls** (Section 1): Jason name spelling, Section 11.C cross-ref, blank effective date convention, signature-block style normalization, subsection bold consistency
2. **Architecture decisions** (Section 4 top three): where quality lives, Agent 3 retry policy, envelope format
3. **Voice guide review:** read `/tmp/proposal-skill-research/04-remix-proposals-voice.md` and tell me if it reads like Remix
4. **Beads scope:** are you OK with these living in `~/Projects/ClaudeProjects/.beads/`? Or move to a new beads repo inside `~/.claude/skills/skills/remix-proposal-writer/` so issues live next to code?
5. **Sequencing:** P0.4 (forbidden-name guard) is currently shipping a bug. Want me to fix that immediately as a one-off patch ahead of the larger overhaul, or roll it in?

---

## Appendix: full deliverables map

```
/tmp/proposal-skill-research/
  01-canonical-msa.md           — verbatim MSA with 6 tokens, Powerfleet-derived
  01-msa-tokens.md              — full token inventory with edge cases
  01-msa-boundaries.md          — MSA/SOW boundary, ambiguities flagged
  02-regex-and-script-inventory.md — 27 instances, KEEP/KILL/MIGRATE per item
  02-skill-architecture-as-is.md   — current architecture map (~100 lines)
  02-workgraph-issues.md           — both wg tasks deeply analyzed + bug hypothesis
  02-kosme-learnings.md            — what KOSME taught us
  03-rewriter-pattern.md           — how the rewriter actually works
  03-proposal-three-agent-architecture.md — full architecture proposal
  03-open-questions.md             — 12 decisions for Justin
  04-corpus-inventory.md           — 14 signed contracts read, with metadata
  04-themes-and-patterns.md        — voice/structural/anti-pattern analysis
  04-remix-proposals-voice.md      — 423-line voice guide draft
  04-skill-fix-recommendations.md  — P0/P1/P2 prioritized changes
```

Move these to durable storage if useful (they currently live in /tmp).
