# TLA+ Failure Modes

Use `src/tlc2/output/EC.java` for codes and `src/tlc2/output/MP.java` for exact user-facing text.

## Error Code Taxonomy

| Range / code | Category |
|---|---|
| `1000..1005` | system errors, OOM, stack overflow |
| `2100..2405` | TLC runtime, violations, liveness, override errors |
| `3000..3114`, `CHECK_*` | check/parameter/CLI errors |
| `4000..4002`, `SANY_*` | SANY parser checks |
| `5001..5006`, `CFG_*` | `.cfg` parser errors |
| `TLC_DEADLOCK_REACHED` | deadlock |
| `VIOLATION_SAFETY` | invariant/safety violation |
| `VIOLATION_LIVENESS` | temporal/liveness violation |

## SANY Errors

SANY fails before TLC starts. Isolate with:

```bash
java -cp dist/tla2tools.jar tla2sany.SANY -error-codes Module.tla
```

Common causes:

- module name does not match filename
- malformed operator or missing final `====`
- undefined operator or missing `EXTENDS` target
- circular definition without `RECURSIVE`
- level mismatch, such as primed variable where only constant/state expression is legal

SANY resolves `EXTENDS` through the module directory and classpath; StandardModules are bundled in `tla2tools.jar`.

## CFG Errors

Examples:

- `CFG_ERROR_READING_FILE`: file missing or unreadable
- `CFG_MISSING_ID`: expected identifier after keyword
- `CFG_TWICE_KEYWORD`: repeated keyword, such as two `SPECIFICATION` lines
- `CFG_EXPECT_ID`, `CFG_EXPECTED_SYMBOL`: malformed value or punctuation

Fix spelling and keyword uniqueness first. Keywords are case-sensitive.

## TLC Violations

### Invariant Violated

`Invariant ... is violated` means a state-level safety predicate failed. Read the trace from state 1 through the final state; the last state is the first shown violating state unless the message says the initial state violated it.

### Deadlock

`Deadlock reached` means no `Next` action is enabled. Check whether this is a real terminal state, an over-tight `CONSTRAINT`, missing `UNCHANGED`, or too-small constants. Suppress only if intentional.

### Action Property Violated

An action property failure means a step violated the expected transition predicate. Inspect the pair of adjacent states around the failure.

### Temporal/Liveness Violated

`Temporal property ... was violated` or `Temporal properties were violated` means a liveness property failed.

- A lasso trace points back to an earlier state and shows an infinite cycle.
- A stuttering trace means the behavior can remain forever in a state.
- Deadlock can imply a liveness failure, but it has a different category; inspect the exact code/message.
- Remove `SYMMETRY` while checking liveness if TLC reports unsupported liveness/symmetry interaction.

## State Not Completely Specified

All variables in `VARIABLES` must be assigned in `Init`; `Next` must either assign primed values or mark variables `UNCHANGED`.

## System Errors

- OOM: reduce state space, increase heap (`java -Xmx...` before `-cp`), constrain constants, or use simulation.
- Liveness OOM: liveness graph is too large; simplify temporal obligations or reduce state space.
- Stack overflow: inspect recursive operators or very deep expression expansion.
- JDK/build errors: verify Java, Ant, Maven/Tycho, and Toolbox version constraints.

## Override Mismatch

Override mismatch errors around `TLC_MODULE_VALUE_JAVA_METHOD_OVERRIDE_*` usually mean the Java method in `src/tlc2/module/*.java` does not match the TLA+ operator in `StandardModules/*.tla`.

Check:

- module/class correspondence
- Java method name and arity
- exact operator identifier
- infix registration through `TLARegistry` where applicable

Use `$tla-plus-stdlib` for the full override workflow.

## Spec Debugging Operators

```tla
ASSUME Assert(N > 0, "N must be positive")
TypeOK == Assert(x \in Nat, "x not in Nat")
TracePrint == PrintT(<<"state", x, y>>)
```

Use `TLCGet`/`TLCSet` to count expression evaluation or inspect progress:

```tla
TLCGet("generated")
TLCGet("distinct")
TLCGet("queue")
TLCGet("diameter")
```

## Opaque Null/Internal Errors

For `GENERAL`, `TLC_BUG`, or unhelpful `null` messages:

1. Reduce the spec and config.
2. Run SANY separately.
3. Run TLC with debug output if available.
4. Check for unbounded constructs such as `Seq(S)`, unsupported `CHOOSE`, or Java override exceptions.
5. Inspect `MP.java`, `EC.java`, and the stack trace.

## Non-Enumerable Sets

TLC cannot enumerate infinite or very large sets as quantifier bounds. Common trigger:

```tla
\E s \in Seq(S) : ...
```

Fix by using a finite model-checking wrapper or bounded equivalent, for example `BoundedSeq` from CommunityModules or a local finite definition.

## Trace Analysis

```bash
java -cp dist/tla2tools.jar tlc2.TLC -dumpTrace json trace.json -config M.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -loadTrace json trace.json -config M.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -dump dot graph.gv -config M.cfg Spec.tla
```

State traces list variable values by state number. For liveness, look for lasso/back-to-state or stuttering annotations.

## Build and Tooling Failures

- Parser generated-code drift: edit `javacc/tla+.jj`, regenerate, and run parser corpus tests.
- Toolbox build failure: verify JDK, Maven/Tycho, platform, and `xvfb-run` setup.
- Ant/Eclipse phantom errors: refresh the Eclipse project after CLI Ant runs.
