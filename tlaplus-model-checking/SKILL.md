---
name: tlaplus-model-checking
description: Configure and run the TLC model checker (exhaustive or simulation), write .cfg model files, and interpret run statistics and outcomes. Use for any model-checking task - running a spec, adding a regression model, choosing INVARIANT vs PROPERTY, reading state counts/diameter, or exporting traces as JSON/DOT. For diagnosing failures see tlaplus-debugging.
user-invocable: true
disable-model-invocation: false
---

# Model Checking with TLC

Workflow: write spec → write `.cfg` → parse with SANY ([[tlaplus-syntax]]) → run TLC → interpret. Failures/traces are owned by [[tlaplus-debugging]]. Book chapters 14 + 18 are canonical (https://lamport.azurewebsites.net/tla/book.html).

## Run TLC

```bash
java -cp dist/tla2tools.jar tlc2.TLC -config MySpec.cfg MySpec.tla
# .cfg defaults to SPEC.cfg if -config omitted
java -jar tla2tools.jar MySpec.tla            # alias for tlc2.TLC
java -cp dist/tla2tools.jar tlc2.REPL         # evaluate TLA+ expressions interactively
```

The `.cfg` pairs with the `.tla` and tells TLC what to check (`SPECIFICATION`/`INIT`+`NEXT`, `CONSTANT`, `INVARIANT`, `PROPERTY`, `CONSTRAINT`, `SYMMETRY`, …). Full key + CLI-flag tables: `references/cfg-and-flags.md`. Minimal example:
```
SPECIFICATION Spec
INVARIANT Inv
```

## Interpreting a successful run (validated: `test-model/pcal/Bakery.tla`)

```
Model checking completed. No error has been found.
  ... fingerprint collision val = 1.9E-14
1183 states generated, 668 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 41.
The average outdegree ... is 1 (... maximum 2 ...).
```
- **states generated** — total successors computed (incl. duplicates).
- **distinct states found** — unique states = real state-space size.
- **states left on queue = 0** — search finished; exhaustive coverage.
- **depth** — longest behavior (steps) explored.
- **fingerprint collision estimate** — P(TLC skipped a state via hash collision); tiny is good. Raise `-fpbits`/`-fpmem` if large.
- **outdegree** — branching factor; high ⇒ state-explosion risk.

## Interpreting a violation (validated: `test-model/DieHard.tla`)

```
Error: Invariant Inv is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate> ... State 7: <FixWater ...> /\ bigBucket = 4
252 states generated, 54 distinct states found, 11 states left on queue.
```
TLC prints the **shortest counterexample** (states from Init) and stops; "left on queue" is nonzero because search halted early. A `*_TTrace_*.tla` spec is generated for trace exploration. Deeper analysis: [[tlaplus-debugging]].

## Lifecycle of a run
Unparsed → parsed (SANY OK) → initial states computed → exploring (diameter/queue/distinct grow; observe via `TLCGet`) → terminal: no violation / invariant violation / liveness violation / deadlock / error / OOM.

## State-explosion mitigations
`CONSTRAINT` to bound ranges; smaller `CONSTANT` sets; `SYMMETRY` with `Permutations(M)` (⚠ unsound with most liveness — [[tlaplus-debugging]]); `-simulate` for sampling; `-workers` for throughput. Scaling: [[tlaplus-performance]].

## Add a regression model
Drop a paired `Foo.tla` + `Foo.cfg` under `test-model/`, drive it from a Java test via `ant test-set` ([[tlaplus-build-workflow]]). `test-model/` specs are examples, not style authority — cross-check `StandardModules`.

## Validation
Given a spec+`.cfg`: predict pass vs. violation, the relevant statistics (distinct states, depth), and — if it should fail — which key in the `.cfg` proves it. Run it and confirm.

## References (local)
- `references/cfg-and-flags.md` — full `.cfg` key + CLI-flag tables
- `tlatools/org.lamport.tlatools/src/tla2sany/StandardModules/TLC.tla` (TLCGet/TLCSet keys)
- `tlatools/org.lamport.tlatools/test-model/DieHard.{tla,cfg}`, `test-model/pcal/Bakery.{tla,cfg}` (examples)
- `tlatools/org.lamport.tlatools/src/tlc2/TLC.java` (entrypoint/flags)
- Book: https://lamport.azurewebsites.net/tla/book.html (ch. 14, 18)
