---
name: agent-product-harness
description: Bootstrap and run a software product end-to-end using the Agent Product
  Harness — disciplined methodology for building Next.js 16 + Tailwind v4 + TypeScript
  products with agentic IDEs (Antigravity, Cursor, Codex). Externalizes
  Memory, Skills, Protocols and Harness per Zhou et al. 2026. Provides templates
  for discovery, PRD, tech spec, ADRs, sprints, execution, testing, deploy. TRIGGER
  when starting a new product, scaffolding docs/ structure, asking how to plan,
  build or ship a Next.js product with agentic dev, or advancing between phases
  (discovery → PRD → spec → sprint → execution → testing → deploy). SKIP for
  isolated bug fixes, one-off scripts, or refactors that do not warrant phase
  ceremony.
---

# Agent Product Harness

You are an agent following the **Agent Product Harness** methodology — a disciplined
workflow for building software products with LLM agents in the loop, derived from
Zhou et al. (2026) "Externalization in LLM Agents" and consolidated for Next.js 16
Tailwind v4 + TypeScript stacks.

The methodology rests on five non-negotiable principles:

+ **Document before code.** Each phase produces a versioned artifact in `docs/`.
+ **Minimum viable context.** No agent receives more than it needs.
+ **Artifacts, not prose.** Reviews happen on diffs/screenshots, not chat logs.
+ **Human in the loop by default.** `agent-assisted` mode unless explicitly upgraded.
+ **Sandbox always on.** Allowlisted commands; restricted workspace.

Full architectural rationale: [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md).
Mechanical conventions (frontmatter, paths, datetime, sed): [`references/00-conventions.md`](references/00-conventions.md).
Critical analysis vs. the source paper: [`references/00-paper-analysis.md`](references/00-paper-analysis.md).

---

## Quick Reference

Route by user signal first. Cite only the section needed; don't load everything.

| User says | Path | Pre-flight |
|-----------|------|------------|
| "começar produto", "scaffold", "init", "bootstrap" | §A — Bootstrap | `cwd` is target project root, no populated `docs/` |
| "avançar fase", "próxima fase" | §B — Advance phase | `_summary.md` of previous phase complete |
| Methodology question ("why X?", "when to delegate?") | §C — Q&A | — |
| "implementar story X" | §D — Story execution | story file at `docs/sprints/<n>/<id>.md`; sprint-plan exists |
| "corrigir bug em story X", "bug em #N" | §E — Bug execution | story `<id>` exists; new bug lives in same sprint folder |
| "qual o status?", "o que falta?", "valida o projeto" | §F — Tracking via scripts | `docs/` exists |
| "spec está errada / contradiz código" durante execução | §H — Spec Drift | story is in execution |
| "sincronizar com GitHub", "epic em issues" | §G — GitHub sync (optional) | `gh` authed, `validate.sh` green |

If the signal is ambiguous, **ask one question** to disambiguate. Do not guess.

---

## §A — Bootstrap a new product

**Pre-flight:**

1. Confirm `cwd` is the **target project root** (not the skill folder itself).
   If the user invoked you from inside the skill repo, refuse and ask for the
   target path. The repository safety check in [`references/scripts/_safety.sh`](references/scripts/_safety.sh)
   formalizes this.
2. Confirm `cwd` does **not** already have `docs/` populated. If it does,
   route to §B instead.

**Discovery questions** (ask the human; do not invent answers):

+ What is the product name?
+ Who is the sponsor (decision-maker)?
+ One sentence: what problem does it solve, and for whom?
+ Is this greenfield (`pnpm create next-app`) or adding harness to an existing repo?

**Scaffolding actions** (after answers):

1. Copy `templates/AGENTS.md` to `<cwd>/AGENTS.md`, substituting placeholders.
2. Create `<cwd>/docs/` tree (full structure documented in
   [`references/00-conventions.md`](references/00-conventions.md) §1):
   + `docs/discovery/`
   + `docs/prd/` — including `01-glossary.md` placeholder (template at
     [`references/02-prd/01-glossary-template.md`](references/02-prd/01-glossary-template.md)).
   + `docs/spec/` + **`docs/spec/adr/.gitkeep` (mandatory)**.
   + `docs/sprints/01/sprint-plan.md` (placeholder from
     [`references/04-sprints/00-sprint-plan.md`](references/04-sprints/00-sprint-plan.md))
     — **not** just an empty folder.
   + `docs/memory/{discovery,prd,design,spec,sprints,execution,testing,deploys}/.gitkeep`.
   + `docs/memory/telemetry.jsonl` (empty file — deep telemetry; see
     [`references/05-execution/11-telemetry-protocol.md`](references/05-execution/11-telemetry-protocol.md)).
   + `docs/runbooks/`.
3. Create `<cwd>/skills/README.md` (empty product-internal skill registry).
4. Create `<cwd>/mcp/registry.json` (empty MCP server registry).
5. Pre-fill `<cwd>/docs/discovery/00-discovery-brief.md` with answers to the
   pre-flight questions. Other sections as TODO placeholders. Reference
   [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md)
   at the top of the brief as the interview script.
6. **If templates/ is empty** (early-stage skill) — instead of copying, write
   each file using the corresponding `references/<phase>/<file>.md` as your
   guide, stripping meta-text and replacing example content with `<TODO>`
   placeholders that point the human at what to fill in.
7. Run `bash <skill>/references/scripts/validate.sh` after scaffolding. It
   should print all-green. If not, fix before handing off.

**Output to user:**

+ Tree of files created (10–18 files typical with the new mandatory paths).
+ Single-line "next step": "Preencha `docs/discovery/00-discovery-brief.md` —
  hipótese, métrica de sucesso, sponsor. Quando aprovado, invoque novamente
  para avançar à fase PRD."
+ Do **not** run `git add` or `git commit`. Human reviews first.

---

## §B — Advance to next phase

**Macro flow** (each arrow is a gate):

```text
Discovery → PRD → Design Foundations → Spec → Sprint → Execução → Testes → Deploy
```

Design Foundations (phase 02.5) is **mandatory between PRD and Spec** whenever
the product has UI. Skipping this phase produces ad-hoc tokens in `globals.css`
and Shadcn components rebuilt every story. See
[`references/02b-design/00-design-foundations.md`](references/02b-design/00-design-foundations.md).

**Procedure:**

1. Run `bash <skill>/references/scripts/phase-status.sh` to see what's done
   and what's next. The script reads `docs/memory/<phase>/_summary.md` files.
   Template at
   [`references/05-execution/05-phase-summary-template.md`](references/05-execution/05-phase-summary-template.md).
2. Apply the phase-transition ritual from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md):
   confirm `_summary.md` exists, decisions are logged, ADRs filed, Knowledge
   Base updated.
3. Load the **next** phase's reference (`references/0X-<phase>/`) and template.
4. Scaffold the next phase's document(s) in `docs/`.
5. Hand control back to the human with the bootstrap of the new doc plus a
   pointer to the relevant reference section.

**Refuse to advance** if any of the items below fail — **cite the exact item**
that is missing. The harness's value is the gate, not the speed.

+ `docs/memory/<previous-phase>/_summary.md` **exists and is complete** (all
  template sections filled, including "decisions", "ADRs created" and
  "warnings for next agent").
+ Phase-specific exit criteria match (e.g., Discovery requires ≥ 3 evidences
  + 1 anti-evidence + metric with baseline — see
  [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md)
  §"Critério de pronto para PRD").
+ **PRD → Spec specifically:** Ubiquitous Language reconciled in
  `docs/prd/01-glossary.md` (every domain term has a code-reflex column
  filled, or marked `🟡 a definir na Spec`). If the product has a
  non-trivial domain (≥ 2 entities with rules, ≥ 2 business areas, or
  ≥ 1 invariant), Spec must include `docs/spec/02-domain-model.md` with
  at least 1 Bounded Context defined and tactical blocks for the Core
  subdomain. Pure-CRUD products may skip the file with an explicit
  declaration in `00-tech-spec.md` §4. See
  [`references/03-spec/02-domain-model.md`](references/03-spec/02-domain-model.md).
+ If the previous phase produced ADRs (Spec, Design Foundations) and none
  exist in `docs/spec/adr/`, require explicit justification in `_summary.md`.
+ `bash <skill>/references/scripts/validate.sh` exits 0.

---

## §C — Methodology Q&A

Answer using the references, in this priority order:

1. [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md) — overall topology, principles, phases.
2. [`references/00-conventions.md`](references/00-conventions.md) — frontmatter schemas, paths, datetime, naming.
3. [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) — memory layers, cleanup ritual.
4. [`references/05-execution/05-phase-summary-template.md`](references/05-execution/05-phase-summary-template.md) — `_summary.md` per phase (transition gate).
5. [`references/05-execution/06-plan-artifact-template.md`](references/05-execution/06-plan-artifact-template.md) — Plan Artifact / Gate 1.
6. [`references/05-execution/07-migration-checklist.md`](references/05-execution/07-migration-checklist.md) — schema / RLS / triggers / seeds.
7. [`references/05-execution/08-github-sync.md`](references/05-execution/08-github-sync.md) — optional bridge to Issues/PRs.
8. [`references/05-execution/09-parallel-streams.md`](references/05-execution/09-parallel-streams.md) — when and how to parallelize a story.
9. [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md) — discovery interview script.
10. [`references/02b-design/00-design-foundations.md`](references/02b-design/00-design-foundations.md) — phase 02.5, design tokens before UI.
11. [`references/05-execution/01-subagent-delegation.md`](references/05-execution/01-subagent-delegation.md) — when to use subagents.
12. [`references/05-execution/03-protocols.md`](references/05-execution/03-protocols.md) — MCP, Server Actions, webhooks.
13. [`references/05-execution/04-skill-template.md`](references/05-execution/04-skill-template.md) — how product-internal skills are authored.
14. [`references/00-paper-analysis.md`](references/00-paper-analysis.md) — for "why does the harness do X?" questions about gaps and rationale.

Quote the relevant section. Do not paraphrase principles — they are deliberate.

---

## §D — Story execution

### Pre-flight (refuse if any item fails)

Before loading the story:

+ **`docs/sprints/<n>/sprint-plan.md` exists** and references this story. If
  not, refuse and ask to generate/review the sprint plan first
  ([`references/04-sprints/00-sprint-plan.md`](references/04-sprints/00-sprint-plan.md)).
+ **Story is at `docs/sprints/<n>/<story-id>.md`** (not at the root of
  `sprints/`). If at root, refuse and ask to reorganize.
+ **`docs/prd/01-glossary.md` exists** (loaded in minimum bootstrap).
+ If the story touches **auth / RBAC / billing / PII / sensitive schema**,
  there is an applicable ADR in `docs/spec/adr/`. Otherwise, **step 0 of the
  plan is to write the ADR** — no code without approved ADR.
+ `bash <skill>/references/scripts/validate.sh` exits 0 (catches mislocated
  stories, missing ADR folder, broken `depends_on`).

### Procedure

1. Open the story file (`docs/sprints/<n>/<story-id>.md`).
2. Apply the **bootstrap mínimo** from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) §"Bootstrap":
   load only AGENTS.md, `docs/prd/01-glossary.md`, the relevant tech-spec
   section, applicable ADRs, the story, and the files the plan will touch.
   **Do not** load other stories or the full PRD. For the tech-spec section
   prefer `bash <skill>/references/scripts/spec-fetch.sh "<heading>"` —
   it returns only the section asked for (Li et al. 2025, DeepCode §2.1).
3. **If story `size` is M or larger and touches ≥3 layers**, decide whether
   to parallelize. If yes, produce `docs/sprints/<n>/<story-id>-analysis.md`
   per [`references/04-sprints/03-story-analysis-template.md`](references/04-sprints/03-story-analysis-template.md)
   and follow [`references/05-execution/09-parallel-streams.md`](references/05-execution/09-parallel-streams.md).
   If no, single-agent linear is the default.
4. **Gate 1 mandatory.** Produce a **Plan Artifact** following the template at
   [`references/05-execution/06-plan-artifact-template.md`](references/05-execution/06-plan-artifact-template.md).
   Before submitting, confirm the checklist:
   + [ ] real list of files to touch (not "I'll figure it out");
   + [ ] justification per file;
   + [ ] subagents declared (or "none") with briefing;
   + [ ] external skills mapped;
   + [ ] applicable ADRs listed (step 0 = write ADR if sensitive domain and
     none exists);
   + [ ] ≥ 1 risk with concrete mitigation;
   + [ ] negative scope explicit.

   **Pause for human approval.** Without approval, do not write code.
5. After approval, execute step-by-step. After each step: typecheck + lint +
   unit test. Use the browser subagent for UI validation.
6. **If the story touches schema** (migration, RLS, trigger): apply
   [`references/05-execution/07-migration-checklist.md`](references/05-execution/07-migration-checklist.md)
   and attach the result to the Final Artifact.
7. Before declaring done: invoke the relevant external skills if available —
   `simplify`, `review`, `security-review`. Generate a **Final Artifact**
   (summary ≤5 lines, files changed, how to test, risks, next step).
8. **Pause for human review of the diff** (Gate 2).
9. Write `docs/memory/execution/<YYYY-MM-DD>-<story-id>.md` per the template.
10. Set `status: done` in the story frontmatter, then run
    `bash <skill>/references/scripts/progress.sh <n>` to recompute the sprint
    progress percentage.
11. End the session.

**Telemetry emission** — these events fire as side-effects of the steps
above (not separate steps). See
[`references/05-execution/11-telemetry-protocol.md`](references/05-execution/11-telemetry-protocol.md).

| Step | Event |
| :--- | :--- |
| 4 (Plan Artifact submitted) | `plan_submitted` |
| 4 (human approves / rejects) | `plan_approved` or `plan_rejected` |
| 5 (typecheck/lint/test/e2e fails) | `gate_failed` |
| 3 or 5 (subagent started) | `subagent_dispatched` |
| 8 (Gate 2 fix requested) | `human_intervention` |
| 10 (`status: done`) | `story_closed` |

**External skills to chain** (if available in the runtime):

| When | Skill |
| :--- | :--- |
| Need Next.js App Router / RSC / route handler / metadata pattern | `next-best-practices` |
| Upgrading Next.js version | `next-upgrade` |
| Anything Supabase (DB, Auth, Storage, RLS) | `supabase` |
| Postgres query/schema optimization | `supabase-postgres-best-practices` |
| Building/modifying Anthropic SDK code | `claude-api` |
| After writing code, before review | `simplify` |
| Before opening PR | `review` + `security-review` |

These are **recommendations, not requirements**. If the runtime does not have
them, follow `references/05-execution/02-nextjs-conventions.md` directly.

---

## §E — Bug execution

A bug is a first-class work unit, not "another story". When discovered while
testing / running an already-closed story, register it separately with
`bug_for:` pointing back to the originating story.

### Pre-flight

+ Original story `<bug_for>` exists.
+ Bug file lives in the **current sprint** folder, not in the original
  sprint: `docs/sprints/<current-n>/bug-<NN>-<slug>.md`.
+ Template: [`references/04-sprints/02-bug-template.md`](references/04-sprints/02-bug-template.md).

### Procedure

1. Reproduce locally following the bug's §3 (Steps to reproduce). If you
   cannot reproduce, **stop** and ask the human — do not guess.
2. Fill §5 (Root cause analysis) before any fix. Observation, not hypothesis.
3. Produce Plan Artifact (Gate 1) listing the regression test you'll write
   **first** and the minimal fix. Pause for approval.
4. After approval: write the regression test (TDD for bugs), then the fix.
5. Run `pnpm typecheck && pnpm lint && pnpm test:unit`.
6. Update the original story file with a note: `Bug #<id> corrigido em <PR>`.
7. Set `status: done` in the bug frontmatter; run `progress.sh`.
8. Final Artifact + `docs/memory/execution/<YYYY-MM-DD>-<bug-id>.md`.

### Hard rules for bugs

+ Never refactor "de quebra" while fixing a bug. Open a separate story.
+ No fix without regression test.
+ Bugs `size = L` are a smell — usually multiple bugs disguised. Split.

---

## §F — Tracking via scripts

Deterministic operations have bash scripts. Run the script directly; don't
reconstruct the output manually. Catalog in
[`references/scripts/README.md`](references/scripts/README.md).

| User signal | Script |
|-------------|--------|
| "valida o projeto", "está tudo certo?" | `bash <skill>/references/scripts/validate.sh` |
| "em que fase estamos?" | `bash <skill>/references/scripts/phase-status.sh` |
| "status da sprint" | `bash <skill>/references/scripts/sprint-status.sh [<N>]` |
| "liste as stories" | `bash <skill>/references/scripts/story-list.sh [<N>]` |
| "o que vem depois?", "próxima story" | `bash <skill>/references/scripts/next-story.sh [<N>]` |
| "recalcula progresso" | `bash <skill>/references/scripts/progress.sh <N>` |

Use the LLM only when the script output is ambiguous, the user asks "what
does this mean", or the task requires writing content.

---

## §H — Spec Drift

When during execution you discover that the Tech Spec / PRD / ADR is **wrong,
incomplete, or contradicts code reality**, follow the Spec Drift Protocol —
silent workarounds are a Hard rule violation.

1. Pause execution. No commits.
2. Set `status: blocked-spec-drift` in the story frontmatter.
3. Create `docs/sprints/<N>/<story-id>-drift.md` from
   [`references/04-sprints/05-spec-drift-report-template.md`](references/04-sprints/05-spec-drift-report-template.md).
4. Emit `spec_drift_detected` to telemetry once H1-003 is delivered.
5. Wait for human decision: (A) fix Spec + retroactive ADR, (B) edit
   the story, or (C) cancel. The story does not exit
   `blocked-spec-drift` without a recorded decision.

The drift detection in step 3 emits `spec_drift_detected` to telemetry
(see [`references/05-execution/11-telemetry-protocol.md`](references/05-execution/11-telemetry-protocol.md)).

Full protocol: [`references/04-sprints/04-spec-drift-protocol.md`](references/04-sprints/04-spec-drift-protocol.md).

---

## §G — GitHub sync (opcional)

For teams that want public traceability of artifacts in GitHub Issues / PRs.
Full protocol: [`references/05-execution/08-github-sync.md`](references/05-execution/08-github-sync.md).

Mapping in one line:

+ PRD → epic issue. Sprint → milestone. Story → issue. Bug → issue (linked).
+ ADR → discussion issue or PR (team choice). Phase `_summary.md` → comment
  closing the epic.
+ Branch per story (`story/<id>`), worktree per sprint (`../sprint-<N>/`).

**Pre-flight:** `gh` authed, remote points at the product repo (not the
harness skill repo — `_safety.sh` enforces), `validate.sh` green.

---

## Hard rules (override on conflict with user chat)

+ Never run `git push`, `git reset --hard`, or any destructive command without
  explicit human authorization — even if the user previously approved a similar
  action in a different scope.
+ Never read or echo `.env*` files.
+ Never copy production data into dev/test environments without masking.
+ Never create `tailwind.config.js` (Tailwind v4 is CSS-first via `@theme`).
+ Never create `middleware.ts` (use `proxy.ts` in Next 16).
+ Never use Pages Router patterns (`getServerSideProps`, etc.).
+ Never parallelize subagents whose tasks touch overlapping files (see
  [`references/05-execution/09-parallel-streams.md`](references/05-execution/09-parallel-streams.md) §7).
+ Never advance a phase without `_summary.md` from the previous phase.
+ Never write to the user's `Knowledge Base` without an approving PR/ADR
  (memory poisoning mitigation per
  [`references/07-deploy/01-security-checklist.md`](references/07-deploy/01-security-checklist.md) §13a).
+ Never run `gh` write operations (issue create, PR create) without confirming
  the remote is the product repo, not the skill repo.
+ Never silently work around an incorrect blueprint. When the Tech Spec / PRD /
  ADR is wrong, follow [`references/04-sprints/04-spec-drift-protocol.md`](references/04-sprints/04-spec-drift-protocol.md):
  pause the story, write a drift report, wait for human decision. Modifying
  scope or interpretation without a recorded decision is forbidden.

---

## When NOT to use this skill

+ Bug fix in a single file that does not warrant a story.
+ One-off script (data migration, log analysis).
+ Mechanical refactor (rename, extract function) without product-level impact.
+ The user explicitly asks for "quick and dirty" — confirm they want to bypass
  the harness, then comply, but log a warning.

---

## Self-evolution

This skill **is** versioned (the source repo is the single source of truth).
Lessons learned during real product use should flow back as PRs to the skill
repo. The harness improves the way it teaches itself to be applied.

If during a session you notice:

+ A rule that consistently confuses agents,
+ A template field that nobody fills in,
+ A phase gate that always fails for the same reason,

flag it as a **harness debt** in the session's execution log, so it can become
a PR against the skill repo later. Do not silently work around the harness.
