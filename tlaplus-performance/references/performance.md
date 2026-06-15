# Performance Case Studies

Primary path: `general/performance/`.

These are snapshots: authoritative for the cases they contain, not necessarily current with upstream projects. Credit original authors when referencing.

## Case Study Map

- `PaxosMadeSimple/`
- `PaxosCommit/`
- `Bookkeeper/`
- `SwarmKit/`
- `Ghostferry/`
- `MongoRepl/`
- `EWD840/`
- `Grid5k/`
- `Bloemen/`

## Measurement Scripts

- `general/performance/measure.sh`
- `general/performance/measureFPSet.sh`
- `general/performance/csv.sh`
- `general/performance/stats.tla`
- `general/performance/measure.tla`

Record:

- command and working directory
- JDK and TLC version/commit
- `.tla` and `.cfg`
- constants and constraints
- worker count
- heap/JVM flags
- elapsed time and memory
- generated/distinct/queue/diameter
- coverage/cost hotspots
- liveness enabled or disabled
- symmetry/view/constraint use

## State Explosion Mitigation

### Constraints

```tla
Constraint == x < MaxVal /\ Len(queue) < MaxQueue
```

```tla
CONSTRAINT Constraint
CONSTANTS MaxVal = 5
          MaxQueue = 3
```

`CONSTRAINT` prunes states. It is not a checked violation like `INVARIANT`; it changes the explored model.

### Symmetry Reduction

```tla
Perms == Permutations(Proc)
```

```tla
SYMMETRY Perms
```

Use symmetry only when the model is actually symmetric under the permutation set. Be careful with liveness; TLC can warn that symmetry and liveness are unsupported together.

### Workers

```bash
java -cp dist/tla2tools.jar tlc2.TLC -workers 4 -config M.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -workers auto -config M.cfg Spec.tla
```

Multiple workers parallelize exploration. Diameter can vary with multiple workers on some models.

### Simulation

```bash
java -cp dist/tla2tools.jar tlc2.TLC -simulate -depth 500 -config M.cfg Spec.tla
```

Simulation is bug-finding, not exhaustive proof. Use when exhaustive checking is too large.

### View-Based Reduction

```tla
View == <<x, y>>
```

```tla
VIEW View
```

Use `VIEW` to abstract auxiliary variables when states with the same view are equivalent for the property being checked.

## Spec-Level Profiling

```tla
ExprWithCount ==
  IF TLCSet(1, TLCGet(1) + 1) THEN RealExpr ELSE 42

Progress ==
  IF TLCGet("distinct") % 1000 = 0
  THEN PrintT(<<"states", TLCGet("distinct"), "queue", TLCGet("queue")>>)
  ELSE TRUE
```

Also use `-coverage 1` to find expression hotspots and allocation costs.

## JVM and Fingerprint Tuning

```bash
java -Xmx16g -cp dist/tla2tools.jar tlc2.TLC -workers 8 -config M.cfg Spec.tla
java -Xmx16g -cp dist/tla2tools.jar tlc2.TLC -fp 1 -config M.cfg Spec.tla
```

Use JVM tuning after confirming the model is intentionally large and finite.

## Workflow Checklist

1. Start with a small finite constants model.
2. Verify correctness on the small model.
3. Measure generated/distinct/diameter/time/memory.
4. Identify whether growth is expected, unbounded, or accidental.
5. Tune constants, constraints, symmetry, view, workers, and heap.
6. Use simulation for large bug-finding when exhaustive checking is infeasible.
7. Document before/after measurements and semantic impact.
8. Compare only against case-appropriate baselines.

## Perf CI

`.github/workflows/perf.yml` compiles TLA+ tools under JDK 11 and runs performance-sensitive jobs. Use it as a CI surface reference; inspect the workflow for exact commands and cases before claiming parity.

Run local commands from `$tla-plus-build-workflow` first, then use the perf job for regression confidence when needed.
