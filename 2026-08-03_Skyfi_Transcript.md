# SkyFi Government Team: AI Integration Strategy
## 2026-08-03 Transcript · 32:16–End

**Participants:** Kate (gov team lead), Whitney (marketing), Jason Rubinstein, Justin Massa

---

## Summary

Kate runs SkyFi's government sales/delivery pipeline (BD → account mgmt → solutions arch → edge integrator → marketing → strategic briefs). Current state: context fragmented across Slack, HubSpot, Prism. Goal: unified, AI-augmented workflow with journey maps, context maps, and reusable prompts.

---

## Two-Phase AI Adoption Model

**Phase 1 (Now):** AI augments individuals while team figures out the *actual* process.
**Phase 2 (Oct 31 target):** Once process is locked down, give AI a clear sequential diagram (Mermaid/DAG) for strong automation.

---

## Start Here: Context Maps & Markdown Cheat Sheets

### Context Map (Source of Truth Cheat Sheet)
Where does each piece of information actually live?
- Deal value: Slack (not HubSpot field)
- Official legal entity name: HubSpot field X
- Informal reference: Slack message Y
- Lifecycle stage: some other field Z

**Why it matters:** When AI sees conflicting info, it doesn't know what to believe. A context map tells it.

### Milestone Expectations (Staging Checklist)
What questions MUST be answered by each stage?
- By BD handoff: customer pain points, budget range, decision-maker names
- By scoping: resource constraints, timeline, success criteria
- By delivery: training schedule, integration points, sign-off

### How to Deploy
1. Add both docs to top of Drive folder.
2. Add to ChatGPT personalization.
3. Every session, they load automatically.

---

## Transcript Automation

**Current:** "Everything goes into Slack."
**Proposed:** Daily scan → extract transcripts → file into customer Drive folders (subfolder: `Transcripts/`).

**Unlock:** Can now query "Did we ask & answer this question?" and pull exact quotes for gap detection or follow-up.

---

## CRM & Source of Truth Architecture

**HubSpot:** "Going away for the gov team." (Too cumbersome.)

**Prism:** Phenomenal for funding/Congress/NATO data, but NOT a system of record.

**Recommendation:** Build own internal system external to CRMs. Use Prism for market data (downstream). Own your workflow on Drive with strong data protection procedures.

---

## Process & Ownership (The Mise en Place Principle)

Assign one person per process segment to own "How do we think about AI in THIS part?"
- BD team: prospecting, qualifying, pitching
- Account mgmt: customer health tracking
- Solutions arch: spec building
- Integrator: training
- Marketing: packaging, briefing

**Critical:** Make sure terminology matches across teams.

---

## Implementation Roadmap

### Week 1
- Build BD context map (2–3 hours).
- Create milestone expectations doc.
- Add both to ChatGPT personalization.

### Week 2–3
- Set up Slack→Drive transcript automation.
- Pull 2–3 representative deals; extract all artifacts.

### Week 3–4 (The Two-Step Dance)
- Run AI analysis: "What patterns do you see?"
- You review & refine patterns.
- Draft v1 of process diagram.

### Month 2+
- Build reusable prompts/skills for each artifact type.
- Assign AI ownership per segment.
- Hold 90-min group session with team.

---

## Key Insights

**On Why Process Matters:**
"Plumbing is complicated. Spec first is slower but cleaner. Agile is faster feeling but has hidden rework. Use AI to discover patterns, then lock it in by Oct 31."

**On Context Maps:**
"It's a cheat sheet. 'Deal value is in Slack. When you see conflicts, believe this source.' AI just needs to know where to look."

**On Transcripts:**
"If I'm late in process and need early info, I can query 'Did we ask & answer X?' and get the exact quote. Unlocks individual problem-solving."

**On CRM Bloat:**
"Own your context with strong data protection. Far stronger than licensing another CRM."

---

## Kate's Next Actions

- [ ] Build context map (list where each data point lives).
- [ ] Create milestone expectations.
- [ ] Add to ChatGPT personalization.
- [ ] Set up Slack→Drive automation.
- [ ] Pull 2–3 representative deals.
- [ ] Schedule 90-min group session (check with Marie).

---

Reference: acme-ai-journey-map.vercel.app (public example of journey map + AI opportunities per stage)
