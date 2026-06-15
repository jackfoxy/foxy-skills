---
name: tlaplus-debugging
description: Diagnose and recover from TLA+ failures - parse/level errors, config (.cfg) errors, TLC runtime errors, safety (invariant) and liveness violations, deadlock, and out-of-memory; analyze counterexample traces. Use for any SANY/TLC failure, opaque error, or trace/counterexample work. Owns the TLC/SANY error-code taxonomy for the pack.
user-invocable: true
disable-model-invocation: false
---

# Debugging TLA+ Failures

Owns the error taxonomy. For running mechanics see [[tlaplus-model-checking]]; for syntax/levels see [[tlaplus-syntax]].

## Start here
1. Get the error **code** (run `tla2sany.SANY -error-codes ...`, or read the `EC_*` name in TLC output).
2. Map the code's **range** to a category — full table in `references/error-codes.md` (1xxx system, 2xxx TLC checking, 3xxx params, 4xxx SANY parser, 5xxx `.cfg`).
3. Apply the symptom→fix below.

## Symptom → cause → fix

**Parse / level error (4000–4002, SANY):** SANY rejects before TLC runs. Causes: syntax typo; module name ≠ filename; level violation (priming in a temporal/constant context; an `INVARIANT` that is really level-2; `Seq(S)` used as an enumerable bound). Fix: re-check [[tlaplus-syntax]] level rules; run `tla2sany.SANY MySpec.tla` alone.

**Config error (5001+, CFG):** mentions the `.cfg`. Causes: missing/duplicate keyword, undeclared constant, `INVARIANT` naming a level-3 formula or `PROPERTY` naming a level-1 predicate, an unassigned `CONSTANT`. Fix: every spec `CONSTANT` must be assigned; invariants are state predicates, properties are temporal.

**Parameter error (3100–3114):** bad CLI flag/value — check `tlc2.TLC -help`.

**Assumption false (2104):** an `ASSUME` is FALSE — constant facts inconsistent with the model values.

**Invariant violated (2110 / 2107):** TLC prints `Error: Invariant X is violated.` then `The behavior up to this point is:` and the shortest counterexample. Read the **last** state — it falsifies the invariant — then walk back to the action that produced the bad value. (Validated: `DieHard` `Inv == bigBucket # 4` → 7-state trace ending `bigBucket = 4`.)

**Temporal/action property violated (2116 / 2112):** liveness failure; trace may end in `Back to state N` (a lasso violating `<>`/`~>`). Usually missing fairness (`WF_`/`SF_`) or an over-strong claim.

**Deadlock (2114):** a reachable state has no successor — genuine bug, or expected termination (add a `Terminating` self-loop disjunct, or run `-deadlock` to disable the check).

**Liveness + symmetry (2279):** `SYMMETRY` is unsound with liveness; TLC refuses/warns. Remove `SYMMETRY` when checking liveness.

**OOM / stack overflow (1001–1005):** state explosion / deep recursion. Mitigate with `CONSTRAINT`, smaller constants, `SYMMETRY` (safety only), `-simulate`; raise heap (`-Xmx`); see [[tlaplus-performance]]. `TOO_MANY_INIT` (1002) ⇒ `Init` admits too many states (often an unbounded `CONSTANT`).

**Opaque `null` / eval failure:** often a partially-specified next state (2109 — a variable has no `'` value in some action) or an unhandled `CASE`. Ensure every action assigns every variable (or `UNCHANGED`).

## Trace tooling
```bash
java -cp dist/tla2tools.jar tlc2.TLC -dump dot graph.gv MySpec.tla          # full state graph (DOT)
java -cp dist/tla2tools.jar tlc2.TLC -dumpTrace json trace.json MySpec.tla  # error trace as JSON
java -cp dist/tla2tools.jar tlc2.TLC -loadTrace json trace.json MySpec.tla  # replay a trace
```
On violation TLC also writes a `*_TTrace_*.tla` trace-exploration spec — open it to step through the counterexample (generated artifact: clean up; never cite as source).

## In-spec debugging aids
- `Print(out, val)` / `PrintT(out)` — emit values during evaluation.
- `Assert(cond, msg)` — fail with a message when `cond` is false.
- `TLCGet("distinct"|"queue"|"diameter"|"level")` + `TLCSet` — observe/count evaluations (e.g. detect runaway lazy re-evaluation). See [[tlaplus-stdlib]].
- `tlc2.REPL` — evaluate a sub-expression in isolation.

## Validation
Given an error snippet: state the code range + category, the single most likely cause, the minimal spec/`.cfg` change, and the command that confirms the fix.

## References (local)
- `references/error-codes.md` — full taxonomy + key codes
- `tlatools/org.lamport.tlatools/src/tlc2/output/EC.java`, `tlc2/output/MP.java`
- `tlatools/org.lamport.tlatools/src/tlc2/TLC.java` (trace/dump options)
- `tlatools/org.lamport.tlatools/test-model/DieHard.{tla,cfg}`, `general/tests/*` (failing examples)
- Book: https://lamport.azurewebsites.net/tla/book.html (ch. 14)
