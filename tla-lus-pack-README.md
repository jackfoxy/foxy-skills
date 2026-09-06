# `tla-lus-*` Skill Pack

Eleven skills for the `%tla-lus` Gall agent — the native, headless TLA+
toolchain for Urbit (`~/gitrepos/tla-lus`). Written 2026-09-06 against R3
(ledger closed, 134 rows, 0 owed).

This pack **replaces** the `tlaplus-*` pack in `/mnt/mars/gitrepos/foxy-skills/`
(symlinked into `~/.claude/skills/`), which is aimed at the Java
`tlaplus/tlaplus` repo. See "Disposition" below.

## Contents

| Skill | Owns |
|---|---|
| `tla-lus-overview` | Orientation, routing, the support/refusal matrix, the doc map |
| `tla-lus-agent` | The wire contract: pokes, request molds, job lifecycle, scries, quotas, dojo recipes |
| `tla-lus-specification` | Expert TLA+ modeling; safety, liveness, fairness, refinement, composition (+ 11 *Specifying Systems* chapters) |
| `tla-lus-syntax` | The accepted grammar, operators, precedence, levels, name resolution |
| `tla-lus-model-checking` | `.cfg`, run modes, limits, coverage, `continue`, statistics |
| `tla-lus-debugging` | Diagnostic codes, failure modes, traces, `%limited` |
| `tla-lus-stdlib` | Standard modules and the `stdops` override registry |
| `tla-lus-internals` | The pure `lib/` pipeline, job kernel, async Clay load, the Gall shell |
| `tla-lus-dev-workflow` | Deploy, tiers 1–3, gates, generators, fuzzing, adding a case |
| `tla-lus-parity` | The pinned Java oracle, goldens, normalization, the ledger |
| `tla-lus-pluscal` | PlusCal authoring; **not available** — plus the enablement checklist |

Each skill is `SKILL.md` + `references/*.md` + `agents/openai.yaml`.
Cross-skill links are sibling-relative (`../../tla-lus-x/...`), so they resolve
both here and under `~/.claude/skills/`.

## Install

```bash
for d in ~/FoxyLabs/tla-lus/skills/tla-lus-*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

## Disposition of the old `tlaplus-*` pack

| Old skill | Action | Replaced by |
|---|---|---|
| `tlaplus-overview` | **delete** | `tla-lus-overview` |
| `tlaplus-syntax` | **delete** | `tla-lus-syntax` |
| `tlaplus-model-checking` | **delete** | `tla-lus-model-checking` |
| `tlaplus-debugging` | **delete** | `tla-lus-debugging` |
| `tlaplus-stdlib` | **delete** | `tla-lus-stdlib` |
| `tlaplus-pluscal` | **delete** | `tla-lus-pluscal` |
| `tlaplus-tools-internals` | **delete** | `tla-lus-internals` |
| `tlaplus-build-workflow` | **delete** | `tla-lus-dev-workflow` (+ the jar build in `tla-lus-parity`) |
| `tlaplus-performance` | **delete** | folded into `tla-lus-model-checking` (limits) and `tla-lus-dev-workflow` (tier 3) |
| `tlaplus-contribution` | **delete** | folded into `tla-lus-parity` (ledger discipline) and `tla-lus-dev-workflow` (close-out) |
| `tlaplus-parser-xml-tooling` | **delete** | `tla-lus-syntax`; the JavaCC/XMLExporter/`sany.xsd` surface has no counterpart (`XMLExporter` survives only as an oracle form, noted in `tla-lus-parity`) |
| `tlaplus-toolbox-eclipse` | **delete** | nothing — no GUI, no Eclipse, zero port surface |

Also superseded: `~/FoxyLabs/tla-lus/skills/specifying-systems/`, whose content
is folded into `tla-lus-specification` (and whose 6 references are the ancestors
of `modeling.md`, `temporal-refinement.md` and `language.md`).

Java knowledge is **not** discarded: the toolchain is still the differential
oracle, so `tla-lus-parity` keeps the pins, the Ant build, every invocation
form, the determinism flags, the dumpers and the normalization rules, and
`tla-lus-pluscal` keeps the `pcal.trans` CLI.

## Provenance

Written from: `~/gitrepos/tla-lus/desk/doc/` (api, architecture, users-guide,
compatibility, parity-manifest, evidence-counts, testing, port-map, tla-bnf),
the desk sources (`app/`, `lib/`, `sur/`, `gen/`, `mar/`), `tools/`, and the
*Specifying Systems* chapter summaries at
`~/FoxyLabs/tla-lus/specifying-systems/`.
