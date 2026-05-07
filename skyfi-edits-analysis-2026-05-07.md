# SkyFi MSA & SOW: Jason's Edits + Comments Analysis & Skill Recommendations

**Date:** 2026-05-07
**Author:** Stafford
**Method:** Reviewed PDF export (`SkyFi_MSA & SOW_2026.05.06.docx.pdf`) + screen-capture of Google Doc with comment panel visible. Cross-referenced findings against the post-canonical-splice `templates/sow-template.docx`.
**Context:** Jason ran the skill on his machine. This is the first cross-machine run since the canonical-MSA splice + voice fixes shipped 2026-05-06.

---

## TL;DR

Jason flagged **17 distinct issues** across 13 comments + visible strikethroughs + content gaps. They sort into 11 categories, of which **6 are P0 bugs** (breaking the doc on Jason's machine, contract integrity issues, or obvious quality failures) and 5 are P1/P2 polish.

The headline finding: **the skill's runtime is corrupting MSA Section 7.** The post-splice template correctly contains 7.A + 7.B, but the rendered SkyFi output shows 7.B has been replaced by the SOW's "Termination" clause text. Hypothesis: a global text-replacement step is matching "Termination:" in both MSA Section 7 and SOW Investment & Terms, then overwriting the MSA one with SOW content. **Classic regex-on-document trap. Exact failure mode the LLM-over-regex policy exists to prevent.**

Second meta-finding: **the canonical MSA itself is missing Section 7.C "Effect of Termination."** Verified by inspecting the Powerfleet 2026-05-04 source — Justin signed Powerfleet's MSA without 7.C. The "canonical" MSA inherited the gap and propagates it to every client. Needs to be re-added with legal review.

Third meta-finding: **multiple bugs trace to the skill assuming a single-machine environment** (logo path, footer setup, paragraph-index map). When Jason runs it on his machine, things break that don't break for Justin. This is an agent-native Parity failure.

---

## Comments + edits inventory

| # | Source | Issue | Pri | Skill change category |
|---|---|---|---|---|
| 1 | Jason comment | "didn't add logo correctly" | P0 | Cross-machine portability |
| 2 | Justin comment | "i bet the skill references my local path for the logo" | P0 | (root cause of #1) |
| 3 | Jason comment | "footer was deleted" + visible "[NO FOOTER]" markers | P0 | Cross-machine portability |
| 4 | Visible bug | Section 7.B text replaced by SOW termination clause | P0 | Runtime text-replacement corruption |
| 5 | Verified gap | Section 7.C "Effect of Termination" missing entirely | P0 | Canonical MSA itself is incomplete |
| 6 | Jason comment | "spacing between 7. and A. is off-tighten" | P1 | Spacing consistency |
| 7 | Jason comment | "this is in the wrong place - should be in SOW" (SOW termination text in MSA Sec 7) | P0 | Same root cause as #4 |
| 8 | Jason comment | "all of the text after each colon should not be in bold, per above styling" (Section 11.A/B/C) | P0 | Run-level bold formatting |
| 9 | Jason comment | "formatting is off" (signature block "Title: Founder & CEO" leaked into Remix block) | P0 | Signature-block layout |
| 10 | Jason comment | "fix spacing between sections" (Engagement Approach) | P1 | Spacing consistency |
| 11 | Jason comment | "tighten spacing" (Phase 3) | P1 | Spacing consistency |
| 12 | Visible strikethrough + comment | Entire "Government Proposal Acceleration" extension cut | P1 | "Where This Could Go" gate calibration |
| 13 | Jason comment + visible | "$25,000######" — `$######` partial replacement, hashes survived | P0 | Token-replacement bug |
| 14 | Jason comment | "fix spacing between sections" (Investment) | P1 | Spacing consistency |
| 15 | Jason comment | "Add: '.'" (after "As agreed by the parties") | P2 | Punctuation typo |
| 16 | Jason comment | "take out of template; end with period showing expiry of quote" (Timing line) | P2 | Content tightening |
| 17 | Jason comment | "should pick-up legal entity name from MSA first paragraph and signature block in MSA" (SOW sig block has "SkyFi" not "Optisense, Inc. d/b/a SkyFi") | P0 | Legal-name reuse across MSA + SOW |

Plus a yellow highlight on the Optisense entity-type/address line in the MSA preamble (visible flag, no explicit comment) — probably for the blank address `__________________________________________________`.

---

## Category 1 — Cross-machine portability (P0): Logo + Footer

**Root cause hypothesis (confirmed by Justin in comment):** the skill hardcodes filesystem paths to brand assets (logo image, fonts, possibly footer template) that resolve only on Justin's laptop. When Jason runs the skill from his machine, those paths fail silently and the doc renders without the logo and possibly without the footer.

**Specific symptoms in SkyFi PDF:**
- Page 1 has a placeholder warning triangle where the Remix logo should be
- "[NO FOOTER]" text appears in the rendered Google Doc on multiple pages, suggesting Google Docs is showing this when a section's footer is missing or unreachable
- The footer that DOES render says "REMIX PARTNERS  CONFIDENTIAL  [page]" — that part works on most pages but is missing on page 1

**Skill change:**

- **P0:** Audit the skill for any hardcoded `/Users/justinmassa/...` paths. Logo and brand asset references should be:
  - Embedded directly in the .docx template (preferred), or
  - Resolved via `SKILL_DIR / "assets" / "logo.png"` (relative to skill directory), or
  - Pulled from a documented network/Drive path that all team members can resolve
- **P0:** Test the skill end-to-end from a non-Justin machine before declaring shipped. The skill effectively had zero coverage for this until Jason ran it.

**Agent-native angle (Parity):** the skill must produce the same output regardless of which Remix team member runs it. Single-machine assumptions are a Parity failure.

**LLM over regex:** not applicable — this is a deterministic environment issue, fix by removing hardcoded paths.

---

## Category 2 — MSA Section 7 corruption (P0): the headline bug

**What's in the post-splice template** (verified by inspection):
```
[17] 7. TERM AND TERMINATION
[18] A. Term: This Agreement commences on the Effective Date...
[19] B. Termination: Either Party may terminate for material breach...
[20] 8. LIMITATION OF LIABILITY...
```

**What's in the rendered SkyFi PDF:**
```
7. TERM AND TERMINATION
A. Term: This Agreement commences on the Effective Date...

Termination:
If Client elects to terminate this fully executed SOW for convenience after execution,
Client remains liable for the first payment representing 50% of the Investment.

8. LIMITATION OF LIABILITY...
```

The skill's runtime is **replacing the MSA's 7.B "Termination by material breach" clause with the SOW's "Termination" clause** about losing 50% of the investment if the client terminates the SOW for convenience. These are completely different concepts:

- **MSA 7.B** is a generic legal-relationship-termination clause (either party can exit on material breach with 15-day cure)
- **SOW Termination** is a specific commercial penalty for SOW termination (client owes 50% if they back out)

The SOW one has been substituted in place of the MSA one.

**Hypothesis on root cause:** somewhere in the skill code or LLM-driven runtime, there's a step that finds "Termination:" in the document and replaces or repositions it. That find matches BOTH:
1. The MSA's "B. Termination:" (paragraph 19 in spliced template)
2. The SOW's standalone "Termination:" label (much later in the SOW Investment & Terms section)

When the runtime processes them, the SOW content is being placed at the MSA position (paragraph 19), or a global text-replacement is matching the wrong "Termination:" label.

This is the **paragraph-index-map drift** problem the workgraph notes warned about back when we first locked the canonical MSA: "The paragraph index map in current SKILL.md is hand-maintained and breaks when the template changes." The splice changed the indices; the skill's hardcoded operations didn't update.

**Skill change:**

- **P0:** Audit the skill for any text-replacement or paragraph-index operation that touches "Termination" without a unique anchor. Replace with semantic anchors that the LLM can resolve correctly (e.g., "find the paragraph that comes after 'B. Termination:' inside Section 7 of the MSA" — the LLM can do this; a regex cannot).
- **P0:** Stop using absolute paragraph indices to address content. After the canonical-MSA splice, indices in the skill's `paragraph_index` map are wrong. Either rebuild the map (brittle, will break again next time the template changes) OR move to LLM-driven semantic placement (more robust).

**Agent-native angle (Granularity):** absolute paragraph indices are too coarse-grained. A semantic anchor ("the paragraph immediately following the 'B. Termination:' label") is the right granularity — composable, resilient to template edits, debuggable.

**LLM over regex:** **this is exactly the LLM-over-regex argument.** A regex on "Termination:" matches both occurrences and breaks. An LLM reading the document understands which "Termination" is the MSA generic one vs. the SOW-specific one and edits the right one (or doesn't edit either, if the template already has them right). The fix is to delete the offending text-replacement step entirely and trust the LLM to compose section content correctly.

---

## Category 3 — Canonical MSA missing Section 7.C (P0)

**Verified:** the Powerfleet 2026-05-04 source MSA paragraph sequence is `7.A → 7.B → 8.` There is no 7.C "Effect of Termination" in the source, so the canonical MSA template inherits the gap, so every client's MSA is missing it.

**Standard 7.C content** (from the canonical extraction in `01-canonical-msa.md`, which appears to have been the agent's correct legal inference rather than a copy from the source):
> "C. Effect of Termination: Upon termination, Client shall pay Consultant for all Services performed and expenses incurred up to the effective date of termination."

This is essential boilerplate. Without 7.C, on termination the contract is silent on what the Client owes for work already performed. That's a real legal hole.

**Skill change:**

- **P0:** Re-add 7.C "Effect of Termination" to the canonical MSA template. Use the standard language above. Verify with counsel before committing.
- **P0:** Re-run `scripts/splice_canonical_msa.py` after the canonical update to refresh `sow-template.docx` with the corrected canonical MSA.
- **P0:** Add a structural assertion to `verify_proposal.py`: every MSA must have 7.A, 7.B, AND 7.C. Halt build if any are missing. This is a deterministic structural check (paragraph-presence test); LLM-over-regex doesn't apply because we're checking presence, not content.

**Note:** Powerfleet has signed a contract without 7.C. That's a legal gap on the Powerfleet relationship; not Stafford's call but worth flagging to Justin.

---

## Category 4 — Section 11 bold bleeding (P0)

**Visual:** Section 11.A, 11.B, 11.C are entirely bold (yellow-highlighted by Jason in the screenshot for emphasis):

> **A. Informal Negotiation: In the event of any dispute, controversy, or claim arising out of or relating to this Agreement, the Parties shall first attempt in good faith to resolve the dispute through informal negotiation between executives with authority to settle the matter.**

Should be:

> **A. Informal Negotiation:** In the event of any dispute, controversy, or claim arising out of or relating to this Agreement, the Parties shall first attempt in good faith to resolve the dispute through informal negotiation between executives with authority to settle the matter.

The bold should end at the colon; the rest of the paragraph should be regular weight. Section 4 (Ownership) and Section 5 (Consultant Tool IP) get this right (`A. Client Input Materials:` is bold, the rest isn't). Section 11 is the outlier.

**Root cause:** the canonical MSA template itself has Section 11.A, B, C with bolding applied to the entire paragraph. Either the Powerfleet source had this formatting bug too (most likely), OR the splice introduced it.

**Skill change:**

- **P0:** Edit the canonical MSA template directly (`templates/msa-canonical-2026-05-04.docx`) to fix Section 11 run-level bold: bold ends after the colon following each subsection label. Then re-run the splice. This is template surgery, not skill code.
- **P0:** Add to `verify_proposal.py` a structural check: in any subsection labeled `A. <Label>: <body>`, the bold run should not extend past `<Label>:`. Flag deviations.

**Agent-native angle (Composability):** run-level formatting is a primitive operation. The template should encode it correctly once; the skill shouldn't need to fix it at runtime.

**LLM over regex:** not applicable — run-level formatting in docx is a structural property, fix it once in the template.

---

## Category 5 — Signature block layout broken (P0)

**Visual:** in the rendered SkyFi PDF, the Remix Partners signature block has "Title: Founder & CEO" appearing on the same line as "Remix Partners, Inc." — but "Founder & CEO" is the Client signatory's title (presumably Luke Fischer-Austin's), not Jason's title (which is "Partner & Co-Founder").

The intended layout for the Remix block:
```
Remix Partners, Inc.
Signature: ___________
Name: Jason Rubinstein
Title: Partner & Co-Founder
```

What rendered:
```
Remix Partners, Inc.                Title:    Founder & CEO
Signature: ___________
Name: Jason Rubinstein
Title: Partner & Co-Founder
```

The Client signatory's title leaked into the Remix block. The Client block below shows "Name: Luke Fischer-Austin" but **no title** — confirming the title got displaced upward.

**Root cause hypothesis:** the canonical MSA was originally built from Powerfleet, which had a 2-column side-by-side signature layout (per the original workgraph diagnostic). My canonical-MSA build script forced the trailing sectPr to single-column, but the internal signature-block sectPrs that wrap the side-by-side layout may still be present and rendering in unexpected ways depending on Google Docs' rendering quirks. Or, related: when the skill replaces tokens in the signature block, if it walks paragraphs in an order that doesn't match the visual layout, it can put the wrong title in the wrong slot.

**Skill change:**

- **P0:** Simplify the signature block in the canonical MSA template to a stacked layout (Remix top, Client below) with NO column breaks anywhere. The existing two-column-with-cols-num=2 sectPr legacy is the source of repeated rendering bugs (this is the original workgraph `fix-recurring-double` issue back from a different angle). Stacked layout is universally robust.
- **P0:** When the skill replaces signatory tokens (`{{CLIENT_SIGNATORY_NAME}}`, `{{CLIENT_SIGNATORY_TITLE}}`), find the tokens by exact match within their paragraph, not by position. The current bug looks like a positional swap.

**Agent-native angle (Granularity):** stacked sig blocks are simpler primitives that compose reliably. Two-column sig blocks are an optimization (saves vertical space) that costs more in rendering bugs than it saves in space.

**LLM over regex:** not directly applicable — this is template structure.

---

## Category 6 — Pricing placeholder partial replacement (P0)

**Visual:** the rendered output shows `$25,000######` instead of `$25,000`. The price was inserted but the original `######` placeholder hashes weren't fully removed.

Same bug appears 3 times: total + both 50% installments.

**Root cause:** the skill is doing string replacement that finds the `$` and inserts the price right after it, instead of replacing the entire `$######` placeholder pattern. Could be:
- A regex that anchors on `$` only and inserts before the hashes
- A token-replacement step that uses an incomplete pattern
- The skill replaces `######` with the price digits but doesn't strip the leading `$` properly OR inserts price + hashes

**Skill change:**

- **P0:** Fix the price replacement to operate on the full `$######` pattern (six `#` characters) — match the pattern including the dollar sign and hashes, replace with the formatted price. This is one of the few places where a deterministic string replacement is correct (closed pattern, fully unambiguous), so the fix is correct implementation, not switching to LLM.
- **P0:** `verify_proposal.py` Check 0c (unreplaced placeholders) already catches `\{\{?[A-Z_]+\}?\}` token leaks. Add a check for surviving `#{2,}` runs after price-replacement; halt build if found.

**LLM over regex:** **exception — this is a place where deterministic string replacement is right** (closed pattern, fully bounded). The bug is that the current implementation is INCOMPLETE, not that it should be LLM-driven.

---

## Category 7 — SOW signature block uses display name not legal name (P0)

**Visual:** the SOW signature block at the bottom of the doc shows just "SkyFi" — but the MSA preamble correctly identifies the entity as "Optisense, Inc. d/b/a SkyFi" and the MSA signature block correctly uses "Optisense, Inc. d/b/a SkyFi".

Jason's comment: *"should pick-up legal entity name from MSA first paragraph and signature block in MSA"*

**Root cause:** the SOW template uses `{CLIENT_COMPANY}` (display name token) for the SOW signature block, while the MSA template uses `{{CLIENT_NAME}}` (legal entity name token). When the same client has a d/b/a or formal entity wrapper, these resolve to different values. The SOW should use the legal entity name in the signature block (since SOWs are signed contracts).

**Skill change:**

- **P0:** SOW signature block should use the legal entity name (`{{CLIENT_NAME}}` post-canonical-tokens, OR `{CLIENT_COMPANY_LEGAL}` legacy form), NOT the display name. Update `templates/sow-template.docx` SOW signature block tokens.
- **P0:** Add to `verify_proposal.py`: the legal entity name appearing in the MSA preamble must also appear in the SOW signature block. If the SOW sig block has only the display name, halt and flag.

**Agent-native angle (Composability):** the resolved legal entity name is one piece of data; it should be reused everywhere it's needed. The current bug is non-composability — same data resolved twice through different paths.

---

## Category 8 — "Where This Could Go" calibration: Jason cut a client-specific extension (P1)

**The hard-gate rule we shipped 2026-05-06** says: each extension must use a client-specific noun. SkyFi's "Government Proposal Acceleration" extension HAD a client-specific noun ("Government Proposal" + "SkyFi's proposal team" + reference to the 80% government revenue). It passed the gate. **Jason cut it anyway.**

**Strikethrough text Jason removed:**
> "Based on the discovery conversation, we see two natural extensions of this work: Government Proposal Acceleration / The Kickstart will establish foundational AI habits for SkyFi's proposal team. The natural next step is building dedicated AI agents and workflows that handle the repetitive data assembly, compliance formatting, and narrative drafting that define government capture work. This could include custom prompt libraries tuned to specific contract vehicles, automated past-performance section generation, and AI-assisted compliance matrix completion. Given that 80% of SkyFi's revenue flows through this process, even modest efficiency gains compound quickly."

Jason kept ONLY the Pulse pitch as a single extension.

**Plausible reasons:**
1. The proposal already covers government proposal writing as one of three Phase 2 focus areas. The "Government Proposal Acceleration" extension promises essentially the same thing as a follow-on engagement, which reads as either redundant ("we'll do this once now and again later") or as scope creep ("the Kickstart you're paying for isn't actually enough").
2. The extension is too long (4 sentences + bullet-implication) for a "Where This Could Go" item.
3. Jason prefers shorter docs.

**The hard-gate rule is correct in PRINCIPLE but missing a caveat:** an extension that overlaps too closely with the engagement's own promises is not a true extension; it's a redundancy. The gate should add a check: *the extension must describe work that goes BEYOND what the Kickstart itself already includes.* "Build dedicated AI agents for proposal writing" overlaps too much with "Phase 2: government proposal drafting experiments."

**Skill change:**

- **P1:** Update the "Where This Could Go" hard gate in `offers/kickstart.md` with an additional check: the proposed extension must describe work that goes BEYOND the engagement's own Phase 2 / Phase 3 deliverables. If the extension overlaps materially with what the Kickstart already promises, drop it. Pulse-only is fine when no genuinely-incremental extension exists.
- **P1:** Add an example to the kickstart.md guidance: "Government Proposal Acceleration" was cut from SkyFi because it overlapped with the Kickstart's own Phase 2 government-proposal experiments. A genuinely-incremental extension might be "Dedicated proposal-writer AI agents post-Kickstart" if and only if the Kickstart does NOT include proposal-drafting experiments.

**Agent-native angle (Improvement Over Time):** rule refinement informed by a single Jason cut. Track future cuts as feedback signal.

---

## Category 9 — Spacing inconsistencies (P1)

**Multiple "fix spacing" / "tighten spacing" comments:**
- Section 7 spacing (between "7. TERM AND TERMINATION" and "A. Term:")
- Engagement Approach section
- Phase 3 section
- Investment and Terms section

**Pattern:** stray empty paragraphs scattered throughout the doc, and inconsistent before/after paragraph spacing applied to section headings.

**Root cause:** mix of:
- Empty paragraphs in the template that should have been deleted
- The skill's content-insertion adding empty paragraphs as separators
- Heading styles that have inconsistent `space_before` / `space_after` values

**Skill change:**

- **P1:** Audit the post-splice `templates/sow-template.docx` for stray empty paragraphs. The verify_proposal.py already checks "empty paragraphs > 20 = error"; tighten threshold and run on the template.
- **P1:** Apply consistent paragraph-spacing rules in the template: each numbered section heading gets `space_before=12pt, space_after=6pt`; each subsection heading (`A.`, `B.`) gets `space_before=6pt, space_after=3pt`. Body paragraphs no extra spacing.
- **P1:** When the skill inserts content, do not add extra empty paragraphs as separators; rely on the template's paragraph-spacing rules.

**Agent-native angle (Improvement Over Time):** template-level fix that benefits every future doc.

---

## Category 10 — Punctuation / content tightening (P2)

Three small fixes:

1. **"As agreed by the parties:" → "As agreed by the parties."** — Jason wants a period where there's currently a colon (or maybe nothing at end). Easy template fix.

2. **"This fee structure is valid through Q3 2026., with flexibility to start whenever works best for your team."** → **"This fee structure is valid through Q3 2026."** — Jason wants the trailing clause removed, ending the sentence with the quote-expiry date. (Note the existing "Q3 2026.," has a stray period before the comma — typo.)

3. **Yellow highlight on Optisense address line** — likely flagging that the address is still blank `__________________________________________________`. Per our HIGH-CONFIDENCE-or-blank rule, this is correct behavior IF the address lookup pass attempted and failed. But more likely the lookup pass didn't fire at all (since we only added it to SKILL.md guidance yesterday, and Jason's local skill version may not have included the new prompt instructions, OR the runtime LLM didn't act on the new guidance).

**Skill changes:**

- **P2:** Update the SOW skeleton "As agreed by the parties:" → "As agreed by the parties." in `templates/sow-template.docx`.
- **P2:** Update the Timing line in the SOW skeleton to remove the "with flexibility to start whenever works best for your team" trailing clause.
- **P1:** Verify the address-lookup pass is actually being invoked at runtime. If yes, what's the lookup logic returning for SkyFi (which is a known Austin TX company with public website)? If the pass isn't being invoked, that's a P1 fix.

---

## Category 11 — Single-machine assumption is the meta-bug (P0 — operational)

Stepping back: SkyFi is the first cross-machine run since the canonical-MSA splice + voice fixes. **It exposed a class of bugs that don't surface when Justin runs the skill** because Justin's machine has the right paths, the right test data, the right local resources.

The skill effectively had zero coverage for the "Jason runs it" scenario. The agent-native Parity principle says the same skill, run by anyone authorized, should produce the same output. Right now it doesn't.

**Operational change (not a code change):**

- **P0 process:** before declaring any future skill update "shipped," run an end-to-end test from Jason's machine (or a CI-equivalent fresh-checkout environment) and compare output to expected. The current cycle is "ship → Jason finds a class of bugs that don't repro for Justin → fix → ship again." A pre-flight run on a different machine would catch most of these earlier.

---

## Recommended changes summary, prioritized

### P0 (must fix before next proposal)

1. **Fix MSA Section 7 corruption** (Category 2). Audit + remove the runtime text-replacement that's clobbering MSA 7.B with SOW termination text. Move to semantic anchors / LLM placement. This is the clearest LLM-over-regex case in the entire corpus.

2. **Re-add MSA Section 7.C "Effect of Termination"** (Category 3). Update canonical MSA template, re-run splice. Add structural assertion that 7.A/B/C all present.

3. **Fix logo + footer cross-machine paths** (Category 1). Embed assets in template OR use SKILL_DIR-relative paths. Test from Jason's machine.

4. **Fix Section 11 bold bleeding** (Category 4). Edit canonical MSA template directly; add structural assertion.

5. **Simplify signature block to stacked layout** (Category 5). Drop two-column sig-block entirely from canonical MSA. Stacked is robust.

6. **Fix pricing `$######` partial-replacement bug** (Category 6). Match full pattern including hashes; verify_proposal.py adds `#{2,}` post-replacement guard.

7. **SOW signature block uses legal entity name** (Category 7). Update SOW token from `{CLIENT_COMPANY}` to legal-entity equivalent.

8. **Cross-machine pre-flight test** (Category 11). Before declaring any future skill update shipped, run from a non-Justin machine.

### P1 (next sprint)

9. **"Where This Could Go" hard-gate refinement** (Category 8). Extension must go BEYOND engagement's own Phase 2/3 deliverables; if it overlaps, drop it.

10. **Spacing consistency** (Category 9). Template-level paragraph-spacing rules; remove stray empty paragraphs.

11. **Verify address-lookup pass actually runs at runtime** (Category 10). Investigate whether the new pass we added 2026-05-06 is being invoked.

### P2 (polish)

12. **"As agreed by the parties." period fix** (Category 10).
13. **Timing line tightening** (Category 10).

---

## Meta: how this round should reshape the multi-agent rebuild track

The recurring pattern across AGR (yesterday) and SkyFi (today) is the same: documentation-driven enforcement keeps drifting, and the highest-leverage fixes are structural — code that makes the bad behavior impossible.

The multi-agent rebuild (`nvn` Agent 1, `wp2` Agent 2, `gt4` Agent 3) addresses most of these by construction:

- **Agent 2 (Assembly)** can be the only place that touches the .docx, and it can be written to never use absolute paragraph indices — semantic anchors only. This alone fixes Categories 2, 4, 5, 7, 9, and most of 6.
- **Agent 1 (Context & Draft)** with the new Step 0 enrichment passes catches Categories 8 and the address-lookup behavior.
- **Agent 3 (Visual Review)** with Playwright catches Categories 1, 4, 5, 9 visually before Jason ever sees the doc.

**The case for accelerating the multi-agent rebuild is now strong.** Documentation-driven incremental fixes are buying us less per session than the same effort spent on `wp2`. Suggested re-prioritization: bump `wp2` (Agent 2) to the highest-effort slot in the next 1-2 sessions.

---

## Appendix: Powerfleet's signed MSA is missing 7.C (legal flag)

Verified: the signed Powerfleet 2026-05-04 MSA does not contain Section 7.C "Effect of Termination." Powerfleet is operating under an MSA without an explicit clause about what's owed for work performed up to a termination date. Not Stafford's call to remediate, but flagging here so Justin can decide whether to amendment-letter the Powerfleet relationship.
