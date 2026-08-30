# Switchboard - cross-family sub-agent dispatch (design spec, 2026-08-29)

Design conversation started 2026-07-10; parked un-picked; resumed and approved in-session
2026-08-29. Input to the writing-plans implementation plan.

## Purpose

Let whichever harness Justin is driving - Claude Code, Codex, Cowork - act as orchestrator and
dispatch a sub-agent to **a different model family**, then get the result back. Today he does this
by hand, bouncing between desktop apps. The switchboard makes it a command any orchestrator can
issue mid-task.

**Explicit non-goal:** replacing native same-family sub-agents. Inside Claude Code, Claude-family
work keeps using the built-in Agent tool (better integrated: background runs, notifications,
isolation). The switchboard exists **only for crossing families**. Justin's existing "Fable may
delegate to lesser models" rule extends across families; it is not replaced.

## Why now (what changed since 2026-07-10)

1. **The economics inverted.** Lunaroute Apex (top tier, currently comped/managed by founder Eran
   Sandler) plus Justin's near-unlimited Claude window through September 2026 means per-token cost
   is effectively zero for ~1 month. "Route cheap work to cheap models" is dead as a v1 motivation.
   What survives and matters more: **second opinions from a foreign family**, throughput, privacy,
   and learning what to move off Claude in October when the meter returns.
2. **`remix-eval-kit` (built 2026-08-29) proved the mechanism.** Its `evalkit/runner.py` already
   swaps endpoint + model env per lane, fires a headless session, scrubs ambient env, deny-lists
   email tools, sandboxes to its own config dir, and enforces timeouts. The switchboard is that
   pattern generalized from *measurement* to *dispatch*. Do not reinvent it - port it.
3. **The eval kit answers a different question.** It asks "which model is good enough at workload
   X?" The switchboard asks "run this specific thing on that model, now." Eval kit = rubric
   generator; switchboard = the thing that acts on the rubric. They are complements, and the eval
   ledger is the evidence base that keeps the routing rubric from being vibes.

## Verified lane state (measured 2026-08-29, this session)

| Lane | Mode | Result | Latency | Notes |
|---|---|---|---|---|
| `codex` (GPT) | hands | LANE OK | 7s | **14,653 tokens for a two-word reply** - dragged Justin's full Codex setup (skills, plugins, 2 failing MCP servers, hooks) into the request. Cost is a non-issue; the 2 failing MCP servers are the real argument for a lean lane profile. |
| `glm` (GLM-5.2 via Lunaroute) | hands | LANE OK | 5.5s | Needs `CLAUDE_CODE_MAX_CONTEXT_TOKENS=524288`; emits an unrecognized-model warning; model name churns (`nvfp4` -> `vision` already). |
| `gemma-small` (gemma4:e4b, 8B) | brain | LANE OK | 9.5s warm | Mini via Tailscale. |
| `gemma` (gemma4-remix, 26B) | brain | timeout | >90s cold | Needs long timeout and/or Ollama keep-alive. |
| `gemma` *with tools* | - | **GATE-FAILED** | - | Eval kit, 2026-08-29: ignores tool-use instructions via Ollama's Anthropic endpoint, returns prose describing what it would do. Re-test on next Gemma release. |

The Gemma tool-use failure **confirms** the two-mode design below rather than breaking it.

## Architecture

**One CLI + one thin skill per harness.** The CLI knows *how* to reach every lane. Each harness's
skill teaches *when* to reach for it and points at the shared routing rubric. This split is the
anti-drift decision: routing logic duplicated as prose in three harnesses would diverge within
weeks (cf. the Jason skills-portability lesson).

```
Claude Code  ─┐
Codex        ─┼─>  switchboard CLI  ─>  lane registry  ─>  codex exec / claude --print / ollama
Cowork       ─┘         │
                        └─> ~/.switchboard/runs/<id>/  +  ledger.jsonl
```

### Two modes

Derived from "does this sub-task need hands, or only a brain?"

- **`--mode hands`** - a headless coding-agent session in a workspace. Can read, write, run
  commands, iterate. Lanes: `codex`, `glm`.
- **`--mode brain`** - a single model call, no tools, prompt in / text out. Lanes: `gemma`,
  `gemma-small`, and any hands-lane that does not need tools.

`brain` is not a degraded `hands`. It is cheaper, faster, and the only mode Gemma currently
supports.

### Lane registry

`~/.config/switchboard/lanes.yaml` - **machine-level, not repo-level**, because lane availability
is a property of the machine. Format deliberately mirrors the eval kit's `config/lanes.yaml`.

Each lane declares: `kind` (`anthropic-gateway` | `codex-cli` | `ollama`), `model`, `base_url`,
`api_key_path`, `modes`, `context_tokens`, `max_concurrency`, `timeout_default`, `extra_env`,
`profile_dir`.

Adding a lane - OpenRouter, a new GLM revision, a future local model - is a config edit, never a
code change. This is the granularity requirement: routing judgment stays in prompt/config space.

### Isolation vs. leash (revised 2026-08-29 after Justin's pushback)

The first draft of this spec bundled three unrelated things under one "clean-room profiles
(non-negotiable)" rule and was wrong to. Separated properly:

**Always on - zero capability cost, genuinely non-negotiable:**

- **Own config/home dir** (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`). The sub-agent gets its own history,
  auth, and session state so it cannot disturb Justin's real sessions.
- **Env scrubbing.** If a stray `ANTHROPIC_BASE_URL` leaks, a run labeled `glm` silently executes
  on Claude and every comparison drawn from it is garbage. Correctness guard, not a restriction.
- **Messaging deny-list** (no email send/reply/forward, no GChat sender). A dispatched sub-agent
  must never message a human as Justin.

**Default: full leash.** Skills, repo context, and project conventions are AVAILABLE by default.
Long leash is the default for work.

Correcting a factual error in the first draft: `--setting-sources ""` and `--strict-mcp-config` do
**not** strip skills. Verified directly 2026-08-29 - a session with both flags still enumerates its
skill library. That is why the eval kit's GLM proposal run scored 5/5 on completeness: the skill
loaded and ran. Those flags remove hooks, user settings, and MCP servers only.

**`--clean` (opt-in): withhold repo conventions and CLAUDE.md.** Justified in exactly one case -
**adversarial review**. A reviewer briefed on our rulebook agrees with our rulebook; that anchoring
destroys the point of asking a foreign family. This is a property of *review tasks*, not of foreign
lanes generally, and the first draft wrongly generalized from the one case to all cases.

**`--mcp` (opt-in): account access.** MCP servers are live write access to Gmail, Drive, Slack,
RemixOS, and calendar. "Lunaroute may read client text" (settled, see Data policy) and "a GLM agent
may write to Drive and post in Slack unsupervised" are different decisions, and only the first has
been made. A misfiring sub-agent holding account keys is a different risk class from one that
writes mediocre prose. Off by default; on by request per dispatch.

**The test that proved the original rule too tight:** as first written it would have forbidden the
flagship hybrid lane - "GLM drafts, Claude judges" on `remix-proposal-writer` - which is the
headline experiment in the eval kit spec. A rule that blocks the best use case is a bad rule.

The 14.6k-token Codex measurement stands as a fact but is **withdrawn as a justification**: it is a
rounding error, and free through September. It argues for a lean *default* profile on the `codex`
lane, not for withholding capability. The real reason that lane needs its own profile is that two
of Justin's MCP servers threw auth errors inside the dispatch - broken ambient config, not cost.

### Briefs are written for strangers

A foreign sub-agent has no CLAUDE.md, no memory, no idea who Stafford is. Every dispatched brief
must be self-contained: goal, inputs (paths or inline), constraints, and the exact shape of the
expected output. The per-harness skill carries this instruction prominently. The same blankness
that makes this necessary is what makes cross-family review valuable - zero anchoring on our
assumptions.

### CLI surface

| Verb | Purpose |
|---|---|
| `sb dispatch --lane <l> --mode <m> [--write] [--clean] [--mcp] [--bg] [--timeout N] <brief>` | Fire a sub-agent. Brief from arg, file, or stdin. Full leash by default; `--clean` withholds repo conventions (adversarial review only); `--mcp` grants account access. |
| `sb list [--active]` | Runs, newest first, with status + lane + elapsed. |
| `sb log <id> [--full]` | Result (default) or full transcript. |
| `sb lanes [--check]` | Available lanes; `--check` pings each and reports health. |

`list`/`log` are not garnish - dispatch without them is `create` with no `read`, the CRUD gap
flagged in the 2026-07-10 agent-native audit.

**`kill` was cut from v1 during the build (2026-08-29).** v1 dispatch is synchronous and never
captures a live pid, so a `kill` verb could never actually kill anything - a control that never
refuses. It pairs with `--bg`, and the two return together or not at all.

**v1 is synchronous** (orchestrator waits, gets the result). `--bg` and `kill` were cut from v1
during the build: they are a pair, and a kill verb with no live pid to kill is worse than no verb.

### Run storage

`~/.switchboard/runs/<run-id>/` containing `brief.md`, `result.md`, `transcript.log`, `meta.json`
(lane, mode, model, exit status, seconds, tokens where available, meter). Plain files: inspectable
by Justin, readable by any harness, self-documenting. One line per run appended to
`~/.switchboard/ledger.jsonl`.

Cost meters are recorded even while everything is effectively free, because the October question
("what should move off Claude?") needs the history.

### Output contract (token discipline)

`dispatch` returns a **compact** result by default: status, lane, elapsed, meter, result path, and
the sub-agent's final answer. Never the full transcript - half the value of a sub-agent is keeping
the orchestrator's context clean, and a chatty dispatcher pours the mess right back in. Full
transcript is opt-in via `sb log <id> --full`.

Other interface requirements, from the AXI checklist:
- **Explicit failure states.** A dead lane (Mini asleep, key expired, model renamed) says so in
  one line. Never hang, never return ambiguous silence.
- **Explicit completion.** A run is done when it writes `result.md` and exits non-zero-free -
  a fact, not a guess.
- **Next-step hints.** Output ends with the useful follow-on command.
- **Shortcut, not gate.** Raw `codex exec`, `glm`, and direct curl-to-Ollama all remain available.
  The switchboard is a convenience, never the only door.

## Safety model

- **Read-only by default.** `--mode hands` runs with a read-only sandbox unless `--write` is given.
- **`--write` runs in an isolated git worktree**, never the live checkout. Everything inspectable
  and revertible; the existing `pre-push` agent-guard still protects `main`.
- **Deny-list inherited from the eval kit**: no email send/reply/forward, no GChat sender, no
  notify paths. A dispatched sub-agent must never be able to message a human on Justin's behalf.
- **Concurrency caps per lane** (from `lanes.yaml`), so a fan-out cannot exhaust the Mini or trip
  Apex limits.
- **Account access is opt-in per dispatch** (`--mcp`), never ambient. See Isolation vs. leash.
- **Secrets never enter a brief** - see Data policy.

## Data policy (settled 2026-08-29)

Justin: *"Lunaroute is a trusted source!"* The July caution ("keep client-confidential work out of
the glm lane until trust is established") is **superseded**: the trust gate is closed. Client
material may go through the `glm` lane, and the same trust extends to the `codex` lane (Justin
works in ChatGPT daily). Local Gemma never leaves the tailnet.

**The one rule that survives for every lane, trusted or not:** secrets, API keys, and credentials
never go into a dispatched brief.

The `reference_glm_lunaroute_lane` memory file was corrected in this session to stop future
sessions from enforcing the retired restriction.

## Routing rubric

`~/.config/switchboard/rubric.md` - **a text file, not code.** Which model earns which work changes
monthly; it must be editable without touching the CLI.

v0 content, explicitly provisional and to be replaced by eval-kit evidence:
- **Cross-family adversarial review** -> the family *opposite* whoever wrote the code. The killer
  app; it is what Justin already does by hand.
- **Structure/scaffolding drafts** -> `glm`. First graded head-to-head (Tullman proposal, eval kit
  2026-08-29): completeness 5/5, **accuracy 1/5** - inverted a fact, cited an untraceable source,
  invented a word cap. Profile: gets the shape right, confidently wrong on specifics. Never route
  fact-critical work here.
- **Bulk mechanical brain work** -> `gemma` (free, private, always-on), below Haiku on the
  judgment ladder until eval evidence promotes it.
- **Anything client-stakes or fact-critical** -> stays frontier Claude.

## The bright line

The switchboard **dials; it never decides.** No `--auto` flag that picks a lane in code. Routing
judgment lives with the reasoning orchestrator, guided by the rubric file. The moment lane
selection moves into the CLI, this becomes the "Agent as Router" anti-pattern - judgment buried in
code where it cannot be edited, reviewed, or improved by prompt.

## Where it lives

**Standalone repo `remixpartners/remix-switchboard`**, cloned to `~/remix-switchboard`.

This reverses an earlier suggestion in-session to add it as a second verb inside `remix-eval-kit`.
Reason: another session is actively committing to that repo *today*, and two sessions in one
checkout is precisely the hazard recorded in the `shared-checkout worktree discipline` memory. A
~15-line duplicated lane config is cheaper than a collision. Once both tools settle, merge the two
lane files into the shared machine-level config.

Ordinary Remix repo rules apply: branch, PR, self-review, self-merge, verify it runs. Never push
to `main`.

## Scope

**In, v1:** the CLI with all five verbs; `codex`, `glm`, `gemma`, `gemma-small` lanes; both modes;
lane isolation (own config dir, env scrubbing, deny-list) with full-leash defaults plus `--clean`/`--mcp` opt-ins; run storage + ledger; read-only default with worktree `--write`; the routing
rubric file; the Claude Code skill.

**In, v1.1 (trivial once the CLI exists):** Codex `AGENTS.md` pointer and the Cowork skill - the
CLI is harness-agnostic by construction, so these are short pointers, not builds.

**Out of scope for v1:** OpenRouter lane (config edit once a key exists); automatic lane selection
(see The bright line); scheduled/unattended dispatch; any merge with the eval kit's config;
Gemma-with-hands (blocked upstream on tool-use support).

## Testing

Per Justin's 2026-08-28 test-estate call, new feature code gets a light default: one smoke test
plus a runtime alarm, with test-first reserved for consequential logic.

- **Smoke:** `sb lanes --check` against a fake lane binary; one round-trip dispatch per lane kind
  with a stubbed executable (the eval kit's `_fake_claude` pattern).
- **Test-first (consequential):** the env-scrubbing logic - a leaked `ANTHROPIC_BASE_URL` would
  silently run a "Claude" lane on GLM and corrupt any comparison. This is exactly the class of bug
  the eval kit guarded against, and it must be proven by an observed failing test first.
- **Alarm:** `sb lanes --check` is the canary; a lane that has failed health for 7 days is
  reported at the next batch session, not pushed (fails CCIR).
- Test hygiene per `chief-of-staff/CLAUDE.md`: pytest-collectable, pinned clocks, no real paths or
  credentials.

## Agent-native checklist

| Principle | How this design satisfies it |
|---|---|
| Parity | Anything Justin does by app-bouncing, any orchestrator can dispatch. `list`/`log`/`kill` close the CRUD gap. |
| Granularity | CLI dials, rubric decides. Behavior changes by editing text, not code. |
| Composability | Judge panels, escalation ladders, and mixed pipelines become prompts. Composes with cron, Workgraph, CoS jobs. |
| Emergent | New lane = one config block. Ledger is the observation instrument for what to formalize. |
| Improvement | Rubric edits deploy to every harness at once; per-run outcome annotations build the evidence that promotes a lane. |
