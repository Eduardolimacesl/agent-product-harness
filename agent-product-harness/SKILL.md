---
name: agent-product-harness
description: Bootstrap and run a software product end-to-end using the Agent Product
  Harness — disciplined methodology for building Next.js 16 + Tailwind v4 + TypeScript
  products with agentic IDEs (Antigravity, Claude Code, Cursor, Codex). Externalizes
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
+ Tailwind v4 + TypeScript stacks.

The methodology rests on five non-negotiable principles:

1. **Document before code.** Each phase produces a versioned artifact in `docs/`.
2. **Minimum viable context.** No agent receives more than it needs.
3. **Artifacts, not prose.** Reviews happen on diffs/screenshots, not chat logs.
4. **Human in the loop by default.** `agent-assisted` mode unless explicitly upgraded.
5. **Sandbox always on.** Allowlisted commands; restricted workspace.

Full architectural rationale: [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md).
Critical analysis vs. the source paper: [`references/00-paper-analysis.md`](references/00-paper-analysis.md).

---

## How to determine what to do when invoked

Read the user's intent and the target project state, then route:

| User signal | Target state | Path |
|-------------|--------------|------|
| "começar produto novo", "scaffold", "init", "bootstrap" | no `docs/` at cwd | §A — Bootstrap |
| "avançar fase", "próxima fase", "estamos em X, vamos para Y" | `docs/` exists with prior phase outputs | §B — Advance phase |
| Question about methodology, why a rule exists, when to delegate | any | §C — Methodology Q&A |
| Story implementation ("implementar story X") | `docs/sprints/<n>/<id>.md` exists | §D — Story execution |

If the signal is ambiguous, **ask one question** to disambiguate. Do not guess.

---

## §A — Bootstrap a new product

**Pre-flight:**

1. Confirm `cwd` is the **target project root** (not the skill folder itself).
   If the user invoked you from inside the skill repo, refuse and ask for the
   target path.
2. Confirm `cwd` does **not** already have `docs/` populated. If it does,
   route to §B instead.

**Discovery questions** (ask the human; do not invent answers):

- What is the product name?
- Who is the sponsor (decision-maker)?
- One sentence: what problem does it solve, and for whom?
- Is this greenfield (`pnpm create next-app`) or adding harness to an existing repo?

**Scaffolding actions** (after answers):

1. Copy `templates/AGENTS.md` to `<cwd>/AGENTS.md`, substituting placeholders.
2. Create `<cwd>/docs/` tree from `templates/docs/` (discovery, prd, spec/adr,
   sprints, memory/{discovery,prd,spec,sprints,execution,deploys}, runbooks).
3. Create `<cwd>/skills/README.md` (empty product-internal skill registry).
4. Create `<cwd>/mcp/registry.json` (empty MCP server registry).
5. Pre-fill `<cwd>/docs/discovery/00-discovery-brief.md` with the answers from
   pre-flight questions. Leave other discovery sections as TODO placeholders.
6. **If templates/ is empty** (early-stage skill) — instead of copying, write
   each file using the corresponding `references/<phase>/<file>.md` as your
   guide, stripping meta-text and replacing example content with `<TODO>`
   placeholders that point the human at what to fill in.

**Output to user:**

- Tree of files created (8–15 files typical).
- Single-line "next step": "Preencha `docs/discovery/00-discovery-brief.md` —
  hipótese, métrica de sucesso, sponsor. Quando aprovado, invoque novamente
  para avançar à fase PRD."
- Do **not** run `git add` or `git commit`. Human reviews first.

---

## §B — Advance to next phase

1. Identify the latest completed phase: read `docs/memory/<phase>/_summary.md`
   files (most recent date wins).
2. Apply the phase-transition ritual from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md):
   confirm `_summary.md` exists, decisions are logged, ADRs filed, Knowledge
   Base updated.
3. Load the **next** phase's reference (`references/0X-<phase>/`) and template.
4. Scaffold the next phase's document(s) in `docs/`.
5. Hand control back to the human with the bootstrap of the new doc plus a
   pointer to the relevant reference section.

**Refuse to advance** if the previous phase's exit criteria are not met. Cite
which item is missing. The harness's value is the gate, not the speed.

---

## §C — Methodology Q&A

Answer using the references, in this priority order:

1. [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md) — overall topology, principles, phases.
2. [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) — memory layers, cleanup ritual.
3. [`references/05-execution/01-subagent-delegation.md`](references/05-execution/01-subagent-delegation.md) — when to use subagents.
4. [`references/05-execution/03-protocols.md`](references/05-execution/03-protocols.md) — MCP, Server Actions, webhooks.
5. [`references/05-execution/04-skill-template.md`](references/05-execution/04-skill-template.md) — how product-internal skills are authored.
6. [`references/00-paper-analysis.md`](references/00-paper-analysis.md) — for "why does the harness do X?" questions about gaps and rationale.

Quote the relevant section. Do not paraphrase principles — they are deliberate.

---

## §D — Story execution

When the user asks you to implement a story:

1. Open the story file (`docs/sprints/<n>/<story-id>.md`).
2. Apply the **bootstrap mínimo** from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) §"Bootstrap":
   load only AGENTS.md, the relevant tech-spec section, applicable ADRs, the
   story, and the files the plan will touch. **Do not** load other stories or
   the full PRD.
3. Produce a **Plan Artifact** (files to touch, steps, subagents needed).
   **Pause for human approval** (Gate 1).
4. After approval, execute step-by-step. After each step: typecheck + lint +
   unit test. Use the browser subagent for UI validation.
5. Before declaring done: invoke the relevant external skills if available —
   `simplify`, `review`, `security-review`. Generate a **Final Artifact**
   (summary ≤5 lines, files changed, how to test, risks, next step).
6. **Pause for human review of the diff** (Gate 2).
7. Write `docs/memory/execution/<YYYY-MM-DD>-<story-id>.md` per the template.
   Encerre a sessão.

**External skills to chain** (if available in the runtime):

| When | Skill |
|------|-------|
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

## Hard rules (override on conflict with user chat)

- Never run `git push`, `git reset --hard`, or any destructive command without
  explicit human authorization — even if the user previously approved a similar
  action in a different scope.
- Never read or echo `.env*` files.
- Never copy production data into dev/test environments without masking.
- Never create `tailwind.config.js` (Tailwind v4 is CSS-first via `@theme`).
- Never create `middleware.ts` (use `proxy.ts` in Next 16).
- Never use Pages Router patterns (`getServerSideProps`, etc.).
- Never paralelize subagents whose tasks touch overlapping files.
- Never advance a phase without `_summary.md` from the previous phase.
- Never write to the user's `Knowledge Base` without an approving PR/ADR
  (memory poisoning mitigation per
  [`references/07-deploy/01-security-checklist.md`](references/07-deploy/01-security-checklist.md) §13a).

---

## When NOT to use this skill

- Bug fix in a single file that does not warrant a story.
- One-off script (data migration, log analysis).
- Refactor mecânico (rename, extract function) without product-level impact.
- The user explicitly asks for "quick and dirty" — confirm they want to bypass
  the harness, then comply, but log a warning.

---

## Self-evolution

This skill **is** versioned (the source repo is the single source of truth).
Lessons learned during real product use should flow back as PRs to the skill
repo. The harness improves the way it teaches itself to be applied.

If during a session you notice:

- A rule that consistently confuses agents,
- A template field that nobody fills in,
- A phase gate that always fails for the same reason,

flag it as a **harness debt** in the session's execution log, so it can become
a PR against the skill repo later. Do not silently work around the harness.
