# TLA+ Syntax Reference

Use this for concrete syntax reminders. For source of truth, inspect `javacc/tla+.jj`, `StandardModules/*.tla`, and the Lamport book.

## Module Skeleton

```tla
---- MODULE ModuleName ----
EXTENDS Naturals, Sequences
CONSTANTS C1, C2
VARIABLES x, y

ASSUME C1 \in Nat

Init == x = 0 /\ y = C1
Next == x' = x + 1 /\ UNCHANGED y
Spec == Init /\ [][Next]_<<x, y>>

Invariant == x >= 0
====
```

## Expression Levels

| Level | Name | Contains | Examples |
|---|---|---|---|
| 0 | Constant | no state variables | `C1 + 3`, `ASSUME` |
| 1 | State | unprimed variables | `x > 0`, `INVARIANT` |
| 2 | Action | primed variables or `UNCHANGED` | `x' = x + 1`, `Next` |
| 3 | Temporal | temporal operators | `[]`, `<>`, `WF_`, `SF_`, `PROPERTY` |

SANY enforces level checking before TLC runs.

## Imports and Instances

```tla
EXTENDS Naturals
LOCAL INSTANCE Sequences
INSTANCE OtherModule
INSTANCE OtherModule WITH x <- y
```

`EXTENDS` imports definitions into the current module. `INSTANCE` instantiates another module, optionally with substitutions.

## Operators

```tla
Add(a, b) == a + b
Apply(Op(_, _), a, b) == Op(a, b)

RECURSIVE Fact(_)
Fact(n) == IF n = 0 THEN 1 ELSE n * Fact(n-1)

Foo == LET bar == 42 IN bar + 1
```

## Actions and Temporal Specs

```tla
Next ==
  /\ x' = x + 1
  /\ UNCHANGED y

Spec == Init /\ [][Next]_<<x, y>>
```

`[Next]_vars` means `Next \/ UNCHANGED vars`, making the step relation stuttering-tolerant.

## Safety, Liveness, Fairness

```tla
TypeOK == x \in Nat /\ y \in Nat
PROPERTY []TypeOK
PROPERTY <>(\E i \in 1..N : pc[i] = "done")
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)
Spec == Init /\ [][Next]_vars /\ SF_vars(Next)
```

Use `INVARIANT TypeOK` for a state predicate checked in all reachable states. Use `PROPERTY []TypeOK` for the equivalent temporal form.

## Sets, Functions, Tuples

```tla
{1, 2, 3}
{x \in S : P(x)}
{f(x) : x \in S}
[S -> T]
[x \in S |-> f(x)]
f[x]
[f EXCEPT ![k] = v]
<<a, b, c>>
DOMAIN f
```

## StandardModules

| Module | Common operators |
|---|---|
| `Naturals` | `Nat`, arithmetic, `..`, comparison |
| `Integers` | `Int`, integer arithmetic |
| `Sequences` | `Seq`, `Len`, `\o`, `Append`, `Head`, `Tail`, `SubSeq`, `SelectSeq` |
| `FiniteSets` | `IsFiniteSet`, `Cardinality` |
| `Bags` | multiset operators |
| `TLC` | `Print`, `PrintT`, `Assert`, `TLCGet`, `TLCSet`, `TLCEval`, `RandomElement`, `SortSeq`, `Permutations`, `:>`, `@@` |
| `TLCExt` | extended TLC introspection |
| `Randomization` | random choice utilities |

`Seq(S)` is not enumerable for TLC in quantifier bounds. Use bounded sequences or a model-checking wrapper.

## SANY Commands

```bash
java -cp dist/tla2tools.jar tla2sany.SANY Module.tla
java -cp dist/tla2tools.jar tla2sany.SANY -error-codes Module.tla
java -cp dist/tla2tools.jar tla2sany.xml.XMLExporter Module.tla
```

When using SANY as a Java library, `tla2sany.drivers.SANY.parse()` populates a `SpecObj`; it is process-safe but not thread-safe.
