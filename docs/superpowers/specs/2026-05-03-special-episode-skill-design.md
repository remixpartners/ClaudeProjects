# Special Episode Skill - Design Spec

**Date:** 2026-05-03
**Author:** Stafford (with Justin)
**Status:** Approved design, ready for implementation plan

---

## Problem

Justin reads (or wants to read) a lot of articles, papers, and long-form pieces - but reads few of them all the way through. He already has a working twice-weekly briefing pipeline that turns curated newsletters into spoken NPR-style scripts read aloud by ElevenLabs Reader on his phone. That pipeline is broad and shallow by design.

He wants a complementary, on-demand pipeline: paste a list of links, get back a single spoken script that walks him through each piece in depth - not a summary, but Cliff's Notes covering the texture, structure, examples, and arguments of each piece. Long enough that listening genuinely substitutes for reading. Less Remix-business analysis, more faithful walk-through of the source material.

## Goals

1. Justin pastes 1-8 links of any kind into a Claude Code session and gets a finished, polished, spoken-word script saved to his `_DailyPodcast` Drive folder.
2. Each piece gets a deep treatment - up to ~15 minutes / ~2,250 words of listening per piece, scaled to the piece's depth (a 600-word blog post might be 400 words of treatment; a 6,000-word New Yorker piece might be 2,000-2,500).
3. The script reads aloud well in ElevenLabs Reader, in a consistent NPR-narrator voice.
4. Skill is reusable, low-friction, and produces an artifact archive for revisiting without re-listening.

## Non-goals

- Audio generation. ElevenLabs Reader on Justin's phone handles that.
- Scheduled / automated runs. This is on-demand only.
- Multi-host or dialogue formats. Single narrator throughout.
- Heavy Remix-business analysis. A 1-2 sentence relevance flag per piece is the cap.
- Replacing the existing briefing pipeline. This is complementary; the briefing stays as-is.

## Architecture

```
User pastes links into /special-episode
        |
        v
[Parse + dedupe + normalize, show numbered list, confirm]
        |
        v
[Optional title/theme hint from user]
        |
        v
[Dispatch sub-agents in parallel, one per link, max 8]
        |
        v
Sub-agent N: fetch -> read -> produce structured "deep treatment"
        |
        v
[Main agent assembles draft: cold open + segments + themes-across + outro]
[Bakes in <break> tags, numbers-as-words, NPR sensibility from the start]
        |
        v
[Show length to user, ask whether to run rewriter polish now or read draft first]
        |
        v
/rewriter "in the npr-narrator voice"
        |
        v
[Save script to _DailyPodcast/YYYY-MM-DD-special-episode.md]
[Save raw treatments to ~/Projects/special-episode-archive/YYYY-MM-DD-<slug>/]
        |
        v
GDrive sync -> ElevenLabs Reader on phone
```

**Design principles:**
- Orchestration logic lives in markdown (the skill itself). Heavy lifting lives in dispatched sub-agents and existing skills (rewriter).
- Sub-agents handle fetch + per-piece treatment in parallel. This protects main context and exploits parallelism for the slow part.
- Main agent does the things that genuinely require the full set in context: cold open, transitions, themes-across, outro, and assembly.
- Voice profile is the contract. Anything ElevenLabs Reader needs is documented in `npr-narrator.md` and explicitly preserved by rewriter's voice layer.

## Components

### 1. The skill itself

**Location:** `~/.claude/skills/skills/special-episode/`

**Files:**
- `SKILL.md` - frontmatter + skill instructions (the orchestration logic)
- `prompts/sub-agent-treatment-prompt.md` - prompt template for the per-link sub-agents
- `prompts/assembly-prompt.md` - prompt template for the main agent's assembly step
- `README.md` - human-readable overview, link to this spec

**Frontmatter trigger:** activated by `/special-episode` slash command, or by user phrases like "make me a special episode," "do a deep dive podcast on these links," "podcast script from this list."

### 2. The NPR narrator voice profile

**Location:** `~/.claude/skills/rewriter/voices/npr-narrator.md`

**Structure** (mirrors `justin.md`):
- **Layer 1: Idea Architecture** - how NPR-style narrators structure arguments (gentle setup, evidence-stacking, lingering on specifics, soft handoffs)
- **Layer 2: Persuasion Patterns** - how attribution works on-air, how counterpoints are framed, how the narrator sits with tension instead of resolving it
- **Layer 3: Sentence Patterns** - sentence length norms for spoken word (short defaults, varied rhythm, no clause-stacking)
- **Layer 4: Spoken-Word Mechanics** (NEW, not in `justin.md`) - the section rewriter must preserve verbatim:
  - `<break time="X.Xs" />` tag conventions
  - Numbers as words ("twenty twenty-six," "forty percent," "January eighteenth")
  - Source attribution format: "from [Name] dot [TLD]"
  - Quote integration: "And I'll quote..." / "As [author] writes..."
  - Anti-AI scrub list (carried forward from existing `rewriter-pass-prompt.md`)

**Source material for building the profile:** public transcripts from Fresh Air, This American Life, On Being, 99% Invisible, Planet Money. Plus the existing `chief-of-staff/prompts/podcast-prompt.md` and `rewriter-pass-prompt.md` as starting points (those briefing-specific prompts encode this voice already; we generalize them into the voice file).

**Side benefit (out of scope, future cleanup):** the briefing pipeline can later migrate to use this voice profile, replacing the duplicated rules in its two prompts.

### 3. The per-link sub-agent

Dispatched via Task tool, `subagent_type: general-purpose`, one per link, in parallel (max 8).

**Sub-agent prompt covers:**

1. **Fetch** - try the right tool for the source type:
   - HTML article: WebFetch first; fall back to Playwright/Chrome MCP if paywalled or JS-heavy
   - PDF: download via curl/WebFetch, then Read
   - YouTube: `yt-dlp --write-auto-sub --skip-download --sub-lang en` for transcript
   - Tweet/thread: Chrome MCP (Twitter is JS-rendered)
   - Podcast page: fetch transcript if linked; else show notes
   - GitHub: WebFetch raw markdown
   - Default: WebFetch -> browser -> flag failure

2. **Read carefully** - identify thesis, structure, evidence, counterarguments, surprising specifics, texture of the author's thinking.

3. **Return structured "deep treatment":**

```markdown
## [Piece Title]

**Source:** [Author/Outlet, date if known]
**URL:** [link, retained for archive only - not used in script]
**Treatment length target:** [matched to piece depth, up to ~2,250 words]
**Fetched via:** [tool used]

### Setup / Why this piece exists
[1-3 paragraphs]

### The walk-through
[Cliff's Notes proper - structural walk-through with direct quotes,
specific examples, evidence, counterpoints]

### Where it gets interesting / where it surprised me
[Specific moments worth lingering on]

### Brief note on Remix relevance
[1-2 sentences max, or skipped entirely]

### Source-fidelity flags
[Anything the main agent should know about fetch quality, paywalls,
auto-generated transcripts, etc.]
```

**Length guidance baked into sub-agent prompt:** "Match treatment length to piece depth. Aim for *Cliff's Notes of the whole thing* - not just the top points, but the texture, structure, and key examples the author uses. Cap at ~2,250 words."

**No "where the author might be wrong" section** - treatments stay faithful to source.

### 4. The main agent assembly step

After all sub-agent treatments come back, main agent drafts the full episode:

```
1. Cold open (~30-60 sec / ~75-150 words)
   "Hey, this is your Special Episode for [date]. Today we're walking through
   [N] pieces - [one-line teaser of each]. Settle in."

2. Per-piece segments (variable, up to ~15 min each)
   - <break time="1.5s" /> + spoken transition ("First up...", "Next...")
   - Treatment rewritten as flowing essay-style narration
   - Direct quotes integrated as "And I'll quote..." / "As [author] writes..."
   - Brief Remix-relevance note woven in lightly (1-2 sentences max)
   - Soft handoff toward next piece

3. Themes-across segment (~1-2 min / ~150-300 words)
   Brief observations on patterns. Honest if there aren't strong threads.

4. Outro (~15-30 sec)
   "That's your Special Episode. [Date]."
```

**Output format requirements:**
- Clean prose, NO markdown headers in the body
- HTML-comment ToC at top of file for navigation when reading the markdown directly:
  ```html
  <!--
  Table of contents (invisible to ElevenLabs Reader):
  1. Cold open
  2. Piece 1: [Title]
  3. Piece 2: [Title]
  ...
  N. Themes across
  N+1. Outro
  -->
  ```
- `<break time="X.Xs" />` tags for pauses (1.0s standard, 1.5-2.0s at major transitions)
- Numbers and dates as words throughout
- Source attribution spoken inline: "from [Name] dot [TLD]"
- No URLs anywhere in the script

### 5. The rewriter handoff

After draft is assembled, main agent shows length estimate and asks:
- (a) run rewriter polish now [default]
- (b) let me read the draft first
- (c) skip rewriter

Default path invokes `/rewriter` with "in the npr-narrator voice" instruction. Rewriter applies its 4-stage pipeline (Strategist / Craftsman / Anti-AI Scrub / Voice Layer) but is explicitly instructed by the npr-narrator voice profile's Layer 4 to preserve `<break>` tags, numbers-as-words, source attribution format, and quote integration patterns verbatim.

### 6. File outputs

- **Script:** `/Users/justinmassa/Library/CloudStorage/GoogleDrive-justin@remixpartners.ai/My Drive/_DailyPodcast/YYYY-MM-DD-special-episode.md`
  - If multiple episodes same day: `-special-episode-2.md`, `-special-episode-3.md`, etc.
- **Treatments archive:** `~/Projects/special-episode-archive/YYYY-MM-DD-<slug>/`
  - One folder per episode
  - One `.md` per treatment, named `01-<piece-slug>.md`, `02-...`, etc.
  - `manifest.json` with episode metadata (links, fetch status, lengths, total runtime estimate)
  - Final assembled (pre-rewriter) draft as `episode-draft.md`
  - Post-rewriter final as `episode-final.md` (mirror of what's in `_DailyPodcast` for archival)

## Data flow

```
Input: pasted text with N links (1 <= N <= 8)
        |
   [parse + normalize]
        v
links: List[str]
        |
   [confirm with user]
        |
   [optional title hint]
        v
title_hint: Optional[str]
        |
   [parallel Task dispatch, one per link]
        v
treatments: List[Treatment]   # structured markdown blobs, see schema above
        |
   [main agent assembles]
        v
episode_draft: str   # full markdown, with <break> tags and prose
        |
   [confirm with user, default = run rewriter]
        |
   [/rewriter "in the npr-narrator voice"]
        v
episode_final: str
        |
   [write to _DailyPodcast and archive]
        v
files written, paths reported back to user
```

## Error handling

| Failure | Behavior |
|---|---|
| User pastes 0 links | Skill asks for links, doesn't dispatch |
| User pastes >8 links | Skill says "cap is 8 per episode, please split your list - which 8 first?" |
| Sub-agent can't fetch a link at all | Try Chrome MCP if not already tried; if still blocked, surface to user with options: (a) skip and continue, (b) you paste the text directly, (c) try again with different tools. Default = ask, do not silently skip. |
| Sub-agent partially fetches (paywall, truncated, auto-transcript only) | Treatment proceeds with explicit source-fidelity flag; flag visible in archive |
| Rewriter fails or returns unusable output | Save the pre-rewriter draft as the final file with a banner at top: "<!-- Rewriter pass failed; this is the unpolished draft. -->" Surface to user. |
| Drive sync path doesn't exist | Skill checks at start; if missing, errors loudly with the expected path |
| Filename collision (same day, same suffix) | Auto-increment: `-special-episode-2.md`, `-3.md`, etc. |

## Testing strategy

- **Manual testing in real sessions** is the primary mode, given this is a creative content skill.
- **First-run validation:** before declaring done, run a real episode with 3 mixed links (one article, one PDF, one YouTube) and listen to the result via ElevenLabs Reader. Adjust voice profile if it doesn't sound right.
- **Self-test for the skill orchestration:** run with 1 link to verify the parse/dispatch/assemble/rewrite/save loop works end-to-end before testing parallelism.
- **Self-test for failure modes:** intentionally pass a paywalled URL, a 404, and an unreachable host to confirm error handling surfaces correctly.

## Open questions for implementation phase

- Exact NPR-narrator voice profile content - to be drafted during implementation, then validated against a real episode and revised.
- **Rewriter "preserve verbatim" mechanism.** This design assumes rewriter's Anti-AI Scrub stage can be told (via the voice profile) to skip stripping certain content (`<break>` tags, spelled-out numbers, "from X dot Y" attributions). Verify during implementation that rewriter honors this; if not, either patch rewriter or invoke it with explicit pre/post-processing that protects the spoken-word mechanics.
- Whether to symlink the skill into `~/.claude/skills/skills/` from `~/Projects/special-episode/` (matching the standalone-repo pattern of rewriter and design-the-right-thing) or keep it inline in the claude-skills repo. Default: inline in the existing claude-skills repo unless there's a reason to standalone.
- Optional: lightweight Python helper for the YouTube transcript fetch path (yt-dlp wrapper) vs. shelling out directly. Default: shell out directly, no Python wrapper, until friction warrants it.

## Out of scope (potential future work)

- Migrating the briefing pipeline to use the new `npr-narrator` voice profile (consolidation, separate task)
- An "evergreen episode" mode that pulls from a saved reading list rather than fresh links
- Multi-voice or implied-dialogue formats
- Custom intro/outro music or audio post-processing
