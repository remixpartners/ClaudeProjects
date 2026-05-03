# Special Episode Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code skill that turns a list of pasted links into a single deep, NPR-style spoken-word script saved to Justin's `_DailyPodcast` Drive folder.

**Architecture:** Markdown-based orchestration skill at `~/.claude/skills/skills/special-episode/`. Per-link sub-agents fetch + produce structured "deep treatments" in parallel. Main agent assembles cold open + segments + themes-across + outro. `/rewriter` polishes using a new `npr-narrator` voice profile at `~/.claude/skills/rewriter/voices/npr-narrator.md`.

**Tech Stack:** Pure markdown skills (no code), Claude Code Task tool for parallel sub-agent dispatch, existing `/rewriter` skill for polish, `yt-dlp` for YouTube transcripts (already installed), Chrome MCP for paywalled content, ElevenLabs Reader on phone (out of scope) for audio.

**Reference spec:** [docs/superpowers/specs/2026-05-03-special-episode-skill-design.md](../specs/2026-05-03-special-episode-skill-design.md)

---

## File Structure

**Voice profile (gitignored by default per existing rewriter convention):**
- Create: `~/.claude/skills/rewriter/voices/npr-narrator.md`

**Skill files (committed to `remixpartners/claude-skills` repo at `~/.claude/skills/`):**
- Create: `~/.claude/skills/skills/special-episode/SKILL.md` - orchestration logic + frontmatter
- Create: `~/.claude/skills/skills/special-episode/README.md` - human-readable overview
- Create: `~/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md` - per-link sub-agent prompt
- Create: `~/.claude/skills/skills/special-episode/prompts/assembly-prompt.md` - main agent assembly prompt

**Documentation updates:**
- Modify: `/Users/justinmassa/CLAUDE.md` (add skill to "Remix Skills" section, voice profile to "Voice guides" section)
- Modify: `~/.claude/skills/README.md` (add skill to skill inventory)

**Created on first run (not in setup):**
- `~/Projects/special-episode-archive/YYYY-MM-DD-<slug>/` - per-episode treatments archive

---

## Notes for the executing engineer

- **This is a markdown-content skill, not code.** "Tests" mean running the skill end-to-end and validating the output. There is no pytest, no compilation step. Validation is manual review of generated scripts and listening through ElevenLabs Reader.
- **The voice profile is the contract.** The script writer (the orchestration logic) and the rewriter (the polish step) both read from `npr-narrator.md`. If the voice profile drifts from what the orchestration produces, you get inconsistent output. Keep them aligned.
- **Don't invent the voice profile alone.** Layers 1-3 should be derived from real public radio transcripts (Fresh Air, This American Life, On Being, 99% Invisible, Planet Money). Layer 4 should be derived from the existing `chief-of-staff/prompts/podcast-prompt.md` and `chief-of-staff/prompts/rewriter-pass-prompt.md` - those are working production prompts that already encode this voice.
- **CLAUDE.md banned punctuation:** never use em-dashes (—) or double-dashes (--) in prose. Use single dashes with spaces, parentheses, semicolons, periods, or rewrite. This applies inside the skill content too. The existing briefing files use this convention; mirror it.
- **All paths are absolute.** When writing the skill instructions, use full paths (no `~`) where the runtime engineer or Claude needs to act.

---

## Task 1: Build the npr-narrator voice profile

**Files:**
- Create: `/Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md`

**Reference material to read first:**
- `/Users/justinmassa/.claude/skills/rewriter/voices/justin.md` - structural reference for layers
- `/Users/justinmassa/chief-of-staff/prompts/podcast-prompt.md` - source for voice/tone rules
- `/Users/justinmassa/chief-of-staff/prompts/rewriter-pass-prompt.md` - source for spoken-word mechanics
- `/Users/justinmassa/Library/CloudStorage/GoogleDrive-justin@remixpartners.ai/My Drive/_DailyPodcast/2026-04-30-briefing.md` - example of working output

- [ ] **Step 1: Read all reference material**

Read the four files listed above end-to-end. Note the structure of `justin.md` (Layer 1 / Layer 2 / Layer 3). Note the rules and patterns in the two chief-of-staff prompts. Note how `<break>` tags, numbers-as-words, and source attribution appear in the working briefing example.

- [ ] **Step 2: Create the voice profile file with full content**

Write the complete file at `/Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md`. The file must contain all four layers. Below is the complete required structure with content guidance for each layer. Do not abbreviate. Do not write "TBD." Write the full prose.

```markdown
# NPR Narrator - Voice Guide

> Warm, intellectually curious, calmly authoritative. The voice of a knowledgeable colleague who has read the piece for you and is walking you through it on a long drive. Built from the conventions of Fresh Air, This American Life, On Being, 99% Invisible, and Planet Money. Optimized for spoken-word delivery via ElevenLabs Reader.

**Source material:** Public transcripts and audio from Fresh Air (Terry Gross), This American Life (Ira Glass and producers), On Being (Krista Tippett), 99% Invisible (Roman Mars), Planet Money (rotating hosts). Plus working production conventions from the Remix daily briefing pipeline.

**Last updated:** [date you write this]

---

## Layer 1: Idea Architecture

[REQUIRED CONTENT - write 200-400 words covering:]

- **Primary pattern:** how an NPR narrator structures a deep dive on a piece of writing or reporting. The pattern is: gentle setup of why this matters, then walking through the source structurally, then naming what's interesting or unresolved. Never lead with the conclusion. Build toward it.
- **Topic introduction:** a calm orienting sentence before launching into detail. Examples from real NPR: "There's a piece in this week's New Yorker that's been on my mind." / "I want to walk you through an essay published yesterday in Stratechery." Use plain, declarative openings.
- **Evidence-stacking:** lay out what the author says, with their examples, in roughly the order they say it. Cliff's Notes faithfulness over compression.
- **Lingering:** when something in the source is genuinely surprising or vivid, slow down. Quote it. Let it breathe. Don't rush to the next bullet.
- **Soft handoffs:** between segments, use spoken transitions ("Alright, second piece," / "Next up." / "Here's where it gets interesting.") rather than hard structural breaks. Never read aloud headers like "Section 2."
- **Sitting with tension:** if the source raises a question it doesn't resolve, say so, and stop. Don't manufacture closure.

## Layer 2: Persuasion Patterns

[REQUIRED CONTENT - write 150-300 words covering:]

- **Attribution discipline:** lead with the source name. "From The New Yorker, Helen Rosner writes that..." / "Ben Thompson, in this week's Stratechery..." Sources get named on-air clearly. The format is "from [Source Name] dot [TLD]" when introducing a piece by URL ("from stratechery dot com," "from the new yorker dot com," "from youtube dot com").
- **Quote integration:** when quoting the source, use natural in-line markers: "And I'll quote..." / "As [author] writes..." / "Here's the line..." Pause briefly before and after. Don't say "open quote / close quote."
- **Counterpoints:** when the source engages a counterargument, voice it as the source does. The narrator does not editorialize against the piece. The narrator faithfully represents what the author thinks AND what the author engages with.
- **No advocacy:** the narrator is not selling the piece. Just walking through it. Light enthusiasm where genuinely warranted ("This part is fun.") but no hype.
- **Light Remix relevance:** at most one or two sentences per piece, woven in casually. "Worth flagging for our work because..." / "Familiar territory for anyone thinking about..." Then move on.

## Layer 3: Sentence Patterns

[REQUIRED CONTENT - write 150-300 words covering:]

- **Spoken sentence length:** short-to-medium default (8 to 18 words). Build long sentences from strong short ones, not from cobbled clauses. A speaker has to breathe; long stacked clauses fail aloud.
- **Vary rhythm:** short-long-short creates pulse. Three short sentences in a row creates emphasis. Don't let every sentence have the same cadence.
- **Active voice, positive form:** "Tesla's revenue fell" not "a decline in revenue was observed." State what is, not what isn't.
- **Concrete over abstract:** numbers, names, specifics. Not "significant growth" but "revenue doubled."
- **Connective tissue:** "And," "But," "So," start sentences freely. Cut "moreover," "furthermore," "however," "in addition," "that said," "additionally."
- **No logical signposts:** cut "therefore," "thus," "hence," "accordingly." If the logic is clear, the listener follows.
- **Emphatic endings:** put the important word at the end of the sentence. Audio rewards this; the listener's attention crests at the period.
- **Contractions are good:** "it's," "that's," "they've." Speakers contract; readers don't notice.
- **Paragraph rhythm:** short paragraphs (1-3 sentences). Aggressive line breaks. Each paragraph break is a half-second pause for the reader.

## Layer 4: Spoken-Word Mechanics (PRESERVE VERBATIM IN VOICE LAYER)

> **Note to rewriter sub-agents:** the rules in this section are not stylistic recommendations. They are the contract with ElevenLabs Reader and must be preserved verbatim in the output. The Anti-AI Scrub stage MUST NOT strip `<break>` tags, MUST NOT convert spelled-out numbers back to numerals, MUST NOT rewrite source attributions out of "from X dot Y" form, and MUST NOT replace the quote-integration markers with formal quotation patterns.

### Pause notation

Use `<break time="X.Xs" />` tags for pauses. ElevenLabs Reader respects these.

- **Standard inter-paragraph pauses:** none needed (paragraph break is enough)
- **Section transitions:** `<break time="1.0s" />` between major segments (cold open to first piece, between pieces, into themes-across, into outro)
- **Major transitions:** `<break time="1.5s" />` or `<break time="2.0s" />` for the biggest beats (cold open to first piece, themes-across to outro)
- **Within-segment beats:** `<break time="0.5s" />` sparingly, when a thought genuinely needs a half-beat for emphasis

Never use other SSML tags. Just `<break>`.

### Numbers and dates as words

- Dates: "January eighteenth twenty twenty-six," not "1/18/2026" or "January 18, 2026"
- Years: "twenty twenty-six," not "2026"
- Percentages: "forty percent," not "40%"
- Decimals: "three point two five," not "3.25"
- Ranges: "five to ten," not "5-10"
- Money: "three hundred billion dollars," not "$300B"
- Fractions: "two-thirds," not "2/3"

Exception: model names and product version numbers stay literal ("GPT-5," "Claude 4.7," "iOS 18"). The narrator names them as written.

### Source attribution format

- Inline introduction: "from [Source Name] dot [TLD]"
- Examples: "from stratechery dot com," "from the new yorker dot com," "from youtube dot com," "from arxiv dot org"
- Author attribution: "Ben Thompson writes..." / "Helen Rosner argues..." / "In a recent piece, Cory Doctorow..."
- NEVER read URLs aloud. The TLD substitute is sufficient.

### Quote integration

- Lead-in: "And I'll quote..." / "As [author] writes..." / "Here's the line..." / "The author puts it this way..."
- After the quote, return to narration without "end quote" or "unquote." The pause after the quote is enough.
- Long quotes (more than ~30 words): break naturally for breath; don't read a 100-word quote as one sentence even if the source had it that way.

### Anti-AI scrub list (carried forward from existing rewriter prompt)

[Reproduce the cursed-vocabulary and pattern lists from chief-of-staff/prompts/rewriter-pass-prompt.md verbatim. This is critical content - do NOT abbreviate. Include:
- Cursed vocabulary list (delve, intricate, tapestry, pivotal, underscore, etc.)
- Significance inflation patterns
- Copula avoidance patterns
- Negative parallelisms
- Rule of three avoidance
- Synonym cycling
- Rhetorical questions as transitions
- Superficial -ing analyses
- False ranges
- Hedging pileups
- Promotional tone
- Compulsive summaries
- Sentence-length uniformity
- Em-dash and double-dash ban (per Justin's standing rule)]

### What to never do

- Read aloud markdown headers (`##`, `###`)
- Read aloud URLs character-by-character
- Read aloud HTML comments
- Use em-dashes (—) or double-dashes (--) in prose
- Convert spelled-out numbers back to numerals during scrub
- Strip `<break>` tags during scrub

---

## How to invoke this voice

When `/rewriter` runs with this voice profile:
1. Strategist stage: preserve the spoken structure (don't restructure for print). Treatments are walking-through-the-piece order, not lede-first journalism order.
2. Craftsman stage: enforce sentence-length and rhythm rules in Layer 3.
3. Anti-AI Scrub stage: apply the scrub list in Layer 4 BUT preserve the items in the "preserve verbatim" notice at the top of Layer 4.
4. Voice Layer stage: ensure the writing matches Layers 1, 2, 3 throughout. Confirm `<break>` tags are intact. Confirm numbers are still spelled out. Confirm source attributions are still in "from X dot Y" form.
```

When writing the file: replace the `[REQUIRED CONTENT - write...]` placeholders with the actual prose described. Replace the `[Reproduce the cursed-vocabulary...]` placeholder by reading `/Users/justinmassa/chief-of-staff/prompts/rewriter-pass-prompt.md` and copying its scrub-list content verbatim into Layer 4. Replace `[date you write this]` with the actual date.

- [ ] **Step 3: Verify the file is well-formed**

Run: `wc -l /Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md`
Expected: at least 150 lines.

Run: `grep -c "TBD\|TODO\|REQUIRED CONTENT" /Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md`
Expected: `0` (zero remaining placeholders).

Run: `grep -E "—|--" /Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md | grep -v "<!--\|-->\|---\|<break"`
Expected: no output (no banned em-dashes or prose double-dashes; matches like `<!--`, `-->`, `---` markdown separators, and `<break>` tags are allowed).

- [ ] **Step 4: Verify rewriter auto-detects the voice profile**

The rewriter SKILL.md auto-detects voices from `voices/*.md`. Spot-check by reading lines 50-90 of `/Users/justinmassa/.claude/skills/rewriter/SKILL.md`. Confirm the auto-detect logic exists. No code change needed.

- [ ] **Step 5: Decide on gitignore**

The rewriter `.gitignore` excludes all `voices/*` because Justin's voice profile contains personal patterns. The npr-narrator voice is derived from public radio transcripts and is reusable.

Read: `/Users/justinmassa/.claude/skills/rewriter/.gitignore`

Decision: keep gitignored for now (consistent with existing convention), add a note in the rewriter README about how to opt in to committing it. If Justin later wants this committed and shared, that's a one-line gitignore change.

If you opt to commit instead, edit `.gitignore` to replace `voices/` with explicit per-file ignores:
```
voices/justin.md
voices/ai-action-plan.md
voices/ai-for-smbs.md
```

Default decision: leave gitignored, no change needed.

- [ ] **Step 6: Commit**

Voice profile is gitignored, so nothing to commit in the rewriter repo. Move on.

---

## Task 2: Scaffold the special-episode skill directory

**Files:**
- Create: `/Users/justinmassa/.claude/skills/skills/special-episode/README.md`
- Create: `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/` (directory)

- [ ] **Step 1: Create the skill directory**

Run: `mkdir -p /Users/justinmassa/.claude/skills/skills/special-episode/prompts`

- [ ] **Step 2: Write the README**

Write `/Users/justinmassa/.claude/skills/skills/special-episode/README.md`:

```markdown
# special-episode

On-demand "special episode" podcast script generator. Paste a list of links, get back a single deep, NPR-style spoken-word script saved to `_DailyPodcast` for ElevenLabs Reader on the phone.

## What it does

1. Parses 1-8 links from your input (any kind: articles, PDFs, YouTube, podcasts, tweets, GitHub).
2. Dispatches one sub-agent per link in parallel. Each fetches the source and produces a deep "Cliff's Notes" treatment.
3. Main agent assembles a cohesive episode: cold open, per-piece segments with quotes and texture, brief themes-across observations, outro.
4. Hands the draft to `/rewriter` with the `npr-narrator` voice profile for polish.
5. Writes the final script to `_DailyPodcast/YYYY-MM-DD-special-episode.md` (Drive-synced, picks up on the phone).
6. Archives raw treatments to `~/Projects/special-episode-archive/YYYY-MM-DD-<slug>/` for future reference.

## What it is NOT

- Not an audio generator. ElevenLabs Reader handles TTS on the phone.
- Not the regular twice-weekly briefing. That's a separate, scheduled pipeline. This one is on-demand and goes deeper per piece.

## Invocation

Type `/special-episode` and paste your links. The skill will confirm what it parsed and ask for an optional title hint before dispatching.

## Files

- `SKILL.md` - the orchestration logic
- `prompts/sub-agent-treatment-prompt.md` - per-link sub-agent prompt template
- `prompts/assembly-prompt.md` - main agent assembly prompt template

## Voice profile dependency

This skill depends on `~/.claude/skills/rewriter/voices/npr-narrator.md`. If that file is missing, the rewriter polish step falls back to voice-neutral mode (still polished, just less NPR-flavored).
```

- [ ] **Step 3: Verify**

Run: `ls /Users/justinmassa/.claude/skills/skills/special-episode/`
Expected: `README.md` and `prompts/` listed.

---

## Task 3: Write the per-link sub-agent treatment prompt

**Files:**
- Create: `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md`

- [ ] **Step 1: Write the full prompt template**

Write `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md`:

```markdown
# Sub-Agent: Per-Link Deep Treatment

You are a research sub-agent for the `special-episode` skill. The main agent has dispatched you with one link. Your job: fetch it, read it carefully, and produce a structured "deep treatment" that the main agent will splice into a spoken podcast script.

## Your inputs

- **URL:** `{{URL}}`
- **Source-type hint (optional):** `{{SOURCE_TYPE_HINT}}`
- **Episode context (optional):** `{{EPISODE_TITLE_HINT}}`

## Step 1: Fetch the content

Use the right tool for the source type:

| Source | Tool order |
|---|---|
| HTML article | `WebFetch` first; if paywalled, JS-heavy, or blocked, fall back to Chrome MCP / Playwright |
| PDF | Download with `curl` or `WebFetch`, save to `/tmp/`, then `Read` |
| YouTube | `yt-dlp --write-auto-sub --skip-download --sub-lang en -o '/tmp/yt-%(id)s.%(ext)s' <URL>` then read the resulting `.vtt` file |
| Tweet / X thread | Chrome MCP (Twitter is JS-rendered) |
| Podcast episode page | Fetch the page; if a transcript is linked, fetch that too. If no transcript, work from show notes and flag this in source-fidelity notes. |
| GitHub README or markdown | `WebFetch` raw URL (`https://raw.githubusercontent.com/...`) |
| Substack | `WebFetch` first; many Substacks are open. If paywalled, try Chrome MCP. |
| Other | Try `WebFetch`, then Chrome MCP, then flag failure to main agent |

If all attempts fail, return a treatment with the failure flagged clearly so the main agent can ask the user how to proceed.

## Step 2: Read carefully

Read the entire piece. Don't skim. Identify:
- The author's thesis or argument
- The structure of how they present it (intro / setup / evidence / counterargument / conclusion, or whatever the actual structure is)
- The specific examples and evidence they use
- Counterarguments they engage with
- Surprising or vivid specifics
- The texture of how they think (their characteristic moves, analogies, rhetorical patterns)

## Step 3: Produce the structured treatment

Return ONLY a markdown blob in exactly this format. The main agent will splice this directly into the assembly stage.

```markdown
## [Piece Title]

**Source:** [Author/Outlet, date if known]
**URL:** [original URL, retained for archive purposes]
**Treatment length target:** [a number between ~400 and ~2,250 words, matched to piece depth]
**Fetched via:** [tool used: WebFetch / Chrome MCP / yt-dlp / etc.]

### Setup / Why this piece exists
[1-3 paragraphs. Who the author is if relevant. What prompted the piece. Why it's worth your time. Set the listener up to care.]

### The walk-through
[The Cliff's Notes proper. Walk through the structure of the piece, in roughly the order the author presents it. Include:
- Direct quotes when they earn their keep, formatted as: > "Quote text here." - [Author]
- Specific examples and evidence
- The texture of the argument, not just the conclusions
- Counterpoints the author engages with
This is the bulk of the treatment. Be faithful to the source. Don't compress so aggressively that the texture disappears.]

### Where it gets interesting / where it surprised me
[Specific moments worth lingering on - a counterintuitive claim, a vivid example, a tension the author doesn't quite resolve. 1-3 paragraphs.]

### Brief note on Remix relevance
[At most 1-2 sentences. Skip this section entirely if there's no obvious tie. The narrator will weave in a brief flag, not deliver an analysis.]

### Source-fidelity flags
[Anything the main agent should know:
- "Could not access full article behind paywall, worked from cached version via Chrome MCP"
- "Transcript was auto-generated, names may be transliterated incorrectly"
- "This is a 90-min YouTube lecture, treatment is from full transcript"
- "Tweet thread had no expanded version, worked from visible thread only"
If everything went smoothly, write: "None."]
```

## Length guidance

Match treatment length to piece depth.

- A 600-word blog post might get 400 words of treatment.
- A 2,000-word essay might get 800-1,200 words of treatment.
- A 6,000-word New Yorker piece might get 2,000-2,500 words of treatment (the cap).
- A 90-min YouTube lecture might get 2,250 words (the cap), pulling the most substantive segments.

Aim for *Cliff's Notes of the whole thing* - not just the top points, but the texture, structure, and key examples the author uses. Cap at ~2,250 words per treatment.

## What you do NOT do

- Do not editorialize against the source.
- Do not add a "where the author might be wrong" section - pushback comes from the listener, not from you.
- Do not insert your own arguments.
- Do not summarize past the texture; preserve the way the author thinks.
- Do not add markdown headers beyond what's in the template above.
- Do not write the script (no `<break>` tags, no spelled-out numbers, no source-attribution-as-spoken-word). The main agent handles all of that during assembly.

## Output

Return ONLY the structured markdown treatment. No commentary. No "here's the treatment." Just the markdown blob.
```

- [ ] **Step 2: Verify**

Run: `wc -l /Users/justinmassa/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md`
Expected: at least 90 lines.

Run: `grep -c "{{" /Users/justinmassa/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md`
Expected: `3` (three template variables: URL, SOURCE_TYPE_HINT, EPISODE_TITLE_HINT).

---

## Task 4: Write the assembly prompt

**Files:**
- Create: `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/assembly-prompt.md`

- [ ] **Step 1: Write the full assembly prompt**

Write `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/assembly-prompt.md`:

```markdown
# Episode Assembly Prompt

You are the main agent for the `special-episode` skill, in the assembly phase. All sub-agent treatments have returned. Your job: stitch them into a single spoken-word podcast script ready for ElevenLabs Reader.

## Your inputs

- **Episode date:** `{{EPISODE_DATE}}` (format: YYYY-MM-DD)
- **Optional title hint from user:** `{{TITLE_HINT}}` (may be empty)
- **Treatments (in user-pasted link order):** `{{TREATMENTS}}`

## Voice profile

You will write the draft with NPR-narrator sensibility from the start. Read `/Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md` before drafting. Your draft is the input to the rewriter polish step; that step assumes the draft is already 80% in the target voice.

## Episode structure (mandatory)

```
1. HTML-comment ToC at the top of the file (invisible to ElevenLabs Reader)
2. Cold open (~30-60 sec / ~75-150 words)
3. <break time="1.5s" />
4. Per-piece segments, in user-pasted link order:
   - Spoken transition phrase ("First up..." / "Next..." / "And our third piece...")
   - Treatment rewritten as flowing essay-style narration
   - Direct quotes integrated with "And I'll quote..." / "As [author] writes..."
   - Brief Remix-relevance flag (1-2 sentences, woven in casually) IF the treatment had one
   - Soft handoff to next piece
   - <break time="1.0s" /> between pieces
5. <break time="1.5s" />
6. Themes-across segment (~1-2 min / ~150-300 words)
7. <break time="1.0s" />
8. Outro (~15-30 sec)
```

## Hard rules (these come from the voice profile; do not violate)

- **No markdown headers in the body.** Use HTML-comment ToC at top for navigation. Body is clean prose.
- **No URLs in the body.** Source attribution format: "from [Source Name] dot [TLD]" (e.g., "from stratechery dot com," "from the new yorker dot com").
- **All numbers and dates as words.** "January eighteenth twenty twenty-six" not "1/18/2026." "Forty percent" not "40%."
- **Use `<break time="X.Xs" />` for pauses.** Standard cadence: 1.0s between pieces, 1.5s for major beats (cold open to first piece, themes-across to outro).
- **No em-dashes or double-dashes in prose.** Use single dashes with spaces, parentheses, semicolons, periods, or rewrite. (Per Justin's standing rule.)
- **Cap individual segment length at ~2,250 words / ~15 minutes of listening.**
- **Themes-across stays brief: 1-2 minutes / 150-300 words.** Be honest if there aren't strong threads; don't manufacture them.

## ToC format

At the very top of the file, before any prose:

```html
<!--
Special Episode - {{EPISODE_DATE}}
Total estimated runtime: [N] min

Table of contents (invisible to ElevenLabs Reader):
1. Cold open
2. [Piece 1 title]
3. [Piece 2 title]
...
N. Themes across
N+1. Outro
-->
```

## Cold open template

The cold open names the date, names the pieces briefly, and sets expectations. Keep it warm and direct.

Example (use as a guide, not a fill-in):

```
Hey. This is your Special Episode for May third, twenty twenty-six.

Today, three pieces. One on the inference inflection - the shift from training-driven to inference-driven AI economics. One from On Being on the disappearance of the grad-student apprenticeship. And one essay from Stratechery on the harness layer becoming the moat.

About forty minutes. Settle in.
```

## Outro template

Short, warm, no manufactured wisdom.

Example:

```
That's your Special Episode for May third. Hope something here was useful.
```

## What to do with the Remix-relevance flags

The treatments may include a "Brief note on Remix relevance" section. Weave that flag into the segment in 1-2 sentences, casually. Don't deliver it as analysis. Examples:

- "Worth flagging for our work because the same dynamic shows up every time we talk to clients about hiring strategy."
- "Familiar territory if you've been thinking about how the harness layer plays into our positioning."

If a treatment didn't include a Remix flag (because no obvious tie existed), skip it entirely. Don't manufacture relevance.

## Output

Output ONLY the assembled draft script. No commentary. No "here's the draft." Just the script, starting with the HTML-comment ToC and ending with the outro.
```

- [ ] **Step 2: Verify**

Run: `wc -l /Users/justinmassa/.claude/skills/skills/special-episode/prompts/assembly-prompt.md`
Expected: at least 90 lines.

Run: `grep -c "{{" /Users/justinmassa/.claude/skills/skills/special-episode/prompts/assembly-prompt.md`
Expected: at least 4 (`{{EPISODE_DATE}}` appears twice in the prompt - once in the inputs section, once in the ToC example; `{{TITLE_HINT}}` once; `{{TREATMENTS}}` once).

---

## Task 5: Write the orchestration SKILL.md

**Files:**
- Create: `/Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`

- [ ] **Step 1: Write the SKILL.md with frontmatter and full orchestration**

Write `/Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`:

```markdown
---
name: special-episode
description: Generate an on-demand, deep-dive NPR-style podcast script from a list of links. Paste 1-8 URLs (articles, PDFs, YouTube, podcasts, tweets, GitHub, anything), get back a single spoken-word script saved to _DailyPodcast for ElevenLabs Reader. Use when Justin says "make me a special episode," "do a deep dive podcast on these links," "podcast script from this list," or invokes /special-episode. Each piece gets a long, faithful Cliff's Notes treatment (up to 15 minutes per piece). Brief themes-across at the end. NOT the regular briefing - this is on-demand and deeper.
---

# Special Episode

You are orchestrating a special-episode podcast script generation. The user has pasted a list of links and wants a single spoken-word script that walks through each piece in depth, in the voice of an NPR narrator, saved to their `_DailyPodcast` Drive folder.

## Required reads before starting

- `/Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md` - the voice profile that defines tone, sentence patterns, and spoken-word mechanics
- `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/sub-agent-treatment-prompt.md` - the per-link sub-agent prompt
- `/Users/justinmassa/.claude/skills/skills/special-episode/prompts/assembly-prompt.md` - the assembly prompt

If the voice profile file is missing, warn the user: "The npr-narrator voice profile is missing at /Users/justinmassa/.claude/skills/rewriter/voices/npr-narrator.md. The rewriter polish step will fall back to voice-neutral mode. Proceed anyway? (y/n)"

## Step 1: Parse and confirm links

Parse the user's input. Extract URLs. Be liberal: handle pasted lists with line breaks, comma separators, mixed-in notes ("that substack post - https://..."), and surrounding prose.

Show the user a numbered list of what you parsed:

```
Parsed [N] links:
1. https://stratechery.com/2026/...
2. https://www.newyorker.com/magazine/...
3. https://youtu.be/...
4. https://exponentialview.co/p/...

Look right? (a = go, b = remove some, c = add more, d = fix one)
```

Handle responses:
- (a) proceed to Step 2
- (b) ask which numbers to remove, then re-display
- (c) ask for additional links, parse, re-display
- (d) ask which number and the corrected URL, then re-display

If [N] > 8: do NOT proceed. Say: "Cap is 8 links per episode (parallel sub-agent limit). Please pick which 8 you want first; I'll start there. The rest can be a follow-on episode."

If [N] == 0: ask for links.

## Step 2: Optional title hint

Ask: "Any guiding theme or title for this episode? (or 'skip')"

This is optional. Save the response (which may be empty) for the assembly stage.

## Step 3: Dispatch sub-agents in parallel

For each of the N links, dispatch a Task tool call with `subagent_type: general-purpose`. Send all calls in a single message so they run in parallel.

Each sub-agent receives the full prompt template from `prompts/sub-agent-treatment-prompt.md` with the `{{URL}}`, `{{SOURCE_TYPE_HINT}}`, and `{{EPISODE_TITLE_HINT}}` template variables filled in. Source-type hint can be inferred from the URL host (substack.com -> "Substack article", youtu.be -> "YouTube video", arxiv.org -> "academic paper", etc.) or left empty if unsure.

While dispatched, tell the user: "Dispatched [N] sub-agents to fetch and treat each piece in parallel. This may take a few minutes - back when they're all done."

## Step 4: Handle sub-agent results

Each sub-agent returns a structured markdown treatment.

**If a sub-agent returns a treatment with no source-fidelity flags:** add it to the assembly pile.

**If a sub-agent returns a treatment with source-fidelity flags but real content:** add it to the assembly pile, note the flag for the user.

**If a sub-agent returns a hard failure (couldn't fetch at all):** surface to the user immediately:

```
Couldn't fetch [URL]. Tried: [tools tried].
Options:
(a) skip this piece and continue
(b) you paste the article text here, I'll feed it to a sub-agent
(c) I try again with different tools
```

Default = ask. Do NOT silently skip.

## Step 5: Assembly

Once all treatments are in (or skipped with user consent), invoke the assembly logic from `prompts/assembly-prompt.md` directly (you, the main agent, do this - not a sub-agent, because you need full context of all treatments).

Fill in the assembly prompt template variables:
- `{{EPISODE_DATE}}` -> today's date in YYYY-MM-DD format
- `{{TITLE_HINT}}` -> the user's title hint from Step 2 (or "")
- `{{TREATMENTS}}` -> the concatenated treatment markdown blobs in pasted-link order

Produce the draft. It must:
- Open with an HTML-comment ToC (see assembly prompt for format)
- Have a cold open
- Have one segment per piece, in pasted order
- Have a themes-across segment
- Have an outro
- Use `<break time="X.Xs" />` for pauses (no markdown headers in the body)
- Spell out all numbers and dates
- Use "from [Source Name] dot [TLD]" for source attribution
- Have NO em-dashes or double-dashes in prose

## Step 6: Rewriter handoff

Estimate draft length and listening time (assume ~150 words per minute):

```
Draft assembled.
Total length: [N] words (~[M] minutes listening time)
Pieces: [N]

Run rewriter polish? (a = yes [default], b = let me read the draft first, c = skip rewriter)
```

Handle responses:

**(a) yes:**
Invoke `/rewriter` with the draft and instruction: "Rewrite this special-episode podcast script in the npr-narrator voice. This is a spoken-word script for ElevenLabs Reader. Preserve all `<break>` tags, spelled-out numbers, source attributions in 'from X dot Y' form, and quote-integration markers verbatim per Layer 4 of the voice profile."

**(b) read first:**
Show the user the full draft. Ask: "Edits before rewriter? (paste edits or 'go')." Apply edits, then proceed to (a).

**(c) skip rewriter:**
Use the draft as-is.

If the rewriter step fails or produces unusable output: save the pre-rewriter draft as the final file with an HTML comment banner at the top: `<!-- Rewriter pass failed; this is the unpolished draft. -->` and surface the failure to the user.

## Step 7: Write outputs

**Output paths:**

```
SCRIPT_PATH = "/Users/justinmassa/Library/CloudStorage/GoogleDrive-justin@remixpartners.ai/My Drive/_DailyPodcast/{{DATE}}-special-episode.md"
ARCHIVE_DIR = "/Users/justinmassa/Projects/special-episode-archive/{{DATE}}-{{SLUG}}/"
```

Where:
- `{{DATE}}` is today's date in `YYYY-MM-DD` format
- `{{SLUG}}` is a 3-5 word kebab-case slug derived from the episode (use the title hint if provided, otherwise generate from the first piece's title or the dominant theme)

**Filename collision handling:**

Before writing the script, check if `SCRIPT_PATH` already exists. If yes, increment: `{{DATE}}-special-episode-2.md`, `-3.md`, etc., until the path is free.

**Drive sync path check:**

Before writing the script, check that the parent directory exists:
```
ls "/Users/justinmassa/Library/CloudStorage/GoogleDrive-justin@remixpartners.ai/My Drive/_DailyPodcast/"
```

If the directory doesn't exist, error loudly: "The _DailyPodcast folder is missing. Drive may not be syncing. Expected path: [path]"

**Write the script:**

Write the final (post-rewriter or fallback) script to `SCRIPT_PATH`.

**Write the archive:**

Create `ARCHIVE_DIR`. Write:
- One `.md` file per treatment, named `01-<piece-slug>.md`, `02-...`, etc.
- `episode-draft.md` - the pre-rewriter assembly
- `episode-final.md` - the post-rewriter final (mirror of what's in `_DailyPodcast`)
- `manifest.json` with episode metadata:

```json
{
  "date": "YYYY-MM-DD",
  "title_hint": "...",
  "links": [
    {"url": "...", "title": "...", "fetched_via": "...", "source_fidelity_flags": "..."}
  ],
  "draft_word_count": N,
  "final_word_count": N,
  "estimated_runtime_minutes": M,
  "rewriter_run": true,
  "script_path": "/Users/.../...md"
}
```

## Step 8: Confirm to user

Report back:

```
Special episode saved.

Script: [SCRIPT_PATH]
Archive: [ARCHIVE_DIR]
Pieces: [N]
Estimated runtime: [M] minutes

GDrive sync should pick this up within a minute. ElevenLabs Reader on your phone, look for "Special Episode {{DATE}}".
```

If any pieces were skipped due to fetch failures, note that:

```
Note: skipped [piece] due to [reason]. Worth retrying separately.
```

## Failure handling summary

| Failure | Behavior |
|---|---|
| 0 links pasted | Ask for links |
| >8 links pasted | Don't proceed; ask user to pick 8 |
| Voice profile missing | Warn, offer to proceed in voice-neutral mode |
| Sub-agent can't fetch | Surface to user; default = ask |
| Sub-agent partial fetch | Treatment proceeds with flag visible |
| Drive folder missing | Error loudly, halt |
| Filename collision | Auto-increment with `-2`, `-3`, etc. |
| Rewriter step fails | Save unpolished draft with banner; surface to user |

## What this skill does NOT do

- Generate audio (ElevenLabs Reader on the phone handles that).
- Run on a schedule (this is on-demand only).
- Replace the regular twice-weekly briefing pipeline.
- Heavy Remix-business analysis (briefing flag is 1-2 sentences max per piece).
```

- [ ] **Step 2: Verify the SKILL.md is well-formed**

Run: `wc -l /Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`
Expected: at least 200 lines.

Run: `head -3 /Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`
Expected: starts with `---`, has `name: special-episode`, has `description: ...`.

Run: `grep -c "TBD\|TODO" /Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`
Expected: `0`.

Run: `grep -E "—|--" /Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md | grep -v "<!--\|-->\|---\|<break\|tabular\|^[[:space:]]*\\\`\\\`\\\`"`
Expected: minimal output. Any matches need to be reviewed manually for whether they're prose em-dashes (banned) or technical syntax (OK).

- [ ] **Step 3: Verify Claude Code picks up the skill**

In a fresh Claude Code session, type `/special-episode` (don't paste anything yet, just the slash command). Confirm Claude recognizes the skill and asks for links.

If the skill isn't recognized, check:
- Is the file at the right path? (`ls /Users/justinmassa/.claude/skills/skills/special-episode/SKILL.md`)
- Does the frontmatter parse? (`head -5` should show `---` then `name:` then `description:` then `---`)

- [ ] **Step 4: Commit the skill**

```bash
cd /Users/justinmassa/.claude/skills
git add skills/special-episode/
git commit -m "$(cat <<'EOF'
feat: add special-episode skill

On-demand deep-dive podcast script generator. Paste 1-8 links, get back
a single spoken-word script for ElevenLabs Reader saved to _DailyPodcast.
Per-link sub-agents for parallel fetch + treatment, main agent assembly,
/rewriter polish via npr-narrator voice profile.

Spec: docs/superpowers/specs/2026-05-03-special-episode-skill-design.md
Plan: docs/superpowers/plans/2026-05-03-special-episode-skill.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: First-run smoke test with 1 link

**Goal:** validate the orchestration end-to-end on the simplest possible case before testing parallelism or mixed source types.

- [ ] **Step 1: Pick a known-good test article**

Choose a freely accessible blog post or essay you can verify against. Suggested: a recent post from `https://stratechery.com` (free posts are accessible without login), or a Substack post that's free.

Write the URL down for reference.

- [ ] **Step 2: Run the skill**

In a Claude Code session: `/special-episode` then paste the single URL. Walk through the flow:
- Confirm parsing
- Provide a title hint or skip
- Wait for the sub-agent to return
- Confirm assembly produces a draft
- Choose (a) run rewriter
- Confirm final output is written to `_DailyPodcast`

- [ ] **Step 3: Validate the output script**

Open `/Users/justinmassa/Library/CloudStorage/GoogleDrive-justin@remixpartners.ai/My Drive/_DailyPodcast/{{TODAY}}-special-episode.md` and check:
- HTML-comment ToC at top
- Cold open is warm and direct, names date in spoken form
- Single segment with substantial walk-through (matched to article depth, ~400-2,250 words)
- At least one or two direct quotes integrated naturally
- Themes-across exists (will be brief since only one piece - may say something like "this one stood alone" - that's fine)
- Outro is short and direct
- `<break time="X.Xs" />` tags present at section boundaries
- No markdown headers in the body
- All numbers and dates spelled out as words
- Source attribution in "from X dot Y" form
- No em-dashes or double-dashes in prose
- No URLs anywhere in the body

- [ ] **Step 4: Validate the archive**

Check `~/Projects/special-episode-archive/{{TODAY}}-<slug>/`:
- `01-<piece-slug>.md` - raw treatment exists
- `episode-draft.md` - pre-rewriter draft
- `episode-final.md` - post-rewriter final (mirror of what's in _DailyPodcast)
- `manifest.json` with valid JSON, fetched_via populated, etc.

- [ ] **Step 5: Listen test**

Wait ~1 minute for Drive sync. On phone, open ElevenLabs Reader. Find the new file in `_DailyPodcast`. Listen to at least the cold open and first piece.

Validation checklist:
- Pauses feel natural (not abrupt, not too long)
- Numbers sound right ("twenty twenty-six," not "two zero two six")
- Source attributions sound natural ("from stratechery dot com")
- No reading-aloud-of-headers ("Section 2" or "## Walk-through")
- No reading-aloud-of-URLs

- [ ] **Step 6: Iterate if needed**

If anything sounds off in the listen test, the fix is in either:
1. The voice profile (`npr-narrator.md`) - update Layer 1/2/3/4 with the issue and rerun
2. The assembly prompt - update the formatting rules and rerun
3. The sub-agent prompt - if treatments are coming back wrong shape

Iterate until the script reads cleanly aloud.

---

## Task 7: Mixed-source test with 3 links

**Goal:** validate parallelism and that the skill handles different source types (article + PDF + YouTube).

- [ ] **Step 1: Pick three test sources**

- One free HTML article (different from Task 6 if possible)
- One PDF (a freely downloadable academic paper or report - arxiv works)
- One YouTube video with auto-generated captions (any 10-30 minute talk)

Write all three URLs down.

- [ ] **Step 2: Run the skill**

`/special-episode` then paste all three URLs. Provide a title hint that ties them loosely if you can ("the inference inflection," "design under uncertainty," etc.) or skip.

- [ ] **Step 3: Validate parallel dispatch**

Watch the Claude Code session. The three sub-agent dispatches should appear in a single tool-call message (parallel), not sequentially. If they're sequential, the SKILL.md needs adjustment to dispatch in a single message.

- [ ] **Step 4: Validate the output**

Same checklist as Task 6, plus:
- Each piece's segment has its own spoken transition ("First up..." / "Next..." / "And our third piece...")
- Each segment has appropriate length matched to source depth
- Themes-across actually identifies threads (or honestly says there aren't strong ones)
- The PDF was fetched and read (manifest should show `fetched_via: WebFetch+Read` or similar)
- The YouTube video transcript was used (manifest should show `fetched_via: yt-dlp`)

- [ ] **Step 5: Listen test**

Listen to the full episode on the phone. Check:
- Total runtime matches the estimate in the manifest
- Transitions between pieces feel natural
- The themes-across is brief and earned

- [ ] **Step 6: Iterate if needed**

Same as Task 6 Step 6.

---

## Task 8: Update documentation

**Files:**
- Modify: `/Users/justinmassa/CLAUDE.md`
- Modify: `/Users/justinmassa/.claude/skills/README.md`

- [ ] **Step 1: Update the global CLAUDE.md**

Open `/Users/justinmassa/CLAUDE.md` and find the "Skills in `remixpartners/claude-skills` repo" section under "Remix Skills (Claude Code)."

Find the long list that begins:
```
- `remix-proposal-writer`, `keynote-slides`, `Narrative-Engine`, ...
```

Add `special-episode` to the list, alphabetically or at the natural end.

In the same CLAUDE.md, find the "Voice guides" section (under "Remix Skills (Claude Code)"). After the bullet on "AI for SMBs voice guide" and before the closing line about `justin-voice` being a thin wrapper, add:

```
- **NPR narrator voice guide** lives at `~/.claude/skills/rewriter/voices/npr-narrator.md` (gitignored, local only). Derived from public radio transcripts (Fresh Air, This American Life, On Being, 99% Invisible, Planet Money) plus the working briefing prompts. Used by `/special-episode` for spoken-word script polish, and reusable by other skills that need spoken-word output.
```

- [ ] **Step 2: Update the claude-skills repo README**

Open `/Users/justinmassa/.claude/skills/README.md`. Find the skill inventory list. Add `special-episode` with a one-line description matching the format of other entries.

If the README has a section for new/recent skills, mention `npr-narrator` voice profile as a related addition.

- [ ] **Step 3: Copy CLAUDE.md to backup repo**

Per the instruction at the bottom of `/Users/justinmassa/CLAUDE.md`:

```bash
cp /Users/justinmassa/CLAUDE.md /Users/justinmassa/claude-config/CLAUDE.md
cd /Users/justinmassa/claude-config
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: add special-episode skill and npr-narrator voice profile

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push
```

- [ ] **Step 4: Commit the claude-skills README update**

```bash
cd /Users/justinmassa/.claude/skills
git add README.md
git commit -m "$(cat <<'EOF'
docs: add special-episode to skill inventory

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Final commit and push

- [ ] **Step 1: Verify all changes are committed**

```bash
cd /Users/justinmassa/.claude/skills && git status
cd /Users/justinmassa/claude-config && git status
cd /Users/justinmassa/Projects/ClaudeProjects && git status
```

Expected: all clean (or only untracked files unrelated to this work).

- [ ] **Step 2: Push the claude-skills repo**

```bash
cd /Users/justinmassa/.claude/skills
git push
```

- [ ] **Step 3: Push the claude-config repo**

```bash
cd /Users/justinmassa/claude-config
git push
```

- [ ] **Step 4: Commit and push the plan in ClaudeProjects**

The plan and spec live in `~/Projects/ClaudeProjects`. The spec was already committed during brainstorming. The plan needs to be committed:

```bash
cd /Users/justinmassa/Projects/ClaudeProjects
git add docs/superpowers/plans/2026-05-03-special-episode-skill.md
git commit -m "$(cat <<'EOF'
plan: special-episode skill implementation

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push
```

- [ ] **Step 5: Notify Justin in chat**

Send a short message:

```
Special-episode skill is live. Paste links into /special-episode anytime.

Test runs done: [link 1 result], [link 2 result]. Voice sounds [your assessment]. Iterate as needed.

NPR voice profile is gitignored (consistent with other voices). If we want to share with the briefing pipeline later, that's a small follow-on.
```

---

## Self-Review Notes

After this plan was drafted, the following spec-coverage check was performed:

| Spec section | Plan coverage |
|---|---|
| Skill at `~/.claude/skills/skills/special-episode/` | Tasks 2-5 |
| `npr-narrator` voice profile | Task 1 |
| Per-link sub-agent dispatch | Task 5 (SKILL.md Step 3), prompt in Task 3 |
| Main agent assembly | Task 5 (SKILL.md Step 5), prompt in Task 4 |
| `/rewriter` handoff | Task 5 (SKILL.md Step 6) |
| File outputs (script + archive) | Task 5 (SKILL.md Step 7) |
| `<break>` tags + numbers as words + source attribution format | Task 1 (Layer 4), Task 4 (assembly rules), Task 5 (Step 5 hard rules) |
| Error handling | Task 5 (SKILL.md Steps 4 and 7, failure-handling summary) |
| Manual end-to-end testing | Tasks 6 and 7 |
| Documentation updates | Task 8 |
| Out-of-scope items (briefing migration, audio gen) | Not in plan, correctly omitted |

No spec gaps. No placeholder content remaining in the plan body.

**Engineer note:** Voice profile content (Task 1 Step 2) is the longest single content drop in the plan. Set aside ~30-45 minutes for that step alone, including reading the source material first. Quality of the entire skill depends on this profile being substantive and accurate.
