---
name: tla-lus-overview
description: Orientation to %tla-lus, the native headless TLA+ toolchain that runs as an Urbit Gall agent (no Java, no GUI) - what it can do, what it refuses by name, where its documentation lives, and which sibling tla-lus-* skill owns a given task. Use at the start of any TLA+ work on this system, when deciding whether a capability exists, or when routing between authoring, driving the agent, checking, debugging, or porting work.
user-invocable: true
disable-model-invocation: false
---

# `%tla-lus`: Overview & Routing

`%tla-lus` is a **native, headless TLA+ toolchain for Urbit**: SANY-compatible
lexing/parsing/semantic analysis/level checking, and TLC-compatible model
checking, liveness, simulation and DFID — as a Gall agent. No GUI, no Java at
runtime, no filesystem, no console. Every heavy computation is a **pure,
bounded, resumable** function of a noun; the agent shell only decides when to
run a slice and what to publish.

Repo layout (paths below are repo-relative):

- `desk/` — the Urbit desk: `app/tla-lus.hoon`, `lib/*.hoon` (the pure
  pipeline), `sur/tla-lus.hoon` (every wire mold), `mar/`, `gen/tla-lus/`,
  `tests/`, `test-data/`, `doc/`.
- `tools/` — Python generators, the Java oracle dumpers, and the gates.
- `desk/doc/` — the authoritative documentation set (see the map below).

## The one-paragraph mental model

You do not run a command. You **poke a typed request** (`%translate`,
`%analyze`, or `%check`) over a **source bundle** (`%inline` nouns or `%clay`
files) with **limits**, under a caller-chosen `req-id`. The agent validates it
at submit, plans a stage list, and runs it as a chain of Behn-scheduled bounded
slices, publishing ordered `%stage`/`%progress`/`%diagnostic` events and
exactly one terminal `%result`. You read results by scry or subscription.
Nothing degrades silently: anything the pipeline cannot do faithfully is a
**typed rejection naming what is missing**.

## Route the task

| Task | Skill |
|---|---|
| Poke/watch/scry the agent, request molds, limits, quotas, job lifecycle, dojo recipes | `tla-lus-agent` |
| Decide the abstraction, variables, atomicity, safety/liveness/fairness, refinement, composition | `tla-lus-specification` |
| Write or read TLA+ that this parser accepts; operators, precedence, levels | `tla-lus-syntax` |
| Configure and run a `%check`; `.cfg` keywords, modes, coverage, statistics | `tla-lus-model-checking` |
| A rejection, a diagnostic code, a violation, a trace, a `%limited` | `tla-lus-debugging` |
| `Naturals`/`Sequences`/`FiniteSets`/`Bags`/`TLC`/`TLCExt`/`Randomization` operators | `tla-lus-stdlib` |
| How the pipeline is built; adding or changing a `lib/` stage | `tla-lus-internals` |
| Deploy the desk, run the suites, regenerate goldens, the gates | `tla-lus-dev-workflow` |
| The parity ledger, approved differences, the Java oracle and its pins | `tla-lus-parity` |
| PlusCal (**not available** — see the skill for what that means) | `tla-lus-pluscal` |

Read [references/support-matrix.md](references/support-matrix.md) before
promising a capability, and [references/doc-map.md](references/doc-map.md) to
find the authoritative document for a claim.

## Rules that hold across every task

1. **The wire is the contract.** Every public noun lives in
   `desk/sur/tla-lus.hoon` and is tabulated with a real value in
   `desk/doc/api.md`. Do not invent fields.
2. **Refusals are typed and named.** `unsupported: …` messages are checked in
   **both directions** by the release gate: every message in the desk appears
   in `desk/doc/compatibility.md`'s table, and every message that table lists
   exists in the desk. If you add a refusal, document it.
3. **`%violated` is never collapsed into `%failed`.** A counterexample is a
   *successful* run that found something; `%failed` means the engine could not
   answer.
4. **A green TLC run is not a proof.** It is evidence for the configured finite
   model only — the same caveat the Java tool carries.
5. **Parity claims are measured, not asserted.** A behaviour is at parity only
   if a differential comparator agrees with the pinned Java oracle on that
   row's projection. See `tla-lus-parity`.
6. **The pipeline is pure; the agent is thin.** No `lib/` or `sur/` file reads
   Clay — the scaffold gate enforces it. Sources arrive asynchronously through
   the `%modules` stage.

## Current status (2026-09-06, R3 complete)

- Parity ledger: **134 rows, 0 owed — closed 2026-09-05 by R3.0d**.
  `tools/release-gate.sh` PASSES every clause; `tools/r3-acceptance.py
  --suite-log` prints **R3 ACCEPTED** on 5/5 (2179 suite arms, 0 failed).
- Oracle pin: `tlaplus@4ba7d8811`; fixtures `tlaplus-Examples@47b0e2cc`,
  `vscode-tlaplus@acc095d6`.
- `api-version` 1, agent state `%0`, `sys.kelvin = [%zuse 411 410 409 408]`.
  Nothing has been released, so no migration exists anywhere in the project.
- Live: `%analyze` (syntax + semantic + level + lint), `%check` (exhaustive,
  simulate, `-generate`, DFID), liveness with fairness, `VIEW`, `ALIAS`,
  symmetry, coverage, `-continue`, `-seed`, postconditions, `promote`
  (`-messagesAsErrors`), Clay sources **and** Clay write-back.
- Not available: **PlusCal** (`%translate` and `check-opts.translate` are typed
  rejections), and the narrow combinations listed in the support matrix.
