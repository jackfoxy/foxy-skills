# Modes, Limits, and Reading the Numbers

## The four run modes

```hoon
+$  check-mode
  $%  [%exhaustive deadlock=? seed=@ud]
      [%simulate seed=@ud num=@ud depth=@ud generate=?]
      [%dfid depth=@ud deadlock=?]
  ==
```

### `%exhaustive` — breadth-first, the default

Explores the whole reachable state space, checking invariants at each state and
optionally deadlock. Shortest counterexamples by construction. This is the only
mode that supports `coverage` and `continue`, and the only one that produces a
full `run-stats`.

`deadlock=&` reports a state with no successors as `[%violated [%deadlock ~]]`.
Turn it off when the spec legitimately terminates — otherwise "done" reads as
"broken".

### `%simulate` — seeded random behaviours

`num` behaviours of at most `depth` transitions from a `seed`. Reproducible:
same seed and limits, same result. Use it when the state space is too large to
enumerate, and to find *long* counterexamples exhaustive search would take too
long to reach.

`generate=&` is tlc2's `-generate`: successor picking becomes **probabilistic**,
one successor per step instead of all of them. It is observable **only below
the action-decomposition boundary** — `Next == A \/ B` and `Next == \E n \in
1..5 : …` are byte-identical either way, because `Tool.getActions` splits the
disjunction and enumerates the quantifier before the successor search runs. A
`CASE` in probabilistic position is a typed `%failed`; **the pin aborts there
too** (`Tool.java:1323`).

Use **wide** seeds. Measured: 1, 2, 3, 7, 8 and 42 all give the same first
draw, because `Random.setSeed` scrambles multiplicatively and the first
`nextDouble` barely moves. The corpus uses 12345 and 987654321.

### `%dfid` — depth-first iterative deepening

tlc2's `-dfid num`. `depth` is the deepest **level** a sweep may reach; below 2
no sweep runs, so 0 and 1 explore the initial states and stop. A run that ends
**at** the bound is `[%limited %depth …]` and never `%ok` — tlc2 prints no
completion line there either.

DFID does **not** do liveness and refuses a genuine temporal `PROPERTY`
verbatim (upstream issue 548); a `[]P` box-state runs, because it is an
invariant. `continue` is refused with DFID. It is the only engine that
currently produces `[%violated [%action …]]` (an implied-action violation, EC
2112).

Its counterexample trace is **not** compared to the pin — see
`tla-lus-parity`.

### `%analyze` — no checking at all

`flags=[syntax semantic level lint]`. Use it as the first step on any new
module: it is fast, it needs no config, and a clean `%analyze` removes an
entire class of confusing `%check` failures.

## `seed` is not simulation-only

`RandomEnumerableValues.setSeed` runs for the BFS too, so `seed` is what
`TLC!RandomElement` and the `Randomization` operators draw from **while the
exhaustive search expands states**. The generator is reseeded to
`fingerprint ^ seed` once per **predecessor state** — not once per evaluation —
so two draws in one action give two values, exactly as at the pin. A spec with
no draws is unaffected. Default is `0`; comparing against the Java tool also
needs `-fp 0`.

## Limits

```hoon
+$  limits  [max-source max-modules max-states max-depth max-time max-artifact max-set-size]
```

`default-limits:job-lib` = `[1.000.000 64 100.000 1.000 ~m10 1.000.000
1.000.000]`.

- Each bound is enforced **where the resource grows** — `max-states`/`max-depth`
  per state registered, `max-time` per **slice**, `max-artifact` at artifact
  store.
- Hitting one is `[%limited kind stats]` with the statistics gathered so far,
  never a crash and never a wrong answer.
- `max-set-size` is tlc2's `-maxSetSize` default. Note the divergence: tlc2
  raises EC 2172 (an **error**) when a value exceeds it; this port bounds the
  same resources through `limits` and returns a typed `%limited` naming the
  resource.
- Separately, a persisted continuation over 16MB ends the run `[%limited %noun
  …]`.
- `default-budget:job-lib` (256 work units per Gall event) is **engine
  configuration**, not a limit: it controls slice size, not what the run may
  do.

## Reading `run-stats`

```hoon
+$  run-stats  [generated=@ud distinct=@ud queued=@ud depth=@ud outdeg=out-degree]
+$  out-degree  [min=@ud mean=@ud p95=@ud max=@ud]
```

| Mode | `generated` | `distinct` | `queued` | `depth` | `outdeg` |
|---|---|---|---|---|---|
| `%exhaustive` | states generated | distinct states found | left on queue | complete-graph depth | one sample per **dequeued** state |
| `%simulate` | **transitions taken** | 0 | 0 | deepest transition index | — |
| `%dfid` | tlc2's number | tlc2's number | 0 | 0 | 0 |

Simulation keeps no frontier, so `distinct`/`queued` are meaningless there.
DFID's summary line carries no queue term, no complete-graph depth line and no
average out-degree, so the port reports **nothing** rather than a number the
oracle never produced — its per-level lines are in the `%report` artifact.

`outdeg.min` is pulled to 0 by any sink state. A `mean` near 1 with a large
`max` usually means one action fans out and the rest are deterministic — often
where the state explosion is.

Judging a run:

- `queued > 0` with `%limited` — the search was cut off; the numbers are a
  lower bound on the real state space.
- `distinct` ≈ `generated` — little revisiting; the graph is close to a tree.
- `depth` at `max-depth` — you bounded it, not the spec.

## `continue` — every counterexample, not just the first

`continue=&` (tlc2's `-continue`) keeps the exhaustive search running past the
first invariant violation. The result is `%ok`/`%limited` plus a
**`%violations` artifact** carrying every counterexample in discovery order.
The statistics differ from a stopping run on the same spec (continuing explores
the whole graph), so do not compare them.

## `coverage`

`coverage=&` adds the per-action / per-constraint coverage block to `%report`.
Exhaustive mode only, no `SPECIFICATION`, no temporal `PROPERTY` — each refused
by name at submit. It is a **boolean**, not tlc2's interval: the interval gates
only periodic reporting and the end-of-run block is byte-identical for
`-coverage 0`, `1` and `2`.

Reproduced: the `INIT` line, the per-action `NEXT` lines (shared cost models
collapsed, sorted by span, with `1:1` / `1:N` declaration labels), the
count-less `INVARIANT` lines, and the `ACTION_CONSTRAINT`/`CONSTRAINT` lines.
**Declared absent**: the per-`VARIABLE` HyperLogLog estimate and the per-node
sub-expression lines — and a run that **prints a counterexample** reports no
block at all, because tlc2's counters there include its trace re-solve.

Read it to find dead actions: an action with count `0` never fired, which is
usually a guard that is never enabled and almost always a bug in the model.
