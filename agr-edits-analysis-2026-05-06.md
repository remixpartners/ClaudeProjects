# AGR Partners SOW: Jason's Edits Analysis & Skill Recommendations

**Date:** 2026-05-06
**Author:** Stafford
**Method:** Diff between `/tmp/AGR Partners_MSA & SOW_2026.05.05.docx` (Stafford-generated, 15:19 yesterday) and the Drive copy (Jason-edited, 18:54 yesterday)
**Working files:** `~/Projects/ClaudeProjects/agr-diff/` (raw diff + both extracted texts, durable)

---

## How I got the diff

The original plan was to read Google Doc comment-notification emails. There are none for AGR — Jason did the edits directly in the doc rather than using comments. Lucky break: the proposal-writer skill's build flow writes the .docx to `/tmp/` first and then copies to Drive (per `SKILL.md` Section 3). The /tmp copy survived. So I have the pre-Jason version and the post-Jason version on disk and could diff them paragraph-by-paragraph. The full diff is at `~/Projects/ClaudeProjects/agr-diff/03-raw-diff.txt`.

---

## TL;DR — Jason's edits sort into 11 categories

| # | Category | Edit volume | Skill change priority |
|---|---|---|---|
| 1 | **MSA legal-text gap** (skill used old MSA, Jason hand-upgraded to canonical) | Massive | P0 (already in beads `wp2`, this validates the priority) |
| 2 | **Client legal entity details** (name suffix, entity type, address) | High | P0 (new) |
| 3 | **Executive Summary tightening** (cut by ~50%, killed "inflection point" cliché) | Medium | P1 (new) |
| 4 | **Builder count miscounted** (skill said 2, Jason said 3) | Low | P1 (new) |
| 5 | **Client-language pickup over-aggressive** (Sarah's quote cut) | Low | P1 (new) |
| 6 | **Specific tool name capitalization** ("co-work" → "Cowork") | Low | P2 (new) |
| 7 | **Background — added pain point Stafford missed** (PowerPoint friction) | Medium | P1 (new) |
| 8 | **Key Dynamics ordering** (build-vs-buy bullet cut, sponsor moved to last) | Low | P2 (new) |
| 9 | **"Where This Could Go" — generic extension cut** (kept only Pulse) | Medium | P1 (new) |
| 10 | **Strategic Opportunity tightening** | Low | P2 (new) |
| 11 | **Pricing filled** (expected behavior, no skill change) | N/A | — |

The biggest by far is **Category 1**: Jason essentially rebuilt the canonical MSA by hand because the skill used the older `sow-template.docx` MSA. The CLIENT.md note from yesterday's run literally flagged this:
> "MSA legal text: this build uses the sow-template.docx MSA (not the locked Powerfleet 2026-05-04 canonical MSA). The canonical-MSA-append flow is part of the in-progress multi-agent rebuild and was not used for this draft."

Validation that the in-flight `wp2` (Agent 2: Assembly with canonical MSA) is the correct priority. **The single biggest improvement we can make is enforcing the canonical MSA in the existing skill flow ahead of the multi-agent rebuild.**

---

## Category 1 — MSA legal-text gap (P0)

**The pattern:** The Stafford-generated MSA was structurally identical to `templates/sow-template.docx`'s legacy MSA, which differs from the canonical Powerfleet 2026-05-04 MSA in seven ways. Jason hand-applied each delta.

**What Jason had to add or fix:**

1. **Section 2 (Fees) — added the suspension-of-services clause.** Original ended at "1.5% per month or the maximum rate permitted by law." Jason added: *"If any undisputed invoice remains unpaid more than fifteen (15) days past its due date, Consultant may, upon written notice to Client, suspend performance of the Services until such amounts are paid in full, and any such suspension shall not constitute a breach of this Agreement by Consultant."* This sentence is in the canonical MSA.

2. **Duplicate Section 5 bug (the worst structural bug).** The Stafford output had Section 5 (Consultant Tool IP) AND Section 5 (Confidentiality) — two sections numbered 5. Jason renumbered Confidentiality to Section 6 and cascaded the renumbering through 7, 8, 9, 10, 11. The canonical MSA has these correctly numbered.

3. **Section 9.D Assignment — added the entire clause.** Stafford's MSA was missing this clause entirely. Jason added the full paragraph about Affiliate transfers and successor-in-interest assignments. This clause IS in the canonical MSA.

4. **Section 11.C cross-reference — Jason did NOT fix this.** The reference still incorrectly says "Section 5, Confidentiality" when Confidentiality is now Section 6. The canonical MSA has this corrected to "Section 6, Confidentiality" (we fixed it during the canonical-MSA build script). Worth noting Jason missed it; the skill output also has it wrong; the canonical lock has it right.

**Skill change:**
- **P0:** Replace the MSA inside `templates/sow-template.docx` with the locked canonical MSA from `templates/msa-canonical-2026-05-04.docx`. Or better, structurally enforce the "canonical MSA + SOW skeleton" build at runtime (issue `wp2`).
- **Why this matters most:** Every Remix proposal until `wp2` ships is shipping a legally-incomplete MSA. Jason caught it for AGR. He may not catch it next time. Pacific Transformer, Hirewell Pulse, NineStar, etc. likely have the same legacy MSA shipped, depending on when they signed.

**Agent-native angle (Improvement Over Time):** the canonical MSA is data; the "use canonical MSA always" rule is a one-line policy in the skill. Both deploy without code shipping. The current state of the skill HAS this written down (Section 0 of SKILL.md tells the runtime to use the canonical), but the runtime isn't enforcing it — it picked the legacy path. **Documentation alone wasn't enough.** This is a Parity violation: the canonical MSA is the source of truth Jason expects, but the skill's actual behavior diverged silently. Need either: (a) the runtime LLM more aggressively reading and obeying SKILL.md Section 0, or (b) a structural assertion that fails the build if the output's section numbers don't match the canonical.

**LLM over regex:** the assertion is a structural check on parsed XML, not regex on Word XML — same pattern as the `force_trailing_sectpr_single_column()` we already shipped.

---

## Category 2 — Client legal entity details (P0)

**Three corrections:**

| Field | Stafford output | Jason fix |
|---|---|---|
| Remix entity type | "a corporation" | "an Illinois corporation" |
| Client name | "AGR Partners" | "AGR Partners LLC" |
| Client entity type | "a corporation" | "a limited liability company" |
| Client address | `__________________________________________________` (blank) | "212 W. Superior St., Suite 500, Chicago, Illinois 60654" |

**Why these slipped through:**

1. **Remix's own entity type was wrong.** The legacy MSA has "a corporation"; the canonical MSA has "an Illinois corporation." Same root cause as Category 1 (legacy MSA used).

2. **Client name suffix was missing.** The skill's resolution chain for legal name (per the schema-fix we shipped 2026-05-05) is: prior signed MSA → transcript → ask Justin. AGR has no prior signed MSA. The transcript may not have stated "AGR Partners LLC" verbatim. Justin wasn't asked. Net: the skill defaulted to display name.

3. **Client entity type defaulted to "a corporation."** The skill currently has no source-of-truth for entity type. CLIENT.md describes AGR as a "PE/investment firm" — that's a business description, not a legal entity. The "LLC" suffix in the legal name is itself the strongest signal of entity type, and the skill missed the inference.

4. **Client address left blank.** The voice guide says "Yellow blank — Manual entry — do NOT auto-populate." That's a deliberate policy. Jason filled it manually, as designed. **No skill change for the address fill itself**, but the "do NOT auto-populate" policy may be too strict — the address can usually be looked up reliably (company website, Google Maps, secretary of state filings). Worth revisiting whether to attempt a lookup with HIGH-CONFIDENCE-or-blank rule.

**Skill changes:**

- **P0:** Add a deterministic legal-entity inference rule: if the resolved client name ends in `LLC`, `L.L.C.`, `Ltd.`, `Inc.`, `Corp.`, `Co.`, `LP`, `LLP`, `PLLC`, etc., infer the entity type accordingly. If no suffix and prior signed MSA exists, pull from there. If neither, ask Justin before generating. This is a deterministic mapping (suffix → entity-type phrase) — appropriate for code, not LLM. **Exception to "LLM over regex":** legal entity-type strings are a closed-vocabulary problem; a 10-line lookup table is right.

- **P0:** Add an "address lookup" pass: search the client's website + Google Maps for the principal place of business. If results converge across sources with high confidence (≥ 2 matching sources), populate the address. If not, leave the yellow blank. This is an LLM-driven research pass, not a regex; "LLM over regex" applies. **Agent-native angle (Granularity):** this is a primitive — `lookup_client_address(name) -> Address | None`. The skill composes it. Future skills (engagement letters, invoices) can reuse it.

- **P0:** Update the schema-fix work we did yesterday: `{{CLIENT_ENTITY_TYPE}}` resolution now adds suffix-inference as the fastest path before falling back to prior MSA / transcript / ask-Justin.

---

## Category 3 — Executive Summary tightening (P1)

**Paragraph 2: Stafford 4 sentences, Jason 2 sentences.**

**Stafford original:**
> "AGR stands at a strategic inflection point. The team has already organized its AI thinking around four clear verticals (Origination, Execution, Portfolio Management, and Fundraising and Investor Relations); a senior partner who has personally invested in agentic AI training and who has framed the build-versus-buy question with rigor; and at least two builder-class teammates inside the org, including an in-house engineer rolling out an NDA review agent and a model-building skill, and an incoming MBA summer hire who is already shipping skills in Claude Code. Those ingredients are uncommon at AGR's stage, and they shorten the runway between this engagement and lasting impact."

**Jason fix:**
> "AGR has three ingredients that shorten the runway to lasting impact: a senior partner sponsoring the effort with rigor, three internal builders already shipping working tools, and a four-vertical operating model that organizes AI opportunities naturally. Those are uncommon at this stage."

**What Jason changed:**
- Killed "AGR stands at a strategic inflection point" (already in voice guide as a banned cliché — it survived)
- Cut total length by ~55%
- Restructured from "long colon-with-semicolons sentence" into "three ingredients colon list"
- Builder count corrected (2 → 3, see Category 4)

**Paragraph 3: similar treatment.**

**Stafford original:**
> "This engagement will equip AGR's team with a shared vocabulary for generative AI, a prioritized set of opportunities mapped to the four-vertical model, and a 30/60/90-day plan that names what should be built in-house, what is worth buying, and what should wait. By the end of six weeks, AGR will be in position to make the $20,000-to-$50,000 vendor decision on the merits and to capture the operational gains that a lean, decentralized team needs to support 22 partnerships well."

**Jason fix:**
> "By the end of six weeks, AGR will have a shared AI vocabulary, a prioritized opportunity map across the four verticals, and a 30/60/90-day plan that names what to build, what to buy, and what to wait on."

**What Jason changed:**
- Removed the dollar-amount reference to the vendor pricing ($20K-$50K)
- Cut the "support 22 partnerships well" closing
- Combined two sentences into one

**Skill changes:**

- **P1:** Add "stands at a strategic inflection point" to the banned-phrase list in `anti-ai-vocabulary.md`. The phrase is in the Remix Proposals voice guide as a Remix-ism — but apparently the runtime drifted toward overuse. Specifically ban this exact construction.

- **P1:** Tighten the Executive Summary length expectations in `offers/kickstart.md`. Paragraph 2 should be 2-3 sentences max. Paragraph 3 should be 1-2 sentences max. Currently the offer template encourages longer paragraphs.

- **P1:** Add a rule: do NOT include external-vendor pricing dollar amounts in the Executive Summary unless Justin explicitly confirms. Vendor pricing changes; what's $20K-$50K today might be different tomorrow. Anchor on the *decision* (build-vs-buy) not the *number*.

**Agent-native angle (Improvement Over Time):** this is a prompt edit. Update the offer template, the next proposal benefits. No code change needed.

**LLM over regex:** the banned phrase needs LLM judgment to catch variants ("inflection moment," "pivotal point," etc.); a literal regex on the exact phrase would miss paraphrases.

---

## Category 4 — Builder count miscounted (P1)

**Stafford said:** "two builder-class teammates" (in-house builder + MBA summer hire)
**Jason corrected to:** "three internal builders"

The third is **Elizabeth** (operations/finance lead), described in CLIENT.md as: *"Built daily-briefing skill that takes Ejnar's flagged emails and produces a daily briefing... Also uses Claude to convert screenshots of member directories... into enriched spreadsheets... Ahead of the curve on skill building."*

The data was AVAILABLE in CLIENT.md. Stafford undercounted because the inference "Elizabeth has shipped two skills, therefore she's a builder" wasn't triggered.

**Skill change:**

- **P1:** Add a structured "team capability inventory" pass to the Step 0 client-language pickup. For each named team member in CLIENT.md, classify their AI sophistication tier: `builder` / `advanced user` / `light user` / `none`. Anyone who has shipped a working skill or agent → `builder`. Use the resulting counts in the Executive Summary's "ingredients" sentence.

**Agent-native angle (Granularity):** this is a primitive — `classify_team_capability(client_md_text) -> dict[name, tier]`. Atomic, composable, reusable across proposals and engagement-prep skills.

**LLM over regex:** classification is judgment, not pattern-matching. LLM-driven.

---

## Category 5 — Client-language pickup over-aggressive (P1)

**Stafford included Sarah-MBA's "effectively, not just efficiently" framing in Strategic Opportunity:**
> "The deeper move is the one the incoming summer hire named on the call: distillation that is "effectively, not just efficiently." That is the central design principle for what we build together..."

**Jason cut to:**
> "The deeper move is organizing AGR's institutional knowledge so that AI agents can do real work inside AGR's voice, judgment, and standards rather than producing generic output."

He killed both the quote and the attribution. Three plausible reasons:
1. The phrase is too cute / marketing-speak
2. Sarah is too junior (incoming summer hire) to be named in a proposal — even via "the incoming summer hire" attribution — when the audience is the senior partner
3. The phrase doesn't actually advance the argument; it's quoted for quote's sake

**Pattern from this and the kickstart.md guidance:** the client-language-pickup pass is doing what we asked, but is including phrases of equal weight regardless of WHO said them. Jason is implicitly weighting by speaker seniority and rhetorical strength.

**Skill change:**

- **P1:** Update the Step 0 client-language pickup pass to weight phrases by:
  1. Speaker seniority (decision-maker / senior partner > associate > summer hire / new hire)
  2. Phrase strength (a compact metaphor or concrete pain point > an abstract distinction)
  3. Frequency in the transcript (used twice or referenced > said once and dropped)
- Surface 3-5 candidates ranked by these weights. Include the top 1-2 in the prose, not all of them.

**Agent-native angle (Emergent Capability):** this is a refinement of an existing pass. As we run more proposals, we'll see which phrase weightings produce signed proposals vs. heavily-edited drafts. Track Jason's "kept" vs "cut" decisions as a feedback signal.

---

## Category 6 — Specific tool name capitalization (P2)

**Stafford:** "co-work environment" (lowercase, with hyphen)
**Jason:** "Cowork environment" (capitalized, no hyphen)

**Cowork** is a specific tool name (Cowork.is or similar); it's a proper noun, not a common noun. The CLIENT.md actually describes Brock as "Using a 'co-work' tool (possibly Cloak or similar)" — note the parenthetical uncertainty in CLIENT.md. Jason knew the tool's actual canonical name and capitalization.

**Skill change:**

- **P2:** Add a tool-name normalization pass: maintain a list of canonical tool names with capitalization (Cowork, ChatGPT, Claude Code, CapIQ, SharePoint, Slack, Teams, etc.). Before final output, the LLM scans for variants ("co-work", "chatgpt", "claude code", "cap iq") and normalizes to the canonical form.

**LLM over regex:** the LLM does this trivially and handles ambiguity (e.g., "co-work" might be the verb, not the tool name — context-dependent). A regex would over-replace.

**Agent-native angle (Improvement Over Time):** the canonical-tool-name list is a markdown reference loaded by the skill. New tool names get added to the file; the skill picks them up on next invocation, no code change.

---

## Category 7 — Background pain point Stafford missed (P1)

**Jason added a sentence to Current Situation:**
> "A recurring friction point across the investment team is time spent polishing presentations and models in PowerPoint, particularly on origination decks where visual quality matters but manual formatting consumes hours."

This is in CLIENT.md (Sarah-origination: *"Spends significant time 'prettying up' presentations - sees this as a major time sink she wants to solve."*). Stafford had access to it and didn't surface it.

**Why this matters more than just "Stafford missed a fact":** The omitted pain point is exactly the kind of thing the skill is supposed to mirror back as evidence we listened. Voice guide explicitly calls out this move (paraphrasing): *"signed proposals echo the client's own pain points back to them."* The PowerPoint-polishing pain point connects directly to the "presentation polish" item already in Phase 2 Team Activities — but the *connection* (named pain point in Background → mapped to engagement activity in Phase 2) wasn't made.

**Skill change:**

- **P1:** Strengthen the Step 0 pass: extract specific pain points named in CLIENT.md (per team member if relevant) and require they appear in Background & Context, mapped to engagement activities in Phase 2 where applicable. The mapping itself is a quality signal.

**Agent-native angle (Parity):** if Justin and Jason expect the pain points to surface, the skill should surface them by default. Currently it surfaces *some* pain points (the four-vertical model, build-vs-buy, lean team) but missed the team-member-specific ones.

**LLM over regex:** classification of "what is a pain point in this CLIENT.md" requires LLM judgment.

---

## Category 8 — Key Dynamics ordering (P2)

**Stafford's bullets (in order):**
1. Senior partner sponsorship
2. Four-vertical model
3. Lean and decentralized
4. Build-vs-buy decision pending
5. Internal builders (count: 2)
6. AI sophistication uneven

**Jason's bullets (in order):**
1. Four-vertical model
2. Lean and decentralized
3. Internal builders (count: 3, with detail)
4. AI sophistication uneven
5. Senior partner sponsorship + MIT course

**Removed entirely:** the build-vs-buy decision bullet (it appears in Strategic Opportunity instead, where it belongs)

**Reordered:** structural facts about the team lead (verticals, lean/decentralized, builder count, sophistication spread); sponsorship moved to last as flavor.

**Skill change:**

- **P2:** Add ordering guidance to `offers/kickstart.md` Background & Context: "Lead with structural team facts (org model, size/distribution, capability inventory). Close with engagement-specific characteristics (sponsorship, special preparation, motivating constraint). Strategy/decision questions belong in Strategic Opportunity, not Background."

**Agent-native angle (Composability):** this is a structural rule for one section, but it composes — apply the same "structural-first, flavor-last" pattern in other Background-style sections (Pulse, AIBA).

---

## Category 9 — "Where This Could Go" — generic extension cut (P1)

The voice guide explicitly says (Section 04-remix-proposals-voice.md, derived from corpus):
> "Each [extension] must use a client-specific noun (the name of a system, a department, a constituency, a project). Generic 'ongoing advisory' is a fallback for the second one only. Never both generic."

Stafford produced two extensions:
1. "Extending Capability Across the Team" (no client-specific noun — generic)
2. "Ongoing Advisory Service" (Pulse — fine as the second, generic-allowed)

Jason cut #1 entirely and kept only Pulse.

**The voice guide already has the rule.** Stafford ignored it.

**Skill change:**

- **P1:** Make the "Where This Could Go" check a hard gate. If neither extension has a client-specific noun, regenerate. If only Pulse can be specific, ship only Pulse (single extension is acceptable). The voice guide rule needs runtime enforcement, not just inclusion in the reference doc.

**Agent-native angle (Parity):** the voice guide is the policy; the runtime should obey it. Drift between policy and behavior is a parity failure.

**LLM over regex:** "is this noun client-specific?" is judgment, not pattern matching.

---

## Category 10 — Strategic Opportunity tightening (P2)

Minor — Jason cut "(and builder)" parenthetical from "sharp enough buyer (and builder)" → "sharp enough builder" and added a transitional clause "(with example use cases included below)". Mostly stylistic, low-stakes.

**Skill change:** none beyond Category 3's general tightening guidance.

---

## Category 11 — Pricing filled (no skill change)

Stafford left `$######` everywhere as designed. Jason filled in $25,000 / $12,500 / $12,500 before sending. **This is the intended workflow** per skill policy (pricing is Justin/Jason judgment, not skill judgment). No change needed.

---

## Recommendations summary, prioritized

### P0 (must fix before next proposal)

1. **Enforce canonical MSA at runtime, not just in docs.** The current state of the skill DOCUMENTS the canonical-MSA build sequence in SKILL.md Section 2 but the runtime LLM didn't follow it. Either (a) make `templates/sow-template.docx` itself contain the canonical MSA (ship-side fix) or (b) add a structural assertion that fails the build if the MSA section structure doesn't match canonical. Option (a) is the fastest path. **Closes the gap that this analysis is documenting.** Tracked in beads as `wp2`; consider a tactical "swap the MSA in sow-template" precursor as P0.

2. **Legal entity-type inference from name suffix.** Deterministic suffix-to-entity-type lookup. When the client name ends in `LLC`, infer entity type "limited liability company"; `Inc.` → "corporation"; `LP` → "limited partnership"; etc. Falls back to prior MSA → transcript → ask Justin only when no suffix is present.

3. **Address lookup pass.** Try website + Google Maps + secretary-of-state lookups. Populate when ≥ 2 sources agree; leave yellow blank when no consensus. LLM-driven research, not regex.

### P1 (next sprint)

4. **Tighten Executive Summary length** in `offers/kickstart.md`. P2 = 2-3 sentences max. P3 = 1-2 sentences max. Update offer template guidance.

5. **Ban "stands at a strategic inflection point"** explicitly in `anti-ai-vocabulary.md`. (LLM-driven match including paraphrases.)

6. **Ban external-vendor pricing dollar amounts in Executive Summary** unless Justin explicitly confirms.

7. **Team capability inventory pass** at Step 0. Classify each named team member into builder / advanced / light / none. Use accurate counts in narrative.

8. **Speaker-seniority-weighted client-language pickup.** Don't surface every distinctive phrase equally. Weight by speaker seniority + phrase strength + frequency.

9. **Pain-point surfacing pass.** Pull team-member-specific pain points from CLIENT.md, ensure they appear in Background & Context with mapping to Phase 2 activities where relevant.

10. **"Where This Could Go" — hard gate on client-specific nouns.** Regenerate if neither extension is specific; ship one if only one can be specific.

### P2 (polish)

11. **Tool-name canonicalization pass** with a maintained list (Cowork, ChatGPT, CapIQ, etc.).

12. **Key Dynamics ordering rule** (structural-first, flavor-last; strategic decisions belong in Strategic Opportunity).

13. **Section 11.C cross-reference fix** — Jason missed it in the AGR doc; the canonical lock has it correct. Future proposals using the canonical will have it right by construction.

---

## Meta-observations for the multi-agent rebuild (`nvn` / `wp2` / `gt4`)

Several of these category fixes converge on architecture decisions worth pre-empting in the rebuild:

- **Agent 1 (Context & Draft) needs a richer Step 0.** Today's Step 0 is "extract distinctive client phrases." After AGR, it should also produce: team capability inventory (builder count, sophistication tiers), pain-point inventory (per team member), and weighted phrase list (not flat list). These are atomic primitives that compose into the prose.

- **Agent 2 (Assembly) needs to be the *only* MSA author.** Documentation-driven enforcement of "use the canonical MSA" failed for AGR. Code-driven enforcement (the assembly agent literally cannot output anything BUT the canonical MSA + tokens) is structurally robust. This is the granularity argument.

- **Agent 3 (Visual Review) wouldn't have caught most of these.** Most edits are content/voice/legal-text issues, not visual layout. Agent 3 is still the right design for what it covers (page breaks, double-column, table overflow), but it doesn't substitute for content quality. Reaffirms that quality work belongs in Agent 1.

- **The "Pacific Transformer test" five questions in `offers/kickstart.md` would have caught:** "stands at a strategic inflection point" usage, missing pain-point connection. The questions are present; the runtime didn't actually run them. Same parity failure as Category 1. The rebuild should make the self-check a literal prompt step, not a passive reference.

---

## Recommended beads issue updates

Will create separately. Anticipated:

| Action | Issue | Notes |
|---|---|---|
| New P0 | Enforce canonical MSA in current skill flow (precursor to wp2) | Tactical precursor: replace MSA inside `sow-template.docx` with canonical, OR force runtime to assemble from canonical |
| New P0 | Legal entity-type suffix inference + address lookup pass | Composable primitives |
| New P1 | Tighten Executive Summary, ban "inflection point", ban vendor pricing | Update offer template + anti-vocab |
| New P1 | Step 0 enrichment: team capability inventory + pain-point pass + speaker-weighted phrases | Atomic primitives feeding Step 0 |
| New P1 | "Where This Could Go" hard gate | Voice-guide rule needs runtime enforcement |
| New P2 | Tool-name canonicalization | Maintained list + LLM normalization |
| New P2 | Key Dynamics ordering rule | Offer template guidance |

---

## Appendix: full diff

`~/Projects/ClaudeProjects/agr-diff/03-raw-diff.txt` — 390 lines, every paragraph-level change Jason made.
