# The Context Project
## A repeatable Remix offering for making a business agent-legible

**Status:** v0.1 outline, drafted by Stafford 2026-08-04. Sources: the 8/4 partner chat, the 8/3 Skyfi call, a sweep of all 370 partner chats and the full client corpus, both vaults, and Remix's own context system. Audience: Justin + Jason. Purpose: the internal spec from the 8/4 call, shaped so the Kate (Skyfi) response can be cut directly from it.

---

## 1. The one-line pitch

Your business produces context all day: meetings, decisions, email, know-how. Almost none of it is captured where an AI agent can use it, and what is captured is scattered across apps that don't talk, in formats agents choke on, with no record of which source to believe. The Context Project captures what you're losing, converts what you have, and structures both so your people and your agents can find it and trust it.

The compressed version you already use with prospects (Footprint, 3/13): "make your business agent legible: radically simplify things, markdown files over PDFs, clear directory structures."

## 2. This is the eighth rep, not the first

The corpus is unambiguous: you have been circling this offering since January and delivering it informally all year. What's missing is only the packaging.

- **Feb 18:** "I have a hunch, we will help our clients do this by the summertime. We're going to make you agent legible." (S2G was already converting transcripts and notes to markdown and cleaning up Box.)
- **Feb 24 (EZO prep):** "step one is, make your business agent legible" - already framed as a stage before the Kickstart.
- **Mar 4:** "our notional offer around here's how you move yourself to markdown... dismantle your agent obstacle course and make yourself agent legible. They are fucking perfect for it because they're all documents." (re Gasthalter)
- **Jul 14 (Hoop):** "We've done like seven or eight now of these little... we originally called them sprints. They're sprint level efforts, but they actually take place over like two months because everybody's data is a disaster, and they don't realize how much of a disaster it is."
- **Jul 30 (weekly sync with Ben):** "everyone we talk to... internal context is a total mass. It's both disorganized and it's not agent legible. And getting a business current state to be agent legible is a whole thing."
- **Aug 4:** "one hundred percent of our clients would benefit from a context project" + the phase spec this doc formalizes.

The knowledge vault called it in its canonical note (`strategy/vision/agent-legibility.md`, 24 sources since January): "agent-legibility services are likely to become a distinct advisory offering during 2026." Neither vault contains a packaged, priced, scoped definition. That is the gap this document fills.

## 3. Why now, and why us

- **Clients are asking by name.** Kate at Skyfi the day after seeing context maps: "oh, I see it now. I get it." Justin's 8/4 read: "some of our clients, as soon as they get the context thing, they're like, oh shit, this is a bunch of work and I need it fast."
- **The mess is universal, and it's structural.** Jason's four-day Drive forensics (Mac-incompatible names, thirteen locked contracts, speaker-less legacy transcripts) is what every client environment looks like. Justin's phrase: "technology paradigm transitionary detritus." Every client straddles the SaaS paradigm and the agent paradigm; the seam (cloud vs. local, sync, naming, formats) is a hornet's nest nobody owns. The practical variables that shape the work: Microsoft vs. Google shop, Mac vs. Windows fleet. Model choice barely matters.
- **The whitespace is documented.** The March briefing (Agent-Legible-Business-Briefing.docx): the discourse is all code repos and product docs (llms.txt, CLAUDE.md); making an operating business agent-legible, especially an SMB, has no owner. "The question isn't whether businesses will become agent-legible. It's who will help them get there." Private vault, same conclusion: "agent legibility as a massive new service line... demand will vastly outstrip supply for years."
- **We sell what we run.** The Lyra insight from 8/4: an MSP selling context maintenance would print money, but can't, because their own context gives them no authority. Ours does: CONTEXT-MAP.md, the CLIENT.md fleet with its 4 AM refresh, the transcript pipeline, two knowledge vaults, per-folder indexes. Justin in July: "this is about doing it for ourselves so we can better talk to our clients about it." The UVA lecture version: "My own business is agent legible, and it is wild."

## 4. The framework we install (the IP)

The value anchor comes from Remix Methodology v0.1, layer 6 of the stack: **"The context - the files, the data, the accumulated record of how your business actually works. The most proprietary thing you have. It does not leave when employees do, and it compounds with use. This is where most of your real investment should go."** The Context Project is the engagement that acts on that claim. Models and harnesses are commodities you rent; context is the asset you own.

**Four types of context** (our CONTEXT-MAP, field-tested at Marquee as "the three kinds"):
1. **What happened** (the ledger): meetings, decisions, interactions
2. **What's true right now** (live state): pipeline, money, inventory - read from the system of record, never from memory
3. **How we work** (the playbook): processes, frameworks, standards
4. **Who we are** (identity and rules): voice, values, guardrails

Most businesses capture almost none of 1 and 3, have 2 trapped inside SaaS tools, and keep 4 entirely in people's heads.

**Hot / warm / cold layering.** Organize by how often an agent needs it: hot (always loaded: the rulebook and indexes), warm (one query away: running logs, the source-of-truth map, searchable history), cold (primary sources: transcripts, email, documents). Design principle: **index in context, content on demand.** We have a client-ready diagram (the context map png). Marquee got the org-scoped version: firm-wide / team-by-team / everyone.

**The one rule.** Every layer is a lossy compression of the layer below. Answer from the highest layer that answers confidently; on conflict or high stakes, chase the citation down to the primary source. This one rule is what makes an agent trustworthy on top of messy reality.

**The accountability model** (client-tested at Marquee): individuals are accountable for their own context, team leads for their team's, "the AI is accountable for none of it, because it is not capable of being accountable." Ownership is assigned per process segment (the mise en place principle from the Skyfi call).

**The 2x2 north star** (March briefing): context is made BY humans or agents, FOR humans or agents. Clients live in Q1 (SOPs by humans for humans). The project moves them to Q2 (context by humans and agents, for agents). The end state is Q4: **the client's agents maintain the client's context**, humans reviewing. Self-serve ethos with teeth, and territory nobody else is touching.

**Standing principles:**
- **Own the files; don't rent your memory.** Context lives in open formats on storage the client controls, not licensed back from a CRM. (Skyfi: "Own your context with strong data protection. Far stronger than licensing another CRM." HubSpot is "going away" for that team.) Whether we adopt "file over app" as the public phrase is an open question (#12); the principle is settled.
- **Markdown is the substrate.** Jason to Pluris, on the record: "we're going to deliver files in markdown, why? Because that's the most simple format. It's the HTML of gen AI."
- **If humans understand the structure, agents will too.** Agent-legibility and a well-run business are the same renovation.
- **Capture at the source.** Recording + transcription is the highest-leverage habit; the transcript archive converts "we lost that" into "we can recover that."
- **One canonical home per fact,** pointers everywhere else. Copies drift. (Teays got this as the "canonical context file" recommendation.)
- **Provenance everywhere.** Summaries carry pointers back to what they compress.
- **Separate facts from analysis.** The facts.md / analysis.md split (S2G precedent, adopted at Buoyant) keeps ground truth distinct from interpretation.

## 5. What clients aren't capturing (the audit inventory)

Discovery walks this list. It doubles as the sales narrative, because most owners have never seen their leakage enumerated:

1. **Conversations.** Meetings, calls, standups: the richest context stream a business has, evaporating daily. (Our own 738-recording archive has repeatedly recovered things nothing else held.)
2. **Decisions and the why.** Made in chat or on calls; only the outcome survives, so reasoning gets re-litigated.
3. **Tribal knowledge.** How work actually gets done, per role. Leaves with people.
4. **Where truth lives.** Which system holds the real number when systems disagree. (Skyfi: deal value lives in Slack, not the HubSpot field. Nowhere was that written down.)
5. **What files and folders are.** No indexes, no naming standard; neither a new hire nor an agent can navigate without loading everything.
6. **Stage expectations.** What must be known by each step of the core process. Uncaptured, so nothing can check completeness.
7. **Email as record, documents in app-bound formats.** Locked to inboxes, PDFs, and proprietary formats with no plain-text twin.

Sales caution from the vault (`resonance/aha-moments/own-data-through-ai-lens.md`): clients get defensive the first time they see their own data quality through an AI's eyes. The audit must land as "everyone's basement looks like this" (it does - see Hoop quote), not as an indictment.

## 6. The engagement, phase by phase

Structure per the 8/4 call, extended with delivery detail from Skyfi, Marquee, and our own build.

### Phase 1: Discovery (with them)
- **Describe the ideal.** "What do you wish your agents and your people just knew?" Business objectives first; the context strategy serves them.
- **Prioritize.** Now vs. later. Explicit guardrail from the call: never a boil-the-ocean exercise.
- **Analyze the tech stack and system architecture.** Deeper than the survey: software inventory, file-management reality, where context lives today, who owns what. Includes the **incompatibility scan** (naming, formats, permissions, sync topology - Jason's after-action report is the template).

### Phase 2: Assessment (on us)
Deliverables:
- **The Context Map, current state.** The source-of-truth cheat sheet: where each critical fact lives, which source wins on conflict. (Skyfi framing: "It's a cheat sheet. 'Deal value is in Slack. When you see conflicts, believe this source.' AI just needs to know where to look.")
- **The evolved target.** Proposed tech stack, system architecture, and file structure with the context strategy in place. What changes, what stays, what gets a markdown twin.
- **The roadmap.** A sequence of phased projects, each with a clear outcome, with **intentional pauses** built in. Justin's 8/4 point: the ground shifts under your feet; how you manage context on today's models differs from six months ago. Scheduled stop-and-reassess beats pretending the target is static.

### Phase 3: Timing and cost
- Level of effort per roadmap item, then pricing. Client signs off on the plan before build starts. (The HireWell lesson applied: formal gates, expectations reset in writing, no "we'll see how it goes.")

### Phase 4: Build (with them, not for them)
Typical roadmap order:
1. **Capture:** recording and transcription on every meeting that matters, auto-routed into per-account folders. Proven pattern: the `assistant@company` + recorder account built at Excelsior. The unlock, per Skyfi: "Did we ask and answer X?" answered with the exact quote.
2. **Convert:** naming hygiene, format rescue (markdown twins of app-bound docs - Orange EV's "Teams-to-Markdown" was a top-3 survey ask; Marquee's law library came from PDF-to-markdown conversion), speaker identification, legacy backlog triaged rather than boiled.
3. **Structure:** folder architecture that means something; **read-first indexes** (every working folder gets a 50-200 line markdown index an agent reads first; if it outgrows that, split the folder); **running logs** per account/project (the CLIENT.md pattern, taught at Buoyant and Marquee as project.md/client.md). Test for a running log: can someone brand new, human or agent, open it and understand the relationship without re-reading everything?
4. **Load:** wire the hot layer into their actual tools (their CLAUDE.md / personalization / system-prompt equivalents) so every session starts oriented. The Powerfleet bet, verbatim (5/19): "not changing anything but making the information legible... is going to see them get like four or five times better responses with nothing else changed."
5. **Own:** one named owner per process segment and per piece of context (mise en place + the Marquee accountability model). Vault governance where needed (S2G principles: classify at vault level, least privilege, segment by who not by topic, human ownership).
6. **Ratify:** the two-step dance. Agents propose the patterns they see in the captured corpus; humans review and lock the process diagram. AI drafts, people sign off.

### Phase 5: Maintain
Two flavors, offered explicitly:
- **Self-serve (default, our ethos, same as Kickstart 3.0's "they build, we coach"):** maintenance runbook + a trained internal owner. Target state is Q4 of the 2x2: their agents maintain their context, humans review.
- **Context maintenance contract (the recurring flavor, born on the 8/4 call):** scheduled audits, incompatibility scans, drift checks, adaptation as tools and models change. There is "endless care and feeding" in these systems; the 8/4 insight is that care and feeding is a product, not an apology.

### Scoping guardrails (the corpus is insistent on these)
- **It always takes longer than it looks.** Hoop: sprint-level efforts "actually take place over like two months because everybody's data is a disaster, and they don't realize how much of a disaster it is." Scope and price for that reality; don't sell a two-week cleanup.
- **Iterate; don't blueprint.** The Marquee Context Architecture doc, on our own system: "Remix started in January with exactly one thing: a file with the same name at the top of every client folder... What it has become is far larger and stranger, and we could not have designed it in January. It arrived by iteration, not by design." The roadmap commits to the next phase firmly and the horizon loosely. Start with one file at the top of every folder if that's what the client can sustain.
- **Fix legibility before adding capability.** The vault's context-engineering note: knowledge management is the prerequisite; organizational cleanup is step one, not a nice-to-have. Don't let the client buy agents to sit on top of an unnavigable corpus.

## 7. The repeatable artifact set

Every Context Project ships from the same menu. Nearly every item has already been delivered to a named client at least once - this is what makes it a product with margins rather than bespoke consulting:

1. Context Map, current state (Skyfi)
2. Target architecture: evolved stack + file structure (8/4 spec)
3. Phased roadmap with intentional pauses (8/4 spec)
4. Capture pipeline: recording, transcription, routing, retention (Excelsior, Hirewell)
5. Read-first indexes across working folders (Five Rivers, Marquee)
6. Running logs per account/project: the CLIENT.md pattern (Buoyant, Marquee)
7. Milestone expectation checklists per process stage (Skyfi)
8. Naming + format standard, Mac/Google-safe, markdown-first, plus the incompatibility scan-and-fix script (Jason's after-action report)
9. Facts/analysis separation + vault governance where multiple audiences share context (S2G, Buoyant, Pacific Transformer)
10. Loading discipline: hot-layer files wired into their tools, plus the ownership map (Excelsior CLAUDE.md-per-folder teaching script, Marquee)
11. Maintenance runbook or maintenance contract (new, from 8/4)

## 8. Staffing: the guide and the plumber

Direct from the 8/4 call, and the model being set up for HireWell:

- **Remix partners:** strategy, the assessment, client communications, expectation-setting. Unified comms cadence during builds is now standard (HireWell feedback: silence during groundwork reads as nothing happening).
- **The guide (Ben archetype):** the IDEO guiding role. In the room for milestone scoping, roughly an hour a week of technical review, training and knowledge transfer to the plumber. Non-FTE by design; reserved "for higher order opportunities."
- **The plumber (Nathan archetype):** hands-on builder working the roadmap day to day, at a more aggressive pace and labor rate.

Justin's packaging of the motion, verbatim: "We're going to talk to you about the strategy of context. We're going to assess your context setup. We come up with a plan. You're going to sign off on the plan. And then we're going to build it with you."

## 9. How we talk about it

- **The groundwork narrative.** Justin's metaphor from 8/4, which should be in every pitch: groundwork is the longest phase of building a house, it looks like nothing is happening, it is the most expensive, and you cannot build the house without it. HireWell taught us the cost of smuggling groundwork inside builds; the Context Project sells it by name, with its own deliverables, so the value is visible instead of resented.
- **The diagnostic hook.** "Change nothing else. Make your information legible, and the same tools get four or five times better." (Powerfleet prep.) This is the cheapest credible promise in the portfolio.
- **The urgency frame.** The vault's "selling plywood before the hurricane": demand is about to vastly outstrip supply; early movers compound.
- **Language check.** Justin, 5/01: "the make your business agent legible language is really not stuck." The 2026 arc backs him: "agent legible" carried the idea internally, but what made Kate say "I get it" was *context* language plus a concrete map. Recommendation in #12.

## 10. Where it sits in the product family

- **The private vault already reserves the slot** (`engagement-structure-evolution.md`): a pre-stage before the Kickstart - "Make your business agent legible. Restructure digital operations so AI agents can navigate them." Portfolio today: Kickstart $20-30K, Pulse $25K/yr, Design Sprint $16-20K; Kickstart 3.0 draft at $30K+/6wk. (Private-vault figures - don't lift into client docs.)
- **Vs. Kickstart:** same DNA (map first, phased, they-build-we-coach, plan deliverable, retainer dovetail). Kickstart finds and ships the jigs; the Context Project makes the business legible enough for jigs and agents to run well. Justin on 8/4: "this feels like we need to re-scope a kickstart." Sequence either way: context-first for the tangled, Kickstart-first for the eager.
- **Four packaging flavors:** (a) standalone project for new clients; (b) change order on a live engagement (Skyfi, this week); (c) named groundwork phase inside a build (HireWell, retroactively); (d) standing maintenance contract.
- **Productization discipline to copy:** Pulse (`pulse-service-evolution.md`) - the SOW template and actual client SOWs are near word-for-word identical; customization happens in delivery, not in contract. Write the Context Project SOW template once, to that standard.
- **Channel, later:** MSPs and IT firms (the Lyra conversation) could resell context maintenance at scale but can't originate it. If the offering proves out, we productize it for that channel. Parked.

## 11. Pricing posture (open, per the 8/4 call)

Agreed sequence: requirements first with Kate as test case, Ben + Nathan estimate level of effort, Sandy checks pricing. Natural shape given the phases: fixed-fee Discovery + Assessment (the diagnostic - fast, standardizable, priced like a product), build priced per roadmap phase, maintenance as monthly recurring. The two-month Hoop reality argues for pricing the build in phases rather than as one fixed sprint. Numbers are yours and Sandy's.

## 12. What I want you two to react to

1. **Name.** "Context Project" (working) vs. "Context Kickstart" vs. owning a bigger term. Evidence says lead with *context* in the sell and keep *agent-legible* as the explainer, not the banner [a: agree / b: keep agent-legible forward / c: other].
2. **Kate response shape.** Change order against the current engagement, or first sold instance of the standalone offering with her as acknowledged test case [a: change order / b: first sale / c: hybrid - change order now, formalize after].
3. **Diagnostic pricing.** Fixed-fee Discovery + Assessment as its own product, or fold assessment into the first build phase [a: fixed diagnostic / b: fold in].
4. **Staffing bet.** Is this the Ben + Nathan proving ground, per the HireWell restructure [a: yes / b: partners-only first rep].
5. **Maintenance stance.** Lead with self-serve and offer the contract, or lead with the contract [a: self-serve default / b: contract default].
6. **Vocabulary.** Adopt "file over app" as public language? It appears exactly once in the corpus; it's evocative but borrowed (Obsidian's phrase) [a: adopt / b: keep "own your files" phrasing].

---

## Sources

**Primary (read in full):**
- Partner chat 2026-08-04 "HireWell Renewal Plan, Google Drive Mac Naming Fixes, and Context Maintenance Offering" - the phase spec, Lyra insight, 100%-of-clients claim, guide/plumber, groundwork metaphor, intentional pauses, maintenance contracts.
- Skyfi call 2026-08-03 (transcript in ClaudeProjects) - Kate's ask, context-map cheat sheet, milestone expectations, transcript automation, mise en place, two-phase adoption, week-by-week roadmap.
- Agent-Legible-Business-Briefing.docx (REMIX MAIN root, 2026-03-01) - market landscape, llms.txt, the 2x2, whitespace analysis.
- Remix Methodology - DRAFT v0.1.md (REMIX MAIN root, 2026-05-28) - six-layer stack; context as layer 6, verified verbatim.
- ~/CONTEXT-MAP.md + context map png - four context types, hot/warm/cold, the one rule.
- Kickstart 3.0 (Strategy/) - packaging DNA, they-build-we-coach, retainer dovetail.

**Partner-chat corpus** (370 files; theme present in 23+; key files): 2026-02-18 (the "by summertime" prediction), 2026-02-24 EZO prep ("step one"), 2026-03-04 (the notional offer), 2026-05-01 (language "not stuck"), 2026-05-19 Powerfleet prep (4-5x), 2026-05-20 Lunch ("every company should become agent legible"), 2026-06-16 (three-vault architecture told to a client), 2026-06-26 (our knowledge-management system end-to-end), 2026-07-30 J+J+B ("everyone we talk to").

**Client precedents (paths in Clients & Partners/):** Marquee (AI Action Plan/2026-07-31 Context Architecture source - the closest thing to this methodology already written), Excelsior (2026-02-20 transcript - the verbatim agent-legible teaching script + assistant@ transcript routing), S2G (knowledge-vault structuring + the markdown/Box migration), Hirewell (transcription as the foundational OS layer), Buoyant (three-level context architecture; "what context should live in markdown?" as a strategy question; facts/analysis split), Powerfleet (client-built Obsidian second brain; Architecture & Shared Context section), Pacific Transformer (vault architecture + data separation), Orange EV (Teams-to-Markdown in SOW), Skyfi (agent-legible Slack channels), Teays (canonical context file), Five Rivers (index-pattern email, 6/11), Pluris interview ("markdown... the HTML of gen AI"). Leads with the pitch delivered: Hoop (the seven-or-eight quote, verified verbatim), Footprint (the one-sentence definition), SKIMS, UVA lecture.

**Vaults:** knowledge vault `strategy/vision/agent-legibility.md` (canonical, 24 sources), `market-intel/capabilities/context-engineering-over-prompting.md`, `resonance/aha-moments/own-data-through-ai-lens.md`, journey-stage notes; private vault `strategy/business-model/engagement-structure-evolution.md` (the pre-stage slot + portfolio pricing), `strategy/vision/pulse-service-evolution.md` (SOW standardization discipline), `eat-your-own-dog-food.md`.

**Episodic memory (Jan-Jul sessions):** build-it-first quote (7/09), Five Rivers pattern email (6/11), CLIENT.md discipline, vault build mechanics, Sensorium provenance model. Dedup confirmed: no prior draft of this offering exists in any corpus; this is the first formalization.
