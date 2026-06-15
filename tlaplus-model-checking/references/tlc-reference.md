# TLC Reference

Use this for concrete TLC command/config reminders. Prefer `USE.md`, `general/docs/current-tools.md`, `docs/*.md`, and `src/tlc2/TLC.java` for source authority.

## Basic Invocation

```bash
java -cp dist/tla2tools.jar tlc2.TLC -config Model.cfg Spec.tla
java -jar dist/tla2tools.jar -config Model.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -workers 4 -config Model.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -simulate -depth 100 -config Model.cfg Spec.tla
```

TLC maintains global static state and cannot be run twice in one JVM process without reloading classes.

## Config File Syntax

```tla
SPECIFICATION Spec

\* Alternative to SPECIFICATION:
INIT Init
NEXT Next

CONSTANTS
  N = 3
  C <- CConf

INVARIANT TypeOK
INVARIANT Invariant

PROPERTY LivenessProp

CONSTRAINT StateConstraint
SYMMETRY Symmetry
VIEW ViewOp
ALIAS AliasOp
POSTCONDITION PostCond
_POSSIBLE PropA PropB
```

`INVARIANT` names a state predicate. `PROPERTY` names a temporal formula; a bare state predicate under `PROPERTY` is checked only initially.

## CLI Options

| Option | Effect |
|---|---|
| `-config <file>` | model config file; default is `<spec>.cfg` |
| `-workers <n>` | worker threads |
| `-depth <n>` | maximum trace depth for BFS/simulation |
| `-simulate` | random simulation, not exhaustive checking |
| `-coverage <n>` | print coverage every N minutes |
| `-checkpoint <n>` | checkpoint every N minutes |
| `-dump dot <file>` | dump state graph as DOT |
| `-dumpTrace json <file>` | dump error trace as JSON |
| `-loadTrace json <file>` | load/validate JSON trace |
| `-dfid <n>` | depth-first iterative deepening |
| `-fp <n>` | fingerprint set size |
| `-seed <n>` | random seed for simulation |
| `-nowarning` | suppress warnings |
| `-terse` | suppress state output on violations |
| `-cleanup` | delete checkpoint files after run |

## Output Stats

- `generated` / `States found`: total states generated, including revisits.
- `distinct` / `Distinct states`: unique states reached.
- `queue`: states waiting to be explored.
- `diameter`: longest discovered behavior depth; may vary with multiple workers.
- Fingerprint collision probability estimates indicate the chance that distinct states were missed due to hash collision.

## TLC State Introspection

From `TLC.tla`:

```tla
TLCGet("generated")
TLCGet("distinct")
TLCGet("queue")
TLCGet("diameter")
TLCGet("duration")
TLCGet("level")

TLCSet(1, 0)
TLCSet(1, TLCGet(1) + 1)
TLCGet(1)
TLCEval(expr)
```

Initialize numeric slots in `ASSUME` or `Init` when all workers need the value.

## Trace and Graph Export

```bash
java -cp dist/tla2tools.jar tlc2.TLC -dumpTrace json trace.json -config M.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -loadTrace json trace.json -config M.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -dump dot graph.gv -config M.cfg Spec.tla
```

## REPL

```bash
java -cp dist/tla2tools.jar tlc2.REPL
```

Use the REPL to evaluate TLA+ expressions before committing them to a spec.

## Test Corpus

`test-model/` contains paired `.tla`/`.cfg` fixtures used by Java tests. Treat them as examples unless validating expected behavior.

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
ant -f customBuild.xml test-set -Dtest.testcases="tlc2/tool/MonolithSpecTest*"
```

## Bakery Example

Run a known example:

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
java -cp dist/tla2tools.jar tlc2.TLC test-model/pcal/Bakery.tla
```

Typical config shape:

```tla
SPECIFICATION Spec
CONSTANTS NumProcs = 2
          MaxNum = 3
INVARIANT Invariant
CONSTRAINT Constraint
```

## Outcome Classification

| Output | Meaning |
|---|---|
| `Model checking completed. No error has been found.` | checked obligations passed |
| `Invariant ... is violated` | safety violation; inspect printed trace |
| `Temporal property ... was violated` | liveness violation; inspect lasso/stuttering trace |
| `Deadlock reached` | no next-state action enabled |
| unexpected exception | reduce and use `$tla-plus-debugging` |
