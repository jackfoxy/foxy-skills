# PlusCal Reference

Primary paths:

- `tlatools/org.lamport.tlatools/src/pcal/trans.java`
- `tlatools/org.lamport.tlatools/src/pcal/PlusCal.tla`
- `tlatools/org.lamport.tlatools/src/pcal/AST.tla`
- `tlatools/org.lamport.tlatools/src/pcal/PcalTranslate.java`
- `tlatools/org.lamport.tlatools/src/pcal/PCalTLAGenerator.java`
- `tlatools/org.lamport.tlatools/test/pcal/`

PlusCal is a pseudocode language for concurrent algorithms. `pcal.trans` converts PlusCal source to TLA+ and writes generated TLA+ back into the same `.tla` file.

## PlusCal Comment Block

```tla
---- MODULE MyAlgorithm ----
EXTENDS Naturals, TLC

CONSTANTS N

(*
  --algorithm AlgorithmName
  variables x = 0, y = N;

  process Proc \in 1..N
  variables local = 0;
  begin
    start:
      local := x;
    update:
      x := local + 1;
  end process;
  end algorithm
*)

\* BEGIN TRANSLATION
\* generated TLA+ goes here
\* END TRANSLATION

Invariant == x >= 0
====
```

## Translator Invocation

```bash
java -cp dist/tla2tools.jar pcal.trans Module.tla
java -cp dist/tla2tools.jar pcal.trans -help
```

`pcal.trans` translates in-place. Do not hand-edit generated text between `BEGIN TRANSLATION` and `END TRANSLATION`; checksum logic detects manual edits and can block retranslation.

## Translation Workflow

1. PlusCal source appears in comments inside a `.tla` module.
2. `pcal.trans` parses and translates it.
3. Generated TLA+ is written back into the same `.tla` file.
4. SANY parses the resulting TLA+.
5. TLC checks the resulting spec/config.

Pipeline phases:

| Phase | Purpose |
|---|---|
| parse | parse PlusCal syntax |
| remove/rename conflicts | avoid name collisions |
| translate/generate | emit TLA+ actions, `Init`, `Next`, and `Spec` support |

## Language Elements

```tla
--algorithm Name
  variables v1 = e1, v2 = e2;

  define
    TypeOK == ...
  end define;

  process ProcName \in SetExpr
  variables local = 0;
  begin
    label1:
      if x > 0 then
        x := x - 1;
      else
        skip;
      end if;
    label2:
      with v \in S do
        y := v;
      end with;
      goto label1;
  end process;
end algorithm
```

Common constructs:

- `variables`: global or process-local state.
- `process P \in S`: one process instance per element of `S`.
- labels: control points that become TLA+ actions.
- `await`: blocking guard.
- `either/or`: nondeterministic branch.
- `with v \in S`: nondeterministic choice.
- `call`, `return`, `goto`: procedure/control transfer.

## Generated TLA+ Shape

```tla
VARIABLES pc, x, y, local
vars == <<pc, x, y, local>>

Init ==
  /\ pc = [self \in ProcSet |-> "label1"]
  /\ x = 0

label1(self) ==
  /\ pc[self] = "label1"
  /\ ...
  /\ pc' = [pc EXCEPT ![self] = "label2"]

Next == \E self \in 1..N : label1(self) \/ label2(self)
Spec == Init /\ [][Next]_vars
```

Each label becomes an action. `pc` maps each process to its current label.

## Fairness

Check generated and surrounding TLA+ before assuming fairness. Add or verify fairness explicitly when the property needs it:

```tla
Spec == Init /\ [][Next]_vars /\ \A self \in 1..N : WF_vars(proc(self))
Spec == Init /\ [][Next]_vars /\ \A self \in 1..N : SF_vars(proc(self))
```

Fairness changes liveness behavior and can interact with TLC liveness checking.

## End-to-End Commands

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
java -cp dist/tla2tools.jar pcal.trans Module.tla
java -cp dist/tla2tools.jar tla2sany.SANY Module.tla
java -cp dist/tla2tools.jar tlc2.TLC -config Module.cfg Module.tla
```

## Bakery Example

`test-model/pcal/Bakery.tla` demonstrates a PlusCal mutual exclusion algorithm. Its config shape:

```tla
SPECIFICATION Spec
CONSTANTS NumProcs = 2
          MaxNum = 3
INVARIANT Invariant
CONSTRAINT Constraint
```

## Failure Modes

- Identifier clashes after translation; rename the conflicting PlusCal variable/operator.
- Fairness annotations changing generated temporal behavior.
- Generated TLA+ parse errors from translator changes.
- Manual edits inside translation markers causing checksum failures.
- Missing labels at required control points.
- Test fixtures expecting exact generated output shape.
