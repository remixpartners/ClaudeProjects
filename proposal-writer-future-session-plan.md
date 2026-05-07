# remix-proposal-writer: Future-Session Plan

**Date:** 2026-05-07
**Status of this session:** The full Path B (multi-agent rebuild + regex audit cleanup) shipped. The architecture is in place, the three agent personas are documented, the regex audit cleanup is done, the templates are fixed.
**What this plan covers:** the work that genuinely requires a separate session because it needs runtime infrastructure setup, end-to-end live validation, or coordinated multi-tool integration that wasn't possible to do in one session.

---

## Immediate next session: end-to-end validation

The architecture has not yet been exercised against a real client. The first thing to do in the next session is run the new three-agent flow against a real lead and observe.

### Recommended target

Pick a current lead with a transcript and CLIENT.md already in place. Best candidates:

- **AGR Partners** — already has full CLIENT.md, transcript, and a previous-architecture proposal we can diff against. Re-running through the new architecture will surface any regressions vs what we already know.
- **Whichever new lead Justin lines up next week.** Real-world test, no prior baseline.

### Pre-flight setup

Before running:

1. **From Jason's machine, pull `remixpartners/claude-skills` to latest.** The 2026-05-07 rebuild commit needs to be on Jason's machine for cross-machine parity testing.
2. **Install LibreOffice** (`brew install --cask libreoffice` on macOS). Agent 3 needs `soffice` for PDF rendering.
3. **Verify `python3 -c "from docx import Document"`** works; install `python-docx` if missing.
4. **Run** `cd ~/.claude/skills/skills/remix-proposal-writer && python3 scripts/verify_proposal.py templates/sow-template.docx` from Jason's machine. The expected errors are unreplaced placeholders (it's a template). Confirm no other errors.

### Run sequence

In a session, invoke the skill with a real client name:

```
/remix-proposal-writer AGR Partners
```

The orchestrating LLM should:

1. Read SKILL.md (the new orchestrator-style version)
2. Load `agents/01-context-draft.md`, follow it completely
3. Emit envelope at `/tmp/proposal-build/agr-partners-kickstart-2026-05-XX/01-context-envelope.yaml`
4. Stop and let Justin review the YAML envelope and `01-draft.md`
5. Load `agents/02-assembly.md`, assemble the .docx
6. Run `verify_proposal.py` — must exit 0
7. Load `agents/03-visual-review.md`, run the visual checks, produce report
8. If clean: copy to Drive
9. If issues: route per the loop policy (N=2 retries, then escalate)

### What to compare against

Diff the new output against `~/.claude/skills/skills/remix-proposal-writer/templates/agr-partners-pre-2026-05-07/...` (if we preserved a copy of yesterday's AGR proposal, otherwise diff against the version in Drive).

Specific things to look for:
- **MSA Section 7** has 7.A AND 7.B AND 7.C (the SkyFi failure mode is gone)
- **Section 11** shows bold-only-on-label across A/B/C
- **Signature blocks** are stacked, no Title-leakage
- **Logo** is on every page; **footer** says "REMIX PARTNERS  CONFIDENTIAL  [page]"
- **Pricing** is `$######` placeholder (Justin fills before send)
- **Where This Could Go** is either Pulse-only OR has 1-2 client-specific extensions that go BEYOND the engagement's own deliverables (no overlapping "Government Proposal Acceleration"-style filler)
- **Banned phrases** absent ("inflection point", "transform from", "AI landscape", "leverage" as verb)
- **Top 1-2 client phrases** from Step 0 Pass A appear in the prose (not all 5 — discipline)
- **Team capability counts** match Pass B inventory exactly

### Likely friction points (predict, then verify)

Things that could go wrong on first real run, with predicted fixes:

1. **Agent 1's envelope schema may be over-prescribed.** Some offer types don't need every field. Soften the schema where genuine flexibility exists; tighten where consistency matters.
2. **Agent 2's semantic-anchor algorithm may not find a section** if the offer template's heading text drifted. Add fallback / better error messages.
3. **`soffice --headless --convert-to pdf` may produce slightly different rendering than Word.** Confirm visual fidelity is acceptable; if not, document the known differences.
4. **Playwright on a PDF** is novel; the simple path is screenshot via `pdftoppm`, then a vision-capable LLM inspects the screenshots manually. Build the full Playwright pipeline only if/when manual proves unscalable.

After this validation, we'll know which of the agent personas need refinement based on real data.

---

## Future session 2: Agent 3 runtime infrastructure

The Agent 3 persona file documents the visual-review checks, but the actual runtime helpers are not yet written. In a separate session, build:

### Helper scripts under `scripts/agent_3_*.py`

- `scripts/agent_3_render_pdf.py` — wraps `soffice --headless --convert-to pdf` with error handling, returns PDF path
- `scripts/agent_3_extract_screenshots.py` — uses `pdftoppm` to convert each PDF page to PNG
- `scripts/agent_3_run_checks.py` — given a PDF + envelope, runs the 11 visual checks listed in `agents/03-visual-review.md` Section 2, returns a structured issue list
- `scripts/agent_3_content_cross_checks.py` — given PDF text + envelope, runs the content cross-checks (Pass A phrases present, pain points mapped, banned phrases absent, Executive Summary length in range)

### Playwright integration

For checks that genuinely require browser-based DOM inspection (e.g., checking a rendered HTML version for layout flow), set up a Playwright runner. This is optional for MVP — the simpler path is screenshot-and-vision-LLM.

### Loop integration into the orchestrator

The orchestrator (the LLM running the skill) needs to know:
- How to invoke Agent 3
- How to read the issue report
- How to route issues back to Agent 1 or Agent 2
- How to track `review_round`
- How to escalate at `review_round > 2`

Document this loop logic in `SKILL.md` under "ORCHESTRATION" with concrete examples.

---

## Future session 3: Template placeholder cleanup (closes beads `klw`)

The SOW skeleton in `templates/sow-template.docx` still contains banned-phrase boilerplate as placeholder content (e.g., paragraphs around the Executive Summary slot say "stands at a unique strategic inflection point" and "transform from its Excel-based foundation into an AI-enhanced organization"). Agent 2 OVERWRITES these placeholders during assembly, so they should never reach the final doc — but defense-in-depth says: replace them with neutral generation-directive markers like `[INSERT: Executive Summary paragraph 1 from envelope]`.

### Approach

Write a small script `scripts/scrub_sow_placeholder_text.py` that:
1. Opens `templates/sow-template.docx`
2. Identifies the placeholder paragraphs in the Executive Summary, Background & Context narrative, Strategic Opportunity intro, Primary Goal, and engagement-approach intro slots (currently containing prior-client copy)
3. Replaces them with `[INSERT: <section-name> from Agent 1 envelope]` markers
4. Preserves paragraph styles (so `set_paragraph_text` still works)
5. Saves a backup before overwriting

### Why deferred

This is defense-in-depth. The actual fix is that Agent 2 overwrites these slots during normal operation. The placeholder text only manifests if Agent 2 fails — at which point we'd want the fail-safe to be "[INSERT: ...]" markers not banned phrases. Useful but not blocking.

---

## Future session 4: `kickstart_cohort` offer type (closes beads `9jl`)

The KOSME GBC Chicago multi-company cohort engagement type doesn't fit the existing kickstart / aiba / pulse / speaking-training categories. Build it.

### What's needed

1. New offer template at `offers/kickstart_cohort.md` describing:
   - Multi-company cohort dynamics (4-6 portfolio companies, biweekly cadence)
   - Readiness survey as a Phase 0 artifact
   - Portfolio-level Action Plan (different from single-client Action Plan)
   - Peer-learning structures
2. Agent 1 needs to recognize this offer type and produce the appropriate envelope structure
3. Agent 2 needs to either reuse `sow-template.docx` (if structurally similar to Kickstart) or have a `templates/cohort-template.docx` (if the structure is genuinely different)

### Source material

The KOSME GBC Chicago proposal at `LEADS/KOSME GBC Chicago/KOSME GBC Chicago_MSA & SOW_2026.04.28.docx` is the working example. Use it as the structural reference for what a cohort SOW looks like.

---

## Future session 5: Examples library refresh (closes beads `d70`)

The `examples/` folder has:
- `excelsior-aiba.md` (verify it's the SIGNED version, not a draft)
- `teays-river-kickstart.md` (this is the JANUARY 16 unsigned draft, NOT the FEBRUARY 25 signed final)

### What to do

1. Replace `teays-river-kickstart.md` with text from the **2026-02-25 signed** Teays SOW (currently at `Clients & Partners/ACTIVE CLIENTS/Teays River Investments/Teays River_Kickstart MSA & SOW_2026.02.25.docx`)
2. Add `pacific-transformer-sprint2.md` as the Sprint reference example. Pacific Transformer Sprint 2 is the gold standard per the voice guide; its Executive Summary opener ("A new doc control position in Southern California runs $65,000 to $85,000 per year in fully loaded compensation. Sprint 2 is designed to make that hire unnecessary.") is the model.
3. Verify `excelsior-aiba.md` is the signed version; if not, replace.

These give Agent 1 better in-context references when drafting.

---

## Future session 6: RemixOS schema migration (closes beads `7ep`)

Add `legal_name`, `address_full`, `entity_type` columns to the RemixOS `companies` table on the Mac Mini. Backfill for active clients from signed MSAs.

### Approach

1. Plan the schema change (ALTER TABLE) on the Mac Mini's `~/remix-os/data/remix_crm.db`
2. Backfill script that reads each active client's signed MSA from Drive (`Clients & Partners/ACTIVE CLIENTS/{Client}/{Client}_MSA & SOW_*.docx`), extracts the preamble's `("Client"), {entity-type} with its principal place of business at {address}` line, and populates the three new columns
3. Update SKILL.md / agent persona files to use the columns when available, falling back to the LLM-resolution chain only when missing
4. Coordinate with Kirby (the Mac Mini agent) since RemixOS is its system of record

### Why deferred

Schema changes on production DB need explicit go-ahead. The LLM-resolution fallback (suffix inference + Drive lookup + ask-Justin) works today and is cross-machine-portable; the schema columns are an optimization, not a requirement.

---

## How to know we're done with the rebuild

We can call the multi-agent rebuild "shipped" when:

1. End-to-end validation in Future Session 1 produces a clean proposal on a real client
2. Agent 3 runtime infrastructure (Future Session 2) is in place — we can run the visual checks programmatically
3. The next 5+ proposals run without Justin or Jason needing to make >5 comments per doc
4. Cross-machine parity confirmed: Justin and Jason can each invoke `/remix-proposal-writer` and produce structurally-identical output for the same input

After that point, Future Sessions 3-6 are polish and convenience, not blocking.

---

## What's already done (this session, for the record)

- Full Path B architecture: orchestrator + 3 agent personas in `agents/`
- Regex audit: 18 KILL items removed (ProposalBuilder class, paragraph index map, bullet-glyph stripping, page-count proxy, Calibri scan, manual-indent detection, table presence check, price placeholder check, filename regex, etc.)
- Regex audit: 4 MIGRATE items moved (deep-copy bullet → Agent 2 toolkit; table-shape heuristic → Agent 2 with documentation; heading-style scan → kept in verify; anti-vocab scan list → baked into Agent 1 system prompt)
- Regex audit: 5 KEEP items hardened (token replacement, unreplaced-token detection, MSA Section 7 structural assertion, signature-block legal fidelity, sectPr structural assertion)
- `verify_proposal.py` slimmed from 560 to 432 lines, focused on structural invariants only
- `offers/subscription.md` slimmed from 305 to 193 lines (paragraph-index table killed, Python f-string copy moved out of skill code)
- `offers/kickstart.md`, `offers/aiba.md`, `offers/speaking_training.md` audited (already clean, no changes needed)
- Top-level SKILL.md rewritten from 1430 to ~250 lines focused on orchestration; previous version preserved at `SKILL-pre-2026-05-07-rebuild.md` for history
- All template surgery from earlier today still in place (canonical MSA + SOW skeleton with proper relationships, Section 7.C, Section 11 split, stacked sig block, $###### placeholders, fixed logo embed, removed dangling rIds)

---

## Summary

The architecture is in place. The framework is shippable. The next sessions are about exercising it against real data, building the runtime infrastructure, and cleaning the long-tail polish. The skill is now in a state where each future session moves us forward without re-fighting yesterday's bugs.
