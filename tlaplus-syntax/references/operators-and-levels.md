# TLA+ Operators, Levels & Standard Modules

## Notation cheatsheet
- `==` defines operators/constants/actions. `#` and `/=` mean "not equal"; `=<` and `\leq` mean ≤.
- `'` (prime) = value in the next state; an action relates current and primed variables.
- `UNCHANGED x` ≡ `x' = x`. `[Next]_vars` ≡ `Next \/ (vars' = vars)` (stuttering).
- `<<...>>` tuples/sequences; `[x \in S |-> e]` functions; `[f EXCEPT ![i] = e]` function update.
- `d :> e` one-element function; `f @@ g` merge functions (from `TLC.tla`).
- `EXTENDS M` imports **and re-exports**; `INSTANCE M WITH x <- y` imports parameterized/renamed; `LOCAL INSTANCE` does not re-export.
- `CONSTANTS`/`VARIABLES` declare; `ASSUME P` states constant-level facts.

## Level checking (book ch. 16-17)
Every expression has a level; SANY rejects level violations.

| Level | Name | Contains | Example |
|-------|------|----------|---------|
| 0 | constant | constants, literals, pure ops | `ASSUME` body |
| 1 | state | unprimed variables | an invariant |
| 2 | action | `'` or `UNCHANGED` | `Next` |
| 3 | temporal | `[]`, `<>`, `WF_`, `SF_` | `Spec` |

Rules:
- Cannot prime an already-primed expression, or prime inside a temporal operator.
- `.cfg` `INVARIANT` must be level ≤ 1 (state predicate); `PROPERTY` is level 3 (temporal). Swapping them is a frequent error.
- `Seq(S)` is infinite/non-enumerable — parses, but TLC can't enumerate it as a quantifier bound.

## Invariants vs temporal properties
- **Invariant** (safety, level 1): holds in every reachable state. `.cfg`: `INVARIANT Inv`.
- **Temporal property** (level 3): `[]P`, `<>P`, `[]<>P`, `P ~> Q`. `.cfg`: `PROPERTY Liveness`.
- **Fairness:** `WF_vars(A)` / `SF_vars(A)`. Typical full spec: `Spec == Init /\ [][Next]_vars /\ WF_vars(Next)`.

## TLC-specific operators (`TLC.tla`, overridden in Java — see tlaplus-stdlib)
`Print`/`PrintT`, `Assert(val,msg)`, `TLCGet(i)`/`TLCSet(i,v)` (+ string keys `"distinct"`,`"queue"`,`"diameter"`,`"level"`,`"duration"`), `d :> e`, `@@`, `Permutations`, `SortSeq`, `RandomElement`, `ToString`, `TLCEval`, `Any`.

## Standard modules (`StandardModules/`)
`Naturals`, `Integers`, `Reals` (arithmetic); `Sequences` (`Seq`,`Len`,`\o`,`Append`,`Head`,`Tail`,`SubSeq`,`SelectSeq`); `FiniteSets` (`IsFiniteSet`,`Cardinality`); `Bags`; `TLC`; `TLCExt`; `Randomization`; `Json`. `EXTENDS` brings them in. These are the canonical examples of good TLA+ style.
