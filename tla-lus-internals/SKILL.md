---
name: tla-lus-internals
description: Understand and modify the %tla-lus implementation - the pure lib/ stage stack from source/lexer/syntax through semantic/config/node-eval to check/temporal/tableau/liveness, the resumable job kernel, the async Clay source load, quotas and retention, and the thin Gall shell. Use when changing engine behavior, adding a stage, tracing how a spec is processed, or reasoning about purity and resumability. For Java-to-Hoon traceability see desk/doc/port-map.md and tla-lus-parity.
user-invocable: true
disable-model-invocation: false
---

# `%tla-lus` Internals

Two halves, and the split is the design:

- a **pure pipeline** (`desk/lib/`) — a stack of libraries with **no Arvo
  effects**, each a port of a Java stage validated against it;
- a **thin Gall shell** (`desk/app/tla-lus.hoon`) that schedules, persists,
  authorizes and publishes.

Every heavy computation is a pure function of a noun. The shell only decides
*when* to run a bounded slice and *what* to do with its output.

- The `lib/` stack, stage by stage, and the liveness engine →
  [references/pipeline.md](references/pipeline.md)
- The job kernel, limits vs budgets vs quotas, async Clay load, the agent →
  [references/job-kernel.md](references/job-kernel.md)
- Java class inventory and per-unit ownership → `desk/doc/port-map.md`
- Why a behaviour differs from Java → `tla-lus-parity`

## The four invariants to preserve

1. **`+step:job` is a pure function of the job noun.** Pausing and resuming
   cannot change the output (`test-pause-resume-identical`), and a job
   persisted across a restart resumes to the identical result. Any change that
   makes a stage depend on the event it runs in breaks the project's central
   property.
2. **No library reads Clay.** The scaffold gate checks that `desk/lib` and
   `desk/sur` contain no scry. Sources arrive by the kernel *naming* files and
   the agent delivering bytes (`%modules` → `%await` → `%writ` → `+deliver`).
3. **Nothing degrades silently.** Anything the pipeline cannot do faithfully is
   a typed rejection **naming what is missing** — at submit where possible, at
   `%config` where not. The release gate checks every `unsupported:` message in
   both directions against `compatibility.md`.
4. **State identity is the FP64 orbit representative**, never rendered text.

## Where things live

| Concern | File |
|---|---|
| Positions, UTF-8, `SimpleCharStream` | `lib/source.hoon` |
| Tokens | `lib/lexer.hoon` |
| CST + parser | `lib/ast.hoon`, `lib/syntax.hoon` |
| `EXTENDS`/`INSTANCE`, std modules, parse cache | `lib/modules.hoon`, `lib/stdmods.hoon` |
| The only constructor of a `source-ref` | `lib/source-path.hoon` |
| Names, arities, levels, substitution | `lib/semantic.hoon` |
| `.cfg` parse + config-vs-graph validation | `lib/config.hoon` |
| Values, equality, order, rendering, FP64 bytes | `lib/value.hoon` |
| Override registry `[module operator arity]` | `lib/stdops.hoon` |
| Semantic-node evaluator, action solver | `lib/node-eval.hoon` |
| Fingerprints, FPSet, symmetry orbits | `lib/fingerprint.hoon` |
| Safety BFS, simulation, report rendering | `lib/check.hoon`, `lib/crc.hoon` |
| Temporal normalization (`oos`) | `lib/temporal.hoon` |
| Particle tableau | `lib/tableau.hoon` |
| Product, SCC, verdict, lasso | `lib/liveness.hoon` |
| Stage engine, continuations, limits, quotas | `lib/job.hoon` |
| MP messages, diagnostic ordering | `lib/diagnostics.hoon` |
| `java.util.Random` | `lib/rng.hoon` |

## Changing something safely

1. Find the row in `desk/doc/parity-manifest.md` that owns the behaviour, and
   read its rationale — it usually explains why the current shape is what it
   is.
2. Read the pin's Java before changing the Hoon. Most of this port's expensive
   mistakes were assumptions about tlc2 that measurement contradicted.
3. Change the library, not the agent, unless the change is genuinely about
   scheduling, authorization, persistence, or publication.
4. Keep the continuation jammable and the stage boundary resumable. If a change
   makes pause/resume non-identical, it is wrong.
5. Regenerate and run tier 1; add or update the differential case; update the
   ledger and, for any deviation, `compatibility.md`. See
   `tla-lus-dev-workflow`.
