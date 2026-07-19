# Remix Tuning Experiment — Training Set Spec

**Date:** 2026-07-18 (**revised 2026-07-19** after auditing the knowledge-vault repo)
**Context:** Justin asked what it would take to safely experiment with tuning Inkling (Thinking Machines' 975B open-weights MoE) for Remix. Path: Tinker (managed fine-tuning, per-token billing). Validate on a small model (Qwen3-8B, ~$20-40) before spending on Inkling (~$150-500 at current 50% discount).
**Revision note:** v1 of this spec independently re-specced a question corpus, a PII scrub, and an eval harness. **All three already exist in `~/remix-knowledge-vault/`, more mature than what was proposed.** This version deletes the duplicated work and re-aims the experiment at the gap the vault's own eval data says is actually open.

---

## 1. Goal (re-aimed by the vault's eval data)

The vault's own mini-eval (`eval/runs/2026-07-18/mini-eval.md`) is the most important input to this spec:

- June 2026-06-14 baseline: **1/119 client-ready (~1%)**
- July 2026-07-18, post-scrub + quality sprint: **4/12 client-ready (33%), avg 3.7/5**
- Diagnosis in that file: *"most misses are score-4 answers failing only the send-unedited bar (one fixable defect each) — polish-class gaps, not substance-class."*

So the remaining gap is **register and polish, not knowledge**. That matters because retrieval/prompting already fixed most of the substance problem, and **voice/register is precisely what supervised fine-tuning is good at and what RAG is bad at.**

**Revised pilot question:** does tuning on our corpus move answers across the send-unedited bar — i.e. raise client-ready rate on the *existing* rubric and question set — beyond what the vault + prompting already achieve?

Non-goals: replacing Claude for client work, serving clients directly, multimodal anything, teaching the model facts the vault already retrieves well.

## 2. What already exists (do not rebuild)

| Asset | What it is | Where |
|---|---|---|
| **285 real client questions** | Ground-truth question corpus from real clients/leads/partners (~179 substantive) | `eval/questions/real-corpus.md` |
| **Answer key, ~41.6K words** | Gold answers + substance points per question, recovered from the real call/email where each was answered ("Answer Archaeology"), across 15 themes | `eval/answer-key/` |
| **Client-ready rubric** | The calibrated definition of good: 5 global criteria + per-question reference + durable-vs-perishable split. *"The bar in one line: an answer is client-ready if Justin or Jason would send it to a client unedited."* | `eval/rubric.md` |
| **Two scored eval runs w/ baselines** | 2026-06-14 (full 119) and 2026-07-18 (mini-12) | `eval/runs/` |
| **733 synthetic persona questions** | 100 DTRT-style personas + routed questions; methodology test set | `eval/questions/personas/` |
| **Scrubbed, shipping corpus** | 336 notes / ~313K words, privacy-linted at build | `dist/public-corpus/` |
| **Privacy system** | `VAULT-RULES.md` (5 rules + red-teamed fingerprint classes + logo-wall corollary), `privacy_lint.py` (roster-based, exit-1 on tier-1 hits), `export_public_corpus.py` (the ONLY sanctioned way to hand the corpus to any system) | `scripts/`, `VAULT-RULES.md` |
| **Voice layer** | ~20+ metaphors (jazz-not-marching-band, wok-jig-power-drill, portrait-vs-camera…), delivery + teaching notes | `voice/` |
| **Specifics library** | tools-and-models, numbers-and-benchmarks, framings-and-metaphors, example-outputs, prompts-and-jigs | `eval/specifics-library/` |

**Three v1 build steps are hereby deleted:** (a) run client-question-harvest — done, 285 questions; (b) design an eval — done, `rubric.md` + answer key + baselines; (c) hand-write a PII policy — done, `VAULT-RULES.md` + roster.

## 3. Corpus for training (revised)

Vault-derived material comes **only from `dist/public-corpus/`** — never the repo directly. This is a standing rule (`VAULT-RULES.md` → Enforcement), it applies to a tuning run exactly as it applies to Remix Advisor, and it means the vault half of the training data needs **zero new scrubbing**.

| Source | Status | Use |
|---|---|---|
| `dist/public-corpus/` (336 notes) | already scrubbed | Track A grounding, Track D house style |
| `eval/answer-key/` (41.6K words) | INTERNAL — real names, needs scrub | **highest-value pairs** (Track A) |
| `eval/questions/real-corpus.md` (285) | internal | the prompts side of Track A |
| Meeting transcripts (205 files, ~2M tokens) | raw, needs scrub | Track C advisory moves |
| Justin's sent email | raw, needs scrub | Track B voice |
| Partner-edit corpus (proposal-writer `judge/`) | internal | Track B — draft→edited pairs |
| CLIENT.md (108), proposals/SOWs (293) | raw, needs scrub | Track B/C, selectively |

## 4. Format: instruction→response pairs

SFT teaches behavior, not facts. Every example is a JSONL pair: realistic prompt → the answer Remix would actually give.

### Track A — Methodology Q&A (~35%) — *mostly pre-built*
The 285 real questions + their answer-key gold answers **are already an instruction→response dataset**. Work here is scrub + format, not authorship. Grade-A pairs where an answer-key entry exists; synthesize the rest from `dist/public-corpus/` notes. Held-out slice reserved for eval (see §6).

### Track B — Voice & polish (~35%, up-weighted)
This is where the measured gap lives, so it gets more weight than v1 proposed.
- **Partner-edit pairs** (draft → what Justin/Jason actually changed) are the highest-signal data we own for the send-unedited bar. Use edited finals as targets.
- Justin's sent email: incoming context → his actual reply (greetings, "-j", "!!", short paragraphs, B2B-capitalization exception).
- Proposal sections as shipped.
- **New idea from the eval:** mine the eval runs themselves for score-4-but-not-ready answers paired with a corrected version — direct supervision on exactly the defect class we're trying to close.

### Track C — Advisory moves (~25%)
From scrubbed transcripts: client statement/objection → how Justin or Jason actually responded. Reframes, pushback, "what would have to be true." Pull the `voice/metaphors/` catalog in as labeled moves — the vault already names ~20 of them.

### Track D — House rules (~5%)
No emdash in client-facing, chartreuse #E0F61F + ink #1D1D1C, numbered-options format, translatability, and the **durable-vs-perishable discipline** from the rubric (never state a stale tool pick as current). Demonstrated across other tracks plus a few explicit correction pairs.

## 5. PII scrub (revised — reuse the vault's system)

**Vault-derived material:** no new scrub. Use `export_public_corpus.py` output. Done.

**Everything else** (transcripts, email, answer-key, CLIENT.md, proposals) runs a two-stage local flow on the Mini — but anchored to the vault's existing standard, not a new hand-written policy:

1. **Redact (gpt-oss-20b via Ollama, local, free).** OpenAI's open-weights model, ~14GB MXFP4, sits alongside the existing gemma4 stack. Rewrites against `VAULT-RULES.md` — the same 5 rules, fingerprint classes, and logo-wall corollary that were already red-teamed. Names → stable role tags ("[CEO-ClientA]", consistent across that client's files so dialogue still reads).
2. **Verify — linter first, model second.** `privacy_lint.py` against the private-vault roster is *deterministic* and beats any model at catching known names; run it as the gate (exit 1 = fail). Use **gpt-oss-safeguard-20b** only for the judgment classes the linter can't pattern-match: fingerprint-class identifiability, the audience test, defamation-adjacent personnel characterizations. Failures loop back to step 1.
3. **Spot-check.** Stafford reviews a random 10% + every flagged-then-fixed file; Justin gets a one-page summary of what categories were removed.

Raw transcripts never upload to Tinker. Rationale for local: the point of scrubbing is that confidential text shouldn't transit a third-party API *before* it's clean.

**Open question for Justin:** the answer key is deliberately un-anonymized internal provenance. Scrubbing it costs some specificity. Recommend scrubbing it to the same bar as everything else for the pilot (internal-only model, but the discipline should hold from day one).

## 6. Eval — use the vault's, don't invent one

- Grade with **`eval/rubric.md`**, the existing bar, against **`eval/answer-key/`** substance points. Do not write a new rubric.
- **Hold out a slice of the 285 before training** (recommend the same ~12-question even-spaced sample as the 2026-07-18 mini-eval, plus ~40 more for power). Those never enter the training set.
- **Compare four arms on identical questions:** (1) base small model, (2) tuned small model, (3) Sonnet + `dist/public-corpus` in context — *the current production setup and the real incumbent*, (4) the 2026-07-18 run as historical reference.
- **Primary metric: client-ready rate** (the send-unedited bar), not average score. The July run's lesson is that avg-score 3.7 hides a 33% ready rate.
- Persona questions (733) available as a secondary generalization check.

**Go/no-go for the Inkling spend:** tuned small model beats its own base on client-ready rate AND materially closes the gap to arm 3. If tuning can't beat Sonnet-with-the-corpus, the honest answer is that the vault + prompting is already the right architecture and we skip Inkling. That is a legitimate and cheap outcome — worth ~$30 to learn.

## 7. Sizing & cost (revised down)

- Target **3,000-6,000 pairs**, ~1-2K tokens each → 5-10M tokens/epoch, 2-3 epochs.
- Qwen3-8B pilot: **~$10-30** train + a few dollars eval.
- Inkling run: **~$150-500** at the discounted $5.61/M train rate. Checkpoints $0.10/GB/mo.
- Build effort: **v1 said 2-3 sessions; now ~1.5-2**, because questions, answer key, rubric, scrub tooling, and the scrubbed corpus already exist. The remaining lift is the transcript/email extraction passes and JSONL assembly.

## 8. Build order (revised)

1. **Scrub the non-vault sources** — stand up gpt-oss-20b + gpt-oss-safeguard-20b on the Mini; wire `privacy_lint.py` as the gate; run over transcripts, answer-key, sampled email (§5).
2. **Assemble Track A** from the 285 questions + answer key (scrubbed) + `dist/public-corpus`. Reserve the held-out eval slice first.
3. **Assemble Track B** — partner-edit pairs, sent-mail pairs, eval-run polish pairs.
4. **Assemble Track C** — one LLM extraction pass over scrubbed transcripts, tagged against `voice/metaphors/`.
5. **Synthesize Track D**, assemble JSONL, split train/eval.
6. **Tinker pilot on Qwen3-8B** → grade with `eval/rubric.md` → four-arm comparison → go/no-go on Inkling.

## 9. Second-order note (worth raising separately)

The vault has become a genuinely serious asset: a scrubbed corpus, a real question corpus, a gold answer key, a calibrated rubric, and a measured improvement curve (1% → 33% client-ready in five weeks). **That eval harness is reusable far beyond this experiment** — it can grade Remix Advisor, the proposal writer's Judge, KirbyGPT, or any future client-facing answer system on the same bar. The tuning experiment should be framed as one more model plugged into an evaluation system we already own, not as a standalone project.

## Sources for pricing claims
- https://tinker-docs.thinkingmachines.ai/tinker/models/ (Inkling $1.87/$4.68/$5.61 per M at 50% discount; $0.10/GB/mo checkpoints)
- https://www.beam.cloud/blog/tinker-model-pricing (Qwen3-8B $0.44/M train after 2026-07-17)
