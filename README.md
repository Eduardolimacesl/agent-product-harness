# Agent Product Harness — Skill Repository

This repository is the source of truth for the **`agent-product-harness`** skill
— an Anthropic-format skill that bootstraps and runs software products under a
disciplined methodology designed for agentic IDEs (Antigravity, Claude Code,
Cursor, Codex).

The skill itself lives in [`agent-product-harness/`](./agent-product-harness/).
This README is for **maintainers** of the skill — people improving the harness.
End-users invoke the skill via their runtime; they do not browse this repo.

---

## What's in this repo

```text
.
├── README.md                                  ← this file (maintainer-facing)
└── agent-product-harness/                     ← the distributable skill
    ├── SKILL.md                               ← manifest + entry point
    ├── references/                            ← methodology docs (read on demand)
    │   ├── 00-architecture-and-flow.md
    │   ├── 00-paper-analysis.md
    │   ├── README.md
    │   ├── AGENTS.md
    │   ├── 01-discovery/
    │   ├── 02-prd/
    │   ├── 03-spec/
    │   ├── 04-sprints/
    │   ├── 05-execution/
    │   ├── 06-testing/
    │   └── 07-deploy/
    └── templates/                             ← drop-in scaffolding (WIP)
        └── docs/
```

- **`references/`** — the methodology. The agent reads these to understand
  principles, fill in templates, and answer Q&A. Never copied verbatim into
  user projects.
- **`templates/`** — pre-filled, placeholder-driven files that get copied into
  the user's project during bootstrap. **Currently empty** — see roadmap below.

---

## How the skill is consumed

Anthropic Skills format (open standard). To make the skill available in a
runtime, place the `agent-product-harness/` folder where that runtime looks for
skills:

| Runtime | Skill location |
| :--- | :--- |
| Claude Code (user-level) | `~/.claude/skills/agent-product-harness/` |
| Claude Code (project-level) | `<project>/.claude/skills/agent-product-harness/` |
| Antigravity | analogous skills directory (Anthropic-format compatible) |
| Cursor / Codex | clone repo and reference via project rules pointing at `agent-product-harness/SKILL.md` |

The simplest distribution is a **`git clone`** of this repo, or a symlink from
the runtime's skills directory to `agent-product-harness/`.

---

## Local Installation (Per-Project)

To use this harness in a specific project (local installation), follow these steps:

1. **Clone this repository** to a location of your choice:

   ```bash
   git clone git@github.com:Eduardolimacesl/agent-product-harness.git
   ```

2. **Create the skills directory** in your target project (e.g., for Antigravity):

   ```bash
   mkdir -p .gemini/antigravity/skills
   ```

3. **Create a symbolic link (symlink)** from the skill folder to your project:

   ```bash
   # Replace /path/to/repo with the actual path where you cloned this repo
   ln -s /path/to/repo/agent-product-harness ./.gemini/antigravity/skills/agent-product-harness
   ```

This allows you to make changes to this harness repository and see them reflected immediately in your development project.

---

## How users invoke it

In any compatible runtime, a user types something like:

- *"Quero começar um produto novo seguindo o agent-product-harness"*
- *"Use a skill agent-product-harness para fazer bootstrap aqui"*
- *"Avance a fase do harness — terminamos discovery"*

The runtime matches the request against the `description` field in
[`agent-product-harness/SKILL.md`](./agent-product-harness/SKILL.md) and loads
the skill. From there, the skill's instructions take over.

---

## Roadmap (skill maturity)

Change history per release: see [`CHANGELOG.md`](./CHANGELOG.md).

### v0.1 — Bootstrap-capable from references

- Skill is invocable, can answer methodology Q&A.
- Bootstrap falls back to "write each file using `references/<phase>/` as a
  guide" when `templates/` is empty.

### v0.2 — Fundação: estado estruturado + telemetria

- **CodeMem layer** (`docs/memory/codemap/`) — structural per-module index;
  closes the cross-file dependency gap (Li et al. 2025).
- **Deep telemetry** (`docs/memory/telemetry.jsonl`) — 7 structured event
  types + aggregation report (Ning et al. 2026, §3.5.1).
- **Tech Spec 5-section blueprint** + `spec-fetch.sh` (hierarchical content
  segmentation).
- **Spec Drift Protocol** + `blocked-spec-drift` story status.
- **Smoke Run** + named convergence criterion (correctness convergence).
- Principles P6–P12 promoted into `00-architecture-and-flow.md`.

### v0.3 — Governança e refinamentos

- **Permission tiers** (read-only / sandbox-edit / full-access) — Ning et
  al. 2026, §3.4.3; context-sensitive.
- **Change Contract** — `minor`/`major` PRs ao harness carregam 6 campos
  (componente, modo de falha, melhoria, invariantes, falsificação,
  rollback).
- **Multi-Agent Specification Analysis** (Concept + Algorithm split em
  fase Spec, produtos M+).
- **Evidence Bundle** no Final Artifact (Gate 2) — regiões NÃO testadas
  é campo obrigatório.
- **Approvals Ledger** (`docs/memory/approvals.jsonl`) — HITL como estado
  durável; aprovações com `becomes_rule` alimentam evolução de política.
- **Reference Mining (CodeRAG) opcional** com allowlist de licenças.
- **Modelo mínimo recomendado** declarado em `AGENTS.md §0`.

### v0.4 — Coerência da spec (filosofia Spec-Driven Development) *(current)*

- **Clarify Protocol** — marcador `[NEEDS CLARIFICATION]`; gate
  anti-ambiguidade nas transições PRD → Spec e Spec → Sprint
  (`check-clarifications.sh`). Importado de `/speckit.clarify`.
- **Constitution** (`docs/memory/constitution.md`) — lei de qualidade
  não-negociável do produto, distinta de `AGENTS.md` e dos princípios
  P1–P12; ratificada no gate PRD → Spec. Importado de
  `/speckit.constitution`.
- **Cross-Artifact Analysis** (`check-cross-artifact.sh`) — coerência entre
  Constitution/PRD/Spec/Stories antes da Execução; pega incoerência cedo
  onde o Spec Drift pega tarde. Importado de `/speckit.analyze`.

### v1.0 — Battle-tested

- Used in ≥ 1 real product end-to-end.
- Evolution Agent autônomo (Code-as-Harness §3.5.2) — meta-agente que muta
  o harness a partir da telemetria; só após v0.2/v0.3 acumularem ≥2
  sprints reais de dados.
- Sandbox Agent autônomo em loop execution-error-fix.
- Skills internas (`templates/skills/`) com seeds:
  `server-action-with-zod`, `proxy-security-headers`,
  `cache-component-pattern`.

---

## Improving the harness

This repo is the **single source of truth**. The cycle:

1. Use the skill in a real product.
2. Notice friction (rule that confuses, template field nobody fills, phase
   gate that always fails for the same reason).
3. Open a PR here updating the relevant `references/` or `templates/` file.
   **For `minor` or `major` changes**, fill the
   [Change Contract template](./.github/PULL_REQUEST_TEMPLATE/harness-change.md) —
   diagnose the failure mode, predict the improvement, name the invariants
   to preserve, describe how to falsify, and document rollback. `patch`
   changes (typo, clarification) are exempt.
4. Tag a new version (`v0.X`).
5. Pull the update into the runtime's skills directory (`git pull`).

The §"Self-evolution" section of
[`agent-product-harness/SKILL.md`](./agent-product-harness/SKILL.md) instructs
the agent to **flag** harness debt during sessions so it surfaces here.
Rationale for the Change Contract:
[`references/12-harness-evolution/00-change-contract.md`](./agent-product-harness/references/12-harness-evolution/00-change-contract.md).

---

## Versioning

Semantic-ish versioning at the **skill** level:

- **major** (`v1.0` → `v2.0`) — breaks compatibility with existing bootstrapped
  projects (renamed phases, removed templates). Migration notes required.
- **minor** (`v1.0` → `v1.1`) — adds new templates, references, or skill
  paths without breaking older outputs.
- **patch** (`v1.0.1`) — typo fixes, clarifications, no behavior change.

Pin by tag in CI / runtime config. Do **not** track `main` in production
projects — pin so a `git pull` does not silently change the harness under a
running product.

---

## License & attribution

Methodology builds on Zhou et al. (2026), *"Externalization in LLM Agents: A
Unified Review of Memory, Skills, Protocols and Harness Engineering"*
(arXiv:2604.08224v1). See
[`agent-product-harness/references/00-paper-analysis.md`](./agent-product-harness/references/00-paper-analysis.md)
for the critical mapping between paper and this harness.
