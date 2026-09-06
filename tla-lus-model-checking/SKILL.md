---
name: tla-lus-model-checking
description: Configure and run %check jobs on the %tla-lus agent - write the .cfg, choose exhaustive/simulate/dfid mode, use CONSTRAINT/SYMMETRY/VIEW/ALIAS/POSTCONDITION, set limits, enable coverage or continue, and interpret run-stats and verdicts. Use for any model-checking task on this engine. For diagnosing a failure or reading a counterexample see tla-lus-debugging.
user-invocable: true
disable-model-invocation: false
---

# Model Checking with `%tla-lus`

The engine is TLC-compatible: same semantics, same statistics, same report
text, same error codes — but driven by a typed request instead of a CLI, and
bounded by `limits` instead of by the machine.

- `.cfg` keywords, `CONSTANT` forms, config validation →
  [references/cfg-reference.md](references/cfg-reference.md)
- Modes, seeds, limits, statistics, coverage, `continue` →
  [references/modes-and-statistics.md](references/modes-and-statistics.md)
- Building and submitting the request → `tla-lus-agent`
- A rejection, a diagnostic, a trace → `tla-lus-debugging`

## The workflow

1. **`%analyze` first.** `flags=[& & & &]`. Fast, needs no config, and clears
   an entire class of confusing check failures. `syntax` must be `&`.
2. **Write the smallest `.cfg` that asks your question.** `INIT`/`NEXT` rather
   than `SPECIFICATION` unless you need fairness conjuncts.
3. **Check `TypeOK` alone, first.** List it as the first `INVARIANT` —
   invariants are checked in declaration order and the first failure is the one
   reported.
4. **Run a tiny model.** Two or three elements per constant set. If it is not
   `%ok` in seconds, the model is too big for a first run.
5. **Deliberately check something false.** A model that cannot report a
   violation is not evidence of anything. Break the invariant, confirm
   `%violated`, restore.
6. **Enlarge, or add a `CONSTRAINT`, or simulate.** In that order.
7. **Report the bounds with the verdict.** `%ok` at `N = 3` is not `%ok`.

## Choosing a mode

| Situation | Mode |
|---|---|
| Default; you want the shortest counterexample and full statistics | `[%exhaustive deadlock=& seed=0]` |
| State space too large to enumerate; you want *long* behaviours | `[%simulate seed num depth generate=|]` |
| Nondeterminism below a conjunction, and you want tlc2's `-generate` walk | `[%simulate seed num depth generate=&]` |
| Depth-bounded exploration, tlc2's `-dfid` | `[%dfid depth deadlock=?]` — no liveness, no `continue` |

Only `%exhaustive` supports `coverage` and `continue`; only `%simulate`
supports `difftrace`. Each mismatch is refused **at submit**, by name.

## Verdicts

| Result | What to do with it |
|---|---|
| `[%ok stats]` | report the bounds alongside it |
| `[%violated violation stats]` | read the `%trace` artifact — this is a **successful** run |
| `[%limited kind stats]` | the numbers are a lower bound; shrink the model or raise the one bound named |
| `[%failed reason]` | the engine could not answer; `reason` names why (often a typed refusal) |
| `[%cancelled ~]` | someone cancelled it |

`violation.initial=&` means the **initial-state computation** found it (tlc2's
EC 2107/2108) — there is no behaviour and no state-graph statistics, so the
`trace` you hold is a single offending state, not a counterexample.

## Things that change what "checked" means

State these when you report a result:

- **`CONSTRAINT` / `ACTION_CONSTRAINT`** prune the search. `%ok` becomes "no
  violation within the constraint".
- **`SYMMETRY`** collapses the graph by a permutation group. Unsound with
  liveness in general.
- **`VIEW`** changes state identity — two distinct states can become one.
  Refused in combination with a temporal `PROPERTY` (the liveness graph is not
  view-keyed).
- **`ALIAS`** changes only what a trace *renders*. Refused with a temporal
  `PROPERTY` and in simulation.
- **`max-states` / `max-depth`** — `%limited` is not `%ok`.
- **Simulation** samples; it never proves absence.

## `POSTCONDITION` and `postconditions`

The `.cfg` keyword and the request field both feed tlc2's one
`POST_CONDITIONS` list: operators evaluated **after** state-space exploration.
Request-supplied ones run *in addition to* and *after* the config's. A
`module` naming somewhere other than where the operator is defined is a typed
rejection — the port resolves definitions by bare name, so honouring it would
silently run a different operator.

`TLCExt!CounterExample` in a postcondition is live, which is how the upstream
`Github1389Counting`-style specs run here.
